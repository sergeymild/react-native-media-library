package com.reactnativemedialibrary

import android.content.Context
import android.graphics.Bitmap
import android.media.MediaMetadataRetriever
import android.net.Uri
import android.webkit.URLUtil
import org.json.JSONObject
import java.io.File
import java.io.FileOutputStream


fun Context.fetchFrame(input: JSONObject): JSONObject? {
  var response: JSONObject? = null
  val retriever = MediaLibraryUtils.retriever
  val time = input.long("time") ?: 0
  val url = input.getString("url")
  val quality = input.long("quality") ?: 1
  if (URLUtil.isFileUrl(url)) {
    retriever.setDataSource(Uri.decode(url).replace("file://", ""))
  } else if (URLUtil.isContentUrl(url)) {
    val fileUri = Uri.parse(url)
    val fileDescriptor = contentResolver.openFileDescriptor(fileUri, "r")?.fileDescriptor
    retriever.setDataSource(fileDescriptor)
  } else {
    retriever.setDataSource(url)
  }

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
  retriever.release()
  return response
}

