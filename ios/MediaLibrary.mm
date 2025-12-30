#import "MediaLibrary.h"

#import <React/RCTBridge.h>
#import <React/RCTConvert.h>
#import <React/RCTLog.h>

#import <Photos/Photos.h>
#import <CoreServices/CoreServices.h>
#import "FetchVideoFrame.h"
#import "MediaAssetManager.h"
#import "Base64Downloader.h"
#import "LibraryImageSize.h"
#import "LibraryImageResize.h"
#import "LibraryCombineImages.h"
#import "LibrarySaveToCameraRoll.h"

@implementation MediaLibrary {
    dispatch_queue_t _queue;
}

RCT_EXPORT_MODULE()

- (instancetype)init {
    self = [super init];
    if (self) {
        _queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    }
    return self;
}

+ (NSString *)JSONString:(NSString *)aString {
    NSMutableString *s = [NSMutableString stringWithString:aString];
    [s replaceOccurrencesOfString:@"\\" withString:@"\\\\" options:NSCaseInsensitiveSearch range:NSMakeRange(0, [s length])];
    [s replaceOccurrencesOfString:@"\"" withString:@"\\\"" options:NSCaseInsensitiveSearch range:NSMakeRange(0, [s length])];
    [s replaceOccurrencesOfString:@"/" withString:@"\\/" options:NSCaseInsensitiveSearch range:NSMakeRange(0, [s length])];
    [s replaceOccurrencesOfString:@"\n" withString:@"\\n" options:NSCaseInsensitiveSearch range:NSMakeRange(0, [s length])];
    [s replaceOccurrencesOfString:@"\b" withString:@"\\b" options:NSCaseInsensitiveSearch range:NSMakeRange(0, [s length])];
    [s replaceOccurrencesOfString:@"\f" withString:@"\\f" options:NSCaseInsensitiveSearch range:NSMakeRange(0, [s length])];
    [s replaceOccurrencesOfString:@"\r" withString:@"\\r" options:NSCaseInsensitiveSearch range:NSMakeRange(0, [s length])];
    [s replaceOccurrencesOfString:@"\t" withString:@"\\t" options:NSCaseInsensitiveSearch range:NSMakeRange(0, [s length])];
    return [NSString stringWithString:s];
}

- (NSArray *)parseJsonToArray:(NSString *)json {
    if (!json || json.length == 0) {
        return @[];
    }
    NSData *data = [json dataUsingEncoding:NSUTF8StringEncoding];
    NSError *error;
    NSArray *array = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
    if (error) {
        return @[];
    }
    return array;
}

- (NSDictionary *)parseJsonToDictionary:(NSString *)json {
    if (!json || json.length == 0) {
        return nil;
    }
    NSData *data = [json dataUsingEncoding:NSUTF8StringEncoding];
    NSError *error;
    NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
    if (error) {
        return nil;
    }
    return dict;
}

#pragma mark - NativeMediaLibrarySpec

- (NSString *)cacheDir {
    NSString *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES).firstObject;
    return paths;
}

- (void)getAssets:(JS::NativeMediaLibrary::GetAssetsOptions &)options
          resolve:(RCTPromiseResolveBlock)resolve
           reject:(RCTPromiseRejectBlock)reject {
    int limit = -1;
    int offset = -1;
    NSString *sortBy = nil;
    NSString *collectionId = nil;
    NSString *sortOrder = nil;

    auto rawLimit = options.limit();
    auto rawOffset = options.offset();
    NSString *rawSortBy = options.sortBy();
    NSString *rawSortOrder = options.sortOrder();
    bool onlyFavorites = options.onlyFavorites();
    auto rawMediaTypes = options.mediaType();
    NSString *rawCollectionId = options.collectionId();

    if (rawLimit.has_value()) limit = (int)rawLimit.value();
    if (rawOffset.has_value()) offset = (int)rawOffset.value();
    if (rawSortBy) sortBy = rawSortBy;
    if (rawSortOrder) sortOrder = rawSortOrder;
    if (rawCollectionId) collectionId = rawCollectionId;

    NSMutableArray *mediaType = [[NSMutableArray alloc] init];
    for (NSString *type : rawMediaTypes) {
        [mediaType addObject:type];
    }

    [MediaAssetManager fetchAssetsWithLimit:limit
                                     offset:offset
                                     sortBy:sortBy
                                  sortOrder:sortOrder
                                  mediaType:mediaType
                               collectionId:collectionId
                                 completion:^(NSString * _Nonnull json) {
        NSArray *result = [self parseJsonToArray:json];
        resolve(result);
    }];
}

