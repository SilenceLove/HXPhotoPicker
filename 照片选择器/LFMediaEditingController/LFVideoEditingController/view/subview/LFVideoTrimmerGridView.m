//
//  LFVideoTrimmerGridView.m
//  LFMediaEditingController
//
//  Created by LamTsanFeng on 2017/7/18.
//  Copyright © 2017年 LamTsanFeng. All rights reserved.
//

#import "LFVideoTrimmerGridView.h"
#import "LFResizeControl.h"
#import "LFVideoTrimmerGridLayer.h"
#import "LFGridMaskLayer.h"
#import "UIView+LFMEFrame.h"


@interface LFResizeImageControl : LFResizeControl

@property (nonatomic, strong) UIImage *image;
@property (strong, nonatomic, nullable) UIColor *color;
@property (nonatomic, assign) CGRect imageRect;

@end

@implementation LFResizeImageControl

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        _imageRect = self.bounds;
    }
    return self;
}

- (void)setImage:(UIImage *)image
{
    _image = image;
    [self setNeedsDisplay];
}

- (void)setColor:(UIColor *)color {
    _color = color;
    [self setNeedsDisplay];
}

- (void)drawRect:(CGRect)rect
{
    // Drawing code
    
    if (self.image) {
        [self.image drawInRect:self.imageRect];
    } else {
        //// Frames
        CGRect bubbleFrame = self.imageRect;
        
        //// Rounded Rectangle Drawing
        CGRect roundedRectangleRect = CGRectMake(CGRectGetMinX(bubbleFrame), CGRectGetMinY(bubbleFrame), CGRectGetWidth(bubbleFrame), CGRectGetHeight(bubbleFrame));
        UIBezierPath *roundedRectanglePath = [UIBezierPath bezierPathWithRoundedRect: roundedRectangleRect byRoundingCorners: UIRectCornerTopLeft | UIRectCornerBottomLeft | UIRectCornerTopRight | UIRectCornerBottomRight cornerRadii: CGSizeMake(3, 3)];
        
        [roundedRectanglePath closePath];
        [self.color setFill];
        [roundedRectanglePath fill];
        
        
        CGFloat lineWidth = 1.5f;
        CGRect decoratingRect = CGRectMake(CGRectGetMinX(bubbleFrame)+CGRectGetWidth(bubbleFrame)/3-lineWidth/2, (CGRectGetHeight(bubbleFrame)-15.f)/2, lineWidth, 15.f);
        UIBezierPath *decoratingPath = [UIBezierPath bezierPathWithRoundedRect:decoratingRect byRoundingCorners: UIRectCornerTopLeft | UIRectCornerBottomLeft | UIRectCornerBottomRight | UIRectCornerTopRight cornerRadii: CGSizeMake(1, 1)];
        [decoratingPath closePath];
        [[UIColor colorWithWhite:0.5 alpha:1.f] setFill];
        [decoratingPath fill];
        
        CGRect decoratingRect1 = decoratingRect;
        decoratingRect1.origin.x += CGRectGetWidth(bubbleFrame)/3;
        UIBezierPath *decoratingPath1 = [UIBezierPath bezierPathWithRoundedRect:decoratingRect1 byRoundingCorners: UIRectCornerTopLeft | UIRectCornerBottomLeft | UIRectCornerBottomRight | UIRectCornerTopRight cornerRadii: CGSizeMake(1, 1)];
        [decoratingPath1 closePath];
        [[UIColor colorWithWhite:0.5 alpha:1.f] setFill];
        [decoratingPath1 fill];
    }
}

@end


/** 可控范围 */
const CGFloat kVideoTrimmerGridControlWidth = 25.f;
const CGFloat kVideoTrimmerGridLayerLineWidth = 2.f;

@interface LFVideoTrimmerGridView () <lf_resizeConrolDelegate>

@property (nonatomic, weak) LFResizeImageControl *leftCornerView;
@property (nonatomic, weak) LFResizeImageControl *rightCornerView;
/** 边框 */
@property (nonatomic, weak) LFVideoTrimmerGridLayer *gridLayer;
/** 背景 */
@property (nonatomic, weak) LFVideoTrimmerGridLayer *bg_gridLayer;
/** 遮罩 */
@property (nonatomic, weak) LFGridMaskLayer *gridMaskLayer;
/** 进度 */
@property (nonatomic, weak) UIView *slider;

@property (nonatomic, assign) CGRect initialRect;

@end

@implementation LFVideoTrimmerGridView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self customInit];
    }
    return self;
}

