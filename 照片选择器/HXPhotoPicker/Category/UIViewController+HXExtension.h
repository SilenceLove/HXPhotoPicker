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
- (void)hx_presentAlbumListViewControllerWithManager:(HXPhotoManager *_Nullable)manager delegate:(id _Nullable )delegate DEPRECATED_MSG_ATTRIBUTE("Use 'hx_presentSelectPhotoControllerWithManager:' instead");

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
- (void)hx_presentSelectPhotoControllerWithManager:(HXPhotoManager *_Nullable)manager
                                           didDone:(void (^_Nullable)(NSArray<HXPhotoModel *> * _Nullable allList, NSArray<HXPhotoModel *> * _Nullable photoList, NSArray<HXPhotoModel *> * _Nullable videoList, BOOL isOriginal, UIViewController * _Nullable viewController, HXPhotoManager * _Nullable manager))models
                                            cancel:(void (^_Nullable)(UIViewController * _Nullable viewController, HXPhotoManager * _Nullable manager))cancel;

/// 跳转预览照片界面
/// @param manager 照片管理者
/// @param previewStyle 预览样式
/// @param currentIndex 当前预览的下标
/// @param photoView 照片展示视图 - 没有就不传
- (void)hx_presentPreviewPhotoControllerWithManager:(HXPhotoManager *_Nullable)manager
                                       previewStyle:(HXPhotoViewPreViewShowStyle)previewStyle
                                       currentIndex:(NSUInteger)currentIndex
                                          photoView:(HXPhotoView * _Nullable)photoView;

/*  <HXCustomCameraViewControllerDelegate>
 *  delegate 不传则代表自己
 */
- (void)hx_presentCustomCameraViewControllerWithManager:(HXPhotoManager *_Nullable)manager delegate:(id _Nullable )delegate;

- (void)hx_presentCustomCameraViewControllerWithManager:(HXPhotoManager *_Nullable)manager done:(HXCustomCameraViewControllerDidDoneBlock _Nonnull )done cancel:(HXCustomCameraViewControllerDidCancelBlock _Nullable )cancel;

- (BOOL)hx_navigationBarWhetherSetupBackground;
@end
