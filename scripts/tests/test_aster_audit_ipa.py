"""Package-contract tests for the unsigned device auditor."""

import hashlib
import importlib.util
import io
import json
import pathlib
import plistlib
import struct
import subprocess
import sys
import tempfile
import unittest
import zipfile


ROOT = pathlib.Path(__file__).resolve().parents[2]
SCRIPT = ROOT / "scripts/aster-audit-ipa.py"
SPEC = importlib.util.spec_from_file_location("aster_audit_ipa", SCRIPT)
AUDIT = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(AUDIT)
PREFIX = "Payload/Aster.app/"
BUILD = "18.1"


def executable(platform=2, cpu=0x0100000C, legacy=False, file_type=2):
    command = (struct.pack("<4I", 0x25, 16, 0x0F0000, 0x1A0500) if legacy
               else struct.pack("<6I", 0x32, 24, platform, 0x0F0000, 0x1A0500, 0))
    return struct.pack("<8I", 0xFEEDFACF, cpu, 0, file_type, 1, len(command), 0, 0) + command


def fat_executable(code, wide=False):
    if wide:
        return b"\xca\xfe\xba\xbf" + struct.pack(">I2I2Q2I", 1, 0x0100000C, 0, 40, len(code), 0, 0) + code
    return b"\xca\xfe\xba\xbe" + struct.pack(">6I", 1, 0x0100000C, 0, 28, len(code), 0) + code


def fixture_files(sticker_executable=False, source_pages=False):
    main = {"CFBundleDisplayName": "Aster", "CFBundleIdentifier": AUDIT.APP_ID,
            "CFBundleShortVersionString": "158.0", "CFBundleVersion": BUILD,
            "CFBundleExecutable": "Client", "DTSDKName": "iphoneos26.5", "MinimumOSVersion": "15.0"}
    files = {PREFIX + "Info.plist": plistlib.dumps(main), PREFIX + "Client": executable()}
    for suffix in AUDIT.EXTENSIONS:
        info = {"CFBundleIdentifier": AUDIT.APP_ID + "." + suffix,
                "CFBundleShortVersionString": "158.0", "CFBundleVersion": BUILD}
        if suffix != "Sticker" or sticker_executable:
            info["CFBundleExecutable"] = suffix
            files[PREFIX + f"PlugIns/{suffix}.appex/{suffix}"] = executable()
        files[PREFIX + f"PlugIns/{suffix}.appex/Info.plist"] = plistlib.dumps(info)
    privacy = {"NSPrivacyAccessedAPITypes": [{"NSPrivacyAccessedAPIType": "NSPrivacyAccessedAPICategoryUserDefaults",
                                           "NSPrivacyAccessedAPITypeReasons": ["1C8F.1"]}]}
    files[PREFIX + "PrivacyInfo.xcprivacy"] = plistlib.dumps(privacy)
    for page in ("help.html", "privacy.html"):
        files[PREFIX + "AsterSupport/" + page] = (
            b"<!doctype html><meta http-equiv='Content-Security-Policy' content=\"default-src 'none'\"><title>Aster</title>")
    if source_pages:
        files[PREFIX + "PrivacyInfo.xcprivacy"] = (ROOT / "firefox-ios/PrivacyInfo.xcprivacy").read_bytes()
        for page in ("help.html", "privacy.html"):
            files[PREFIX + "AsterSupport/" + page] = (ROOT / "firefox-ios/Client/Assets/AsterSupport" / page).read_bytes()
    rules = json.dumps([{"trigger": {"url-filter": "ads"}, "action": {"type": "block"}}] * 1001).encode()
    metadata = {"mode": "adguard", "ruleCount": 1001, "rulesSHA256": hashlib.sha256(rules).hexdigest(),
                "converter": "SafariConverterLib 4.3.0", "converterCommit": AUDIT.CONVERTER_COMMIT,
                "converterReleaseSHA256": AUDIT.CONVERTER_SHA256, "sources": []}
    for identifier in (2, 11):
        data = f"Fixture source {identifier}\n".encode()
        files[PREFIX + f"AsterFilters/source-{identifier}.txt"] = data
        metadata["sources"].append({"id": identifier, "sha256": hashlib.sha256(data).hexdigest(),
                                    "url": f"https://filters.adtidy.org/ios/filters/{identifier}_optimized.txt"})
    files[PREFIX + "AsterFilters/ads.json"] = rules
    files[PREFIX + "AsterFilters/metadata.json"] = json.dumps(metadata).encode()
    files[PREFIX + "AsterFilters/conversion-report.json"] = json.dumps(
        {"safariRulesCount": 1001, "discardedSafariRules": 0, "errorsCount": 93}).encode()
    for name in ("LICENSE-MPL-2.0.txt", "FILTER-LICENSE-LGPL-3.0.txt", "CONVERTER-LICENSE-GPL-3.0.txt", "NOTICE.txt"):
        files[PREFIX + "AsterFilters/" + name] = b"Fixture license/notice text\n"
    return files


