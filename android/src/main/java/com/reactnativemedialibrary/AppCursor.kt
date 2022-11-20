package com.reactnativemedialibrary

import android.content.ContentResolver
import android.database.Cursor
import android.graphics.BitmapFactory
import android.media.MediaMetadataRetriever
import android.net.Uri
import android.provider.MediaStore
import org.json.JSONArray
import org.json.JSONObject

private fun toSet(array: JSONArray): Set<String> {
  val strings = HashSet<String>(array.length())
  for (i in 0 until array.length()) {
    strings.add(array.getString(i))
  }
  return strings
}

private fun exportMediaType(mediaType: Int): String {
  return when (mediaType) {
    MediaStore.Files.FileColumns.MEDIA_TYPE_IMAGE -> "photo"
    MediaStore.Files.FileColumns.MEDIA_TYPE_AUDIO, MediaStore.Files.FileColumns.MEDIA_TYPE_PLAYLIST -> "audio"
    MediaStore.Files.FileColumns.MEDIA_TYPE_VIDEO -> "video"
    else -> "unknown"
  }
}

private fun getAssetDimensionsFromCursor(
  cursor: Cursor,
  contentResolver: ContentResolver,
  mediaType: Int,
  localUriColumnIndex: Int
): IntArray {
  val uri = cursor.getString(localUriColumnIndex)
  if (mediaType == MediaStore.Files.FileColumns.MEDIA_TYPE_VIDEO) {
    val videoUri = Uri.parse("file://$uri")
    contentResolver.openAssetFileDescriptor(videoUri, "r").use { r ->
      MediaMetadataRetriever().use { retriever ->
        retriever.setDataSource(r!!.fileDescriptor)
        val videoWidth =
          retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_VIDEO_WIDTH)
        val videoHeight =
          retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_VIDEO_HEIGHT)
        return intArrayOf(videoWidth!!.toInt(), videoHeight!!.toInt())
      }
    }
  }
  val widthIndex = cursor.getColumnIndex(MediaStore.MediaColumns.WIDTH)
  val heightIndex = cursor.getColumnIndex(MediaStore.MediaColumns.HEIGHT)
  var width = cursor.getInt(widthIndex)
  var height = cursor.getInt(heightIndex)
  // If the image doesn't have the required information, we can get them from Bitmap.Options
  if (mediaType == MediaStore.Files.FileColumns.MEDIA_TYPE_IMAGE && (width <= 0 || height <= 0)) {
    val options = BitmapFactory.Options()
    options.inJustDecodeBounds = true
    BitmapFactory.decodeFile(uri, options)
    width = options.outWidth
    height = options.outHeight
  }
  return intArrayOf(width, height)
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
    `object`.put("filename", getString(filenameIndex))
    `object`.put("id", assetId)
    `object`.put("creationTime", getLong(creationDateIndex) * 1000.0)
    `object`.put("modificationTime", getLong(modificationDateIndex) * 1000.0)
    `object`.put("mediaType", exportMediaType(mediaType))
    `object`.put("duration", getInt(durationIndex) / 1000.0)
    `object`.put("width", widthHeight[0])
    `object`.put("height", widthHeight[1])
    `object`.put("url", localUri)
    `object`.put("uri", localUri)
    array.put(`object`)
    if (limit == 1) break
  }
}
