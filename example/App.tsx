/**
 * Example app for react-native-subject-lift
 *
 * @format
 */

import React, {useCallback, useState} from 'react';
import {
  ActivityIndicator,
  FlatList,
  Image,
  SafeAreaView,
  StatusBar,
  StyleSheet,
  Text,
  View,
} from 'react-native';
import {GestureHandlerRootView} from 'react-native-gesture-handler';
import {
  SubjectLiftView,
  useSubjectLift,
  type SubjectLiftedEvent,
} from 'react-native-subject-lift';

/** Public HTTPS image — works on simulator/device with network */
// const SAMPLE_IMAGE_URI = 'https://posterspy.com/wp-content/uploads/2025/04/SPIDER-MAN-BRAND-NEW-DAY.jpg';
const SAMPLE_IMAGE_URI = 'https://www.labelplanet.co.uk/_cache/og_faq_glossary/1200x630/qr-code-235.jpg';

const MAX_LOG_ENTRIES = 80;

type LiftLogEntry = {
  id: string;
  at: string;
  kind: string;
  summary: string;
  detail: string;
  /** `data:image/png;base64,...` for cutout rows — shown in the list thumbnail */
  clipUri?: string;
};

const fail_this_commit = true;

function summarizeLiftEvent(type: string, data: string): Omit<LiftLogEntry, 'id' | 'at'> {
  if (type === 'image') {
    const trimmed = data.trimStart();
    const isLikelyBase64 = data.length > 80 && !trimmed.startsWith('{');
    if (isLikelyBase64) {
      const kb = Math.round(data.length / 1024);
      return {
        kind: 'image',
        summary: 'Subject cutout (PNG)',
        detail: `~${kb} KB`,
        clipUri: `data:image/png;base64,${data}`,
      };
    }
    return {
      kind: 'image',
      summary: 'Gesture / metadata',
      detail:
        data.length > 160 ? `${data.slice(0, 160)}…` : data || '(empty)',
    };
  }
  if (type === 'text') {
    try {
      const j = JSON.parse(data) as {phase?: string; text?: string};
      if (j?.phase === 'selectionBegan') {
        const t = typeof j.text === 'string' ? j.text : '';
        const preview = t.length > 120 ? `${t.slice(0, 120)}…` : t;
        return {
          kind: 'text',
          summary: 'Text selection began',
          detail: preview || '(empty)',
        };
      }
      const detail =
        data.length > 160 ? `${data.slice(0, 160)}…` : data || '(empty)';
      return {
        kind: 'text',
        summary: 'Gesture / metadata',
        detail,
      };
    } catch {
      /* plain string = selection ended */
    }
    const preview = data.length > 120 ? `${data.slice(0, 120)}…` : data;
    return {
      kind: 'text',
      summary: 'Text selection cleared',
      detail: preview || '(empty)',
    };
  }
  return {
    kind: type,
    summary: 'Event',
    detail: data.length > 160 ? `${data.slice(0, 160)}…` : data,
  };
}

