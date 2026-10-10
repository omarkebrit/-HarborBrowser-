#!/usr/bin/env bash
# Invoked only by the explicitly selected signing/upload jobs. Never enable tracing.
set -euo pipefail
set +x
umask 077

fail() {
  printf '::error::%s\n' "$1" >&2
  exit 1
}

require_secret() {
  [ -n "${!1:-}" ] || fail "Missing GitHub Actions secret: $1. Configure repository secrets before requesting this delivery."
}

[ -n "${RUNNER_TEMP:-}" ] || fail 'RUNNER_TEMP is required. Run this script on a GitHub macOS runner.'
state_dir="$RUNNER_TEMP/harbor-signing-${GITHUB_RUN_ID:-local}-${GITHUB_RUN_ATTEMPT:-1}"
keychain_path="$state_dir/ci.keychain-db"

cleanup() {
  if [ -f "$state_dir/original-keychains.txt" ]; then
    original_keychains=()
    while IFS= read -r original_keychain; do
      original_keychains+=("$original_keychain")
    done < <(python3 -c 'import shlex,sys; print("\n".join(shlex.split(open(sys.argv[1]).read())))' "$state_dir/original-keychains.txt")
    if [ "${#original_keychains[@]}" -gt 0 ]; then
      security list-keychains -d user -s "${original_keychains[@]}" >/dev/null 2>&1 || true
    fi
  fi
  if [ -f "$keychain_path" ]; then
    security delete-keychain "$keychain_path" >/dev/null 2>&1 || true
  fi
  if [ -f "$state_dir/profile-paths.txt" ]; then
    while IFS= read -r installed_profile; do
      rm -f -- "$installed_profile"
    done < "$state_dir/profile-paths.txt"
  fi
  rm -rf -- "$state_dir"
}

check_xcode() {
  [ "$(uname -s)" = Darwin ] || fail 'Apple signing and upload require the GitHub-hosted macOS runner.'
  command -v xcodebuild >/dev/null || fail 'Xcode is not installed on this runner.'
  xcode_major=$(xcodebuild -version | awk '/^Xcode / { split($2, version, "."); print version[1]; exit }')
  sdk_major=$(xcrun --sdk iphoneos --show-sdk-version | cut -d . -f 1)
  [[ "$xcode_major" =~ ^[0-9]+$ && "$sdk_major" =~ ^[0-9]+$ ]] || fail 'Could not determine the Xcode/iOS SDK version.'
  [ "$xcode_major" -ge 26 ] && [ "$sdk_major" -ge 26 ] || fail 'Apple uploads require Xcode 26 or later and the iOS 26 SDK or later. Select an updated macOS runner/Xcode installation.'
}

case "${1:-}" in
  cleanup)
    cleanup
    exit 0
    ;;
  archive)
    require_secret APPLE_DISTRIBUTION_P12_BASE64
    require_secret APPLE_DISTRIBUTION_P12_PASSWORD
    require_secret APPLE_PROVISIONING_PROFILE_BASE64
    [ -n "${HARBOR_PROJECT:-}" ] && [ -d "$HARBOR_PROJECT" ] || fail 'HARBOR_PROJECT must point to HarborBrowser.xcodeproj.'
    [ -n "${GITHUB_WORKSPACE:-}" ] || fail 'GITHUB_WORKSPACE is required.'
    [[ "${GITHUB_RUN_NUMBER:-}" =~ ^[1-9][0-9]*$ && "${GITHUB_RUN_ATTEMPT:-}" =~ ^[1-9][0-9]*$ ]] || fail 'GitHub run number and attempt are required for a unique build version.'
    check_xcode
    mkdir -p "$state_dir"
    trap cleanup EXIT

    # Decode directly from environment to protected files; never print secret values.
    python3 - "$state_dir" <<'PY'
import base64, binascii, os, pathlib, sys
root = pathlib.Path(sys.argv[1])
for variable, filename in (
    ("APPLE_DISTRIBUTION_P12_BASE64", "distribution.p12"),
    ("APPLE_PROVISIONING_PROFILE_BASE64", "profile.mobileprovision"),
):
    try:
        data = base64.b64decode("".join(os.environ[variable].split()), validate=True)
        if not data:
            raise ValueError()
    except (ValueError, binascii.Error):
        sys.exit(f"::error::{variable} must contain valid, nonempty Base64.")
    (root / filename).write_bytes(data)
PY
    security cms -D -i "$state_dir/profile.mobileprovision" > "$state_dir/profile.plist" || fail 'The provisioning profile could not be decoded. Supply an Apple-issued App Store Connect profile.'

    python3 - "$state_dir" <<'PY'
import datetime, pathlib, plistlib, re, sys
root = pathlib.Path(sys.argv[1])
def reject(message):
    sys.exit("::error::Provisioning profile: " + message)
