#!/bin/bash
set -e
BASE="$(cd "$(dirname "$0")" && pwd)"
mkdir -p "$BASE/data/gallery/upload" "$BASE/data/gallery/thumbs" "$BASE/data/gallery/profile"
mkdir -p "$BASE/data/gallery/backups" "$BASE/data/gallery/library" "$BASE/data/gallery/encoded-video"
for dir in upload thumbs profile backups library encoded-video; do
    touch "$BASE/data/gallery/$dir/.immich"
done
