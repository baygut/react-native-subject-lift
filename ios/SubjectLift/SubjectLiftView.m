#import <React/RCTViewManager.h>

// Swift implementation: SubjectLiftViewManager (SubjectLiftViewManager.swift).
// RCT_EXTERN_MODULE wraps prop exports for the ObjC runtime; RCT_EXPORT_* alone at file scope is invalid.
@interface RCT_EXTERN_MODULE(SubjectLiftViewManager, RCTViewManager)

RCT_EXPORT_VIEW_PROPERTY(imageUri, NSString)
RCT_EXPORT_VIEW_PROPERTY(preferredInteractionTypes, NSString)
RCT_EXPORT_VIEW_PROPERTY(onAnalysisComplete, RCTBubblingEventBlock)
RCT_EXPORT_VIEW_PROPERTY(onSubjectLifted, RCTBubblingEventBlock)

@end
