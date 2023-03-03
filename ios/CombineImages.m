//
//  ImageFramework.m
//  ImageFramework
//
//  Created by Yuriy Danilchenko on 05.03.2020.
//  Copyright © 2020 Yuriy Danilchenko. All rights reserved.
//

#import "CombineImages.h"
#import "ImageSize.h"

@implementation CombineImages

+ (BOOL)combineImages:(NSArray<UIImage *> * _Nonnull)images
       resultSavePath:(NSString* _Nonnull) resultSavePath {
    
    UIImage *firstImage = [images firstObject];
    float parentCenterX = firstImage.size.width / 2;
    float parentCenterY = firstImage.size.height / 2;
    CGSize newImageSize = CGSizeMake(firstImage.size.width, firstImage.size.height);
    
    UIGraphicsBeginImageContextWithOptions(newImageSize, false, [UIScreen mainScreen].scale);
    
    for (UIImage *image in images) {
        float x = parentCenterX - (image.size.width / 2);
        float y = parentCenterY - (image.size.height / 2);
        [image drawAtPoint:CGPointMake(x, y)];
    }
    
    UIImage *finalImage = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    
    if (finalImage == nil) {
        NSLog(@"empty context");
        return false;
    }
    
    return [ImageSize save:finalImage format:@"png" path:resultSavePath];
}

@end
