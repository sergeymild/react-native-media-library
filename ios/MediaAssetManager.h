//
//  MediaAssetManager.h
//  MediaLibrary
//

#import <Foundation/Foundation.h>
#import <Photos/Photos.h>

NS_ASSUME_NONNULL_BEGIN

@interface MediaAssetManager : NSObject

+ (nullable PHAsset *)fetchRawAssetWithIdentifier:(NSString *)identifier;

+ (void)fetchAssetWithIdentifier:(NSString *)identifier
                      completion:(void (^)(NSString * _Nullable json))completion;

+ (void)fetchAssetsWithLimit:(int)limit
                      offset:(int)offset
                      sortBy:(NSString * _Nullable)sortBy
                   sortOrder:(NSString * _Nullable)sortOrder
                   mediaType:(NSArray<NSString *> *)mediaType
                collectionId:(NSString * _Nullable)collectionId
                  completion:(void (^)(NSString *json))completion;

+ (void)fetchCollectionsWithCompletion:(void (^)(NSString *json))completion;

+ (void)exportVideoWithIdentifier:(NSString *)identifier
                   resultSavePath:(NSString *)resultSavePath
                       completion:(void (^)(BOOL success))completion;

@end

NS_ASSUME_NONNULL_END
