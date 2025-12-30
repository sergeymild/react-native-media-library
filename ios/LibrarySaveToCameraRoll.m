//
//  LibrarySaveToCameraRoll.m
//  MediaLibrary
//

#import "LibrarySaveToCameraRoll.h"
#import "MediaAssetManager.h"
#import <Photos/Photos.h>
#import <MobileCoreServices/MobileCoreServices.h>

@implementation LibrarySaveToCameraRoll

+ (PHAssetMediaType)assetTypeForUri:(NSString *)uri {
    NSString *fileExtension = [uri pathExtension];
    CFStringRef fileUTI = UTTypeCreatePreferredIdentifierForTag(
        kUTTagClassFilenameExtension,
        (__bridge CFStringRef)fileExtension,
        NULL
    );

    if (!fileUTI) return PHAssetMediaTypeUnknown;

    PHAssetMediaType type = PHAssetMediaTypeUnknown;
    if (UTTypeConformsTo(fileUTI, kUTTypeImage)) {
        type = PHAssetMediaTypeImage;
    } else if (UTTypeConformsTo(fileUTI, kUTTypeMovie)) {
        type = PHAssetMediaTypeVideo;
    } else if (UTTypeConformsTo(fileUTI, kUTTypeAudio)) {
        type = PHAssetMediaTypeAudio;
    }

    CFRelease(fileUTI);
    return type;
}

+ (NSURL *)normalizeAssetURLFromUri:(NSString *)uri {
    if ([uri hasPrefix:@"/"]) {
        return [NSURL URLWithString:[NSString stringWithFormat:@"file://%@", uri]];
    }
    return [NSURL URLWithString:uri];
}

+ (void)saveBlockWithAssetType:(PHAssetMediaType)assetType
                           url:(NSURL *)url
                    collection:(PHAssetCollection * _Nullable)collection
                    completion:(void (^)(NSString * _Nullable error, NSString * _Nullable identifier))completion {
    __block NSString *assetId = nil;

    [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
        PHAssetChangeRequest *changeRequest;
        if (assetType == PHAssetMediaTypeVideo) {
            changeRequest = [PHAssetChangeRequest creationRequestForAssetFromVideoAtFileURL:url];
        } else {
            changeRequest = [PHAssetChangeRequest creationRequestForAssetFromImageAtFileURL:url];
        }

        PHObjectPlaceholder *assetPlaceholder = changeRequest.placeholderForCreatedAsset;
        assetId = assetPlaceholder.localIdentifier;

        if (collection) {
            PHFetchResult *photosAsset = [PHAsset fetchAssetsInAssetCollection:collection options:nil];
            PHAssetCollectionChangeRequest *albumChangeRequest = [PHAssetCollectionChangeRequest changeRequestForAssetCollection:collection assets:photosAsset];
            [albumChangeRequest addAssets:@[assetPlaceholder]];
        }
    } completionHandler:^(BOOL success, NSError *error) {
        if (error) {
            completion(error.localizedDescription, nil);
        } else {
            completion(nil, assetId);
        }
    }];
}

+ (void)saveWithOptionsAlbum:(NSString * _Nullable)album
                   assetType:(PHAssetMediaType)assetType
                         url:(NSURL *)url
                  completion:(void (^)(NSString * _Nullable error, NSString * _Nullable identifier))completion {
    if (!album || album.length == 0) {
        [self saveBlockWithAssetType:assetType url:url collection:nil completion:completion];
        return;
    }

    PHFetchOptions *fetchOptions = [[PHFetchOptions alloc] init];
    fetchOptions.predicate = [NSPredicate predicateWithFormat:@"title = %@", album];

    PHFetchResult *collections = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeAlbum
                                                                          subtype:PHAssetCollectionSubtypeAny
                                                                          options:fetchOptions];

    if (collections.firstObject) {
        [self saveBlockWithAssetType:assetType url:url collection:collections.firstObject completion:completion];
        return;
    }

    // Create new collection
    __block NSString *placeholderId = nil;

    [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
        PHAssetCollectionChangeRequest *createAlbum = [PHAssetCollectionChangeRequest creationRequestForAssetCollectionWithTitle:album];
        placeholderId = createAlbum.placeholderForCreatedAssetCollection.localIdentifier;
    } completionHandler:^(BOOL success, NSError *error) {
        if (error || !placeholderId) {
            completion(error.localizedDescription ?: @"Failed to create album", nil);
            return;
        }

        PHFetchResult *newCollections = [PHAssetCollection fetchAssetCollectionsWithLocalIdentifiers:@[placeholderId] options:nil];
        PHAssetCollection *newCollection = newCollections.firstObject;

        if (newCollection) {
            [self saveBlockWithAssetType:assetType url:url collection:newCollection completion:completion];
        } else {
            completion(@"Failed to fetch created album", nil);
        }
    }];
}

+ (void)saveToCameraRollWithLocalUri:(NSString *)localUri
                               album:(NSString *)album
                            callback:(void (^)(NSString * _Nullable error, NSString * _Nullable result))callback {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        if (![[NSBundle mainBundle] objectForInfoDictionaryKey:@"NSPhotoLibraryAddUsageDescription"]) {
            callback(@"kErrorNoPermissions", nil);
            return;
        }

        if ([localUri pathExtension].length == 0) {
            callback(@"kErrorNoFileExtension", nil);
            return;
        }

        PHAssetMediaType assetType = [self assetTypeForUri:localUri];
        if (assetType == PHAssetMediaTypeAudio || assetType == PHAssetMediaTypeUnknown) {
            callback(@"kErrorUnsupportedAsset", nil);
            return;
        }

        NSURL *assetUrl = [self normalizeAssetURLFromUri:localUri];
        if (!assetUrl) {
            callback(@"kErrorNotValidUri", nil);
            return;
        }

        [self saveWithOptionsAlbum:album assetType:assetType url:assetUrl completion:^(NSString *error, NSString *identifier) {
            if (error) {
                callback(error, nil);
                return;
            }

            if (identifier) {
                [MediaAssetManager fetchAssetWithIdentifier:identifier completion:^(NSString *data) {
                    if (data) {
                        callback(nil, data);
                    } else {
                        callback(@"kErrorFetchAssetData", nil);
                    }
                }];
                return;
            }

            callback(@"kErrorSaveToCameraRoll", nil);
        }];
    });
}

@end
