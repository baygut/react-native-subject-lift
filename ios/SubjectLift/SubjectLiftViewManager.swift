import React

@available(iOS 16.0, *)
@objc(SubjectLiftViewManager)
class SubjectLiftViewManager: RCTViewManager {

  override func view() -> UIView! {
    return SubjectLiftView()
  }

  override static func requiresMainQueueSetup() -> Bool {
    return true
  }
}
