# AGENTS.md

## Repository

- This is a standalone Swift Package Manager macOS menu-bar app; it is not part of `manatel-bot-api`.
- The package requires macOS 13+ and Swift tools 6.0; there are no external package dependencies.
- The app entry point is `Sources/OpenCodeGoWidget/OpenCodeGoWidgetApp.swift` and the executable target is `OpenCodeGoWidget`.
- Keep generated `.build/` and `dist/` output out of commits; both are gitignored.

## Commands

- Run unit tests with `swift test`.
- Build the release executable with `swift build -c release --arch arm64 --arch x86_64` (universal).
- Build the Finder-launchable app bundle with `./scripts/build-app.sh`; the script runs a universal release build first and writes `dist/OpenCode Go Widget.app`.
- Package a release zip plus `SHA256SUMS.txt` with `./scripts/package-release.sh <version>`.
- Sign and notarize (skips without credentials) with `./scripts/sign-and-notarize.sh <version>`; it requires `SIGNING_IDENTITY`, `APPLE_ID`, `APPLE_APP_PASSWORD`, and `APPLE_TEAM_ID`.
- Launch the generated app with `open "dist/OpenCode Go Widget.app"`.
- The bundle script copies `.build/apple/Products/Release/OpenCodeGoWidget`, a universal (`arm64` + `x86_64`) binary.

## Architecture

- `UsageAPIClient` performs the authenticated GET request to `https://opencode.ai/zen/go/v1/usage` and decodes `UsageResponse`; it stores an injectable `URLSession` for deterministic tests.
- `UsageViewModel` owns loading, errors, Keychain access, manual refresh, the refresh loop, threshold notifications, and the menu-bar metric.
- `PreferencesStore` persists the refresh interval, menu-bar metric, and notification toggles (70/85/90) in `UserDefaults`.
- `UsageHistoryStore` persists local usage snapshots (percentages + timestamps only, never the API key) and feeds the Swift Charts history graph.
- `NotificationScheduler` wraps `UNUserNotificationCenter` behind the `NotificationScheduling` protocol so tests can inject a mock.
- SwiftUI views under `Views/` render the menu-bar window and API-key settings.
- `KeychainService` is the only credential persistence layer; never print, log, or write the API key to project files.
- The usage decoder accepts both lowercase `usage` and the API's observed capitalized `Usage` root key; the endpoint contract is documented in `docs/OPENCODE-GO-API.md`.
- `percent` values are treated as 0-100 percentages; UI renders `validatedPercent`, which clamps to `0...100`. Thresholds are green below 70, orange from 70 to below 90, and red at 90+.
- `Resources/AppIcon.icns` is generated with `swift scripts/generate-icon.swift`; the bundle script copies it into the `.app`.

## Configuration

- Configure the key from the app's `Configuracion`/settings UI; it is stored in macOS Keychain under service `com.manatel.opencode-go-widget` and account `api-key`.
- Do not add an `.env` fallback unless the security model is deliberately revisited; the current app has no environment-variable configuration.

## Verification

- After source changes, run `swift test` and `swift build -c release --arch arm64 --arch x86_64`.
- If the app-bundle behavior changes, also run `./scripts/build-app.sh` and verify the generated path before opening it.
- Keep API-client tests deterministic by injecting a custom endpoint/session rather than calling the live OpenCode API.
- CI (`.github/workflows/ci.yml`) runs tests and the universal build on every push/PR; the release workflow builds, optionally signs, packages, and attaches artifacts on `v*` tags.