- (void)customInit
{
    /** 进度 */
    UIView *slider = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 2, self.bounds.size.height)];
    slider.backgroundColor = [UIColor colorWithWhite:1.f alpha:0.8f];
    slider.userInteractionEnabled = NO;
    [self addSubview:slider];
    _slider = slider;
    
    /** 背景 */
    LFVideoTrimmerGridLayer *bg_gridLayer = [[LFVideoTrimmerGridLayer alloc] init];
    bg_gridLayer.frame = self.bounds;
    bg_gridLayer.lineWidth = kVideoTrimmerGridLayerLineWidth;
    bg_gridLayer.bgColor = [UIColor clearColor];
    bg_gridLayer.gridColor = [UIColor colorWithWhite:1.f alpha:0.5f];
    bg_gridLayer.gridRect = self.bounds;
    bg_gridLayer.hidden = YES;
    [self.layer addSublayer:bg_gridLayer];
    self.bg_gridLayer = bg_gridLayer;
    
    /** 遮罩 */
    LFGridMaskLayer *gridMaskLayer = [[LFGridMaskLayer alloc] init];
    gridMaskLayer.frame = self.bounds;
    gridMaskLayer.maskColor = [UIColor colorWithWhite:.0f alpha:.5f].CGColor;
    [self.layer addSublayer:gridMaskLayer];
    self.gridMaskLayer = gridMaskLayer;
    
    /** 边框 */
    LFVideoTrimmerGridLayer *gridLayer = [[LFVideoTrimmerGridLayer alloc] init];
    gridLayer.frame = self.bounds;
    gridLayer.lineWidth = kVideoTrimmerGridLayerLineWidth;
    gridLayer.bgColor = [UIColor clearColor];
    gridLayer.gridColor = [UIColor whiteColor];
    [self.layer addSublayer:gridLayer];
    self.gridLayer = gridLayer;
    
    /** 左右控制器 */
    self.leftCornerView = [self createResizeControl];
    self.rightCornerView = [self createResizeControl];
    
    self.gridRect = self.bounds;
    self.controlMinWidth = self.frame.size.width * 0.33f;
    self.controlMaxWidth = self.frame.size.width;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    self.gridLayer.frame = self.bounds;
    self.bg_gridLayer.frame = self.bounds;
    self.gridMaskLayer.frame = self.bounds;
    
    CGRect rect = self.gridRect;
    
    self.leftCornerView.frame = (CGRect){CGRectGetMinX(rect) - CGRectGetWidth(self.leftCornerView.bounds) / 2, (CGRectGetHeight(rect) - CGRectGetHeight(self.leftCornerView.bounds)) / 2, self.leftCornerView.bounds.size};
    self.rightCornerView.frame = (CGRect){CGRectGetMaxX(rect) - CGRectGetWidth(self.rightCornerView.bounds) / 2, (CGRectGetHeight(rect) - CGRectGetHeight(self.rightCornerView.bounds)) / 2, self.rightCornerView.bounds.size};
}

- (void)setProgress:(double)progress
{
    if (isnan(progress) || progress < 0) {
        return;
    }
    _progress = progress;
    _slider.x = progress*self.width;
}

- (void)setHiddenProgress:(BOOL)hidden
{
    _slider.hidden = hidden;
}

#pragma mark - lf_resizeConrolDelegate

- (void)lf_resizeConrolDidBeginResizing:(LFResizeControl *)resizeConrol
{
    [self bringSubviewToFront:resizeConrol];
    
    self.bg_gridLayer.hidden = NO;
    self.initialRect = self.gridRect;
    
    if ([self.delegate respondsToSelector:@selector(lf_videoTrimmerGridViewDidBeginResizing:)]) {
        [self.delegate lf_videoTrimmerGridViewDidBeginResizing:self];
    }
}
- (void)lf_resizeConrolDidResizing:(LFResizeControl *)resizeConrol
{
    CGRect gridRect = [self cropRectMakeWithResizeControlView:resizeConrol];
    
    if (!CGRectEqualToRect(_gridRect, gridRect)) {
        [self setGridRect:gridRect animated:NO];
        if ([self.delegate respondsToSelector:@selector(lf_videoTrimmerGridViewDidResizing:)]) {
            [self.delegate lf_videoTrimmerGridViewDidResizing:self];
        }
    }
}
- (void)lf_resizeConrolDidEndResizing:(LFResizeControl *)resizeConrol
{
    self.bg_gridLayer.hidden = YES;
    if ([self.delegate respondsToSelector:@selector(lf_videoTrimmerGridViewDidEndResizing:)]) {
        [self.delegate lf_videoTrimmerGridViewDidEndResizing:self];
    }
}

