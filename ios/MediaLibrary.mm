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


using namespace facebook;

@interface MediaLibrary()
{
    SaveToCameraRoll *saveToCameraRoll;
}
@end

@implementation MediaLibrary
RCT_EXPORT_MODULE()

NSString *const AssetMediaTypeAudio = @"audio";
NSString *const AssetMediaTypePhoto = @"photo";
NSString *const AssetMediaTypeVideo = @"video";
NSString *const AssetMediaTypeUnknown = @"unknown";
NSString *const AssetMediaTypeAll = @"all";

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

jsi::String toJSIString(NSString *value, jsi::Runtime* runtime_) {
  return jsi::String::createFromUtf8(*runtime_, [value UTF8String] ?: "");
}

const char* toCString(NSString *value) {
    return [value cStringUsingEncoding:NSUTF8StringEncoding];
}

NSString* toString(jsi::String value, jsi::Runtime* runtime_) {
    return [[NSString alloc] initWithCString:value.utf8(*runtime_).c_str() encoding:NSUTF8StringEncoding];
}

+ (PHAssetMediaType)_assetTypeForUri:(nonnull NSString *)localUri
{
  CFStringRef fileExtension = (__bridge CFStringRef)[localUri pathExtension];
  CFStringRef fileUTI = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, fileExtension, NULL);

  if (UTTypeConformsTo(fileUTI, kUTTypeImage)) {
    return PHAssetMediaTypeImage;
  }
  if (UTTypeConformsTo(fileUTI, kUTTypeMovie)) {
    return PHAssetMediaTypeVideo;
  }
  if (UTTypeConformsTo(fileUTI, kUTTypeAudio)) {
    return PHAssetMediaTypeAudio;
  }
  return PHAssetMediaTypeUnknown;
}

+ (NSURL *)_normalizeAssetURLFromUri:(NSString *)uri
{
  if ([uri hasPrefix:@"/"]) {
    return [NSURL URLWithString:[@"file://" stringByAppendingString:uri]];
  }
  return [NSURL URLWithString:uri];
}

+ (NSString *)_stringifyMediaType:(PHAssetMediaType)mediaType
{
  switch (mediaType) {
    case PHAssetMediaTypeAudio:
      return AssetMediaTypeAudio;
    case PHAssetMediaTypeImage:
      return AssetMediaTypePhoto;
    case PHAssetMediaTypeVideo:
      return AssetMediaTypeVideo;
    default:
      return AssetMediaTypeUnknown;
  }
}

+ (double)_exportDate:(NSDate *)date {
    if (!date) return 0.0;
    NSTimeInterval interval = date.timeIntervalSince1970;
    NSUInteger intervalMs = interval * 1000;
    return [[NSNumber numberWithUnsignedInteger:intervalMs] doubleValue];
}

+ (NSString *)_assetIdFromLocalId:(nonnull NSString *)localId {
  // PHAsset's localIdentifier looks like `8B51C35E-E1F3-4D18-BF90-22CC905737E9/L0/001`
  // however `/L0/001` doesn't take part in URL to the asset, so we need to strip it out.
  return [localId stringByReplacingOccurrencesOfString:@"/.*" withString:@"" options:NSRegularExpressionSearch range:NSMakeRange(0, localId.length)];
}

+ (NSString *)_assetUriForLocalId:(nonnull NSString *)localId
{
  NSString *assetId = [MediaLibrary _assetIdFromLocalId:localId];
  return [NSString stringWithFormat:@"ph://%@", assetId];
}


+ (NSString *)_toSdUrl:(nonnull NSString *)localId
{
    return [[NSURL URLWithString:[NSString stringWithFormat:@"ph://%@", localId]] absoluteString];
}

NSSortDescriptor* _sortDescriptorFrom(jsi::Runtime* runtime_, jsi::Value sortBy, jsi::Value sortOrder)
{
    auto sortKey = toString(sortBy.asString(*runtime_), runtime_);
    if ([sortKey  isEqual: @"creationTime"] || [sortKey  isEqual: @"modificationTime"]) {
        bool ascending = false;
        if (!sortOrder.isUndefined() && sortOrder.asString(*runtime_).utf8(*runtime_) == "asc") {
            ascending = true;
        }
        return [NSSortDescriptor sortDescriptorWithKey:sortKey ascending:ascending];
    }
    return nil;
}

