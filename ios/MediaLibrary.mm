#import "MediaLibrary.h"

#import <React/RCTBridgeModule.h>
#import <React/RCTBridge.h>
#import "Macros.h"

#import <React/RCTBlobManager.h>
#import <React/RCTUIManager.h>
#import <React/RCTBridge+Private.h>
#import <ReactCommon/RCTTurboModule.h>

#import <Photos/Photos.h>
#import <CoreServices/CoreServices.h>
#import "SaveToCameraRoll.h"
#import "FetchVideoFrame.h"
#import "json.h"
#import "CombineImages.h"
#import "ImageSize.h"
#import "ImageResize.h"
#import "AssetsManager.h"
#import "Helpers.h"
#import "react_native_media_library-Swift.h"


using namespace facebook;

@interface MediaLibrary()
{
    SaveToCameraRoll *saveToCameraRoll;
}
@end

@implementation MediaLibrary
RCT_EXPORT_MODULE()

std::string RESULT_FALSE = "{\"result\": false}";
std::string RESULT_TRUE = "{\"result\": true}";


dispatch_queue_t defQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);

+ (BOOL)requiresMainQueueSetup
{
  return FALSE;
}

RCT_EXPORT_BLOCKING_SYNCHRONOUS_METHOD(install) {
    NSLog(@"Installing MediaLibrary polyfill Bindings...");
    auto _bridge = [RCTBridge currentBridge];
    auto _cxxBridge = (RCTCxxBridge*)_bridge;
    if (_cxxBridge == nil) return @false;
    auto runtime_ = (jsi::Runtime*) _cxxBridge.runtime;
    if (runtime_ == nil) return @false;
    [self installJSIBindings:_bridge runtime:runtime_];

    saveToCameraRoll = [[SaveToCameraRoll alloc] init];


    return @true;
}

