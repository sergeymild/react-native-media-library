package com.reactnativemedialibrary

import com.facebook.react.bridge.WritableArray
import com.facebook.react.bridge.WritableNativeArray
import com.facebook.react.bridge.WritableNativeMap
import java.io.File

object FilesUtils {
    fun getFilesList(path: String, sort: String, extensions: String): WritableArray {
        val result = WritableNativeArray()
        val directory = File(path.fixFilePathFromJs())

        if (!directory.exists() || !directory.isDirectory) {
            return result
        }

        val extensionsList = if (extensions.isNotEmpty()) {
            extensions.lowercase().split(",").map { it.trim() }
        } else {
            emptyList()
        }

        val files = directory.listFiles() ?: return result

        // Sort files
        val sortedFiles = when {
            sort.contains("modificationTime") -> {
                if (sort.contains("desc")) {
                    files.sortedByDescending { it.lastModified() }
                } else {
                    files.sortedBy { it.lastModified() }
                }
            }
            sort.contains("name") -> {
                if (sort.contains("desc")) {
                    files.sortedByDescending { it.name }
                } else {
                    files.sortedBy { it.name }
                }
            }
            else -> files.sortedByDescending { it.lastModified() }
        }

        for (file in sortedFiles) {
            // Filter by extension if provided
            if (extensionsList.isNotEmpty() && !file.isDirectory) {
                val fileExtension = file.extension.lowercase()
                if (!extensionsList.contains(fileExtension)) {
                    continue
                }
            }

            val entry = WritableNativeMap()
            entry.putString("filename", file.name)
            entry.putString("uri", file.absolutePath.fixFilePathToJs())
            entry.putBoolean("isDirectory", file.isDirectory)
            entry.putDouble("size", file.length().toDouble())
            entry.putDouble("creationTime", file.lastModified().toDouble())

            result.pushMap(entry)
        }

        return result
    }
}
