//
//  UIImage+HXExtension.h
//  HXPhotoPicker-Demo
//
//  Created by 洪欣 on 17/2/15.
//  Copyright © 2017年 洪欣. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreMedia/CoreMedia.h>

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
+ (UIImage *)hx_rotationImage:(UIImage *)image orient:(UIImageOrientation)orient;
+ (UIImage *)hx_imageWithColor:(UIColor *)color havingSize:(CGSize)size;


- (UIImage *)hx_cropInRect:(CGRect)rect;
- (UIImage *)hx_imageRotatedByRadians:(CGFloat)radians mirrorHorizontally:(BOOL)mirrorHorizontally;
- (UIImage *)hx_imageRotatedByRadians:(CGFloat)radians scale:(CGFloat)scale  mirrorHorizontally:(BOOL)mirrorHorizontally;
- (UIImage *)hx_scaleToFillSize:(CGSize)size;
- (UIImage *)hx_mergeimages:(NSArray <UIImage *>*)images;
+ (UIImage *)hx_mergeimages:(NSArray <UIImage *>*)images;
+ (CGSize)hx_scaleImageSizeBySize:(CGSize)imageSize targetSize:(CGSize)size isBoth:(BOOL)isBoth ;
- (UIImage *)hx_scaleToFitSize:(CGSize)size;
- (UIImage *)hx_transToMosaicLevel:(NSUInteger)level;
- (UIImage *)hx_transToBlurLevel:(NSUInteger)blurRadius;

+ (UIImage *)hx_imageFromSampleBuffer:(CMSampleBufferRef)sampleBuffer;
+ (UIImage *)hx_snapshotCALayer:(CALayer *)layer;
@end
