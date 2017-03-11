//
//  UIView+HXExtension.m
//  微博照片选择
//
//  Created by 洪欣 on 17/2/16.
//  Copyright © 2017年 洪欣. All rights reserved.
//

#import "UIView+HXExtension.h"
#import "HXPhotoTools.h"

@implementation UIView (HXExtension)

- (void)showImageHUDText:(NSString *)text
{
    CGFloat hudW = [HXPhotoTools getTextWidth:text withHeight:15 fontSize:14];
    if (hudW > self.frame.size.width - 60) {
        hudW = self.frame.size.width - 60;
    }
    HXHUD *hud = [[HXHUD alloc] initWithFrame:CGRectMake(0, 0, hudW + 20, 110) imageName:@"alert_failed_icon@2x.png" text:text];
    hud.alpha = 0;
    hud.tag = 1008611;
    [self addSubview:hud];
    hud.center = CGPointMake(self.frame.size.width / 2, self.frame.size.height / 2);
    [UIView animateWithDuration:0.25 animations:^{
        hud.alpha = 1;
    }];
    [self performSelector:@selector(handleGraceTimer) withObject:nil afterDelay:1.5f inModes:@[NSRunLoopCommonModes]];
}

- (void)showLoadingHUDText:(NSString *)text
{
    CGFloat hudW = [HXPhotoTools getTextWidth:text withHeight:15 fontSize:14];
    if (hudW > self.frame.size.width - 60) {
        hudW = self.frame.size.width - 60;
    }
    HXHUD *hud = [[HXHUD alloc] initWithFrame:CGRectMake(0, 0, 110, 110) imageName:@"alert_failed_icon@2x.png" text:text];
    [hud showloading];
    hud.alpha = 0;
    hud.tag = 10086;
    [self addSubview:hud];
    hud.center = CGPointMake(self.frame.size.width / 2, self.frame.size.height / 2);
    [UIView animateWithDuration:0.25 animations:^{
        hud.alpha = 1;
    }];
}

- (void)handleLoading
{
    [UIView cancelPreviousPerformRequestsWithTarget:self];
    for (UIView *view in self.subviews) {
        if (view.tag == 10086) {
            [UIView animateWithDuration:0.25 animations:^{
                view.alpha = 0;
            } completion:^(BOOL finished) {
                [view removeFromSuperview];
            }];
        }
    }
}

- (void)handleGraceTimer
{
    [UIView cancelPreviousPerformRequestsWithTarget:self];
    for (UIView *view in self.subviews) {
        if (view.tag == 1008611) {
            [UIView animateWithDuration:0.25 animations:^{
                view.alpha = 0;
            } completion:^(BOOL finished) {
                [view removeFromSuperview];
            }];
        }
    }
}

@end

@interface HXHUD ()
@property (copy, nonatomic) NSString *imageName;
@property (copy, nonatomic) NSString *text;
@property (weak, nonatomic) UIImageView *imageView;
@end

@implementation HXHUD

- (instancetype)initWithFrame:(CGRect)frame imageName:(NSString *)imageName text:(NSString *)text
{
    self = [super initWithFrame:frame];
    if (self) {
        self.text = text;
        self.imageName = imageName;
        self.layer.masksToBounds = YES;
        self.layer.cornerRadius = 5;
        self.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.85];
        [self setup];
    }
    return self;
}

- (void)setup
{
    UIImageView *imageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:self.imageName]];
    [self addSubview:imageView];
    CGFloat imgW = imageView.image.size.width;
    CGFloat imgH = imageView.image.size.height;
    CGFloat imgCenterX = self.frame.size.width / 2;
    CGFloat imgCenterY = self.frame.size.height / 2 - 12.5;
    imageView.frame = CGRectMake(0, 0, imgW, imgH);
    imageView.center = CGPointMake(imgCenterX, imgCenterY);
    self.imageView = imageView;
    
    UILabel *label = [[UILabel alloc] init];
    label.text = self.text;
    label.textColor = [UIColor whiteColor];
    label.textAlignment = NSTextAlignmentCenter;
    label.font = [UIFont systemFontOfSize:14];
    [self addSubview:label];
    CGFloat labelX = 10;
    CGFloat labelY = CGRectGetMaxY(imageView.frame) + 10;
    CGFloat labelW = self.frame.size.width - 20;
    CGFloat labelH = 15;
    label.frame = CGRectMake(labelX, labelY, labelW, labelH);
}

- (void)showloading
{
    UIActivityIndicatorView *loading = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    [loading startAnimating];
    [self addSubview:loading];
    loading.frame = self.imageView.frame;
    self.imageView.hidden = YES;
}
@end
