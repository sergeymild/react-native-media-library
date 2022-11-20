package com.reactnativemedialibrary;

import com.facebook.jni.HybridData;
import com.facebook.proguard.annotations.DoNotStrip;

@DoNotStrip
public class GetAssetsCallback {
  @DoNotStrip
  private final HybridData mHybridData;

  @DoNotStrip
  public GetAssetsCallback(HybridData mHybridData) {
    System.out.println("🥸 GetAssetsCallback.constructor");
    this.mHybridData = mHybridData;
  }

  public synchronized void destroy() {
    if (mHybridData != null) {
      mHybridData.resetNative();
    }
  }

  @SuppressWarnings("JavaJniMissingFunction")
  native void onChange(String type);
}
