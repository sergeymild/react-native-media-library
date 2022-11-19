cmake_minimum_required(VERSION 3.10)

set (CMAKE_VERBOSE_MAKEFILE ON)
set (CMAKE_CXX_STANDARD 17)
set (CMAKE_CXX_FLAGS "-DFOLLY_NO_CONFIG=1 -DFOLLY_HAVE_CLOCK_GETTIME=1 -DFOLLY_HAVE_MEMRCHR=1 -DFOLLY_USE_LIBCPP=1 -DFOLLY_MOBILE=1 -DON_ANDROID -DONANDROID")

set (PACKAGE_NAME "react-native-media-library")
set (BUILD_DIR ${CMAKE_SOURCE_DIR}/build)
set (CPPHTTPLIB_ZLIB_SUPPORT 0)
set (RN_SO_DIR ${NODE_MODULES_DIR}/react-native/ReactAndroid/src/main/jni/first-party/react/jni)

add_library(
        ${PACKAGE_NAME}
        SHARED
        src/main/cpp/MediaLibrary.cpp
)

# includes

file (GLOB LIBFBJNI_INCLUDE_DIR "${BUILD_DIR}/fbjni-*-headers.jar/")

target_include_directories(
        ${PACKAGE_NAME}
        PRIVATE
        # --- fbjni ---
        "${LIBFBJNI_INCLUDE_DIR}"
        # --- React Native ---
        "${NODE_MODULES_DIR}/react-native/React"
        "${NODE_MODULES_DIR}/react-native/React/Base"
        "${NODE_MODULES_DIR}/react-native/ReactCommon/jsi"
        "${NODE_MODULES_DIR}/react-native/ReactAndroid/src/main/java/com/facebook/react/turbomodule/core/jni"
        "${NODE_MODULES_DIR}/react-native/ReactCommon"
        "${NODE_MODULES_DIR}/react-native/ReactCommon/callinvoker"
        "src/main/cpp"
)

# find libraries

file (GLOB LIBRN_DIR "${BUILD_DIR}/react-native-0*/jni/${ANDROID_ABI}")

find_library(
        FBJNI_LIB
        fbjni
        PATHS ${LIBRN_DIR}
        NO_CMAKE_FIND_ROOT_PATH
)
if(${REACT_NATIVE_VERSION} LESS 69)
    find_library(
            FOLLY_JSON_LIB
            folly_json
            PATHS ${LIBRN_DIR}
            NO_CMAKE_FIND_ROOT_PATH
    )
else()
    find_library(
            FOLLY_JSON_LIB
            folly_runtime
            PATHS ${LIBRN_DIR}
            NO_CMAKE_FIND_ROOT_PATH
    )
endif()

find_library(
        REACT_NATIVE_JNI_LIB
        reactnativejni
        PATHS ${LIBRN_DIR}
        NO_CMAKE_FIND_ROOT_PATH
)

# RN 0.66 distributes libjsi.so, can be used instead of compiling jsi.cpp manually.
find_library(
        JSI_LIB
        jsi
        PATHS ${LIBRN_DIR}
        NO_CMAKE_FIND_ROOT_PATH
)


find_library(
        LOG_LIB
        log
)

message(WARNING "JSI-WS linking: CMAKE_CURRENT_SOURCE_DIR=${ANDROID_ABI}")
target_link_libraries(
        ${PACKAGE_NAME}
        ${LOG_LIB}
        ${JSI_LIB}
        ${FBJNI_LIB}
        ${REACT_NATIVE_JNI_LIB}
        android
)
