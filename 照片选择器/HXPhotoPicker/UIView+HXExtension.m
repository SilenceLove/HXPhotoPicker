//
//  UIView+HXExtension.m
//  照片选择器
//
//  Created by 洪欣 on 17/2/16.
//  Copyright © 2017年 洪欣. All rights reserved.
//

#import "UIView+HXExtension.h"
#import "HXPhotoPicker.h"

@implementation UIView (HXExtension)
- (void)setHx_x:(CGFloat)hx_x
{
    CGRect frame = self.frame;
    frame.origin.x = hx_x;
    self.frame = frame;
}

- (CGFloat)hx_x
{
    return self.frame.origin.x;
}

- (void)setHx_y:(CGFloat)hx_y
{
    CGRect frame = self.frame;
    frame.origin.y = hx_y;
    self.frame = frame;
}

- (CGFloat)hx_y
{
    return self.frame.origin.y;
}

- (void)setHx_w:(CGFloat)hx_w
{
    CGRect frame = self.frame;
    frame.size.width = hx_w;
    self.frame = frame;
}

- (CGFloat)hx_w
{
    return self.frame.size.width;
}

- (void)setHx_h:(CGFloat)hx_h
{
    CGRect frame = self.frame;
    frame.size.height = hx_h;
    self.frame = frame;
}

- (CGFloat)hx_h
{
    return self.frame.size.height;
}

- (void)setHx_size:(CGSize)hx_size
{
    CGRect frame = self.frame;
    frame.size = hx_size;
    self.frame = frame;
}

- (CGSize)hx_size
{
    return self.frame.size;
}

- (void)setHx_origin:(CGPoint)hx_origin
{
    CGRect frame = self.frame;
    frame.origin = hx_origin;
    self.frame = frame;
}

- (CGPoint)hx_origin
{
    return self.frame.origin;
}

/**
 获取当前视图的控制器
 
 @return 控制器
 */
- (UIViewController*)hx_viewController {
    for (UIView* next = [self superview]; next; next = next.superview) {
        UIResponder* nextResponder = [next nextResponder];
        if ([nextResponder isKindOfClass:[UINavigationController class]] || [nextResponder isKindOfClass:[UIViewController class]]) {
            return (UIViewController*)nextResponder;
        }
    }
    return nil;
}

- (void)hx_presentAlbumListViewControllerWithManager:(HXPhotoManager *)manager delegate:(id)delegate {
    HXAlbumListViewController *vc = [[HXAlbumListViewController alloc] init];
    vc.delegate = delegate ? delegate : (id)self;
    vc.manager = manager;
    HXCustomNavigationController *nav = [[HXCustomNavigationController alloc] initWithRootViewController:vc];
    nav.supportRotation = manager.configuration.supportRotation;
    [self.hx_viewController presentViewController:nav animated:YES completion:nil];
}

- (void)hx_presentCustomCameraViewControllerWithManager:(HXPhotoManager *)manager delegate:(id)delegate {
    HXCustomCameraViewController *vc = [[HXCustomCameraViewController alloc] init];
    vc.delegate = delegate ? delegate : (id)self;
    vc.manager = manager;
    vc.isOutside = YES;
    HXCustomNavigationController *nav = [[HXCustomNavigationController alloc] initWithRootViewController:vc];
    nav.isCamera = YES;
    nav.supportRotation = manager.configuration.supportRotation;
    [self.hx_viewController presentViewController:nav animated:YES completion:nil];
}

