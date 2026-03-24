package com.subjectlift

import android.content.Context
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.util.Base64
import android.view.View
import com.facebook.react.bridge.Arguments
import com.facebook.react.bridge.WritableMap
import com.facebook.react.uimanager.events.RCTEventEmitter
import com.google.mlkit.vision.common.InputImage
import com.google.mlkit.vision.segmentation.subject.SubjectSegmentation
import com.google.mlkit.vision.segmentation.subject.SubjectSegmenterOptions
import java.io.ByteArrayOutputStream
import java.io.File
import java.net.URL

class SubjectLiftView(context: Context) : View(context) {

  var imageUri: String = ""
    set(value) {
      field = value
      if (value.isNotEmpty()) runSegmentation()
    }

  var onAnalysisComplete: ((WritableMap) -> Unit)? = null

  // MARK: - Segmentation

  private fun runSegmentation() {
    Thread {
      try {
        val bitmap = loadBitmap(imageUri) ?: run {
          emitError("Failed to load image at: $imageUri")
          return@Thread
        }

        val options = SubjectSegmenterOptions.Builder()
          .enableForegroundBitmap()
          .build()

        val segmenter = SubjectSegmentation.getClient(options)
        val inputImage = InputImage.fromBitmap(bitmap, 0)

        segmenter.process(inputImage)
          .addOnSuccessListener { result ->
            val foreground = result.foregroundBitmap
            val base64 = bitmapToBase64(foreground)
            val map = Arguments.createMap()
            map.putString("status", "ready")
            map.putString("base64", base64)
            onAnalysisComplete?.invoke(map)
          }
          .addOnFailureListener { e ->
            emitError(e.message ?: "Segmentation failed")
          }
      } catch (e: Exception) {
        emitError(e.message ?: "Unknown error")
      }
    }.start()
  }

  private fun loadBitmap(uri: String): Bitmap? {
    return if (uri.startsWith("http://") || uri.startsWith("https://")) {
      val stream = URL(uri).openStream()
      BitmapFactory.decodeStream(stream)
    } else {
      val path = uri.removePrefix("file://")
      BitmapFactory.decodeFile(path)
    }
  }

  private fun bitmapToBase64(bitmap: Bitmap?): String {
    if (bitmap == null) return ""
    val stream = ByteArrayOutputStream()
    bitmap.compress(Bitmap.CompressFormat.PNG, 100, stream)
    return Base64.encodeToString(stream.toByteArray(), Base64.DEFAULT)
  }

  private fun emitError(message: String) {
    val map = Arguments.createMap()
    map.putString("status", "error")
    map.putString("message", message)
    onAnalysisComplete?.invoke(map)
  }
}
