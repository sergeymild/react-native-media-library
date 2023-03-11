//
//  NSObject+AssetsManager.h
//  MediaLibrary
//
//  Created by Sergei Golishnikov on 03/03/2023.
//  Copyright © 2023 Facebook. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Photos/Photos.h>
#import "json.h"

typedef void (^FetchAssetBlock)(json::object);

@interface AssetsManager: NSObject
+ (id _Nonnull )sharedManager;

-(void) fetchCollections:(json::array* _Nonnull)results;

-(void) fetchAssets:(json::array* _Nonnull)results
              limit:(int)limit
             sortBy:(NSString* _Nullable)sortBy
          sortOrder:(NSString* _Nullable)sortOrder
          mediaType:(NSArray* _Nonnull)mediaType
         collection:(NSString* _Nullable)collectionId;


-(void) pHAssetToJSON: (PHAsset* _Nonnull)asset
               object:(json::object* _Nonnull)object;

-(NSString* _Nonnull)fetchAssetUrl :(PHAsset* _Nonnull)asset;

-(void) fetchAsset:(NSString* _Nonnull)identifier
                         object:(json::object* _Nonnull)object;

-(PHAsset* _Nonnull) fetchRawAsset:(NSString* _Nonnull)identifier;
@end
