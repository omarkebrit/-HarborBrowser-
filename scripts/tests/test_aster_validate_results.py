"""Contracts for native summary completeness and source-bound runtime skip checks."""

import importlib.util
import json
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest


SCRIPT = Path(__file__).resolve().parents[1] / 'aster-validate-results.py'
SPEC = importlib.util.spec_from_file_location('aster_validate_results', SCRIPT)
VALIDATOR = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(VALIDATOR)
SOURCE = '82dd060ead28e7e0170218a342fbcb991bbeef58'


class NativeResultValidationTests(unittest.TestCase):
    def setUp(self):
        temporary = tempfile.TemporaryDirectory()
        self.addCleanup(temporary.cleanup)
        self.root = Path(temporary.name)
        (self.root / 'source-commit.txt').write_text(SOURCE + '\n')
        self.summaries = {}
        for suite, (counts, total) in {
            'AsterUnitTests': ((5747, 0, 2, 0), 5749),
            'AsterRegressionTests': ((5, 0, 0, 0), 5),
            'AsterAcceptanceTests': ((16, 0, 0, 0), 16),
            'AsterDownloadTests': ((1, 0, 0, 0), 1),
        }.items():
            self.summaries[suite] = dict(zip(
                ('passedTests', 'failedTests', 'skippedTests', 'expectedFailures'), counts
            ), result='Passed', totalTestCount=total)
            self.save(suite)
        self.log = (
            b"interleaved Rust log prefixTest Case '-[ClientTests.TabEventHandlerTests testBlankPopupURL]' skipped (0.113 seconds).\n"
            b"another prefixTest Case '-[ClientTests.TestHistory testRandomThreading]' skipped (0.129 seconds).\n"
        )
        (self.root / 'unit-tests.log').write_bytes(self.log)

    def save(self, suite):
        (self.root / (suite + '-summary.json')).write_text(json.dumps(self.summaries[suite]))

    def check(self, scope='full'):
        return VALIDATOR.validate_results(self.root, scope, SOURCE)

    def test_full_results_accept_exact_source_counts_and_prefixed_skip_markers(self):
        report = self.check()
        self.assertEqual(report['result'], 'Passed')
        self.assertEqual(report['sourceCommit'], SOURCE)
        self.assertEqual(len(report['suites']), 4)
        self.assertEqual(report['runtimeSkips']['cases'], sorted(VALIDATOR.ALLOWED_SKIPS))
        self.assertEqual(len(report['validatorSHA256']), 64)

    def test_preflight_requires_only_its_summary_and_source(self):
        for suite in ('AsterUnitTests', 'AsterAcceptanceTests', 'AsterDownloadTests'):
            (self.root / (suite + '-summary.json')).unlink()
        (self.root / 'unit-tests.log').unlink()
        self.assertEqual(list(self.check('preflight')['suites']), ['AsterRegressionTests'])

    def test_rejects_missing_boolean_string_or_null_counts_in_every_suite(self):
        for suite in self.summaries:
            for field in ('passedTests', 'failedTests', 'skippedTests', 'expectedFailures', 'totalTestCount'):
                original = self.summaries[suite][field]
                for invalid in ('missing', True, False, '0', None, 0.0):
                    with self.subTest(suite=suite, field=field, invalid=invalid):
                        if invalid == 'missing':
                            self.summaries[suite].pop(field)
                        else:
                            self.summaries[suite][field] = invalid
                        self.save(suite)
                        with self.assertRaises(VALIDATOR.ValidationError):
                            self.check()
                        self.summaries[suite][field] = original
                self.save(suite)

    def test_rejects_expected_failures_and_other_count_mismatches_in_every_suite(self):
        for suite in self.summaries:
            for field in ('passedTests', 'failedTests', 'skippedTests', 'expectedFailures', 'totalTestCount'):
                with self.subTest(suite=suite, field=field):
                    original = self.summaries[suite][field]
                    self.summaries[suite][field] = original + 1
                    self.save(suite)
                    with self.assertRaises(VALIDATOR.ValidationError):
                        self.check()
                    self.summaries[suite][field] = original
                    self.save(suite)

    def test_rejects_partial_unit_plan_even_when_xcode_reports_passed(self):
        self.summaries['AsterUnitTests'].update(passedTests=1, skippedTests=0, totalTestCount=1)
        self.save('AsterUnitTests')
        with self.assertRaises(VALIDATOR.ValidationError):
            self.check()

    def test_rejects_missing_or_nonpassed_result_in_every_suite(self):
        for suite in self.summaries:
            for invalid in ('missing', 'Failed', 'Skipped', True, None):
                with self.subTest(suite=suite, invalid=invalid):
                    if invalid == 'missing':
                        self.summaries[suite].pop('result')
                    else:
                        self.summaries[suite]['result'] = invalid
                    self.save(suite)
                    with self.assertRaises(VALIDATOR.ValidationError):
                        self.check()
                    self.summaries[suite]['result'] = 'Passed'
            self.save(suite)

    def test_uses_top_level_counts_instead_of_dynamic_parameter_execution_counts(self):
        self.summaries['AsterUnitTests']['devicesAndConfigurations'] = [{'passedTests': 5758, 'skippedTests': 2}]
        self.save('AsterUnitTests')
        self.assertEqual(self.check()['result'], 'Passed')

    def test_rejects_missing_duplicate_or_substituted_skip_identities(self):
        extra = b"Test Case 'UnrelatedSuite/testUnexpectedSkip()' skipped (0.1 seconds).\n"
        replacements = (
            b'', self.log + extra, self.log + self.log.splitlines(keepends=True)[0],
            self.log.replace(b'ClientTests.TestHistory testRandomThreading', b'ClientTests.OtherTests anotherCase'),
        )
        for log in replacements:
            with self.subTest(log=log):
                (self.root / 'unit-tests.log').write_bytes(log)
                with self.assertRaises(VALIDATOR.ValidationError):
                    self.check()

    def test_skip_reason_messages_alone_cannot_replace_actual_skip_results(self):
        (self.root / 'unit-tests.log').write_bytes(
            b'-[ClientTests.TabEventHandlerTests testBlankPopupURL] : Test skipped - upstream reason\n'
            b'-[ClientTests.TestHistory testRandomThreading] : Test skipped - upstream reason\n'
        )
        with self.assertRaises(VALIDATOR.ValidationError):
            self.check()

    def test_rejects_wrong_missing_or_invalid_source_binding(self):
        for source in ('0' * 40, SOURCE + '\nextra source', ''):
            with self.subTest(source=source):
                (self.root / 'source-commit.txt').write_text(source)
                with self.assertRaises(VALIDATOR.ValidationError):
                    self.check()
        (self.root / 'source-commit.txt').unlink()
        with self.assertRaises(OSError):
            self.check()
        with self.assertRaises(VALIDATOR.ValidationError):
            VALIDATOR.validate_results(self.root, 'full', 'short-sha')

    def test_preflight_rejects_expected_failure_or_missing_count(self):
        self.summaries['AsterRegressionTests']['expectedFailures'] = 1
        self.save('AsterRegressionTests')
        with self.assertRaises(VALIDATOR.ValidationError):
            self.check('preflight')
        self.summaries['AsterRegressionTests'].pop('expectedFailures')
        self.save('AsterRegressionTests')
        with self.assertRaises(VALIDATOR.ValidationError):
            self.check('preflight')

    def test_cli_rejects_malformed_or_nonobject_summary_with_failed_json_and_nonzero_exit(self):
        summary = self.root / 'AsterUnitTests-summary.json'
        for content in ('{invalid', '[]', 'null'):
            with self.subTest(content=content):
                summary.write_text(content)
                result = subprocess.run([sys.executable, str(SCRIPT), str(self.root), '--expected-source', SOURCE],
                                        capture_output=True, text=True, check=False)
                self.assertNotEqual(result.returncode, 0)
                self.assertEqual(json.loads(result.stdout)['result'], 'Failed')

    def test_cli_emits_source_bound_sidecar_and_step_summary_without_modifying_evidence(self):
        original = {path.name: path.read_bytes() for path in self.root.iterdir()}
        summary = self.root / 'derived-step-summary.md'
        result = subprocess.run([sys.executable, str(SCRIPT), str(self.root), '--expected-source', SOURCE,
                                 '--step-summary', str(summary)], capture_output=True, text=True, check=False)
        self.assertEqual(result.returncode, 0, result.stderr)
        report = json.loads(result.stdout)
        self.assertEqual(report['sourceCommit'], SOURCE)
        self.assertIn(SOURCE, summary.read_text())
        for name, data in original.items():
            self.assertEqual((self.root / name).read_bytes(), data)


if __name__ == '__main__':
    unittest.main()
