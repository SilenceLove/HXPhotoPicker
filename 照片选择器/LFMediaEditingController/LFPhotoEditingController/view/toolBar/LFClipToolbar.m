//
//  LFClipToolbar.m
//  LFImagePickerController
//
//  Created by LamTsanFeng on 2017/4/13.
//  Copyright © 2017年 LamTsanFeng. All rights reserved.
//

#import "LFClipToolbar.h"
#import "LFMediaEditingHeader.h"

@interface LFClipToolbar ()

@property (nonatomic, strong) UIImage *resetImage;
@property (nonatomic, strong) UIImage *resetImage_HL;
@property (nonatomic, strong) UIImage *rotateCCWImage;
@property (nonatomic, strong) UIImage *rotateCCWImage_HL;
@property (nonatomic, strong) UIImage *clampCCWImage;
@property (nonatomic, strong) UIImage *clampCCWImage_HL;

@property (nonatomic, strong) UIColor *oKButtonTitleColorNormal;

/** 重置按钮 */
@property (nonatomic, weak) UIButton *resetButton;
/** 长宽比例按钮 */
@property (nonatomic, weak) UIButton *clampButton;

@end

@implementation LFClipToolbar

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self customInit];
        self.enableReset = NO;
        self.selectAspectRatio = NO;
    }
    return self;
}

- (void)customInit
{
    self.oKButtonTitleColorNormal = [UIColor colorWithRed:(26/255.0) green:(178/255.0) blue:(10/255.0) alpha:1.0];
    
    self.rotateCCWImage = [self createRotateCWImageWithHighlighted:NO];
    self.rotateCCWImage_HL = [self createRotateCWImageWithHighlighted:YES];
    self.resetImage = [self createResetImageWithHighlighted:NO];
    self.resetImage_HL = [self createResetImageWithHighlighted:YES];
    self.clampCCWImage = [self createClampImageWithHighlighted:NO];
    self.clampCCWImage_HL = [self createClampImageWithHighlighted:YES];
    
    CGFloat rgb = 34 / 255.0;
    self.backgroundColor = [UIColor colorWithRed:rgb green:rgb blue:rgb alpha:0.7];
    self.alpha = 0.f;
    
    CGSize size = CGSizeMake(44, 44);
    CGFloat margin = 10.f;
    
    /** 左 */
    UIButton *leftButton = [UIButton buttonWithType:UIButtonTypeCustom];
    leftButton.frame = (CGRect){{margin,0}, size};
    [leftButton setImage:bundleEditImageNamed(@"EditImageCancelBtn.png") forState:UIControlStateNormal];
    [leftButton setImage:bundleEditImageNamed(@"EditImageCancelBtn_HL.png") forState:UIControlStateHighlighted];
    [leftButton setImage:bundleEditImageNamed(@"EditImageCancelBtn_HL.png") forState:UIControlStateSelected];
    [leftButton addTarget:self action:@selector(clippingCancel:) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:leftButton];
    
    /** 减去右按钮的剩余宽度 */
    CGFloat surplusWidth = CGRectGetWidth(self.frame)-(size.width+margin)-margin;
    CGFloat resetButtonX = surplusWidth/4+margin;
    CGFloat rotateButtonX = surplusWidth/4*2+margin;
    CGFloat clampButtonX = surplusWidth/4*3+margin;
    
    /** 还原 */
    UIButton *resetButton = [UIButton buttonWithType:UIButtonTypeCustom];
    resetButton.frame = (CGRect){{resetButtonX,0}, size};
    [resetButton setImage:self.resetImage forState:UIControlStateNormal];
    [resetButton setImage:self.resetImage_HL forState:UIControlStateHighlighted];
    [resetButton setImage:self.resetImage_HL forState:UIControlStateSelected];
    [resetButton addTarget:self action:@selector(clippingReset:) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:resetButton];
    self.resetButton = resetButton;
    
    /** 新增旋转 */
    UIButton *rotateButton = [UIButton buttonWithType:UIButtonTypeCustom];
    rotateButton.frame = (CGRect){{rotateButtonX,0}, size};
    [rotateButton setImage:self.rotateCCWImage forState:UIControlStateNormal];
    [rotateButton setImage:self.rotateCCWImage_HL forState:UIControlStateHighlighted];
    [rotateButton setImage:self.rotateCCWImage_HL forState:UIControlStateSelected];
    [rotateButton addTarget:self action:@selector(clippingRotate:) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:rotateButton];
    
    /** 新增长宽比例 */
    UIButton *clampButton = [UIButton buttonWithType:UIButtonTypeCustom];
    clampButton.frame = (CGRect){{clampButtonX,0}, size};
    [clampButton setImage:self.clampCCWImage forState:UIControlStateNormal];
    [clampButton setImage:self.clampCCWImage_HL forState:UIControlStateHighlighted];
    [clampButton setImage:self.clampCCWImage_HL forState:UIControlStateSelected];
    [clampButton addTarget:self action:@selector(clippingClamp:) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:clampButton];
    self.clampButton = clampButton;
    
    /** 右 */
    UIButton *rightButton = [UIButton buttonWithType:UIButtonTypeCustom];
    rightButton.frame = (CGRect){{CGRectGetWidth(self.frame)-size.width-margin,0}, size};
    [rightButton setImage:bundleEditImageNamed(@"EditImageConfirmBtn.png") forState:UIControlStateNormal];
    [rightButton setImage:bundleEditImageNamed(@"EditImageConfirmBtn_HL.png") forState:UIControlStateHighlighted];
    [rightButton setImage:bundleEditImageNamed(@"EditImageConfirmBtn_HL.png") forState:UIControlStateSelected];
    [rightButton addTarget:self action:@selector(clippingOk:) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:rightButton];
}

