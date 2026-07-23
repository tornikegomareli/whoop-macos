#!/bin/bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
VERSION="$(tr -d '[:space:]' < "$ROOT_DIR/VERSION")"
TAG="v$VERSION"
OUTPUT_DIR="${OUTPUT_DIR:-$ROOT_DIR/release/$TAG}"
ZIP_PATH="$OUTPUT_DIR/WhoopScope-$VERSION-macOS.zip"
CHECKSUM_PATH="$OUTPUT_DIR/SHA256SUMS.txt"
NOTES_PATH="$ROOT_DIR/docs/releases/$TAG.md"

command -v gh >/dev/null 2>&1 || { echo "Missing gh" >&2; exit 1; }
[[ -f "$ZIP_PATH" ]] || { echo "Missing $ZIP_PATH" >&2; exit 1; }
[[ -f "$CHECKSUM_PATH" ]] || { echo "Missing $CHECKSUM_PATH" >&2; exit 1; }
[[ -f "$NOTES_PATH" ]] || { echo "Missing $NOTES_PATH" >&2; exit 1; }

"$ROOT_DIR/Scripts/release/verify-release.sh"

git -C "$ROOT_DIR" diff --quiet
git -C "$ROOT_DIR" diff --cached --quiet
git -C "$ROOT_DIR" fetch origin main
[[ "$(git -C "$ROOT_DIR" rev-parse HEAD)" == "$(git -C "$ROOT_DIR" rev-parse origin/main)" ]] || {
  echo "HEAD must match origin/main" >&2
  exit 1
}

if git -C "$ROOT_DIR" rev-parse "$TAG" >/dev/null 2>&1; then
  [[ "$(git -C "$ROOT_DIR" rev-list -n 1 "$TAG")" == "$(git -C "$ROOT_DIR" rev-parse HEAD)" ]] || {
    echo "$TAG exists on a different commit" >&2
    exit 1
  }
else
  git -C "$ROOT_DIR" tag -a "$TAG" -m "WhoopScope $VERSION"
  git -C "$ROOT_DIR" push origin "$TAG"
fi

gh release create "$TAG" \
  "$ZIP_PATH" \
  "$CHECKSUM_PATH" \
  --repo tornikegomareli/whoop-macos \
  --title "WhoopScope $VERSION" \
  --notes-file "$NOTES_PATH" \
  --prerelease \
  --verify-tag

echo "Published https://github.com/tornikegomareli/whoop-macos/releases/tag/$TAG"
