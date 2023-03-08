package com.example.reactnativemedialibrary;

import com.facebook.react.ReactActivity;
import com.facebook.react.ReactActivityDelegate;
import com.facebook.react.ReactRootView;

public class MainActivity extends ReactActivity {

  /**
   * Returns the name of the main component registered from JavaScript. This is used to schedule
   * rendering of the component.
   */
  @Override
  protected String getMainComponentName() {
    return "main";
  }


    @Override
    protected ReactActivityDelegate createReactActivityDelegate() {
      return new DefaultReactActivityDelegate(
          this,
          getMainComponentName(),
          // If you opted-in for the New Architecture, we enable the Fabric Renderer.
          DefaultNewArchitectureEntryPoint.getFabricEnabled(), // fabricEnabled
          // If you opted-in for the New Architecture, we enable Concurrent React (i.e. React 18).
          DefaultNewArchitectureEntryPoint.getConcurrentReactEnabled() // concurrentRootEnabled
          );
    }
}