function App(): React.JSX.Element {
  const {status, error, isReady, handleAnalysisComplete} = useSubjectLift();
  const [liftLog, setLiftLog] = useState<LiftLogEntry[]>([]);

  const handleSubjectLifted = useCallback(({nativeEvent}: SubjectLiftedEvent) => {
    const {type, data} = nativeEvent;
    const partial = summarizeLiftEvent(type, data);
    const entry: LiftLogEntry = {
      id: `${Date.now()}-${Math.random().toString(36).slice(2, 9)}`,
      at: new Date().toLocaleTimeString(),
      ...partial,
    };
    setLiftLog(prev => [entry, ...prev].slice(0, MAX_LOG_ENTRIES));
  }, []);

  const clearLog = useCallback(() => setLiftLog([]), []);

  return (
    <GestureHandlerRootView style={styles.root}>
      <SafeAreaView style={styles.safe}>
        <StatusBar barStyle="dark-content" />
        <Text style={styles.title}>Subject lift example</Text>
        <Text style={styles.meta}>
          {status === 'idle' && 'Waiting for native analysis…'}
          {status === 'ready' &&
            (isReady
              ? 'Ready — long-press the subject (iOS) or lift (Android). Events append below.'
              : '')}
          {status === 'error' && (error ?? 'Error')}
        </Text>
        <View style={styles.stage}>
          <SubjectLiftView
            imageUri={SAMPLE_IMAGE_URI}
            style={styles.fill}
            onAnalysisComplete={handleAnalysisComplete}
            onSubjectLifted={handleSubjectLifted}
          />
          {status === 'idle' && (
            <View style={styles.overlay} pointerEvents="none">
              <ActivityIndicator size="large" color="#333" />
            </View>
          )}
        </View>
        <View style={styles.logSection}>
          <View style={styles.logHeader}>
            <Text style={styles.logHeaderTitle}>onSubjectLifted ({liftLog.length})</Text>
            {liftLog.length > 0 ? (
              <Text style={styles.clearBtn} onPress={clearLog}>
                Clear
              </Text>
            ) : null}
          </View>
          <FlatList
            data={liftLog}
            keyExtractor={item => item.id}
            renderItem={({item}) => (
              <View style={styles.logRow}>
                <View style={styles.logRowTop}>
                  <Text style={styles.logKind}>{item.kind}</Text>
                  <Text style={styles.logAt}>{item.at}</Text>
                </View>
                <View style={styles.logBody}>
                  {item.clipUri ? (
                    <Image
                      source={{uri: item.clipUri}}
                      style={styles.thumb}
                      resizeMode="contain"
                    />
                  ) : null}
                  <View style={styles.logTextCol}>
                    <Text style={styles.logSummary}>{item.summary}</Text>
                    <Text
                      style={styles.logDetail}
                      numberOfLines={item.clipUri ? 2 : 4}>
                      {item.detail}
                    </Text>
                  </View>
                </View>
              </View>
            )}
            ListEmptyComponent={
              <Text style={styles.logEmpty}>
                Lift or select text — each event will appear here.
              </Text>
            }
            style={styles.logList}
          />
        </View>
      </SafeAreaView>
    </GestureHandlerRootView>
  );
}

const styles = StyleSheet.create({
  root: {flex: 1},
  safe: {flex: 1, backgroundColor: '#fff'},
  title: {
    fontSize: 18,
    fontWeight: '600',
    textAlign: 'center',
    paddingTop: 8,
  },
  meta: {
    textAlign: 'center',
    paddingHorizontal: 16,
    paddingVertical: 8,
    color: '#444',
    fontSize: 14,
  },
  stage: {flex: 1, minHeight: 200, overflow: 'hidden'},
  fill: {flex: 1},
  overlay: {
    ...StyleSheet.absoluteFillObject,
    justifyContent: 'center',
    alignItems: 'center',
    backgroundColor: 'rgba(255,255,255,0.35)',
  },
  // Fixed height so the image stage doesn’t resize when the log fills — that reflow made Live Text
  // look like it “zoomed” when the first rows appeared (not a VisionKit font bug).
  logSection: {
    height: 280,
    flexShrink: 0,
    borderTopWidth: StyleSheet.hairlineWidth,
    borderTopColor: '#ccc',
    backgroundColor: '#f8f8f8',
  },
  logHeader: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    paddingHorizontal: 12,
    paddingVertical: 8,
    borderBottomWidth: StyleSheet.hairlineWidth,
    borderBottomColor: '#ddd',
  },
  logHeaderTitle: {
    fontSize: 13,
    fontWeight: '600',
    color: '#333',
  },
  clearBtn: {
    fontSize: 13,
    color: '#007aff',
    fontWeight: '500',
  },
  logList: {
    flex: 1,
  },
  logRow: {
    paddingHorizontal: 12,
    paddingVertical: 10,
    borderBottomWidth: StyleSheet.hairlineWidth,
    borderBottomColor: '#e5e5e5',
    backgroundColor: '#fff',
  },
  logBody: {
    flexDirection: 'row',
    alignItems: 'flex-start',
  },
  thumb: {
    width: 76,
    height: 76,
    marginRight: 10,
    borderRadius: 8,
    backgroundColor: '#eee',
  },
  logTextCol: {
    flex: 1,
    minWidth: 0,
  },
  logRowTop: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: 4,
  },
  logKind: {
    fontSize: 11,
    fontWeight: '700',
    color: '#666',
    textTransform: 'uppercase',
    letterSpacing: 0.5,
  },
  logAt: {
    fontSize: 11,
    color: '#999',
  },
  logSummary: {
    fontSize: 14,
    fontWeight: '600',
    color: '#111',
    marginBottom: 2,
  },
  logDetail: {
    fontSize: 12,
    color: '#555',
    lineHeight: 16,
  },
  logEmpty: {
    padding: 16,
    fontSize: 13,
    color: '#888',
    textAlign: 'center',
  },
});

export default App;
