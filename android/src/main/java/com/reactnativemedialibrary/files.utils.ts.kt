package com.reactnativemedialibrary

fun String.fixFilePathFromJs(): String {
  return if (this.startsWith("file://")) this.substring(7) else this
}

fun String.fixFilePathToJs(): String {
  if (this.startsWith("http")) return this
  return if (!this.startsWith("file://")) "file://$this" else this
}
