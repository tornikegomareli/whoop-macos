#!/bin/bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
OUTPUT="$ROOT_DIR/docs/media/whoopscope-demo.mp4"

for command in ffmpeg; do
  if ! command -v "$command" >/dev/null 2>&1; then
    echo "Missing required command: $command" >&2
    exit 1
  fi
done

ffmpeg -y -loglevel warning \
  -loop 1 -t 3.8 -i "$ROOT_DIR/docs/images/dashboard.png" \
  -loop 1 -t 3.8 -i "$ROOT_DIR/docs/images/trends.png" \
  -loop 1 -t 3.8 -i "$ROOT_DIR/docs/images/workouts.png" \
  -loop 1 -t 3.8 -i "$ROOT_DIR/docs/images/menu-bar.png" \
  -filter_complex "
    [0:v]scale=1920:1080:force_original_aspect_ratio=decrease,
      pad=1920:1080:(ow-iw)/2:(oh-ih)/2:color=0x111111,setsar=1[v0];
    [1:v]scale=1920:1080:force_original_aspect_ratio=decrease,
      pad=1920:1080:(ow-iw)/2:(oh-ih)/2:color=0x111111,setsar=1[v1];
    [2:v]scale=1920:1080:force_original_aspect_ratio=decrease,
      pad=1920:1080:(ow-iw)/2:(oh-ih)/2:color=0x111111,setsar=1[v2];
    [3:v]scale=1920:1080:force_original_aspect_ratio=decrease,
      pad=1920:1080:(ow-iw)/2:(oh-ih)/2:color=0x111111,setsar=1[v3];
    [v0][v1]xfade=transition=fade:duration=0.6:offset=3.2[x1];
    [x1][v2]xfade=transition=fade:duration=0.6:offset=6.4[x2];
    [x2][v3]xfade=transition=fade:duration=0.6:offset=9.6,
      format=yuv420p[out]
  " \
  -map "[out]" \
  -an \
  -r 30 \
  -c:v libx264 \
  -preset medium \
  -crf 20 \
  -movflags +faststart \
  -t 13.4 \
  "$OUTPUT"

echo "Rendered $OUTPUT"
