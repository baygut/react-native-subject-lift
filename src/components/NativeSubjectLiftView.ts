import { requireNativeComponent, StyleSheet } from 'react-native';
import type { SubjectLiftViewProps } from '../types';

/**
 * Native iOS view backed by VisionKit's ImageAnalysisInteraction.
 * Provides the full system subject lift UX: long-press glow, lift animation,
 * copy/share sheet — identical to Photos.app.
 *
 * Requires iOS 16+.
 */
export const NativeSubjectLiftView =
  requireNativeComponent<SubjectLiftViewProps>('SubjectLiftViewManager');

export const defaultStyle = StyleSheet.create({
  fill: { flex: 1 },
});