try:
    profile = plistlib.loads((root / "profile.plist").read_bytes())
except Exception:
    reject("the decoded file is not a valid plist.")
entitlements = profile.get("Entitlements", {})
expiration = profile.get("ExpirationDate")
if not isinstance(expiration, datetime.datetime):
    reject("expiration date is missing.")
if expiration.replace(tzinfo=datetime.timezone.utc) <= datetime.datetime.now(datetime.timezone.utc):
    reject("the profile has expired; issue a new profile in Apple Developer.")
if profile.get("ProvisionedDevices") or profile.get("ProvisionsAllDevices") or entitlements.get("get-task-allow"):
    reject("an App Store Connect distribution profile is required; development, Ad Hoc, and enterprise profiles are unsupported.")
if entitlements.get("beta-reports-active") is not True:
    reject("the profile is not enabled for App Store Connect/TestFlight distribution.")
teams = profile.get("TeamIdentifier", [])
if len(teams) != 1 or not re.fullmatch(r"[A-Z0-9]{10}", teams[0]):
    reject("a single valid Apple team identifier is required.")
team = teams[0]
if entitlements.get("com.apple.developer.team-identifier") != team:
    reject("team identifiers do not match.")
prefixes = profile.get("ApplicationIdentifierPrefix", [])
application_id = entitlements.get("application-identifier", "")
prefix = next((p for p in prefixes if application_id.startswith(p + ".")), None)
if not prefix:
    reject("the application identifier prefix is missing or inconsistent.")
bundle = application_id[len(prefix) + 1:]
if not re.fullmatch(r"[A-Za-z0-9-]+(?:\.[A-Za-z0-9-]+)+", bundle):
    reject("use an explicit app bundle identifier, not a wildcard profile.")
uuid = profile.get("UUID", "")
if not re.fullmatch(r"[A-Fa-f0-9]{8}(?:-[A-Fa-f0-9]{4}){3}-[A-Fa-f0-9]{12}", uuid):
    reject("the profile UUID is invalid.")
if not profile.get("DeveloperCertificates"):
    reject("no distribution certificate is listed.")
for filename, value in (("team-id", team), ("bundle-id", bundle), ("profile-uuid", uuid)):
    (root / filename).write_text(value)
PY

    team_id=$(cat "$state_dir/team-id")
    bundle_id=$(cat "$state_dir/bundle-id")
    profile_uuid=$(cat "$state_dir/profile-uuid")
    keychain_password=$(python3 -c 'import secrets; print(secrets.token_hex(32))')
    security list-keychains -d user > "$state_dir/original-keychains.txt"
    security create-keychain -p "$keychain_password" "$keychain_path"
    security set-keychain-settings -lut 21600 "$keychain_path"
    security unlock-keychain -p "$keychain_password" "$keychain_path"
    security import "$state_dir/distribution.p12" -P "$APPLE_DISTRIBUTION_P12_PASSWORD" \
      -t cert -f pkcs12 -k "$keychain_path" -T /usr/bin/codesign -T /usr/bin/security >/dev/null
    security set-key-partition-list -S apple-tool:,apple: -k "$keychain_password" "$keychain_path" >/dev/null
    original_keychains=()
    while IFS= read -r original_keychain; do
      original_keychains+=("$original_keychain")
    done < <(python3 -c 'import shlex,sys; print("\n".join(shlex.split(open(sys.argv[1]).read())))' "$state_dir/original-keychains.txt")
    security list-keychains -d user -s "$keychain_path" "${original_keychains[@]}"
    security find-identity -v -p codesigning "$keychain_path" > "$state_dir/identities.txt"
    certificate_sha=$(python3 - "$state_dir" <<'PY'
import hashlib, pathlib, plistlib, re, sys
root = pathlib.Path(sys.argv[1])
profile = plistlib.loads((root / "profile.plist").read_bytes())
allowed = {hashlib.sha1(certificate).hexdigest().upper() for certificate in profile["DeveloperCertificates"]}
for line in (root / "identities.txt").read_text().splitlines():
    match = re.search(r'([A-F0-9]{40})\s+"(?:Apple Distribution|iPhone Distribution):', line)
    if match and match.group(1) in allowed:
        print(match.group(1))
        break
else:
    sys.exit("::error::The P12 must contain a valid Apple distribution certificate and its private key, matching the provisioning profile.")
PY
    )
    # Xcode versions use either of these profile directories; remove both on exit.
    for profile_directory in \
      "$HOME/Library/MobileDevice/Provisioning Profiles" \
      "$HOME/Library/Developer/Xcode/UserData/Provisioning Profiles"; do
      mkdir -p "$profile_directory"
      installed_profile="$profile_directory/$profile_uuid.mobileprovision"
      printf '%s\n' "$installed_profile" >> "$state_dir/profile-paths.txt"
      cp "$state_dir/profile.mobileprovision" "$installed_profile"
    done

    build_version="$GITHUB_RUN_NUMBER.$GITHUB_RUN_ATTEMPT"
    archive_path="$state_dir/Harbor.xcarchive"
    export_path="$state_dir/export"
    xcodebuild -project "$HARBOR_PROJECT" -scheme HarborBrowser -configuration Release \
      -sdk iphoneos -destination 'generic/platform=iOS' \
      -archivePath "$archive_path" -derivedDataPath "$state_dir/derived-data" \
      CODE_SIGN_STYLE=Manual DEVELOPMENT_TEAM="$team_id" PRODUCT_BUNDLE_IDENTIFIER="$bundle_id" \
      PROVISIONING_PROFILE_SPECIFIER="$profile_uuid" CODE_SIGN_IDENTITY="$certificate_sha" \
      OTHER_CODE_SIGN_FLAGS="--keychain $keychain_path" CURRENT_PROJECT_VERSION="$build_version" archive

    python3 - "$state_dir/ExportOptions.plist" "$team_id" "$bundle_id" "$profile_uuid" "$certificate_sha" <<'PY'
