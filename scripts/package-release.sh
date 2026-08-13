#!/usr/bin/env bash
set -euo pipefail

VERSION="${1:-0.1.0}"
APP_NAME="OpenCode Go Widget"
ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
APP_DIR="$ROOT_DIR/dist/$APP_NAME.app"
ARCHIVE="OpenCodeGoWidget-$VERSION-universal.zip"
CHECKSUMS="SHA256SUMS.txt"

if [ ! -d "$APP_DIR" ]; then
    echo "App bundle not found; running build-app.sh first."
    "$ROOT_DIR/scripts/build-app.sh"
fi

rm -f "$ROOT_DIR/dist/$ARCHIVE" "$ROOT_DIR/dist/$CHECKSUMS"

xattr -cr "$APP_DIR" 2>/dev/null || true
ditto --norsrc -c -k --keepParent "$APP_DIR" "$ROOT_DIR/dist/$ARCHIVE"

(
    cd "$ROOT_DIR/dist"
    shasum -a 256 "$ARCHIVE" > "$CHECKSUMS"
)

echo "Created: dist/$ARCHIVE"
echo "Checksums: dist/$CHECKSUMS"
cat "$ROOT_DIR/dist/$CHECKSUMS"