- (void)setEnableReset:(BOOL)enableReset
{
    _enableReset = enableReset;
    self.resetButton.enabled = enableReset;
}

- (void)setSelectAspectRatio:(BOOL)selectAspectRatio
{
    _selectAspectRatio = selectAspectRatio;
    self.clampButton.selected = selectAspectRatio;
}

#pragma mark - action
- (void)clippingCancel:(UIButton *)button
{
    _clickViewRect = button.frame;
    if ([self.delegate respondsToSelector:@selector(lf_clipToolbarDidCancel:)]) {
        [self.delegate lf_clipToolbarDidCancel:self];
    }
}

- (void)clippingReset:(UIButton *)button
{
    _clickViewRect = button.frame;
    if ([self.delegate respondsToSelector:@selector(lf_clipToolbarDidReset:)]) {
        [self.delegate lf_clipToolbarDidReset:self];
    }
}

- (void)clippingRotate:(UIButton *)button
{
    _clickViewRect = button.frame;
    if ([self.delegate respondsToSelector:@selector(lf_clipToolbarDidRotate:)]) {
        [self.delegate lf_clipToolbarDidRotate:self];
    }
}

- (void)clippingClamp:(UIButton *)button
{
    _clickViewRect = button.frame;
    if ([self.delegate respondsToSelector:@selector(lf_clipToolbarDidAspectRatio:)]) {
        [self.delegate lf_clipToolbarDidAspectRatio:self];
    }
}

- (void)clippingOk:(UIButton *)button
{
    _clickViewRect = button.frame;
    if ([self.delegate respondsToSelector:@selector(lf_clipToolbarDidFinish:)]) {
        [self.delegate lf_clipToolbarDidFinish:self];
    }
}

#pragma mark - draw image
- (UIImage *)createRotateCCWImageWithHighlighted:(BOOL)highlighted
{
    UIImage *rotateImage = nil;
    
    UIGraphicsBeginImageContextWithOptions((CGSize){18,21}, NO, 0.0f);
    {
        //// Rectangle 2 Drawing
        UIBezierPath* rectangle2Path = [UIBezierPath bezierPathWithRect: CGRectMake(0, 9, 12, 12)];
        highlighted ? [self.oKButtonTitleColorNormal setFill] : [UIColor.whiteColor setFill];
        [rectangle2Path fill];
        
        
        //// Rectangle 3 Drawing
        UIBezierPath* rectangle3Path = UIBezierPath.bezierPath;
        [rectangle3Path moveToPoint: CGPointMake(5, 3)];
        [rectangle3Path addLineToPoint: CGPointMake(10, 6)];
        [rectangle3Path addLineToPoint: CGPointMake(10, 0)];
        [rectangle3Path addLineToPoint: CGPointMake(5, 3)];
        [rectangle3Path closePath];
        highlighted ? [self.oKButtonTitleColorNormal setFill] : [UIColor.whiteColor setFill];
        [rectangle3Path fill];
        
        
        //// Bezier Drawing
        UIBezierPath* bezierPath = UIBezierPath.bezierPath;
        [bezierPath moveToPoint: CGPointMake(10, 3)];
        [bezierPath addCurveToPoint: CGPointMake(17.5, 11) controlPoint1: CGPointMake(15, 3) controlPoint2: CGPointMake(17.5, 5.91)];
        highlighted ? [self.oKButtonTitleColorNormal setStroke] : [UIColor.whiteColor setStroke];
        bezierPath.lineWidth = 1;
        [bezierPath stroke];
        rotateImage = UIGraphicsGetImageFromCurrentImageContext();
    }
    UIGraphicsEndImageContext();
    
    return rotateImage;
}

- (UIImage *)createRotateCWImageWithHighlighted:(BOOL)highlighted
{
    UIImage *rotateCCWImage = [self createRotateCCWImageWithHighlighted:highlighted];
    UIGraphicsBeginImageContextWithOptions(rotateCCWImage.size, NO, rotateCCWImage.scale);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextTranslateCTM(context, rotateCCWImage.size.width, rotateCCWImage.size.height);
    CGContextRotateCTM(context, M_PI);
    CGContextDrawImage(context,CGRectMake(0,0,rotateCCWImage.size.width,rotateCCWImage.size.height),rotateCCWImage.CGImage);
    UIImage *rotateCWImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return rotateCWImage;
}

