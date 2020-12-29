//
//  UIView+HXExtension.m
//  HXPhotoPickerExample
//
//  Created by Silence on 17/2/16.
//  Copyright © 2017年 Silence. All rights reserved.
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
    nav.modalPresentationCapturesStatusBarAppearance = YES;
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
                nav.modalPresentationCapturesStatusBarAppearance = YES;
                [weakSelf.hx_viewController presentViewController:nav animated:YES completion:nil];
            }else {
                [HXPhotoTools showUnusableCameraAlert:weakSelf.hx_viewController];
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
    hud.transform = CGAffineTransformMakeScale(0.4, 0.4);
    [UIView animateWithDuration:0.25 delay:0 usingSpringWithDamping:0.5 initialSpringVelocity:1.0 options:0 animations:^{
        hud.alpha = 1;
        hud.transform = CGAffineTransformIdentity;
    } completion:nil];
    [UIView cancelPreviousPerformRequestsWithTarget:self];
    [self performSelector:@selector(hx_handleGraceTimer) withObject:nil afterDelay:1.75f inModes:@[NSRunLoopCommonModes]];
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
        hud.transform = CGAffineTransformMakeScale(0.4, 0.4);
        [UIView animateWithDuration:0.25 delay:delay usingSpringWithDamping:0.5 initialSpringVelocity:1 options:0 animations:^{
            hud.alpha = 1;
            hud.transform = CGAffineTransformIdentity;
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
                    view.transform = CGAffineTransformMakeScale(0.5, 0.5);
                } completion:^(BOOL finished) {
                    [view removeFromSuperview];
                }];
            }else {
                [view removeFromSuperview];
            } 
        }
    }
}
- (void)hx_handleImageWithAnimation:(BOOL)animation {
    [UIView cancelPreviousPerformRequestsWithTarget:self];
    for (UIView *view in self.subviews) {
        if ([view isKindOfClass:[HXHUD class]] && [(HXHUD *)view isImage]) {
            if (animation) {
                [UIView animateWithDuration:0.25f animations:^{
                    view.alpha = 0;
                    view.transform = CGAffineTransformMakeScale(0.5, 0.5);
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
            [self hx_handleGraceTimer];
        });
    }else {
        [self hx_handleGraceTimer];
    }
}
- (void)hx_handleGraceTimer {
    [self hx_handleImageWithAnimation:YES];
}
/**
 圆角
 使用自动布局，需要在layoutsubviews 中使用
 @param radius 圆角尺寸
 @param corner 圆角位置
 */
- (void)hx_radiusWithRadius:(CGFloat)radius corner:(UIRectCorner)corner {
#ifdef __IPHONE_11_0
    if (@available(iOS 11.0, *)) {
        self.layer.cornerRadius = radius;
        self.layer.maskedCorners = (CACornerMask)corner;
#else
    if ((NO)) {
#endif
    } else {
        UIBezierPath * path = [UIBezierPath bezierPathWithRoundedRect:self.bounds byRoundingCorners:corner cornerRadii:CGSizeMake(radius, radius)];
        CAShapeLayer *maskLayer = [[CAShapeLayer alloc] init];
        maskLayer.frame = self.bounds;
        maskLayer.path = path.CGPath;
        self.layer.mask = maskLayer;
    }
}

- (UIImage *)hx_captureImageAtFrame:(CGRect)rect {
    
    UIImage* image = nil;
    
    if (/* DISABLES CODE */ (YES)) {
        CGSize size = self.bounds.size;
        CGPoint point = self.bounds.origin;
        if (!CGRectEqualToRect(CGRectZero, rect)) {
            size = rect.size;
            point = CGPointMake(-rect.origin.x, -rect.origin.y);
        }
        @autoreleasepool {
            UIGraphicsBeginImageContextWithOptions(size, NO, 0.0);
            [self drawViewHierarchyInRect:(CGRect){point, self.bounds.size} afterScreenUpdates:YES];
            image = UIGraphicsGetImageFromCurrentImageContext();
            UIGraphicsEndImageContext();
        }
        
    } else {
        
            BOOL translateCTM = !CGRectEqualToRect(CGRectZero, rect);
        
            if (!translateCTM) {
                rect = self.frame;
            }
        
            /** 参数取整，否则可能会出现1像素偏差 */
            /** 有小数部分才调整差值 */
#define lfme_fixDecimal(d) ((fmod(d, (int)d)) > 0.59f ? ((int)(d+0.5)*1.f) : (((fmod(d, (int)d)) < 0.59f && (fmod(d, (int)d)) > 0.1f) ? ((int)(d)*1.f+0.5f) : (int)(d)*1.f))
            rect.origin.x = lfme_fixDecimal(rect.origin.x);
            rect.origin.y = lfme_fixDecimal(rect.origin.y);
            rect.size.width = lfme_fixDecimal(rect.size.width);
            rect.size.height = lfme_fixDecimal(rect.size.height);
#undef lfme_fixDecimal
            CGSize size = rect.size;
        
        @autoreleasepool {
            //1.开启上下文
            UIGraphicsBeginImageContextWithOptions(size, NO, [UIScreen mainScreen].scale);
            
            CGContextRef context = UIGraphicsGetCurrentContext();
            
            if (translateCTM) {
                /** 移动上下文 */
                CGContextTranslateCTM(context, -rect.origin.x, -rect.origin.y);
            }
            //2.绘制图层
            [self.layer renderInContext: context];
            
            //3.从上下文中获取新图片
            image = UIGraphicsGetImageFromCurrentImageContext();
            
            //4.关闭图形上下文
            UIGraphicsEndImageContext();
        }
    }
    return image;
}

- (UIColor *)hx_colorOfPoint:(CGPoint)point {
    unsigned char pixel[4] = {0};
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate(pixel, 1, 1, 8, 4, colorSpace, kCGImageAlphaPremultipliedLast);
    
    CGContextTranslateCTM(context, -point.x, -point.y);
    
    [self.layer renderInContext:context];
    
    CGContextRelease(context);
    CGColorSpaceRelease(colorSpace);
    
    UIColor *color = [UIColor colorWithRed:pixel[0]/255.0 green:pixel[1]/255.0 blue:pixel[2]/255.0 alpha:pixel[3]/255.0];
    
    return color;
}
@end

@interface HXHUD ()
@property (copy, nonatomic) NSString *imageName;
@property (strong, nonatomic) UIImageView *imageView;
@property (strong, nonatomic) UIVisualEffectView *visualEffectView;
@property (strong, nonatomic) UILabel *titleLb;
@property (strong, nonatomic) UIActivityIndicatorView *loading;
@end

@implementation HXHUD

- (instancetype)initWithFrame:(CGRect)frame imageName:(NSString *)imageName text:(NSString *)text {
    self = [super initWithFrame:frame];
    if (self) {
        _text = text;
        self.imageName = imageName;
        self.layer.masksToBounds = YES;
        self.layer.cornerRadius = 5;
        [self addSubview:self.visualEffectView];
        [self setup];
    }
    return self;
}

- (void)setup {
    UIImage *image = self.imageName.length ? [UIImage hx_imageNamed:self.imageName] : nil;
    self.isImage = image != nil;
    if ([HXPhotoCommon photoCommon].isDark) {
        image = [image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    }
    self.imageView = [[UIImageView alloc] initWithImage:image];
    [self addSubview:self.imageView];
    if ([HXPhotoCommon photoCommon].isDark) {
        self.imageView.tintColor = [UIColor colorWithRed:0.1 green:0.1 blue:0.1 alpha:1];
    }
    
    self.titleLb = [[UILabel alloc] init];
    self.titleLb.text = self.text;
    self.titleLb.textColor = [HXPhotoCommon photoCommon].isDark ? [UIColor colorWithRed:0.1 green:0.1 blue:0.1 alpha:1] : [UIColor whiteColor];
    self.titleLb.textAlignment = NSTextAlignmentCenter;
    self.titleLb.font = [UIFont systemFontOfSize:14];
    self.titleLb.numberOfLines = 0;
    [self addSubview:self.titleLb];
}
- (void)setText:(NSString *)text {
    _text = text;
    self.titleLb.text = text;
}
- (void)layoutSubviews {
    [super layoutSubviews];
    
    CGFloat imgW = self.imageView.image.size.width;
    if (imgW <= 0) imgW = 37;
    CGFloat imgH = self.imageView.image.size.height;
    if (imgH <= 0) imgH = 37;
    CGFloat imgCenterX = self.frame.size.width / 2;
    self.imageView.frame = CGRectMake(0, 20, imgW, imgH);
    self.imageView.center = CGPointMake(imgCenterX, self.imageView.center.y);
    
    self.titleLb.hx_x = 10;
    self.titleLb.hx_y = CGRectGetMaxY(self.imageView.frame) + 10;
    self.titleLb.hx_w = self.frame.size.width - 20;
    self.titleLb.hx_h = [self.titleLb hx_getTextHeight];
    if (self.text.length) {
        self.hx_h = CGRectGetMaxY(self.titleLb.frame) + 20;
    }
    if (_loading) {
        if (self.text) {
            self.loading.frame = self.imageView.frame;
        }else {
            self.loading.frame = self.bounds;
        }
    }
}
- (UIActivityIndicatorView *)loading {
    if (!_loading) {
        _loading = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
#ifdef __IPHONE_13_0
        if ([HXPhotoCommon photoCommon].isDark) {
            if (@available(iOS 13.0, *)) {
                _loading.activityIndicatorViewStyle = UIActivityIndicatorViewStyleLarge;
            } else {
                _loading.activityIndicatorViewStyle = UIActivityIndicatorViewStyleWhiteLarge;
            }
            _loading.color = [UIColor colorWithRed:0.1 green:0.1 blue:0.1 alpha:1];
        }
#endif
        [_loading startAnimating];
    }
    return _loading;
}
- (void)showloading {
    [self addSubview:self.loading];
    self.imageView.hidden = YES;
}

- (UIVisualEffectView *)visualEffectView {
    if (!_visualEffectView) {
        if ([HXPhotoCommon photoCommon].isDark) {
            UIBlurEffect *blurEffrct =[UIBlurEffect effectWithStyle:UIBlurEffectStyleLight];
            _visualEffectView = [[UIVisualEffectView alloc]initWithEffect:blurEffrct];
        }else {
            UIBlurEffect *blurEffrct =[UIBlurEffect effectWithStyle:UIBlurEffectStyleDark];
            _visualEffectView = [[UIVisualEffectView alloc]initWithEffect:blurEffrct];
        }
        _visualEffectView.frame = self.bounds;
    }
    return _visualEffectView;
}
@end
