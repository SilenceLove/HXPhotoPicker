//
//  LFGridMaskLayer.h
//  ClippingText
//
//  Created by LamTsanFeng on 2017/3/7.
//  Copyright © 2017年 LamTsanFeng. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface LFGridMaskLayer : CAShapeLayer

@property (nonatomic, assign) CGColorRef maskColor;
@property (nonatomic, setter=setMaskRect:) CGRect maskRect;
- (void)setMaskRect:(CGRect)maskRect animated:(BOOL)animated;

@end
