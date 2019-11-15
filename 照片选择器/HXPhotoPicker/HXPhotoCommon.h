//
//  HXPhotoCommon.h
//  照片选择器
//
//  Created by 洪欣 on 2019/1/8.
//  Copyright © 2019年 洪欣. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HXPhotoConfiguration.h"
#import "HXPhotoModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface HXPhotoCommon : NSObject

/**
相册风格
*/
@property (assign, nonatomic) HXPhotoStyle photoStyle;
@property (assign, nonatomic) HXPhotoLanguageType languageType;
@property (strong, nonatomic) UIImage *cameraImage;

+ (instancetype)photoCommon;
+ (void)deallocPhotoCommon;
- (void)saveCamerImage;
- (BOOL)isDark;
@end

NS_ASSUME_NONNULL_END
