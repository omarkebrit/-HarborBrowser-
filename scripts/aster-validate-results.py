#!/usr/bin/env python3
"""Validate source-bound native summaries and the two documented runtime skips."""

import argparse
import hashlib
import json
from pathlib import Path
import re
import sys


FIELDS = ('passedTests', 'failedTests', 'skippedTests', 'expectedFailures')
EXPECTED = {
    'AsterUnitTests': ((5747, 0, 2, 0), 5749),
    'AsterRegressionTests': ((5, 0, 0, 0), 5),
    'AsterAcceptanceTests': ((16, 0, 0, 0), 16),
    'AsterDownloadTests': ((1, 0, 0, 0), 1),
}
ALLOWED_SKIPS = (
    '-[ClientTests.TabEventHandlerTests testBlankPopupURL]',
    '-[ClientTests.TestHistory testRandomThreading]',
)


class ValidationError(ValueError):
    pass


def require(condition, message):
    if not condition:
        raise ValidationError(message)


def digest(data):
    return hashlib.sha256(data).hexdigest()


def validate_results(directory, scope, expected_source):
    directory = Path(directory)
    require(scope in ('full', 'preflight'), 'Unknown validation scope.')
    require(re.fullmatch(r'[0-9a-f]{40}', expected_source) is not None,
            'Expected source must be a complete lowercase Git commit SHA.')
    source_bytes = (directory / 'source-commit.txt').read_bytes()
    source = source_bytes.decode('utf-8').strip()
    require(source == expected_source, 'Evidence source-commit.txt does not match the expected source.')
    suites = EXPECTED if scope == 'full' else {'AsterRegressionTests': EXPECTED['AsterRegressionTests']}
    report = {
        'result': 'Passed', 'scope': scope, 'sourceCommit': source,
        'expectedSource': expected_source, 'sourceRecordSHA256': digest(source_bytes),
        'validatorSHA256': digest(Path(__file__).read_bytes()), 'suites': {},
        'limits': 'Checks retained summaries and log identities; does not execute tests or attest binary provenance.',
    }
    for suite, (expected, total) in suites.items():
        raw = (directory / (suite + '-summary.json')).read_bytes()
        result = json.loads(raw)
        require(isinstance(result, dict), f'{suite}: summary must be a JSON object.')
        counts = tuple(result.get(field) for field in FIELDS)
        require(all(type(count) is int for count in counts), f'{suite}: all four count fields must be integers.')
        require(type(result.get('totalTestCount')) is int, f'{suite}: totalTestCount must be an integer.')
        require(counts == expected and result['totalTestCount'] == total and result.get('result') == 'Passed',
                f'{suite}: expected counts {expected}, total {total}, result Passed; got {counts}.')
        report['suites'][suite] = {'counts': dict(zip(FIELDS, counts)), 'totalTestCount': total,
                                   'summarySHA256': digest(raw)}
    if scope == 'full':
        unit_log = (directory / 'unit-tests.log').read_bytes()
        skipped = re.findall(rb"Test Case '([^'\r\n]+)' skipped \(", unit_log)
        require(sorted(skipped) == sorted(case.encode('ascii') for case in ALLOWED_SKIPS),
                'Unit runtime skip identities must be exactly the two documented upstream cases, once each.')
        report['runtimeSkips'] = {'cases': sorted(ALLOWED_SKIPS), 'unitLogSHA256': digest(unit_log)}
    return report


def write_step_summary(path, report):
    lines = ['Aster native validation', '', f'Evidence source: `{report["sourceCommit"]}`.', '']
    for suite, item in report['suites'].items():
        counts = item['counts']
        lines.append(f'- {suite}: {counts["passedTests"]} passed; {counts["skippedTests"]} skipped; '
                     'zero failures or expected failures.')
    lines.append('Simulator checks do not certify physical-device battery use, all websites, DRM, or Brave paid services.')
    with Path(path).open('a') as output:
        output.write('\n'.join(lines) + '\n')


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('results', type=Path)
    parser.add_argument('--scope', choices=('full', 'preflight'), default='full')
    parser.add_argument('--expected-source', required=True)
    parser.add_argument('--step-summary', type=Path)
    args = parser.parse_args()
    try:
        report = validate_results(args.results, args.scope, args.expected_source)
        if args.step_summary:
            write_step_summary(args.step_summary, report)
    except (ValidationError, OSError, ValueError, TypeError) as error:
        report = {'result': 'Failed', 'scope': args.scope, 'expectedSource': args.expected_source,
                  'validatorSHA256': digest(Path(__file__).read_bytes()), 'error': str(error)}
        print(f'::error::{error}', file=sys.stderr)
    print(json.dumps(report, indent=2))
    return 0 if report['result'] == 'Passed' else 1


if __name__ == '__main__':
    sys.exit(main())
