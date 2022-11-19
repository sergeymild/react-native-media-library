package com.reactnativemedialibrary;

import static com.reactnativemedialibrary.MediaLibraryUtils.errorJson;

import android.content.ContentResolver;
import android.content.Context;
import android.content.res.AssetFileDescriptor;
import android.database.Cursor;
import android.graphics.BitmapFactory;
import android.media.MediaMetadataRetriever;
import android.net.Uri;
import android.os.Environment;
import android.provider.MediaStore;
import android.text.TextUtils;

import com.facebook.jni.HybridData;
import com.facebook.proguard.annotations.DoNotStrip;
import com.facebook.react.bridge.JavaScriptContextHolder;
import com.facebook.react.bridge.ReactApplicationContext;

import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import java.io.IOException;
import java.util.HashSet;
import java.util.Objects;
import java.util.Set;
import java.util.concurrent.Semaphore;

@DoNotStrip
public class MediaLibrary {
  @DoNotStrip
  private HybridData mHybridData;

  static Uri EXTERNAL_CONTENT_URI = MediaStore.Files.getContentUri("external");
  static String dateAdded = MediaStore.Files.FileColumns.DATE_ADDED;
  static String[] ASSET_PROJECTION = new String[]{
    MediaStore.Images.Media._ID,
    MediaStore.Files.FileColumns.DISPLAY_NAME,
    MediaStore.Images.Media.DATA,
    MediaStore.Files.FileColumns.MEDIA_TYPE,
    MediaStore.MediaColumns.WIDTH,
    MediaStore.MediaColumns.HEIGHT,
    dateAdded,
    MediaStore.Images.Media.DATE_MODIFIED,
    MediaStore.Images.Media.ORIENTATION,
    MediaStore.Video.VideoColumns.DURATION,
    MediaStore.Images.Media.BUCKET_ID
  };

  public MediaLibrary(Context context) {
    this.context = context.getApplicationContext();
  }

  @SuppressWarnings("JavaJniMissingFunction")
  public native HybridData initHybrid(long jsContext);

  @SuppressWarnings("JavaJniMissingFunction")
  public native void installJSIBindings();

  private Context context;

  boolean install(ReactApplicationContext context) {
    System.loadLibrary("react-native-media-library");
    JavaScriptContextHolder jsContext = context.getJavaScriptContextHolder();
    mHybridData = initHybrid(jsContext.get());
    installJSIBindings();
    return true;
  }

  private String createSelectionString(JSONObject input) throws JSONException {
    StringBuilder stringBuilder = new StringBuilder();

    if (input.has("mediaType")) {
      JSONArray mediaType = input.getJSONArray("mediaType");
      String[] mediaTypeInts = new String[mediaType.length()];
      for (int i = 0; i < mediaType.length(); i++) {
        mediaTypeInts[i] = String.valueOf(mediaTypeToInt(mediaType.getString(i)));
      }
      String mediaTypes = TextUtils.join(",", mediaTypeInts);
      stringBuilder
        .append(MediaStore.Files.FileColumns.MEDIA_TYPE)
        .append(" IN ")
        .append("(")
        .append(mediaTypes)
        .append(")");
    } else {
      stringBuilder
        .append(MediaStore.Files.FileColumns.MEDIA_TYPE)
        .append(" != ")
        .append(MediaStore.Files.FileColumns.MEDIA_TYPE_NONE);
    }

    return stringBuilder.toString();
  }

