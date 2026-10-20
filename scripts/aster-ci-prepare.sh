#!/usr/bin/env bash
set -euo pipefail

aster_root=$(cd "$(dirname "$0")/.." && pwd)
cd "$aster_root"
[ "$(uname -s)" = Darwin ] || { echo 'Aster native preparation requires macOS and Xcode.' >&2; exit 1; }
command -v node >/dev/null
command -v npm >/dev/null
command -v xcodebuild >/dev/null
command -v python3 >/dev/null
python3 scripts/aster-generate-support.py --check

nimbus_ref=47b9efa112d5dc6adee6b757703742e5c19022f6
nimbus_script_sha=443a72235811e6367914f80b2eacc900d55913442cb9d594930170e0e2cc5da4
nimbus_version=159.20260930050300
nimbus_binary_sha=4aadd1abc09b1ab1a0b25b78fa5e269957278238fd0fa24b97d9444af3d01864

package_version=$(python3 - <<'PY'
import pathlib, re
source = pathlib.Path('MozillaRustComponents/Package.swift').read_text()
print(re.search(r'let version = "([^"]+)"', source).group(1).replace('.0.', '.'))
PY
)
[ "$package_version" = "$nimbus_version" ] || {
  echo 'The MozillaRustComponents version changed. Update the pinned Nimbus generator version and checksum.' >&2
  exit 1
}

aster_temp=$(mktemp -d "${TMPDIR:-/tmp}/aster-prepare.XXXXXX")
trap 'rm -rf "$aster_temp"' EXIT
curl --proto '=https' --tlsv1.2 --fail --silent --show-error --location --retry 3 \
  "https://raw.githubusercontent.com/mozilla/application-services/$nimbus_ref/components/nimbus/ios/scripts/nimbus-fml.sh" \
  -o "$aster_temp/nimbus-fml.sh"
[ "$(shasum -a 256 "$aster_temp/nimbus-fml.sh" | cut -d ' ' -f 1)" = "$nimbus_script_sha" ] || {
  echo 'Nimbus generator script checksum mismatch.' >&2
  exit 1
}
mkdir -p firefox-ios/bin
cp "$aster_temp/nimbus-fml.sh" firefox-ios/bin/nimbus-fml.sh
chmod +x firefox-ios/bin/nimbus-fml.sh
printf 'export AS_VERSION=%s\n' "$nimbus_version" > firefox-ios/bin/nimbus-fml-configuration.local.sh

nimbus_binary_dir="$aster_root/firefox-ios/build/nimbus/$nimbus_version/bin"
mkdir -p "$nimbus_binary_dir"
curl --proto '=https' --tlsv1.2 --fail --silent --show-error --location --retry 3 \
  "https://firefox-ci-tc.services.mozilla.com/api/index/v1/task/project.application-services.v2.nimbus-fml.$nimbus_version/artifacts/public%2Fbuild%2Fnimbus-fml.zip" \
  -o "$nimbus_binary_dir/nimbus-fml.zip"
[ "$(shasum -a 256 "$nimbus_binary_dir/nimbus-fml.zip" | cut -d ' ' -f 1)" = "$nimbus_binary_sha" ] || {
  echo 'Nimbus generator binary checksum mismatch.' >&2
  exit 1
}
printf '%s  nimbus-fml.zip\n' "$nimbus_binary_sha" > "$nimbus_binary_dir/nimbus-fml.sha256"
case "$(uname -m)" in
  arm64) nimbus_arch=aarch64-apple-darwin ;;
  x86_64) nimbus_arch=x86_64-apple-darwin ;;
  *) echo 'Unsupported macOS runner architecture.' >&2; exit 1 ;;
esac
unzip -q -o -j "$nimbus_binary_dir/nimbus-fml.zip" "$nimbus_arch/release/nimbus-fml" -d "$nimbus_binary_dir"
chmod +x "$nimbus_binary_dir/nimbus-fml"

bash scripts/install-swiftlint.sh >/dev/null
npm ci --no-audit --no-fund
npm run build
python3 Scripts/aster/prepare_ad_filters.py
swift Scripts/aster/validate_ad_filters.swift firefox-ios/Client/Assets/AsterFilters/ads.json

printf 'Prepared pinned Nimbus generator, SwiftLint, user scripts, and verified advertising rules and bundled support pages.\n'
