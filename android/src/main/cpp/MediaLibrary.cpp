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
        mediaLibrary::GetAssetsCallback::registerNatives();
    });
};

namespace mediaLibrary {

using namespace facebook;
using namespace facebook::jni;
using namespace facebook::jsi;


using TSelf = local_ref<HybridClass<MediaLibrary>::jhybriddata>;

// JNI binding
void MediaLibrary::registerNatives() {
    __android_log_print(ANDROID_LOG_DEBUG, "MediaLibrary", "🥸 MediaLibrary.registerNatives");
    registerHybrid({
       makeNativeMethod("initHybrid", MediaLibrary::initHybrid),
       makeNativeMethod("installJSIBindings", MediaLibrary::installJSIBindings),
   });
}

std::function<void(std::string)> MediaLibrary::createCallback(
        const std::shared_ptr<facebook::jsi::Value>& resolve,
        bool returnUndefinedOnEmpty
        ) {
    std::function<void(std::string)> wrapperOnChange =
            [j = jsCallInvoker_, r = runtime_, resolve, returnUndefinedOnEmpty](const std::string& data) {
                j->invokeAsync([r, data, resolve, returnUndefinedOnEmpty]() {
                    if (data.empty() && returnUndefinedOnEmpty) {
                        resolve->asObject(*r).asFunction(*r).call(*r, jsi::Value::undefined());
                        return;
                    }
                    auto str = reinterpret_cast<const uint8_t *>(data.c_str());
                    auto value = jsi::Value::createFromJsonUtf8(*r, str, data.size());
                    resolve->asObject(*r).asFunction(*r).call(*r, std::move(value));
                });
            };
    return std::move(wrapperOnChange);
}

void MediaLibrary::installJSIBindings() {
    auto exportModule = jsi::Object(*runtime_);

    auto cacheDir = JSI_HOST_FUNCTION("cacheDir", 0) {
       auto method = javaPart_->getClass()->getMethod<JString()>("cacheDir");
       return jsi::String::createFromUtf8(runtime, method(javaPart_.get())->toStdString());
   });

