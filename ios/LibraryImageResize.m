//
//  LibraryImageResize.m
//  MediaLibrary
//

#import "LibraryImageResize.h"
#import "LibraryImageSize.h"
#import <React/RCTImageUtils.h>

@implementation LibraryImageResize

+ (nullable NSString *)resizeWithUri:(NSString *)uri
                               width:(NSNumber *)width
                              height:(NSNumber *)height
                              format:(NSString *)format
                      resultSavePath:(NSString *)resultSavePath {
    UIImage *image = [LibraryImageSize imageWithPath:uri];
    if (!image) {
        return @"LibraryImageResize.image.notExists";
    }

    CGFloat imageWidth = image.size.width;
    CGFloat imageHeight = image.size.height;
    CGFloat imageRatio = imageWidth / imageHeight;
    CGSize targetSize = CGSizeZero;

    if ([width floatValue] >= 0) {
        targetSize.width = [width floatValue];
        targetSize.height = targetSize.width / imageRatio;
    }

    if ([height floatValue] >= 0) {
        targetSize.height = [height floatValue];
        if (targetSize.width <= 0) {
            targetSize.width = imageRatio * targetSize.height;
        }
    }

    UIGraphicsBeginImageContextWithOptions(targetSize, NO, 1.0);
    [image drawInRect:CGRectMake(0, 0, targetSize.width, targetSize.height)];
    UIImage *finalImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    if (!finalImage) {
        return @"LibraryImageResize.image.emptyContext";
    }

    return [LibraryImageSize saveImage:finalImage format:format path:resultSavePath];
}

+ (nullable NSString *)cropWithUri:(NSString *)uri
                                 x:(NSNumber *)x
                                 y:(NSNumber *)y
                             width:(NSNumber *)width
                            height:(NSNumber *)height
                            format:(NSString *)format
                    resultSavePath:(NSString *)resultSavePath {
    UIImage *image = [LibraryImageSize imageWithPath:uri];
    if (!image) {
        return @"LibraryImageResize.crop.notExists";
    }

    CGSize originalSize = image.size;
    CGFloat fX = [x floatValue] * originalSize.width;
    CGFloat fY = [y floatValue] * originalSize.height;
    CGFloat fWidth = [width floatValue];
    CGFloat fHeight = [height floatValue];

    if (fX + fWidth > image.size.width) {
        fX = image.size.width - fWidth;
    }

    if (fY + fHeight > image.size.height) {
        fY = image.size.height - fHeight;
    }

    CGSize targetSize = CGSizeMake(fWidth, fHeight);
    CGRect targetRect = CGRectMake(-fX, -fY, image.size.width, image.size.height);
    CGAffineTransform transform = RCTTransformFromTargetRect(image.size, targetRect);
    UIImage *finalImage = RCTTransformImage(image, targetSize, image.scale, transform);

    if (!finalImage) {
        return @"LibraryImageResize.crop.errorTransform";
    }

    return [LibraryImageSize saveImage:finalImage format:format path:resultSavePath];
}

@end
