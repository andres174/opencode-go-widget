# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- Menu bar widget that shows rolling, weekly, and monthly OpenCode Go usage.
- API key stored in the macOS Keychain (service `com.manatel.opencode-go-widget`).
- Automatic refresh loop with configurable interval (5/15/30/60 minutes).
- Manual refresh, offline state, and last-updated timestamp.
- Notifications when monthly usage crosses 70%, 85%, or 90% (opt-in per threshold).
- Selectable menu bar metric (rolling/weekly/monthly).
- Local usage history with a Swift Charts graph (percentages and timestamps only).
- Settings UI with API key management, including key deletion.
- Universal (`arm64` + `x86_64`) app bundle with app icon.
- Deterministic test suite: HTTP client, model validation, view model lifecycle,
  preferences, notifications, and history (no network access required).
- CI workflow (tests + universal build) and release workflow (package, optional
  signing and notarization, checksums, GitHub Release).

## [0.1.0] - unreleased

First public release.
