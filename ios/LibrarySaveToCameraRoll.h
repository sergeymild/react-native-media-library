//
//  LibrarySaveToCameraRoll.h
//  MediaLibrary
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface LibrarySaveToCameraRoll : NSObject

+ (void)saveToCameraRollWithLocalUri:(NSString *)localUri
                               album:(NSString *)album
                            callback:(void (^)(NSString * _Nullable error, NSString * _Nullable result))callback;

@end

NS_ASSUME_NONNULL_END
