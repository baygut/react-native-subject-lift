/**
 * Android subject lift component.
 *
 * Android's ML Kit returns a foreground bitmap (base64 PNG).
 * Since there's no system UX equivalent to VisionKit, we simulate the
 * lift animation using Reanimated: blurred original underneath + lifted
 * subject on top with a spring scale + translateY.
 */

import React, { useState, useCallback } from 'react';
import { Image, StyleSheet, View, requireNativeComponent } from 'react-native';
import Animated, {
  useSharedValue,
  useAnimatedStyle,
  withSpring,
} from 'react-native-reanimated';
import type { SubjectLiftViewProps, AnalysisCompleteEvent } from '../types';

const NativeSegmentationView =
  requireNativeComponent<SubjectLiftViewProps>('SubjectLiftView');

export function SubjectLiftViewAndroid({
  imageUri,
  style,
  onAnalysisComplete,
  onSubjectLifted,
}: SubjectLiftViewProps) {
  const [maskedBase64, setMaskedBase64] = useState<string | null>(null);

  // Animation values
  const scale = useSharedValue(1);
  const translateY = useSharedValue(0);
  const shadowOpacity = useSharedValue(0);

  const liftStyle = useAnimatedStyle(() => ({
    transform: [{ scale: scale.value }, { translateY: translateY.value }],
    shadowOpacity: shadowOpacity.value,
  }));

  const triggerLiftAnimation = useCallback(() => {
    scale.value = withSpring(1.07, { damping: 14, stiffness: 120 });
    translateY.value = withSpring(-10, { damping: 14, stiffness: 120 });
    shadowOpacity.value = withSpring(0.45);
  }, [scale, translateY, shadowOpacity]);

  const handleAnalysisComplete = useCallback(
    (event: AnalysisCompleteEvent) => {
      const { status, base64 } = event.nativeEvent;
      if (status === 'ready' && base64) {
        setMaskedBase64(base64);
        triggerLiftAnimation();
        onSubjectLifted?.({ nativeEvent: { type: 'image', data: base64 } });
      }
      onAnalysisComplete?.(event);
    },
    [onAnalysisComplete, onSubjectLifted, triggerLiftAnimation]
  );

  return (
    <View style={[styles.container, style]}>
      {/* Blurred original image underneath */}
      <Image
        source={{ uri: imageUri }}
        style={StyleSheet.absoluteFill}
        blurRadius={maskedBase64 ? 6 : 0}
      />

      {/* Lifted subject */}
      {maskedBase64 && (
        <Animated.Image
          source={{ uri: `data:image/png;base64,${maskedBase64}` }}
          style={[StyleSheet.absoluteFill, styles.subject, liftStyle]}
          resizeMode="contain"
        />
      )}

      {/* Invisible native view that drives ML Kit segmentation */}
      <NativeSegmentationView
        imageUri={imageUri}
        style={StyleSheet.absoluteFill}
        onAnalysisComplete={handleAnalysisComplete}
      />
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    overflow: 'hidden',
  },
  subject: {
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 8 },
    shadowRadius: 16,
    elevation: 12,
  },
});
