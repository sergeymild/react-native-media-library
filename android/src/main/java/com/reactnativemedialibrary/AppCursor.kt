package com.reactnativemedialibrary

import android.content.ContentResolver
import android.database.Cursor
import android.graphics.BitmapFactory
import android.media.ExifInterface
import android.net.Uri
import android.provider.MediaStore
import android.util.Log
import com.reactnativemedialibrary.AssetItemKeys.*
import org.json.JSONArray
import org.json.JSONObject
import java.io.IOException
import kotlin.math.abs

private fun toSet(array: JSONArray): Set<String> {
  val strings = HashSet<String>(array.length())
  for (i in 0 until array.length()) {
    strings.add(array.getString(i))
  }
  return strings
}

private fun exportMediaType(mediaType: Int): String {
  return when (mediaType) {
    MediaStore.Files.FileColumns.MEDIA_TYPE_IMAGE -> AssetMediaType.photo.name
    MediaStore.Files.FileColumns.MEDIA_TYPE_AUDIO, MediaStore.Files.FileColumns.MEDIA_TYPE_PLAYLIST -> AssetMediaType.audio.name
    MediaStore.Files.FileColumns.MEDIA_TYPE_VIDEO -> AssetMediaType.video.name
    else -> "unknown"
  }
}

private fun maybeRotateAssetSize(width: Int, height: Int, orientation: Int): IntArray {
  // given width and height might need to be swapped if the orientation is -90 or 90
  return if (abs(orientation) % 180 == 90) {
    intArrayOf(height, width)
  } else {
    intArrayOf(width, height)
  }
}

private fun getOrientation(cursor: Cursor, uri: String, mediaType: Int): Int {
  val orientationIndex = cursor.getColumnIndex(MediaStore.Images.Media.ORIENTATION)
  var orientation = cursor.getInt(orientationIndex)
  if (mediaType == MediaStore.Files.FileColumns.MEDIA_TYPE_IMAGE) {
    var exifInterface: ExifInterface? = null
    try {
      exifInterface = ExifInterface(uri)
    } catch (e: IOException) {
      Log.w("media-library", "Could not parse EXIF tags for $uri")
      e.printStackTrace()
    }
    if (exifInterface != null) {
      val exifOrientation = exifInterface.getAttributeInt(
        ExifInterface.TAG_ORIENTATION,
        ExifInterface.ORIENTATION_NORMAL
      )
      if (exifOrientation == ExifInterface.ORIENTATION_ROTATE_90 ||
        exifOrientation == ExifInterface.ORIENTATION_ROTATE_270 ||
        exifOrientation == ExifInterface.ORIENTATION_TRANSPOSE ||
        exifOrientation == ExifInterface.ORIENTATION_TRANSVERSE
      ) {
        orientation = 90
      }
    }
  }
  return orientation
}

private fun getAssetDimensionsFromCursor(
  cursor: Cursor,
  contentResolver: ContentResolver,
  mediaType: Int,
  localUriColumnIndex: Int
): IntArray {
  val size = IntArray(2)
  val uri = cursor.getString(localUriColumnIndex)

  val widthIndex = cursor.getColumnIndex(MediaStore.MediaColumns.WIDTH)
  val heightIndex = cursor.getColumnIndex(MediaStore.MediaColumns.HEIGHT)
  var width = cursor.getInt(widthIndex)
  var height = cursor.getInt(heightIndex)
  val orientation = getOrientation(cursor, uri, mediaType)
  val isNoWH = (width <= 0 || height <= 0)

  if (isNoWH && mediaType == MediaStore.Files.FileColumns.MEDIA_TYPE_VIDEO) {
    val videoUri = Uri.parse("file://$uri")
    MediaLibraryUtils.retrieveWidthHeightFromMedia(contentResolver, videoUri, size)
    if (size[0] > 0 && size[1] > 0) return maybeRotateAssetSize(size[0], size[1], orientation)
  }

  // If the image doesn't have the required information, we can get them from Bitmap.Options
  if (mediaType == MediaStore.Files.FileColumns.MEDIA_TYPE_IMAGE && (width <= 0 || height <= 0)) {
    val options = BitmapFactory.Options()
    options.inJustDecodeBounds = true
    BitmapFactory.decodeFile(uri, options)
    width = options.outWidth
    height = options.outHeight
  }
  return maybeRotateAssetSize(width, height, orientation)
}

fun Cursor.mapToJson(
  contentResolver: ContentResolver,
  array: JSONArray,
  input: JSONObject,
  limit: Int
) {
  val idIndex = getColumnIndex(MediaStore.Images.Media._ID)
  val filenameIndex = getColumnIndex(MediaStore.Files.FileColumns.DISPLAY_NAME)
  val mediaTypeIndex = getColumnIndex(MediaStore.Files.FileColumns.MEDIA_TYPE)
  val creationDateIndex = getColumnIndex(MediaLibrary.dateAdded)
  val modificationDateIndex =
    getColumnIndex(MediaStore.Files.FileColumns.DATE_MODIFIED)
  val durationIndex = getColumnIndex(MediaStore.Video.VideoColumns.DURATION)
  val localUriIndex = getColumnIndex(MediaStore.Images.Media.DATA)
  var extensions: Set<String>? = null
  if (input.has("extensions")) {
    extensions = toSet(input.getJSONArray("extensions"))
  }
  while (moveToNext()) {
    val assetId = getString(idIndex)
    val path = getString(localUriIndex)
    val extension = path.substring(path.lastIndexOf(".") + 1)
    if (extensions != null && !extensions.contains(extension)) {
      continue
    }
    val localUri = "file://$path"
    val mediaType = getInt(mediaTypeIndex)
    val widthHeight =
      getAssetDimensionsFromCursor(this, contentResolver, mediaType, localUriIndex)
    val `object` = JSONObject()
    `object`.put(filename.name, getString(filenameIndex))
    `object`.put(id.name, assetId)
    `object`.put(creationTime.name, getLong(creationDateIndex) * 1000.0)
    `object`.put(modificationTime.name, getLong(modificationDateIndex) * 1000.0)
    `object`.put(AssetItemKeys.mediaType.name, exportMediaType(mediaType))
    `object`.put(duration.name, getInt(durationIndex) / 1000.0)
    `object`.put(width.name, widthHeight[0])
    `object`.put(height.name, widthHeight[1])
    `object`.put(url.name, localUri)
    `object`.put(uri.name, localUri)
    array.put(`object`)
    if (limit == 1) break
  }
}
