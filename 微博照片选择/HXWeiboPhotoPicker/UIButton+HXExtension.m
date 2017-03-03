//
//  UIButton+HXExtension.m
//  微博照片选择
//
//  Created by 洪欣 on 17/2/16.
//  Copyright © 2017年 洪欣. All rights reserved.
//

#import "UIButton+HXExtension.h"
#import <objc/runtime.h>

@implementation UIButton (HXExtension)

static char topNameKey;
static char rightNameKey;
static char bottomNameKey;
static char leftNameKey;

- (void)setEnlargeEdgeWithTop:(CGFloat)top right:(CGFloat)right bottom:(CGFloat)bottom left:(CGFloat)left
{
    objc_setAssociatedObject(self, &topNameKey, [NSNumber numberWithFloat:top], OBJC_ASSOCIATION_COPY_NONATOMIC);
    objc_setAssociatedObject(self, &rightNameKey, [NSNumber numberWithFloat:right], OBJC_ASSOCIATION_COPY_NONATOMIC);
    objc_setAssociatedObject(self, &bottomNameKey, [NSNumber numberWithFloat:bottom], OBJC_ASSOCIATION_COPY_NONATOMIC);
    objc_setAssociatedObject(self, &leftNameKey, [NSNumber numberWithFloat:left], OBJC_ASSOCIATION_COPY_NONATOMIC);
}
@end
