package com.reactnativemedialibrary;

import androidx.annotation.NonNull;

import com.facebook.react.bridge.Promise;
import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.ReactContextBaseJavaModule;
import com.facebook.react.bridge.ReactMethod;
import com.facebook.react.module.annotations.ReactModule;

@ReactModule(name = MediaLibraryModule.NAME)
public class MediaLibraryModule extends ReactContextBaseJavaModule {
  public static final String NAME = "MediaLibrary";
  private MediaLibrary mediaLibrary;

  public MediaLibraryModule(ReactApplicationContext reactContext) {
    super(reactContext);
    mediaLibrary = new MediaLibrary(reactContext);
  }

  @Override
  @NonNull
  public String getName() {
    return NAME;
  }


  @ReactMethod(isBlockingSynchronousMethod = true)
  public void install() {
    mediaLibrary.install(getReactApplicationContext());
  }

}
