#import <React/RCTViewManager.h>

RCT_EXPORT_MODULE(SubjectLiftViewManager)

// Props
RCT_EXPORT_VIEW_PROPERTY(imageUri, NSString)
RCT_EXPORT_VIEW_PROPERTY(preferredInteractionTypes, NSString)

// Events
RCT_EXPORT_VIEW_PROPERTY(onAnalysisComplete, RCTBubblingEventBlock)
RCT_EXPORT_VIEW_PROPERTY(onSubjectLiftBegan, RCTBubblingEventBlock)
RCT_EXPORT_VIEW_PROPERTY(onSubjectLiftEnded, RCTBubblingEventBlock)
