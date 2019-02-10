//
//  UIView+HXExtension.h
//  照片选择器
//
//  Created by 洪欣 on 17/2/16.
//  Copyright © 2017年 洪欣. All rights reserved.
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

/* <HXAlbumListViewControllerDelegate> */
- (void)hx_presentAlbumListViewControllerWithManager:(HXPhotoManager *)manager delegate:(id)delegate;

/* <HXCustomCameraViewControllerDelegate> */
- (void)hx_presentCustomCameraViewControllerWithManager:(HXPhotoManager *)manager delegate:(id)delegate;

@end


@interface HXHUD : UIView
@property (assign, nonatomic) BOOL isImage;
- (instancetype)initWithFrame:(CGRect)frame imageName:(NSString *)imageName text:(NSString *)text;
- (void)showloading;
@end
