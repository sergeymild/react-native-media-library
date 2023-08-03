//
//  Helpers.m
//  MediaLibrary
//
//  Created by Sergei Golishnikov on 03/03/2023.
//  Copyright © 2023 Facebook. All rights reserved.
//

#import "Helpers.h"


using namespace facebook;




@implementation Helpers
NSString *const AssetMediaTypeAudio = @"audio";
NSString *const AssetMediaTypePhoto = @"photo";
NSString *const AssetMediaTypeVideo = @"video";
NSString *const AssetMediaTypeUnknown = @"unknown";
NSString *const AssetMediaTypeAll = @"all";

+(jsi::String) toJSIString:(NSString*)value runtime_:(jsi::Runtime*)runtime_ {
  return jsi::String::createFromUtf8(*runtime_, [value UTF8String] ?: "");
}

+(const char*) toCString:(NSString *)value {
    return [value cStringUsingEncoding:NSUTF8StringEncoding];
}

+(NSString*) toString:(jsi::String)value runtime_:(jsi::Runtime*)runtime_ {
    return [[NSString alloc] initWithCString:value.utf8(*runtime_).c_str() encoding:NSUTF8StringEncoding];
}


+(double) _exportDate:(NSDate *)date {
    if (!date) return 0.0;
    NSTimeInterval interval = date.timeIntervalSince1970;
    NSUInteger intervalMs = interval * 1000;
    return [[NSNumber numberWithUnsignedInteger:intervalMs] doubleValue];
}

+(NSString*) _assetIdFromLocalId:(NSString*)localId {
  // PHAsset's localIdentifier looks like `8B51C35E-E1F3-4D18-BF90-22CC905737E9/L0/001`
  // however `/L0/001` doesn't take part in URL to the asset, so we need to strip it out.
  return [localId stringByReplacingOccurrencesOfString:@"/.*" withString:@"" options:NSRegularExpressionSearch range:NSMakeRange(0, localId.length)];
}

+(NSString*) _assetUriForLocalId:(NSString *)localId {
  NSString *assetId = [Helpers _assetIdFromLocalId:localId];
  return [NSString stringWithFormat:@"ph://%@", assetId];
}


+(NSString*) _toSdUrl:(NSString *)localId {
    return [[NSURL URLWithString:[NSString stringWithFormat:@"ph://%@", localId]] absoluteString];
}


+(NSString *) _stringifyMediaType:(PHAssetMediaType)mediaType {
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


+(PHAssetMediaType) _assetTypeForUri:(NSString *)localUri {
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

+(NSURL*) _normalizeAssetURLFromUri:(NSString *)uri {
  if ([uri hasPrefix:@"/"]) {
    return [NSURL URLWithString:[@"file://" stringByAppendingString:uri]];
  }
  return [NSURL URLWithString:uri];
}

+(NSSortDescriptor*) _sortDescriptorFrom:(jsi::Runtime*)runtime_ sortBy:(jsi::Value)sortBy sortOrder:(jsi::Value)sortOrder {
    auto sortKey = [Helpers toString:sortBy.asString(*runtime_) runtime_:runtime_];;
    if ([sortKey isEqual: @"creationTime"] || [sortKey  isEqual: @"modificationTime"]) {
        bool ascending = false;
        if (!sortOrder.isUndefined() && sortOrder.asString(*runtime_).utf8(*runtime_) == "asc") {
            ascending = true;
        }
        return [NSSortDescriptor sortDescriptorWithKey:sortKey ascending:ascending];
    }
    return nil;
}


+(void) assetToJSON: (AssetData* _Nonnull)asset
               object:(json::object* _Nonnull)object {

    object->insert("filename", [Helpers toCString:asset.filename]);
    object->insert("id", [Helpers toCString:asset.id]);
    object->insert("creationTime", asset.creationTime);
    object->insert("modificationTime", asset.modificationTime);
    object->insert("mediaType", asset.mediaType);
    object->insert("duration", asset.duration);
    object->insert("width", asset.width);
    object->insert("height", asset.height);
    object->insert("uri", [Helpers toCString:asset.uri]);
    if (asset.url) {
        object->insert("url", [Helpers toCString:asset.url]);
    }
    object->insert("isSloMo", asset.isSloMo);
    if (asset.location != NULL) {
        json::object location;
        location.insert("longitude", asset.location.longitude);
        location.insert("latitude", asset.location.latitude);
        object->insert("location", location);
    }
}

@end