  private int[] getAssetDimensionsFromCursor(
    Cursor cursor,
    ContentResolver contentResolver,
    int mediaType,
    int localUriColumnIndex
  ) throws IOException {
    String uri = cursor.getString(localUriColumnIndex);
    if (mediaType == MediaStore.Files.FileColumns.MEDIA_TYPE_VIDEO) {
      Uri videoUri = Uri.parse("file://" + uri);
      try (AssetFileDescriptor r = contentResolver.openAssetFileDescriptor(videoUri, "r")) {
        try(MediaMetadataRetriever retriever = new MediaMetadataRetriever()) {
          retriever.setDataSource(r.getFileDescriptor());
          String videoWidth = retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_VIDEO_WIDTH);
          String videoHeight = retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_VIDEO_HEIGHT);
          return new int[]{Integer.parseInt(videoWidth), Integer.parseInt(videoHeight)};
        }
      }
    }

    int widthIndex = cursor.getColumnIndex(MediaStore.MediaColumns.WIDTH);
    int heightIndex = cursor.getColumnIndex(MediaStore.MediaColumns.HEIGHT);
    int width = cursor.getInt(widthIndex);
    int height = cursor.getInt(heightIndex);
    // If the image doesn't have the required information, we can get them from Bitmap.Options
    if (mediaType == MediaStore.Files.FileColumns.MEDIA_TYPE_IMAGE && (width <= 0 || height <= 0)) {
      BitmapFactory.Options options = new BitmapFactory.Options();
      options.inJustDecodeBounds = true;
      BitmapFactory.decodeFile(uri, options);
      width = options.outWidth;
      height = options.outHeight;
    }
    return new int[]{width, height};
  }

  private String exportMediaType(int mediaType) {
    switch (mediaType) {
      case MediaStore.Files.FileColumns.MEDIA_TYPE_IMAGE:
        return "photo";
      case MediaStore.Files.FileColumns.MEDIA_TYPE_AUDIO:
      case MediaStore.Files.FileColumns.MEDIA_TYPE_PLAYLIST:
        return "audio";
      case MediaStore.Files.FileColumns.MEDIA_TYPE_VIDEO:
        return "video";
      default:
        return "unknown";
    }
  }

  private int mediaTypeToInt(String mediaType) {
    switch (mediaType) {
      case "photo":
        return MediaStore.Files.FileColumns.MEDIA_TYPE_IMAGE;
      case "audio":
        return MediaStore.Files.FileColumns.MEDIA_TYPE_AUDIO;
      case "video":
        return MediaStore.Files.FileColumns.MEDIA_TYPE_VIDEO;
      default:
        return MediaStore.Files.FileColumns.MEDIA_TYPE_NONE;
    }
  }

  private Set<String> toSet(JSONArray array) throws JSONException {
    HashSet<String> strings = new HashSet<>(array.length());
    for (int i = 0; i < array.length(); i++) {
      strings.add(array.getString(i));
    }
    return strings;
  }

  private void putAssetsInfo(
    Cursor cursor,
    ContentResolver contentResolver,
    JSONArray array,
    JSONObject input,
    int limit
  ) throws IOException, JSONException {
    int idIndex = cursor.getColumnIndex(MediaStore.Images.Media._ID);
    int filenameIndex = cursor.getColumnIndex(MediaStore.Files.FileColumns.DISPLAY_NAME);
    int mediaTypeIndex = cursor.getColumnIndex(MediaStore.Files.FileColumns.MEDIA_TYPE);
    int creationDateIndex = cursor.getColumnIndex(dateAdded);
    int modificationDateIndex = cursor.getColumnIndex(MediaStore.Files.FileColumns.DATE_MODIFIED);
    int durationIndex = cursor.getColumnIndex(MediaStore.Video.VideoColumns.DURATION);
    int localUriIndex = cursor.getColumnIndex(MediaStore.Images.Media.DATA);

    Set<String> extensions = null;
    if (input.has("extensions")) {
      extensions = toSet(input.getJSONArray("extensions"));
    }

    while (cursor.moveToNext()) {
      String assetId = cursor.getString(idIndex);
      String path = cursor.getString(localUriIndex);
      String extension = path.substring(path.lastIndexOf(".") + 1);
      if (extensions != null && !extensions.contains(extension)) {
        continue;
      }

      String localUri = "file://" + path;
      int mediaType = cursor.getInt(mediaTypeIndex);
      int [] widthHeight = getAssetDimensionsFromCursor(cursor, contentResolver, mediaType, localUriIndex);

      JSONObject object = new JSONObject();
      object.put("filename", cursor.getString(filenameIndex));
      object.put("id", assetId);
      object.put("creationTime", cursor.getLong(creationDateIndex));
      object.put("modificationTime", cursor.getLong(modificationDateIndex) * 1000.0);
      object.put("mediaType", exportMediaType(mediaType));
      object.put("duration", cursor.getInt(durationIndex) / 1000.0);
      object.put("width", widthHeight[0]);
      object.put("height", widthHeight[1]);
      object.put("url", localUri);
      object.put("uri", localUri);
      array.put(object);
      if (limit == 1) break;
    }
  }

  private String sortToColumnName(String sort) {
    if (Objects.equals(sort, "creationTime")) return dateAdded;
    if (Objects.equals(sort, "modificationTime")) return MediaStore.Files.FileColumns.DATE_MODIFIED;
    throw new RuntimeException("Unsupported " + sort);
  }

  private String sortBy(JSONObject input) throws JSONException {
    if (!input.has("sortBy")) return MediaStore.Images.Media.DEFAULT_SORT_ORDER;
    String sortBy = input.getString("sortBy");
    if (!input.has("sortOrder")) return sortToColumnName(sortBy);
    return  sortToColumnName(sortBy) + " " + input.getString("sortOrder");
  }

  @DoNotStrip
  String getAssets(String params) throws JSONException, IOException {
    ContentResolver contentResolver = context.getContentResolver();
    JSONObject input = new JSONObject(params);
    try (Cursor cursor = contentResolver.query(
      EXTERNAL_CONTENT_URI,
      ASSET_PROJECTION,
      createSelectionString(input),
      null,
      sortBy(input))) {

      JSONArray array = new JSONArray();

      putAssetsInfo(cursor, contentResolver, array, input, -1);
      return array.toString();
    }
  }

  @DoNotStrip
  String getAsset(String params) throws JSONException, IOException {
    ContentResolver contentResolver = context.getContentResolver();
    try (Cursor cursor = contentResolver.query(
      EXTERNAL_CONTENT_URI,
      ASSET_PROJECTION,
      MediaStore.Images.Media._ID + " = " + params,
      null,
      null)) {

      JSONArray array = new JSONArray();
      putAssetsInfo(cursor, contentResolver, array, new JSONObject(), 1);
      if (array.length() > 0) return array.getJSONObject(0).toString();
      return null;
    }
  }

  @DoNotStrip
  String saveToLibrary(String params) throws JSONException, InterruptedException {
    try {
      Semaphore semaphore = new Semaphore(0);
      final String[] resultUri = {null};
      final String[] resultError = {null};
      new MedialLibraryCreateAsset().saveToLibrary(params, context, result -> {
        resultUri[0] = result.has("id") ? result.getString("id") : null;
        resultError[0] = result.has("error") ? result.getString("error") : null;
        semaphore.release();
      });
      semaphore.acquire();;
      if (resultError[0] != null) {
        return errorJson(resultError[0]).toString();
      }
      return getAsset(resultUri[0]);
    } catch (IOException e) {
      return errorJson("Unable to copy file into external storage").toString();
    }
  }
}
