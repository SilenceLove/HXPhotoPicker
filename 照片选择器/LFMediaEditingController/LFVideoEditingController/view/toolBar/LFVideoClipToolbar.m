//
//  LFVideoClipToolbar.m
//  LFMediaEditingController
//
//  Created by LamTsanFeng on 2017/7/18.
//  Copyright © 2017年 LamTsanFeng. All rights reserved.
//

#import "LFVideoClipToolbar.h"
#import "LFMediaEditingHeader.h"

@interface LFVideoClipToolbar ()

@property (nonatomic, strong) UIColor *oKButtonTitleColorNormal;

@end

@implementation LFVideoClipToolbar

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
    self.oKButtonTitleColorNormal = [UIColor colorWithRed:(26/255.0) green:(178/255.0) blue:(10/255.0) alpha:1.0];
    
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
    
    /** 右 */
    UIButton *rightButton = [UIButton buttonWithType:UIButtonTypeCustom];
    rightButton.frame = (CGRect){{CGRectGetWidth(self.frame)-size.width-margin,0}, size};
    [rightButton setImage:bundleEditImageNamed(@"EditImageConfirmBtn.png") forState:UIControlStateNormal];
    [rightButton setImage:bundleEditImageNamed(@"EditImageConfirmBtn_HL.png") forState:UIControlStateHighlighted];
    [rightButton setImage:bundleEditImageNamed(@"EditImageConfirmBtn_HL.png") forState:UIControlStateSelected];
    [rightButton addTarget:self action:@selector(clippingOk:) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:rightButton];
}

#pragma mark - action
- (void)clippingCancel:(UIButton *)button
{
    if ([self.delegate respondsToSelector:@selector(lf_videoClipToolbarDidCancel:)]) {
        [self.delegate lf_videoClipToolbarDidCancel:self];
    }
}

- (void)clippingOk:(UIButton *)button
{
    if ([self.delegate respondsToSelector:@selector(lf_videoClipToolbarDidFinish:)]) {
        [self.delegate lf_videoClipToolbarDidFinish:self];
    }
}

@end
