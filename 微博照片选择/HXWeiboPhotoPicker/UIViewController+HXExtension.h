//
//  UIViewController+HXExtension.h
//  微博照片选择
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

- (void)hx_presentAlbumListViewControllerWithManager:(HXPhotoManager *)manager done:(HXAlbumListViewControllerDidDoneBlock)done cancel:(HXAlbumListViewControllerDidCancelBlock)cancel;

/*  <HXCustomCameraViewControllerDelegate>
 *  delegate 不传则代表自己
 */
- (void)hx_presentCustomCameraViewControllerWithManager:(HXPhotoManager *)manager delegate:(id)delegate;

- (void)hx_presentCustomCameraViewControllerWithManager:(HXPhotoManager *)manager  done:(HXCustomCameraViewControllerDidDoneBlock)done cancel:(HXCustomCameraViewControllerDidCancelBlock)cancel;

- (BOOL)navigationBarWhetherSetupBackground;
@end
