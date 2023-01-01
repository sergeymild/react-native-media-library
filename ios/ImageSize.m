//
//  ImageSize.m
//  MediaLibrary
//
//  Created by Sergei Golishnikov on 14/12/2022.
//  Copyright © 2022 Facebook. All rights reserved.
//

#import <React/RCTConvert.h>
#import <React/RCTImageSource.h>
#import "ImageSize.h"

@implementation ImageSize

+ (RCTImageSource *)RCTImageSource:(id)json
{
  if (!json) {
    return nil;
  }

  NSURLRequest *request;
  CGSize size = CGSizeZero;
  CGFloat scale = 1.0;
  if ([json isKindOfClass:[NSDictionary class]]) {
    if (!(request = [RCTConvert NSURLRequest:json])) {
      return nil;
    }
    size = [RCTConvert CGSize:json];
    scale = [RCTConvert CGFloat:json[@"scale"]] ?: [RCTConvert BOOL:json[@"deprecated"]] ? 0.0 : 1.0;
  } else if ([json isKindOfClass:[NSString class]]) {
    request = [RCTConvert NSURLRequest:json];
  } else {
    RCTLogConvertError(json, @"an image. Did you forget to call resolveAssetSource() on the JS side?");
    return nil;
  }

  return [[RCTImageSource alloc] initWithURLRequest:request size:size scale:scale];
}

+ (UIImage *)uiImage:(NSString*)json
{
    RCTImageSource *imageSource = [self RCTImageSource:json];
    if (!imageSource) {
      return nil;
    }
    
    __block UIImage *image;
    
  NSURL *URL = imageSource.request.URL;
  NSString *scheme = URL.scheme.lowercaseString;
  if ([scheme isEqualToString:@"file"]) {
    image = RCTImageFromLocalAssetURL(URL);
    // There is a case where this may fail when the image is at the bundle location.
    // RCTImageFromLocalAssetURL only checks for the image in the same location as the jsbundle
    // Hence, if the bundle is CodePush-ed, it will not be able to find the image.
    // This check is added here instead of being inside RCTImageFromLocalAssetURL, since
    // we don't want breaking changes to RCTImageFromLocalAssetURL, which is called in a lot of places
    // This is a deprecated method, and hence has the least impact on existing code. Basically,
    // instead of crashing the app, it tries one more location for the image.
    if (!image) {
      image = RCTImageFromLocalBundleAssetURL(URL);
    }
    if (!image) {
      RCTLogConvertError(json, @"an image. File not found.");
    }
  } else if ([scheme isEqualToString:@"data"]) {
    image = [UIImage imageWithData:[NSData dataWithContentsOfURL:URL]];
  } else if ([scheme hasPrefix:@"http"]) {
    image = [UIImage imageWithData:[NSData dataWithContentsOfURL:URL]];
  } else {
    RCTLogConvertError(json, @"an image. Only local files or data URIs are supported.");
    return nil;
  }

  CGFloat scale = imageSource.scale;
  if (!scale && imageSource.size.width) {
    // If no scale provided, set scale to image width / source width
    scale = CGImageGetWidth(image.CGImage) / imageSource.size.width;
  }

  if (scale) {
    image = [UIImage imageWithCGImage:image.CGImage scale:scale orientation:image.imageOrientation];
  }

  if (!CGSizeEqualToSize(imageSource.size, CGSizeZero) && !CGSizeEqualToSize(imageSource.size, image.size)) {
    RCTLogError(
        @"Image source %@ size %@ does not match loaded image size %@.",
        URL.path.lastPathComponent,
        NSStringFromCGSize(imageSource.size),
        NSStringFromCGSize(image.size));
  }

  return image;
}


+ (BOOL)save:(UIImage*)image format:(NSString*)format path:(NSString*)path {
    NSString *folderPath = [path stringByDeletingLastPathComponent];
    NSError * error = nil;
    [[NSFileManager defaultManager] createDirectoryAtPath:folderPath
                              withIntermediateDirectories:YES
                                               attributes:nil
                                                    error:&error];
    if (error != NULL) {
        NSLog(@"Error %@", error.description);
        return false;
    }
    if ([[NSFileManager defaultManager] fileExistsAtPath:path]) {
        [[NSFileManager defaultManager] removeItemAtPath:path error:nil];
    }
    
    if ([format isEqualToString: @"png"]) {
        return [UIImagePNGRepresentation(image) writeToFile:path atomically:true];
    }

    return [UIImageJPEGRepresentation(image, 1.0) writeToFile:path atomically:true];
}
@end
