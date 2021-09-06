//
//  HXPhotoLimitView.m
//  HXPhotoPickerExample
//
//  Created by Slience on 2021/9/6.
//  Copyright © 2021 洪欣. All rights reserved.
//

#import "HXPhotoLimitView.h"
#import "NSBundle+HXPhotoPicker.h"
#import "UIColor+HXExtension.h"
#import "UIImage+HXExtension.h"
#import "UIView+HXExtension.h"
#import "UILabel+HXExtension.h"
#import "HXPhotoTools.h"

@interface HXPhotoLimitView()
@property (strong, nonatomic) UIVisualEffectView *bgView;
@property (strong, nonatomic) UILabel *textLb;
@property (strong, nonatomic) UIButton *settingButton;
@property (strong, nonatomic) UIButton *closeButton;
@end

@implementation HXPhotoLimitView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self addSubview:self.bgView];
        [self addSubview:self.textLb];
        [self addSubview:self.settingButton];
        [self addSubview:self.closeButton];
        self.layer.cornerRadius = 7;
        self.layer.masksToBounds = YES;
    }
    return self;
}
- (void)setTextColor:(UIColor *)color {
    self.textLb.textColor = color;
}
- (void)setSettingColor:(UIColor *)color {
    [self.settingButton setTitleColor:color forState:UIControlStateNormal];
}
- (void)setCloseColor:(UIColor *)color {
    self.closeButton.imageView.tintColor = color;
    self.closeButton.tintColor = color;
}
- (void)setBlurEffectStyle:(UIBlurEffectStyle)style {
    UIBlurEffect *effect = [UIBlurEffect effectWithStyle:style];
    self.bgView.effect = effect;
}
- (void)layoutSubviews {
    [super layoutSubviews];
    self.bgView.frame = self.bounds;
    CGFloat settingTextWidth = [self.settingButton.titleLabel hx_getTextWidth];
    self.textLb.frame = CGRectMake(10, 0, self.hx_w - settingTextWidth - 35, self.hx_h);
    CGFloat textWidth = self.textLb.hx_getTextWidth;
    if (self.textLb.hx_w > textWidth) {
        self.textLb.hx_w = textWidth;
    }
    CGFloat settingX = CGRectGetMaxX(self.textLb.frame) + 5;
    self.settingButton.frame = CGRectMake(settingX, 0, settingTextWidth, self.hx_h);
    self.closeButton.hx_size = CGSizeMake(18, 18);
    self.closeButton.hx_x = self.hx_w - self.closeButton.hx_w;
    self.closeButton.hx_y = 0;
}
- (UIVisualEffectView *)bgView {
    if (!_bgView) {
        UIBlurEffect *effect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleDark];
        _bgView = [[UIVisualEffectView alloc] initWithEffect:effect];
    }
    return _bgView;
}
- (UILabel *)textLb {
    if (!_textLb) {
        _textLb = [[UILabel alloc] init];
        _textLb.text = [NSBundle hx_localizedStringForKey:@"仅可访问部分照片，建议开启「所有照片」"];
        _textLb.font = [UIFont systemFontOfSize:14];
        _textLb.textColor = [UIColor hx_colorWithHexStr:@"#999999"];
        _textLb.numberOfLines = 0;
        _textLb.adjustsFontSizeToFitWidth = YES;
    }
    return _textLb;
}

- (UIButton *)settingButton {
    if (!_settingButton) {
        _settingButton = [UIButton buttonWithType:UIButtonTypeSystem];
        [_settingButton setTitle:[NSBundle hx_localizedStringForKey:@"去设置"] forState:UIControlStateNormal];
        [_settingButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        _settingButton.titleLabel.font = [UIFont systemFontOfSize:14];
        [_settingButton addTarget:self action:@selector(didSettingButtonClick) forControlEvents:UIControlEventTouchUpInside];
        _settingButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
    }
    return _settingButton;
}
- (void)didSettingButtonClick {
    [HXPhotoTools openSetting];
}
- (UIButton *)closeButton {
    if (!_closeButton) {
        _closeButton = [UIButton buttonWithType:UIButtonTypeSystem];
        [_closeButton setImage:[UIImage hx_imageNamed:@"hx_compose_delete"] forState:UIControlStateNormal];
        [_closeButton addTarget:self action:@selector(didCloseButtonClick) forControlEvents:UIControlEventTouchUpInside];
        _closeButton.imageView.tintColor = [UIColor whiteColor];
        _closeButton.tintColor = [UIColor whiteColor];
    }
    return _closeButton;
}
- (void)didCloseButtonClick {
    [UIView animateWithDuration:0.25 animations:^{
        self.alpha = 0;
    } completion:^(BOOL finished) {
        [self removeFromSuperview];
    }];
}
@end
