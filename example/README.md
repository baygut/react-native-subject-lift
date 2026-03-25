# SubjectLiftExample

Demo app for [`react-native-subject-lift`](../README.md), linked from the repo root with `"react-native-subject-lift": "file:.."`.

## Requirements

- **Node.js** 18–20 LTS recommended (React Native 0.74; very new Node versions can break the iOS build scripts).
- **iOS**: Xcode, CocoaPods (`gem install cocoapods` or `bundle install` in `ios/`), simulator or device with **iOS 16+**.
- **Android**: Android Studio / SDK, emulator or device (API 24+), Google Play services for ML Kit.

## First-time setup

From the **repository root**:

```sh
npm install
cd example
npm install
cd ios
bundle install   # optional; uses Gemfile for CocoaPods
bundle exec pod install
cd ../..
```

## Run

From `example/`:

```sh
npm start
```

In another terminal (same `example/` directory):

```sh
npm run ios
# or
npm run android
```

Or from the repo root:

```sh
npm run example:start
npm run example:ios
npm run example:android
```

The sample screen loads a remote image (`picsum.photos`). Use a **network-connected** device.

**iOS:** Long-press **subject lift** (VisionKit) is **not reliable in the Simulator** — use a **physical iPhone** (A12+). Use a photo with a clear person or subject; random placeholder images may not lift.

## Troubleshooting

- **`build.db: database is locked` / “two concurrent builds”** — Only one build should use the same DerivedData at a time. Close **Xcode** if this project is open, stop any other `react-native run-ios` / `xcodebuild`, then clean and rebuild:
  ```sh
  rm -rf ~/Library/Developer/Xcode/DerivedData/SubjectLiftExample-*
  cd example && npm run ios
  ```
  If it persists, quit Xcode fully (`Cmd+Q`), run `killall xcodebuild` (only if no build should be running), then try again.

- **iOS build / `run-ios` fails with a Node stack trace** — switch to Node 20 (see `.nvmrc`), then `cd example/ios && pod install` again.

- **`Invalid hook call` / `Cannot read property 'useState' of null`** — Metro was resolving `react` from the **repo root** (`../node_modules`) while the app uses **`example/node_modules/react`**. `metro.config.js` sets **`disableHierarchicalLookup`**, a single **`nodeModulesPaths`**, and a **`resolveRequest`** pin for `react` / `react-native`. Restart Metro with **`npm start -- --reset-cache`**, then reload the app (uninstall from simulator if needed).

- **`Command PhaseScriptExecution failed with a nonzero exit code`** — Xcode’s script phases (Hermes, “Bundle React Native code and images”, etc.) run with a **minimal `PATH`**, so **`node` is often not found**. This repo’s `ios/.xcode.env` prepends common Homebrew paths. If it still fails, create `ios/.xcode.env.local` (gitignored) and set Node explicitly, e.g. `export NODE_BINARY=$(command -v node)` after loading nvm, or `export NODE_BINARY=/opt/homebrew/bin/node`. In Xcode, open the **Report navigator** (last tab), select the failed build, and expand the red **PhaseScriptExecution** line to see the real error (often `node: command not found`).

- **Android ML Kit** — `com.google.mlkit:subject-segmentation` is already added in `android/app/build.gradle` for this example.
