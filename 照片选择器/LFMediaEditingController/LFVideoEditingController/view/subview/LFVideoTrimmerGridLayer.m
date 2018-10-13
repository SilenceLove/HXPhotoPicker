//
//  LFVideoTrimmerGridLayer.m
//  LFMediaEditingController
//
//  Created by LamTsanFeng on 2017/7/18.
//  Copyright © 2017年 LamTsanFeng. All rights reserved.
//

#import "LFVideoTrimmerGridLayer.h"

@implementation LFVideoTrimmerGridLayer

- (instancetype)init
{
    self = [super init];
    if (self) {
        //        _lineWidth = 1.f;
        self.contentsScale = [[UIScreen mainScreen] scale];
        _bgColor = [UIColor clearColor];
        _gridColor = [UIColor whiteColor];
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
            [self addAnimation:animate forKey:@"lf_videoGridLayer_contentsRectAnimate"];
        }
        
        self.path = path;
    }
}

- (CGPathRef)drawGrid
{
    self.fillColor = self.bgColor.CGColor;
    self.strokeColor = self.gridColor.CGColor;
    
    CGRect rct = self.gridRect;
    UIBezierPath *path = [UIBezierPath bezierPathWithRect:rct];
    
    return path.CGPath;
}
@end
