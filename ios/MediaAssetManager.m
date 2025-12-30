//
//  MediaAssetManager.m
//  MediaLibrary
//

#import "MediaAssetManager.h"
#import "LibraryImageSize.h"
#import <AVFoundation/AVFoundation.h>

@implementation MediaAssetManager

+ (nullable PHAsset *)fetchRawAssetWithIdentifier:(NSString *)identifier {
    NSString *cleanId = [identifier stringByReplacingOccurrencesOfString:@"ph://" withString:@""];
    PHFetchOptions *options = [[PHFetchOptions alloc] init];
    options.includeHiddenAssets = YES;
    options.includeAllBurstAssets = YES;
    options.fetchLimit = 1;
    return [PHAsset fetchAssetsWithLocalIdentifiers:@[cleanId] options:options].firstObject;
}

+ (NSString *)mediaTypeStringForAsset:(PHAsset *)asset {
    switch (asset.mediaType) {
        case PHAssetMediaTypeAudio: return @"audio";
        case PHAssetMediaTypeImage: return @"photo";
        case PHAssetMediaTypeVideo: return @"video";
        default: return @"unknown";
    }
}

+ (NSArray<NSString *> *)mediaSubtypesForAsset:(PHAsset *)asset {
    NSMutableArray *subtypes = [NSMutableArray array];
    PHAssetMediaSubtype sub = asset.mediaSubtypes;

    if (sub & PHAssetMediaSubtypePhotoPanorama) [subtypes addObject:@"photoPanorama"];
    if (sub & PHAssetMediaSubtypePhotoHDR) [subtypes addObject:@"photoHDR"];
    if (sub & PHAssetMediaSubtypePhotoScreenshot) [subtypes addObject:@"photoScreenshot"];
    if (sub & PHAssetMediaSubtypePhotoLive) [subtypes addObject:@"photoLive"];
    if (sub & PHAssetMediaSubtypePhotoDepthEffect) [subtypes addObject:@"photoDepthEffect"];
    if (sub & PHAssetMediaSubtypeVideoStreamed) [subtypes addObject:@"videoStreamed"];
    if (sub & PHAssetMediaSubtypeVideoHighFrameRate) [subtypes addObject:@"videoHighFrameRate"];
    if (sub & PHAssetMediaSubtypeVideoTimelapse) [subtypes addObject:@"videoTimelapse"];
    if (@available(iOS 15.0, *)) {
        if (sub & PHAssetMediaSubtypeVideoCinematic) [subtypes addObject:@"videoCinematic"];
    }

    return subtypes;
}

+ (NSDictionary *)assetToDataWithAsset:(PHAsset *)asset url:(NSString * _Nullable)url {
    NSString *localUrl = url;
    if (url) {
        NSArray *parts = [url componentsSeparatedByString:@"#"];
        localUrl = parts.firstObject;
    }

    NSMutableDictionary *location = nil;
    if (asset.location) {
        location = [NSMutableDictionary dictionary];
        location[@"longitude"] = @(asset.location.coordinate.longitude);
        location[@"latitude"] = @(asset.location.coordinate.latitude);
    }

    NSMutableDictionary *data = [NSMutableDictionary dictionary];
    data[@"filename"] = [asset valueForKey:@"filename"];
    data[@"id"] = asset.localIdentifier;
    data[@"duration"] = @(asset.duration);
    data[@"width"] = @((double)asset.pixelWidth);
    data[@"height"] = @((double)asset.pixelHeight);
    data[@"mediaType"] = [self mediaTypeStringForAsset:asset];
    data[@"uri"] = [NSString stringWithFormat:@"ph://%@", asset.localIdentifier];
    data[@"subtypes"] = [self mediaSubtypesForAsset:asset];

    if (asset.creationDate) {
        data[@"creationTime"] = @([asset.creationDate timeIntervalSince1970] * 1000.0);
    }
    if (asset.modificationDate) {
        data[@"modificationTime"] = @([asset.modificationDate timeIntervalSince1970] * 1000.0);
    }
    if (localUrl) {
        data[@"url"] = localUrl;
    }
    if (location) {
        data[@"location"] = location;
    }

    return data;
}

+ (void)fetchAssetUrlForAsset:(PHAsset *)asset completion:(void (^)(NSURL * _Nullable url))completion {
    if (asset.mediaType == PHAssetMediaTypeImage) {
        PHContentEditingInputRequestOptions *options = [[PHContentEditingInputRequestOptions alloc] init];
        options.networkAccessAllowed = YES;

        [asset requestContentEditingInputWithOptions:options completionHandler:^(PHContentEditingInput *input, NSDictionary *info) {
            completion(input.fullSizeImageURL);
        }];
        return;
    }

    if (asset.mediaType == PHAssetMediaTypeVideo) {
        PHVideoRequestOptions *options = [[PHVideoRequestOptions alloc] init];
        options.networkAccessAllowed = YES;

        [[PHImageManager defaultManager] requestAVAssetForVideo:asset options:options resultHandler:^(AVAsset *avAsset, AVAudioMix *audioMix, NSDictionary *info) {
            if ([avAsset isKindOfClass:[AVURLAsset class]]) {
                AVURLAsset *urlAsset = (AVURLAsset *)avAsset;
                completion(urlAsset.URL);
            } else {
                completion(nil);
            }
        }];
        return;
    }

    completion(nil);
}

+ (void)fetchAssetWithIdentifier:(NSString *)identifier
                      completion:(void (^)(NSString * _Nullable json))completion {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        PHAsset *asset = [self fetchRawAssetWithIdentifier:identifier];
        if (!asset) {
            completion(nil);
            return;
        }

        [self fetchAssetUrlForAsset:asset completion:^(NSURL *url) {
            NSDictionary *data = [self assetToDataWithAsset:asset url:url.absoluteString];
            NSError *error;
            NSData *jsonData = [NSJSONSerialization dataWithJSONObject:data options:0 error:&error];
            if (error) {
                completion(nil);
                return;
            }
            completion([[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding]);
        }];
    });
}

