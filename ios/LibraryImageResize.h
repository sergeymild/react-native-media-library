//
//  LibraryImageResize.h
//  MediaLibrary
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface LibraryImageResize : NSObject

+ (nullable NSString *)resizeWithUri:(NSString *)uri
                               width:(NSNumber *)width
                              height:(NSNumber *)height
                              format:(NSString *)format
                      resultSavePath:(NSString *)resultSavePath;

+ (nullable NSString *)cropWithUri:(NSString *)uri
                                 x:(NSNumber *)x
                                 y:(NSNumber *)y
                             width:(NSNumber *)width
                            height:(NSNumber *)height
                            format:(NSString *)format
                    resultSavePath:(NSString *)resultSavePath;

@end

NS_ASSUME_NONNULL_END
