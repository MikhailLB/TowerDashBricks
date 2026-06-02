# TowerDash Bricks — Swift (iOS)

Native iOS port of the **TowerDash Bricks** nonogram puzzle game, written in **SwiftUI**.  
This is the `white-part-swift` branch — the blueprint/dark-industrial colour scheme.

## What's inside

```
TowerDashBricks.xcodeproj/   ← Xcode project (objectVersion 77, Xcode 16+)
TowerDashBricks/
  Theme/          AppTheme.swift          — colours + fonts
  Models/         PuzzleLevel.swift       — 15 nonogram puzzles
                  NonogramController.swift — pure-logic game state
  State/          GameProgress.swift      — UserDefaults persistence
  Services/       AudioService.swift      — BGM + SFX + haptics
  Components/     BlueprintBackground, BlueprintGrid, BlueprintThumbnail,
                  BrickTile, PixelButton, HowToPlayView
  Views/          LoadingView, MainMenuView, LevelSelectView, GameView,
                  ShopView, SettingsView, InfoWebView
  Resources/      9x16_loading_screen.mp4  (loading splash — portrait)
                  16x9_loading_screen.mp4  (loading splash — landscape)
                  loading_bar_0{1-4}.webp  (progress bar frames)
                  tdb_bar_{1-4}.webp       (alternate bar set)
  Assets.xcassets/ AppIcon, AccentColor
  Info.plist
```

## How to open & run on Mac

### Requirements
- **macOS 13+**
- **Xcode 16+** (download from the App Store or [developer.apple.com](https://developer.apple.com/xcode/))

### Steps

1. Clone the repo and switch to this branch:
   ```bash
   git clone https://github.com/MikhailLB/TowerDashBricks.git
   cd TowerDashBricks
   git checkout white-part-swift
   ```

2. Open the project in Xcode:
   ```bash
   open TowerDashBricks.xcodeproj
   ```
   Or double-click `TowerDashBricks.xcodeproj` in Finder.

3. **Select a simulator or device** in the toolbar (e.g. *iPhone 15 Pro*).

4. Press **⌘R** (or click the ▶ button) to build and run.

> **No CocoaPods / SPM dependencies** — the project has zero external packages.  
> All game assets are drawn procedurally (no webp/png gameplay sprites).  
> Loading screen videos and bar frames are bundled under `Resources/`.

### Signing (for a real device / App Store)
In Xcode → target **TowerDashBricks** → **Signing & Capabilities**:
| Field | Value |
|---|---|
| Team | `4SST65R9U6` |
| Bundle Identifier | `com.towerlab.tower.dash.bricks` |
| App Store Connect App ID | `6771513809` |

These values are already set in `project.pbxproj`.

## Architecture notes

| Flutter original | Swift equivalent |
|---|---|
| `NonogramController` (ChangeNotifier) | `NonogramController` (`ObservableObject`) |
| `GameProgress` + `StorageService` | `GameProgress` (`ObservableObject` + `UserDefaults`) |
| `AudioService` | `AudioService` (`AVAudioPlayer`, haptics via `UIImpactFeedbackGenerator`) |
| `BlueprintBackground` (CustomPainter) | `BlueprintBackground` (SwiftUI `Canvas`) |
| `BlueprintGrid` | `BlueprintGrid` (SwiftUI `DragGesture`) |
| `PixelButton` (press animation) | `PixelButton` (`.scaleEffect` + gradient lerp) |
| `BrickTile` (tdb_brick_0X.webp) | `BrickTile` — 6 procedural gradient skins |
| Google Fonts Roboto Slab | System serif (`Font.Design.serif`) |
| `webview_flutter` | `WKWebView` via `UIViewRepresentable` |