- (void)setGridRect:(CGRect)gridRect
{
    [self setGridRect:gridRect animated:NO];
}

- (void)setGridRect:(CGRect)gridRect animated:(BOOL)animated
{
    if (!CGRectEqualToRect(_gridRect, gridRect)) {
        _gridRect = gridRect;
        [self.gridLayer setGridRect:gridRect animated:animated];
        self.gridMaskLayer.maskRect = self.gridRect;
        [self setNeedsLayout];
    }
}

#pragma mark - private
- (LFResizeImageControl *)createResizeControl
{
    LFResizeImageControl *control = [[LFResizeImageControl alloc] initWithFrame:(CGRect){CGPointMake(0, -kVideoTrimmerGridLayerLineWidth/2), CGSizeMake(kVideoTrimmerGridControlWidth, self.bounds.size.height+kVideoTrimmerGridLayerLineWidth)}];
    control.color = [UIColor whiteColor];
    CGFloat imageWidth = 10.f;
    control.imageRect = CGRectMake((control.frame.size.width-imageWidth)/2, 0, imageWidth, control.frame.size.height);
    control.delegate = self;
    [self addSubview:control];
    return control;
}

- (CGRect)cropRectMakeWithResizeControlView:(LFResizeControl *)resizeControlView
{
    CGRect rect = self.gridRect;
    
    
    if (resizeControlView == self.leftCornerView) {
        rect = CGRectMake(CGRectGetMinX(self.initialRect) + resizeControlView.translation.x,
                          CGRectGetMinY(self.initialRect),
                          CGRectGetWidth(self.initialRect) - resizeControlView.translation.x,
                          CGRectGetHeight(self.initialRect));
    } else if (resizeControlView == self.rightCornerView) {
        rect = CGRectMake(CGRectGetMinX(self.initialRect),
                          CGRectGetMinY(self.initialRect),
                          CGRectGetWidth(self.initialRect) + resizeControlView.translation.x,
                          CGRectGetHeight(self.initialRect));
    }
    /** ps：
     此处判断 不能使用CGRectGet开头的方法，计算会有问题；
     当rect = (origin = (x = 50, y = 618), size = (width = 61, height = -488)) 时，
     CGRectGetMaxY(rect) = 618；CGRectGetHeight(rect) = 488
     */
    
    if (resizeControlView == self.leftCornerView) {
        /** 限制宽度 超出 最大限度 */
        if (rect.size.width+FLT_EPSILON > self.controlMaxWidth+FLT_EPSILON || rect.origin.x < 0) {
            CGFloat diff = rect.origin.x < 0 ? (rect.origin.x-0) : (self.controlMaxWidth - rect.size.width);
            rect.origin.x -= diff;
            rect.size.width += diff;
        } else
        /** 限制宽度 超出 最小限度 */
        if (rect.size.width+FLT_EPSILON < self.controlMinWidth+FLT_EPSILON) {
            CGFloat diff = self.controlMinWidth - rect.size.width;
            rect.origin.x -= diff;
            rect.size.width += diff;
        }
    } else if (resizeControlView == self.rightCornerView) {
        /** 限制宽度 超出 最大限度 */
        if (rect.size.width+FLT_EPSILON > self.controlMaxWidth+FLT_EPSILON || rect.origin.x+FLT_EPSILON+rect.size.width+FLT_EPSILON > self.controlMaxWidth+FLT_EPSILON) {
            CGFloat diff = rect.size.width+FLT_EPSILON > self.controlMaxWidth+FLT_EPSILON ? (self.controlMaxWidth - rect.size.width) : (self.controlMaxWidth-(rect.origin.x+FLT_EPSILON+rect.size.width+FLT_EPSILON));
            rect.size.width += diff;
        } else
        /** 限制宽度 超出 最小限度 */
        if (rect.size.width+FLT_EPSILON < self.controlMinWidth+FLT_EPSILON) {
            CGFloat diff = self.controlMinWidth - rect.size.width;
            rect.size.width += diff;
        }
    }
    
    
    return rect;
}

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event
{
    UIView *view = [super hitTest:point withEvent:event];
    if (self == view) {
        return nil;
    }
    return view;
}

- (BOOL)pointInside:(CGPoint)point withEvent:(nullable UIEvent *)event
{
    BOOL isHit = [super pointInside:point withEvent:event];
    
    if (!isHit) {
        return (CGRectContainsPoint(self.leftCornerView.frame, point) || CGRectContainsPoint(self.rightCornerView.frame, point));
    }
    
    return isHit;
}

@end
