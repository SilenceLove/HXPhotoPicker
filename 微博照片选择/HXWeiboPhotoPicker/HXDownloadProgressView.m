//
//  HXDownloadProgressView.m
//  微博照片选择
//
//  Created by 洪欣 on 2017/11/20.
//  Copyright © 2017年 洪欣. All rights reserved.
//

#import "HXDownloadProgressView.h"
#import "HXPhotoTools.h" 

@interface HXDownloadProgressView ()<CAAnimationDelegate>
@property (nonatomic, strong) CAShapeLayer *edgeShapeLayer;
@property (nonatomic, assign, readonly) CGFloat showRadius;
@property (nonatomic, strong) UIView *centerView;
@property (nonatomic, strong) UILabel *label;
@end

@implementation HXDownloadProgressView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setup];
    }
    return self;
}

- (void)setup {
    self.layer.masksToBounds = YES;
    self.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:0.2];
    [self.layer addSublayer:self.edgeShapeLayer];
    [self addSubview:self.centerView];
}
- (void)resetState {
    UIBezierPath *bezierPath = [self bezierWithRadius:self.showRadius progressValue:0];
    self.edgeShapeLayer.path = bezierPath.CGPath;
}
- (void)layoutSubviews {
    [super layoutSubviews];
    self.centerView.frame = CGRectMake(0, 0, (self.hx_h * 0.6 - 1.5), (self.hx_h * 0.6 - 1.5));
    self.centerView.center = CGPointMake(self.hx_w / 2, self.hx_h / 2);
    self.centerView.layer.cornerRadius = self.centerView.hx_w / 2;
    self.label.frame = self.centerView.bounds;
}
- (void)startAnima {
    [self.centerView.layer removeAnimationForKey:@"centerScale"];
    CAKeyframeAnimation *scaleAnima = [CAKeyframeAnimation animationWithKeyPath:@"transform.scale"];
    scaleAnima.values = @[@(0.9),@(1.1),@(0.95),@(1.05)];
    scaleAnima.duration = 1.f;
    scaleAnima.autoreverses = YES;
    scaleAnima.repeatCount = MAXFLOAT;
    [self.centerView.layer addAnimation:scaleAnima forKey:@"centerScale"];
}
- (void)setProgress:(CGFloat)progress {
    _progress = progress;
    self.label.text = [NSString stringWithFormat:@"%d%%",(int)(progress * 100)];
    if (progress >= 1) {
        progress = 1;
        [self animationComplete];
    }
}
- (void)animationComplete {
    self.label.text = nil;
    [self.centerView.layer removeAnimationForKey:@"centerScale"];
    [UIView animateWithDuration:0.3 animations:^{
        self.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:0];
    }];
    CABasicAnimation *scaleAnimation = [CABasicAnimation animationWithKeyPath:@"transform.scale"];
    scaleAnimation.toValue = @(0);
    scaleAnimation.duration = 0.3f;
    scaleAnimation.delegate = self;
    [self.centerView.layer addAnimation:scaleAnimation forKey:nil];
    
    CABasicAnimation *maskLayerAnimation = [CABasicAnimation animationWithKeyPath:@"path"];
    maskLayerAnimation.toValue = (__bridge id _Nullable)([self bezierWithRadius:self.showRadius progressValue:1].CGPath);
    maskLayerAnimation.duration = 0.7f;
    maskLayerAnimation.delegate = self;
    [self.edgeShapeLayer addAnimation:maskLayerAnimation forKey:nil];
}
- (void)animationDidStop:(CAAnimation *)anim finished:(BOOL)flag {
    if (flag) {
        self.hidden = YES;
        [self resetState];
    }
}
- (CAShapeLayer *)edgeShapeLayer{
    if (!_edgeShapeLayer) {
        _edgeShapeLayer = [CAShapeLayer layer];
        _edgeShapeLayer.strokeColor = [UIColor clearColor].CGColor;
        _edgeShapeLayer.fillColor = [[UIColor blackColor] colorWithAlphaComponent:0.7].CGColor;
        _edgeShapeLayer.fillRule = @"even-odd";
        UIBezierPath *bezierPath = [self bezierWithRadius:self.showRadius progressValue:0];
        _edgeShapeLayer.path = bezierPath.CGPath;
    }
    return _edgeShapeLayer;
}
- (UIBezierPath *)bezierWithRadius:(CGFloat)radius progressValue:(CGFloat)progressValue{
    UIBezierPath *bezierPath = [UIBezierPath bezierPathWithRect:self.bounds];
    
    CGFloat showRadius = (radius * 0.65) + (self.hx_w * progressValue);
    CGFloat move_X = self.hx_w/ 2.0 + showRadius;
    
    [bezierPath moveToPoint:CGPointMake(move_X, self.hx_h/ 2)];
    CGPoint centerPoint = CGPointMake(self.hx_w/ 2.0, self.hx_h/ 2.0);
    [bezierPath addArcWithCenter:centerPoint
                          radius:showRadius
                      startAngle:0
                        endAngle:M_PI * 2
                       clockwise:YES];
    return bezierPath;
}
- (CGFloat)showRadius{
    CGFloat showRadius = MIN(self.hx_w, self.hx_h)/ 2.0;
    return showRadius;
}
- (UIView *)centerView {
    if (!_centerView) {
        _centerView = [[UIView alloc] init];
        _centerView.layer.masksToBounds = YES;
        _centerView.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.7];
        [_centerView addSubview:self.label];
    }
    return _centerView;
}
- (UILabel *)label {
    if (!_label) {
        _label = [[UILabel alloc] init];
        _label.textColor = [UIColor whiteColor];
        _label.textAlignment = NSTextAlignmentCenter;
        _label.font = [UIFont boldSystemFontOfSize:15];
    }
    return _label;
}
@end

