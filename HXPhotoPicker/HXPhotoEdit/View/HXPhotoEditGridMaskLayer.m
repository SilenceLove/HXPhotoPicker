//
//  HXPhotoEditGridMaskLayer.m
//  photoEditDemo
//
//  Created by Silence on 2020/6/29.
//  Copyright © 2020 Silence. All rights reserved.
//

#import "HXPhotoEditGridMaskLayer.h"

@implementation HXPhotoEditGridMaskLayer
@synthesize maskColor = _maskColor;

- (instancetype)init {
    self = [super init];
    if (self) {
        [self customInit];
    }
    return self;
}

- (void)customInit {
    self.contentsScale = [[UIScreen mainScreen] scale];
}

- (void)setMaskColor:(CGColorRef)maskColor {
    self.fillColor = maskColor;
    self.fillRule = kCAFillRuleEvenOdd;
}

- (CGColorRef)maskColor {
    return self.fillColor;
}

- (void)setMaskRect:(CGRect)maskRect {
    [self setMaskRect:maskRect animated:NO];
}

- (void)setMaskRect:(CGRect)maskRect animated:(BOOL)animated {
    _maskRect = maskRect;
    CGPathRef path = nil;
    if (CGRectEqualToRect(CGRectZero, maskRect)) {
        path = [self newDrawClearGrid];
    } else {
        path = [self newDrawGrid];
    }
    [self removeAnimationForKey:@"hx_maskLayer_opacityAnimate"];
    if (animated) {
        CABasicAnimation *animate = [CABasicAnimation animationWithKeyPath:@"opacity"];
        animate.duration = 0.25f;
        animate.fromValue = @(0.0);
        animate.toValue = @(1.0);
        self.path = path;
        [self addAnimation:animate forKey:@"hx_maskLayer_opacityAnimate"];
    } else {
        self.path = path;
    }
    CGPathRelease(path);
}

- (void)clearMask {
    [self clearMaskWithAnimated:NO];
}

- (void)clearMaskWithAnimated:(BOOL)animated {
    [self setMaskRect:CGRectZero animated:animated];
    
}

- (CGPathRef)newDrawGrid {
    CGRect maskRect = self.maskRect;
    CGMutablePathRef mPath = CGPathCreateMutable();
    CGPathAddRect(mPath, NULL, self.bounds);
    if (self.isRound) {
        CGPathAddRoundedRect(mPath, NULL, maskRect, maskRect.size.width / 2.f, maskRect.size.height / 2.f);
    }else {
        CGPathAddRect(mPath, NULL, maskRect);
    }
    return mPath;
}

- (CGPathRef)newDrawClearGrid {
    CGMutablePathRef mPath = CGPathCreateMutable();
    CGPathAddRect(mPath, NULL, self.bounds);
    CGPathAddRect(mPath, NULL, self.bounds);
    return mPath;
}
@end
