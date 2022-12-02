//
//  FetchVideoFrame.m
//  MediaLibrary
//
//  Created by Sergei Golishnikov on 01/12/2022.
//  Copyright © 2022 Facebook. All rights reserved.
//

#import "FetchVideoFrame.h"

#import <AVFoundation/AVFoundation.h>
#import <AVFoundation/AVAsset.h>

@implementation FetchVideoFrame

+ (BOOL)ensureDirExistsWithPath:(NSString *)path
{
  BOOL isDir = NO;
  NSError *error;
  BOOL exists = [[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&isDir];
  if (!(exists && isDir)) {
    [[NSFileManager defaultManager] createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:&error];
    if (error) {
      return NO;
    }
  }
  return YES;
}

+(NSString*)createVideoThumbnailsFolder {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString *cacheDirectory = [paths objectAtIndex:0];
    auto path = [[NSURL URLWithString:cacheDirectory] URLByAppendingPathComponent:@"VideoThumbnails"];
    [self ensureDirExistsWithPath:path.absoluteString];
    return path.absoluteString;
}


+(nullable NSString*)fetchVideoFrame:(NSString*)url time:(double)time quality:(double)quality {
    NSLog(@"fetchVideoFrame: time: %f, quality: %f url: %@", time, quality, url);
    NSString *p = [url stringByReplacingOccurrencesOfString:@"file://" withString:@""];
    NSURL *nsUrl = [NSURL URLWithString:url];
    if (![[NSFileManager defaultManager] fileExistsAtPath:p]) {
        return NULL;
    }
    
    auto asset = [[AVURLAsset alloc] initWithURL:nsUrl options:nil];
    auto generator = [[AVAssetImageGenerator alloc] initWithAsset:asset];
    generator.appliesPreferredTrackTransform = YES;
    generator.requestedTimeToleranceBefore = kCMTimeZero;
    generator.requestedTimeToleranceAfter = kCMTimeZero;
    
    NSError *err = NULL;
    CMTime cmTime = CMTimeMake(time * 1000, 1000);
    CGImageRef imgRef = [generator copyCGImageAtTime:cmTime actualTime:NULL error:&err];
    if (err) {
        NSLog(@"error: %@", err.localizedFailureReason);
        return NULL;
    }
    
    UIImage *thumbnail = [UIImage imageWithCGImage:imgRef];
    
    
    NSString *fileName = [[[NSUUID UUID] UUIDString] stringByAppendingString:@".jpg"];
    NSString *newPath = [[self createVideoThumbnailsFolder] stringByAppendingPathComponent:fileName];
    NSLog(@"writeTo: %@", newPath);
    NSData *data = UIImageJPEGRepresentation(thumbnail, quality);
    
    if (![data writeToFile:newPath atomically:YES]) {
        NSLog(@"error:Can't write to file");
        return NULL;
    }
    
    NSURL *fileURL = [NSURL fileURLWithPath:newPath];
    NSString *filePath = [fileURL absoluteString];

    CGImageRelease(imgRef);
    json::object response;
    
    response.insert("url", [filePath cStringUsingEncoding:NSUTF8StringEncoding]);
    response.insert("width", (double)thumbnail.size.width);
    response.insert("width", (double)thumbnail.size.height);
    
    return [[NSString alloc] initWithCString:json::stringify(response).c_str() encoding:NSUTF8StringEncoding];
    
}
@end
