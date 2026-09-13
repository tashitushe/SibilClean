# SibilClean

A lightweight native macOS app to find and remove leftover files from uninstalled or unwanted apps — caches, preferences, logs, and other data left behind in `~/Library`.

## Features

- Scans `/Applications` and `~/Applications` for installed apps
- Finds related leftover files by bundle identifier (Application Support, Caches, Preferences, Logs, Saved Application State, Containers, LaunchAgents, etc.)
- Select one or more apps and remove them — along with their leftovers — to the Trash
- Native SwiftUI interface with Liquid Glass design

## Requirements

- macOS 26 (Tahoe) or later
- Xcode 26+

## Build & Run

```bash
./Scripts/make_app.sh debug
open build/SibilClean.app
```

## License

MIT
