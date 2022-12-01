package com.reactnativemedialibrary

import android.content.ContentResolver
import android.media.MediaMetadataRetriever
import android.media.MediaMetadataRetriever.METADATA_KEY_VIDEO_HEIGHT
import android.media.MediaMetadataRetriever.METADATA_KEY_VIDEO_WIDTH
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import android.webkit.MimeTypeMap
import androidx.exifinterface.media.ExifInterface
import org.json.JSONException
import org.json.JSONObject
import java.io.File
import java.io.IOException
import java.util.*

object MediaLibraryUtils {

  val retriever: MediaMetadataRetriever
    get() = MediaMetadataRetriever()

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

  fun getFileNameAndExtension(name: String): Array<String> {
    var dotIdx = name.length
    if (name.lastIndexOf(".") != -1) {
      dotIdx = name.lastIndexOf(".")
    }
    val extension = name.substring(dotIdx)
    val filename = name.substring(0, dotIdx)
    return arrayOf(filename, extension)
  }

  @Throws(IOException::class, JSONException::class)
  fun safeCopyFile(src: File, destDir: File?): Any {
    var newFile = File(destDir, src.name)
    var suffix = 0
    val fileNameAndExtension = getFileNameAndExtension(src.name)
    val filename = fileNameAndExtension[0]
    val extension = fileNameAndExtension[1]
    val suffixLimit = Short.MAX_VALUE.toInt()
    while (newFile.exists()) {
      newFile = File(destDir, filename + "_" + suffix + extension)
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

  fun retrieveWidthHeightFromMedia(contentResolver: ContentResolver, videoUri: Uri, size: IntArray) {
    contentResolver.openAssetFileDescriptor(videoUri, "r").use { r ->
      MediaLibraryUtils.retriever.use { retriever ->
        retriever.setDataSource(r!!.fileDescriptor)
        val videoWidth = retriever.extractMetadata(METADATA_KEY_VIDEO_WIDTH)
        val videoHeight = retriever.extractMetadata(METADATA_KEY_VIDEO_HEIGHT)
        size[0] = videoWidth!!.toInt()
        size[1] = videoHeight!!.toInt()
      }
    }
  }


  fun getMediaLocation(media: JSONObject, contentResolver: ContentResolver) {
    val latLong = DoubleArray(2)
    val localUri = media.getString("uri")
    val uri = Uri.parse(localUri)

    if (media.getString(AssetItemKeys.mediaType.name) == AssetMediaType.video.name) {
      contentResolver.openAssetFileDescriptor(uri, "r").use { fd ->
        retriever.use {
          it.setDataSource(fd!!.fileDescriptor)
          val locationMetadata = retriever.extractMetadata(
            MediaMetadataRetriever.METADATA_KEY_LOCATION
          )
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

  fun ensureDirExists(dir: File): File? {
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
