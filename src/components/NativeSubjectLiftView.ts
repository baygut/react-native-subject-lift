import { requireNativeComponent, StyleSheet } from 'react-native';
import type { SubjectLiftViewProps } from '../types';

/**
 * Native iOS view backed by VisionKit's ImageAnalysisInteraction.
 * Provides the full system subject lift UX: long-press glow, lift animation,
 * copy/share sheet — identical to Photos.app.
 *
 * Requires iOS 16+.
 */
// RN iOS registers view managers without the "Manager" suffix (see RCTViewManagerModuleNameForClass).
// Android uses the same JS name for consistency.
export const NativeSubjectLiftView =
  requireNativeComponent<SubjectLiftViewProps>('SubjectLiftView');

export const defaultStyle = StyleSheet.create({
  fill: { flex: 1 },
});
