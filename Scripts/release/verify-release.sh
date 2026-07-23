#!/bin/bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
VERSION="$(tr -d '[:space:]' < "$ROOT_DIR/VERSION")"
OUTPUT_DIR="${OUTPUT_DIR:-$ROOT_DIR/release/v$VERSION}"
ZIP_PATH="$OUTPUT_DIR/WhoopScope-$VERSION-macOS.zip"
CHECKSUM_PATH="$OUTPUT_DIR/SHA256SUMS.txt"
TEMP_DIR="$(mktemp -d "${TMPDIR:-/tmp}/whoopscope-release.XXXXXX")"

cleanup() {
  rm -rf "$TEMP_DIR"
}
trap cleanup EXIT

[[ -f "$ZIP_PATH" ]] || { echo "Missing $ZIP_PATH" >&2; exit 1; }
[[ -f "$CHECKSUM_PATH" ]] || { echo "Missing $CHECKSUM_PATH" >&2; exit 1; }

(
  cd "$OUTPUT_DIR"
  shasum -a 256 -c "$(basename "$CHECKSUM_PATH")"
)

ditto -x -k "$ZIP_PATH" "$TEMP_DIR"
APP_PATH="$TEMP_DIR/WhoopScope-$VERSION/WhoopScope.app"

[[ -d "$APP_PATH" ]] || { echo "Archive does not contain WhoopScope.app" >&2; exit 1; }
codesign --verify --deep --strict --verbose=2 "$APP_PATH"
xcrun stapler validate "$APP_PATH"
spctl --assess --type execute --verbose=4 "$APP_PATH"

ACTUAL_VERSION=$(/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" "$APP_PATH/Contents/Info.plist")
[[ "$ACTUAL_VERSION" == "${VERSION%%-*}" ]] || {
  echo "Bundle version $ACTUAL_VERSION does not match $VERSION" >&2
  exit 1
}

echo "Verified WhoopScope $VERSION"
