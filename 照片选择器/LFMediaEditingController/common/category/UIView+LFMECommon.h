//
//  UIView+LFCommon.h
//  LFImagePickerController
//
//  Created by LamTsanFeng on 2017/2/23.
//  Copyright © 2017年 LamTsanFeng. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIView (LFMECommon)
/** 截取图层为图片 */
- (UIImage *)LFME_captureImage;
/** 截图图层部分为图片 */
- (UIImage *)LFME_captureImageAtFrame:(CGRect)rect;
/** layer坐标颜色 */
- (UIColor *)LFME_colorOfPoint:(CGPoint)point;
@end