import plistlib, sys
path, team, bundle, uuid, certificate = sys.argv[1:]
with open(path, "wb") as output:
    plistlib.dump({
        "method": "app-store-connect", "destination": "export", "signingStyle": "manual",
        "teamID": team, "signingCertificate": certificate,
        "provisioningProfiles": {bundle: uuid}, "manageAppVersionAndBuildNumber": False,
    }, output)
PY
    xcodebuild -exportArchive -archivePath "$archive_path" -exportPath "$export_path" \
      -exportOptionsPlist "$state_dir/ExportOptions.plist"
    signed_ipas=("$export_path"/*.ipa)
    [ "${#signed_ipas[@]}" -eq 1 ] && [ -f "${signed_ipas[0]}" ] || fail 'Expected exactly one signed IPA after export.'
    mkdir -p "$GITHUB_WORKSPACE/build-output/signed"
    cp "${signed_ipas[0]}" "$GITHUB_WORKSPACE/build-output/signed/Harbor.ipa"
    printf 'Signed App Store IPA exported. It installs through TestFlight after upload and Apple processing.\n'
    ;;
  upload)
    require_secret ASC_API_KEY_ID
    require_secret ASC_API_ISSUER_ID
    require_secret ASC_API_KEY_P8_BASE64
    [[ "$ASC_API_KEY_ID" =~ ^[A-Z0-9]{10}$ ]] || fail 'ASC_API_KEY_ID must be the 10-character App Store Connect team API key ID.'
    [[ "$ASC_API_ISSUER_ID" =~ ^[A-Fa-f0-9]{8}(-[A-Fa-f0-9]{4}){3}-[A-Fa-f0-9]{12}$ ]] || fail 'ASC_API_ISSUER_ID must be the UUID for that App Store Connect team API key.'
    [ -n "${GITHUB_WORKSPACE:-}" ] || fail 'GITHUB_WORKSPACE is required.'
    signed_ipa="$GITHUB_WORKSPACE/build-output/signed/Harbor.ipa"
    [ -f "$signed_ipa" ] || fail 'The signed IPA artifact is missing. The signed build must succeed before upload.'
    check_xcode
    mkdir -p "$state_dir/private_keys"
    trap cleanup EXIT
    python3 - "$state_dir/private_keys" <<'PY'
import base64, binascii, os, pathlib, sys
try:
    data = base64.b64decode("".join(os.environ["ASC_API_KEY_P8_BASE64"].split()), validate=True)
    if b"-----BEGIN PRIVATE KEY-----" not in data:
        raise ValueError()
except (ValueError, binascii.Error):
    sys.exit("::error::ASC_API_KEY_P8_BASE64 must contain the Base64-encoded App Store Connect .p8 private key.")
(pathlib.Path(sys.argv[1]) / ("AuthKey_" + os.environ["ASC_API_KEY_ID"] + ".p8")).write_bytes(data)
PY
    # altool searches ./private_keys for AuthKey_<key-id>.p8. Avoid verbose token logs.
    cd "$state_dir"
    xcrun altool --validate-app -f "$signed_ipa" -t ios \
      --apiKey "$ASC_API_KEY_ID" --apiIssuer "$ASC_API_ISSUER_ID" --output-format json
    xcrun altool --upload-app -f "$signed_ipa" -t ios \
      --apiKey "$ASC_API_KEY_ID" --apiIssuer "$ASC_API_ISSUER_ID" --output-format json
    printf 'Uploaded to App Store Connect. Wait for Apple processing, then configure TestFlight access. This does not submit an App Store release.\n'
    ;;
  *)
    fail 'Usage: bash scripts/ci-sign-ios.sh archive|upload|cleanup'
    ;;
esac
