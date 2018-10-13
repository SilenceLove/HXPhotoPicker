//
//  UIViewController+HXExtension.m
//  照片选择器
//
//  Created by 洪欣 on 2017/11/24.
//  Copyright © 2017年 洪欣. All rights reserved.
//

#import "UIViewController+HXExtension.h"
#import "HXPhotoPicker.h" 

@implementation UIViewController (HXExtension)
- (void)hx_presentAlbumListViewControllerWithManager:(HXPhotoManager *)manager delegate:(id)delegate {
    HXAlbumListViewController *vc = [[HXAlbumListViewController alloc] init];
    vc.delegate = delegate ? delegate : (id)self;
    vc.manager = manager;
    HXCustomNavigationController *nav = [[HXCustomNavigationController alloc] initWithRootViewController:vc];
    nav.supportRotation = manager.configuration.supportRotation;
    [self presentViewController:nav animated:YES completion:nil];
}
- (void)hx_presentSelectPhotoControllerWithManager:(HXPhotoManager *)manager didDone:(void (^)(NSArray<HXPhotoModel *> *, NSArray<HXPhotoModel *> *, NSArray<HXPhotoModel *> *, BOOL, UIViewController *, HXPhotoManager *))models imageList:(void (^)(NSArray<UIImage *> *, BOOL))images cancel:(void (^)(UIViewController *, HXPhotoManager *))cancel {
    
    viewControllerDidDoneBlock modelBlock = ^(NSArray<HXPhotoModel *> *allList, NSArray<HXPhotoModel *> *photoList, NSArray<HXPhotoModel *> *videoList, BOOL original, UIViewController *viewController, HXPhotoManager *manager) {
        if (models) {
            models(allList, photoList, videoList, original, viewController, manager);
        }
    };
    viewControllerDidDoneAllImageBlock imageBlock = ^(NSArray<UIImage *> *imageList, BOOL original, UIViewController *viewController, HXPhotoManager *manager) {
        if (images) {
            images(imageList, original);
        }
    };
    viewControllerDidCancelBlock cancelBlock = ^(UIViewController *viewController, HXPhotoManager *manager) {
        if (cancel) {
            cancel(viewController, manager);
        }
    };
    if (manager.configuration.albumShowMode == HXPhotoAlbumShowModeDefault) {
        HXAlbumListViewController *vc = [[HXAlbumListViewController alloc] init];
        vc.manager = manager;
        vc.doneBlock = modelBlock;
        vc.allImageBlock = imageBlock;
        vc.cancelBlock = cancelBlock;
        vc.delegate = (id)self;
        HXCustomNavigationController *nav = [[HXCustomNavigationController alloc] initWithRootViewController:vc];
        nav.supportRotation = manager.configuration.supportRotation;
        [self presentViewController:nav animated:YES completion:nil];
    }else if (manager.configuration.albumShowMode == HXPhotoAlbumShowModePopup) {
        HXDatePhotoViewController *vc = [[HXDatePhotoViewController alloc] init];
        vc.manager = manager;
        vc.doneBlock = modelBlock;
        vc.allImageBlock = imageBlock;
        vc.cancelBlock = cancelBlock;
        vc.delegate = (id)self;
        HXCustomNavigationController *nav = [[HXCustomNavigationController alloc] initWithRootViewController:vc];
        nav.supportRotation = manager.configuration.supportRotation;
        [self presentViewController:nav animated:YES completion:nil];
    }
    
}

- (void)hx_presentCustomCameraViewControllerWithManager:(HXPhotoManager *)manager delegate:(id)delegate {
    HXCustomCameraViewController *vc = [[HXCustomCameraViewController alloc] init];
    vc.delegate = delegate ? delegate : (id)self;
    vc.manager = manager;
    vc.isOutside = YES;
    HXCustomNavigationController *nav = [[HXCustomNavigationController alloc] initWithRootViewController:vc];
    nav.isCamera = YES;
    nav.supportRotation = manager.configuration.supportRotation;
    [self presentViewController:nav animated:YES completion:nil];
}

- (void)hx_presentCustomCameraViewControllerWithManager:(HXPhotoManager *)manager done:(HXCustomCameraViewControllerDidDoneBlock)done cancel:(HXCustomCameraViewControllerDidCancelBlock)cancel {
    HXCustomCameraViewController *vc = [[HXCustomCameraViewController alloc] init];
    vc.doneBlock = done;
    vc.cancelBlock = cancel;
    vc.manager = manager;
    vc.isOutside = YES;
    vc.delegate = (id)self;
    HXCustomNavigationController *nav = [[HXCustomNavigationController alloc] initWithRootViewController:vc];
    nav.isCamera = YES;
    nav.supportRotation = manager.configuration.supportRotation;
    [self presentViewController:nav animated:YES completion:nil];
}

- (BOOL)navigationBarWhetherSetupBackground {
    if ([self.navigationController.navigationBar backgroundImageForBarMetrics:UIBarMetricsDefault]) {
        return YES;
    }else if ([self.navigationController.navigationBar backgroundImageForBarMetrics:UIBarMetricsCompact]) {
        return YES;
    }else if ([self.navigationController.navigationBar backgroundImageForBarMetrics:UIBarMetricsDefaultPrompt]) {
        return YES;
    }else if ([self.navigationController.navigationBar backgroundImageForBarMetrics:UIBarMetricsCompactPrompt]) {
        return YES;
    }else if (self.navigationController.navigationBar.backgroundColor) {
        return YES;
    }
    return NO;
}
@end
