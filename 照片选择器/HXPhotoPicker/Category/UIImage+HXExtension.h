//
//  UIImage+HXExtension.h
//  照片选择器
//
//  Created by 洪欣 on 17/2/15.
//  Copyright © 2017年 洪欣. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIImage (HXExtension)
+ (UIImage *)hx_imageNamed:(NSString *)imageName;
+ (UIImage *)hx_thumbnailImageForVideo:(NSURL *)videoURL
                             atTime:(NSTimeInterval)time;
+ (UIImage *)hx_animatedGIFWithData:(NSData *)data;
+ (UIImage *)hx_animatedGIFWithURL:(NSURL *)URL;
- (UIImage *)hx_animatedImageByScalingAndCroppingToSize:(CGSize)size;
- (UIImage *)hx_normalizedImage;
- (UIImage *)hx_clipImage:(CGFloat)scale;
- (UIImage *)hx_scaleImagetoScale:(float)scaleSize;
- (UIImage *)hx_clipNormalizedImage:(CGFloat)scale;
- (UIImage *)hx_fullNormalizedImage;
- (UIImage *)hx_clipLeftOrRightImage:(CGFloat)scale;
- (UIImage *)hx_rotationImage:(UIImageOrientation)orient;

@end
