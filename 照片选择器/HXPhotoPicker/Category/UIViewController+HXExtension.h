//
//  UIViewController+HXExtension.h
//  照片选择器
//
//  Created by 洪欣 on 2017/11/24.
//  Copyright © 2017年 洪欣. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "HXCustomCameraViewController.h"
#import "HXPhotoView.h"

@class HXPhotoView;
@interface UIViewController (HXExtension)
/*  <HXAlbumListViewControllerDelegate>
 *  delegate 不传则代表自己
 */
- (void)hx_presentAlbumListViewControllerWithManager:(HXPhotoManager *)manager delegate:(id)delegate DEPRECATED_MSG_ATTRIBUTE("Use 'hx_presentSelectPhotoControllerWithManager:' instead");

/**
 跳转相册列表

 @param manager 照片管理者
 @param models  NSArray<HXPhotoModel *> *allList - 所选的所有模型数组,
                NSArray<HXPhotoModel *> *videoList - 所选的视频模型数组
                NSArray<HXPhotoModel *> *photoList - 所选的照片模型数组
                BOOL original - 是否原图
                UIViewController *viewController 相册列表控制器
 @param cancel 取消选择
 */
- (void)hx_presentSelectPhotoControllerWithManager:(HXPhotoManager *)manager didDone:(void (^)(NSArray<HXPhotoModel *> *allList, NSArray<HXPhotoModel *> *photoList, NSArray<HXPhotoModel *> *videoList, BOOL isOriginal, UIViewController *viewController, HXPhotoManager *manager))models cancel:(void (^)(UIViewController *viewController, HXPhotoManager *manager))cancel;

/**
 跳转预览照片界面

 @param manager 照片管理者
 @param models 模型数组
 @param currentModel 当前预览的模型
 @param photoView 照片展示视图
 */

/// 跳转预览照片界面
/// @param manager 照片管理者
/// @param previewStyle 预览样式
/// @param currentIndex 当前预览的下标
/// @param photoView 照片展示视图 - 没有就不传
- (void)hx_presentPreviewPhotoControllerWithManager:(HXPhotoManager *)manager
                                       previewStyle:(HXPhotoViewPreViewShowStyle)previewStyle
                                       currentIndex:(NSUInteger)currentIndex
                                          photoView:(HXPhotoView * _Nullable)photoView;

/*  <HXCustomCameraViewControllerDelegate>
 *  delegate 不传则代表自己
 */
- (void)hx_presentCustomCameraViewControllerWithManager:(HXPhotoManager *)manager delegate:(id)delegate;

- (void)hx_presentCustomCameraViewControllerWithManager:(HXPhotoManager *)manager done:(HXCustomCameraViewControllerDidDoneBlock)done cancel:(HXCustomCameraViewControllerDidCancelBlock)cancel;

- (BOOL)hx_navigationBarWhetherSetupBackground;
@end
