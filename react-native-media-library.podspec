require "json"

package = JSON.parse(File.read(File.join(__dir__, "package.json")))

Pod::Spec.new do |s|
  s.name         = "react-native-media-library"
  s.version      = package["version"]
  s.summary      = package["description"]
  s.homepage     = package["homepage"]
  s.license      = package["license"]
  s.authors      = package["author"]

  s.platforms    = { :ios => "15.0" }
  s.source       = { :git => "https://github.com/sergeymild/react-native-media-library.git", :tag => "#{s.version}" }

  s.source_files = "ios/**/*.{h,m,mm,swift,cpp}"
  s.public_header_files = 'ios/MediaLibrary-Bridging-Header.h'

  s.pod_target_xcconfig = {
    "CLANG_CXX_LANGUAGE_STANDARD" => "c++17",
    "DEFINES_MODULE" => "YES",
    "SWIFT_OBJC_INTERFACE_HEADER_NAME" => "react_native_media_library-Swift.h"
  }

  install_modules_dependencies(s)
end
