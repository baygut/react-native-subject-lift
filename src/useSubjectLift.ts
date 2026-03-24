import { useState, useCallback } from 'react';
import type { AnalysisStatus, AnalysisCompleteEvent } from './types';

export type UseSubjectLiftReturn = {
  /** Current analysis status */
  status: AnalysisStatus;
  /** Error message if status === 'error' */
  error: string | null;
  /** True when analysis is done and subject lift is ready to interact */
  isReady: boolean;
  /** Android only — base64 PNG of the segmented subject */
  maskedBase64: string | null;
  /** Pass this to SubjectLiftView's onAnalysisComplete prop */
  handleAnalysisComplete: (event: AnalysisCompleteEvent) => void;
  /** Reset back to idle state */
  reset: () => void;
};

/**
 * Hook to manage SubjectLiftView state.
 *
 * @example
 * const { isReady, handleAnalysisComplete } = useSubjectLift();
 *
 * <SubjectLiftView
 *   imageUri={uri}
 *   onAnalysisComplete={handleAnalysisComplete}
 * />
 */
export function useSubjectLift(): UseSubjectLiftReturn {
  const [status, setStatus] = useState<AnalysisStatus>('idle');
  const [error, setError] = useState<string | null>(null);
  const [maskedBase64, setMaskedBase64] = useState<string | null>(null);

  const handleAnalysisComplete = useCallback((event: AnalysisCompleteEvent) => {
    const { status: s, message, base64 } = event.nativeEvent;

    if (s === 'ready') {
      setStatus('ready');
      setError(null);
      if (base64) setMaskedBase64(base64);
    } else {
      setStatus('error');
      setError(message ?? 'Unknown error during analysis');
    }
  }, []);

  const reset = useCallback(() => {
    setStatus('idle');
    setError(null);
    setMaskedBase64(null);
  }, []);

  return {
    status,
    error,
    isReady: status === 'ready',
    maskedBase64,
    handleAnalysisComplete,
    reset,
  };
}
