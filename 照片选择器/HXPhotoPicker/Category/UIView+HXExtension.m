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

- (CGFloat)hx_centerX
{
    return self.center.x;
}

- (void)setHx_centerX:(CGFloat)hx_centerX {
    CGPoint center = self.center;
    center.x = hx_centerX;
    self.center = center;
}

- (CGFloat)hx_centerY
{
    return self.center.y;
}

- (void)setHx_centerY:(CGFloat)hx_centerY {
    CGPoint center = self.center;
    center.y = hx_centerY;
    self.center = center;
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
    HXAlbumListViewController *vc = [[HXAlbumListViewController alloc] initWithManager:manager];
    vc.delegate = delegate ? delegate : (id)self; 
    HXCustomNavigationController *nav = [[HXCustomNavigationController alloc] initWithRootViewController:vc];
    nav.supportRotation = manager.configuration.supportRotation;
    nav.modalPresentationStyle = UIModalPresentationOverFullScreen;
    [self.hx_viewController presentViewController:nav animated:YES completion:nil];
}

- (void)hx_presentCustomCameraViewControllerWithManager:(HXPhotoManager *)manager delegate:(id)delegate {
    if(![UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
        [self.hx_viewController.view hx_showImageHUDText:[NSBundle hx_localizedStringForKey:@"无法使用相机!"]];
        return;
    }
    HXWeakSelf
    [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(BOOL granted) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (granted) {
                HXCustomCameraViewController *vc = [[HXCustomCameraViewController alloc] init];
                vc.delegate = delegate ? delegate : (id)weakSelf;
                vc.manager = manager;
                vc.isOutside = YES;
                HXCustomNavigationController *nav = [[HXCustomNavigationController alloc] initWithRootViewController:vc];
                nav.isCamera = YES;
                nav.supportRotation = manager.configuration.supportRotation;
                nav.modalPresentationStyle = UIModalPresentationOverFullScreen;
                [weakSelf.hx_viewController presentViewController:nav animated:YES completion:nil];
            }else {
                hx_showAlert(weakSelf.hx_viewController, [NSBundle hx_localizedStringForKey:@"无法使用相机"], [NSBundle hx_localizedStringForKey:@"请在设置-隐私-相机中允许访问相机"], [NSBundle hx_localizedStringForKey:@"取消"], [NSBundle hx_localizedStringForKey:@"设置"] , nil, ^{
                    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]];
                });
            }
        });
    }];
}

- (void)hx_showImageHUDText:(NSString *)text {
    CGFloat hudW = [UILabel hx_getTextWidthWithText:text height:15 fontSize:14];
    if (hudW > self.frame.size.width - 60) {
        hudW = self.frame.size.width - 60;
    }
    
    CGFloat hudH = [UILabel hx_getTextHeightWithText:text width:hudW fontSize:14];
    if (hudW < 100) {
        hudW = 100;
    }
    HXHUD *hud = [[HXHUD alloc] initWithFrame:CGRectMake(0, 0, hudW + 20, 110 + hudH - 15) imageName:@"hx_alert_failed" text:text];
    hud.alpha = 0;
    [self addSubview:hud];
    hud.center = CGPointMake(self.frame.size.width / 2, self.frame.size.height / 2);
    [UIView animateWithDuration:0.25 animations:^{
        hud.alpha = 1;
    }];
    [UIView cancelPreviousPerformRequestsWithTarget:self];
    [self performSelector:@selector(handleGraceTimer) withObject:nil afterDelay:1.5f inModes:@[NSRunLoopCommonModes]];
} 

- (void)hx_immediatelyShowLoadingHudWithText:(NSString *)text {
    [self hx_showLoadingHudWithText:text delay:0 immediately:YES];
}

- (void)hx_showLoadingHUDText:(NSString *)text {
    [self hx_showLoadingHUDText:text delay:0.f];
}

- (void)hx_showLoadingHUDText:(NSString *)text delay:(NSTimeInterval)delay {
    [self hx_showLoadingHudWithText:text delay:delay immediately:NO];
}

- (void)hx_showLoadingHudWithText:(NSString *)text delay:(NSTimeInterval)delay immediately:(BOOL)immediately {
    CGFloat hudW = [UILabel hx_getTextWidthWithText:text height:15 fontSize:14];
    if (hudW > self.frame.size.width - 60) {
        hudW = self.frame.size.width - 60;
    }
    
    CGFloat hudH = [UILabel hx_getTextHeightWithText:text width:hudW fontSize:14];
    CGFloat width = 110;
    CGFloat height = width + hudH - 15;
    if (!text) {
        width = 95;
        height = 95;
    }
    HXHUD *hud = [[HXHUD alloc] initWithFrame:CGRectMake(0, 0, width, height) imageName:nil text:text];
    [hud showloading];
    hud.alpha = 0;
    [self addSubview:hud];
    hud.center = CGPointMake(self.frame.size.width / 2, self.frame.size.height / 2);
    if (immediately) {
        hud.alpha = 1;
    }else {
        [UIView animateWithDuration:0.25 delay:delay options:0 animations:^{
            hud.alpha = 1;
        } completion:nil];
    }
}

- (void)hx_handleLoading {
    [self hx_handleLoading:YES];
} 
- (void)hx_handleLoading:(BOOL)animation {
    [self hx_handleLoading:animation duration:0.2f];
}
- (void)hx_handleLoading:(BOOL)animation duration:(NSTimeInterval)duration {
    [UIView cancelPreviousPerformRequestsWithTarget:self];
    for (UIView *view in self.subviews) {
        if ([view isKindOfClass:[HXHUD class]] && ![(HXHUD *)view isImage]) {
            if (animation) {
                [UIView animateWithDuration:duration animations:^{
                    view.alpha = 0;
                } completion:^(BOOL finished) {
                    [view removeFromSuperview];
                }];
            }else {
                [view removeFromSuperview];
            } 
        }
    }
}
- (void)hx_handleImageWithDelay:(NSTimeInterval)delay {
    if (delay) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self handleGraceTimer];
        });
    }else {
        [self handleGraceTimer];
    }
}
- (void)handleGraceTimer {
    [UIView cancelPreviousPerformRequestsWithTarget:self];
    for (UIView *view in self.subviews) {
        if ([view isKindOfClass:[HXHUD class]] && [(HXHUD *)view isImage]) {
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
    UIImage *image = self.imageName.length ? [UIImage hx_imageNamed:self.imageName] : nil;
    self.isImage = image;
    UIImageView *imageView = [[UIImageView alloc] initWithImage:image];
    [self addSubview:imageView];
    CGFloat imgW = imageView.image.size.width;
    if (imgW <= 0) imgW = 37;
    CGFloat imgH = imageView.image.size.height;
    if (imgH <= 0) imgH = 37;
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
    label.hx_x = 10;
    label.hx_y = CGRectGetMaxY(imageView.frame) + 10;
    label.hx_w = self.frame.size.width - 20;
    label.hx_h = [label hx_getTextHeight];
    if (self.text.length) {
        self.hx_h = CGRectGetMaxY(label.frame) + 20;
    }
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
