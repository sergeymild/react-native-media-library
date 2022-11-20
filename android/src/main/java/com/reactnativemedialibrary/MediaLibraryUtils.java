package com.reactnativemedialibrary;

import android.content.ContentResolver;
import android.net.Uri;
import android.os.Environment;
import android.provider.MediaStore;
import android.webkit.MimeTypeMap;

import androidx.annotation.Nullable;

import org.json.JSONException;
import org.json.JSONObject;

import java.io.File;
import java.io.FileInputStream;
import java.io.FileNotFoundException;
import java.io.FileOutputStream;
import java.io.IOException;
import java.nio.channels.FileChannel;

public class MediaLibraryUtils {

  static Uri EXTERNAL_CONTENT_URI = MediaStore.Files.getContentUri("external");

  public static JSONObject errorJson(String error) throws JSONException {
    JSONObject jsonObject = new JSONObject();
    jsonObject.put("error", error);
    return jsonObject;
  }

  public static JSONObject uriJson(String id) throws JSONException {
    JSONObject jsonObject = new JSONObject();
    jsonObject.put("id", id);
    return jsonObject;
  }

  @Nullable
  static String getMimeTypeFromFileUrl(String url) {
    String extension = MimeTypeMap.getFileExtensionFromUrl(url);
    if (extension == null) return null;
    return MimeTypeMap.getSingleton().getMimeTypeFromExtension(extension);
  }

  @Nullable
  static String getMimeType(ContentResolver contentResolver, Uri uri) {
    String type = contentResolver.getType(uri);
    if (type != null) return type;
    return getMimeTypeFromFileUrl(uri.toString());
  }

  public static String getRelativePathForAssetType(@Nullable String mimeType, boolean useCameraDir) {
    if (mimeType != null && (mimeType.contains("image") || mimeType.contains("video"))) {
      return useCameraDir ? Environment.DIRECTORY_DCIM : Environment.DIRECTORY_PICTURES;
    } else if (mimeType != null && mimeType.contains("audio")) {
      return Environment.DIRECTORY_MUSIC;
    }
    return useCameraDir ? Environment.DIRECTORY_DCIM : Environment.DIRECTORY_PICTURES;
  }

  public static Uri mimeTypeToExternalUri(@Nullable String mimeType) {
    if (mimeType == null) return MediaStore.Images.Media.EXTERNAL_CONTENT_URI;
    if (mimeType.contains("image")) return MediaStore.Images.Media.EXTERNAL_CONTENT_URI;
    if (mimeType.contains("video")) return MediaStore.Video.Media.EXTERNAL_CONTENT_URI;
    if (mimeType.contains("audio")) return MediaStore.Audio.Media.EXTERNAL_CONTENT_URI;
    return EXTERNAL_CONTENT_URI;
  }

  public static File getEnvDirectoryForAssetType(@Nullable String mimeType, boolean useCameraDir) {
    return Environment.getExternalStoragePublicDirectory(getRelativePathForAssetType(mimeType, useCameraDir));
  }

  static String[] getFileNameAndExtension(String name) {
    int dotIdx = name.length();
    if (name.lastIndexOf(".") != -1) {
      dotIdx = name.lastIndexOf(".");
    }
    String  extension = name.substring(dotIdx);
    String filename = name.substring(0, dotIdx);
    return new String[]{filename, extension};
  }

  public static Object safeCopyFile(File src, File destDir) throws IOException, JSONException {
    File newFile = new File(destDir, src.getName());
    int suffix = 0;
    String[] fileNameAndExtension = getFileNameAndExtension(src.getName());
    String filename = fileNameAndExtension[0];
    String extension = fileNameAndExtension[1];
    int suffixLimit = Short.MAX_VALUE;
    while (newFile.exists()) {
      newFile = new File(destDir, filename + "_" + suffix + extension);
      suffix++;
      if (suffix > suffixLimit) {
        return "E_FILE_NAME_SUFFIX_REACHED";
      }
    }

    try(FileChannel input = new FileInputStream(src).getChannel()) {
      try(FileChannel output = new FileOutputStream(newFile).getChannel()) {
        long transferred = input.transferTo(0, input.size(), output);
        if (transferred != input.size()) {
          newFile.delete();
          return "E_COULD_NOT_SAVE_FILE";
        }
      }
    }
    return newFile;
  }
}