PHAsset* fetchAssetById(NSString* _id) {
    if ([_id hasPrefix:@"ph://"]) {
        _id = [_id stringByReplacingOccurrencesOfString:@"ph://" withString:@""];
    }
    PHFetchOptions *options = [PHFetchOptions new];
    options.includeHiddenAssets = YES;
    options.includeAllBurstAssets = YES;
    options.fetchLimit = 1;
    return [PHAsset fetchAssetsWithLocalIdentifiers:@[_id] options:options].firstObject;
}

NSString* _requestUrl(PHAsset *asset, PHContentEditingInputRequestOptions *options) {
    dispatch_semaphore_t sema = dispatch_semaphore_create(0);
    __block NSString *url = @"";
    if (asset.mediaType == PHAssetMediaTypeImage) {
        [asset requestContentEditingInputWithOptions: options
                                   completionHandler:^(PHContentEditingInput * _Nullable contentEditingInput, NSDictionary * _Nonnull info) {
            url = [contentEditingInput.fullSizeImageURL absoluteString];
            dispatch_semaphore_signal(sema);
        }];
    } else if (asset.mediaType == PHAssetMediaTypeVideo) {
        PHVideoRequestOptions* options = [[PHVideoRequestOptions alloc] init];
        [options setVersion:PHVideoRequestOptionsVersionOriginal];
        [options setNetworkAccessAllowed:true];
        [[PHImageManager defaultManager] requestAVAssetForVideo:asset
                                                        options:options
                                                  resultHandler:^(AVAsset * _Nullable ass, AVAudioMix * _Nullable audioMix, NSDictionary * _Nullable info) {
            url = [((AVURLAsset*)ass).URL absoluteString];
            dispatch_semaphore_signal(sema);
        }];
    }
    dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);
    return url;
}

void fromPHAssetToValue(PHAsset *asset, json::object *object, bool isFull) {
    object->insert("fileName", toCString([asset valueForKey:@"filename"]));
    object->insert("id", toCString(asset.localIdentifier));
    object->insert("creationTime", [MediaLibrary _exportDate:asset.creationDate]);
    object->insert("modificationTime", [MediaLibrary _exportDate:asset.modificationDate]);
    object->insert("mediaType", toCString([MediaLibrary _stringifyMediaType:asset.mediaType]));
    object->insert("duration", asset.duration);
    object->insert("width", (double)asset.pixelWidth);
    object->insert("height", (double)asset.pixelHeight);
    object->insert("uri", toCString([MediaLibrary _toSdUrl:asset.localIdentifier]));
    if (asset.location != NULL) {
        json::object location;
        location.insert("longitude", asset.location.coordinate.longitude);
        location.insert("latitude", asset.location.coordinate.latitude);
        object->insert("location", location);
    }

    if (isFull) {
        PHContentEditingInputRequestOptions *options = [PHContentEditingInputRequestOptions new];
        [options setNetworkAccessAllowed:true];
        object->insert("url", toCString(_requestUrl(asset, options)));
    }
}

void fetchAssets(json::array *results, int limit, NSString* _Nullable sortBy, NSString* _Nullable sortOrder, bool onlyFavorites) {
    PHFetchOptions *fetchOptions = [PHFetchOptions new];

    if (limit > 0) fetchOptions.fetchLimit = limit;

    // sort
    if (sortBy != NULL && ![sortBy isEqualToString:@""]) {
        if ([sortBy isEqualToString: @"creationTime"] || [sortBy isEqualToString: @"modificationTime"]) {
            bool ascending = false;
            auto key = [sortBy isEqual: @"creationTime"] ? @"creationDate" : @"modificationDate";
            if (sortOrder != NULL && [sortOrder isEqualToString:@"asc"]) {
                ascending = true;
            }
            fetchOptions.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:key ascending:ascending]];
        }
    }

    if (onlyFavorites) {
        NSString *format = @"favorite == true";
        fetchOptions.predicate = [NSPredicate predicateWithFormat:format];
    }

    fetchOptions.includeAllBurstAssets = false;
    fetchOptions.includeHiddenAssets = false;
    auto result = [PHAsset fetchAssetsWithOptions:fetchOptions];

    results->reserve(result.count);


    for (int i = 0; i < result.count; i++) {
        PHAsset* asset = [result objectAtIndex:i];
        json::object object;
        fromPHAssetToValue(asset, &object, false);
        results->push_back(object);
    }

}

