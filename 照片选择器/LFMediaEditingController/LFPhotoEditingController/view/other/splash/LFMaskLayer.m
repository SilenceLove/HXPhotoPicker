//
//  LFMaskLayer.m
//  DrawTest
//
//  Created by LamTsanFeng on 2017/3/3.
//  Copyright © 2017年 LamTsanFeng. All rights reserved.
//

#import "LFMaskLayer.h"

@implementation LFBlurBezierPath


@end

@implementation LFMaskLayer

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.contentsScale = [[UIScreen mainScreen] scale];
        _lineArray = [@[] mutableCopy];
    }
    return self;
}

- (void)drawInContext:(CGContextRef)context
{
    UIGraphicsPushContext( context );
    CGContextSetLineCap(context, kCGLineCapRound);
    CGContextSetLineJoin(context, kCGLineJoinRound);
    
    for (LFBlurBezierPath *path in self.lineArray) {
        if (path.isClear) {
            CGContextSetBlendMode( context, kCGBlendModeClear );
        } else {
            CGContextSetBlendMode( context, kCGBlendModeNormal );
        }
//        [[UIColor darkGrayColor] setStroke];
        [path stroke];
    }

    UIGraphicsPopContext();
}

@end
