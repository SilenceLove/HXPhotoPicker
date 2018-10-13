//
//  LFColorSlider.m
//  LFImagePickerController
//
//  Created by LamTsanFeng on 2017/3/28.
//  Copyright © 2017年 LamTsanFeng. All rights reserved.
//

#import "LFColorSlider.h"

@interface LFColorSlider ()


@end

@implementation LFColorSlider

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setMaximumTrackImage:[UIImage new] forState:UIControlStateNormal];
        [self setMinimumTrackImage:[UIImage new] forState:UIControlStateNormal];
        [self setThumbImage:[UIImage new] forState:UIControlStateNormal];
        self.backgroundColor = [UIColor colorWithPatternImage:[self colorSliderBackground]];
        UITapGestureRecognizer *_singleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(singleTapPressed:)];
        [self addGestureRecognizer:_singleTap];
        [self addTarget:self action:@selector(colorSliderDidChange:) forControlEvents:UIControlEventValueChanged];
    }
    return self;
}

- (void)setValue:(float)value
{
    [super setValue:value];
    self.thumbTintColor = self.color;
}

#pragma mark - 滑动
- (void)colorSliderDidChange:(LFColorSlider *)sender
{
    UIColor *color = sender.color;
    sender.thumbTintColor = color;
    if ([self.delegate respondsToSelector:@selector(lf_colorSliderDidChangeColor:)]) {
        [self.delegate lf_colorSliderDidChangeColor:color];
    }
}


#pragma mark - 单击方法
- (void)singleTapPressed:(UITapGestureRecognizer *)tap
{
    /** 最终目的：让slider无法点击穿透 */
    
//    CGRect t = [self trackRectForBounds: [self bounds]];
//    float v = [self minimumValue] + ([tap locationInView: self].x - t.origin.x) * (([self maximumValue]-[self minimumValue]) / (t.size.width));
    [self setValue:([tap locationInView: self].x/self.bounds.size.width)];
    [self colorSliderDidChange:self];
}

#pragma mark - 重写父类 (进度条两边有空隙的问题)
//- (CGRect)thumbRectForBounds:(CGRect)bounds trackRect:(CGRect)rect value:(float)value
//{
//    CGRect thumbRect = [super thumbRectForBounds:bounds trackRect:rect value:value];
//    thumbRect.origin.x += (thumbRect.size.width-40)/2;
//    thumbRect.size.width = 40;
//    return thumbRect;
//}

-(CGRect)trackRectForBounds:(CGRect)bounds {
    
    bounds.origin.x=-15;
    
    bounds.origin.y=bounds.size.height/3;
    
    bounds.size.height=bounds.size.height/5;
    
    bounds.size.width=bounds.size.width+30;
    
    return bounds;
}


#pragma mark - 私有
- (UIImage*)colorSliderBackground
{
    CGSize size = self.frame.size;
    UIGraphicsBeginImageContextWithOptions(size, NO, 0.0);
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGRect frame = CGRectMake(5, (size.height-10)/2, size.width-10, 5);
    CGPathRef path = [UIBezierPath bezierPathWithRoundedRect:frame cornerRadius:5].CGPath;
    CGContextAddPath(context, path);
    CGContextClip(context);
    
    CGColorSpaceRef colorSpaceRef = CGColorSpaceCreateDeviceRGB();
    CGFloat components[] = {
        0.0f, 0.0f, 0.0f, 1.0f,
        1.0f, 1.0f, 1.0f, 1.0f,
        1.0f, 0.0f, 0.0f, 1.0f,
        1.0f, 1.0f, 0.0f, 1.0f,
        0.0f, 1.0f, 0.0f, 1.0f,
        0.0f, 1.0f, 1.0f, 1.0f,
        0.0f, 0.0f, 1.0f, 1.0f
    };
    
    size_t count = sizeof(components)/ (sizeof(CGFloat)* 4);
    CGFloat locations[] = {0.0f, 0.9/3.0, 1/3.0, 1.5/3.0, 2/3.0, 2.5/3.0, 1.0};
    
    CGPoint startPoint = CGPointMake(5, 0);
    CGPoint endPoint = CGPointMake(size.width-5, 0);
    
    CGGradientRef gradientRef = CGGradientCreateWithColorComponents(colorSpaceRef, components, locations, count);
    
    CGContextDrawLinearGradient(context, gradientRef, startPoint, endPoint, kCGGradientDrawsAfterEndLocation);
    
    UIImage *tmp = UIGraphicsGetImageFromCurrentImageContext();
    
    CGGradientRelease(gradientRef);
    CGColorSpaceRelease(colorSpaceRef);
    
    UIGraphicsEndImageContext();
    
    return tmp;
}

- (UIColor*)color
{
    CGFloat value = self.value;
    if(value<1/3.0){
        return [UIColor colorWithWhite:value/0.3 alpha:1];
    }
    return [UIColor colorWithHue:((value-1/3.0)/0.7)*2/3.0 saturation:1 brightness:1 alpha:1];
}
@end
