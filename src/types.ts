import type { ViewStyle } from 'react-native';

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

export type SubjectLiftViewProps = {
  /** URI of the image to analyze. Supports file:// and http(s):// */
  imageUri: string;

  /**
   * iOS only — controls which VisionKit interactions are enabled.
   * - 'automatic': subject lift + Live Text + Visual Look Up (default)
   * - 'subjectLiftOnly': subject lift only
   */
  preferredInteractionTypes?: InteractionType;

  /** Called when VisionKit analysis (iOS) or ML Kit segmentation (Android) completes */
  onAnalysisComplete?: (event: AnalysisCompleteEvent) => void;

  style?: ViewStyle;
};
