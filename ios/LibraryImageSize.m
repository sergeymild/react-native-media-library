//
//  LibraryImageSize.m
//  MediaLibrary
//

#import "LibraryImageSize.h"
#import "MediaAssetManager.h"
#import <React/RCTConvert.h>
#import <React/RCTImageSource.h>
#import <React/RCTImageUtils.h>

NSURL *toFilePath(NSString *path) {
    if ([path hasPrefix:@"file://"]) {
        return [NSURL URLWithString:path];
    }
    return [NSURL URLWithString:[NSString stringWithFormat:@"file://%@", path]];
}

void ensurePath(NSString *path) {
    NSString *folderPath = [path stringByDeletingLastPathComponent];
    NSFileManager *fm = [NSFileManager defaultManager];
    [fm createDirectoryAtPath:folderPath withIntermediateDirectories:YES attributes:nil error:nil];
    if ([fm fileExistsAtPath:path]) {
        [fm removeItemAtPath:path error:nil];
    }
}

@implementation LibraryImageSize

+ (RCTImageSource *)imageSourceWithPath:(NSString *)path {
    return [[RCTImageSource alloc] initWithURLRequest:[RCTConvert NSURLRequest:path]
                                                 size:CGSizeZero
                                                scale:1.0];
}

+ (nullable UIImage *)imageWithPath:(NSString *)path {
    RCTImageSource *source = [self imageSourceWithPath:path];
    if (!source || !source.request.URL || !source.request.URL.scheme) {
        return nil;
    }

    NSString *scheme = [source.request.URL.scheme lowercaseString];
    UIImage *image = nil;

    if ([scheme isEqualToString:@"file"]) {
        image = RCTImageFromLocalAssetURL(source.request.URL);
        if (!image) {
            image = RCTImageFromLocalBundleAssetURL(source.request.URL);
        }
    } else if ([scheme isEqualToString:@"data"] || [scheme hasPrefix:@"http"]) {
        NSData *data = [NSData dataWithContentsOfURL:source.request.URL];
        if (!data) return nil;
        return [UIImage imageWithData:data];
    }

    CGFloat scale = source.scale;
    if (scale == 1.0 && source.size.width > 0 && image) {
        scale = (CGFloat)CGImageGetWidth(image.CGImage) / source.size.width;
    }

    if (scale > 1.0 && image && image.CGImage) {
        image = [UIImage imageWithCGImage:image.CGImage
                                    scale:scale
                              orientation:image.imageOrientation];
    }

    return image;
}

+ (void)getSizesWithPaths:(NSArray<NSString *> *)paths
               completion:(void (^)(NSString *result))completion {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSMutableArray *sizes = [NSMutableArray array];

        for (NSString *path in paths) {
            if ([path hasPrefix:@"ph://"]) {
                PHAsset *asset = [MediaAssetManager fetchRawAssetWithIdentifier:path];
                if (asset) {
                    [sizes addObject:@{
                        @"width": @((double)asset.pixelWidth),
                        @"height": @((double)asset.pixelHeight)
                    }];
                }
                continue;
            }

            UIImage *image = [self imageWithPath:path];
            if (!image) continue;

            [sizes addObject:@{
                @"width": @(image.size.width),
                @"height": @(image.size.height)
            }];
        }

        NSError *error;
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:sizes options:0 error:&error];
        NSString *result = error ? @"[]" : [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
        completion(result ?: @"[]");
    });
}

+ (nullable NSString *)saveImage:(UIImage *)image
                          format:(NSString *)format
                            path:(NSString *)path {
    ensurePath(path);

    NSURL *finalPath = toFilePath(path);
    NSData *data;

    if ([format isEqualToString:@"png"]) {
        data = UIImagePNGRepresentation(image);
        if (!data) return @"LibraryImageSize.failConvertToPNG";
    } else {
        data = UIImageJPEGRepresentation(image, 1.0);
        if (!data) return @"LibraryImageSize.failConvertToJPG";
    }

    NSError *error;
    BOOL success = [data writeToURL:finalPath options:NSDataWritingAtomic error:&error];
    if (!success || error) {
        return [NSString stringWithFormat:@"LibraryImageSize.catch.error: %@", error.localizedDescription];
    }

    return nil;
}

@end