    auto getAssets = JSI_HOST_FUNCTION("getAssets", 2) {
       auto stringify = runtime.global()
               .getPropertyAsObject(runtime, "JSON")
               .getPropertyAsFunction(runtime, "stringify");
       auto result = stringify.call(runtime, args[0]).asString(runtime).utf8(runtime);

        auto params = jni::make_jstring(result);
        auto resolve = std::make_shared<jsi::Value>(runtime, args[1]);

        auto method = javaPart_->getClass()->getMethod<void(jni::local_ref<JString>, GetAssetsCallback::javaobject)>("getAssets");

        std::function<void(std::string)> wrapperOnChange = createCallback(resolve, false);
        auto obj = GetAssetsCallback::newObjectCxxArgs(std::move(wrapperOnChange));
        method(javaPart_.get(), params, obj.get());
        return jsi::Value::undefined();
    });

    auto getCollections = JSI_HOST_FUNCTION("getCollections", 1) {
       auto stringify = runtime.global()
               .getPropertyAsObject(runtime, "JSON")
               .getPropertyAsFunction(runtime, "stringify");

        auto resolve = std::make_shared<jsi::Value>(runtime, args[0]);

        auto method = javaPart_->getClass()->getMethod<void(GetAssetsCallback::javaobject)>("getCollections");

        std::function<void(std::string)> wrapperOnChange = createCallback(resolve, false);
        auto obj = GetAssetsCallback::newObjectCxxArgs(std::move(wrapperOnChange));
        method(javaPart_.get(), obj.get());
        return jsi::Value::undefined();
    });

    auto getAsset = JSI_HOST_FUNCTION("getAsset", 1) {
        auto params = jni::make_jstring(args[0].asString(runtime).utf8(runtime));
        auto resolve = std::make_shared<jsi::Value>(runtime, args[1]);

        auto method = javaPart_->getClass()->getMethod<void(jni::local_ref<JString>, GetAssetsCallback::javaobject)>("getAsset");

        std::function<void(std::string)> wrapperOnChange = createCallback(resolve, true);

         auto obj = GetAssetsCallback::newObjectCxxArgs(std::move(wrapperOnChange));
         method(javaPart_.get(), params, obj.get());
         return jsi::Value::undefined();
   });

    auto saveToLibrary = JSI_HOST_FUNCTION("saveToLibrary", 1) {
        auto stringify = runtime.global()
        .getPropertyAsObject(runtime, "JSON")
        .getPropertyAsFunction(runtime, "stringify");
        auto result = stringify.call(runtime, args[0]).asString(runtime).utf8(runtime);

        auto params = jni::make_jstring(result);
        auto resolve = std::make_shared<jsi::Value>(runtime, args[1]);

        auto method = javaPart_->getClass()->getMethod<void(jni::local_ref<JString>, GetAssetsCallback::javaobject)>("saveToLibrary");

        std::function<void(std::string)> wrapperOnChange = createCallback(resolve, true);

       auto obj = GetAssetsCallback::newObjectCxxArgs(std::move(wrapperOnChange));
       method(javaPart_.get(), params, obj.get());
       return jsi::Value::undefined();
    });

    auto fetchVideoFrame = JSI_HOST_FUNCTION("fetchVideoFrame", 1) {
         auto stringify = runtime.global()
                 .getPropertyAsObject(runtime, "JSON")
                 .getPropertyAsFunction(runtime, "stringify");
         auto result = stringify.call(runtime, args[0]).asString(runtime).utf8(runtime);

         auto params = jni::make_jstring(result);
         auto resolve = std::make_shared<jsi::Value>(runtime, args[1]);

         auto method = javaPart_->getClass()->getMethod<void(jni::local_ref<JString>, GetAssetsCallback::javaobject)>("fetchVideoFrame");

         std::function<void(std::string)> wrapperOnChange = createCallback(resolve, true);

         auto obj = GetAssetsCallback::newObjectCxxArgs(std::move(wrapperOnChange));
         method(javaPart_.get(), params, obj.get());
         return jsi::Value::undefined();
     });

    auto combineImages = JSI_HOST_FUNCTION("combineImages", 1) {
       auto stringify = runtime.global()
               .getPropertyAsObject(runtime, "JSON")
               .getPropertyAsFunction(runtime, "stringify");
       auto result = stringify.call(runtime, args[0]).asString(runtime).utf8(runtime);
       auto params = jni::make_jstring(result);
       auto resolve = std::make_shared<jsi::Value>(runtime, args[1]);

       auto method = javaPart_->getClass()->getMethod<void(jni::local_ref<JString>, GetAssetsCallback::javaobject)>("combineImages");

       std::function<void(std::string)> wrapperOnChange = createCallback(resolve, true);

       auto obj = GetAssetsCallback::newObjectCxxArgs(std::move(wrapperOnChange));
       method(javaPart_.get(), params, obj.get());
       return jsi::Value::undefined();
   });

    auto imageResize = JSI_HOST_FUNCTION("imageResize", 1) {
       auto stringify = runtime.global()
               .getPropertyAsObject(runtime, "JSON")
               .getPropertyAsFunction(runtime, "stringify");
       auto result = stringify.call(runtime, args[0]).asString(runtime).utf8(runtime);
       auto params = jni::make_jstring(result);
       auto resolve = std::make_shared<jsi::Value>(runtime, args[1]);

       auto method = javaPart_->getClass()->getMethod<void(jni::local_ref<JString>, GetAssetsCallback::javaobject)>("imageResize");

       std::function<void(std::string)> wrapperOnChange = createCallback(resolve, true);

       auto obj = GetAssetsCallback::newObjectCxxArgs(std::move(wrapperOnChange));
       method(javaPart_.get(), params, obj.get());
       return jsi::Value::undefined();
   });

    auto imageCrop = JSI_HOST_FUNCTION("imageCrop", 1) {
       auto stringify = runtime.global()
               .getPropertyAsObject(runtime, "JSON")
               .getPropertyAsFunction(runtime, "stringify");
       auto result = stringify.call(runtime, args[0]).asString(runtime).utf8(runtime);
       auto params = jni::make_jstring(result);
       auto resolve = std::make_shared<jsi::Value>(runtime, args[1]);

       auto method = javaPart_->getClass()->getMethod<void(jni::local_ref<JString>, GetAssetsCallback::javaobject)>("imageCrop");

       std::function<void(std::string)> wrapperOnChange = createCallback(resolve, true);

       auto obj = GetAssetsCallback::newObjectCxxArgs(std::move(wrapperOnChange));
       method(javaPart_.get(), params, obj.get());
       return jsi::Value::undefined();
   });

    auto imageSizes = JSI_HOST_FUNCTION("combineImages", 1) {
       auto stringify = runtime.global()
               .getPropertyAsObject(runtime, "JSON")
               .getPropertyAsFunction(runtime, "stringify");
       auto result = stringify.call(runtime, args[0]).asString(runtime).utf8(runtime);
       auto params = jni::make_jstring(result);
       auto resolve = std::make_shared<jsi::Value>(runtime, args[1]);

       auto method = javaPart_->getClass()->getMethod<void(jni::local_ref<JString>, GetAssetsCallback::javaobject)>("imageSizes");

       std::function<void(std::string)> wrapperOnChange = createCallback(resolve, true);

       auto obj = GetAssetsCallback::newObjectCxxArgs(std::move(wrapperOnChange));
       method(javaPart_.get(), params, obj.get());
       return jsi::Value::undefined();
   });

    exportModule.setProperty(*runtime_, "cacheDir", std::move(cacheDir));
    exportModule.setProperty(*runtime_, "getAssets", std::move(getAssets));
    exportModule.setProperty(*runtime_, "getAsset", std::move(getAsset));
    exportModule.setProperty(*runtime_, "saveToLibrary", std::move(saveToLibrary));
    exportModule.setProperty(*runtime_, "fetchVideoFrame", std::move(fetchVideoFrame));
    exportModule.setProperty(*runtime_, "combineImages", std::move(combineImages));
    exportModule.setProperty(*runtime_, "imageSizes", std::move(imageSizes));
    exportModule.setProperty(*runtime_, "imageResize", std::move(imageResize));
    exportModule.setProperty(*runtime_, "imageCrop", std::move(imageCrop));
    exportModule.setProperty(*runtime_, "getCollections", std::move(getCollections));
    runtime_->global().setProperty(*runtime_, "__mediaLibrary", exportModule);
}


MediaLibrary::MediaLibrary(
        jni::alias_ref<MediaLibrary::javaobject> jThis,
        jsi::Runtime *rt,
        std::shared_ptr<facebook::react::CallInvoker> jsCallInvoker)
        : javaPart_(jni::make_global(jThis)),
          runtime_(rt),
          jsCallInvoker_(std::move(jsCallInvoker))
{}

// JNI init
TSelf MediaLibrary::initHybrid(
        alias_ref<jhybridobject> jThis,
        jlong jsContext,
        jni::alias_ref<facebook::react::CallInvokerHolder::javaobject> jsCallInvokerHolder
) {
    __android_log_print(ANDROID_LOG_DEBUG, "MediaLibrary", "🥸 initHybrid");
    auto jsCallInvoker = jsCallInvokerHolder->cthis()->getCallInvoker();
    return makeCxxInstance(
            jThis,
            (jsi::Runtime *) jsContext,
            jsCallInvoker
    );
}

}
