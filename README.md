# 嗅你行 (OdorWatch)

An indoor odor detection and tracking app for iOS/macOS built with SwiftUI.

## Features

- Track 10 types of indoor odors (smoke, gas, mold, chemical, etc.)
- Record intensity, location, and notes for each odor event
- Pattern analysis engine to establish baseline air quality
- Room-based odor profiling
- Persistent storage via UserDefaults

## Tech Stack

- **Language:** Swift 5.9
- **Framework:** SwiftUI
- **Platform:** iOS 17+ / macOS 14+

## Project Structure

```
Sources/OdorWatch/
  App/              — App entry point
  Models/           — Data models
  Services/         — Business logic (storage, pattern engine, notifications)
    Protocols/      — Service protocols for dependency injection
  ViewModels/       — Observable view models
  Views/            — SwiftUI views (split by feature)
  Extensions/       — Cross-platform helpers
Tests/OdorWatchTests/
```

## Development

```bash
# Build library + app
swift build

# Run app (macOS)
swift run OdorWatchApp

# Test
swift test

# Lint
swiftlint

# Generate Xcode project
xcodegen
```
