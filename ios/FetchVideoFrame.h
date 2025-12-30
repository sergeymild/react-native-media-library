//
//  FetchVideoFrame.h
//  MediaLibrary
//
//  Created by Sergei Golishnikov on 01/12/2022.
//  Copyright © 2022 Facebook. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface FetchVideoFrame : NSObject
+(nullable NSString*)fetchVideoFrame:(NSString*)url time:(double)time quality:(double)quality;
@end

NS_ASSUME_NONNULL_END
