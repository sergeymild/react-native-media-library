//
//  SaveToCameraRoll.h
//  MediaLibrary
//
//  Created by Sergei Golishnikov on 20/11/2022.
//  Copyright © 2022 Facebook. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN


typedef void (^PhotosAuthorizedBlock)( NSString* _Nullable  error, NSString* _Nullable success);

typedef void (^LibCallback)(NSString* _Nullable  error, NSString* _Nullable success);

@interface SaveToCameraRoll : NSObject
-(void)saveToCameraRoll:(NSString *)localUri
                  album:(NSString* _Nullable)album
               callback:(PhotosAuthorizedBlock)callback;
@end

NS_ASSUME_NONNULL_END
