#!/usr/bin/env bash
set -euo pipefail

# Signs and notarizes the app bundle with a Developer ID certificate.
# Skips silently when credentials are not configured so the same workflow
# can run in forks and local machines without signing secrets.
#
# Required environment variables:
#   SIGNING_IDENTITY   e.g. "Developer ID Application: Name (TEAMID)"
#   APPLE_ID           Apple ID used for notarization
#   APPLE_APP_PASSWORD app-specific password for notarization
#   APPLE_TEAM_ID      team identifier
#
# Output:
#   dist/OpenCodeGoWidget-<VERSION>-universal.zip (signed and stapled)
#   dist/SHA256SUMS.txt

VERSION="${1:-0.1.0}"
APP_NAME="OpenCode Go Widget"
ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
APP_DIR="$ROOT_DIR/dist/$APP_NAME.app"
ARCHIVE="OpenCodeGoWidget-$VERSION-universal.zip"
CHECKSUMS="SHA256SUMS.txt"

if [ -z "${SIGNING_IDENTITY:-}" ] || [ -z "${APPLE_ID:-}" ] || [ -z "${APPLE_APP_PASSWORD:-}" ] || [ -z "${APPLE_TEAM_ID:-}" ]; then
    echo "Signing credentials not configured; skipping signing and notarization."
    exit 0
fi

if [ ! -d "$APP_DIR" ]; then
    echo "App bundle not found; run scripts/build-app.sh first." >&2
    exit 1
fi

echo "Signing $APP_DIR with identity '$SIGNING_IDENTITY'..."
xattr -cr "$APP_DIR" 2>/dev/null || true
codesign --deep --force --options runtime --timestamp --sign "$SIGNING_IDENTITY" "$APP_DIR"
codesign --verify --deep --strict "$APP_DIR"

echo "Zipping for notarization submission..."
rm -f "$ROOT_DIR/dist/$ARCHIVE"
ditto --norsrc -c -k --keepParent "$APP_DIR" "$ROOT_DIR/dist/$ARCHIVE"

echo "Submitting to notary service..."
xcrun notarytool submit "$ROOT_DIR/dist/$ARCHIVE" \
    --apple-id "$APPLE_ID" \
    --password "$APPLE_APP_PASSWORD" \
    --team-id "$APPLE_TEAM_ID" \
    --wait

echo "Stapling ticket..."
xcrun stapler staple "$APP_DIR"
xcrun stapler validate "$APP_DIR"

echo "Re-zipping stapled app..."
rm -f "$ROOT_DIR/dist/$ARCHIVE"
ditto --norsrc -c -k --keepParent "$APP_DIR" "$ROOT_DIR/dist/$ARCHIVE"

(
    cd "$ROOT_DIR/dist"
    shasum -a 256 "$ARCHIVE" > "$CHECKSUMS"
)

echo "Signed and notarized: dist/$ARCHIVE"
cat "$ROOT_DIR/dist/$CHECKSUMS"
