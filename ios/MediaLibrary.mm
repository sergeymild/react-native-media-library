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
dispatch_semaphore_t sema = dispatch_semaphore_create(0);

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

NSString* toString(jsi::String value) {
    return [[NSString alloc] initWithCString:value.utf8(*runtime_).c_str() encoding:NSUTF8StringEncoding];
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

NSSortDescriptor* _sortDescriptorFrom(jsi::Value sortBy, jsi::Value sortOrder)
{
    auto sortKey = toString(sortBy.asString(*runtime_));
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
    PHFetchOptions *options = [PHFetchOptions new];
    options.includeHiddenAssets = YES;
    options.includeAllBurstAssets = YES;
    options.fetchLimit = 1;
    return [PHAsset fetchAssetsWithLocalIdentifiers:@[_id] options:options].firstObject;
}

NSString* _requestUrl(PHAsset *asset, PHContentEditingInputRequestOptions *options) {
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

jsi::Value fromPHAssetToValue(PHAsset *asset, bool requestUrls) {
    auto object = jsi::Object(*runtime_);
    
    if (requestUrls) {
        PHContentEditingInputRequestOptions *options = [PHContentEditingInputRequestOptions new];
        object.setProperty(*runtime_, "url", toJSIString(_requestUrl(asset, options)));
    }
    
    object.setProperty(*runtime_, "fileName", toJSIString([asset valueForKey:@"filename"]));
    object.setProperty(*runtime_, "id", toJSIString(asset.localIdentifier));
    object.setProperty(*runtime_, "creationTime", [MediaLibrary _exportDate:asset.creationDate]);
    object.setProperty(*runtime_, "modificationTime", [MediaLibrary _exportDate:asset.modificationDate]);
    object.setProperty(*runtime_, "mediaType", toJSIString([MediaLibrary _stringifyMediaType:asset.mediaType]));
    object.setProperty(*runtime_, "duration", asset.duration);
    object.setProperty(*runtime_, "width", (double)asset.pixelWidth);
    object.setProperty(*runtime_, "height", (double)asset.pixelHeight);
    object.setProperty(*runtime_, "uri", toJSIString([MediaLibrary _toSdUrl:asset.localIdentifier]));
    return object;
}

jsi::Value fetchAssets(const jsi::Value *args) {
//    fetchAssetGroups();
    auto params = args[0].asObject(*runtime_);
    bool requestUrls = params.getProperty(*runtime_, "requestUrls").getBool();
    PHFetchOptions *fetchOptions = [PHFetchOptions new];
    
    // limit
    auto limit = params.getProperty(*runtime_, "limit");
    if (!limit.isUndefined()) {
        fetchOptions.fetchLimit = limit.asNumber();
    }
    
    // sort
    auto sortBy = params.getProperty(*runtime_, "sortBy");
    auto sortOrder = params.getProperty(*runtime_, "sortOrder");
    if (!sortBy.isUndefined()) {
        auto sortKey = toString(sortBy.asString(*runtime_));
        if ([sortKey isEqual: @"creationTime"] || [sortKey  isEqual: @"modificationTime"]) {
            bool ascending = false;
            auto key = [sortKey isEqual: @"creationTime"] ? @"creationDate" : @"modificationDate";
            if (sortOrder.asString(*runtime_).utf8(*runtime_) == "asc") {
                ascending = true;
            }
            fetchOptions.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:key ascending:ascending]];
        }
    }
    
    fetchOptions.includeAllBurstAssets = false;
    fetchOptions.includeHiddenAssets = false;
    auto result = [PHAsset fetchAssetsWithOptions:fetchOptions];
    
    auto photosResult = jsi::Array(*runtime_, result.count);
    
    
    for (int i = 0; i < result.count; i++) {
        PHAsset* asset = [result objectAtIndex:i];
        
        auto photo = fromPHAssetToValue(asset, requestUrls);
        photosResult.setValueAtIndex(*runtime_, i, photo);
    }
    
    return photosResult;
}

-(void)installJSIBindings {
    
    auto getAssets = JSI_HOST_FUNCTION("getAssets", 1) {
        return fetchAssets(args);
    });
    
    auto getAsset = JSI_HOST_FUNCTION("getAsset", 1) {
        auto _id = toString(args[0].asString(runtime));
        
        PHContentEditingInputRequestOptions *options = [PHContentEditingInputRequestOptions new];
        auto asset = fetchAssetById(_id);
        if (asset == nil) return jsi::Value::undefined();
        return fromPHAssetToValue(asset, true);
    });


    auto exportModule = jsi::Object(*runtime_);
    exportModule.setProperty(*runtime_, "getAssets", std::move(getAssets));
    exportModule.setProperty(*runtime_, "getAsset", std::move(getAsset));
    runtime_->global().setProperty(*runtime_, "__mediaLibrary", exportModule);
}

@end
