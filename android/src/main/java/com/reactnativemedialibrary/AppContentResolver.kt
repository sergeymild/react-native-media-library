package com.reactnativemedialibrary

import android.content.ContentResolver
import android.content.Context
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.provider.MediaStore
import android.provider.MediaStore.Files.FileColumns.*
import androidx.annotation.RequiresApi
import org.json.JSONArray
import org.json.JSONObject

fun String?.asJsonInput(): JSONObject {
  if (this != null) return JSONObject(this)
  return JSONObject()
}

var ASSET_PROJECTION = arrayOf(
  _ID,
  DISPLAY_NAME,
  DATA,
  //MediaStore.Files.FileColumns.IS_FAVORITE,
  MEDIA_TYPE,
  MediaStore.MediaColumns.WIDTH,
  MediaStore.MediaColumns.HEIGHT,
  MediaLibrary.dateAdded,
  DATE_MODIFIED,
  MediaStore.Images.Media.ORIENTATION,
  MediaStore.Video.VideoColumns.DURATION,
  MediaStore.Images.Media.BUCKET_ID
)

@RequiresApi(Build.VERSION_CODES.O)
fun Bundle.addLimitOffset(input: JSONObject) {
  if (input.has("limit")) putInt(ContentResolver.QUERY_ARG_LIMIT, input.getInt("limit"))
  if (input.has("offset")) putInt(ContentResolver.QUERY_ARG_OFFSET, input.getInt("offset"))
}

@RequiresApi(Build.VERSION_CODES.O)
fun Bundle.addSort(input: JSONObject) {
  // Sort function
  var field = DATE_MODIFIED
  if (input.has("sortBy") && input.getString("sortBy") == "creationTime") {
    field = DATE_ADDED
  }
  putStringArray(ContentResolver.QUERY_ARG_SORT_COLUMNS, arrayOf(field))

  var direction = ContentResolver.QUERY_SORT_DIRECTION_DESCENDING
  if (input.has("sortOrder") && input.getString("sortOrder") == "asc") {
    direction = ContentResolver.QUERY_SORT_DIRECTION_ASCENDING
  }

  putInt(ContentResolver.QUERY_ARG_SORT_DIRECTION, direction)
}


@RequiresApi(Build.VERSION_CODES.O)
fun Bundle.sqlSelection(input: String) {
  putString(ContentResolver.QUERY_ARG_SQL_SELECTION, input)
}

@RequiresApi(Build.VERSION_CODES.O)
fun Bundle.sqlArgs(selectionArgs: Array<String>) {
  putStringArray(
    ContentResolver.QUERY_ARG_SQL_SELECTION_ARGS,
    selectionArgs
  )
}


fun addLegacySort(input: JSONObject): String {
  var field = DATE_MODIFIED
  if (input.has("sortBy") && input.getString("sortBy") == "creationTime") {
    field = DATE_ADDED
  }

  var direction = "DESC"
  if (input.has("sortOrder") && input.getString("sortOrder") == "asc") {
    direction = "ASC"
  }

  return "$field $direction"
}

data class Tuple(val selection: String, val arguments: Array<String>)
fun queryByMediaType(input: JSONObject): Tuple {
  val selection = mutableListOf<String>()
  val arguments = mutableListOf<String>()
  if (input.has(AssetItemKeys.mediaType.name)) {
    val jsonArray = input.getJSONArray(AssetItemKeys.mediaType.name)
    for (i in (0 until jsonArray.length())) {
      when (jsonArray.getString(i)) {
          AssetMediaType.video.name -> {
            selection.add("$MEDIA_TYPE = ?")
            arguments.add(MEDIA_TYPE_VIDEO.toString())
          }
          AssetMediaType.audio.name -> {
            selection.add("$MEDIA_TYPE = ?")
            arguments.add(MEDIA_TYPE_AUDIO.toString())
          }
          AssetMediaType.photo.name -> {
            selection.add("$MEDIA_TYPE = ?")
            arguments.add(MEDIA_TYPE_IMAGE.toString())
          }
      }
    }
  }
  if (selection.isEmpty()) {
    selection.add("$MEDIA_TYPE = ?")
    selection.add("$MEDIA_TYPE = ?")
    selection.add("$MEDIA_TYPE = ?")
    arguments.add(MEDIA_TYPE_VIDEO.toString())
    arguments.add(MEDIA_TYPE_AUDIO.toString())
    arguments.add(MEDIA_TYPE_IMAGE.toString())
  }
  return Tuple(selection.joinToString(" OR "), arguments.toTypedArray())
}

fun ContentResolver.listQuery(
  uri: Uri,
  context: Context,
  input: JSONObject,
): JSONArray {
  var (selection, arguments) = queryByMediaType(input)
  if (input.has("collectionId")) {
    if (selection.isNotEmpty()) selection = "($selection) AND "
    selection += "${MediaStore.Images.Media.BUCKET_ID} = ?"
    arguments = arrayOf(*arguments, input.getString("collectionId"))
  }
  println("⚽️ SELECT: $selection, ${arguments.contentToString()}")
  return makeQuery(uri, context, input, selection, arguments)
}

fun ContentResolver.getCollections(mediaType: Int): JSONArray {
  var contentUri = MediaStore.Images.Media.EXTERNAL_CONTENT_URI
  if (mediaType == MEDIA_TYPE_VIDEO) {
    contentUri = MediaStore.Video.Media.EXTERNAL_CONTENT_URI
  }

  val projection = arrayOf(MediaStore.Images.ImageColumns.BUCKET_ID, MediaStore.Images.ImageColumns.BUCKET_DISPLAY_NAME)
  val cursor = this.query(contentUri, projection, null, null, null)

  val array = JSONArray()
  val buckets = mutableMapOf<String, JSONObject>()
  if (cursor != null) {
    while (cursor.moveToNext()) {
      val name = cursor.getString(cursor.getColumnIndexOrThrow(MediaStore.Images.ImageColumns.BUCKET_DISPLAY_NAME))
      val bucketId = cursor.getString(cursor.getColumnIndexOrThrow(MediaStore.Images.ImageColumns.BUCKET_ID))
      if (buckets.containsKey(bucketId)) {
        var count = buckets[bucketId]!!.getInt("count")
        if (count == 0) count = 1
        buckets[bucketId]!!.put("count", count + 1)
        continue
      }
      val item = JSONObject()
      item.put("filename", name)
      item.put("id", bucketId)
      item.put("count", 0)
      buckets[bucketId] = item
      array.put(item)
    }
    cursor.close()

  }
  return array

}

fun ContentResolver.singleQuery(
  uri: Uri,
  context: Context,
  input: JSONObject,
  id: String
): JSONArray {
  val selection = "$_ID = ?"
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
        addLimitOffset(input)
        addSort(input)
        sqlSelection(selection)
        sqlArgs(selectionArgs)
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
