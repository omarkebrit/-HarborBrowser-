#!/usr/bin/env python3
"""Generate the bundled ad layer from official iOS lists using a pinned converter."""
import datetime
import hashlib
import json
import pathlib
import subprocess
import sys
import tempfile
import urllib.request

ROOT = pathlib.Path(__file__).resolve().parents[2]
DEST = ROOT / "firefox-ios/Client/Assets/AsterFilters"
VERSION = "4.3.0"
COMMIT = "7a2e93f0afa70479cc59985f332025236c3f0c39"
TOOL_SHA = "6687be9f1a77abd5299299086c5fbffd0d1b5baec755eb4808aa2f53e275d3c0"
TOOL_URL = f"https://github.com/AdguardTeam/SafariConverterLib/releases/download/v{VERSION}/ConverterTool"
FILTERS = [(2, "AdGuard Base"), (11, "AdGuard Mobile Ads")]


def download(url):
    with urllib.request.urlopen(url, timeout=60) as response:
        data = response.read(25_000_001)
    if len(data) > 25_000_000:
        raise ValueError(f"Download exceeds 25 MB: {url}")
    return data


def main():
    DEST.mkdir(parents=True, exist_ok=True)
    with tempfile.TemporaryDirectory(prefix="aster-ad-filters-") as temporary:
        staging = pathlib.Path(temporary)
        tool = staging / "ConverterTool"
        binary = download(TOOL_URL)
        if hashlib.sha256(binary).hexdigest() != TOOL_SHA:
            raise ValueError("Converter release checksum mismatch")
        tool.write_bytes(binary)
        tool.chmod(0o700)
        sources, inputs = [], []
        for number, name in FILTERS:
            url = f"https://filters.adtidy.org/ios/filters/{number}_optimized.txt"
            data = download(url)
            text = data.decode("utf-8-sig")
            if "AdGuard" not in text[:2000] or len(text.splitlines()) < 100 or "<html" in text[:1000].lower():
                raise ValueError(f"Unexpected filter response: {name}")
            (staging / f"source-{number}.txt").write_text(text, encoding="utf-8")
            inputs.extend(text.splitlines())
            sources.append({"id": number, "name": name, "url": url, "sha256": hashlib.sha256(data).hexdigest()})
        combined = staging / "combined.txt"
        combined.write_text("\n".join(inputs), encoding="utf-8")
        command = [str(tool), "convert", "--input-path", str(combined), "--safari-version", "16", "--advanced-blocking", "false"]
        try:
            result = subprocess.run(command, capture_output=True, text=True, timeout=240)
        except OSError as error:
            result = subprocess.CompletedProcess(command, 126, stdout="", stderr=str(error))
        if result.returncode:
            print("Converter release could not run; building the same pinned release from source.", file=sys.stderr)
            print(result.stderr[-3000:], file=sys.stderr)
            source = staging / "converter-source"
            subprocess.run(["git", "init", str(source)], check=True, capture_output=True)
            subprocess.run(["git", "-C", str(source), "remote", "add", "origin", "https://github.com/AdguardTeam/SafariConverterLib.git"], check=True)
            subprocess.run(["git", "-C", str(source), "fetch", "--depth", "1", "origin", COMMIT], check=True)
            subprocess.run(["git", "-C", str(source), "checkout", "--detach", "FETCH_HEAD"], check=True)
            actual = subprocess.check_output(["git", "-C", str(source), "rev-parse", "HEAD"], text=True).strip()
            if actual != COMMIT:
                raise ValueError("Converter source commit mismatch")
            expected_dependencies = {
                "punycodeswift": "30a462bdb4398ea835a3585472229e0d74b36ba5",
                "swift-argument-parser": "41982a3656a71c768319979febd796c6fd111d5c",
                "swift-psl": "7ccee9d576d4ca45219440e346f61117f44c816f",
            }
            resolved = json.loads((source / "Package.resolved").read_text())
            if {pin["identity"]: pin["state"]["revision"] for pin in resolved["pins"]} != expected_dependencies:
                raise ValueError("Converter dependency lock mismatch")
            subprocess.run(["swift", "build", "--package-path", str(source), "--disable-automatic-resolution", "-c", "release", "--product", "ConverterTool"], check=True, timeout=600)
            command[0] = str(source / ".build/release/ConverterTool")
            result = subprocess.run(command, capture_output=True, text=True, timeout=240)
            if result.returncode:
                raise RuntimeError(result.stderr[-8000:])
        report = json.loads(result.stdout)
        rules = json.loads(report.pop("safariRulesJSON"))
        if not isinstance(rules, list) or not 1000 < len(rules) < 150_000:
            raise ValueError(f"Unexpected rule count: {len(rules)}")
        if report.get("discardedSafariRules", 0) != 0:
            raise ValueError("Converter truncated the ad filters")
        if not any(rule.get("action", {}).get("type") == "ignore-previous-rules" for rule in rules):
            raise ValueError("Expected upstream compatibility exceptions")
        encoded = json.dumps(rules, separators=(",", ":"), ensure_ascii=False)
        (staging / "ads.json").write_text(encoded, encoding="utf-8")
        (staging / "conversion-report.json").write_text(json.dumps(report, indent=2), encoding="utf-8")
        metadata = {
            "mode": "adguard", "ruleCount": len(rules),
            "generatedAt": datetime.datetime.now(datetime.timezone.utc).isoformat(),
            "converter": f"SafariConverterLib {VERSION}", "converterCommit": COMMIT,
            "converterReleaseSHA256": TOOL_SHA, "safariTarget": 16, "sources": sources,
            "rulesSHA256": hashlib.sha256(encoded.encode("utf-8")).hexdigest(),
            "scope": "AdGuard Base and Mobile Ads; native ETP remains a separate layer. No added blanket cookie rule or video exceptions.",
        }
        (staging / "metadata.json").write_text(json.dumps(metadata, indent=2), encoding="utf-8")
        licenses = [
            ("FILTER-LICENSE-LGPL-3.0.txt", "https://raw.githubusercontent.com/AdguardTeam/FiltersRegistry/master/LICENSE"),
            ("CONVERTER-LICENSE-GPL-3.0.txt", f"https://raw.githubusercontent.com/AdguardTeam/SafariConverterLib/{COMMIT}/LICENSE"),
        ]
        for name, url in licenses:
            (staging / name).write_bytes(download(url))
        (staging / "NOTICE.txt").write_text(
            "Aster bundles transformed AdGuard Base and Mobile Ads iOS optimized filter lists. Copyright their respective authors. "
            "FiltersRegistry is LGPL-3.0; upstream third-party filter components retain the licenses stated in the accompanying source lists. "
            "Source lists, licenses, hashes and transformation report accompany this app. SafariConverterLib 4.3.0 is used only during builds "
            "and is not linked into the app. Converter source: https://github.com/AdguardTeam/SafariConverterLib at " + COMMIT + ". "
            "Filter source: https://github.com/AdguardTeam/FiltersRegistry . Advanced scriptlets/procedural rules are not supported by this WebKit layer.\n",
            encoding="utf-8",
        )
        for name in ["ads.json", "metadata.json", "conversion-report.json", "NOTICE.txt", *[f"source-{number}.txt" for number, _ in FILTERS], *[name for name, _ in licenses]]:
            (DEST / name).write_bytes((staging / name).read_bytes())
        print(json.dumps(metadata, indent=2))


if __name__ == "__main__":
    main()
