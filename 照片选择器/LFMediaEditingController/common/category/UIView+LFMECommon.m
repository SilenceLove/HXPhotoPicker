//
//  UIView+LFCommon.m
//  LFImagePickerController
//
//  Created by LamTsanFeng on 2017/2/23.
//  Copyright © 2017年 LamTsanFeng. All rights reserved.
//

#import "UIView+LFMECommon.h"

@implementation UIView (LFMECommon)

- (UIImage *)LFME_captureImage
{
    return [self LFME_captureImageAtFrame:CGRectZero];
}

- (UIImage *)LFME_captureImageAtFrame:(CGRect)rect
{
    UIImage* image = nil;
    
    BOOL translateCTM = !CGRectEqualToRect(CGRectZero, rect);
    
    if (!translateCTM) {
        rect = self.frame;
    }
    
    /** 参数取整，否则可能会出现1像素偏差 */
    rect.origin.x = (rect.origin.x+FLT_EPSILON);
    rect.origin.y = (rect.origin.y+FLT_EPSILON);
    rect.size.width = (rect.size.width+FLT_EPSILON);
    rect.size.height = (rect.size.height+FLT_EPSILON);
    
    CGSize size = rect.size;
    
    //1.开启上下文
    UIGraphicsBeginImageContextWithOptions(size, NO, [UIScreen mainScreen].scale);
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    if (translateCTM) {
        /** 移动上下文 */
        CGContextTranslateCTM(context, -rect.origin.x, -rect.origin.y);
    }
    //2.绘制图层
    [self.layer renderInContext: context];
    
    //3.从上下文中获取新图片
    image = UIGraphicsGetImageFromCurrentImageContext();
    
    //4.关闭图形上下文
    UIGraphicsEndImageContext();
    
//    if (!CGRectEqualToRect(CGRectZero, rect)) {
//        UIGraphicsBeginImageContextWithOptions(rect.size, NO, [UIScreen mainScreen].scale);
//        [image drawAtPoint:CGPointMake(-roundf(rect.origin.x*100)/100, -roundf(rect.origin.y*100)/100)];
//        image = UIGraphicsGetImageFromCurrentImageContext();
//        UIGraphicsEndImageContext();
//    }
    
    return image;
}

- (UIColor *)LFME_colorOfPoint:(CGPoint)point
{
    unsigned char pixel[4] = {0};
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate(pixel, 1, 1, 8, 4, colorSpace, kCGImageAlphaPremultipliedLast);
    
    CGContextTranslateCTM(context, -point.x, -point.y);
    
    [self.layer renderInContext:context];
    
    CGContextRelease(context);
    CGColorSpaceRelease(colorSpace);
    
    UIColor *color = [UIColor colorWithRed:pixel[0]/255.0 green:pixel[1]/255.0 blue:pixel[2]/255.0 alpha:pixel[3]/255.0];
    
    return color;
}
@end
