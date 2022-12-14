//
//  ImageSize.h
//  MediaLibrary
//
//  Created by Sergei Golishnikov on 14/12/2022.
//  Copyright © 2022 Facebook. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ImageSize : NSObject
+ (UIImage *)uiImage:(NSString*)json;
@end

NS_ASSUME_NONNULL_END
