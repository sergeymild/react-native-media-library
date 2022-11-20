#include <fbjni/fbjni.h>
#include <jsi/jsi.h>
#include <ReactCommon/CallInvokerHolder.h>
#include <fbjni/detail/References.h>
#import "map"

namespace mediaLibrary {

    using namespace facebook::jsi;

    class GetAssetsCallback : public facebook::jni::HybridClass<GetAssetsCallback> {
    public:
        static auto constexpr kJavaDescriptor =
                "Lcom/reactnativemedialibrary/GetAssetsCallback;";

        void onChange(std::string data) {
            __android_log_print(ANDROID_LOG_DEBUG, "MediaLibrary", "🥸 GetAssetsCallback.onChange");
            callback_(data);
        }

        static void registerNatives() {
            __android_log_print(ANDROID_LOG_DEBUG, "MediaLibrary", "🥸 GetAssetsCallback.registerNatives");
            registerHybrid({
                makeNativeMethod("onChange", GetAssetsCallback::onChange)
            });
        }

    private:
        friend HybridBase;

        explicit GetAssetsCallback(std::function<void(std::string)> callback)
                : callback_(std::move(callback)) {}
        std::function<void(std::string)> callback_;
    };


    class MediaLibrary : public facebook::jni::HybridClass<MediaLibrary> {
    public:
        static constexpr auto kJavaDescriptor = "Lcom/reactnativemedialibrary/MediaLibrary;";

        static facebook::jni::local_ref<jhybriddata> initHybrid(
                facebook::jni::alias_ref<jhybridobject> jThis,
                jlong jsContext,
                facebook::jni::alias_ref<facebook::react::CallInvokerHolder::javaobject> jsCallInvokerHolder
        );

        static void registerNatives();

        void installJSIBindings();

    private:
        friend HybridBase;
        facebook::jni::global_ref<MediaLibrary::javaobject> javaPart_;
        facebook::jsi::Runtime *runtime_;
        std::shared_ptr<facebook::react::CallInvoker> jsCallInvoker_;

        explicit MediaLibrary(
                facebook::jni::alias_ref<MediaLibrary::jhybridobject> jThis,
        facebook::jsi::Runtime *rt,
                std::shared_ptr<facebook::react::CallInvoker> jsCallInvoker
        );
    };

}