-(void)installJSIBindings:(RCTBridge *) _bridge runtime:(jsi::Runtime*)runtime_ {

    auto cacheDir = JSI_HOST_FUNCTION("cacheDir", 1) {
        auto *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES).firstObject;
        NSLog(@"===== %@", paths);
        return [Helpers toJSIString:paths runtime_:&runtime];
    });

    auto getCollections = JSI_HOST_FUNCTION("getCollections", 1) {
        auto resolve = std::make_shared<jsi::Value>(runtime, args[0]);

        dispatch_async(defQueue, ^{
            json::array results;
            [AssetsManager.sharedManager fetchCollections:&results];

            std::string resultString = json::stringify(results);
            _bridge.jsCallInvoker->invokeAsync([data = std::move(resultString), &runtime, resolve]() {
                auto str = reinterpret_cast<const uint8_t *>(data.c_str());
                auto value = jsi::Value::createFromJsonUtf8(runtime, str, data.size());
                resolve->asObject(runtime).asFunction(runtime).call(runtime, std::move(value));
            });
        });

        return jsi::Value::undefined();
    });

    auto getAssets = JSI_HOST_FUNCTION("getAssets", 2) {
        int limit = -1;
        int offset = -1;
        NSString *sortBy = NULL;
        NSString *collectionId = NULL;
        NSString *sortOrder = NULL;
        bool onlyFavorites = false;

        auto params = args[0].asObject(runtime);
        auto rawLimit = params.getProperty(*runtime_, "limit");
        auto rawOffset = params.getProperty(*runtime_, "offset");
        auto rawSortBy = params.getProperty(*runtime_, "sortBy");
        auto rawSortOrder = params.getProperty(*runtime_, "sortOrder");
        auto rawOnlyFavorites = params.getProperty(*runtime_, "onlyFavorites");
        auto rawMediaTypes = params
            .getProperty(*runtime_, "mediaType")
            .asObject(runtime)
            .asArray(runtime);
        auto rawCollectionId = params.getProperty(*runtime_, "collectionId");
        if (!rawLimit.isUndefined()) limit = rawLimit.asNumber();
        if (!rawOffset.isUndefined()) offset = rawOffset.asNumber();
        if (!rawSortBy.isUndefined() && rawSortBy.isString()) {
            sortBy = [Helpers toString:rawSortBy.asString(runtime) runtime_:&runtime];
        }
        if (!rawCollectionId.isUndefined() && rawCollectionId.isString()) {
            collectionId = [Helpers toString:rawCollectionId.asString(runtime) runtime_:&runtime];
        }

        if (!rawOnlyFavorites.isUndefined() && !rawOnlyFavorites.isNull() && rawOnlyFavorites.getBool() == true) {
            onlyFavorites = true;
        }

        if (!rawSortOrder.isUndefined() && rawSortOrder.isString()) {
            sortOrder = [Helpers toString:rawSortOrder.asString(runtime) runtime_:&runtime];
        }

        auto resolve = std::make_shared<jsi::Value>(runtime, args[1]);

        NSMutableArray *mediaType = [[NSMutableArray alloc] init];

        for (int i = 0; i < rawMediaTypes.size(runtime); i++) {
            auto type =rawMediaTypes.getValueAtIndex(runtime, i);
            [mediaType addObject:[Helpers toString:type.asString(runtime) runtime_:&runtime]];
        }

        dispatch_async(defQueue, ^{
            json::array results;
            [AssetsManager.sharedManager fetchAssets:&results
                                               limit:limit
                                              offset:offset
                                              sortBy:sortBy
                                           sortOrder:sortOrder
                                           mediaType:mediaType
                                          collection:collectionId];

            std::string resultString = json::stringify(results);
            _bridge.jsCallInvoker->invokeAsync([data = std::move(resultString), &runtime, resolve]() {
                auto str = reinterpret_cast<const uint8_t *>(data.c_str());
                auto value = jsi::Value::createFromJsonUtf8(runtime, str, data.size());
                resolve->asObject(runtime).asFunction(runtime).call(runtime, std::move(value));
            });
        });

        return jsi::Value::undefined();
    });

    auto getAsset = JSI_HOST_FUNCTION("getAsset", 2) {
        auto _id = [Helpers toString:args[0].asString(runtime) runtime_:&runtime];
        auto resolve = std::make_shared<jsi::Value>(runtime, args[1]);
        
        [MediaAssetManager fetchAssetWithIdentifier:_id completion:^(AssetData * _Nullable assetData) {
            json::object object;
            [Helpers assetToJSON:assetData object:&object];
            std::string resultString = json::stringify(object);
            
            _bridge.jsCallInvoker->invokeAsync([data = std::move(resultString), &runtime, &args, resolve]() {
                if (data.size() == 0) {
                    resolve->asObject(runtime).asFunction(runtime).call(runtime, jsi::Value::undefined());
                    return;
                }
                auto str = reinterpret_cast<const uint8_t *>(data.c_str());
                auto value = jsi::Value::createFromJsonUtf8(runtime, str, data.size());
                resolve->asObject(runtime).asFunction(runtime).call(runtime, std::move(value));
            });
        }];
        return jsi::Value::undefined();
    });

    auto saveToLibrary = JSI_HOST_FUNCTION("saveToLibrary", 2) {
        auto params = args[0].asObject(runtime);
        auto localUri = [Helpers toString:params.getProperty(runtime, "localUrl").asString(runtime) runtime_:&runtime];
        NSString* album = @"";
        auto rawAlbum = params.getProperty(runtime, "album");
        if (!rawAlbum.isUndefined() && !rawAlbum.isNull() && rawAlbum.isString()) {
            album = [Helpers toString:rawAlbum.asString(runtime) runtime_:&runtime];
        }
        auto resolve = std::make_shared<jsi::Value>(runtime, args[1]);
        dispatch_async(defQueue, ^{
            [self->saveToCameraRoll saveToCameraRoll:localUri
                                         album:album
                                      callback:^(NSString * _Nullable error, NSString * _Nullable _id) {

                dispatch_async(defQueue, ^{

                    std::string resultString = "";
                    std::string errorString = "";
                    if (error) {
                        errorString = [Helpers toCString:error];
                    } else {
                        json::object object;
                        [AssetsManager.sharedManager fetchAsset:_id object:&object];
                        resultString = json::stringify(object);
                    }

                    _bridge.jsCallInvoker->invokeAsync([data = std::move(resultString), err = std::move(errorString), &runtime, &args, resolve]() {
                        if (err.size() > 0) {
                            resolve->asObject(runtime).asFunction(runtime).call(runtime, jsi::String::createFromUtf8(runtime, err));
                            return;
                        }
                        auto str = reinterpret_cast<const uint8_t *>(data.c_str());
                        auto value = jsi::Value::createFromJsonUtf8(runtime, str, data.size());
                        resolve->asObject(runtime).asFunction(runtime).call(runtime, std::move(value));
                    });

                });
            }];
        });

        return jsi::Value::undefined();
    });

    auto fetchVideoFrame = JSI_HOST_FUNCTION("fetchVideoFrame", 2) {
        auto params = args[0].asObject(runtime);
        auto url = [Helpers toString:params.getProperty(runtime, "url").asString(runtime) runtime_:&runtime];
        auto resolve = std::make_shared<jsi::Value>(runtime, args[1]);
        auto rawTime = params.getProperty(runtime, "time");
        auto rawQuality = params.getProperty(runtime, "quality");
        double time = 0;
        double quality = 1;
        if (!rawTime.isUndefined() && !rawTime.isNull() && rawTime.isNumber()) {
            time = rawTime.asNumber();
        }

        if (!rawQuality.isUndefined() && !rawQuality.isNull() && rawQuality.isNumber()) {
            quality = rawQuality.asNumber();
        }

        dispatch_async(defQueue, ^{
            auto resultString = [FetchVideoFrame fetchVideoFrame:url time:time quality:quality];
            dispatch_async(defQueue, ^{

                _bridge.jsCallInvoker->invokeAsync([data = std::move(resultString), &runtime, &args, resolve]() {
                    if (data == NULL) {
                        resolve->asObject(runtime).asFunction(runtime).call(runtime, jsi::Value::undefined());
                        return;
                    }
                    auto _str = [Helpers toCString:data];
                    auto str = reinterpret_cast<const uint8_t *>(_str);
                    auto value = jsi::Value::createFromJsonUtf8(runtime, str, data.length);
                    resolve->asObject(runtime).asFunction(runtime).call(runtime, std::move(value));
                });

            });
        });

        return jsi::Value::undefined();
    });

    auto combineImages = JSI_HOST_FUNCTION("combineImages", 2) {
        auto params = args[0].asObject(runtime);
        auto resolve = std::make_shared<jsi::Value>(runtime, args[1]);

        auto imagesRawArray = params.getPropertyAsObject(runtime, "images").asArray(runtime);
        auto rawPath = params.getProperty(runtime, "resultSavePath").asString(runtime).utf8(runtime);
        auto arraySize = imagesRawArray.size(runtime);
        NSString *resultSavePath = [[NSString alloc] initWithCString:rawPath.c_str() encoding:NSUTF8StringEncoding];

        NSMutableArray * imagesPathArray = [[NSMutableArray alloc] initWithCapacity:arraySize];

        for (int i = 0; i < arraySize; i++) {
            auto rawImage = imagesRawArray.getValueAtIndex(runtime, i).asString(runtime).utf8(runtime);
            [imagesPathArray addObject:[[NSString alloc] initWithCString:rawImage.c_str() encoding:NSUTF8StringEncoding]];
        }

        dispatch_async(defQueue, ^{
            NSMutableArray * imagesArray = [[NSMutableArray alloc] initWithCapacity:imagesPathArray.count];
            for (NSString* path in imagesPathArray) {
                auto image = [ImageSize uiImage:path];
                [imagesArray addObject:image];
            }
            auto result = [CombineImages combineImages:imagesArray resultSavePath:resultSavePath] ? RESULT_TRUE : RESULT_FALSE;

            _bridge.jsCallInvoker->invokeAsync([data = std::move(result), &runtime, &args, resolve]() {
                auto str = reinterpret_cast<const uint8_t *>(data.c_str());
                auto value = jsi::Value::createFromJsonUtf8(runtime, str, data.size());
                resolve->asObject(runtime).asFunction(runtime).call(runtime, value);
            });
        });


        return jsi::Value::undefined();
    });

    auto imageSizes = JSI_HOST_FUNCTION("imageSizes", 2) {
        auto params = args[0].asObject(runtime);
        auto resolve = std::make_shared<jsi::Value>(runtime, args[1]);

        auto imagesRawArray = params.getPropertyAsObject(runtime, "images").asArray(runtime);
        auto arraySize = imagesRawArray.size(runtime);

        NSMutableArray * imagesPathArray = [[NSMutableArray alloc] initWithCapacity:arraySize];

        for (int i = 0; i < arraySize; i++) {
            auto rawImage = imagesRawArray.getValueAtIndex(runtime, i).asString(runtime).utf8(runtime);
            [imagesPathArray addObject:[[NSString alloc] initWithCString:rawImage.c_str() encoding:NSUTF8StringEncoding]];
        }

        dispatch_async(defQueue, ^{
            json::array jsonResultArray;
            for (NSString* path in imagesPathArray) {
                json::object object;
                if ([path hasPrefix:@"ph://"]) {
                    PHAsset* asset = [AssetsManager.sharedManager fetchRawAsset:path];

                    object.insert("width", (double)asset.pixelWidth);
                    object.insert("height", (double)asset.pixelHeight);
                } else {
                    auto image = [ImageSize uiImage:path];
                    object.insert("width", (float)image.size.width);
                    object.insert("height", (float)image.size.height);
                }
                jsonResultArray.push_back(object);
            }
            auto resultString = json::stringify(jsonResultArray);

            _bridge.jsCallInvoker->invokeAsync([data = std::move(resultString), &runtime, &args, resolve]() {
                auto str = reinterpret_cast<const uint8_t *>(data.c_str());
                auto value = jsi::Value::createFromJsonUtf8(runtime, str, data.size());
                resolve->asObject(runtime).asFunction(runtime).call(runtime, value);
            });
        });


        return jsi::Value::undefined();
    });

    auto imageResize = JSI_HOST_FUNCTION("imageResize", 1) {
        auto params = args[0].asObject(runtime);
        auto resolve = std::make_shared<jsi::Value>(runtime, args[1]);

        auto imageUri = params.getProperty(runtime, "uri").asString(runtime).utf8(runtime);
        auto rawWidth = params.getProperty(runtime, "width").asNumber();
        auto rawHeight = params.getProperty(runtime, "height").asNumber();
        auto rawFormat = params.getProperty(runtime, "format").asString(runtime).utf8(runtime);
        auto rawPath = params.getProperty(runtime, "resultSavePath").asString(runtime).utf8(runtime);

        NSString *uri = [[NSString alloc] initWithCString:imageUri.c_str() encoding:NSUTF8StringEncoding];
        NSString *format = [[NSString alloc] initWithCString:rawFormat.c_str() encoding:NSUTF8StringEncoding];
        NSString *resultSavePath = [[NSString alloc] initWithCString:rawPath.c_str() encoding:NSUTF8StringEncoding];
        NSNumber *width = [NSNumber numberWithDouble:rawWidth];
        NSNumber *height = [NSNumber numberWithDouble:rawHeight];

        dispatch_async(defQueue, ^{
            auto result = [ImageResize resize:uri
                                        width:width
                                       height:height
                                       format:format
                               resultSavePath:resultSavePath] ? RESULT_TRUE : RESULT_FALSE;

            _bridge.jsCallInvoker->invokeAsync([data = std::move(result), &runtime, &args, resolve]() {
                auto str = reinterpret_cast<const uint8_t *>(data.c_str());
                auto value = jsi::Value::createFromJsonUtf8(runtime, str, data.size());
                resolve->asObject(runtime).asFunction(runtime).call(runtime, value);
            });
        });


        return jsi::Value::undefined();
    });

    auto imageCrop = JSI_HOST_FUNCTION("imageCrop", 1) {
        auto params = args[0].asObject(runtime);
        auto resolve = std::make_shared<jsi::Value>(runtime, args[1]);

        auto imageUri = params.getProperty(runtime, "uri").asString(runtime).utf8(runtime);
        auto rawX = params.getProperty(runtime, "x").asNumber();
        auto rawY = params.getProperty(runtime, "y").asNumber();
        auto rawWidth = params.getProperty(runtime, "width").asNumber();
        auto rawHeight = params.getProperty(runtime, "height").asNumber();
        auto rawFormat = params.getProperty(runtime, "format").asString(runtime).utf8(runtime);
        auto rawPath = params.getProperty(runtime, "resultSavePath").asString(runtime).utf8(runtime);

        NSString *uri = [[NSString alloc] initWithCString:imageUri.c_str() encoding:NSUTF8StringEncoding];
        NSString *format = [[NSString alloc] initWithCString:rawFormat.c_str() encoding:NSUTF8StringEncoding];
        NSString *resultSavePath = [[NSString alloc] initWithCString:rawPath.c_str() encoding:NSUTF8StringEncoding];

        dispatch_async(defQueue, ^{
            auto result = [ImageResize crop:uri
                                          x:[NSNumber numberWithDouble:rawX]
                                          y:[NSNumber numberWithDouble:rawY]
                                      width:[NSNumber numberWithDouble:rawWidth]
                                     height:[NSNumber numberWithDouble:rawHeight]
                                     format:format
                             resultSavePath:resultSavePath] ? RESULT_TRUE : RESULT_FALSE;

            _bridge.jsCallInvoker->invokeAsync([data = std::move(result), &runtime, &args, resolve]() {
                auto str = reinterpret_cast<const uint8_t *>(data.c_str());
                auto value = jsi::Value::createFromJsonUtf8(runtime, str, data.size());
                resolve->asObject(runtime).asFunction(runtime).call(runtime, value);
            });
        });


        return jsi::Value::undefined();
    });


    auto exportModule = jsi::Object(*runtime_);
    exportModule.setProperty(*runtime_, "getAssets", std::move(getAssets));
    exportModule.setProperty(*runtime_, "getAsset", std::move(getAsset));
    exportModule.setProperty(*runtime_, "saveToLibrary", std::move(saveToLibrary));
    exportModule.setProperty(*runtime_, "fetchVideoFrame", std::move(fetchVideoFrame));
    exportModule.setProperty(*runtime_, "combineImages", std::move(combineImages));
    exportModule.setProperty(*runtime_, "cacheDir", std::move(cacheDir));
    exportModule.setProperty(*runtime_, "imageSizes", std::move(imageSizes));
    exportModule.setProperty(*runtime_, "imageResize", std::move(imageResize));
    exportModule.setProperty(*runtime_, "imageCrop", std::move(imageCrop));
    exportModule.setProperty(*runtime_, "getCollections", std::move(getCollections));
    runtime_->global().setProperty(*runtime_, "__mediaLibrary", exportModule);
}

@end
