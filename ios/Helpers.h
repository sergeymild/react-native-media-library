//
//  Helpers.h
//  MediaLibrary
//
//  Created by Sergei Golishnikov on 03/03/2023.
//  Copyright © 2023 Facebook. All rights reserved.
//
#import <Foundation/Foundation.h>
#include <jsi/jsi.h>
#import <Photos/Photos.h>
#import <CoreServices/CoreServices.h>
#import <React/RCTBridgeModule.h>
#import "react_native_media_library-Swift.h"
#import "json.h"


using namespace facebook;

NS_ASSUME_NONNULL_BEGIN

@interface Helpers : NSObject

+(jsi::String) toJSIString:(NSString*)value runtime_:(jsi::Runtime*)runtime_;
+(const char*) toCString:(NSString *)value;
+(NSString*) toString:(jsi::String)value runtime_:(jsi::Runtime*)runtime_;
+(double) _exportDate:(NSDate *)date;
+(NSString*) _toSdUrl:(NSString *)localId;
+(NSString*) _assetIdFromLocalId:(NSString*)localId;
+(NSString*) _assetUriForLocalId:(NSString *)localId;
+(NSString *) _stringifyMediaType:(PHAssetMediaType)mediaType;
+(PHAssetMediaType) _assetTypeForUri:(NSString *)localUri;
+(NSURL*) _normalizeAssetURLFromUri:(NSString *)uri;
+(NSSortDescriptor*) _sortDescriptorFrom:(jsi::Runtime*)runtime_ sortBy:(jsi::Value)sortBy sortOrder:(jsi::Value)sortOrder;
@end

NS_ASSUME_NONNULL_END

