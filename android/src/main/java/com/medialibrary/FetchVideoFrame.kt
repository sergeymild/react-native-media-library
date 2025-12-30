package com.medialibrary

import android.content.Context
import android.graphics.Bitmap
import android.media.MediaMetadataRetriever
import android.net.Uri
import com.medialibrary.MediaLibraryUtils.withRetriever
import org.json.JSONObject
import java.io.File
import java.io.FileOutputStream
import java.lang.RuntimeException


fun Context.fetchFrame(input: JSONObject): JSONObject? {
  try {
    var response: JSONObject? = null
    val time = input.long("time") ?: 0
    val url = input.getString("url")
    val quality = input.long("quality") ?: 1
    withRetriever(contentResolver, Uri.parse(url)) { retriever ->
      retriever.getFrameAtTime(time, MediaMetadataRetriever.OPTION_CLOSEST_SYNC)?.let { thumbnail ->
        val path = MediaLibraryUtils.generateOutputPath(cacheDir, "VideoThumbnails", "jpg")
        FileOutputStream(path).use { output ->
          thumbnail.compress(Bitmap.CompressFormat.JPEG, (quality * 100).toInt(), output)
          response = JSONObject().also {
            it.put("url", Uri.fromFile(File(path)).toString())
            it.put("width", thumbnail.width)
            it.put("height", thumbnail.height)
          }
        }
      }
    }
    return response
  } catch (e: RuntimeException) {
    return null
  }
}

