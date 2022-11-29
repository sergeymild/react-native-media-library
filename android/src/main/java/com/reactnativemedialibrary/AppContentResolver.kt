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
  var field = MediaStore.Files.FileColumns.DATE_MODIFIED
  if (input.has("sortBy") && input.getString("sortBy") == "creationTime") {
    field = MediaStore.Files.FileColumns.DATE_ADDED
  }
  putStringArray(ContentResolver.QUERY_ARG_SORT_COLUMNS, arrayOf(field))

  var direction = ContentResolver.QUERY_SORT_DIRECTION_DESCENDING
  if (input.has("sortOrder") && input.getString("sortOrder") == "asc") {
    direction = ContentResolver.QUERY_SORT_DIRECTION_ASCENDING
  }

  putInt(ContentResolver.QUERY_ARG_SORT_DIRECTION, direction)
}


fun addLegacySort(input: JSONObject) {
  var field = MediaStore.Files.FileColumns.DATE_MODIFIED
  if (input.has("sortBy") && input.getString("sortBy") == "creationTime") {
    field = MediaStore.Files.FileColumns.DATE_ADDED
  }

  var direction = "DESC"
  if (input.has("sortOrder") && input.getString("sortOrder") == "asc") {
    direction = "ASC"
  }

  return "$field $direction"
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
    var sortOrder = addLegacySort(input)
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
