# react-native-subject-lift

Native subject lift for React Native — the "Select Subject" experience from Photos.app, available in your app.

- **iOS 16+** — powered by Apple's VisionKit `ImageAnalysisInteraction`. Full native UX: long-press glow, lift animation, copy/share sheet. Zero JS overhead.
- **Android 7+** — powered by Google ML Kit `SubjectSegmenter`. Segments the foreground subject and plays a Reanimated spring lift animation.

---

## Preview

| iOS (VisionKit) | Android (ML Kit + Reanimated) |
|---|---|
| System lift UX — identical to Photos.app | Animated foreground lift over blurred background |

---

## Installation

```sh
npm install react-native-subject-lift
```

### iOS

```sh
cd ios && pod install
```

Minimum deployment target: **iOS 16.0**

In your `Info.plist`, no special permissions are needed for local images. For remote images over HTTP, ensure `NSAppTransportSecurity` is configured.

### Android

Add the ML Kit dependency to your `android/app/build.gradle`:

```gradle
dependencies {
  implementation 'com.google.mlkit:subject-segmentation:16.0.0-beta5'
}
```

ML Kit downloads the segmentation model on first use via Google Play Services.

---

## Usage

```tsx
import { SubjectLiftView, useSubjectLift } from 'react-native-subject-lift';

export function PhotoScreen({ imageUri }: { imageUri: string }) {
  const { isReady, status, handleAnalysisComplete } = useSubjectLift();

  return (
    <View style={{ flex: 1 }}>
      <SubjectLiftView
        imageUri={imageUri}
        style={{ flex: 1 }}
        onAnalysisComplete={handleAnalysisComplete}
      />
      {status === 'analyzing' && <ActivityIndicator />}
    </View>
  );
}
```

### iOS — interaction types

```tsx
// Default: subject lift + Live Text + Visual Look Up (same as Photos.app)
<SubjectLiftView
  imageUri={imageUri}
  preferredInteractionTypes="automatic"
/>

// Subject lift only — no Live Text, no Visual Look Up
<SubjectLiftView
  imageUri={imageUri}
  preferredInteractionTypes="subjectLiftOnly"
/>
```

---

## API

### `<SubjectLiftView />`

| Prop | Type | Default | Description |
|---|---|---|---|
| `imageUri` | `string` | required | Image URI (`file://` or `https://`) |
| `preferredInteractionTypes` | `'automatic' \| 'subjectLiftOnly'` | `'automatic'` | iOS only — which VisionKit interactions to enable |
| `onAnalysisComplete` | `(event) => void` | — | Fired when analysis finishes |
| `style` | `ViewStyle` | — | Standard RN style prop |

#### `onAnalysisComplete` event

```ts
{
  nativeEvent: {
    status: 'ready' | 'error';
    base64?: string;   // Android only — base64 PNG of segmented subject
    message?: string;  // Error message if status === 'error'
  }
}
```

### `useSubjectLift()`

```ts
const {
  status,          // 'idle' | 'analyzing' | 'ready' | 'error'
  isReady,         // boolean — true when lift is ready to interact
  error,           // string | null
  maskedBase64,    // string | null — Android only
  handleAnalysisComplete,  // pass to onAnalysisComplete prop
  reset,           // reset back to idle
} = useSubjectLift();
```

---

## Platform notes

| | iOS | Android |
|---|---|---|
| Minimum version | iOS 16 | API 24 (Android 7) |
| Native UX | ✅ Full system UX | ❌ JS animation via Reanimated |
| On-device | ✅ | ✅ (model downloaded once) |
| Remote images | ✅ | ✅ |
| `preferredInteractionTypes` | ✅ | Ignored |
| `base64` in event | ❌ | ✅ |

---

## Requirements

- React Native >= 0.72
- react-native-reanimated >= 3.0.0 (Android only, peer dependency)
- iOS 16+ deployment target
- Android minSdkVersion 24+

---

## Contributing

Issues and PRs are welcome. Please open an issue before submitting large changes.

---

## License

MIT © [Berkay Baygut](https://berkaybaygut.com)
