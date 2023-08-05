//
//  ImageResize.m
//  MediaLibrary
//
//  Created by Sergei Golishnikov on 01/01/2023.
//  Copyright © 2023 Facebook. All rights reserved.
//

#import "ImageResize.h"
#import "RCTImageUtils.h"

@implementation ImageResize

+ (NSString*)crop:(NSString* _Nonnull)uri
           x:(NSNumber*)x
           y:(NSNumber*)y
       width:(NSNumber*)width
      height:(NSNumber*)height
      format:(NSString*)format
resultSavePath:(NSString* _Nonnull) resultSavePath {
    UIImage *image = [LibraryImageSize imageWithPath:uri];
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
    return [LibraryImageSize saveWithImage:finalImage format:format path:resultSavePath];
}
@end
