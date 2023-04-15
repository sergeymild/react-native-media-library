//
//  ImageResize.m
//  MediaLibrary
//
//  Created by Sergei Golishnikov on 01/01/2023.
//  Copyright © 2023 Facebook. All rights reserved.
//

#import "ImageResize.h"
#import "ImageSize.h"
#import "RCTImageUtils.h"

@implementation ImageResize
+ (BOOL)resize:(NSString* _Nonnull)uri
              width:(NSNumber*)width
              height:(NSNumber*)height
              format:(NSString*)format
      resultSavePath:(NSString* _Nonnull) resultSavePath {
    
    UIImage *image = [ImageSize uiImage:uri];
    
    CGFloat imageWidth = image.size.width;
    CGFloat imageHeight = image.size.height;
    CGFloat imageRatio = imageWidth / imageHeight;
    CGSize targetSize = CGSizeZero;
    
    if (width.floatValue >= 0) {
        targetSize.width = (CGFloat)[width floatValue];
        targetSize.height = targetSize.width / imageRatio;
    }
    
    if (height.floatValue >= 0) {
        targetSize.height = (CGFloat)[height floatValue];
        targetSize.width = targetSize.width <= 0 ? imageRatio * targetSize.height : targetSize.width;
    }
    
    UIGraphicsBeginImageContextWithOptions(targetSize, false, 1.0);
    [image drawInRect:CGRectMake(0, 0, targetSize.width, targetSize.height)];
    UIImage *finalImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    if (finalImage == nil) {
        NSLog(@"empty context");
        return false;
    }
    
    return [ImageSize save:finalImage format:format path:resultSavePath];
}

+ (BOOL)crop:(NSString* _Nonnull)uri
           x:(NSNumber*)x
           y:(NSNumber*)y
       width:(NSNumber*)width
      height:(NSNumber*)height
      format:(NSString*)format
resultSavePath:(NSString* _Nonnull) resultSavePath {
    UIImage *image = [ImageSize uiImage:uri];
    CGSize originalSize = image.size;
    
    CGFloat fX = [x floatValue] * originalSize.width;
    CGFloat fY = [y floatValue] * originalSize.height;
    CGFloat fWidth = (CGFloat)[width floatValue];
    CGFloat fHeight = (CGFloat)[height floatValue];
    
    if (fX + fWidth > image.size.width) {
        fX = image.size.width - fWidth;
    }
    if (fY + fHeight > image.size.height) {
        fY = image.size.height - fHeight;
    }
    
    CGSize targetSize = CGSizeMake(fWidth, fHeight);
    CGRect targetRect = {-fX, -fY, image.size.width, image.size.height};
    CGAffineTransform transform = RCTTransformFromTargetRect(image.size, targetRect);
    UIImage *finalImage = RCTTransformImage(image, targetSize, image.scale, transform);
    return [ImageSize save:finalImage format:format path:resultSavePath];
}
@end
