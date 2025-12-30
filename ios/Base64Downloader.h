//
//  Base64Downloader.h
//  MediaLibrary
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface Base64Downloader : NSObject

+ (void)downloadWithUrl:(NSString *)url
             completion:(void (^)(NSString * _Nullable result))completion;

@end

NS_ASSUME_NONNULL_END