+ (void)fetchAssetsWithLimit:(int)limit
                      offset:(int)offset
                      sortBy:(NSString * _Nullable)sortBy
                   sortOrder:(NSString * _Nullable)sortOrder
                   mediaType:(NSArray<NSString *> *)mediaType
                collectionId:(NSString * _Nullable)collectionId
                  completion:(void (^)(NSString *json))completion {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        PHAssetCollection *collection = nil;
        if (collectionId) {
            collection = [PHAssetCollection fetchAssetCollectionsWithLocalIdentifiers:@[collectionId] options:nil].firstObject;
        }

        PHFetchOptions *options = [[PHFetchOptions alloc] init];
        options.includeAllBurstAssets = NO;
        options.includeHiddenAssets = NO;

        BOOL hasPhoto = [mediaType containsObject:@"photo"];
        BOOL hasVideo = [mediaType containsObject:@"video"];

        if (!(hasPhoto && hasVideo)) {
            PHAssetMediaType type = hasVideo ? PHAssetMediaTypeVideo : PHAssetMediaTypeImage;
            options.predicate = [NSPredicate predicateWithFormat:@"mediaType = %d", type];
        }

        if (limit > 0 && offset == -1) {
            options.fetchLimit = limit;
        }

        if (sortBy && sortBy.length > 0) {
            if ([sortBy isEqualToString:@"creationTime"] || [sortBy isEqualToString:@"modificationTime"]) {
                BOOL ascending = [sortOrder isEqualToString:@"asc"];
                NSString *key = [sortBy isEqualToString:@"creationTime"] ? @"creationDate" : @"modificationDate";
                options.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:key ascending:ascending]];
            }
        }

        PHFetchResult *result;
        if (collection) {
            result = [PHAsset fetchAssetsInAssetCollection:collection options:options];
        } else {
            result = [PHAsset fetchAssetsWithOptions:options];
        }

        NSInteger totalCount = result.count;
        NSInteger startIndex = MAX(0, offset == -1 ? 0 : offset);
        NSInteger effectiveLimit = limit == -1 ? 10 : limit;
        NSInteger endIndex = MIN(startIndex + effectiveLimit, totalCount);

        if (startIndex >= endIndex) {
            completion(@"[]");
            return;
        }

        NSMutableArray *assets = [NSMutableArray array];
        for (NSInteger i = startIndex; i < endIndex; i++) {
            PHAsset *asset = [result objectAtIndex:i];
            [assets addObject:[self assetToDataWithAsset:asset url:nil]];
        }

        NSError *error;
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:assets options:0 error:&error];
        NSString *jsonString = error ? @"[]" : [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
        completion(jsonString ?: @"[]");
    });
}

+ (void)fetchCollectionsWithCompletion:(void (^)(NSString *json))completion {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        PHFetchResult *smartAlbums = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeSmartAlbum subtype:PHAssetCollectionSubtypeAny options:nil];
        PHFetchResult *albums = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeAlbum subtype:PHAssetCollectionSubtypeAny options:nil];

        NSMutableArray *collections = [NSMutableArray array];

        PHFetchOptions *countOptions = [[PHFetchOptions alloc] init];
        countOptions.includeAllBurstAssets = NO;
        countOptions.includeHiddenAssets = NO;

        for (PHAssetCollection *coll in smartAlbums) {
            NSInteger count = [PHAsset fetchAssetsInAssetCollection:coll options:countOptions].count;
            [collections addObject:@{
                @"id": coll.localIdentifier,
                @"filename": coll.localizedTitle ?: @"unknown",
                @"count": @(count)
            }];
        }

        for (PHAssetCollection *coll in albums) {
            NSInteger count = [PHAsset fetchAssetsInAssetCollection:coll options:countOptions].count;
            [collections addObject:@{
                @"id": coll.localIdentifier,
                @"filename": coll.localizedTitle ?: @"unknown",
                @"count": @(count)
            }];
        }

        NSError *error;
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:collections options:0 error:&error];
        NSString *jsonString = error ? @"[]" : [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
        completion(jsonString ?: @"[]");
    });
}

+ (void)exportVideoWithIdentifier:(NSString *)identifier
                   resultSavePath:(NSString *)resultSavePath
                       completion:(void (^)(BOOL success))completion {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        PHAsset *asset = [self fetchRawAssetWithIdentifier:identifier];
        if (!asset) {
            completion(NO);
            return;
        }

        PHVideoRequestOptions *options = [[PHVideoRequestOptions alloc] init];
        options.networkAccessAllowed = YES;

        [[PHImageManager defaultManager] requestExportSessionForVideo:asset
                                                              options:options
                                                         exportPreset:AVAssetExportPresetMediumQuality
                                                        resultHandler:^(AVAssetExportSession *exportSession, NSDictionary *info) {
            if (!exportSession) {
                completion(NO);
                return;
            }

            ensurePath(resultSavePath);

            exportSession.outputURL = toFilePath(resultSavePath);
            exportSession.outputFileType = AVFileTypeMPEG4;
            exportSession.shouldOptimizeForNetworkUse = YES;

            [exportSession exportAsynchronouslyWithCompletionHandler:^{
                switch (exportSession.status) {
                    case AVAssetExportSessionStatusCompleted:
                        completion(YES);
                        break;
                    default:
                        if (exportSession.error) {
                            NSLog(@"Export error: %@", exportSession.error);
                        }
                        completion(NO);
                        break;
                }
            }];
        }];
    });
}

@end
