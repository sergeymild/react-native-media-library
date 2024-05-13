package com.reactnativemedialibrary

import android.content.Context
import android.content.res.Resources
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Canvas
import android.graphics.Paint
import android.util.Log
import androidx.annotation.ColorInt
import com.facebook.react.uimanager.PixelUtil
import org.json.JSONArray
import org.json.JSONObject
import java.io.ByteArrayOutputStream
import java.io.File
import java.io.InputStream
import java.lang.RuntimeException
import java.net.URI
import java.net.URL


fun toCompressFormat(format: String): Bitmap.CompressFormat {
  return when (format) {
    "jpeg" -> Bitmap.CompressFormat.JPEG
    "jpg" -> Bitmap.CompressFormat.JPEG
    "png" -> Bitmap.CompressFormat.PNG
    else -> Bitmap.CompressFormat.PNG
  }
}

class ManipulateImages(private val context: Context) {
  fun combineImages(input: JSONObject): Boolean {
    val imagesArray = input.getJSONArray("images")
    val resultSavePath = input.getString("resultSavePath").fixFilePathFromJs()
    val mainImageIndex = input.optInt("mainImageIndex", -1).takeIf { it != -1 } ?: 0

    @ColorInt
    val backgroundColor = input.optInt("backgroundColor", -1).takeIf { it != -1 }
    val file = File(resultSavePath)

    return try {
      val mainImageJson = imagesArray.getJSONObject(mainImageIndex)
      val mainImage = mainImageJson.getString("image").fixFilePathFromJs()
      println("🗡️ $mainImage")
      val mainBitmap = getBitmapFromUrl(mainImage)?.copy(Bitmap.Config.ARGB_8888, true)
      mainBitmap ?: return false
      val canvas = Canvas(mainBitmap)
      val parentCenterX = canvas.width / 2F
      val parentCenterY = canvas.height / 2F

      if (backgroundColor != null) {
        canvas.drawPaint(Paint().apply {
          color = backgroundColor
          style = Paint.Style.FILL
        })
      }

      for (i in 0 until (imagesArray.length())) {
        val obj = imagesArray.getJSONObject(i)
        val url = obj.getString("image").fixFilePathFromJs()
        if (mainImageIndex == i) continue
        println("🗡️ $url")
        val bitmap = getBitmapFromUrl(url) ?: return false
        val positions = obj.optJSONObject("positions")
        var x = parentCenterX - bitmap.width / 2F
        var y = parentCenterY - bitmap.height / 2F
        if (positions != null) {
          x = PixelUtil.toPixelFromDIP(positions.getDouble("x").toFloat())
          y = PixelUtil.toPixelFromDIP(positions.getDouble("y").toFloat())
          if (x > canvas.width) x = (canvas.width - bitmap.width).toFloat()
          if (y > canvas.height) y = (canvas.height - bitmap.height).toFloat()
          if (x < 0) x = 0F
          if (y <= 0) y = 0F
        }
        canvas.drawBitmap(bitmap, x, y, null)
        bitmap.recycle()
      }
      if (file.exists()) file.delete()
      if (file.parentFile?.exists() != true) {
        if (file.parentFile?.mkdirs() != true) return false
      }
      val byteArrayOutputStream = ByteArrayOutputStream()
      mainBitmap.compress(Bitmap.CompressFormat.PNG, 100, byteArrayOutputStream)
      val byteArray = byteArrayOutputStream.toByteArray()
      file.writeBytes(byteArray)
      mainBitmap.recycle()
      true
    } catch (e: Throwable) {
      Log.e("CombineImages", null, e)
      false
    }
  }

  fun imageResize(input: JSONObject): Boolean {
    val uri = input.getString("uri").fixFilePathFromJs()
    val width = input.getDouble("width")
    val height = input.getDouble("height")
    val format = input.getString("format")
    val resultSavePath = input.getString("resultSavePath").fixFilePathFromJs()
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
    val uri = input.getString("uri").fixFilePathFromJs()
    val x = input.getDouble("x")
    val y = input.getDouble("y")
    val width = input.getDouble("width")
    val height = input.getDouble("height")
    val format = input.getString("format")
    val resultSavePath = input.getString("resultSavePath").fixFilePathFromJs()
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

  // TODO: rename to getImagesDimensions
  fun imageSizes(input: JSONObject): JSONArray {
    val imagesArray = input.getJSONArray("images")
    val imagesDimensions = JSONArray()

    Log.d("MediaLibrary", "getImagesDimensions")

    try {
      for (i in 0 until imagesArray.length()) {
        val url = imagesArray.getString(i).fixFilePathFromJs()
        val bitmap = getBitmapFromUrl(url) ?: throw RuntimeException("failCreateBitmap")

        val imageDimensions = JSONObject()
        imageDimensions.put("width", bitmap.width)
        imageDimensions.put("height", bitmap.height)
        imagesDimensions.put(imageDimensions)
      }
    } catch (error: Throwable) {
      Log.e("MediaLibrary", "Couldn't determine Image Dimensions", error)
    }

    return imagesDimensions
  }

  private fun getBitmapFromUrl(source: String?): Bitmap? {
    source ?: return null
    val resourceId: Int =
      context.resources.getIdentifier(source, "drawable", context.packageName)

    return if (resourceId == 0) {
      val uri = URI(source.fixFilePathToJs())
      BitmapFactory.decodeStream(uri.toURL().openConnection().getInputStream())
    } else {
      BitmapFactory.decodeResource(context.resources, resourceId)
    }
  }
}
