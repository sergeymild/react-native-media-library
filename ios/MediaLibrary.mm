#import "MediaLibrary.h"

#import <React/RCTBridgeModule.h>
#import <React/RCTBridge.h>
#import "Macros.h"

#import <React/RCTBlobManager.h>
#import <React/RCTUIManager.h>
#import <React/RCTBridge+Private.h>
#import <React-NativeModulesApple/ReactCommon/RCTTurboModule.h>

#import <Photos/Photos.h>
#import <CoreServices/CoreServices.h>
#import "FetchVideoFrame.h"
#import "Helpers.h"
#import "react_native_media_library-Swift.h"
#import "MediaAssetFileNative.h"


using namespace facebook;

@interface MediaLibrary()
{

}
@end

@interface MediaLibraryFileEntry : NSObject
    @property (nonatomic, strong, nonnull) NSString *name;
    @property (nonatomic, strong, nonnull) NSString *absolutePath;
    @property (nonatomic, assign) BOOL isDirectory;
    @property (nonatomic, assign) UInt64 size;
    @property (nonatomic, strong, nullable) NSDate *modificationDate;
    - (NSMutableDictionary *)toNSDictionary;
@end

@implementation MediaLibraryFileEntry
- (NSMutableDictionary *)toNSDictionary
{
     
    NSMutableDictionary *dictionary = [[NSMutableDictionary alloc] init];
    [dictionary setValue:self.name forKey:@"filename"];
    [dictionary setValue:self.absolutePath forKey:@"uri"];
    [dictionary setValue:@(self.isDirectory) forKey:@"isDirectory"];
    [dictionary setValue:@(self.size) forKey:@"size"];
    [dictionary setValue:@([self.modificationDate timeIntervalSince1970] * 1000.0) forKey:@"modificationTime"];
     
    return dictionary;
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

-(MediaLibraryFileEntry *) createFrom:(MediaAssetFileNative::File)file {
    MediaLibraryFileEntry *entry = [[MediaLibraryFileEntry alloc] init];
    entry.name = @(file.name.c_str());
    entry.absolutePath = @(file.absolutePath.c_str());
    entry.isDirectory = file.isDir;
    entry.size = file.size;
    
    entry.modificationDate = [NSDate dateWithTimeIntervalSince1970:file.lastModificationTime / 1000];
    return entry;
};

RCT_EXPORT_BLOCKING_SYNCHRONOUS_METHOD(install) {
    NSLog(@"Installing MediaLibrary polyfill Bindings...");
    auto _bridge = [RCTBridge currentBridge];
    auto _cxxBridge = (RCTCxxBridge*)_bridge;
    if (_cxxBridge == nil) return @false;
    auto runtime_ = (jsi::Runtime*) _cxxBridge.runtime;
    if (runtime_ == nil) return @false;
    [self installJSIBindings:_bridge runtime:runtime_];


    return @true;
}

-(void)installJSIBindings:(RCTBridge *) _bridge runtime:(jsi::Runtime*)runtime_ {

    // MARK: cacheDir
    auto cacheDir = JSI_HOST_FUNCTION("cacheDir", 1) {
        auto *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES).firstObject;
        NSLog(@"===== %@", paths);
        return [Helpers toJSIString:paths runtime_:&runtime];
    });

    // MARK: getCollections
    auto getCollections = JSI_HOST_FUNCTION("getCollections", 1) {
        auto resolve = std::make_shared<jsi::Value>(runtime, args[0]);

        [MediaAssetManager fetchCollectionsWithCompletion:^(NSString * _Nonnull json) {
            std::string resultString = [Helpers toCString:json];
            _bridge.jsCallInvoker->invokeAsync([data = std::move(resultString), &runtime, resolve]() {
                auto str = reinterpret_cast<const uint8_t *>(data.c_str());
                auto value = jsi::Value::createFromJsonUtf8(runtime, str, data.size());
                resolve->asObject(runtime).asFunction(runtime).call(runtime, std::move(value));
            });
        }];

        return jsi::Value::undefined();
    });

    // MARK: getAssets
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

        [MediaAssetManager fetchAssetsWithLimit:limit
                                         offset:offset
                                         sortBy:sortBy
                                      sortOrder:sortOrder
                                      mediaType:mediaType
                                   collectionId:collectionId completion:^(NSString * _Nonnull json) {
            std::string resultString = [Helpers toCString:json];
            _bridge.jsCallInvoker->invokeAsync([data = std::move(resultString), &runtime, resolve]() {
                auto str = reinterpret_cast<const uint8_t *>(data.c_str());
                auto value = jsi::Value::createFromJsonUtf8(runtime, str, data.size());
                resolve->asObject(runtime).asFunction(runtime).call(runtime, std::move(value));
            });
        }];

        return jsi::Value::undefined();
    });
    
    auto getFromDisk = JSI_HOST_FUNCTION("getFromDisk", 2) {
        std::string sortBy;
        std::string sortOrder;
        
        std::string extensions;
        std::string sort = "modificationTime_desc";

        auto params = args[0].asObject(runtime);
        auto rawPath = params.getProperty(*runtime_, "path").asString(runtime).utf8(runtime);
        auto rawExtensions = params.getProperty(*runtime_, "extensions");
        auto rawSortBy = params.getProperty(*runtime_, "sortBy");
        auto rawSortOrder = params.getProperty(*runtime_, "sortOrder");

        if (!rawSortBy.isUndefined() && rawSortBy.isString()) {
            sortBy = rawSortBy.asString(runtime).utf8(runtime);
        }

        if (!rawSortOrder.isUndefined() && rawSortOrder.isString()) {
            sortOrder = rawSortOrder.asString(runtime).utf8(runtime);
        }
        
        if (!rawExtensions.isUndefined() && rawExtensions.isString()) {
            extensions = rawExtensions.asString(runtime).utf8(runtime);
            for (auto& x : extensions) x = tolower(x);
        }

        auto resolve = std::make_shared<jsi::Value>(runtime, args[1]);
        
        dispatch_async(defQueue, ^{
            MediaAssetFileNative::fileVector_t files;
            MediaAssetFileNative::getFilesList(rawPath.c_str(), sort.c_str(), &files);
            
            NSMutableArray<NSMutableDictionary *> *entries = [NSMutableArray arrayWithCapacity:files.size()];
            for(int i = 0; i < files.size(); i++) {
                auto f = files[i];
                auto skip = false;
                if (extensions != "") {
                    auto ext = f.absolutePath.substr(f.absolutePath.find_last_of(".") + 1);
                    for (auto& x : ext) x = tolower(x);
                    if (extensions.find(ext) == std::string::npos) skip = true;
                }
                
                if (skip) continue;
                MediaLibraryFileEntry *entry = [self createFrom:files[i]];
                [entries addObject:[entry toNSDictionary]];
            }
            
            NSError *error;
            NSData *jsonData = [NSJSONSerialization dataWithJSONObject:entries
                                            options:0
                                              error:&error];
            
            NSString *jsonString = @"[]";
            
            if (jsonData) {
                jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
            }
            std::string resultString = [Helpers toCString:jsonString];
            
            _bridge.jsCallInvoker->invokeAsync([data = std::move(resultString), &runtime, resolve]() {
                auto str = reinterpret_cast<const uint8_t *>(data.c_str());
                auto value = jsi::Value::createFromJsonUtf8(runtime, str, data.size());
                resolve->asObject(runtime).asFunction(runtime).call(runtime, std::move(value));
            });
        });

        return jsi::Value::undefined();
    });

    // MARK: getAsset
    auto getAsset = JSI_HOST_FUNCTION("getAsset", 2) {
        auto _id = [Helpers toString:args[0].asString(runtime) runtime_:&runtime];
        auto resolve = std::make_shared<jsi::Value>(runtime, args[1]);

        [MediaAssetManager fetchAssetWithIdentifier:_id completion:^(NSString * _Nullable json) {
            std::string resultString = [Helpers toCString:json];
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

    // MARK: saveToLibrary
    auto saveToLibrary = JSI_HOST_FUNCTION("saveToLibrary", 2) {
        auto params = args[0].asObject(runtime);
        auto localUri = [Helpers toString:params.getProperty(runtime, "localUrl").asString(runtime) runtime_:&runtime];
        NSString* album = @"";
        auto rawAlbum = params.getProperty(runtime, "album");
        if (!rawAlbum.isUndefined() && !rawAlbum.isNull() && rawAlbum.isString()) {
            album = [Helpers toString:rawAlbum.asString(runtime) runtime_:&runtime];
        }
        auto resolve = std::make_shared<jsi::Value>(runtime, args[1]);

        [LibrarySaveToCameraRoll saveToCameraRollWithLocalUri:localUri
                                                        album:album
                                                     callback:^(NSString * _Nullable error, NSString * _Nullable json) {
            std::string resultString = "";
            std::string errorString = "";

            if (error) {
                RCTLogError(@"MediaLibraryError %@", error);
                errorString = [Helpers toCString:error];
            } else {
                resultString = [Helpers toCString:json];
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
        }];

        return jsi::Value::undefined();
    });

    // MARK: fetchVideoFrame
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

    // MARK: combineImages
    auto combineImages = JSI_HOST_FUNCTION("combineImages", 2) {
        auto params = args[0].asObject(runtime);
        auto resolve = std::make_shared<jsi::Value>(runtime, args[1]);

        auto imagesRawArray = params.getPropertyAsObject(runtime, "images").asArray(runtime);
        auto rawPath = params.getProperty(runtime, "resultSavePath").asString(runtime).utf8(runtime);
        auto mainImageIndex = params.getProperty(runtime, "mainImageIndex").asNumber();
        auto backgroundColorNum = params.getProperty(runtime, "backgroundColor").asNumber();
        UIColor *backgroundColor = [RCTConvert UIColor:[NSNumber numberWithDouble:backgroundColorNum]];

        auto arraySize = imagesRawArray.size(runtime);
        NSString *resultSavePath = [[NSString alloc] initWithCString:rawPath.c_str() encoding:NSUTF8StringEncoding];

        NSMutableArray * imagesPathArray = [[NSMutableArray alloc] initWithCapacity:arraySize];

        for (int i = 0; i < arraySize; i++) {
            auto obj = imagesRawArray.getValueAtIndex(runtime, i).asObject(runtime);
            auto rawPath = obj.getProperty(runtime, "image").asString(runtime).utf8(runtime);
            NSString *path = [[NSString alloc] initWithCString:rawPath.c_str() encoding:NSUTF8StringEncoding];
            NSMutableDictionary* pos = [[NSMutableDictionary alloc] init];
            if (obj.hasProperty(runtime, "positions")) {
                auto rawPos = obj.getProperty(runtime, "positions").asObject(runtime);
                NSInteger x = rawPos.getProperty(runtime, "x").asNumber();
                NSInteger y = rawPos.getProperty(runtime, "y").asNumber();
                @try {
                    [pos setValue:[NSNumber numberWithDouble:x] forKey:@"x"];
                    [pos setValue:[NSNumber numberWithDouble:y] forKey:@"y"];
                } @catch (NSException *exception) {
                    NSLog(@"--");
                }
            }
            [imagesPathArray addObject:@{@"image": path, @"positions": pos}];
        }

        auto movedImages = std::move(imagesRawArray);
        dispatch_async(defQueue, ^{
            NSMutableArray * imagesArray = [[NSMutableArray alloc] initWithCapacity:arraySize];
            
            for (NSDictionary* obj in imagesPathArray) {
                NSString *path = [obj valueForKey:@"image"];
                NSDictionary *positions = [obj valueForKey:@"positions"];
                auto image = [LibraryImageSize imageWithPath:path];
                if (image) [imagesArray addObject:@{@"image": image, @"positions": positions}];
            }
            [imagesPathArray removeAllObjects];
            NSString* error = [LibraryCombineImages combineImagesWithImages:imagesArray
                                                             resultSavePath:resultSavePath
                                                             mainImageIndex:mainImageIndex
                                                            backgroundColor:backgroundColor];
            
            if (error) {
                RCTLogError(@"MediaLibraryError %@", error);
            }

            auto result = error ? RESULT_FALSE : RESULT_TRUE;

            _bridge.jsCallInvoker->invokeAsync([data = std::move(result), &runtime, &args, resolve]() {
                auto str = reinterpret_cast<const uint8_t *>(data.c_str());
                auto value = jsi::Value::createFromJsonUtf8(runtime, str, data.size());
                resolve->asObject(runtime).asFunction(runtime).call(runtime, value);
            });
        });


        return jsi::Value::undefined();
    });

    // MARK: combineImages
    auto exportVideo = JSI_HOST_FUNCTION("exportVideo", 2) {
        auto params = args[0].asObject(runtime);
        auto resolve = std::make_shared<jsi::Value>(runtime, args[1]);

        auto rawIdentifier = params.getProperty(runtime, "identifier").asString(runtime).utf8(runtime);
        auto rawPath = params.getProperty(runtime, "resultSavePath").asString(runtime).utf8(runtime);

        NSString *identifier = [[NSString alloc] initWithCString:rawIdentifier.c_str()
                                                        encoding:NSUTF8StringEncoding];

        NSString *resultPath = [[NSString alloc] initWithCString:rawPath.c_str()
                                                        encoding:NSUTF8StringEncoding];

        [MediaAssetManager exportVideoWithIdentifier:identifier resultSavePath:resultPath completion:^(BOOL success) {
            auto result = success ? RESULT_TRUE : RESULT_FALSE;
            _bridge.jsCallInvoker->invokeAsync([data = std::move(result), &runtime, &args, resolve]() {
                auto str = reinterpret_cast<const uint8_t *>(data.c_str());
                auto value = jsi::Value::createFromJsonUtf8(runtime, str, data.size());
                resolve->asObject(runtime).asFunction(runtime).call(runtime, value);
            });
        }];

        return jsi::Value::undefined();
    });

    // MARK: imageSizes
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

        [LibraryImageSize getSizesWithPaths:imagesPathArray completion:^(NSString * _Nonnull result) {
            std::string resultString = [Helpers toCString:result];

            _bridge.jsCallInvoker->invokeAsync([data = std::move(resultString), &runtime, &args, resolve]() {
                auto str = reinterpret_cast<const uint8_t *>(data.c_str());
                auto value = jsi::Value::createFromJsonUtf8(runtime, str, data.size());
                resolve->asObject(runtime).asFunction(runtime).call(runtime, value);
            });
        }];


        return jsi::Value::undefined();
    });

    // MARK: imageResize
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
            NSString* error = [LibraryImageResize resizeWithUri:uri
                                                          width:width
                                                         height:height
                                                         format:format
                                                 resultSavePath:resultSavePath];

            if (error) {
                RCTLogError(@"MediaLibraryError %@", error);
            }

            auto result = error ? RESULT_FALSE : RESULT_TRUE;

            _bridge.jsCallInvoker->invokeAsync([data = std::move(result), &runtime, &args, resolve]() {
                auto str = reinterpret_cast<const uint8_t *>(data.c_str());
                auto value = jsi::Value::createFromJsonUtf8(runtime, str, data.size());
                resolve->asObject(runtime).asFunction(runtime).call(runtime, value);
            });
        });


        return jsi::Value::undefined();
    });

    // MARK: imageCrop
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
            NSString* error = [LibraryImageResize cropWithUri:uri
                                                            x:[NSNumber numberWithDouble:rawX]
                                                            y:[NSNumber numberWithDouble:rawY]
                                                        width:[NSNumber numberWithDouble:rawWidth]
                                                       height:[NSNumber numberWithDouble:rawHeight]
                                                       format:format
                                               resultSavePath:resultSavePath];

            if (error) {
                RCTLogError(@"MediaLibraryError %@", error);
            }

            auto result = error ? RESULT_FALSE : RESULT_TRUE;

            _bridge.jsCallInvoker->invokeAsync([data = std::move(result), &runtime, &args, resolve]() {
                auto str = reinterpret_cast<const uint8_t *>(data.c_str());
                auto value = jsi::Value::createFromJsonUtf8(runtime, str, data.size());
                resolve->asObject(runtime).asFunction(runtime).call(runtime, value);
            });
        });


        return jsi::Value::undefined();
    });
    
    // MARK: downloadAsBase64
    auto downloadAsBase64 = JSI_HOST_FUNCTION("downloadAsBase64", 1) {
        auto params = args[0].asObject(runtime);
        auto resolve = std::make_shared<jsi::Value>(runtime, args[1]);

        auto imageUrl = params.getProperty(runtime, "url").asString(runtime).utf8(runtime);

        NSString *url = [[NSString alloc] initWithCString:imageUrl.c_str() encoding:NSUTF8StringEncoding];

        dispatch_async(defQueue, ^{
            [Base64Downloader downloadWithUrl:url completion:^(NSString * _Nullable string) {
                std::string resultString = [Helpers toCString:string];
                
                _bridge.jsCallInvoker->invokeAsync([data = std::move(resultString), &runtime, &args, resolve]() {
                    auto str = reinterpret_cast<const uint8_t *>(data.c_str());
                    auto value = jsi::Value::createFromJsonUtf8(runtime, str, data.size());
                    resolve->asObject(runtime).asFunction(runtime).call(runtime, value);
                });
            }];
        });


        return jsi::Value::undefined();
    });


    auto exportModule = jsi::Object(*runtime_);
    exportModule.setProperty(*runtime_, "getFromDisk", std::move(getFromDisk));
    exportModule.setProperty(*runtime_, "getAssets", std::move(getAssets));
    exportModule.setProperty(*runtime_, "getAsset", std::move(getAsset));
    exportModule.setProperty(*runtime_, "saveToLibrary", std::move(saveToLibrary));
    exportModule.setProperty(*runtime_, "fetchVideoFrame", std::move(fetchVideoFrame));
    exportModule.setProperty(*runtime_, "combineImages", std::move(combineImages));
    exportModule.setProperty(*runtime_, "cacheDir", std::move(cacheDir));
    exportModule.setProperty(*runtime_, "imageSizes", std::move(imageSizes));
    exportModule.setProperty(*runtime_, "imageResize", std::move(imageResize));
    exportModule.setProperty(*runtime_, "imageCrop", std::move(imageCrop));
    exportModule.setProperty(*runtime_, "exportVideo", std::move(exportVideo));
    exportModule.setProperty(*runtime_, "getCollections", std::move(getCollections));
    exportModule.setProperty(*runtime_, "downloadAsBase64", std::move(downloadAsBase64));
    runtime_->global().setProperty(*runtime_, "__mediaLibrary", exportModule);
}

@end
