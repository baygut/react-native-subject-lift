package com.subjectlift

import com.facebook.react.bridge.ReactApplicationContext
import com.facebook.react.bridge.ReadableArray
import com.facebook.react.common.MapBuilder
import com.facebook.react.uimanager.SimpleViewManager
import com.facebook.react.uimanager.ThemedReactContext
import com.facebook.react.uimanager.annotations.ReactProp

class SubjectLiftViewManager : SimpleViewManager<SubjectLiftView>() {

  override fun getName() = "SubjectLiftView"

  override fun createViewInstance(reactContext: ThemedReactContext): SubjectLiftView {
    val view = SubjectLiftView(reactContext)

    view.onAnalysisComplete = { map ->
      val reactContext = view.context as ThemedReactContext
      reactContext.getJSModule(com.facebook.react.uimanager.events.RCTEventEmitter::class.java)
        .receiveEvent(view.id, "onAnalysisComplete", map)
    }

    return view
  }

  @ReactProp(name = "imageUri")
  fun setImageUri(view: SubjectLiftView, uri: String) {
    view.imageUri = uri
  }

  override fun getExportedCustomBubblingEventTypeConstants(): Map<String, Any> {
    return MapBuilder.builder<String, Any>()
      .put(
        "onAnalysisComplete",
        MapBuilder.of("phasedRegistrationNames", MapBuilder.of("bubbled", "onAnalysisComplete"))
      )
      .build()
  }
}
