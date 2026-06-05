#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

BUILD_NUMBER=$(grep -E '^version:' pubspec.yaml | sed -E 's/.*\+([0-9]+).*/\1/')
if [[ -z "$BUILD_NUMBER" || "$BUILD_NUMBER" == *version* ]]; then
  echo "Could not parse build number from pubspec.yaml (expected version: x.y.z+N)" >&2
  exit 1
fi

flutter build appbundle "$@"

AAB_SRC=$(find build/app/outputs/bundle -name '*.aab' -print -quit)
if [[ -z "$AAB_SRC" ]]; then
  echo "No .aab found under build/app/outputs/bundle" >&2
  exit 1
fi

mkdir -p dist
DEST="dist/luftdaten-${BUILD_NUMBER}.aab"
cp "$AAB_SRC" "$DEST"
echo "App bundle copied to $DEST"
