import type { StyleProp, ViewStyle } from 'react-native';

export type AnalysisStatus = 'idle' | 'analyzing' | 'ready' | 'error';

export type InteractionType = 'automatic' | 'subjectLiftOnly';

export type AnalysisCompleteEvent = {
  nativeEvent: {
    status: 'ready' | 'error';
    /** Android only — base64 PNG of the segmented subject */
    base64?: string;
    message?: string;
  };
};

/**
 * Fired when the user interacts with lifted / analyzed content.
 *
 * **iOS (VisionKit)** — `type` is typically:
 * - `image` — `data` is JSON `{"phase":"began","interactionTypeRaw":n}` when a lift gesture starts,
 *   or a **base64 PNG** string when the cutout is ready. iOS may deliver this soon after **began**
 *   (best-effort `subject(at:)` + `image(for:)`) or later via lift-end heuristics / timeout — VisionKit
 *   does not guarantee the bitmap exists at `shouldBeginAt`.
 * - `text` — while the user is selecting (iOS 17+), `data` may be JSON
 *   `{"phase":"selectionBegan","text":"..."}` once per selection when non-empty text is first available
 *   (short poll after gesture began + `textSelectionDidChange`). When the selection is cleared, `data` is
 *   the **plain string** of the last selected text (backward compatible).
 * - **QR / barcodes** — analysis includes machine-readable codes; they appear in the Live Text / data-detector
 *   UI, not as subject lift. There is no separate “QR cutout” event like `image`; use `dataDetector` / text
 *   flows if the system surfaces them.
 * - `dataDetector` / `interaction` — began phase JSON in `data`, same shape as image began.
 *
 * **Android** — `type` is `image` and `data` is the **base64 PNG** of the segmented subject when segmentation succeeds.
 */
export type SubjectLiftedEvent = {
  nativeEvent: {
    type: string;
    data: string;
  };
};

/**
 * iOS: Apple’s `ImageAnalysisOverlayView` + `MenuTag` menu customization exists in documentation
 * for AppKit/`NSMenu` flows; **VisionKit on iPhone only exposes `ImageAnalysisInteraction`**, which
 * has **no API** to hide or edit the subject-lift Copy / Share row. Use `onSubjectLifted` for app UI.
 */
export type SubjectLiftViewProps = {
  /** URI of the image to analyze. Supports file:// and http(s):// */
  imageUri: string;

  /**
   * iOS only — controls which VisionKit interactions are enabled.
   * - 'automatic': subject lift + Live Text + Visual Look Up + QR/barcode detection (default)
   * - 'subjectLiftOnly': subject lift only
   */
  preferredInteractionTypes?: InteractionType;

  /** Called when VisionKit analysis (iOS) or ML Kit segmentation (Android) completes */
  onAnalysisComplete?: (event: AnalysisCompleteEvent) => void;

  /**
   * Called when subject / text lift-style interaction yields data your app can use to build UI.
   * See {@link SubjectLiftedEvent}.
   */
  onSubjectLifted?: (event: SubjectLiftedEvent) => void;

  style?: StyleProp<ViewStyle>;
};
