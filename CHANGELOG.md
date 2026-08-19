# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.3.0] - 2026-08-19

### Changed

- Settings opens inside the menu bar popover (Back to return) so the panel
  stays open while you edit preferences. Cmd+, still opens the Settings window.
- History is a full-width control with the chevron on the right, and the chart
  uses the selected metric's threshold color plus a metric caption.
- Manual refresh keeps the last usage on screen; a later network or API error
  shows a banner instead of replacing the metrics.
- The menu bar percentage uses the same green / orange / red threshold colors
  as the usage rows.

### Fixed

- Clicking Settings presented a sheet that dismissed the MenuBarExtra window.
- History could only be expanded by clicking the disclosure chevron.

## [0.2.1] - 2026-08-14

### Fixed

- Parse reset timestamps containing fractional seconds, so the UI no longer
  falls back to raw ISO 8601 strings.

## [0.2.0] - 2026-08-14

### Changed

- Reset dates are now shown in a friendly, relative format that updates every
  minute: "Resets now", "Resets in 34 minutes", "Resets in 4 hours",
  "Resets tomorrow", "Resets in 3 days", or the exact date beyond a week.
  Hovering the text shows the exact date and time; VoiceOver announces it too.

## [0.1.0] - 2026-08-14

First public release.
