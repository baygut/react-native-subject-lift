# react-native-subject-lift

Bring **Select Subject**–style interactions into React Native: iOS uses VisionKit (same stack as Photos), Android uses ML Kit segmentation plus a Reanimated lift animation.

| | iOS 16+ | Android 7+ (API 24+) |
|---|:---:|:---:|
| Engine | VisionKit `ImageAnalysisInteraction` | ML Kit Subject Segmenter |
| UX | System lift, Live Text, Visual Look Up | Custom lift animation |

## Install

```sh
npm install react-native-subject-lift
```

**iOS** — `cd ios && pod install`. Deployment target **16.0**.

**Android** — add to `android/app/build.gradle`:

```gradle
dependencies {
  implementation 'com.google.android.gms:play-services-mlkit-subject-segmentation:16.0.0-beta1'
}
```

`react-native-reanimated` ≥ 3 is a **peer dependency** (used on Android).

## Quick start

```tsx
import { SubjectLiftView, useSubjectLift } from 'react-native-subject-lift';

export function PhotoScreen({ imageUri }: { imageUri: string }) {
  const { isReady, status, handleAnalysisComplete } = useSubjectLift();

  return (
    <SubjectLiftView
      imageUri={imageUri}
      style={{ flex: 1 }}
      onAnalysisComplete={handleAnalysisComplete}
      onSubjectLifted={({ nativeEvent }) => {
        // nativeEvent.type + nativeEvent.data — see below
      }}
    />
  );
}
```

### iOS — `preferredInteractionTypes`

- **`automatic`** (default) — subject lift, Live Text, Visual Look Up, QR/barcode detection.
- **`subjectLiftOnly`** — subject lift only.

## API

| Prop | Description |
|------|-------------|
| `imageUri` | `file://` or `https://` image URI |
| `preferredInteractionTypes` | iOS only — see above |
| `onAnalysisComplete` | Analysis finished (`ready` / `error`; Android may include `base64` preview) |
| `onSubjectLifted` | Optional — gesture / cutout / text payloads (see [src/types.ts](src/types.ts)) |
| `style` | `ViewStyle` |

### `useSubjectLift()`

Returns `status`, `isReady`, `error`, `maskedBase64` (Android), `handleAnalysisComplete`, and `reset`.

## `onSubjectLifted` (iOS)

Shape: `{ nativeEvent: { type: string, data: string } }`. Full detail is in the `SubjectLiftedEvent` JSDoc in [`src/types.ts`](src/types.ts).

- **`image`** — JSON when a lift gesture starts; **base64 PNG** when the subject cutout is ready (timing varies; VisionKit does not guarantee a bitmap at gesture start).
- **`text`** — iOS 17+: JSON `selectionBegan` with selected text when selection first has content; **plain string** when the selection ends.
- **`dataDetector` / `interaction`** — began-phase JSON for other interaction kinds.
- **QR/barcodes** — detected in analysis and shown in system Live Text / data-detector UI; there is no separate “QR subject lift” bitmap event.

On **Android**, `onSubjectLifted` fires with `type: "image"` and base64 when segmentation succeeds.

## Notes

- Subject lift on iOS is meant for **real devices** (A12+); the Simulator is often unreliable.
- Use photos with a clear foreground subject; not every image will segment.
- Remote HTTP images need appropriate App Transport Security on iOS.

## Requirements

React Native ≥ 0.72 · iOS 16+ · Android minSdk 24 · Reanimated ≥ 3 (Android)

## License

MIT © [Berkay Baygut](https://berkaybaygut.com)
