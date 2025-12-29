package com.reactnativemedialibrary

import android.net.Uri
import android.provider.MediaStore
import android.provider.MediaStore.Files.FileColumns.MEDIA_TYPE_IMAGE
import com.facebook.react.bridge.Promise
import com.facebook.react.bridge.ReactApplicationContext
import com.facebook.react.bridge.ReactMethod
import com.facebook.react.bridge.ReadableMap
import com.facebook.react.bridge.WritableArray
import com.facebook.react.bridge.WritableMap
import com.facebook.react.bridge.WritableNativeArray
import com.facebook.react.bridge.WritableNativeMap
import com.facebook.react.module.annotations.ReactModule
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.launch
import org.json.JSONArray
import org.json.JSONObject

@ReactModule(name = MediaLibraryModule.NAME)
class MediaLibraryModule(reactContext: ReactApplicationContext) :
    NativeMediaLibrarySpec(reactContext) {

    private val manipulateImages: ManipulateImages = ManipulateImages(reactContext.applicationContext)
    private val job = SupervisorJob()
    private val scope = CoroutineScope(Dispatchers.IO + job)

    override fun getName(): String = NAME

    @ReactMethod(isBlockingSynchronousMethod = true)
    override fun cacheDir(): String {
        return reactApplicationContext.cacheDir.absolutePath
    }

    @ReactMethod
    override fun getAssets(options: ReadableMap, promise: Promise) {
        scope.launch {
            try {
                val contentResolver = reactApplicationContext.contentResolver
                val jsonParams = readableMapToJson(options)
                val jsonArray = contentResolver.listQuery(
                    EXTERNAL_CONTENT_URI,
                    reactApplicationContext,
                    jsonParams
                )
                promise.resolve(jsonArrayToWritableArray(jsonArray))
            } catch (e: Exception) {
                promise.reject("ERROR", e.message)
            }
        }
    }

    @ReactMethod
    override fun getFromDisk(options: ReadableMap, promise: Promise) {
        scope.launch {
            try {
                val path = options.getString("path") ?: ""
                val extensions = options.getString("extensions") ?: ""
                val result = FilesUtils.getFilesList(path, "modificationTime_desc", extensions)
                promise.resolve(result)
            } catch (e: Exception) {
                promise.reject("ERROR", e.message)
            }
        }
    }

    @ReactMethod
    override fun getCollections(promise: Promise) {
        scope.launch {
            try {
                val contentResolver = reactApplicationContext.contentResolver
                val jsonArray = contentResolver.getCollections(MEDIA_TYPE_IMAGE)
                promise.resolve(jsonArrayToWritableArray(jsonArray))
            } catch (e: Exception) {
                promise.reject("ERROR", e.message)
            }
        }
    }

    @ReactMethod
    override fun getAsset(id: String, promise: Promise) {
        scope.launch {
            try {
                val contentResolver = reactApplicationContext.contentResolver
                val jsonArray = contentResolver.singleQuery(
                    EXTERNAL_CONTENT_URI,
                    reactApplicationContext,
                    JSONObject(),
                    id
                )
                if (jsonArray.length() == 0) {
                    promise.resolve(null)
                    return@launch
                }
                val media = jsonArray.getJSONObject(0)
                MediaLibraryUtils.getMediaLocation(media, contentResolver)
                promise.resolve(jsonObjectToWritableMap(media))
            } catch (e: Exception) {
                promise.reject("ERROR", e.message)
            }
        }
    }

    @ReactMethod
    override fun exportVideo(params: ReadableMap, promise: Promise) {
        scope.launch {
            try {
                // Not implemented on Android
                val result = WritableNativeMap()
                result.putBoolean("result", false)
                promise.resolve(result)
            } catch (e: Exception) {
                promise.reject("ERROR", e.message)
            }
        }
    }

    @ReactMethod
    override fun saveToLibrary(params: ReadableMap, promise: Promise) {
        scope.launch {
            try {
                val jsonParams = readableMapToJson(params)
                MedialLibraryCreateAsset.saveToLibrary(jsonParams, reactApplicationContext) { error, id ->
                    if (error != null) {
                        val errorResult = WritableNativeMap()
                        errorResult.putString("error", error)
                        promise.resolve(errorResult)
                    } else {
                        // Get the saved asset
                        scope.launch {
                            val contentResolver = reactApplicationContext.contentResolver
                            val jsonArray = contentResolver.singleQuery(
                                EXTERNAL_CONTENT_URI,
                                reactApplicationContext,
                                JSONObject(),
                                id!!
                            )
                            if (jsonArray.length() > 0) {
                                val media = jsonArray.getJSONObject(0)
                                promise.resolve(jsonObjectToWritableMap(media))
                            } else {
                                promise.resolve(null)
                            }
                        }
                    }
                }
            } catch (e: Exception) {
                promise.reject("ERROR", e.message)
            }
        }
    }

    @ReactMethod
    override fun fetchVideoFrame(params: ReadableMap, promise: Promise) {
        scope.launch {
            try {
                val jsonParams = readableMapToJson(params)
                val response = reactApplicationContext.fetchFrame(jsonParams)
                if (response == null) {
                    promise.resolve(null)
                } else {
                    promise.resolve(jsonObjectToWritableMap(response))
                }
            } catch (e: Exception) {
                promise.reject("ERROR", e.message)
            }
        }
    }

    @ReactMethod
    override fun combineImages(params: ReadableMap, promise: Promise) {
        scope.launch {
            try {
                val jsonParams = readableMapToJson(params)
                val success = manipulateImages.combineImages(jsonParams)
                val result = WritableNativeMap()
                result.putBoolean("result", success)
                promise.resolve(result)
            } catch (e: Exception) {
                promise.reject("ERROR", e.message)
            }
        }
    }

    @ReactMethod
    override fun imageResize(params: ReadableMap, promise: Promise) {
        scope.launch {
            try {
                val jsonParams = readableMapToJson(params)
                val success = manipulateImages.imageResize(jsonParams)
                val result = WritableNativeMap()
                result.putBoolean("result", success)
                promise.resolve(result)
            } catch (e: Exception) {
                promise.reject("ERROR", e.message)
            }
        }
    }

    @ReactMethod
    override fun imageCrop(params: ReadableMap, promise: Promise) {
        scope.launch {
            try {
                val jsonParams = readableMapToJson(params)
                val success = manipulateImages.imageCrop(jsonParams)
                val result = WritableNativeMap()
                result.putBoolean("result", success)
                promise.resolve(result)
            } catch (e: Exception) {
                promise.reject("ERROR", e.message)
            }
        }
    }

    @ReactMethod
    override fun imageSizes(params: ReadableMap, promise: Promise) {
        scope.launch {
            try {
                val jsonParams = readableMapToJson(params)
                val jsonArray = manipulateImages.imageSizes(jsonParams)
                promise.resolve(jsonArrayToWritableArray(jsonArray))
            } catch (e: Exception) {
                promise.reject("ERROR", e.message)
            }
        }
    }

    @ReactMethod
    override fun downloadAsBase64(params: ReadableMap, promise: Promise) {
        scope.launch {
            try {
                val url = params.getString("url") ?: ""
                val base64String = Base64Downloader.download(url)
                if (base64String == null) {
                    promise.resolve(null)
                } else {
                    val result = WritableNativeMap()
                    result.putString("base64", base64String)
                    promise.resolve(result)
                }
            } catch (e: Exception) {
                promise.reject("ERROR", e.message)
            }
        }
    }

    // Helper functions
    private fun readableMapToJson(map: ReadableMap): JSONObject {
        val json = JSONObject()
        val iterator = map.keySetIterator()
        while (iterator.hasNextKey()) {
            val key = iterator.nextKey()
            when (map.getType(key)) {
                com.facebook.react.bridge.ReadableType.Null -> json.put(key, JSONObject.NULL)
                com.facebook.react.bridge.ReadableType.Boolean -> json.put(key, map.getBoolean(key))
                com.facebook.react.bridge.ReadableType.Number -> json.put(key, map.getDouble(key))
                com.facebook.react.bridge.ReadableType.String -> json.put(key, map.getString(key))
                com.facebook.react.bridge.ReadableType.Map -> json.put(key, readableMapToJson(map.getMap(key)!!))
                com.facebook.react.bridge.ReadableType.Array -> {
                    val array = map.getArray(key)!!
                    val jsonArray = JSONArray()
                    for (i in 0 until array.size()) {
                        when (array.getType(i)) {
                            com.facebook.react.bridge.ReadableType.String -> jsonArray.put(array.getString(i))
                            com.facebook.react.bridge.ReadableType.Number -> jsonArray.put(array.getDouble(i))
                            com.facebook.react.bridge.ReadableType.Boolean -> jsonArray.put(array.getBoolean(i))
                            com.facebook.react.bridge.ReadableType.Map -> jsonArray.put(readableMapToJson(array.getMap(i)))
                            else -> {}
                        }
                    }
                    json.put(key, jsonArray)
                }
            }
        }
        return json
    }

    private fun jsonArrayToWritableArray(jsonArray: JSONArray): WritableArray {
        val array = WritableNativeArray()
        for (i in 0 until jsonArray.length()) {
            val item = jsonArray.get(i)
            when (item) {
                is JSONObject -> array.pushMap(jsonObjectToWritableMap(item))
                is JSONArray -> array.pushArray(jsonArrayToWritableArray(item))
                is String -> array.pushString(item)
                is Number -> array.pushDouble(item.toDouble())
                is Boolean -> array.pushBoolean(item)
                else -> array.pushNull()
            }
        }
        return array
    }

    private fun jsonObjectToWritableMap(json: JSONObject): WritableMap {
        val map = WritableNativeMap()
        val keys = json.keys()
        while (keys.hasNext()) {
            val key = keys.next()
            val value = json.get(key)
            when (value) {
                is JSONObject -> map.putMap(key, jsonObjectToWritableMap(value))
                is JSONArray -> map.putArray(key, jsonArrayToWritableArray(value))
                is String -> map.putString(key, value)
                is Number -> map.putDouble(key, value.toDouble())
                is Boolean -> map.putBoolean(key, value)
                JSONObject.NULL -> map.putNull(key)
                else -> map.putNull(key)
            }
        }
        return map
    }

    companion object {
        const val NAME = "MediaLibrary"
        val EXTERNAL_CONTENT_URI: Uri = MediaStore.Files.getContentUri("external")
    }
}
