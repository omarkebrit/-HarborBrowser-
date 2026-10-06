#!/usr/bin/env python3
"""Fetch official iOS lists, convert with a pinned AdGuard CLI, retain attribution."""
import datetime, hashlib, json, pathlib, subprocess, urllib.request

ROOT = pathlib.Path(__file__).resolve().parents[1]
DEST = ROOT / 'HarborBrowser/Filters'
DEST.mkdir(parents=True, exist_ok=True)
TOOL_SHA = '6687be9f1a77abd5299299086c5fbffd0d1b5baec755eb4808aa2f53e275d3c0'
TOOL_URL = 'https://github.com/AdguardTeam/SafariConverterLib/releases/download/v4.3.0/ConverterTool'

def download(url):
    with urllib.request.urlopen(url, timeout=90) as response:
        data = response.read(25_000_001)
    if len(data) > 25_000_000:
        raise ValueError('Download exceeds 25 MB')
    return data

tool = ROOT / 'ConverterTool'
tool.write_bytes(download(TOOL_URL))
assert hashlib.sha256(tool.read_bytes()).hexdigest() == TOOL_SHA, 'Converter checksum mismatch'
tool.chmod(0o700)
filters = [(2, 'Base'), (3, 'Tracking Protection'), (11, 'Mobile Ads'), (19, 'Popups')]
inputs, sources = [], []
for number, name in filters:
    url = f'https://filters.adtidy.org/ios/filters/{number}_optimized.txt'
    data = download(url)
    text = data.decode('utf-8-sig')
    if 'AdGuard' not in text[:2000] or len(text.splitlines()) < 100 or '<html' in text[:1000].lower():
        raise ValueError(f'Unexpected filter response: {name}')
    (DEST / f'source-{number}.txt').write_text(text)
    inputs.extend(text.splitlines())
    sources.append({'id': number, 'name': name, 'url': url, 'sha256': hashlib.sha256(data).hexdigest()})
combined = ROOT / 'filters-input.txt'
combined.write_text('\n'.join(inputs), encoding='utf-8')
command = [str(tool), 'convert', '--input-path', str(combined),
           '--safari-version', '16', '--advanced-blocking', 'false']
result = subprocess.run(command, capture_output=True, text=True)
if result.returncode:
    print('Release binary failed; building the same pinned release from source.', flush=True)
    print(result.stderr[-4000:], flush=True)
    converter_source = ROOT / 'converter-source'
    subprocess.run(['git', 'clone', '--depth', '1', '--branch', 'v4.3.0',
                    'https://github.com/AdguardTeam/SafariConverterLib.git', str(converter_source)], check=True)
    subprocess.run(['swift', 'build', '--package-path', str(converter_source),
                    '-c', 'release', '--product', 'ConverterTool'], check=True)
    command[0] = str(converter_source / '.build/release/ConverterTool')
    result = subprocess.run(command, capture_output=True, text=True)
    if result.returncode:
        raise RuntimeError(result.stderr[-8000:])
report = json.loads(result.stdout)
(DEST / 'conversion-report.json').write_text(json.dumps(report, indent=2))
raw = report['safariRulesJSON']
rules = json.loads(raw)
# Keep cookie policy ahead of the converter's exception rules; never split lists
# arbitrarily, since ignore-previous-rules must remain with the rules it overrides.
rules.insert(0, {'trigger': {'url-filter': '.*', 'load-type': ['third-party']},
                 'action': {'type': 'block-cookies'}})
if not 1000 < len(rules) <= 150000:
    raise ValueError(f'Unexpected converted count: {len(rules)}')
# Reject converter truncation where the current result API reports it.
if report.get('discardedSafariRules', 0) != 0:
    raise ValueError('Converter truncated the filters')
(DEST / 'enhanced.json').write_text(json.dumps(rules, separators=(',', ':')))
metadata = {'generatedAt': datetime.datetime.now(datetime.timezone.utc).isoformat(),
            'ruleCount': len(rules), 'converter': 'SafariConverterLib 4.3.0',
            'safariTarget': 16, 'sources': sources}
(DEST / 'metadata.json').write_text(json.dumps(metadata, indent=2))
for filename, url in [
    ('FILTER-LICENSE-LGPL-3.0.txt', 'https://raw.githubusercontent.com/AdguardTeam/FiltersRegistry/master/LICENSE'),
    ('COPYING-GPL-3.0.txt', 'https://raw.githubusercontent.com/AdguardTeam/SafariConverterLib/v4.3.0/LICENSE')]:
    (DEST / filename).write_bytes(download(url))
(DEST / 'NOTICE.txt').write_text('Harbor uses transformed AdGuard Base, Tracking Protection, Mobile Ads and Popups iOS optimized filter lists. Copyright their respective authors. FiltersRegistry: LGPL-3.0; upstream third-party filter components retain their stated licenses. Original source lists, notices and transformation report accompany this app in this folder. ConverterTool 4.3.0 is used only during builds and is not bundled. Source: https://github.com/AdguardTeam/FiltersRegistry and https://github.com/AdguardTeam/SafariConverterLib\n')
print(json.dumps(metadata, indent=2))
