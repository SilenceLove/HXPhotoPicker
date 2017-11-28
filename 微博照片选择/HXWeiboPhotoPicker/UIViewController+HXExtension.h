//
//  UIViewController+HXExtension.h
//  微博照片选择
//
//  Created by 洪欣 on 2017/11/24.
//  Copyright © 2017年 洪欣. All rights reserved.
//

#import <UIKit/UIKit.h>
@class HXPhotoManager;
@interface UIViewController (HXExtension)
/* <HXAlbumListViewControllerDelegate> */
- (void)hx_presentAlbumListViewControllerWithManager:(HXPhotoManager *)manager delegate:(id)delegate;
/* <HXCustomCameraViewControllerDelegate> */
- (void)hx_presentCustomCameraViewControllerWithManager:(HXPhotoManager *)manager delegate:(id)delegate;
- (BOOL)navigationBarWhetherSetupBackground;
@end
