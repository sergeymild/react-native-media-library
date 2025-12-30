//
//  LibraryCombineImages.m
//  MediaLibrary
//

#import "LibraryCombineImages.h"
#import "LibraryImageSize.h"

@implementation LibraryCombineImages

+ (nullable NSString *)combineImagesWithImages:(NSArray<NSDictionary *> *)images
                                resultSavePath:(NSString *)resultSavePath
                                mainImageIndex:(NSInteger)mainImageIndex
                               backgroundColor:(UIColor *)backgroundColor {
    if (images.count == 0) {
        return @"LibraryCombineImages.combineImages.emptyArray";
    }

    NSDictionary *mainJson = images[mainImageIndex];
    UIImage *mainImage = mainJson[@"image"];
    CGFloat parentCenterX = mainImage.size.width / 2;
    CGFloat parentCenterY = mainImage.size.height / 2;
    CGSize newImageSize = CGSizeMake(mainImage.size.width, mainImage.size.height);

    UIGraphicsBeginImageContextWithOptions(newImageSize, NO, 1.0);
    [backgroundColor setFill];
    CGContextFillRect(UIGraphicsGetCurrentContext(), CGRectMake(0, 0, newImageSize.width, newImageSize.height));

    for (NSInteger index = 0; index < images.count; index++) {
        NSDictionary *json = images[index];
        UIImage *image = json[@"image"];
        CGFloat x = parentCenterX - image.size.width / 2;
        CGFloat y = parentCenterY - image.size.height / 2;

        NSDictionary *positions = json[@"positions"];
        if (positions && [positions isKindOfClass:[NSDictionary class]]) {
            NSNumber *pX = positions[@"x"];
            NSNumber *pY = positions[@"y"];
            if (pX && pY) {
                x = [pX doubleValue];
                y = [pY doubleValue];

                if (x > mainImage.size.width) {
                    x = mainImage.size.width - image.size.width;
                }
                if (y > mainImage.size.height) {
                    y = mainImage.size.height - image.size.height;
                }
                if (x < 0) x = 0;
                if (y <= 0) y = 0;
            }
        }

        [image drawAtPoint:CGPointMake(x, y)];
    }

    UIImage *finalImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    if (!finalImage) {
        return @"CombineImages.combineImages.emptyContext";
    }

    return [LibraryImageSize saveImage:finalImage format:@"png" path:resultSavePath];
}

@end
