//
//  ImageResize.h
//  MediaLibrary
//
//  Created by Sergei Golishnikov on 01/01/2023.
//  Copyright © 2023 Facebook. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "react_native_media_library-Swift.h"

NS_ASSUME_NONNULL_BEGIN

@interface ImageResize : NSObject

+ (NSString*)crop:(NSString* _Nonnull)uri
           x:(NSNumber*)x
           y:(NSNumber*)y
       width:(NSNumber*)width
      height:(NSNumber*)height
      format:(NSString*)format
resultSavePath:(NSString* _Nonnull) resultSavePath;
@end

NS_ASSUME_NONNULL_END