- (void)getFromDisk:(JS::NativeMediaLibrary::GetFromDiskOptions &)options
            resolve:(RCTPromiseResolveBlock)resolve
             reject:(RCTPromiseRejectBlock)reject {
    NSString *rawPath = options.path();
    NSString *rawExtensions = options.extensions();

    NSSet *extensionsSet = nil;
    if (rawExtensions && rawExtensions.length > 0) {
        NSArray *extArray = [[rawExtensions lowercaseString] componentsSeparatedByString:@","];
        extensionsSet = [NSSet setWithArray:extArray];
    }

    dispatch_async(_queue, ^{
        NSFileManager *fileManager = [NSFileManager defaultManager];
        NSError *error;
        NSArray<NSString *> *contents = [fileManager contentsOfDirectoryAtPath:rawPath error:&error];

        if (error) {
            resolve(@[]);
            return;
        }

        NSMutableArray *entries = [NSMutableArray arrayWithCapacity:contents.count];

        for (NSString *filename in contents) {
            // Skip hidden files
            if ([filename hasPrefix:@"."]) continue;

            NSString *fullPath = [rawPath stringByAppendingPathComponent:filename];
            NSDictionary *attrs = [fileManager attributesOfItemAtPath:fullPath error:nil];
            if (!attrs) continue;

            BOOL isDirectory = [attrs[NSFileType] isEqualToString:NSFileTypeDirectory];

            // Filter by extension if provided
            if (extensionsSet && !isDirectory) {
                NSString *ext = [[filename pathExtension] lowercaseString];
                if (![extensionsSet containsObject:ext]) continue;
            }

            NSDate *modDate = attrs[NSFileModificationDate];
            NSNumber *fileSize = attrs[NSFileSize];

            NSDictionary *entry = @{
                @"filename": filename,
                @"uri": fullPath,
                @"isDirectory": @(isDirectory),
                @"size": fileSize ?: @0,
                @"creationTime": @([modDate timeIntervalSince1970] * 1000.0)
            };

            [entries addObject:entry];
        }

        // Sort by modification time descending
        [entries sortUsingComparator:^NSComparisonResult(NSDictionary *a, NSDictionary *b) {
            // Directories first
            BOOL aIsDir = [a[@"isDirectory"] boolValue];
            BOOL bIsDir = [b[@"isDirectory"] boolValue];
            if (aIsDir && !bIsDir) return NSOrderedAscending;
            if (!aIsDir && bIsDir) return NSOrderedDescending;

            // Then by modification time descending
            NSNumber *aTime = a[@"creationTime"];
            NSNumber *bTime = b[@"creationTime"];
            return [bTime compare:aTime];
        }];

        resolve(entries);
    });
}

- (void)getCollections:(RCTPromiseResolveBlock)resolve
                reject:(RCTPromiseRejectBlock)reject {
    [MediaAssetManager fetchCollectionsWithCompletion:^(NSString * _Nonnull json) {
        NSArray *result = [self parseJsonToArray:json];
        resolve(result);
    }];
}

- (void)getAsset:(NSString *)identifier
         resolve:(RCTPromiseResolveBlock)resolve
          reject:(RCTPromiseRejectBlock)reject {
    [MediaAssetManager fetchAssetWithIdentifier:identifier completion:^(NSString * _Nullable json) {
        if (!json || json.length == 0) {
            resolve([NSNull null]);
            return;
        }
        NSDictionary *result = [self parseJsonToDictionary:json];
        resolve(result);
    }];
}

- (void)exportVideo:(JS::NativeMediaLibrary::ExportVideoParams &)params
            resolve:(RCTPromiseResolveBlock)resolve
             reject:(RCTPromiseRejectBlock)reject {
    NSString *identifier = params.identifier();
    NSString *resultPath = params.resultSavePath();

    [MediaAssetManager exportVideoWithIdentifier:identifier resultSavePath:resultPath completion:^(BOOL success) {
        resolve(@{@"result": @(success)});
    }];
}

- (void)saveToLibrary:(JS::NativeMediaLibrary::SaveToLibraryParams &)params
              resolve:(RCTPromiseResolveBlock)resolve
               reject:(RCTPromiseRejectBlock)reject {
    NSString *localUri = params.localUrl();
    NSString *album = params.album() ?: @"";

    [LibrarySaveToCameraRoll saveToCameraRollWithLocalUri:localUri
                                                    album:album
                                                 callback:^(NSString * _Nullable error, NSString * _Nullable json) {
        if (error) {
            RCTLogWarn(@"MediaLibrary.saveToLibrary error: %@", error);
            resolve(@{@"error": [MediaLibrary JSONString:error]});
        } else {
            NSDictionary *result = [self parseJsonToDictionary:json];
            resolve(result ?: @{});
        }
    }];
}

- (void)fetchVideoFrame:(JS::NativeMediaLibrary::FetchVideoFrameParams &)params
                resolve:(RCTPromiseResolveBlock)resolve
                 reject:(RCTPromiseRejectBlock)reject {
    NSString *url = params.url();
    double time = params.time();
    double quality = params.quality();

    dispatch_async(_queue, ^{
        NSString *resultString = [FetchVideoFrame fetchVideoFrame:url time:time quality:quality];

        if (!resultString) {
            resolve([NSNull null]);
            return;
        }

        NSDictionary *result = [self parseJsonToDictionary:resultString];
        resolve(result);
    });
}

