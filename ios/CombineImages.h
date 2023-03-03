//
//  ImageFramework.h
//  ImageFramework
//
//  Created by Yuriy Danilchenko on 05.03.2020.
//  Copyright © 2020 Yuriy Danilchenko. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CombineImages : NSObject

+ (BOOL)combineImages:(NSArray<UIImage *> * _Nonnull)images
       resultSavePath:(NSString* _Nonnull) resultSavePath;

@end