- (UIImage *)createResetImageWithHighlighted:(BOOL)highlighted
{
    UIImage *resetImage = nil;
    
    UIGraphicsBeginImageContextWithOptions((CGSize){22,18}, NO, 0.0f);
    {
        
        //// Bezier 2 Drawing
        UIBezierPath* bezier2Path = UIBezierPath.bezierPath;
        [bezier2Path moveToPoint: CGPointMake(22, 9)];
        [bezier2Path addCurveToPoint: CGPointMake(13, 18) controlPoint1: CGPointMake(22, 13.97) controlPoint2: CGPointMake(17.97, 18)];
        [bezier2Path addCurveToPoint: CGPointMake(13, 16) controlPoint1: CGPointMake(13, 17.35) controlPoint2: CGPointMake(13, 16.68)];
        [bezier2Path addCurveToPoint: CGPointMake(20, 9) controlPoint1: CGPointMake(16.87, 16) controlPoint2: CGPointMake(20, 12.87)];
        [bezier2Path addCurveToPoint: CGPointMake(13, 2) controlPoint1: CGPointMake(20, 5.13) controlPoint2: CGPointMake(16.87, 2)];
        [bezier2Path addCurveToPoint: CGPointMake(6.55, 6.27) controlPoint1: CGPointMake(10.1, 2) controlPoint2: CGPointMake(7.62, 3.76)];
        [bezier2Path addCurveToPoint: CGPointMake(6, 9) controlPoint1: CGPointMake(6.2, 7.11) controlPoint2: CGPointMake(6, 8.03)];
        [bezier2Path addLineToPoint: CGPointMake(4, 9)];
        [bezier2Path addCurveToPoint: CGPointMake(4.65, 5.63) controlPoint1: CGPointMake(4, 7.81) controlPoint2: CGPointMake(4.23, 6.67)];
        [bezier2Path addCurveToPoint: CGPointMake(7.65, 1.76) controlPoint1: CGPointMake(5.28, 4.08) controlPoint2: CGPointMake(6.32, 2.74)];
        [bezier2Path addCurveToPoint: CGPointMake(13, 0) controlPoint1: CGPointMake(9.15, 0.65) controlPoint2: CGPointMake(11, 0)];
        [bezier2Path addCurveToPoint: CGPointMake(22, 9) controlPoint1: CGPointMake(17.97, 0) controlPoint2: CGPointMake(22, 4.03)];
        [bezier2Path closePath];
        highlighted ? [self.oKButtonTitleColorNormal setFill] : [UIColor.whiteColor setFill];
        [bezier2Path fill];
        
        
        //// Polygon Drawing
        UIBezierPath* polygonPath = UIBezierPath.bezierPath;
        [polygonPath moveToPoint: CGPointMake(5, 15)];
        [polygonPath addLineToPoint: CGPointMake(10, 9)];
        [polygonPath addLineToPoint: CGPointMake(0, 9)];
        [polygonPath addLineToPoint: CGPointMake(5, 15)];
        [polygonPath closePath];
        highlighted ? [self.oKButtonTitleColorNormal setFill] : [UIColor.whiteColor setFill];
        [polygonPath fill];
        
        
        resetImage = UIGraphicsGetImageFromCurrentImageContext();
    }
    UIGraphicsEndImageContext();
    
    return resetImage;
}

- (UIImage *)createClampImageWithHighlighted:(BOOL)highlighted
{
    UIImage *clampImage = nil;
    
    UIGraphicsBeginImageContextWithOptions((CGSize){22,16}, NO, 0.0f);
    {
        //// Color Declarations
        UIColor* outerBox = highlighted ? [self.oKButtonTitleColorNormal colorWithAlphaComponent:0.553] : [UIColor colorWithRed: 1 green: 1 blue: 1 alpha: 0.553];
        UIColor* innerBox = highlighted ? [self.oKButtonTitleColorNormal colorWithAlphaComponent:0.773] : [UIColor colorWithRed: 1 green: 1 blue: 1 alpha: 0.773];
        
        
        
        //// Rectangle Drawing
        UIBezierPath* rectanglePath = [UIBezierPath bezierPathWithRect: CGRectMake(0, 3, 13, 13)];
        highlighted ? [self.oKButtonTitleColorNormal setFill] : [UIColor.whiteColor setFill];
        [rectanglePath fill];
        
        
        //// Outer
        {
            //// Top Drawing
            UIBezierPath* topPath = [UIBezierPath bezierPathWithRect: CGRectMake(0, 0, 22, 2)];
            [outerBox setFill];
            [topPath fill];
            
            
            //// Side Drawing
            UIBezierPath* sidePath = [UIBezierPath bezierPathWithRect: CGRectMake(19, 2, 3, 14)];
            [outerBox setFill];
            [sidePath fill];
        }
        
        
        //// Rectangle 2 Drawing
        UIBezierPath* rectangle2Path = [UIBezierPath bezierPathWithRect: CGRectMake(14, 3, 4, 13)];
        [innerBox setFill];
        [rectangle2Path fill];
        
        
        clampImage = UIGraphicsGetImageFromCurrentImageContext();
    }
    UIGraphicsEndImageContext();
    
    return clampImage;
}


@end
