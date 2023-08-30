package com.reactnativemedialibrary

import android.content.ContentResolver
import android.graphics.Bitmap
import android.media.MediaMetadataRetriever
import android.media.MediaMetadataRetriever.METADATA_KEY_VIDEO_HEIGHT
import android.media.MediaMetadataRetriever.METADATA_KEY_VIDEO_WIDTH
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.os.ParcelFileDescriptor
import android.provider.MediaStore
import android.webkit.MimeTypeMap
import android.webkit.URLUtil
import androidx.exifinterface.media.ExifInterface
import org.json.JSONException
import org.json.JSONObject
import java.io.File
import java.io.IOException
import java.util.*
import java.util.regex.Matcher
import java.util.regex.Pattern


object MediaLibraryUtils {

  val retriever: MediaMetadataRetriever
    get() = MediaMetadataRetriever()

  private val iSO6709LocationPattern = Pattern.compile("([+\\-][0-9.]+)([+\\-][0-9.]+)")

  fun getMimeTypeFromFileUrl(url: String?): String? {
    val extension = MimeTypeMap.getFileExtensionFromUrl(url) ?: return null
    return MimeTypeMap.getSingleton().getMimeTypeFromExtension(extension)
  }

  fun getMimeType(contentResolver: ContentResolver, uri: Uri): String? {
    val type = contentResolver.getType(uri)
    return type ?: getMimeTypeFromFileUrl(uri.toString())
  }

  fun getRelativePathForAssetType(mimeType: String?, useCameraDir: Boolean): String {
    if (mimeType != null && (mimeType.contains("image") || mimeType.contains("video"))) {
      return if (useCameraDir) Environment.DIRECTORY_DCIM else Environment.DIRECTORY_PICTURES
    } else if (mimeType != null && mimeType.contains("audio")) {
      return Environment.DIRECTORY_MUSIC
    }
    return if (useCameraDir) Environment.DIRECTORY_DCIM else Environment.DIRECTORY_PICTURES
  }

  fun getEnvDirectoryForAssetType(mimeType: String?, useCameraDir: Boolean): File {
    return Environment.getExternalStoragePublicDirectory(
      getRelativePathForAssetType(mimeType, useCameraDir)
    )
  }

  fun copyBitmapToFile(
    bitmap: Bitmap,
    path: String,
    format: Bitmap.CompressFormat = Bitmap.CompressFormat.JPEG,
    quality: Int = 100,
  ): Boolean {
    val file = File(path)
    if (file.extension.isEmpty()) {
      println("ERROR: extension must be present, FILE: ${file.absolutePath}")
      return false
    }
    return File(path).outputStream().use { output ->
      return@use bitmap.compress(format, quality, output)
    }
  }

  @Throws(IOException::class, JSONException::class)
  fun safeCopyFile(src: File, destDir: File?): Any {
    println("👌 ${src.absolutePath}")
    var newFile = File(destDir, src.name)
    var suffix = 0
    val filename = src.nameWithoutExtension
    val extension = src.extension
    val suffixLimit = Short.MAX_VALUE.toInt()
    while (newFile.exists()) {
      newFile = File(destDir, "${filename}_$suffix.$extension")
      suffix++
      if (suffix > suffixLimit) {
        return "E_FILE_NAME_SUFFIX_REACHED"
      }
    }

    src.inputStream().channel.use { input ->
      newFile.outputStream().channel.use { output ->
        val transferred = input.transferTo(0, input.size(), output)
        if (transferred != input.size()) {
          newFile.delete()
          return "E_COULD_NOT_SAVE_FILE"
        }
      }
    }
    return newFile
  }

  inline fun withRetriever(contentResolver: ContentResolver, uri: Uri, handler: (MediaMetadataRetriever) -> Unit) {
    try {
      val path = uri.path ?: return
      val r = retriever
      var openFileDescriptor: ParcelFileDescriptor? = null
      if (URLUtil.isFileUrl(path)) {
        r.setDataSource(path.replace("file://", ""))
      } else if (URLUtil.isContentUrl(path)) {
        openFileDescriptor = contentResolver.openFileDescriptor(uri, "r")
        val fileDescriptor = openFileDescriptor?.fileDescriptor
        r.setDataSource(fileDescriptor)
      } else {
        r.setDataSource(path)
      }
      handler(r)
      openFileDescriptor?.close()
      r.release()
    } catch (e: java.lang.RuntimeException) {
      println(e.message)
    }
  }

  fun retrieveWidthHeightFromMedia(contentResolver: ContentResolver, videoUri: Uri, size: IntArray) {
    withRetriever(contentResolver, videoUri) {
      val videoWidth = it.extractMetadata(METADATA_KEY_VIDEO_WIDTH)
      val videoHeight = it.extractMetadata(METADATA_KEY_VIDEO_HEIGHT)
      size[0] = videoWidth?.toInt() ?: 0
      size[1] = videoHeight?.toInt() ?: 0
    }
  }

  private fun parseStringLocation(location: String?): DoubleArray? {
    if (location == null) return null
    val m: Matcher = iSO6709LocationPattern.matcher(location)
    if (m.find() && m.groupCount() == 2) {
      val latstr = m.group(1) ?: return null
      val lonstr = m.group(2) ?: return null
      try {
        val lat = latstr.toDouble()
        val lon = lonstr.toDouble()
        return doubleArrayOf(lat, lon)
      } catch (ignored: NumberFormatException) {
      }
    }
    return null
  }

  fun getMediaLocation(media: JSONObject, contentResolver: ContentResolver) {
    val latLong = DoubleArray(2)
    val localUri = media.getString("uri")
    val uri = Uri.parse(localUri)

    if (media.getString(AssetItemKeys.mediaType.name) == AssetMediaType.video.name) {
      withRetriever(contentResolver, uri) {
        val locationMetadata = it.extractMetadata(
          MediaMetadataRetriever.METADATA_KEY_LOCATION
        )
        parseStringLocation(locationMetadata)?.let { result ->
          val location = JSONObject()
          location.put("latitude", result[0])
          location.put("longitude", result[1])
          media.put("location", location)
        }
      }
    } else {
      if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
        MediaStore.setRequireOriginal(uri)
      }
      contentResolver.openInputStream(uri)?.use {
        val exifInterface = ExifInterface(it)
        exifInterface.latLong?.let { latLng ->
          latLong[0] = latLng[0]
          latLong[1] = latLng[1]
        }
      }
    }
    if (latLong[0] != 0.0 && latLong[1] != 0.0) {
      val location = JSONObject()
      location.put("latitude", latLong[0])
      location.put("longitude", latLong[1])
      media.put("location", location)
    }
  }

  private fun ensureDirExists(dir: File): File? {
    if (!(dir.isDirectory || dir.mkdirs())) {
      throw IOException("Couldn't create directory '$dir'")
    }
    return dir
  }

  fun generateOutputPath(internalDirectory: File, dirName: String, extension: String): String {
    val directory = File(internalDirectory.toString() + File.separator + dirName)
    ensureDirExists(directory)
    val filename = UUID.randomUUID().toString()
    return directory.toString() + File.separator + filename + if (extension.startsWith(".")) extension else ".$extension"
  }
}
