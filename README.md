# OpenCode Go Widget

A macOS menu bar widget that checks your OpenCode Go usage and stores the API key in the system Keychain.

## Install

1. Download `OpenCodeGoWidget-<version>-universal.zip` from the latest GitHub release.
2. Unzip it and drag `OpenCode Go Widget.app` into `/Applications` (or anywhere you like).
3. Right-click the app and choose `Open` the first time to confirm you trust it (Gatekeeper).
4. Open the menu bar icon, choose `Settings`, and paste your OpenCode Go API key.

The widget runs only in the menu bar; it has no Dock icon.

## Uninstall

1. Quit the app from the menu bar.
2. Delete `OpenCode Go Widget.app`.
3. Remove the API key: open Keychain Access, search for `com.manatel.opencode-go-widget`, and delete the `api-key` item.
4. Optionally clear preferences and history:
   ```bash
   defaults delete com.manatel.opencode-go-widget
   ```

## Requirements

- macOS 13 or later
- Xcode 15 or later

## Run

```bash
swift run
```

On first launch, open `Settings` and enter your API key. The app queries the endpoint every 15 minutes and also supports manual refresh.

## Settings

- **Refresh interval**: choose between 5, 15, 30 and 60 minutes.
- **Menu bar metric**: pick which usage window (rolling, weekly or monthly) shows in the menu bar and in the history chart.
- **Usage notifications**: opt in to get notified when monthly usage crosses 70%, 85% or 90%. Notifications fire only when a threshold is crossed, not on every refresh.
- **Delete API key**: remove the stored key and local usage history from the Keychain and preferences.

## Test

```bash
swift test
```

Tests are deterministic and run without internet access: HTTP responses are mocked with a custom `URLProtocol`, and the Keychain is injected as a mock.

## Build

```bash
swift build -c release --arch arm64 --arch x86_64
```

The universal binary is written to `.build/apple/Products/Release/OpenCodeGoWidget` (Apple Silicon and Intel).

To create an app you can open from Finder:

```bash
chmod +x scripts/build-app.sh
./scripts/build-app.sh
open "dist/OpenCode Go Widget.app"
```

## Security

The API key is never written to project files or logs. It is stored using Keychain Services under service `com.manatel.opencode-go-widget` and account `api-key`. Local usage history only stores percentages and timestamps — never the API key or raw API responses — and is removed when the API key is deleted.

## API

See [`docs/OPENCODE-GO-API.md`](docs/OPENCODE-GO-API.md) for the endpoint contract the widget relies on.

## Contributing

See [`CONTRIBUTING.md`](CONTRIBUTING.md) and [`SECURITY.md`](SECURITY.md) before contributing. The roadmap is in [`docs/ROADMAP.md`](docs/ROADMAP.md).

## License

[MIT](LICENSE)

## Roadmap

See [`docs/ROADMAP.md`](docs/ROADMAP.md) for future improvements and the open source release plan.
