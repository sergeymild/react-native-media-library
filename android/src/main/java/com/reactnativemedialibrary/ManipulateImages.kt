package com.reactnativemedialibrary

import android.R.attr
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Canvas
import android.graphics.Matrix
import android.util.Log
import org.json.JSONArray
import org.json.JSONObject
import java.io.ByteArrayOutputStream
import java.io.File
import java.net.URL
import kotlin.math.min


fun toCompressFormat(format: String): Bitmap.CompressFormat {
  return when (format) {
    "jpeg" -> Bitmap.CompressFormat.JPEG
    "jpg" -> Bitmap.CompressFormat.JPEG
    "png" -> Bitmap.CompressFormat.PNG
    else -> Bitmap.CompressFormat.PNG
  }
}

object ManipulateImages {
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

  fun imageResize(input: JSONObject): Boolean {
    val uri = input.getString("uri")
    val width = input.getDouble("width")
    val height = input.getDouble("height")
    val format = input.getString("format")
    val resultSavePath = input.getString("resultSavePath")
    val file = File(resultSavePath)

    return try {
      var bitmap = getBitmapFromUrl(uri) ?: return false
      val currentImageRatio = bitmap.width.toFloat() / bitmap.height
      var newWidth = 0
      var newHeight = 0
      if (width >= 0) {
        newWidth = width.toInt()
        newHeight = (newWidth / currentImageRatio).toInt()
      }

      if (height >= 0) {
        newHeight = height.toInt()
        newWidth = if (newWidth == 0) (currentImageRatio * newHeight).toInt() else newWidth
      }
      bitmap = Bitmap.createScaledBitmap(bitmap, newWidth, newHeight, true)

      file.outputStream().use { fileOut ->
        bitmap.compress(toCompressFormat(format), 100, fileOut)
      }
      true
    } catch (e: Throwable) {
      Log.e("CombineImages", null, e)
      false
    }
  }

  fun imageCrop(input: JSONObject): Boolean {
    val uri = input.getString("uri")
    val x = input.getDouble("x")
    val y = input.getDouble("y")
    val width = input.getDouble("width")
    val height = input.getDouble("height")
    val format = input.getString("format")
    val resultSavePath = input.getString("resultSavePath")
    val file = File(resultSavePath)

    return try {
      var bitmap = getBitmapFromUrl(uri) ?: return false
      var cropX = (x * bitmap.width).toInt()
      if (cropX + width > bitmap.width) {
        cropX = bitmap.width - width.toInt()
      }

      var cropY = (y * bitmap.height).toInt()
      if (cropY + height > bitmap.height) {
        cropY = bitmap.height - height.toInt()
      }


      bitmap = Bitmap.createBitmap(bitmap, cropX, cropY, width.toInt(), height.toInt(), null, true)

      file.outputStream().use { fileOut ->
        bitmap.compress(toCompressFormat(format), 100, fileOut)
      }
      true
    } catch (e: Throwable) {
      Log.e("CombineImages", null, e)
      false
    }
  }


  fun imageSizes(input: JSONObject): JSONArray {
    val imagesArray = input.getJSONArray("images")
    val array = JSONArray()
    try {
      for (i in 0 until imagesArray.length()) {
        val url = imagesArray.getString(i)
        val bitmap = getBitmapFromUrl(url) ?: return JSONArray()
        val obj = JSONObject()
        obj.put("width", bitmap.width)
        obj.put("height", bitmap.height)
        array.put(obj)
        bitmap.recycle()
      }
    } catch (e: Throwable) {
      Log.e("CombineImages", null, e)
    }
    return array
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
