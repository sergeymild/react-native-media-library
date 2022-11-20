package com.reactnativemedialibrary

import com.facebook.react.bridge.ReactApplicationContext
import com.facebook.react.bridge.ReactContextBaseJavaModule
import com.facebook.react.bridge.ReactMethod
import com.facebook.react.module.annotations.ReactModule

@ReactModule(name = MediaLibraryModule.NAME)
class MediaLibraryModule(reactContext: ReactApplicationContext?) :
    ReactContextBaseJavaModule(reactContext) {
    private val mediaLibrary: MediaLibrary

    init {
        mediaLibrary = MediaLibrary(reactContext!!)
    }

    override fun getName(): String {
        return NAME
    }

    @ReactMethod(isBlockingSynchronousMethod = true)
    fun install() {
        mediaLibrary.install(reactApplicationContext)
    }

    companion object {
        const val NAME = "MediaLibrary"
    }
}
