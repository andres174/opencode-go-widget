# Contributing

Thanks for your interest in contributing to OpenCode Go Widget.

## Setup

- macOS 13+ with Xcode 15+ (Swift tools 6.0).
- No external dependencies; `swift build` resolves everything.

## Validation commands

```bash
swift test                                   # unit tests (no network access needed)
swift build -c release --arch arm64 --arch x86_64   # universal release build
./scripts/build-app.sh                       # Finder-launchable app bundle in dist/
```

## Pull request process

1. Open an issue first for anything larger than a small fix so the change can be discussed.
2. Branch from `main` and keep the change focused.
3. Add or update tests for behavioral changes. HTTP tests must mock responses with a custom `URLProtocol`; never call the live OpenCode API from tests.
4. Run the validation commands above before opening the PR.
5. CI must be green before merging.

## Security constraints

- Never commit the API key or any credentials. The app reads the key from the macOS Keychain only.
- The API key must never appear in logs, tests, screenshots, or CI artifacts.
- Keep `KeychainService` the only credential persistence layer.

## Style

- SwiftUI and Swift concurrency, targeting macOS 13.
- UI text is in English.
- No comments unless they explain something non-obvious.
