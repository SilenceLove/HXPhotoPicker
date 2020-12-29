//
//  UIButton+HXExtension.h
//  HXPhotoPickerExample
//
//  Created by Silence on 17/2/16.
//  Copyright © 2017年 Silence. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIButton (HXExtension)
/**  扩大buuton点击范围  */
- (void)hx_setEnlargeEdgeWithTop:(CGFloat)top right:(CGFloat)right bottom:(CGFloat)bottom left:(CGFloat)left;
@end
