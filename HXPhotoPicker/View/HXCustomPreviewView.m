//
//  HXCustomPreviewView.m
//  HXPhotoPickerExample
//
//  Created by Silence on 2017/10/31.
//  Copyright © 2017年 Silence. All rights reserved.
//

#import "HXCustomPreviewView.h"
#import "UIImage+HXExtension.h"
#define HXCustomCameraViewBOX_BOUNDS CGRectMake(0.0f, 0.0f, 100, 100)

@interface HXCustomPreviewView ()<UIGestureRecognizerDelegate>
@property (strong, nonatomic) UIImageView *focusBox;
@property (strong, nonatomic) UITapGestureRecognizer *singleTapRecognizer;
@property (strong, nonatomic) UIPinchGestureRecognizer *pinch;
@property (strong, nonatomic) UISwipeGestureRecognizer *leftSwipe;
@property (strong, nonatomic) UISwipeGestureRecognizer *rightSwipe;
@end

@implementation HXCustomPreviewView

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setupView];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
    if (self) {
        [self setupView];
    }
    return self;
} 

- (void)setupView {
    self.beginGestureScale = 1.0f;
    self.effectiveScale = 1.0f;
    
    _pinch = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(handlePinchGesture:)];
    _pinch.delegate = self;
    [self addGestureRecognizer:_pinch];
    
    _singleTapRecognizer =
    [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleSingleTap:)];
    
    [self addGestureRecognizer:_singleTapRecognizer];
    
    _focusBox = [[UIImageView alloc] initWithFrame:HXCustomCameraViewBOX_BOUNDS];
    _focusBox.hidden = YES;
    _focusBox.image = [[UIImage hx_imageNamed:@"hx_camera_focusbox"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    [self addSubview:_focusBox];
}
- (void)setThemeColor:(UIColor *)themeColor {
    _themeColor = themeColor;
    self.focusBox.tintColor = themeColor;
}
- (UISwipeGestureRecognizer *)leftSwipe {
    if (!_leftSwipe) {
        _leftSwipe = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(leftSwipeClick:)];
        _leftSwipe.direction = UISwipeGestureRecognizerDirectionLeft;
    }
    return _leftSwipe;
}
- (UISwipeGestureRecognizer *)rightSwipe {
    if (!_rightSwipe) {
        _rightSwipe = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(rightSwipeClick:)];
        _rightSwipe.direction = UISwipeGestureRecognizerDirectionRight;
    }
    return _rightSwipe;
}
- (void)addSwipeGesture {
    [self addGestureRecognizer:self.leftSwipe];
    [self addGestureRecognizer:self.rightSwipe];
}
- (void)leftSwipeClick:(UISwipeGestureRecognizer *)swipe {
    if (swipe.direction == UISwipeGestureRecognizerDirectionLeft) {
        if ([self.delegate respondsToSelector:@selector(didLeftSwipeClick)]) {
            [self.delegate didLeftSwipeClick];
        }
    }
}

- (void)rightSwipeClick:(UISwipeGestureRecognizer *)swipe {
    if (swipe.direction == UISwipeGestureRecognizerDirectionRight) {
        if ([self.delegate respondsToSelector:@selector(didRightSwipeClick)]) {
            [self.delegate didRightSwipeClick];
        }
    }
}
//缩放手势 用于调整焦距
- (void)handlePinchGesture:(UIPinchGestureRecognizer *)recognizer{
    if (recognizer.state == UIGestureRecognizerStateChanged) {
        self.effectiveScale = self.beginGestureScale * recognizer.scale;
        
        if (self.effectiveScale > self.maxScale) {
            self.effectiveScale = self.maxScale;
        }
        if (self.effectiveScale < 1.0){
            self.effectiveScale = 1.0;
        }
        if ([self.delegate respondsToSelector:@selector(pinchGestureScale:)]) {
            [self.delegate pinchGestureScale:self.effectiveScale];
        }
    }
}

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer {
    if ( [gestureRecognizer isKindOfClass:[UIPinchGestureRecognizer class]] ) {
        self.beginGestureScale = self.effectiveScale;
    }
    return YES;
}

- (void)firstFocusing {
    CGPoint point = CGPointMake(self.frame.size.width / 2, self.frame.size.height / 2);
    [self runBoxAnimationOnView:self.focusBox point:point];
    if ([self.delegate respondsToSelector:@selector(tappedToFocusAtPoint:)]) {
        [self.delegate tappedToFocusAtPoint:[self captureDevicePointForPoint:point]];
    }
}
- (void)handleSingleTap:(UIGestureRecognizer *)recognizer {
    CGPoint point = [recognizer locationInView:self];
    [self runBoxAnimationOnView:self.focusBox point:point];
    if ([self.delegate respondsToSelector:@selector(tappedToFocusAtPoint:)]) {
        [self.delegate tappedToFocusAtPoint:[self captureDevicePointForPoint:point]];
    }
}

- (void)runBoxAnimationOnView:(UIView *)view point:(CGPoint)point {
    [UIView cancelPreviousPerformRequestsWithTarget:self];
    [view.layer removeAnimationForKey:@"boxAnimation"];
    view.center = point;
    view.hidden = NO;
    view.transform = CGAffineTransformIdentity;
    view.alpha = 1;
    
    
    CAKeyframeAnimation *scaleAnim = [CAKeyframeAnimation animationWithKeyPath:@"transform.scale"];
    scaleAnim.duration = 1.0f;
    scaleAnim.values = @[@(0.8),@(1.0),@(0.85),@(1.0),@(0.85),@(0.9),@(1.0)];
    
    
    CAKeyframeAnimation *opacityAnim = [CAKeyframeAnimation animationWithKeyPath:@"opacity"];
    opacityAnim.duration = 1.0f;
    opacityAnim.values = @[@(0.6),@(1.0),@(0.6),@(1.0),@(0.6),@(0.9),@(0.7),@(0)];
    
    CAAnimationGroup *annimaGroup = [CAAnimationGroup animation];
    annimaGroup.animations = @[scaleAnim, opacityAnim];
    annimaGroup.duration = 1.0f;
    annimaGroup.removedOnCompletion = NO;
    annimaGroup.fillMode = kCAFillModeForwards;
    [view.layer addAnimation:annimaGroup forKey:@"boxAnimation"];
    [self performSelector:@selector(animationDidStop) withObject:nil afterDelay:1.0];
}
- (void)animationDidStop {
    self.focusBox.hidden = YES;
}
- (void)setTapToFocusEnabled:(BOOL)enabled {
    _tapToFocusEnabled = enabled;
    self.singleTapRecognizer.enabled = enabled;
}

- (void)setTapToExposeEnabled:(BOOL)enabled {
    _tapToExposeEnabled = enabled;
    self.singleTapRecognizer.enabled = enabled;
}

- (void)setPinchToZoomEnabled:(BOOL)pinchToZoomEnabled {
    _pinchToZoomEnabled = pinchToZoomEnabled;
    self.pinch.enabled = pinchToZoomEnabled;
}
- (void)setupPreviewLayer {
    self.previewLayer.frame = self.bounds;
    [self.layer insertSublayer:self.previewLayer atIndex:0];
}

- (AVCaptureSession *)session {
    return self.previewLayer.session;
}

- (CGPoint)captureDevicePointForPoint:(CGPoint)point {
    return [self.previewLayer captureDevicePointOfInterestForPoint:point];
}

@end
