//
//  UIView+HXExtension.h
//  HXPhotoPickerExample
//
//  Created by Silence on 17/2/16.
//  Copyright © 2017年 Silence. All rights reserved.
//

#import <UIKit/UIKit.h>

@class HXPhotoManager;
@interface UIView (HXExtension)

@property (assign, nonatomic) CGFloat hx_x;
@property (assign, nonatomic) CGFloat hx_y;
@property (assign, nonatomic) CGFloat hx_w;
@property (assign, nonatomic) CGFloat hx_h;
@property (assign, nonatomic) CGFloat hx_centerX;
@property (assign, nonatomic) CGFloat hx_centerY;
@property (assign, nonatomic) CGSize hx_size;
@property (assign, nonatomic) CGPoint hx_origin;

/**
 获取当前视图的控制器
 
 @return 控制器
 */
- (UIViewController *)hx_viewController;

- (void)hx_showImageHUDText:(NSString *)text;
- (void)hx_showLoadingHUDText:(NSString *)text;
- (void)hx_showLoadingHUDText:(NSString *)text delay:(NSTimeInterval)delay;
- (void)hx_immediatelyShowLoadingHudWithText:(NSString *)text;
- (void)hx_handleLoading;
- (void)hx_handleLoading:(BOOL)animation;
- (void)hx_handleLoading:(BOOL)animation duration:(NSTimeInterval)duration;
- (void)hx_handleImageWithDelay:(NSTimeInterval)delay;
- (void)hx_handleImageWithAnimation:(BOOL)animation;
- (void)hx_handleGraceTimer;

/* <HXAlbumListViewControllerDelegate> */
- (void)hx_presentAlbumListViewControllerWithManager:(HXPhotoManager *)manager delegate:(id)delegate DEPRECATED_MSG_ATTRIBUTE("Use UIViewController+HXEXtension 'hx_presentSelectPhotoControllerWithManager:' instead");

/* <HXCustomCameraViewControllerDelegate> */
- (void)hx_presentCustomCameraViewControllerWithManager:(HXPhotoManager *)manager delegate:(id)delegate DEPRECATED_MSG_ATTRIBUTE("Use UIViewController+HXEXtension 'hx_presentCustomCameraViewControllerWithManager:' instead");

/// 设置圆角。使用自动布局，需要在layoutsubviews 中使用
/// @param radius 圆角尺寸
/// @param corner 圆角位置
- (void)hx_radiusWithRadius:(CGFloat)radius corner:(UIRectCorner)corner;
- (UIImage *)hx_captureImageAtFrame:(CGRect)rect;
- (UIColor *)hx_colorOfPoint:(CGPoint)point;
@end


@interface HXHUD : UIView
@property (assign, nonatomic) BOOL isImage;
@property (copy, nonatomic) NSString *text;
- (instancetype)initWithFrame:(CGRect)frame imageName:(NSString *)imageName text:(NSString *)text;
- (void)showloading;
@end
