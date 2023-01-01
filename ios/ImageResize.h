//
//  ImageResize.h
//  MediaLibrary
//
//  Created by Sergei Golishnikov on 01/01/2023.
//  Copyright © 2023 Facebook. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ImageResize : NSObject
+ (BOOL)resize:(NSString* _Nonnull)uri
              width:(NSNumber*)width
              height:(NSNumber*)height
              format:(NSString*)format
      resultSavePath:(NSString* _Nonnull) resultSavePath;
@end

NS_ASSUME_NONNULL_END
