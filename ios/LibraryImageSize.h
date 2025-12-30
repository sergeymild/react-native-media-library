//
//  LibraryImageSize.h
//  MediaLibrary
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

NSURL *toFilePath(NSString *path);
void ensurePath(NSString *path);

@interface LibraryImageSize : NSObject

+ (nullable UIImage *)imageWithPath:(NSString *)path;
+ (void)getSizesWithPaths:(NSArray<NSString *> *)paths
               completion:(void (^)(NSString *result))completion;
+ (nullable NSString *)saveImage:(UIImage *)image
                          format:(NSString *)format
                            path:(NSString *)path;

@end

NS_ASSUME_NONNULL_END
