cmake_minimum_required(VERSION 3.10)

set (CMAKE_VERBOSE_MAKEFILE ON)
set (CMAKE_CXX_STANDARD 17)
set (PACKAGE_NAME "react-native-media-library")

set (BUILD_DIR ${CMAKE_SOURCE_DIR}/build)
include("${REACT_NATIVE_DIR}/ReactAndroid/cmake-utils/folly-flags.cmake")
add_compile_options(${folly_FLAGS})

# Consume shared libraries and headers from prefabs
find_package(fbjni REQUIRED CONFIG)
find_package(ReactAndroid REQUIRED CONFIG)

add_library(
        ${PACKAGE_NAME}
        SHARED
        src/main/cpp/MediaLibrary.cpp
        src/main/cpp/MediaAssetFileNative.cpp
)

# includes

target_include_directories(
        ${PACKAGE_NAME}
        PRIVATE
        "${REACT_NATIVE_DIR}/ReactAndroid/src/main/jni/react/turbomodule"
        "${REACT_NATIVE_DIR}/ReactCommon"
        "${REACT_NATIVE_DIR}/ReactCommon/callinvoker"
        "src/main/cpp"
)

find_library(
        LOG_LIB
        log
)

target_link_libraries(
        ${PACKAGE_NAME}
        ${LOG_LIB}
        ReactAndroid::jsi
        ReactAndroid::reactnativejni
        fbjni::fbjni
        android
)
