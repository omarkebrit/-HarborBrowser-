#!/usr/bin/env python3
"""Inspect an unsigned Aster device package without extracting or signing it."""

import argparse
import hashlib
import io
import json
import pathlib
import plistlib
import re
import struct
import subprocess
import sys
import zipfile


APP_ID = "com.omarkebrit.aster"
EXTENSIONS = {"WidgetKit", "NotificationService", "CredentialProvider", "Sticker", "ActionExtension", "ShareTo"}
CONVERTER_COMMIT = "7a2e93f0afa70479cc59985f332025236c3f0c39"
CONVERTER_SHA256 = "6687be9f1a77abd5299299086c5fbffd0d1b5baec755eb4808aa2f53e275d3c0"


class AuditError(ValueError):
    pass


def require(condition, message):
    if not condition:
        raise AuditError(message)


def sha256(data):
    return hashlib.sha256(data).hexdigest()


def macho_architectures(data):
    require(len(data) >= 4, "Executable is truncated.")
    magic = data[:4]
    fat_formats = {
        b"\xca\xfe\xba\xbe": (">", False), b"\xbe\xba\xfe\xca": ("<", False),
        b"\xca\xfe\xba\xbf": (">", True), b"\xbf\xba\xfe\xca": ("<", True),
    }
    if magic in fat_formats:
        endian, wide = fat_formats[magic]
        require(len(data) >= 8, "Fat executable header is truncated.")
        count = struct.unpack_from(endian + "I", data, 4)[0]
        size = 32 if wide else 20
        require(0 < count <= 64 and 8 + count * size <= len(data), "Invalid fat architecture table.")
        architectures = []
        for index in range(count):
            offset = 8 + index * size
            if wide:
                cpu, _, start, length, _, _ = struct.unpack_from(endian + "IIQQII", data, offset)
            else:
                cpu, _, start, length, _ = struct.unpack_from(endian + "IIIII", data, offset)
            require(start >= 8 + count * size and length > 0 and start + length <= len(data),
                    "Invalid fat executable slice bounds.")
            slices = macho_architectures(data[start:start + length])
            require(len(slices) == 1 and slices[0]["cpuType"] == cpu, "Fat slice architecture does not match its table.")
            architectures.extend(slices)
        return architectures

    formats = {b"\xcf\xfa\xed\xfe": "<", b"\xfe\xed\xfa\xcf": ">"}
    require(magic in formats, "Expected a 64-bit Mach-O executable.")
    endian = formats[magic]
    require(len(data) >= 32, "Mach-O header is truncated.")
    _, cpu, subtype, file_type, commands, command_bytes, _, _ = struct.unpack_from(endian + "8I", data)
    require(cpu == 0x0100000C, "Executable must use arm64, not a simulator/other CPU architecture.")
    require(file_type == 2, "App and extension code must be Mach-O executables.")
    require(commands > 0 and 32 + command_bytes <= len(data), "Invalid Mach-O load-command bounds.")
    cursor = 32
    platforms = []
    for _ in range(commands):
        require(cursor + 8 <= 32 + command_bytes, "Mach-O load command is truncated.")
        command, size = struct.unpack_from(endian + "II", data, cursor)
        require(size >= 8 and cursor + size <= 32 + command_bytes, "Invalid Mach-O load-command size.")
        if command == 0x32:
            require(size >= 24, "LC_BUILD_VERSION is truncated.")
            platforms.append(struct.unpack_from(endian + "I", data, cursor + 8)[0])
        elif command == 0x25:
            require(size >= 16, "LC_VERSION_MIN_IPHONEOS is truncated.")
            platforms.append(2)
        elif command in {0x24, 0x2F, 0x30}:
            raise AuditError("Executable declares a non-iPhone operating system.")
        cursor += size
    require(cursor == 32 + command_bytes, "Mach-O command table length is inconsistent.")
    require(platforms and set(platforms) == {2}, "Executable must target iOS device platform 2; arm64 simulator is invalid.")
    return [{"architecture": "arm64", "cpuType": cpu, "cpuSubtype": subtype,
             "platform": 2, "fileType": file_type}]


