package com.reactnativemedialibrary

import com.facebook.react.bridge.Promise
import com.facebook.react.bridge.ReactApplicationContext
import com.facebook.react.bridge.ReactContextBaseJavaModule
import com.facebook.react.bridge.ReadableMap

abstract class NativeMediaLibrarySpec(reactContext: ReactApplicationContext) :
    ReactContextBaseJavaModule(reactContext) {

    abstract fun cacheDir(): String
    abstract fun getAssets(options: ReadableMap, promise: Promise)
    abstract fun getFromDisk(options: ReadableMap, promise: Promise)
    abstract fun getCollections(promise: Promise)
    abstract fun getAsset(id: String, promise: Promise)
    abstract fun exportVideo(params: ReadableMap, promise: Promise)
    abstract fun saveToLibrary(params: ReadableMap, promise: Promise)
    abstract fun fetchVideoFrame(params: ReadableMap, promise: Promise)
    abstract fun combineImages(params: ReadableMap, promise: Promise)
    abstract fun imageResize(params: ReadableMap, promise: Promise)
    abstract fun imageCrop(params: ReadableMap, promise: Promise)
    abstract fun imageSizes(params: ReadableMap, promise: Promise)
    abstract fun downloadAsBase64(params: ReadableMap, promise: Promise)
}
