# aizen

A native macOS menubar utility that shows real-time remaining usage limits for your AI subscriptions -- with an optional desktop widget.

## Features

- Lives in your menubar with a compact `C:72% G:85%` summary at a glance
- Fetches usage data in real-time every time you open the popover
- Auto-discovers credentials from locally installed CLI tools -- zero configuration needed
- Color-coded progress bars: green (ok), yellow (warning), red (critical)
- Shows reset countdowns for each limit window
- Automatic token refresh when Codex credentials expire
- Extensible provider architecture -- add new AI services by conforming to a single protocol
- Desktop widget (WidgetKit) -- see your usage at a glance without opening the app

## Supported Providers

| Provider | Metrics | Credential Source |
|---|---|---|
| GPT Codex | 5-hour limit, Weekly limit | `~/.codex/auth.json` (via `codex login`) |
| GitHub Copilot | Premium requests remaining | `gh auth token` (via `gh auth login`) |

## Prerequisites

- macOS 15.0 (Sequoia) or later
- Xcode 16+ (to build from source)

For GPT Codex tracking:
- [Codex CLI](https://github.com/openai/codex) installed and authenticated (`codex login`)

For GitHub Copilot tracking:
- [GitHub CLI](https://cli.github.com/) installed and authenticated (`gh auth login`)

The app gracefully handles missing providers -- if a CLI tool isn't installed, it shows setup instructions instead of an error.

## Installation

```bash
git clone https://github.com/benro/aizen.git
cd aizen
open aizen.xcodeproj
```

Build and run from Xcode (Cmd+R). The app appears in your menubar, not in the Dock.

## How It Works

**Codex**: Reads your access token and account ID from `~/.codex/auth.json`, then queries the ChatGPT usage API (`chatgpt.com/backend-api/wham/usage`) for rate limit windows. If the token has expired, it automatically refreshes via the OpenAI OAuth endpoint and writes the new token back to disk.

**Copilot**: Runs `gh auth token` to get your GitHub token, then queries the Copilot internal API (`api.github.com/copilot_internal/user`) for quota snapshots including premium request entitlements and remaining counts.

Both providers use undocumented internal APIs. These may change without notice.

## Adding a Provider

aizen is designed to be extended. To add a new AI service, conform to the `UsageProvider` protocol:

```swift
protocol UsageProvider: Identifiable {
    var id: String { get }
    var name: String { get }
    var iconName: String { get }            // SF Symbol name
    var planType: String? { get }
    var summaryPrefix: String { get }       // Single char for menubar (e.g. "C" for Claude)
    var configurationInstructions: String { get }

    func fetchUsage() async throws -> [UsageItem]
    func isAvailable() -> Bool
    func summaryRemainingPercent(from items: [UsageItem]) -> Int?
}
```

Then register it in `UsageManager.init`:

```swift
self.providers = [
    CodexProvider(credentialManager: credentialManager),
    CopilotProvider(credentialManager: credentialManager),
    YourNewProvider(credentialManager: credentialManager)
]
```

The UI automatically picks up new providers -- no view changes needed.

## Architecture

```
aizen/
  aizenApp.swift              # MenuBarExtra entry point
  Shared/
    WidgetUsageData.swift      # Shared data model (main app ↔ widget)
  Models/
    UsageData.swift            # UsageItem, UsageStatus, ProviderUsageState
    ProviderModels.swift       # Codable models for API responses
  Providers/
    UsageProvider.swift        # Provider protocol + ProviderError
    CodexProvider.swift        # GPT Codex usage fetching
    CopilotProvider.swift      # GitHub Copilot usage fetching
  Services/
    CredentialManager.swift    # Actor: credential reading, token refresh
    UsageManager.swift         # @Observable orchestrator, menubar summary
  Views/
    MenuBarView.swift          # Main popover layout
    ProviderCardView.swift     # Individual provider card
    UsageBarView.swift         # Color-coded progress bar
  Assets.xcassets/
    AppIcon.appiconset/        # App icon (all sizes)
    MenuBarIcon.imageset/      # Monochrome menubar template icon
aizenWidget/
  aizenWidget.swift            # WidgetKit timeline provider + views
  aizenWidgetBundle.swift      # Widget bundle entry point
  WidgetUsageData.swift        # Symlink → Shared/WidgetUsageData.swift
```

## Tech Stack

- SwiftUI with `MenuBarExtra` (`.window` style)
- `@Observable` (Observation framework, no Combine)
- Swift concurrency: `async/await`, `actor` for thread-safe credential access
- [Sparkle 2.x](https://sparkle-project.org/) for OTA auto-updates (single external dependency)
- WidgetKit for desktop widget (shared data via App Groups)

## Desktop Widget

aizen includes a macOS desktop widget that displays your AI usage at a glance. Available in two sizes:

- **Small** -- provider names with remaining percentage and a single progress bar each
- **Medium** -- expanded view with all usage items, individual progress bars, and remaining counts

The widget reads data from the main app via shared `UserDefaults` (App Groups). It refreshes automatically every 15 minutes and immediately whenever the main app fetches new data.

To add the widget: right-click your desktop → Edit Widgets → search for "aizen".

**Note**: The widget does not make API calls directly. You need to open the menubar app at least once so it can write initial data for the widget to display.

## Auto-Update

aizen automatically checks for updates in the background every 24 hours using [Sparkle](https://sparkle-project.org/). A "Check for Updates" button is available in the menubar popover. When an update is available, Sparkle handles the full download, verification, installation, and relaunch -- no manual steps required.

**Note**: Auto-updates only work with signed release builds distributed via GitHub Releases. Development builds from Xcode do not receive updates.

## Releasing

One-time setup (EdDSA keys, Apple certificates, GitHub secrets, GitHub Pages): see [`docs/release-setup.md`](docs/release-setup.md).

To release a new version, create and push a version tag:

```bash
git tag v1.1.0
git push origin v1.1.0
```

GitHub Actions automatically builds, signs, notarizes, creates a GitHub Release with the `.zip` asset, and updates the appcast at `https://darthbenro008.github.io/aizen/appcast.xml`. Running app instances will pick up the update within 24 hours.

## License

MIT

## Acknowledgements

- [CodexBar](https://github.com/steipete/CodexBar) for architecture inspiration
- Uses undocumented OpenAI and GitHub APIs -- use at your own discretion