def read_package(path):
    original = pathlib.Path(path).read_bytes()
    with zipfile.ZipFile(io.BytesIO(original)) as archive:
        names = archive.namelist()
        if any(name.startswith("Payload/") for name in names):
            return original, None
        candidates = [name for name in names if name.lower().endswith(".ipa") and not name.endswith("/")]
        require(len(candidates) == 1, "Artifact ZIP must contain exactly one IPA.")
        return archive.read(candidates[0]), sha256(original)


def source_checks(root):
    root = pathlib.Path(root)
    entitlement = plistlib.loads((root / "firefox-ios/Client/Entitlements/AsterApplication.entitlements").read_bytes())
    require(entitlement.get("com.apple.security.application-groups") == ["group.$(MOZ_BUNDLE_ID)"],
            "Source application-group declaration changed unexpectedly.")
    require(entitlement.get("keychain-access-groups") == ["$(AppIdentifierPrefix)$(MOZ_BUNDLE_ID)"],
            "Source keychain group declaration changed unexpectedly.")
    require("com.apple.developer.web-browser" not in entitlement, "Source unexpectedly requests a managed browser entitlement.")
    flags = ("allowsInlineMediaPlayback", "allowsPictureInPictureMediaPlayback",
             "allowsAirPlayForMediaPlayback", "isElementFullscreenEnabled")
    paths = ("firefox-ios/Client/TabManagement/TabConfigurationProvider.swift",
             "BrowserKit/Sources/WebEngine/WKWebview/WKEngineConfigurationProvider.swift")
    for path in paths:
        code = (root / path).read_text()
        for flag in flags:
            require(re.search(r"\b" + flag + r"\s*=\s*true\b", code), f"Missing source media setting: {path}: {flag}.")
    commit = subprocess.run(["git", "-C", str(root), "rev-parse", "HEAD"],
                            capture_output=True, text=True, check=False)
    return {"checkoutCommit": commit.stdout.strip() if commit.returncode == 0 else None,
            "mediaConfigurationFiles": list(paths), "mediaFlagsChecked": list(flags),
            "appGroup": "group.$(MOZ_BUNDLE_ID)",
            "keychainGroup": "$(AppIdentifierPrefix)$(MOZ_BUNDLE_ID)",
            "scope": "Source declarations only; this does not prove binary provenance or runtime behavior."}


