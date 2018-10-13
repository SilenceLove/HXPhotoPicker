//
//  UIImage+LFCommon.h
//  LFImagePickerController
//
//  Created by LamTsanFeng on 2017/2/13.
//  Copyright © 2017年 LamTsanFeng. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIImage (LFMECommon)

/** 修正图片方向 */
- (UIImage *)LFME_fixOrientation;

/** 计算图片的缩放大小 */
+ (CGSize)LFME_scaleImageSizeBySize:(CGSize)imageSize targetSize:(CGSize)size isBoth:(BOOL)isBoth;

/** 缩放图片到指定大小 */
- (UIImage*)LFME_scaleToSize:(CGSize)size;

/** 合并图片 */
- (UIImage *)LFME_mergeimages:(NSArray <UIImage *>*)images;

/** 将图片旋转弧度radians */
- (UIImage *)LFME_imageRotatedByRadians:(CGFloat)radians;

/*
 *转换成马赛克,level代表一个点转为多少level*level的正方形
 */
- (UIImage *)LFME_transToMosaicLevel:(NSUInteger)level;

/** 高斯模糊 */
- (UIImage *)LFME_transToBlurLevel:(NSUInteger)blurRadius;
@end
