#import "MediaLibrary.h"

#import <React/RCTBridgeModule.h>
#import <React/RCTBridge.h>
#import "Macros.h"

#import <React/RCTBlobManager.h>
#import <React/RCTUIManager.h>
#import <React/RCTBridge+Private.h>
#import <ReactCommon/RCTTurboModule.h>

#import <Photos/Photos.h>

using namespace facebook;

@implementation MediaLibrary
RCT_EXPORT_MODULE()

jsi::Runtime* runtime_;

NSString *const AssetMediaTypeAudio = @"audio";
NSString *const AssetMediaTypePhoto = @"photo";
NSString *const AssetMediaTypeVideo = @"video";
NSString *const AssetMediaTypeUnknown = @"unknown";
NSString *const AssetMediaTypeAll = @"all";


+ (BOOL)requiresMainQueueSetup
{
  return FALSE;
}

RCT_EXPORT_BLOCKING_SYNCHRONOUS_METHOD(install) {
    NSLog(@"Installing MediaLibrary polyfill Bindings...");
    auto _bridge = [RCTBridge currentBridge];
    auto _cxxBridge = (RCTCxxBridge*)_bridge;
    if (_cxxBridge == nil) return @false;
    runtime_ = (jsi::Runtime*) _cxxBridge.runtime;
    if (runtime_ == nil) return @false;
    [self installJSIBindings];
    

    return @true;
}

jsi::String toJSIString(NSString *value) {
  return jsi::String::createFromUtf8(*runtime_, [value UTF8String] ?: "");
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

PHAsset* fetchAssetById(NSString* _id) {
    PHFetchOptions *options = [PHFetchOptions new];
    options.includeHiddenAssets = YES;
    options.includeAllBurstAssets = YES;
    options.fetchLimit = 1;
    return [PHAsset fetchAssetsWithLocalIdentifiers:@[_id] options:options].firstObject;
}

NSString* _requestUrl(PHAsset *asset, PHContentEditingInputRequestOptions *options, dispatch_semaphore_t sema) {
    __block NSString *url = @"";
    if (asset.mediaType == PHAssetMediaTypeImage) {
        [asset requestContentEditingInputWithOptions:options completionHandler:^(PHContentEditingInput * _Nullable contentEditingInput, NSDictionary * _Nonnull info) {
            url = [contentEditingInput.fullSizeImageURL absoluteString];
            dispatch_semaphore_signal(sema);
        }];
    } else if (asset.mediaType == PHAssetMediaTypeVideo) {
        auto options = [[PHVideoRequestOptions alloc] init];
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

jsi::Value fetchAssets(const jsi::Value *args) {
//    fetchAssetGroups();
    auto params = args[0].asObject(*runtime_);
    bool requestUrls = params.getProperty(*runtime_, "requestUrls").getBool();
    PHFetchOptions *fetchOptions = [PHFetchOptions new];
    NSMutableArray<NSPredicate *> *predicates = [NSMutableArray new];
    NSMutableDictionary *response = [NSMutableDictionary new];
    NSMutableArray<NSDictionary *> *assets = [NSMutableArray new];
    
    auto limit = params.getProperty(*runtime_, "limit");
    if (!limit.isUndefined()) {
        fetchOptions.fetchLimit = limit.asNumber();
    }
    
    fetchOptions.includeAllBurstAssets = false;
    fetchOptions.includeHiddenAssets = false;
    auto result = [PHAsset fetchAssetsWithOptions:fetchOptions];
    
    auto photosResult = jsi::Array(*runtime_, result.count);
    
    PHContentEditingInputRequestOptions *options = [PHContentEditingInputRequestOptions new];
    
    
    dispatch_semaphore_t sema = dispatch_semaphore_create(0);
    for (int i = 0; i < result.count; i++) {
        PHAsset* asset = [result objectAtIndex:i];
        
        auto photo = jsi::Object(*runtime_);
        
        if (requestUrls) {
            photo.setProperty(*runtime_, "url", toJSIString(_requestUrl(asset, options, sema)));
        }
        
        
        photo.setProperty(*runtime_, "fileName", toJSIString([asset valueForKey:@"filename"]));
        photo.setProperty(*runtime_, "id", toJSIString(asset.localIdentifier));
        photo.setProperty(*runtime_, "modificationTime", [MediaLibrary _exportDate:asset.modificationDate]);
        photo.setProperty(*runtime_, "mediaType", toJSIString([MediaLibrary _stringifyMediaType:asset.mediaType]));
        photo.setProperty(*runtime_, "duration", asset.duration);
        photo.setProperty(*runtime_, "width", (double)asset.pixelWidth);
        photo.setProperty(*runtime_, "height", (double)asset.pixelHeight);
        photosResult.setValueAtIndex(*runtime_, i, photo);
    }
    
    return photosResult;
}

-(void)installJSIBindings {
    
    auto getAssets = JSI_HOST_FUNCTION("getAssets", 1) {
        return fetchAssets(args);
    });
    
    auto getAssetUrl = JSI_HOST_FUNCTION("getAssetUrl", 1) {
        auto _id = [[NSString alloc] initWithCString:args[0].asString(runtime).utf8(runtime).c_str() encoding:NSUTF8StringEncoding];
        
        PHContentEditingInputRequestOptions *options = [PHContentEditingInputRequestOptions new];
        dispatch_semaphore_t sema = dispatch_semaphore_create(0);
        auto asset = fetchAssetById(_id);
        if (asset == nil) return jsi::Value::undefined();
        auto url = _requestUrl(asset, options, sema);
        return toJSIString(url);
    });


    auto exportModule = jsi::Object(*runtime_);
    exportModule.setProperty(*runtime_, "getAssets", std::move(getAssets));
    exportModule.setProperty(*runtime_, "getAssetUrl", std::move(getAssetUrl));
    runtime_->global().setProperty(*runtime_, "__mediaLibrary", exportModule);
}

@end
