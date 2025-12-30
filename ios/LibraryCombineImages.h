//
//  LibraryCombineImages.h
//  MediaLibrary
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface LibraryCombineImages : NSObject

+ (nullable NSString *)combineImagesWithImages:(NSArray<NSDictionary *> *)images
                                resultSavePath:(NSString *)resultSavePath
                                mainImageIndex:(NSInteger)mainImageIndex
                               backgroundColor:(UIColor *)backgroundColor;

@end

NS_ASSUME_NONNULL_END
