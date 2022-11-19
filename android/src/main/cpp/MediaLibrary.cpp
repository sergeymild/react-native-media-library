//
// Created by Sergei Golishnikov on 06/03/2022.
//

#include "MediaLibrary.h"
#include "Macros.h"

#include <utility>
#include "iostream"

JNIEXPORT jint JNICALL JNI_OnLoad(JavaVM *vm, void *) {
    return facebook::jni::initialize(vm, [] {
        mediaLibrary::MediaLibrary::registerNatives();
    });
};

namespace mediaLibrary {

using namespace facebook;
using namespace facebook::jni;
using namespace facebook::jsi;


using TSelf = local_ref<HybridClass<MediaLibrary>::jhybriddata>;

// JNI binding
void MediaLibrary::registerNatives() {
    __android_log_print(ANDROID_LOG_ERROR, "MediaLibrary", "🥸 registerNatives");
    registerHybrid({
       makeNativeMethod("initHybrid", MediaLibrary::initHybrid),
       makeNativeMethod("installJSIBindings", MediaLibrary::installJSIBindings),
   });
}

void MediaLibrary::installJSIBindings() {
    auto exportModule = jsi::Object(*runtime_);


    auto getAssets = JSI_HOST_FUNCTION("getAssets", 1) {
        auto params = jni::make_jstring(args[0].asString(runtime).utf8(runtime));
        auto method = javaPart_->getClass()->getMethod<JString(jni::local_ref<JString>)>("getAssets");
        auto response = method(javaPart_.get(), params);
        auto str = response->toStdString();
        return jsi::Value::createFromJsonUtf8(runtime, reinterpret_cast<const uint8_t *>(str.c_str()), str.size());
    });

    auto getAsset = JSI_HOST_FUNCTION("getAsset", 1) {
        auto params = jni::make_jstring(args[0].asString(runtime).utf8(runtime));
        auto method = javaPart_->getClass()->getMethod<JString(jni::local_ref<JString>)>("getAsset");
        auto response = method(javaPart_.get(), params);
        auto str = response->toStdString();
        return jsi::Value::createFromJsonUtf8(runtime, reinterpret_cast<const uint8_t *>(str.c_str()), str.size());
   });

    auto saveToLibrary = JSI_HOST_FUNCTION("saveToLibrary", 1) {
        auto params = jni::make_jstring(args[0].asString(runtime).utf8(runtime));
        auto method = javaPart_->getClass()->getMethod<JString(jni::local_ref<JString>)>("saveToLibrary");
        auto response = method(javaPart_.get(), params);
        auto str = response->toStdString();
        return jsi::Value::createFromJsonUtf8(runtime, reinterpret_cast<const uint8_t *>(str.c_str()), str.size());
    });

    exportModule.setProperty(*runtime_, "getAssets", std::move(getAssets));
    exportModule.setProperty(*runtime_, "getAsset", std::move(getAsset));
    exportModule.setProperty(*runtime_, "saveToLibrary", std::move(saveToLibrary));
    runtime_->global().setProperty(*runtime_, "__mediaLibrary", exportModule);
}


MediaLibrary::MediaLibrary(jni::alias_ref<MediaLibrary::javaobject> jThis,jsi::Runtime *rt)
        : javaPart_(jni::make_global(jThis)),
          runtime_(rt)
          {}

// JNI init
TSelf MediaLibrary::initHybrid(alias_ref<jhybridobject> jThis,jlong jsContext) {
    __android_log_print(ANDROID_LOG_ERROR, "MediaLibrary", "🥸 initHybrid");
    return makeCxxInstance(jThis,(jsi::Runtime *) jsContext);
}

}
