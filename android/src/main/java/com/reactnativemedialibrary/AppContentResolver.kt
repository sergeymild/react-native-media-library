package com.reactnativemedialibrary

import android.content.ContentResolver
import android.content.Context
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.provider.MediaStore
import androidx.annotation.RequiresApi
import org.json.JSONArray
import org.json.JSONObject
import java.lang.RuntimeException

fun String?.asJsonInput(): JSONObject {
  if (this != null) return JSONObject(this)
  return JSONObject()
}

var ASSET_PROJECTION = arrayOf(
  MediaStore.Files.FileColumns._ID,
  MediaStore.Files.FileColumns.DISPLAY_NAME,
  MediaStore.Files.FileColumns.DATA,
  MediaStore.Files.FileColumns.MEDIA_TYPE,
  MediaStore.MediaColumns.WIDTH,
  MediaStore.MediaColumns.HEIGHT,
  MediaLibrary.dateAdded,
  MediaStore.Files.FileColumns.DATE_MODIFIED,
  MediaStore.Images.Media.ORIENTATION,
  MediaStore.Video.VideoColumns.DURATION,
  MediaStore.Images.Media.BUCKET_ID
)

private fun mediaTypeToInt(mediaType: String): Int {
  return when (mediaType) {
    "photo" -> MediaStore.Files.FileColumns.MEDIA_TYPE_IMAGE
    "audio" -> MediaStore.Files.FileColumns.MEDIA_TYPE_AUDIO
    "video" -> MediaStore.Files.FileColumns.MEDIA_TYPE_VIDEO
    else -> MediaStore.Files.FileColumns.MEDIA_TYPE_NONE
  }
}

private fun sortBy(input: JSONObject): String {
  if (!input.has("sortBy")) return MediaStore.Images.Media.DEFAULT_SORT_ORDER
  val sortBy = input.getString("sortBy")
  return if (!input.has("sortOrder")) sortToColumnName(sortBy) else sortToColumnName(sortBy) + " " + input.getString(
    "sortOrder"
  )
}

private fun sortToColumnName(sort: String): String {
  if (sort == "creationTime") return MediaLibrary.dateAdded
  if (sort == "modificationTime") return MediaStore.Files.FileColumns.DATE_MODIFIED
  throw RuntimeException("Unsupported $sort")
}


@RequiresApi(Build.VERSION_CODES.O)
fun Bundle.addLimitOffset(input: JSONObject) {
  if (input.has("limit")) putInt(ContentResolver.QUERY_ARG_LIMIT, input.getInt("limit"))
  if (input.has("offset")) putInt(ContentResolver.QUERY_ARG_OFFSET, input.getInt("offset"))
}

@RequiresApi(Build.VERSION_CODES.O)
fun Bundle.addSort(input: JSONObject) {
  // Sort function
  putStringArray(     // <-- This should be an array. I spent a whole day trying to figure out what I was doing wrong
    ContentResolver.QUERY_ARG_SORT_COLUMNS,
    arrayOf(MediaStore.Files.FileColumns.DATE_MODIFIED)
  )

  putInt(
    ContentResolver.QUERY_ARG_SORT_DIRECTION,
    ContentResolver.QUERY_SORT_DIRECTION_DESCENDING
  )
}

fun ContentResolver.listQuery(
  uri: Uri,
  context: Context,
  input: JSONObject,
): JSONArray {
  val selection =
    "${MediaStore.Files.FileColumns.MEDIA_TYPE} = ? OR ${MediaStore.Files.FileColumns.MEDIA_TYPE} = ?"
  val selectionArgs = arrayOf(
    MediaStore.Files.FileColumns.MEDIA_TYPE_IMAGE.toString(),
    MediaStore.Files.FileColumns.MEDIA_TYPE_VIDEO.toString()
  )
  return makeQuery(uri, context, input, selection, selectionArgs)
}

fun ContentResolver.singleQuery(
  uri: Uri,
  context: Context,
  input: JSONObject,
  id: String
): JSONArray {
  val selection = "${MediaStore.Files.FileColumns._ID} = ?"
  val selectionArgs = arrayOf(id)
  input.put("limit", 1)
  return makeQuery(uri, context, input, selection, selectionArgs)
}

fun ContentResolver.makeQuery(
  uri: Uri,
  context: Context,
  input: JSONObject,
  selection: String,
  selectionArgs: Array<String>
): JSONArray {
  val galleryImageUrls = JSONArray()

  val limit = if (input.has("limit")) input.getInt("limit") else -1
  val offset = if (input.has("offset")) input.getInt("offset") else -1
  /**
   * Change the way to fetch Media Store
   */
  if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
    // Get All data in Cursor by sorting in DESC order
    context.contentResolver.query(
      uri,
      ASSET_PROJECTION,
      Bundle().apply {
        // Limit & Offset
        addLimitOffset(input)
        addSort(input)
        // Selection
        putString(ContentResolver.QUERY_ARG_SQL_SELECTION, selection)
        putStringArray(
          ContentResolver.QUERY_ARG_SQL_SELECTION_ARGS,
          selectionArgs
        )
      }, null
    )
  } else {
    var sortOrder = "${MediaStore.Files.FileColumns.DATE_MODIFIED} DESC"
    if (limit > 0) sortOrder += " LIMIT $limit"
    if (offset > 0) sortOrder += " OFFSET $offset"
    // Get All data in Cursor by sorting in DESC order
    context.contentResolver.query(
      uri,
      ASSET_PROJECTION,
      selection,
      selectionArgs,
      sortOrder
    )
  }?.use { cursor ->
    cursor.mapToJson(this, galleryImageUrls, input, limit)
  }

  return galleryImageUrls
}
