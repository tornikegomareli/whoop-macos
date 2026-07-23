#!/bin/bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
VERSION="$(tr -d '[:space:]' < "$ROOT_DIR/VERSION")"
TAG="v$VERSION"
APP_VERSION="${VERSION%%-*}"
OUTPUT_DIR="${OUTPUT_DIR:-$ROOT_DIR/release/$TAG}"
ARCHIVE_PATH="$OUTPUT_DIR/WhoopScope.xcarchive"
STAGING_DIR="$OUTPUT_DIR/WhoopScope-$VERSION"
APP_PATH="$STAGING_DIR/WhoopScope.app"
ZIP_PATH="$OUTPUT_DIR/WhoopScope-$VERSION-macOS.zip"
CHECKSUM_PATH="$OUTPUT_DIR/SHA256SUMS.txt"
SIGNING_IDENTITY="${SIGNING_IDENTITY:-Developer ID Application}"
DEVELOPMENT_TEAM="${DEVELOPMENT_TEAM:-}"
NOTARY_PROFILE="${NOTARY_PROFILE:-}"
BUNDLE_PREFIX="${BUNDLE_PREFIX:-com.whoopscope}"
APP_GROUP="${APP_GROUP:-}"

fail() {
  echo "error: $*" >&2
  exit 1
}

for command in mise xcodebuild codesign ditto shasum xcrun spctl security; do
  command -v "$command" >/dev/null 2>&1 || fail "missing required command: $command"
done

[[ "$VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+(-[0-9A-Za-z.-]+)?$ ]] ||
  fail "VERSION must use semantic versioning"

grep -q "private let appVersion = \"$APP_VERSION\"" "$ROOT_DIR/Project.swift" ||
  fail "Project.swift appVersion does not match VERSION"

if [[ "${ALLOW_DIRTY:-0}" != "1" ]]; then
  git -C "$ROOT_DIR" diff --quiet || fail "working tree has unstaged changes"
  git -C "$ROOT_DIR" diff --cached --quiet || fail "working tree has staged changes"
fi

[[ ! -e "$OUTPUT_DIR" ]] ||
  fail "$OUTPUT_DIR already exists; move it aside before rebuilding"

[[ -n "$DEVELOPMENT_TEAM" ]] ||
  fail "set DEVELOPMENT_TEAM to the team that owns the Developer ID certificate, bundle IDs, and App Group"
[[ -n "$NOTARY_PROFILE" ]] ||
  fail "set NOTARY_PROFILE to an xcrun notarytool Keychain profile"
[[ -n "$APP_GROUP" ]] ||
  APP_GROUP="$DEVELOPMENT_TEAM.com.whoopscope.shared"

security find-identity -v -p codesigning |
  grep -F "Developer ID Application:" |
  grep -F "($DEVELOPMENT_TEAM)" >/dev/null ||
  fail "no Developer ID Application identity is installed for team $DEVELOPMENT_TEAM"

xcrun notarytool history --keychain-profile "$NOTARY_PROFILE" >/dev/null 2>&1 ||
  fail "notarytool Keychain profile '$NOTARY_PROFILE' is missing or invalid"

mkdir -p "$OUTPUT_DIR" "$STAGING_DIR"

echo "Generating the Tuist workspace"
mise exec -- tuist install
TUIST_WHOOPSCOPE_DEVELOPMENT_TEAM="$DEVELOPMENT_TEAM" \
TUIST_WHOOPSCOPE_BUNDLE_PREFIX="$BUNDLE_PREFIX" \
TUIST_WHOOPSCOPE_APP_GROUP="$APP_GROUP" \
mise exec -- tuist generate --no-open

echo "Archiving $TAG with Developer ID"
xcodebuild archive \
  -workspace "$ROOT_DIR/WhoopScope.xcworkspace" \
  -scheme WhoopScope \
  -configuration Release \
  -destination "generic/platform=macOS" \
  -archivePath "$ARCHIVE_PATH" \
  -allowProvisioningUpdates \
  DEVELOPMENT_TEAM="$DEVELOPMENT_TEAM" \
  CODE_SIGN_STYLE=Automatic \
  CODE_SIGN_IDENTITY="$SIGNING_IDENTITY" \
  ENABLE_HARDENED_RUNTIME=YES \
  CURRENT_PROJECT_VERSION=1 \
  MARKETING_VERSION="$APP_VERSION"

BUILT_APP="$ARCHIVE_PATH/Products/Applications/WhoopScopeMac.app"
[[ -d "$BUILT_APP" ]] || fail "archive did not contain $BUILT_APP"

ditto "$BUILT_APP" "$APP_PATH"
cp "$ROOT_DIR/LICENSE" "$ROOT_DIR/NOTICE" "$ROOT_DIR/THIRD_PARTY_NOTICES.md" "$STAGING_DIR/"

echo "Verifying Developer ID signatures"
codesign --verify --deep --strict --verbose=2 "$APP_PATH"
codesign -dv --verbose=4 "$APP_PATH" 2>&1 | grep -q "Runtime Version" ||
  fail "hardened runtime was not present"
codesign -dv --verbose=4 "$APP_PATH" 2>&1 | grep -q "Authority=Developer ID Application" ||
  fail "app is not signed with Developer ID Application"

NOTARY_ZIP="$OUTPUT_DIR/WhoopScope-$VERSION-notarization.zip"
ditto -c -k --keepParent "$APP_PATH" "$NOTARY_ZIP"

echo "Submitting to Apple notary service"
xcrun notarytool submit "$NOTARY_ZIP" \
  --keychain-profile "$NOTARY_PROFILE" \
  --wait

echo "Stapling and assessing the app"
xcrun stapler staple "$APP_PATH"
xcrun stapler validate "$APP_PATH"
spctl --assess --type execute --verbose=4 "$APP_PATH"

ditto -c -k --keepParent "$STAGING_DIR" "$ZIP_PATH"
(
  cd "$OUTPUT_DIR"
  shasum -a 256 "$(basename "$ZIP_PATH")" > "$(basename "$CHECKSUM_PATH")"
)

rm "$NOTARY_ZIP"

echo
echo "Release ready:"
echo "  $ZIP_PATH"
echo "  $CHECKSUM_PATH"