- (void)showImageHUDText:(NSString *)text {
    CGFloat hudW = [HXPhotoTools getTextWidth:text height:15 fontSize:14];
    if (hudW > self.frame.size.width - 60) {
        hudW = self.frame.size.width - 60;
    }
    CGFloat hudH = [HXPhotoTools getTextHeight:text width:hudW fontSize:14];
    if (hudW < 100) {
        hudW = 100;
    }
    HXHUD *hud = [[HXHUD alloc] initWithFrame:CGRectMake(0, 0, hudW + 20, 110 + hudH - 15) imageName:@"hx_alert_failed@2x.png" text:text];
    hud.alpha = 0;
    hud.tag = 1008611;
    [self addSubview:hud];
    hud.center = CGPointMake(self.frame.size.width / 2, self.frame.size.height / 2);
    [UIView animateWithDuration:0.25 animations:^{
        hud.alpha = 1;
    }];
    [UIView cancelPreviousPerformRequestsWithTarget:self];
    [self performSelector:@selector(handleGraceTimer) withObject:nil afterDelay:1.5f inModes:@[NSRunLoopCommonModes]];
}

- (void)showLoadingHUDText:(NSString *)text {
    CGFloat hudW = [HXPhotoTools getTextWidth:text height:15 fontSize:14];
    if (hudW > self.frame.size.width - 60) {
        hudW = self.frame.size.width - 60;
    }
    CGFloat hudH = [HXPhotoTools getTextHeight:text width:hudW fontSize:14];
    CGFloat width = 110;
    CGFloat height = width + hudH - 15;
    if (!text) {
        width = 95;
        height = 95;
    }
    HXHUD *hud = [[HXHUD alloc] initWithFrame:CGRectMake(0, 0, width, height) imageName:@"hx_alert_failed@2x.png" text:text];
    [hud showloading];
    hud.alpha = 0;
    hud.tag = 10086;
    [self addSubview:hud];
    hud.center = CGPointMake(self.frame.size.width / 2, self.frame.size.height / 2);
    [UIView animateWithDuration:0.25 animations:^{
        hud.alpha = 1;
    }];
}

- (void)handleLoading {
    [UIView cancelPreviousPerformRequestsWithTarget:self];
    for (UIView *view in self.subviews) {
        if (view.tag == 10086) {
            [UIView animateWithDuration:0.2f animations:^{
                view.alpha = 0;
            } completion:^(BOOL finished) {
                [view removeFromSuperview];
            }];
        }
    }
}

- (void)handleGraceTimer {
    [UIView cancelPreviousPerformRequestsWithTarget:self];
    for (UIView *view in self.subviews) {
        if (view.tag == 1008611) {
            [UIView animateWithDuration:0.2f animations:^{
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

- (instancetype)initWithFrame:(CGRect)frame imageName:(NSString *)imageName text:(NSString *)text {
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

- (void)setup {
    UIImageView *imageView = [[UIImageView alloc] initWithImage:[HXPhotoTools hx_imageNamed:self.imageName]];
    [self addSubview:imageView];
    CGFloat imgW = imageView.image.size.width;
    CGFloat imgH = imageView.image.size.height;
    CGFloat imgCenterX = self.frame.size.width / 2;
    imageView.frame = CGRectMake(0, 20, imgW, imgH);
    imageView.center = CGPointMake(imgCenterX, imageView.center.y);
    self.imageView = imageView;
    
    UILabel *label = [[UILabel alloc] init];
    label.text = self.text;
    label.textColor = [UIColor whiteColor];
    label.textAlignment = NSTextAlignmentCenter;
    label.font = [UIFont systemFontOfSize:14];
    label.numberOfLines = 0;
    [self addSubview:label];
    CGFloat labelX = 10;
    CGFloat labelY = CGRectGetMaxY(imageView.frame) + 10;
    CGFloat labelW = self.frame.size.width - 20;
    CGFloat labelH = [HXPhotoTools getTextHeight:self.text width:labelW fontSize:14];
    label.frame = CGRectMake(labelX, labelY, labelW, labelH);
}

- (void)showloading {
    UIActivityIndicatorView *loading = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    [loading startAnimating];
    [self addSubview:loading];
    if (self.text) {
        loading.frame = self.imageView.frame;
    }else {
        loading.frame = self.bounds;
    }
    self.imageView.hidden = YES;
}
@end
