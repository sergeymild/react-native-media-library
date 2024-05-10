package com.reactnativemedialibrary

import android.util.Base64
import android.util.Base64OutputStream
import java.io.ByteArrayOutputStream
import java.net.URL

object Base64Downloader {

  fun download(url: String): String {
    val byteArray = URL(url).readBytes()
    val out = ByteArrayOutputStream()
    Base64OutputStream(out, Base64.DEFAULT).use {
      it.write(byteArray)
    }
    return out.toString()
  }
}
