//
//  UIImage+HXExtension.h
//  HXPhotoPickerExample
//
//  Created by Silence on 17/2/15.
//  Copyright © 2017年 Silence. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreMedia/CoreMedia.h>

@interface UIImage (HXExtension)
+ (UIImage *)hx_imageNamed:(NSString *)imageName;
+ (UIImage *)hx_imageContentsOfFile:(NSString *)imageName;
+ (UIImage *)hx_thumbnailImageForVideo:(NSURL *)videoURL
                             atTime:(NSTimeInterval)time;
+ (UIImage *)hx_animatedGIFWithData:(NSData *)data;
+ (UIImage *)hx_animatedGIFWithURL:(NSURL *)URL;
- (UIImage *)hx_normalizedImage;

- (UIImage *)hx_scaleImagetoScale:(float)scaleSize;
- (UIImage *)hx_rotationImage:(UIImageOrientation)orient;

+ (UIImage *)hx_imageWithColor:(UIColor *)color havingSize:(CGSize)size;


- (UIImage *)hx_cropInRect:(CGRect)rect;
- (UIImage *)hx_roundClipingImage;
- (UIImage *)hx_scaleToFillSize:(CGSize)size;
- (UIImage *)hx_mergeimages:(NSArray <UIImage *>*)images;
+ (UIImage *)hx_mergeimages:(NSArray <UIImage *>*)images;
+ (CGSize)hx_scaleImageSizeBySize:(CGSize)imageSize targetSize:(CGSize)size isBoth:(BOOL)isBoth ;
- (UIImage *)hx_scaleToFitSize:(CGSize)size;

@end