def archive_bytes(files):
    target = io.BytesIO()
    with zipfile.ZipFile(target, "w", zipfile.ZIP_DEFLATED) as archive:
        for name, content in files.items():
            archive.writestr(name, content)
    return target.getvalue()


class PackageAuditTests(unittest.TestCase):
    def setUp(self):
        self.directory = tempfile.TemporaryDirectory()
        self.addCleanup(self.directory.cleanup)
        self.ipa = pathlib.Path(self.directory.name) / "Aster.ipa"

    def inspect(self, files=None, source=None):
        self.ipa.write_bytes(archive_bytes(fixture_files() if files is None else files))
        return AUDIT.audit(self.ipa, BUILD, source)

    def rejects(self, files, message):
        with self.assertRaisesRegex(AUDIT.AuditError, message):
            self.inspect(files)

    def update_plist(self, files, name, **changes):
        data = plistlib.loads(files[name])
        data.update(changes)
        files[name] = plistlib.dumps(data)

    def test_device_package_allows_legitimate_resource_only_sticker(self):
        report = self.inspect()
        self.assertEqual(report["result"], "Passed")
        self.assertEqual(len(report["extensions"]), 6)
        sticker = next(item for item in report["extensions"] if item["bundleIdentifier"].endswith(".Sticker"))
        self.assertTrue(sticker["resourceOnlyStickerPack"])
        self.assertFalse(report["signing"]["appleSigned"])

    def test_sticker_executable_is_checked_when_present(self):
        files = fixture_files(sticker_executable=True)
        files[PREFIX + "PlugIns/Sticker.appex/Sticker"] = executable(platform=7)
        self.rejects(files, "platform 2")

    def test_nested_artifact_reports_actual_inner_ipa_hash(self):
        inner = archive_bytes(fixture_files())
        outer = archive_bytes({"Aster.ipa": inner})
        self.ipa.write_bytes(outer)
        result = AUDIT.audit(self.ipa, BUILD)
        self.assertEqual(result["ipaSHA256"], hashlib.sha256(inner).hexdigest())
        self.assertEqual(result["ipaBytes"], len(inner))
        self.assertEqual(result["artifactArchiveSHA256"], hashlib.sha256(outer).hexdigest())
        self.assertNotEqual(result["ipaSHA256"], result["artifactArchiveSHA256"])

    def test_arm64_simulator_rejected_despite_device_info_plist(self):
        files = fixture_files()
        files[PREFIX + "Client"] = executable(platform=7)
        self.rejects(files, "platform 2")

    def test_embedded_extension_simulator_rejected(self):
        files = fixture_files()
        files[PREFIX + "PlugIns/ShareTo.appex/ShareTo"] = executable(platform=7)
        self.rejects(files, "platform 2")

    def test_non_arm64_code_rejected(self):
        files = fixture_files()
        files[PREFIX + "Client"] = executable(cpu=0x01000007)
        self.rejects(files, "arm64")

    def test_legacy_arm64_iphoneos_load_command_is_supported(self):
        files = fixture_files()
        files[PREFIX + "Client"] = executable(legacy=True)
        self.assertEqual(self.inspect(files)["application"]["architectures"][0]["platform"], 2)

    def test_legacy_macos_command_is_rejected(self):
        files = fixture_files()
        code = bytearray(executable(legacy=True))
        struct.pack_into("<I", code, 32, 0x24)
        files[PREFIX + "Client"] = bytes(code)
        self.rejects(files, "non-iPhone")

    def test_fat32_and_fat64_device_slices_are_supported(self):
        for wide in (False, True):
            with self.subTest(wide=wide):
                files = fixture_files()
                files[PREFIX + "Client"] = fat_executable(executable(), wide)
                self.assertEqual(self.inspect(files)["application"]["architectures"][0]["platform"], 2)

    def test_fat_simulator_slice_is_rejected(self):
        files = fixture_files()
        files[PREFIX + "Client"] = fat_executable(executable(platform=7))
        self.rejects(files, "platform 2")

    def test_macho_object_cannot_masquerade_as_executable(self):
        files = fixture_files()
        files[PREFIX + "Client"] = executable(file_type=1)
        self.rejects(files, "executables")

    def test_truncated_load_command_is_rejected(self):
        files = fixture_files()
        files[PREFIX + "Client"] = executable()[:-1]
        self.rejects(files, "bounds")

    def test_missing_extension_is_rejected(self):
        files = fixture_files()
        for key in list(files):
            if "/NotificationService.appex/" in key:
                del files[key]
        self.rejects(files, "six Aster extensions")

    def test_non_sticker_requires_executable(self):
        files = fixture_files()
        key = PREFIX + "PlugIns/CredentialProvider.appex/Info.plist"
        info = plistlib.loads(files[key])
        del info["CFBundleExecutable"]
        files[key] = plistlib.dumps(info)
        self.rejects(files, "Executable is required")

    def test_extension_build_must_match_actual_package_build(self):
        files = fixture_files()
        self.update_plist(files, PREFIX + "PlugIns/WidgetKit.appex/Info.plist", CFBundleVersion="17.1")
        self.rejects(files, "build version")

    def test_unresolved_main_build_is_rejected(self):
        files = fixture_files()
        self.update_plist(files, PREFIX + "Info.plist", CFBundleVersion="$(CURRENT_PROJECT_VERSION)")
        self.rejects(files, "build version")

    def test_duplicate_extension_identifier_is_rejected(self):
        files = fixture_files()
        self.update_plist(files, PREFIX + "PlugIns/ShareTo.appex/Info.plist", CFBundleIdentifier=AUDIT.APP_ID + ".WidgetKit")
        self.rejects(files, "duplicate extension")

    def test_rule_content_hash_mismatch_is_rejected(self):
        files = fixture_files()
        files[PREFIX + "AsterFilters/ads.json"] += b"\n"
        self.rejects(files, "rules hash mismatch")

    def test_raw_source_hash_mismatch_is_rejected(self):
        files = fixture_files()
        files[PREFIX + "AsterFilters/source-2.txt"] += b"changed"
        self.rejects(files, "source hash mismatch")

    def test_filter_license_is_required(self):
        files = fixture_files()
        del files[PREFIX + "AsterFilters/FILTER-LICENSE-LGPL-3.0.txt"]
        self.rejects(files, "Missing packaged file")

    def test_offline_support_csp_is_required(self):
        files = fixture_files()
        files[PREFIX + "AsterSupport/privacy.html"] = b"<title>Aster Privacy</title>"
        self.rejects(files, "content/CSP")

    def test_apple_provisioning_and_main_seal_are_rejected(self):
        for name in ("embedded.mobileprovision", "_CodeSignature/CodeResources"):
            with self.subTest(name=name):
                files = fixture_files()
                files[PREFIX + name] = b"signed"
                self.rejects(files, "provisioning profiles|signing seal")

    def test_other_payload_application_is_rejected(self):
        files = fixture_files()
        files["Payload/Other.app/Info.plist"] = files[PREFIX + "Info.plist"]
        self.rejects(files, "exactly Payload/Aster.app")

    def test_source_declarations_are_reported_with_scope_limit(self):
        result = self.inspect(fixture_files(source_pages=True), ROOT)
        self.assertEqual(len(result["sourceConfigurationChecks"]["mediaFlagsChecked"]), 4)
        self.assertIn("does not prove binary provenance", result["sourceConfigurationChecks"]["scope"])

    def test_cli_failure_writes_diagnostic_json_and_nonzero_exit(self):
        files = fixture_files()
        files[PREFIX + "Client"] = executable(platform=7)
        self.ipa.write_bytes(archive_bytes(files))
        output = pathlib.Path(self.directory.name) / "audit.json"
        result = subprocess.run([sys.executable, str(SCRIPT), str(self.ipa), "--expected-build", BUILD,
                                 "--output", str(output)], capture_output=True, text=True)
        self.assertEqual(result.returncode, 1)
        self.assertEqual(json.loads(output.read_text())["result"], "Failed")
        self.assertNotIn("Traceback", result.stderr)


if __name__ == "__main__":
    unittest.main()
