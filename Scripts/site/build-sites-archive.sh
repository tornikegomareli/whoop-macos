#!/bin/bash

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
WEBSITE="$ROOT/Website"
VERSION="$(tr -d '[:space:]' < "$ROOT/VERSION")"
OUTPUT_DIR="$ROOT/release/site"
ARCHIVE="$OUTPUT_DIR/whoopscope-site-$VERSION.tar.gz"
STAGE="$(mktemp -d "${TMPDIR:-/tmp}/whoopscope-site.XXXXXX")"

cleanup() {
  find "$STAGE" -depth -delete
}
trap cleanup EXIT

if [[ ! -f "$ROOT/.openai/hosting.json" ]]; then
  echo "Missing .openai/hosting.json." >&2
  exit 1
fi

if [[ -n "$(git -C "$ROOT" status --porcelain --untracked-files=no)" ]]; then
  echo "Tracked files must be clean before packaging the site." >&2
  exit 1
fi

npm --prefix "$WEBSITE" ci
npm --prefix "$WEBSITE" audit
npm --prefix "$WEBSITE" run check
npm --prefix "$WEBSITE" run build:cloudflare

mkdir -p "$OUTPUT_DIR"
mkdir -p "$STAGE/.openai"

cp -R "$WEBSITE/.open-next" "$STAGE/.open-next"
cp "$WEBSITE/wrangler.jsonc" "$STAGE/wrangler.jsonc"
cp "$ROOT/.openai/hosting.json" "$STAGE/.openai/hosting.json"

tar -C "$STAGE" -czf "$ARCHIVE" .
shasum -a 256 "$ARCHIVE" > "$ARCHIVE.sha256"

echo "$ARCHIVE"
