package com.reactnativemedialibrary

import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Canvas
import android.util.Log
import org.json.JSONObject
import java.io.ByteArrayOutputStream
import java.io.File
import java.net.URL

object CombineImages {
  fun combineImages(input: JSONObject): Boolean {
    val imagesArray = input.getJSONArray("images")
    val resultSavePath = input.getString("resultSavePath")
    val file = File(resultSavePath)

    return try {
      val result = getBitmapFromUrl(imagesArray.getString(0))?.copy(Bitmap.Config.ARGB_8888, true)
      val canvas = result?.let { Canvas(it) } ?: return false
      val parentCenterX = canvas.width / 2F
      val parentCenterY = canvas.height / 2F

      for (i in 0 until imagesArray.length()) {
        val url = imagesArray.getString(i)
        if (i != 0) {
          val bitmap = getBitmapFromUrl(url) ?: return false
          val x = parentCenterX - bitmap.width / 2F
          val y = parentCenterY - bitmap.height / 2F
          canvas.drawBitmap(bitmap, x, y, null)
          bitmap.recycle()
        }
      }
      if (file.exists()) file.delete()
      if (file.parentFile?.exists() != true) {
        if (file.parentFile?.mkdirs() != true) return false
      }
      val byteArrayOutputStream = ByteArrayOutputStream()
      result.compress(Bitmap.CompressFormat.PNG, 100, byteArrayOutputStream)
      val byteArray = byteArrayOutputStream.toByteArray()
      file.writeBytes(byteArray)
      true
    } catch (e: Throwable) {
      Log.e("CombineImages", null, e)
      false
    }
  }

  private fun getBitmapFromUrl(url: String): Bitmap? {
    if (url.startsWith("http") || url.startsWith("file")) {
      val con = URL(url).openConnection()
      con.connect()
      con.getInputStream().use {
        return BitmapFactory.decodeStream(it)
      }
    } else {
      val file = File(url)
      if (!file.exists()) return null
      file.inputStream().use {
        return BitmapFactory.decodeStream(it)
      }
    }
  }
}