-(void)installJSIBindings:(RCTBridge *) _bridge runtime:(jsi::Runtime*)runtime_ {

    auto cacheDir = JSI_HOST_FUNCTION("cacheDir", 1) {
        auto *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES).firstObject;
        NSLog(@"===== %@", paths);
        return toJSIString(paths, &runtime);
    });

    auto getAssets = JSI_HOST_FUNCTION("getAssets", 2) {
        int limit = -1;
        NSString *sortBy = NULL;
        NSString *sortOrder = NULL;
        bool onlyFavorites = false;

        auto params = args[0].asObject(runtime);
        auto rawLimit = params.getProperty(*runtime_, "limit");
        auto rawSortBy = params.getProperty(*runtime_, "sortBy");
        auto rawSortOrder = params.getProperty(*runtime_, "sortOrder");
        auto rawOnlyFavorites = params.getProperty(*runtime_, "onlyFavorites");
        if (!rawLimit.isUndefined()) limit = rawLimit.asNumber();
        if (!rawSortBy.isUndefined() && rawSortBy.isString()) {
            sortBy = toString(rawSortBy.asString(runtime), &runtime);
        }

        if (!rawOnlyFavorites.isUndefined() && !rawOnlyFavorites.isNull() && rawOnlyFavorites.getBool() == true) {
            onlyFavorites = true;
        }

        if (!rawSortOrder.isUndefined() && rawSortOrder.isString()) {
            sortOrder = toString(rawSortOrder.asString(runtime), &runtime);
        }

        auto resolve = std::make_shared<jsi::Value>(runtime, args[1]);

        dispatch_async(defQueue, ^{
            json::array results;
            fetchAssets(&results, limit, sortBy, sortOrder, onlyFavorites);
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
        auto _id = toString(args[0].asString(runtime), &runtime);
        auto resolve = std::make_shared<jsi::Value>(runtime, args[1]);

        dispatch_async(defQueue, ^{
            PHAsset* asset = fetchAssetById(_id);
            std::string resultString = "";
            if (asset != nil) {
                json::object object;
                fromPHAssetToValue(asset, &object, true);
                resultString = json::stringify(object);
            }

            _bridge.jsCallInvoker->invokeAsync([data = std::move(resultString), &runtime, &args, resolve]() {
                if (data.size() == 0) {
                    resolve->asObject(runtime).asFunction(runtime).call(runtime, jsi::Value::undefined());
                    return;
                }
                auto str = reinterpret_cast<const uint8_t *>(data.c_str());
                auto value = jsi::Value::createFromJsonUtf8(runtime, str, data.size());
                resolve->asObject(runtime).asFunction(runtime).call(runtime, std::move(value));
            });
        });
        return jsi::Value::undefined();
    });

    auto saveToLibrary = JSI_HOST_FUNCTION("saveToLibrary", 2) {
        auto params = args[0].asObject(runtime);
        auto localUri = toString(params.getProperty(runtime, "localUrl").asString(runtime), &runtime);
        NSString* album = @"";
        auto rawAlbum = params.getProperty(runtime, "album");
        if (!rawAlbum.isUndefined() && !rawAlbum.isNull() && rawAlbum.isString()) {
            album = toString(rawAlbum.asString(runtime), &runtime);
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
                        errorString = toCString(error);
                    } else {
                        PHAsset* asset = fetchAssetById(_id);
                        if (asset != nil) {
                            json::object object;
                            fromPHAssetToValue(asset, &object, true);
                            resultString = json::stringify(object);
                        }
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
        auto url = toString(params.getProperty(runtime, "url").asString(runtime), &runtime);
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
                    auto _str = toCString(data);
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
                    auto asset = fetchAssetById(path);
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


    auto exportModule = jsi::Object(*runtime_);
    exportModule.setProperty(*runtime_, "getAssets", std::move(getAssets));
    exportModule.setProperty(*runtime_, "getAsset", std::move(getAsset));
    exportModule.setProperty(*runtime_, "saveToLibrary", std::move(saveToLibrary));
    exportModule.setProperty(*runtime_, "fetchVideoFrame", std::move(fetchVideoFrame));
    exportModule.setProperty(*runtime_, "combineImages", std::move(combineImages));
    exportModule.setProperty(*runtime_, "cacheDir", std::move(cacheDir));
    exportModule.setProperty(*runtime_, "imageSizes", std::move(imageSizes));
    exportModule.setProperty(*runtime_, "imageResize", std::move(imageResize));
    runtime_->global().setProperty(*runtime_, "__mediaLibrary", exportModule);
}

@end
