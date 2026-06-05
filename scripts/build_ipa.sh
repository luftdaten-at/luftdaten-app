#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

BUILD_NUMBER=$(grep -E '^version:' pubspec.yaml | sed -E 's/.*\+([0-9]+).*/\1/')
if [[ -z "$BUILD_NUMBER" || "$BUILD_NUMBER" == *version* ]]; then
  echo "Could not parse build number from pubspec.yaml (expected version: x.y.z+N)" >&2
  exit 1
fi

flutter build ipa "$@"

IPA_SRC=$(find build/ios/ipa -maxdepth 1 -name '*.ipa' -print -quit)
if [[ -z "$IPA_SRC" ]]; then
  echo "No .ipa found under build/ios/ipa" >&2
  exit 1
fi

mkdir -p dist
DEST="dist/luftdaten-${BUILD_NUMBER}.ipa"
cp "$IPA_SRC" "$DEST"
echo "IPA copied to $DEST"
