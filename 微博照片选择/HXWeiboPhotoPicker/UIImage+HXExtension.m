//
//  UIImage+HXExtension.m
//  微博照片选择
//
//  Created by 洪欣 on 17/2/15.
//  Copyright © 2017年 洪欣. All rights reserved.
//

#import "UIImage+HXExtension.h"
#import <ImageIO/ImageIO.h>
@implementation UIImage (HXExtension)

+ (UIImage *)animatedGIFWithData:(NSData *)data {
    if (!data) {
        return nil;
    }
    //通过CFData读取gif文件的数据
    CGImageSourceRef source = CGImageSourceCreateWithData((__bridge CFDataRef)data, NULL);
    //获取gif文件的帧数
    size_t count = CGImageSourceGetCount(source);
    UIImage *animatedImage;
    if (count <= 1) {
        animatedImage = [[UIImage alloc] initWithData:data];
    }
    else {//大于一张图片时
        NSMutableArray *images = [NSMutableArray array];
        //设置gif播放的时间
        NSTimeInterval duration = 0.0f;
        for (size_t i = 0; i < count; i++) {
            //获取gif指定帧的像素位图
            CGImageRef image = CGImageSourceCreateImageAtIndex(source, i, NULL);
            if (!image) {
                continue;
            }
            //获取每张图的播放时间
            duration += [self frameDurationAtIndex:i source:source];
            [images addObject:[UIImage imageWithCGImage:image scale:[UIScreen mainScreen].scale orientation:UIImageOrientationUp]];
            CGImageRelease(image);
        }
        if (!duration) {//如果播放时间为空
            duration = (1.0f / 10.0f) * count;
        }
        animatedImage = [UIImage animatedImageWithImages:images duration:duration];
    }
    CFRelease(source);
    return animatedImage;
}

+ (float)frameDurationAtIndex:(NSUInteger)index source:(CGImageSourceRef)source {
    float frameDuration = 0.1f;
    //获取这一帧图片的属性字典
    CFDictionaryRef cfFrameProperties = CGImageSourceCopyPropertiesAtIndex(source, index, nil);
    NSDictionary *frameProperties = (__bridge NSDictionary *)cfFrameProperties;
    //获取gif属性字典
    NSDictionary *gifProperties = frameProperties[(NSString *)kCGImagePropertyGIFDictionary];
    //获取这一帧持续的时间
    NSNumber *delayTimeUnclampedProp = gifProperties[(NSString *)kCGImagePropertyGIFUnclampedDelayTime];
    if (delayTimeUnclampedProp) {
        frameDuration = [delayTimeUnclampedProp floatValue];
    }
    else {
        NSNumber *delayTimeProp = gifProperties[(NSString *)kCGImagePropertyGIFDelayTime];
        if (delayTimeProp) {
            frameDuration = [delayTimeProp floatValue];
        }
    }
    //如果帧数小于0.1,则指定为0.1
    if (frameDuration < 0.011f) {
        frameDuration = 0.100f;
    }
    CFRelease(cfFrameProperties);
    return frameDuration;
}

- (UIImage *)animatedImageByScalingAndCroppingToSize:(CGSize)size {
    if (CGSizeEqualToSize(self.size, size) || CGSizeEqualToSize(size, CGSizeZero)) {
        return self;
    }
    CGSize scaledSize = size;
    CGPoint thumbnailPoint = CGPointZero;
    //获取较大的缩放比例值,宽高等比缩放
    CGFloat widthFactor = size.width / self.size.width;
    CGFloat heightFactor = size.height / self.size.height;
    CGFloat scaleFactor = (widthFactor > heightFactor) ? widthFactor : heightFactor;
    scaledSize.width = self.size.width * scaleFactor;
    scaledSize.height = self.size.height * scaleFactor;
    //调整位置,使缩放后的图居中
    if (widthFactor > heightFactor) {
        thumbnailPoint.y = (size.height - scaledSize.height) * 0.5;
    }
    else if (widthFactor < heightFactor) {
        thumbnailPoint.x = (size.width - scaledSize.width) * 0.5;
    }
    //遍历self.images, 将图片缩放后导出放入数组
    NSMutableArray *scaledImages = [NSMutableArray array];
    for (UIImage *image in self.images) {
        UIGraphicsBeginImageContextWithOptions(size, NO, 0.0);
        [image drawInRect:CGRectMake(thumbnailPoint.x, thumbnailPoint.y, scaledSize.width, scaledSize.height)];
        UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
        [scaledImages addObject:newImage];
        UIGraphicsEndImageContext();
    }
    return [UIImage animatedImageWithImages:scaledImages duration:self.duration];
}

- (UIImage *)normalizedImage
{
    if (self.imageOrientation == UIImageOrientationUp) return self;
    
    UIGraphicsBeginImageContextWithOptions(self.size, NO, self.scale);
    [self drawInRect:(CGRect){0, 0, self.size}];
    UIImage *normalizedImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return normalizedImage;
}

- (UIImage *)clipImage:(CGFloat)scale
{
    CGFloat width = self.size.width;
    CGFloat height = self.size.height;
    
    CGRect rect = CGRectMake((width - width / scale) / 2, height / 2 - width / scale / 2, width / scale, width / scale);
    CGImageRef imageRef = self.CGImage;
    CGImageRef imagePartRef = CGImageCreateWithImageInRect(imageRef, rect);
    UIImage *image = [UIImage imageWithCGImage:imagePartRef];
    CGImageRelease(imagePartRef);
    return image;
}

- (UIImage *)scaleImagetoScale:(float)scaleSize
{
    
    UIGraphicsBeginImageContext(CGSizeMake(self.size.width * scaleSize, self.size.height * scaleSize));
                                
    [self drawInRect:CGRectMake(0, 0, self.size.width * scaleSize, self.size.height * scaleSize)];
    UIImage *scaledImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    return scaledImage;
}

@end