def audit(path, expected_build, source=None):
    require(re.fullmatch(r"\d+(?:\.\d+){0,2}", expected_build), "Expected build must be a resolved numeric Apple build version.")
    ipa, outer_hash = read_package(path)
    report = {"result": "Passed", "ipaSHA256": sha256(ipa), "ipaBytes": len(ipa),
              "signing": {"appleSigned": False, "needsSigning": True,
                          "note": "Linker ad-hoc signature bytes do not provide Apple signing or provisioning."},
              "limits": ["No signed installation or physical-device test is certified.",
                         "Packaging checks do not replace unit, browser UI, media or download tests."]}
    if outer_hash:
        report["artifactArchiveSHA256"] = outer_hash
    with zipfile.ZipFile(io.BytesIO(ipa)) as archive:
        names = archive.namelist()
        require(len(names) == len(set(names)), "IPA contains duplicate archive entries.")
        require(all(not pathlib.PurePosixPath(name).is_absolute() and ".." not in pathlib.PurePosixPath(name).parts
                    and "\\" not in name for name in names), "IPA contains an invalid archive path.")
        roots = {name.split("/")[1] for name in names if re.fullmatch(r"Payload/[^/]+\.app/Info\.plist", name)}
        require(roots == {"Aster.app"}, "IPA must contain exactly Payload/Aster.app.")
        root = "Payload/Aster.app/"

        def read(name):
            require(name in names, f"Missing packaged file: {name}.")
            return archive.read(name)

        def plist(name):
            value = plistlib.loads(read(name))
            require(isinstance(value, dict), f"Expected a property-list dictionary: {name}.")
            return value

        require(not any(name.endswith("/embedded.mobileprovision") for name in names), "IPA unexpectedly includes provisioning profiles.")
        require(root + "_CodeSignature/CodeResources" not in names, "Main app unexpectedly has a resource signing seal.")
        main = plist(root + "Info.plist")
        require(main.get("CFBundleDisplayName") == "Aster", "Main app display name is not Aster.")
        sdk = main.get("DTSDKName", "")
        require(isinstance(sdk, str) and re.fullmatch(r"iphoneos\d+(?:\.\d+){0,2}", sdk),
                "App Info.plist must identify a resolved iPhone device SDK.")
        minimum_os = main.get("MinimumOSVersion", "")
        require(isinstance(minimum_os, str) and re.fullmatch(r"\d+(?:\.\d+){0,2}", minimum_os),
                "MinimumOSVersion must be resolved.")

        def bundle(prefix, info, identifier, passive=False):
            require(info.get("CFBundleIdentifier") == identifier, f"Unexpected bundle identifier: {prefix}.")
            require(info.get("CFBundleShortVersionString") == "158.0", f"Unexpected/unresolved app version: {prefix}.")
            require(info.get("CFBundleVersion") == expected_build, f"Unexpected/unresolved build version: {prefix}.")
            executable = info.get("CFBundleExecutable")
            result = {"bundleIdentifier": identifier, "version": "158.0", "build": expected_build}
            if not executable:
                require(passive, f"Executable is required: {prefix}.")
                result["resourceOnlyStickerPack"] = True
                return result
            require(isinstance(executable, str) and "/" not in executable and executable not in {".", ".."},
                    f"Invalid executable name: {prefix}.")
            code = read(prefix + executable)
            result.update({"executable": executable, "executableSHA256": sha256(code),
                           "architectures": macho_architectures(code)})
            return result

        report["application"] = bundle(root, main, APP_ID)
        report["application"]["sdk"] = sdk
        report["application"]["minimumOSVersion"] = main.get("MinimumOSVersion")
        plugin_plists = [name for name in names if re.fullmatch(re.escape(root) + r"PlugIns/[^/]+\.appex/Info\.plist", name)]
        require(len(plugin_plists) == len(EXTENSIONS), "IPA must contain all six Aster extensions.")
        found = set()
        report["extensions"] = []
        for name in sorted(plugin_plists):
            info = plist(name)
            identifier = info.get("CFBundleIdentifier", "")
            require(isinstance(identifier, str), "Extension bundle identifier must be a string.")
            suffix = identifier.removeprefix(APP_ID + ".")
            require(suffix in EXTENSIONS and identifier == APP_ID + "." + suffix and suffix not in found,
                    f"Unexpected or duplicate extension: {identifier}.")
            found.add(suffix)
            report["extensions"].append(bundle(name.removesuffix("Info.plist"), info, identifier, suffix == "Sticker"))
        require(found == EXTENSIONS, "Aster extension set does not match the expected package.")
        privacy = plist(root + "PrivacyInfo.xcprivacy")
        require(isinstance(privacy.get("NSPrivacyAccessedAPITypes"), list)
                and privacy["NSPrivacyAccessedAPITypes"], "Missing privacy API declarations.")
        report["privacyManifestSHA256"] = sha256(read(root + "PrivacyInfo.xcprivacy"))
        report["offlineSupportSHA256"] = {}
        for filename in ("help.html", "privacy.html"):
            content = read(root + "AsterSupport/" + filename)
            require(b"Content-Security-Policy" in content and b"default-src 'none'" in content and b"Aster" in content,
                    f"Offline support page is missing its content/CSP: {filename}.")
            report["offlineSupportSHA256"][filename] = sha256(content)
            if source:
                expected = pathlib.Path(source) / "firefox-ios/Client/Assets/AsterSupport" / filename
                require(content == expected.read_bytes(), f"Packaged offline page differs from source: {filename}.")
        filters = root + "AsterFilters/"
        metadata = json.loads(read(filters + "metadata.json"))
        rules_bytes = read(filters + "ads.json")
        rules = json.loads(rules_bytes)
        conversion = json.loads(read(filters + "conversion-report.json"))
        require(isinstance(metadata, dict) and isinstance(conversion, dict), "Advertising metadata/report must be dictionaries.")
        require(isinstance(rules, list) and len(rules) > 1000, "Production advertising rule pack is missing or too small.")
        require(metadata.get("mode") == "adguard" and metadata.get("ruleCount") == len(rules), "Advertising metadata count/mode mismatch.")
        require(metadata.get("rulesSHA256") == sha256(rules_bytes), "Packaged advertising rules hash mismatch.")
        require(metadata.get("converter") == "SafariConverterLib 4.3.0"
                and metadata.get("converterCommit") == CONVERTER_COMMIT
                and metadata.get("converterReleaseSHA256") == CONVERTER_SHA256,
                "Advertising converter provenance mismatch.")
        require(conversion.get("safariRulesCount") == len(rules) and conversion.get("discardedSafariRules") == 0,
                "Advertising conversion report/count mismatch.")
        inputs = metadata.get("sources", [])
        require(isinstance(inputs, list) and len(inputs) == 2 and all(isinstance(item, dict) for item in inputs)
                and {item.get("id") for item in inputs} == {2, 11}, "Expected AdGuard Base and Mobile Ads inputs.")
        for item in inputs:
            require(item.get("url") == f"https://filters.adtidy.org/ios/filters/{item['id']}_optimized.txt",
                    "Unexpected advertising source URL.")
            require(sha256(read(filters + f"source-{item['id']}.txt")) == item.get("sha256"), "Advertising source hash mismatch.")
        for filename in ("LICENSE-MPL-2.0.txt", "FILTER-LICENSE-LGPL-3.0.txt", "CONVERTER-LICENSE-GPL-3.0.txt", "NOTICE.txt"):
            require(read(filters + filename).strip(), f"Missing advertising license/notice: {filename}.")
        report["advertisingFilters"] = {"metadata": metadata, "conversionReport": conversion}
        report["checks"] = ["Resolved main and six-extension identities/versions", "arm64 iOS device Mach-O platform",
                            "No embedded Apple provisioning or main resource signing seal",
                            "Offline Help/Privacy and privacy manifest", "Exact bundled advertising input/output integrity"]
        if source:
            require(privacy == plistlib.loads((pathlib.Path(source) / "firefox-ios/PrivacyInfo.xcprivacy").read_bytes()),
                    "Packaged privacy declarations differ from source.")
            report["sourceConfigurationChecks"] = source_checks(source)
    return report


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("ipa", type=pathlib.Path)
    parser.add_argument("--source", type=pathlib.Path)
    parser.add_argument("--expected-build", required=True)
    parser.add_argument("--output", type=pathlib.Path, required=True)
    args = parser.parse_args()
    try:
        report = audit(args.ipa, args.expected_build, args.source)
    except (AuditError, OSError, ValueError, KeyError, TypeError, zipfile.BadZipFile, struct.error) as error:
        report = {"result": "Failed", "error": str(error), "input": args.ipa.name}
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps(report, indent=2) + "\n")
    print(json.dumps({key: report[key] for key in ("result", "ipaSHA256", "ipaBytes", "error") if key in report}))
    return 0 if report["result"] == "Passed" else 1


if __name__ == "__main__":
    sys.exit(main())
