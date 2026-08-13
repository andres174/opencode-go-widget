# AGENTS.md

## Repository

- This is a standalone Swift Package Manager macOS menu-bar app; it is not part of `manatel-bot-api`.
- The package requires macOS 13+ and Swift tools 6.0; there are no external package dependencies.
- The app entry point is `Sources/OpenCodeGoWidget/OpenCodeGoWidgetApp.swift` and the executable target is `OpenCodeGoWidget`.
- Keep generated `.build/` and `dist/` output out of commits; both are gitignored.

## Commands

- Run unit tests with `swift test`.
- Build the release executable with `swift build -c release`.
- Build the Finder-launchable app bundle with `./scripts/build-app.sh`; the script runs a release build first and writes `dist/OpenCode Go Widget.app`.
- Launch the generated app with `open "dist/OpenCode Go Widget.app"`.
- The bundle script copies `.build/arm64-apple-macosx/release/OpenCodeGoWidget`, so it currently targets Apple Silicon rather than being a universal build.

## Architecture

- `UsageAPIClient` performs the authenticated GET request to `https://opencode.ai/zen/go/v1/usage` and decodes `UsageResponse`.
- `UsageViewModel` owns loading, errors, Keychain access, manual refresh, and the 15-minute refresh loop.
- SwiftUI views under `Views/` render the menu-bar window and API-key settings.
- `KeychainService` is the only credential persistence layer; never print, log, or write the API key to project files.
- The usage decoder accepts both lowercase `usage` and the API's observed capitalized `Usage` root key.
- `percent` values are treated as 0-100 percentages; UI thresholds are green below 70, orange from 70 to below 90, and red at 90+.

## Configuration

- Configure the key from the app's `Configuracion`/settings UI; it is stored in macOS Keychain under service `com.manatel.opencode-go-widget` and account `api-key`.
- Do not add an `.env` fallback unless the security model is deliberately revisited; the current app has no environment-variable configuration.

## Verification

- After source changes, run `swift test` and `swift build -c release`.
- If the app-bundle behavior changes, also run `./scripts/build-app.sh` and verify the generated path before opening it.
- Keep API-client tests deterministic by injecting a custom endpoint/session rather than calling the live OpenCode API.
