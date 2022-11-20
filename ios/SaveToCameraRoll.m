//
//  SaveToCameraRoll.m
//  MediaLibrary
//
//  Created by Sergei Golishnikov on 20/11/2022.
//  Copyright © 2022 Facebook. All rights reserved.
//

#import "SaveToCameraRoll.h"
#import <Photos/Photos.h>
#import <CoreServices/CoreServices.h>

@implementation SaveToCameraRoll

static NSString *const kErrorUnableToSave = @"E_UNABLE_TO_SAVE";
static NSString *const kErrorUnableToLoad = @"E_UNABLE_TO_LOAD";

static NSString *const kErrorAuthRestricted = @"E_PHOTO_LIBRARY_AUTH_RESTRICTED";
static NSString *const kErrorAuthDenied = @"E_PHOTO_LIBRARY_AUTH_DENIED";
static NSString *const kErrorNoPermissions = @"kErrorNoPermissions";
static NSString *const kErrorNoFileExtension = @"E_NO_FILE_EXTENSION";
static NSString *const kErrorUnsupportedAsset = @"E_UNSUPPORTED_ASSET";
static NSString *const kErrorNotValidUri = @"E_INVALID_URI";
static NSString *const kErrorSaveAssetFailed = @"E_ASSET_SAVE_FAILED";
static NSString *const kSaveAssetOk = @"kSaveAssetOk";
static NSString *const kAuthOk = @"kAuthOk";
//This app is missing NSPhotoLibraryAddUsageDescription. Add this entry to your bundle's Info.plist.
static NSString *const kAuthLimited = @"kAuthLimited";



static void requestPhotoLibraryAccess(PhotosAuthorizedBlock authorizedBlock) {
    PHAuthorizationStatus authStatus;
    if (@available(iOS 14, *)) {
        authStatus = [PHPhotoLibrary authorizationStatusForAccessLevel:PHAccessLevelReadWrite];
    } else {
        authStatus = [PHPhotoLibrary authorizationStatus];
    }
    if (authStatus == PHAuthorizationStatusRestricted) {
        authorizedBlock(kErrorAuthRestricted, nil);
    } else if (authStatus == PHAuthorizationStatusAuthorized) {
        authorizedBlock(nil, kAuthOk);
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wunguarded-availability-new"
    } else if (authStatus == PHAuthorizationStatusLimited) {
#pragma clang diagnostic pop
        authorizedBlock(nil, kAuthLimited);
    } else if (authStatus == PHAuthorizationStatusNotDetermined) {
        if (@available(iOS 14, *)) {
            [PHPhotoLibrary requestAuthorizationForAccessLevel:PHAccessLevelReadWrite handler:^(PHAuthorizationStatus status) {
                requestPhotoLibraryAccess(authorizedBlock);
            }];
        } else {
            [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
                requestPhotoLibraryAccess(authorizedBlock);
            }];
        }
    } else {
        authorizedBlock(kErrorAuthDenied, nil);
    }
}

+ (PHAssetMediaType)_assetTypeForUri:(nonnull NSString *)localUri {
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

+ (NSURL *)_normalizeAssetURLFromUri:(NSString *)uri {
  if ([uri hasPrefix:@"/"]) {
    return [NSURL URLWithString:[@"file://" stringByAppendingString:uri]];
  }
  return [NSURL URLWithString:uri];
}

-(void)saveToCameraRoll:(NSString *)localUri album:(NSString*)album callback:(PhotosAuthorizedBlock)callback {
    if ([[NSBundle mainBundle] objectForInfoDictionaryKey:@"NSPhotoLibraryAddUsageDescription"] == nil) {
        callback(kErrorNoPermissions, nil);
        return;
    }
    
    if ([[localUri pathExtension] length] == 0) {
        callback(kErrorNoFileExtension, nil);
        return;
    }
    
    PHAssetMediaType assetType = [self.class _assetTypeForUri:localUri];
    if (assetType == PHAssetMediaTypeUnknown || assetType == PHAssetMediaTypeAudio) {
        callback(kErrorUnsupportedAsset, nil);
        return;
    }
    
    NSURL *assetUrl = [self.class _normalizeAssetURLFromUri:localUri];
    if (assetUrl == nil) {
        callback(kErrorNotValidUri, nil);
        return;
    }


    __block PHAssetCollection *collection;
    __block PHObjectPlaceholder *assetPlaceholder;

    void (^saveBlock)(void) = ^void() {
        [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
            PHAssetChangeRequest *assetRequest ;
            
            PHAssetChangeRequest *changeRequest = assetType == PHAssetMediaTypeVideo
            ? [PHAssetChangeRequest creationRequestForAssetFromVideoAtFileURL:assetUrl]
            : [PHAssetChangeRequest creationRequestForAssetFromImageAtFileURL:assetUrl];
            
            assetPlaceholder = changeRequest.placeholderForCreatedAsset;
            
            if (collection != NULL) {
                
                PHFetchResult *photosAsset = [PHAsset fetchAssetsInAssetCollection:collection options:nil];
                PHAssetCollectionChangeRequest *albumChangeRequest = [PHAssetCollectionChangeRequest changeRequestForAssetCollection:collection assets:photosAsset];
                [albumChangeRequest addAssets:@[assetPlaceholder]];
            }
        } completionHandler:^(BOOL success, NSError *error) {
            if (success) {
                callback(nil, assetPlaceholder.localIdentifier);
            } else {
                callback(kErrorSaveAssetFailed, nil);
            }
        }];
    };
    
    void (^saveWithOptions)(void) = ^void() {
        if (album == NULL || [album isEqualToString:@""]) {
            return saveBlock();
        }
        
        PHFetchOptions *fetchOptions = [[PHFetchOptions alloc] init];
        fetchOptions.predicate = [NSPredicate predicateWithFormat:@"title = %@", album ];
        collection = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeAlbum
                                                              subtype:PHAssetCollectionSubtypeAny
                                                              options:fetchOptions].firstObject;
        // Create the album
        if (collection) return saveBlock();
        
        [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
            PHAssetCollectionChangeRequest *createAlbum = [PHAssetCollectionChangeRequest creationRequestForAssetCollectionWithTitle: album];
            assetPlaceholder = [createAlbum placeholderForCreatedAssetCollection];
        } completionHandler:^(BOOL success, NSError *error) {
            if (success) {
                PHFetchResult *collectionFetchResult = [PHAssetCollection fetchAssetCollectionsWithLocalIdentifiers:@[assetPlaceholder.localIdentifier] options:nil];
                collection = collectionFetchResult.firstObject;
                saveBlock();
            } else {
                callback(kErrorUnableToSave, nil);
            }
        }];
    };

    saveWithOptions();
}
@end
