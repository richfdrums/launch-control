# Launch Control — Plan

An iPhone app for a 2020 Mazda MX-5 RF: a big, good-looking GPS speedometer and a hands-free 0–60 timer.

## Scope

- **Speedometer**: MPH in large digits filling the screen, a GPS signal-quality indicator, and the screen kept awake.
- **0–60 timer**: arm it while stopped; it starts on its own when the car launches and stops on its own at 60 mph. The phone is never touched during a run.
- **Run history**: each run saved with date/time, 0–60, 0–60 with 1-ft rollout, and a 0–30 split. Best time shown.
- **Voice callout**: speaks the time when the run ends.
- **HUD mirror mode**: flips the speedometer horizontally to read correctly when reflected in the windshield.
- **Portrait only.**
- **Themes**: six, each with its own app icon that the app switches to.

## Accuracy approach

iPhone GPS reports speed about **once per second**, which on its own gives about ±0.5 s on a ~6 s run. To do better:

- **Start time from the accelerometer** (CoreMotion, 100 Hz): the run starts at the first sustained forward acceleration from a stop, not at the next GPS reading.
- **Fill in speed between GPS readings** by integrating forward acceleration and correcting it with each GPS reading. The 60 mph moment is found between samples.
- **Rollout**: also report the time from 1 ft of travel onward, which is how magazines measure. It typically takes 0.2–0.3 s off.
- **Mount check**: the phone must be mounted solidly. Before arming, the app checks that it is still and works out which way the car's forward axis points.
- **Raw logging**: every run's GPS and motion data is saved, so the math can be re-run and tuned later without more driving.

## Themes

Following stem-studio's pattern (`appleshared/Theme.swift`): a `ThemeID` enum, a `Palette` of colour tokens, a `Look` per theme with its own digit font and effects, a picker under a settings gear, and an alternate app icon per theme.

| Theme | Feel |
|---|---|
| **Outrun** | Neon pink and cyan, glowing digits, a horizon grid |
| **LCD Dash** | 80s seven-segment digital dashboard, with dim unlit segments behind the digits |
| **Gauge** | Classic white-on-black analog dial, sweeping needle, number inside it |
| **Night Drive** | Dim red on black, easy on the eyes at night |
| **Nixie** | Orange glowing tube digits |
| **Crimson** | Deep metallic red and silver |

## Tech

- SwiftUI, iOS 26+ (raised from 17 for the CarPlay Live Activity), CoreLocation (`kCLLocationAccuracyBestForNavigation`, `.automotiveNavigation`), CoreMotion, AVSpeechSynthesizer.
- `Base.xcconfig` plus a git-ignored `Local.xcconfig` for the signing team and bundle id prefix, as in stem-studio.
- Installed with a free Apple ID via an `./iphone-install` script (like stem-studio's `ipad-install`). It has to be re-run every 7 days.
- Unit tests feed recorded and synthetic runs through the timing math.

## Build order

1. **Project skeleton**: Xcode project, xcconfig signing setup, `./iphone-install`, `git init`.
2. **Sensors**: GPS speed and motion data, the stillness and mount check, raw run logging.
3. **Timing math**: launch detection, speed between GPS readings, the 60 mph and rollout times, with unit tests on synthetic runs.
4. **Speedometer screen** in one theme. *First real-world test: a normal drive to check the GPS readings.*
5. **0–60 screen**: arm, run, result, voice callout.
6. **Run history.**
7. **The other five themes and their app icons.**
8. **HUD mirror mode.**

## CarPlay Live Activity

The app on the car's screen. A real CarPlay app is not possible: it needs an entitlement Apple grants to a paid account, and the only category that fits ("driving task") is limited to Apple's templates, refreshed at most once every 10 seconds. A **Live Activity** needs neither. With iOS 26 it shows in the CarPlay Dashboard (or as a notification), drawn by our own SwiftUI, so the themes come along. The phone still does all the work.

**The card**, in the current theme:
- In speedometer mode, the live mph in the theme's digits.
- In 0–60 mode, the run's state ("Hold still", "Ready", the live mph while running), then the result ("0–60 6.42 s", "NEW BEST").

GPS reports once a second, so the speedometer needs about one update a second. During a run, the 100 Hz speed is throttled to a few updates a second.

**Steps** (branch `feat/carplay-live-activity`):

1. **Spike**: a bare Live Activity showing GPS speed, watched in CarPlay Simulator (Xcode's Device Hub, iPhone on USB). It answers whether the card keeps up at once a second. If it doesn't, the card shows the state and result only.
2. **Shared theme code**: move `ThemeID`, `Look`, `Palette` and `Readout` into a folder that both the app and the extension compile, as the tests share `LaunchKit`. `ThemeStore` stays in the app, since it uses `UIApplication`, which an extension can't. No behaviour change.
3. **Widget extension**: a `LaunchControlWidgets` target with its own xcconfig (bundle id `$(BUNDLE_ID_PREFIX).app.widgets`) and `NSSupportsLiveActivities` set on the app. The extension is embedded, so `./iphone-install` still installs everything. Raise the deployment target to **iOS 26** for every target.
4. **`LiveCard`** (in `Run/`): starts the Live Activity when the app becomes active and ends it when the app goes away. It feeds the card `Location`'s speed and `RunController.state`, throttled, plus the current theme.
5. **Views**: the small family (`.supplementalActivityFamilies([.small])`), which is what CarPlay shows; the Lock Screen view; and simple Dynamic Island views.
6. **Test** every theme in CarPlay Simulator, then in the car.

**Risks:**
- How often iOS redraws the card. The spike answers this.
- Whether Mazda Connect shows the card in the Dashboard or only as a notification. Only the car can tell.

**Decided: foreground only, for now.** As before, the app stops GPS and cancels any run when it goes to the background, and the card ends with it. The alternative is the background location mode. Once on, GPS never stops on its own, so the app would need its own stop rule: stop when CarPlay disconnects (seen from the audio route), or after 5 minutes standing still in the background.

**Later, maybe:** a CarPlay widget with the best and last times. It would need `history.json` shared through an App Group, which may not be available to a free Apple ID.

## Safety

Do 0–60 runs only on a track or a closed road.
