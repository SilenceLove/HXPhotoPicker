//
//  LFGridLayer.m
//  LFImagePickerController
//
//  Created by LamTsanFeng on 2017/3/6.
//  Copyright © 2017年 LamTsanFeng. All rights reserved.
//

#import "LFGridLayer.h"

@implementation LFGridLayer

- (instancetype)init
{
    self = [super init];
    if (self) {
//        _lineWidth = 1.f;
        self.contentsScale = [[UIScreen mainScreen] scale];
        _bgColor = [UIColor clearColor];
        _gridColor = [UIColor blackColor];
    }
    return self;
}

- (void)setGridRect:(CGRect)gridRect
{
    [self setGridRect:gridRect animated:NO];
}

- (void)setGridRect:(CGRect)gridRect animated:(BOOL)animated
{
    if (!CGRectEqualToRect(_gridRect, gridRect)) {
        _gridRect = gridRect;
        
        CGPathRef path = [self drawGrid];
        if (animated) {
            CABasicAnimation *animate = [CABasicAnimation animationWithKeyPath:@"path"];
            animate.duration = 0.25f;
            animate.fromValue = (__bridge id _Nullable)(self.path);
            animate.toValue = (__bridge id _Nullable)(path);
//            animate.fillMode=kCAFillModeForwards;
            [self addAnimation:animate forKey:@"lf_gridLayer_contentsRectAnimate"];
        }
        
        self.path = path;
    }
}

- (CGPathRef)drawGrid
{
    self.fillColor = self.bgColor.CGColor;
    self.strokeColor = self.gridColor.CGColor;
    
    CGRect rct = self.gridRect;
    UIBezierPath *path = [[UIBezierPath alloc] init];
    
    CGFloat dW = 0;
    for(int i=0;i<4;++i){ /** 竖线 */
        [path moveToPoint:CGPointMake(rct.origin.x+dW, rct.origin.y)];
        [path addLineToPoint:CGPointMake(rct.origin.x+dW, rct.origin.y+rct.size.height)];
        dW += _gridRect.size.width/3;
    }
    
    dW = 0;
    for(int i=0;i<4;++i){ /** 横线 */
        [path moveToPoint:CGPointMake(rct.origin.x, rct.origin.y+dW)];
        [path addLineToPoint:CGPointMake(rct.origin.x+rct.size.width, rct.origin.y+dW)];
        dW += rct.size.height/3;
    }
    
    /** 偏移量 */
    CGFloat offset = 1;
    /** 长度 */
    CGFloat cornerlength = 15.f;
    
    CGRect newRct = CGRectInset(rct, -offset, -offset);
    
    /** 左上角 */
    [path moveToPoint:CGPointMake(CGRectGetMinX(newRct) , CGRectGetMinY(newRct)+cornerlength)];
    [path addLineToPoint:CGPointMake(CGRectGetMinX(newRct) , CGRectGetMinY(newRct))];
    [path addLineToPoint:CGPointMake(CGRectGetMinX(newRct)+cornerlength , CGRectGetMinY(newRct))];
    
    /** 右上角 */
    [path moveToPoint:CGPointMake(CGRectGetMaxX(newRct)-cornerlength , CGRectGetMinY(newRct))];
    [path addLineToPoint:CGPointMake(CGRectGetMaxX(newRct) , CGRectGetMinY(newRct))];
    [path addLineToPoint:CGPointMake(CGRectGetMaxX(newRct) , CGRectGetMinY(newRct)+cornerlength)];
    
    /** 右下角 */
    [path moveToPoint:CGPointMake(CGRectGetMaxX(newRct) , CGRectGetMaxY(newRct)-cornerlength)];
    [path addLineToPoint:CGPointMake(CGRectGetMaxX(newRct) , CGRectGetMaxY(newRct))];
    [path addLineToPoint:CGPointMake(CGRectGetMaxX(newRct)-cornerlength , CGRectGetMaxY(newRct))];
    
    /** 左下角 */
    [path moveToPoint:CGPointMake(CGRectGetMinX(newRct)+cornerlength , CGRectGetMaxY(newRct))];
    [path addLineToPoint:CGPointMake(CGRectGetMinX(newRct) , CGRectGetMaxY(newRct))];
    [path addLineToPoint:CGPointMake(CGRectGetMinX(newRct) , CGRectGetMaxY(newRct)-cornerlength)];
    
    return path.CGPath;
}

@end
