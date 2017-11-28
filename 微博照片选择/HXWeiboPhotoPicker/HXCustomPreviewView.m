//
//  HXCustomPreviewView.m
//  微博照片选择
//
//  Created by 洪欣 on 2017/10/31.
//  Copyright © 2017年 洪欣. All rights reserved.
//

#import "HXCustomPreviewView.h"
#define BOX_BOUNDS CGRectMake(0.0f, 0.0f, 150, 150.0f)

@interface HXCustomPreviewView ()<UIGestureRecognizerDelegate>
@property (strong, nonatomic) UIView *focusBox;
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
    
    [(AVCaptureVideoPreviewLayer *)self.layer setVideoGravity:AVLayerVideoGravityResizeAspectFill];
    
    _pinch = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(handlePinchGesture:)];
    _pinch.delegate = self;
    [self addGestureRecognizer:_pinch];
    
    _singleTapRecognizer =
    [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleSingleTap:)];
    
    [self addGestureRecognizer:_singleTapRecognizer];
    
    _focusBox = [self viewWithColor:[UIColor colorWithRed:0.102 green:0.636 blue:1.000 alpha:1.000]];
    [self addSubview:_focusBox];
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
- (void)handleSingleTap:(UIGestureRecognizer *)recognizer {
    CGPoint point = [recognizer locationInView:self];
    [self runBoxAnimationOnView:self.focusBox point:point];
    if ([self.delegate respondsToSelector:@selector(tappedToFocusAtPoint:)]) {
        [self.delegate tappedToFocusAtPoint:[self captureDevicePointForPoint:point]];
    }
}

- (void)runBoxAnimationOnView:(UIView *)view point:(CGPoint)point {
    view.center = point;
    view.hidden = NO;
    view.transform = CGAffineTransformIdentity;
    view.alpha = 1;
    [UIView animateWithDuration:0.15f
                          delay:0.0f
                        options:UIViewAnimationOptionCurveEaseInOut
                     animations:^{
                         view.layer.transform = CATransform3DMakeScale(0.5, 0.5, 1.0);
                     }
                     completion:^(BOOL complete) {
                         [UIView animateWithDuration:0.5 animations:^{
                             view.alpha = 0;
                         }];
                     }];
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

- (UIView *)viewWithColor:(UIColor *)color {
    UIView *view = [[UIView alloc] initWithFrame:BOX_BOUNDS];
    view.backgroundColor = [UIColor clearColor];
    view.layer.borderColor = color.CGColor;
    view.layer.borderWidth = 5.0f;
    view.hidden = YES;
    return view;
}
+ (Class)layerClass {
    return [AVCaptureVideoPreviewLayer class];
}

- (void)setSession:(AVCaptureSession *)session {
    [(AVCaptureVideoPreviewLayer *)self.layer setSession:session];
}

- (AVCaptureSession *)session {
    return [(AVCaptureVideoPreviewLayer *)self.layer session];
}

- (CGPoint)captureDevicePointForPoint:(CGPoint)point {
    AVCaptureVideoPreviewLayer *layer = (AVCaptureVideoPreviewLayer *)self.layer;
    return [layer captureDevicePointOfInterestForPoint:point];
}

@end
