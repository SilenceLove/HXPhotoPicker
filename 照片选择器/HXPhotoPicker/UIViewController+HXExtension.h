//
//  UIViewController+HXExtension.h
//  照片选择器
//
//  Created by 洪欣 on 2017/11/24.
//  Copyright © 2017年 洪欣. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "HXAlbumListViewController.h"
#import "HXCustomCameraViewController.h" 

@interface UIViewController (HXExtension)
/*  <HXAlbumListViewControllerDelegate>
 *  delegate 不传则代表自己
 */
- (void)hx_presentAlbumListViewControllerWithManager:(HXPhotoManager *)manager delegate:(id)delegate;

/**
 跳转相册列表

 @param manager 照片管理者
 @param done 确定 NSArray<HXPhotoModel *> *allList - 所选的所有模型数组,
                 NSArray<HXPhotoModel *> *videoList - 所选的视频模型数组
                 NSArray<HXPhotoModel *> *photoList - 所选的照片模型数组
                 NSArray<UIImage *> *imageList - 所选的所有UIImage对象数组(当requestImageAfterFinishingSelection = YES 时才有值,内部会在点击确定的时候去请求已经选择资源的图片，为视频时则是视频封面)
                 BOOL original - 是否原图
                 HXAlbumListViewController *viewController 相册列表控制器
 @param cancel 取消
 */
- (void)hx_presentAlbumListViewControllerWithManager:(HXPhotoManager *)manager done:(HXAlbumListViewControllerDidDoneBlock)done cancel:(HXAlbumListViewControllerDidCancelBlock)cancel;

/*  <HXCustomCameraViewControllerDelegate>
 *  delegate 不传则代表自己
 */
- (void)hx_presentCustomCameraViewControllerWithManager:(HXPhotoManager *)manager delegate:(id)delegate;

- (void)hx_presentCustomCameraViewControllerWithManager:(HXPhotoManager *)manager  done:(HXCustomCameraViewControllerDidDoneBlock)done cancel:(HXCustomCameraViewControllerDidCancelBlock)cancel;

- (BOOL)navigationBarWhetherSetupBackground;
@end