- (void)combineImages:(JS::NativeMediaLibrary::CombineImagesParams &)params
              resolve:(RCTPromiseResolveBlock)resolve
               reject:(RCTPromiseRejectBlock)reject {
    auto imagesArray = params.images();
    NSString *resultSavePath = params.resultSavePath();
    NSInteger mainImageIndex = (NSInteger)params.mainImageIndex();
    auto backgroundColorOpt = params.backgroundColor();
    UIColor *backgroundColor = backgroundColorOpt.has_value()
        ? [RCTConvert UIColor:@(backgroundColorOpt.value())]
        : [UIColor clearColor];

    dispatch_async(_queue, ^{
        NSMutableArray *processedImages = [[NSMutableArray alloc] initWithCapacity:imagesArray.size()];

        for (const auto &obj : imagesArray) {
            NSString *path = obj.image();
            NSDictionary *positions = @{};
            auto positionsOpt = obj.positions();
            if (positionsOpt.has_value()) {
                positions = @{
                    @"x": @(positionsOpt.value().x()),
                    @"y": @(positionsOpt.value().y())
                };
            }
            UIImage *image = [LibraryImageSize imageWithPath:path];
            if (image) {
                [processedImages addObject:@{@"image": image, @"positions": positions}];
            }
        }

        NSString *error = [LibraryCombineImages combineImagesWithImages:processedImages
                                                         resultSavePath:resultSavePath
                                                         mainImageIndex:mainImageIndex
                                                        backgroundColor:backgroundColor];

        if (error) {
            RCTLogWarn(@"MediaLibrary.combineImages error: %@", error);
        }

        resolve(@{@"result": @(error == nil)});
    });
}

- (void)imageResize:(JS::NativeMediaLibrary::ImageResizeParams &)params
            resolve:(RCTPromiseResolveBlock)resolve
             reject:(RCTPromiseRejectBlock)reject {
    NSString *uri = params.uri();
    NSNumber *width = @(params.width());
    NSNumber *height = @(params.height());
    NSString *format = params.format();
    NSString *resultSavePath = params.resultSavePath();

    dispatch_async(_queue, ^{
        NSString *error = [LibraryImageResize resizeWithUri:uri
                                                      width:width
                                                     height:height
                                                     format:format
                                             resultSavePath:resultSavePath];

        if (error) {
            RCTLogWarn(@"MediaLibrary.imageResize error: %@", error);
        }

        resolve(@{@"result": @(error == nil)});
    });
}

- (void)imageCrop:(JS::NativeMediaLibrary::ImageCropParams &)params
          resolve:(RCTPromiseResolveBlock)resolve
           reject:(RCTPromiseRejectBlock)reject {
    NSString *uri = params.uri();
    NSNumber *x = @(params.x());
    NSNumber *y = @(params.y());
    NSNumber *width = @(params.width());
    NSNumber *height = @(params.height());
    NSString *format = params.format();
    NSString *resultSavePath = params.resultSavePath();

    dispatch_async(_queue, ^{
        NSString *error = [LibraryImageResize cropWithUri:uri
                                                        x:x
                                                        y:y
                                                    width:width
                                                   height:height
                                                   format:format
                                           resultSavePath:resultSavePath];

        if (error) {
            RCTLogWarn(@"MediaLibrary.imageCrop error: %@", error);
        }

        resolve(@{@"result": @(error == nil)});
    });
}

- (void)imageSizes:(JS::NativeMediaLibrary::ImageSizesParams &)params
           resolve:(RCTPromiseResolveBlock)resolve
            reject:(RCTPromiseRejectBlock)reject {
    auto imagesVec = params.images();
    NSMutableArray *images = [[NSMutableArray alloc] initWithCapacity:imagesVec.size()];
    for (NSString *img : imagesVec) {
        [images addObject:img];
    }

    [LibraryImageSize getSizesWithPaths:images completion:^(NSString * _Nonnull result) {
        NSArray *parsed = [self parseJsonToArray:result];
        resolve(parsed);
    }];
}

- (void)downloadAsBase64:(JS::NativeMediaLibrary::DownloadAsBase64Params &)params
                 resolve:(RCTPromiseResolveBlock)resolve
                  reject:(RCTPromiseRejectBlock)reject {
    NSString *url = params.url();

    dispatch_async(_queue, ^{
        [Base64Downloader downloadWithUrl:url completion:^(NSString * _Nullable result) {
            if (!result) {
                resolve([NSNull null]);
                return;
            }
            NSDictionary *parsed = [self parseJsonToDictionary:result];
            resolve(parsed);
        }];
    });
}

- (std::shared_ptr<facebook::react::TurboModule>)getTurboModule:
    (const facebook::react::ObjCTurboModule::InitParams &)params
{
    return std::make_shared<facebook::react::NativeMediaLibrarySpecJSI>(params);
}

@end