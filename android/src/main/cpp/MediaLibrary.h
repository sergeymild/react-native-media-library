#include <fbjni/fbjni.h>
#include <jsi/jsi.h>
#include <ReactCommon/CallInvokerHolder.h>
#include <fbjni/detail/References.h>
#import "map"

namespace mediaLibrary {

    using namespace facebook::jsi;

    class MediaLibrary : public facebook::jni::HybridClass<MediaLibrary> {
    public:
        static constexpr auto kJavaDescriptor = "Lcom/reactnativemedialibrary/MediaLibrary;";

        static facebook::jni::local_ref<jhybriddata> initHybrid(
                facebook::jni::alias_ref<jhybridobject> jThis,
                jlong jsContext
        );

        static void registerNatives();

        void installJSIBindings();

    private:
        friend HybridBase;
        facebook::jni::global_ref<MediaLibrary::javaobject> javaPart_;
        facebook::jsi::Runtime *runtime_;

        explicit MediaLibrary(
                facebook::jni::alias_ref<MediaLibrary::jhybridobject> jThis,
                facebook::jsi::Runtime *rt
        );
    };

}
