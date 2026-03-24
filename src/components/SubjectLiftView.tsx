import React from 'react';
import { Platform, StyleSheet, Text, View } from 'react-native';
import { NativeSubjectLiftView } from './NativeSubjectLiftView';
import { SubjectLiftViewAndroid } from './SubjectLiftViewAndroid';
import type { SubjectLiftViewProps } from '../types';

/**
 * SubjectLiftView
 *
 * iOS  → VisionKit `ImageAnalysisInteraction`: full native subject lift UX
 *         (long-press glow + lift animation + copy/share sheet), identical to Photos.app
 *
 * Android → ML Kit `SubjectSegmenter`: segments the subject, then plays a
 *            Reanimated spring lift animation over a blurred background
 *
 * Requires iOS 16+ / Android API 24+
 *
 * @example
 * <SubjectLiftView
 *   imageUri="file:///path/to/photo.jpg"
 *   style={{ flex: 1 }}
 *   onAnalysisComplete={({ nativeEvent }) => {
 *     if (nativeEvent.status === 'ready') console.log('Ready to lift!');
 *   }}
 * />
 */
export function SubjectLiftView(props: SubjectLiftViewProps) {
  if (Platform.OS === 'ios') {
    return (
      <NativeSubjectLiftView
        {...props}
        style={[styles.fill, props.style]}
      />
    );
  }

  if (Platform.OS === 'android') {
    return <SubjectLiftViewAndroid {...props} />;
  }

  // Unsupported platform fallback
  return (
    <View style={[styles.fallback, props.style]}>
      <Text style={styles.fallbackText}>
        SubjectLiftView is not supported on this platform
      </Text>
    </View>
  );
}

const styles = StyleSheet.create({
  fill: { flex: 1 },
  fallback: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
    backgroundColor: '#111',
  },
  fallbackText: {
    color: '#666',
    fontSize: 13,
    textAlign: 'center',
    paddingHorizontal: 24,
  },
});
