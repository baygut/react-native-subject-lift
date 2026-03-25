# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.2.0] - 2026-03-25

### Added
- iOS: `onSubjectLifted` text payload when selection first has content — JSON `{"phase":"selectionBegan","text":"..."}` (iOS 17+), plus a short poll after text gestures; selection end remains a plain string.
- iOS: VisionKit analysis includes **machine-readable codes** (QR/barcode) alongside text and Visual Look Up.

### Changed
- README trimmed; event semantics documented alongside TypeScript types.

### Fixed
- npm package `files` list excludes `android/build` and `android/.gradle`.

## [0.1.0] - 2026-03-25

### Added
- `SubjectLiftView` component — iOS (VisionKit) and Android (ML Kit)
- `useSubjectLift` hook
- `preferredInteractionTypes` prop for iOS interaction control
- `onAnalysisComplete` event with `base64` support on Android
- GitHub Actions CI and npm publish workflows
