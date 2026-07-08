# Setlist (SwiftUI + SwiftData)

A native implementation of the `Setlist.dc.html` prototype, following
`project/uploads/first-implementation-plan.md` section 1 (SwiftUI + SwiftData,
iOS 17+, zero backend) and the final design direction reached in
`chats/chat1.md` (de-emphasized timer, always-visible mini-bar, focus mode
drives the workout, overview is for editing, Barlow-style sportier numerals,
routine picker on start, timechart progress, 10s rest steps, tab bar visible
on the overview).

**This code was written in a Linux container with no Xcode/Swift toolchain,
so it has not been compiled or run.** Everything here follows standard,
well-established SwiftUI/SwiftData patterns, but budget a first build pass in
Xcode to shake out any typos before you rely on it.

## What's here

```
Sources/
  App/SetlistApp.swift        — app entry, SwiftData ModelContainer, seeding
  Models/                     — Exercise, Routine(+Entry), Workout(+Exercise/Set), SettingsStore
  Seed/SeedData.swift         — first-launch catalog + ~13 weeks of real history
  Engine/
    WorkoutSession.swift      — the active-workout state machine (timers, focus nav, sets)
    Analytics.swift           — streaks, PRs, muscle-group volume trends, e1RM — all real queries
  DesignSystem/                — colors, condensed-italic numeral font, shared components
  Views/                       — one folder per tab, plus Workout/ for the active-workout surfaces
```

There is no mock/demo data baked into the UI layer — `SeedData` populates the
SwiftData store once on first launch (exercise catalog, three routines, and
~13 weeks of alternating Push/Pull/Legs history with progressive overload) so
Progress and History have something real to show immediately. Every screen
after that computes from what's actually stored.

## Build it — pick one

### Option A: plain Xcode (recommended, no extra tools)

1. Xcode → **File → New → Project… → iOS → App**.
   - Product Name: `Setlist`
   - Interface: **SwiftUI**, Storage: **SwiftData**, Language: **Swift**
   - Uncheck "Include Tests" if you don't want them (harmless either way).
2. In the new project, delete the generated `ContentView.swift` and the
   generated `@main App` file's body (keep the file name if you like, or
   delete it too — see step 3).
3. Drag the `Sources` folder from this bundle into the Xcode project
   navigator ("Copy items if needed" checked, add to the `Setlist` target).
   If you kept Xcode's generated app entry file, delete it — this bundle's
   `Sources/App/SetlistApp.swift` replaces it (only one `@main` allowed).
4. Set the deployment target to **iOS 17.0** (Project settings → target →
   General → Minimum Deployments).
5. Build & run on an iOS 17+ simulator or device.

### Option B: XcodeGen

If you have [XcodeGen](https://github.com/yonaskolb/XcodeGen) installed:

```sh
cd ios/Setlist
xcodegen generate
open Setlist.xcodeproj
```

This uses `project.yml` in this folder to generate the `.xcodeproj` for you
(no Info.plist file needed — it's generated from build settings). If XcodeGen
isn't installed: `brew install xcodegen`.

## Notes on fidelity to the design

- **Numerals/headings**: the design calls for Barlow Condensed Heavy Italic.
  Rather than bundle font files (which this environment couldn't fetch),
  `Font.numeral(_:weight:)` in `DesignSystem/Theme.swift` approximates it with
  SF Pro's condensed width + heavy weight + italic — no extra setup needed.
  To use the real typeface: add the Barlow Condensed `.ttf` files to the
  target, register them in Info.plist's `UIAppFonts`, and swap the
  implementation of `Font.numeral` to `.custom("BarlowCondensed-ExtraBoldItalic", size: size)`.
- **Accent color**: `SettingsStore.accent` supports lime/amber like the
  original `accent` prop; there's no in-app switcher UI yet (the prototype
  exposed it as a design-tool prop, not an end-user setting) — change the
  default in `AccentChoice` or wire up a picker in `SettingsSheet` if you want
  users to switch it themselves.
- **Live Activity / lock-screen rest timer** (plan section 4) and the
  **plate calculator / supersets / Apple Health export** (plan section 7,
  "Version 2") are intentionally not implemented — they're called out in the
  plan as later additions, not part of the screens specified in the design
  handoff.
