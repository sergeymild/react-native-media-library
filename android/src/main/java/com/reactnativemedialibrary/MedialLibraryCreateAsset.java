package com.reactnativemedialibrary;

import static com.reactnativemedialibrary.MediaLibraryUtils.errorJson;
import static com.reactnativemedialibrary.MediaLibraryUtils.uriJson;

import android.content.ContentResolver;
import android.content.ContentUris;
import android.content.ContentValues;
import android.content.Context;
import android.media.MediaScannerConnection;
import android.net.Uri;
import android.os.Build;
import android.provider.MediaStore;

import androidx.annotation.Nullable;
import androidx.annotation.RequiresApi;

import com.facebook.proguard.annotations.DoNotStrip;

import org.json.JSONException;
import org.json.JSONObject;

import java.io.File;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.IOException;
import java.nio.channels.FileChannel;

public class MedialLibraryCreateAsset {
  interface MedialLibraryCreateAssetCallback {
    void onResult(JSONObject result) throws JSONException;
  }

  private boolean isFileExtensionPresent(String uri) {
    return !uri.substring(uri.lastIndexOf(".") + 1).isEmpty();
  }

  private Uri normalizeAssetUri(String uri) {
    if (uri.startsWith("/")) {
      return Uri.fromFile(new File(uri));
    }
    return Uri.parse(uri);
  }

  @Nullable
  private Object createAssetFileLegacy(Context context, Uri uri) throws IOException, JSONException {
    File localFile = new File(uri.getPath());
    File destDir = MediaLibraryUtils.getEnvDirectoryForAssetType(
      MediaLibraryUtils.getMimeType(context.getContentResolver(), uri),
      true
    );
    if (destDir == null) return errorJson("Could not guess file type");

    Object result = MediaLibraryUtils.safeCopyFile(localFile, destDir);
    if (result instanceof JSONObject) return result;
    File destFile = (File) result;
    if (!destFile.exists() || !destFile.isFile()) {
      return errorJson("Could not create asset record. Related file is not existing.");
    }
    return destFile;
  }


  @RequiresApi(api = Build.VERSION_CODES.Q)
  @Nullable
  private Uri createAssetUsingContentResolver(Context context, Uri uri) {
    ContentResolver contentResolver = context.getContentResolver();
    String mimeType = MediaLibraryUtils.getMimeType(contentResolver, uri);
    String filename = uri.getLastPathSegment();
    String path = MediaLibraryUtils.getRelativePathForAssetType(mimeType, true);
    Uri contentUri = MediaLibraryUtils.mimeTypeToExternalUri(mimeType);
    ContentValues contentValues = new ContentValues();
    contentValues.put(MediaStore.MediaColumns.DISPLAY_NAME, filename);
    contentValues.put(MediaStore.MediaColumns.MIME_TYPE, mimeType);
    contentValues.put(MediaStore.MediaColumns.RELATIVE_PATH, path);
    contentValues.put(MediaStore.MediaColumns.IS_PENDING, 1);
    return contentResolver.insert(contentUri, contentValues);
  }


  @RequiresApi(api = Build.VERSION_CODES.Q)
  @Nullable
  private JSONObject writeFileContentsToAsset(Context context, File localFile, Uri assetUri) throws IOException, JSONException {
    ContentResolver contentResolver = context.getContentResolver();
    try(FileChannel input = new FileInputStream(localFile).getChannel()) {
      try(FileChannel output = ((FileOutputStream)contentResolver.openOutputStream(assetUri)).getChannel()) {
        long transferred = input.transferTo(0, input.size(), output);
        if (transferred != input.size()) {
          contentResolver.delete(assetUri, null, null);
          return errorJson("Could not save file Not enough space.");
        }
      }
    }

    ContentValues values = new ContentValues();
    values.put(MediaStore.MediaColumns.IS_PENDING, 0);
    contentResolver.update(assetUri, values, null, null);
    return null;
  }

  @DoNotStrip
  void saveToLibrary(String params, Context context, MedialLibraryCreateAssetCallback callback) throws IOException, JSONException {
    if (!isFileExtensionPresent(params)) {
      callback.onResult(errorJson("Could not get the file's extension."));
      return;
    }
    Uri uri = normalizeAssetUri(params);
    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
      createAssetUsingContentResolver(context, uri);
      Uri assetUri = createAssetUsingContentResolver(context, normalizeAssetUri(params));
      if (assetUri == null) {
        callback.onResult(errorJson("Could not create content entry."));
        return;
      };
      try {
        JSONObject error = writeFileContentsToAsset(context, new File(uri.getPath()), assetUri);
        if (error != null) {
          callback.onResult(error);
          return;
        };
        callback.onResult(uriJson(String.valueOf(ContentUris.parseId(assetUri))));
        return;
        // return asset
      } catch (IOException e) {
        callback.onResult(errorJson(e.getMessage()));
        return;
      }
    }

    Object result = createAssetFileLegacy(context, uri);
    // error
    if (result instanceof JSONObject) {
      callback.onResult((JSONObject) result);
      return;
    };
    File asset = (File) result;
    MediaScannerConnection.scanFile(context, new String[]{asset.getPath()}, null, (path, newUri) -> {
      if (newUri == null) {
        try {
          callback.onResult(errorJson("Unable to copy file into external storage."));
        } catch (JSONException e) {
          throw new RuntimeException(e);
        }
        return;
      }
      try {
        callback.onResult(uriJson(String.valueOf(ContentUris.parseId(newUri))));
      } catch (JSONException e) {
        throw new RuntimeException(e);
      }
    });
  }
}
