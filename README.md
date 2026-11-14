# Launch Mode

An iPhone GPS speedometer and hands-free 0–60 timer, built for a 2020 Mazda MX-5 RF. See `PLAN.md` for the design and build order.

## What you need

- A Mac with Xcode.
- An Apple ID signed in to Xcode (**Xcode → Settings → Accounts**). A free one works, but the app then stops opening after 7 days and has to be installed again.
- iOS 17 or later.

## Install it on your iPhone

1. **Signing, once.** Copy `Local.xcconfig.example` to `Local.xcconfig` and fill in your Team ID and a bundle id prefix of your own. Set the team there, not in Xcode's Signing pane, which would change the shared project file.
2. **Connect the iPhone** to the Mac with a cable (or pair it over Wi-Fi in **Window → Devices and Simulators**), and on the iPhone turn on **Settings → Privacy & Security → Developer Mode** when Xcode asks.
3. **Install.** Run `./iphone-install`. It builds the app for the paired iPhone, installs it and opens it (the iPhone unlocked). The first time with a free account, trust the developer on the iPhone: **Settings → General → VPN & Device Management**. Run it again every 7 days. With more than one iPhone paired, name it: `./iphone-install "My iPhone"`.

## Building without a device

```bash
xcodebuild -project LaunchMode.xcodeproj -scheme LaunchMode -sdk iphonesimulator \
  -destination 'generic/platform=iOS Simulator' build
```
