//
//  NSObject+AssetsManager.m
//  MediaLibrary
//
//  Created by Sergei Golishnikov on 03/03/2023.
//  Copyright © 2023 Facebook. All rights reserved.
//

#import "AssetsManager.h"
#import "Helpers.h"

@implementation AssetsManager

+ (id)sharedManager {
    static AssetsManager *manager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[self alloc] init];
    });
    return manager;
}

- (id)init {
  return self;
}


-(void) fetchCollections:(json::array*)results {
    auto result = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeSmartAlbum subtype:PHAssetCollectionSubtypeSmartAlbumUserLibrary options:nil];
    auto resultFavorites = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeSmartAlbum subtype:PHAssetCollectionSubtypeSmartAlbumFavorites options:nil];
    
    results->reserve(result.count + resultFavorites.count);

    for (int i = 0; i < result.count; i++) {
        PHAssetCollection* asset = [result objectAtIndex:i];
        json::object object;
        object.insert("filename", [Helpers toCString:asset.localizedTitle]);
        object.insert("id", [Helpers toCString:asset.localIdentifier]);
        object.insert("type", "userType");
        results->push_back(object);
    }
    
    for (int i = 0; i < resultFavorites.count; i++) {
        PHAssetCollection* asset = [resultFavorites objectAtIndex:i];
        json::object object;
        object.insert("filename", [Helpers toCString:asset.localizedTitle]);
        object.insert("id", [Helpers toCString:asset.localIdentifier]);
        object.insert("type", "favorites");
        results->push_back(object);
    }
}

-(void) fetchAssets:(json::array*)results
              limit:(int)limit
             sortBy:(NSString* _Nullable)sortBy
          sortOrder:(NSString* _Nullable)sortOrder
         collection:(NSString* _Nullable)collectionId {
    PHCollection* _Nullable collection;
    if (collection) {
        collection = [PHAssetCollection fetchAssetCollectionsWithLocalIdentifiers:@[collectionId] options:nil].firstObject;
    }
    
    PHFetchOptions *fetchOptions = [PHFetchOptions new];
    fetchOptions.includeAllBurstAssets = false;
    fetchOptions.includeHiddenAssets = false;
    
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
    
    PHFetchResult<PHAsset *> *result;
    if (collection != NULL) {
        result = [PHAsset fetchAssetsInAssetCollection:collection options:fetchOptions];
    } else {
        result = [PHAsset fetchAssetsWithOptions:fetchOptions];
    }
    
    results->reserve(result.count);
    
    for (int i = 0; i < result.count; i++) {
        PHAsset* asset = [result objectAtIndex:i];
        json::object object;
        [self pHAssetToJSON:asset object:&object];
        results->push_back(object);
    }
}

-(void) fetchAsset:(NSString* _Nonnull)identifier
            object:(json::object* _Nonnull)object {

    PHAsset* asset = [self fetchRawAsset:identifier];
    
    [self pHAssetToJSON:asset object:object];
    PHContentEditingInputRequestOptions *options = [PHContentEditingInputRequestOptions new];
    [options setNetworkAccessAllowed:true];
    NSString* url = [self fetchAssetUrl: asset];
    object->insert("url", [Helpers toCString:url]);
}

-(PHAsset* _Nonnull) fetchRawAsset:(NSString* _Nonnull)identifier {
    if ([identifier hasPrefix:@"ph://"]) {
        identifier = [identifier stringByReplacingOccurrencesOfString:@"ph://" withString:@""];
    }
    
    PHFetchOptions *options = [PHFetchOptions new];
    options.includeHiddenAssets = YES;
    options.includeAllBurstAssets = YES;
    options.fetchLimit = 1;
    return [PHAsset fetchAssetsWithLocalIdentifiers:@[identifier] options:options].firstObject;
}

-(void) pHAssetToJSON: (PHAsset* _Nonnull)asset
               object:(json::object* _Nonnull)object {

    object->insert("fileName", [Helpers toCString:[asset valueForKey:@"filename"]]);
    object->insert("id", [Helpers toCString:asset.localIdentifier]);
    object->insert("creationTime", [Helpers _exportDate:asset.creationDate]);
    object->insert("modificationTime", [Helpers _exportDate:asset.modificationDate]);
    object->insert("mediaType", [Helpers toCString:[Helpers _stringifyMediaType:asset.mediaType]]);
    object->insert("duration", asset.duration);
    object->insert("width", (double)asset.pixelWidth);
    object->insert("height", (double)asset.pixelHeight);
    object->insert("uri", [Helpers toCString:[Helpers _toSdUrl:asset.localIdentifier]]);
    if (asset.location != NULL) {
        json::object location;
        location.insert("longitude", asset.location.coordinate.longitude);
        location.insert("latitude", asset.location.coordinate.latitude);
        object->insert("location", location);
    }
}


-(NSString*)fetchAssetUrl :(PHAsset *)asset  {
    PHContentEditingInputRequestOptions *options = [PHContentEditingInputRequestOptions new];
    [options setNetworkAccessAllowed:true];
    
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

@end
