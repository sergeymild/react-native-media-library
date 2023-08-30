package com.reactnativemedialibrary

import android.content.ContentUris
import android.content.Context
import android.media.MediaScannerConnection
import android.net.Uri
import com.facebook.proguard.annotations.DoNotStrip
import org.json.JSONObject
import java.io.File

fun JSONObject.string(key: String): String? {
  if (has(key)) return getString(key)
  return null
}

fun JSONObject.long(key: String): Long? {
  if (has(key)) return getLong(key)
  return null
}

object MedialLibraryCreateAsset {

  private fun isFileExtensionPresent(uri: String): Boolean {
    return !uri.substring(uri.lastIndexOf(".") + 1).isEmpty()
  }

  private fun normalizeAssetUri(uri: String): Uri {
    return if (uri.startsWith("/")) {
      Uri.fromFile(File(uri))
    } else Uri.parse(uri)
  }

  private inline fun createAssetFileLegacy(
    context: Context,
    uri: Uri,
    album: String?,
    callback: (String?, File?) -> Unit
  ) {
    val localFile = File(uri.path)
    var destDir = MediaLibraryUtils.getEnvDirectoryForAssetType(
      MediaLibraryUtils.getMimeType(context.contentResolver, uri),
      false
    ) ?: return callback("E_COULD_NOT_GUESS_FILE_TYPE", null)
    if (!album.isNullOrEmpty()) {
      destDir = File(destDir, album)
      if (!destDir.exists() && !destDir.mkdirs()) {
        return callback("E_WRITE_EXTERNAL_STORAGE_CREATE_ALBUM", null)
      }
    }
    val result = MediaLibraryUtils.safeCopyFile(localFile, destDir)
    if (result is String) return callback(result, null)
    val destFile = result as File
    if (!destFile.exists() || !destFile.isFile) {
      return callback("E_COULD_NOT_CREATE_ASSET_RELATED_FILE_IS_NOT_EXISTING", null);
    }
    callback(null, destFile)
  }



  @DoNotStrip
  fun saveToLibrary(
    params: JSONObject,
    context: Context,
    callback: (String?, String?) -> Unit
  ) {
    val localUrl = params.getString("localUrl")
    if (!isFileExtensionPresent(localUrl)) {
      callback.invoke("E_NO_FILE_EXTENSION", null)
      return
    }
    val uri = normalizeAssetUri(localUrl)

    createAssetFileLegacy(context, uri, params.string("album")) { error, asset ->
      if (error != null) return callback(error, null)

      MediaScannerConnection.scanFile(
        context,
        arrayOf(asset!!.path),
        null
      ) { path: String?, newUri: Uri? ->
        if (newUri == null) return@scanFile callback("E_UNABLE_COPY_FILE_TO_EXTERNAL_STORAGE", null)
        callback(null, ContentUris.parseId(newUri).toString())
      }
    }
  }
}
