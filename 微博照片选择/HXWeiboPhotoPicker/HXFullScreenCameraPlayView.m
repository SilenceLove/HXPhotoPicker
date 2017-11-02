//
//  HXFullScreenCameraPlayView.m
//  微博照片选择
//
//  Created by 洪欣 on 2017/5/23.
//  Copyright © 2017年 洪欣. All rights reserved.
//

#import "HXFullScreenCameraPlayView.h"

@interface HXFullScreenCameraPlayView ()
// 外界圆形
@property (nonatomic, strong) CAShapeLayer *whiteCircleLayer;
// 内部圆形
@property (nonatomic, strong) CAShapeLayer *circleLayer;
// 进度扇形
@property (nonatomic, strong) CAShapeLayer *progressLayer;
@property (assign, nonatomic) CGFloat currentProgress;

@end

@implementation HXFullScreenCameraPlayView

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self setup];
    }
    return self;
}
- (instancetype)initWithFrame:(CGRect)frame color:(UIColor *)color {
    if (self = [super initWithFrame:frame]) {
        self.color = color;
        [self setup];
    }
    return self;
}
- (UIColor *)color {
    if (!_color) {
        _color = [UIColor colorWithRed:253/255.0 green:142/255.0 blue:36/255.0 alpha:1];
    }
    return _color;
}

- (void)setup {
    self.backgroundColor = [UIColor clearColor];
    CAShapeLayer *whiteCircleLayer = [CAShapeLayer layer];
    whiteCircleLayer.strokeColor = [UIColor colorWithRed:1 green:1 blue:1 alpha:1].CGColor;
    whiteCircleLayer.fillColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0].CGColor;
    whiteCircleLayer.lineWidth = 5;
    whiteCircleLayer.path = [self circlePath:self.frame.size.width * 0.5].CGPath;
    [self.layer addSublayer:whiteCircleLayer];
    self.whiteCircleLayer = whiteCircleLayer;
    
    CAShapeLayer *circleLayer = [CAShapeLayer layer];
    circleLayer.strokeColor = [UIColor clearColor].CGColor;
    circleLayer.fillColor = self.color.CGColor;
    circleLayer.path = [self circlePath:(self.frame.size.width * 0.5 - 12)].CGPath;
    [self.layer addSublayer:circleLayer];
    circleLayer.hidden = YES;
    self.circleLayer = circleLayer;
    
    CAShapeLayer *progressLayer = [CAShapeLayer layer];
    progressLayer.strokeColor = self.color.CGColor;
    progressLayer.fillColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0].CGColor;
    progressLayer.lineWidth = 5;
    progressLayer.path = [UIBezierPath bezierPathWithArcCenter:CGPointMake(self.frame.size.width * 0.5, self.frame.size.height * 0.5) radius:self.frame.size.width * 0.5 startAngle:-M_PI / 2 endAngle:-M_PI / 2 + M_PI * 2 * 1 clockwise:true].CGPath;
    progressLayer.hidden = YES;
    [self.layer addSublayer:progressLayer];
    self.progressLayer = progressLayer;
    self.currentProgress = 0.f;
}
- (UIBezierPath *)circlePath:(CGFloat)radius {
    UIBezierPath *path = [UIBezierPath bezierPathWithArcCenter:CGPointMake(self.frame.size.width * 0.5, self.frame.size.height * 0.5) radius:radius startAngle:0 endAngle:M_PI * 2 clockwise:true];
    path.lineWidth = 1;
    return path;
}
- (void)clean {
    self.progressLayer.hidden = YES;
    self.circleLayer.hidden = YES;
    self.currentProgress = 0;
}
- (void)setProgress:(CGFloat)progress {
    _progress = progress; 
    self.progressLayer.hidden = NO;
    self.circleLayer.hidden = NO;
    CABasicAnimation *circleAnim = [CABasicAnimation animationWithKeyPath:@"strokeEnd"];
    circleAnim.fromValue = @(self.currentProgress);
    circleAnim.toValue = @(progress);
    circleAnim.duration = 1.0f;
    circleAnim.fillMode = kCAFillModeForwards;
    circleAnim.removedOnCompletion = NO;
    circleAnim.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear];
    [self.progressLayer addAnimation:circleAnim forKey:@"circle"];
    self.currentProgress = progress;
}
- (UIBezierPath *)pathForProgress:(CGFloat)progress {
    CGPoint center = CGPointMake(self.frame.size.width * 0.5, self.frame.size.height * 0.5);
    CGFloat radius = self.frame.size.height * 0.5;
    UIBezierPath *path = [UIBezierPath bezierPathWithArcCenter:center radius:radius startAngle:-M_PI / 2 endAngle:-M_PI / 2 + M_PI * 2 * progress clockwise:true];
    path.lineWidth = 1;
    return path;
}

@end
