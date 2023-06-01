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
    auto smartAlbums = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeSmartAlbum subtype:PHAssetCollectionSubtypeAny options:nil];
    auto albums = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeAlbum subtype:PHAssetCollectionSubtypeAny options:nil];

    results->reserve(smartAlbums.count + albums.count);
    NSOperationQueue* queue = [NSOperationQueue new];

    for (int i = 0; i < smartAlbums.count; i++) {
        NSOperation* op = [NSBlockOperation blockOperationWithBlock:^{
            PHAssetCollection* asset = [smartAlbums objectAtIndex:i];
            json::object object;
            object.insert("filename", [Helpers toCString:asset.localizedTitle]);
            object.insert("count", [self fetchCollectionCount:asset]);
            object.insert("id", [Helpers toCString:asset.localIdentifier]);
            results->push_back(object);
        }];
        [queue addOperation:op];
    }

    for (int i = 0; i < albums.count; i++) {
        NSOperation* op = [NSBlockOperation blockOperationWithBlock:^{
            PHAssetCollection* asset = [albums objectAtIndex:i];
            json::object object;
            object.insert("filename", [Helpers toCString:asset.localizedTitle]);
            object.insert("count", [self fetchCollectionCount:asset]);
            object.insert("id", [Helpers toCString:asset.localIdentifier]);
            results->push_back(object);
        }];
        [queue addOperation:op];
    }

    [queue waitUntilAllOperationsAreFinished];
}

-(NSUInteger)fetchCollectionCount:(PHAssetCollection* _Nonnull)collection {
    PHFetchOptions *fetchOptions = [PHFetchOptions new];
    fetchOptions.includeAllBurstAssets = false;
    fetchOptions.includeHiddenAssets = false;
    fetchOptions.fetchLimit = 0;
    auto result = [PHAsset fetchAssetsInAssetCollection:collection options:fetchOptions];
    return result.count;
}

-(void) fetchAssets:(json::array*)results
              limit:(int)limit
              offset:(int)offset
             sortBy:(NSString* _Nullable)sortBy
          sortOrder:(NSString* _Nullable)sortOrder
          mediaType:(NSArray* _Nonnull)mediaType
         collection:(NSString* _Nullable)collectionId {
    PHCollection* _Nullable collection;
    if (collectionId) {
        collection = [PHAssetCollection fetchAssetCollectionsWithLocalIdentifiers:@[collectionId] options:nil].firstObject;
    }

    PHFetchOptions *fetchOptions = [PHFetchOptions new];
    fetchOptions.includeAllBurstAssets = false;
    fetchOptions.includeHiddenAssets = false;

    if (!([mediaType containsObject:@"photo"] && [mediaType containsObject:@"video"])) {
        PHAssetMediaType type = PHAssetMediaTypeImage;
        if ([mediaType containsObject:@"video"]) {
            type = PHAssetMediaTypeVideo;
        }
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"mediaType = %d",type];
        [fetchOptions setPredicate:predicate];
    }

    if (limit > 0 && offset == -1) fetchOptions.fetchLimit = limit;

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

    int totalCount = result.count;
    int startIndex = MAX(0, offset == -1 ? -1 : offset + 1);
    int endIndex = MIN(startIndex + limit, totalCount);
    if (startIndex == endIndex) return;

    results->reserve(endIndex - startIndex);
    NSLog(@"fetchFrom: %d to: %d, total: %lu", startIndex, endIndex, (unsigned long)result.count);

    for (int i = startIndex; i < endIndex; i++) {
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

    object->insert("filename", [Helpers toCString:[asset valueForKey:@"filename"]]);
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
//        [options setVersion:PHVideoRequestOptionsVersionOriginal];
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
