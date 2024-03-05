package com.reactnativemedialibrary

fun String.fixFilePathFromJs(): String {
  return if (this.startsWith("file://")) this.substring(7) else this
}

fun String.fixFilePathToJs(): String {
  return if (!this.startsWith("file://")) "file://$this" else this
}
