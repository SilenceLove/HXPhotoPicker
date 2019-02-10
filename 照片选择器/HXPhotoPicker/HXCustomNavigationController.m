//
//  HXCustomNavigationController.m
//  照片选择器
//
//  Created by 洪欣 on 2017/10/31.
//  Copyright © 2017年 洪欣. All rights reserved.
//

#import "HXCustomNavigationController.h"
#import "HXAlbumListViewController.h"
#import "HXPhotoViewController.h"
#import "HXPhotoTools.h"

@interface HXCustomNavigationController ()<HXAlbumListViewControllerDelegate, HXPhotoViewControllerDelegate>

@end

@implementation HXCustomNavigationController
- (instancetype)initWithManager:(HXPhotoManager *)manager {
    return [self initWithManager:manager delegate:nil doneBlock:nil cancelBlock:nil];
}
- (instancetype)initWithManager:(HXPhotoManager *)manager
                       delegate:(id<HXCustomNavigationControllerDelegate>)delegate {
    return [self initWithManager:manager delegate:delegate doneBlock:nil cancelBlock:nil];
}
- (instancetype)initWithManager:(HXPhotoManager *)manager
                      doneBlock:(viewControllerDidDoneBlock)doneBlock
                    cancelBlock:(viewControllerDidCancelBlock)cancelBlock {
    return [self initWithManager:manager delegate:nil doneBlock:doneBlock cancelBlock:cancelBlock];
}
- (instancetype)initWithManager:(HXPhotoManager *)manager
                       delegate:(id<HXCustomNavigationControllerDelegate>)delegate
                      doneBlock:(viewControllerDidDoneBlock)doneBlock
                    cancelBlock:(viewControllerDidCancelBlock)cancelBlock {
    manager.selectPhotoing = YES;
    [manager selectedListTransformBefore];
    if (!manager.cameraRollAlbumModel) {
        [manager preloadData];
    }
    
    if (manager.configuration.albumShowMode == HXPhotoAlbumShowModeDefault) {
        HXAlbumListViewController *vc = [[HXAlbumListViewController alloc] initWithManager:manager];
        self = [super initWithRootViewController:vc];
        if (self) {
            self.hx_delegate = delegate;
            self.manager = manager;
            self.doneBlock = doneBlock;
            self.cancelBlock = cancelBlock;
            vc.doneBlock = self.doneBlock;
            vc.cancelBlock = self.cancelBlock;
            vc.delegate = self;
            
        }
    }else if (manager.configuration.albumShowMode == HXPhotoAlbumShowModePopup) {
        HXPhotoViewController *vc = [[HXPhotoViewController alloc] init];
        vc.manager = manager;
        self = [super initWithRootViewController:vc];
        if (self) {
            self.hx_delegate = delegate;
            self.manager = manager;
            self.doneBlock = doneBlock;
            self.cancelBlock = cancelBlock;
            vc.doneBlock = self.doneBlock;
            vc.cancelBlock = self.cancelBlock;
            vc.delegate = self;
        }
    }
    return self;
}
- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

#pragma mark - < HXAlbumListViewControllerDelegate >
- (void)albumListViewControllerDidCancel:(HXAlbumListViewController *)albumListViewController {
    if ([self.hx_delegate respondsToSelector:@selector(photoNavigationViewControllerDidCancel:)]) {
        [self.hx_delegate photoNavigationViewControllerDidCancel:self];
    }
}
- (void)albumListViewController:(HXAlbumListViewController *)albumListViewController didDoneAllList:(NSArray<HXPhotoModel *> *)allList photos:(NSArray<HXPhotoModel *> *)photoList videos:(NSArray<HXPhotoModel *> *)videoList original:(BOOL)original {
    if ([self.hx_delegate respondsToSelector:@selector(photoNavigationViewController:didDoneAllList:photos:videos:original:)]) {
        [self.hx_delegate photoNavigationViewController:self didDoneAllList:allList photos:photoList videos:videoList original:original];
    }
}
#pragma mark - < HXPhotoViewControllerDelegate >
- (void)photoViewControllerDidCancel:(HXPhotoViewController *)photoViewController {
    if ([self.hx_delegate respondsToSelector:@selector(photoNavigationViewControllerDidCancel:)]) {
        [self.hx_delegate photoNavigationViewControllerDidCancel:self];
    }
}
- (void)photoViewController:(HXPhotoViewController *)photoViewController didDoneAllList:(NSArray<HXPhotoModel *> *)allList photos:(NSArray<HXPhotoModel *> *)photoList videos:(NSArray<HXPhotoModel *> *)videoList original:(BOOL)original {
    if ([self.hx_delegate respondsToSelector:@selector(photoNavigationViewController:didDoneAllList:photos:videos:original:)]) {
        [self.hx_delegate photoNavigationViewController:self didDoneAllList:allList photos:photoList videos:videoList original:original];
    }
}
- (BOOL)shouldAutorotate{
    if (self.isCamera) {
        return NO;
    }
    if (self.manager.configuration.supportRotation) {
        return YES;
    }else {
        return NO;
    }
}

//支持的方向

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    if (self.isCamera) {
        return UIInterfaceOrientationMaskPortrait;
    }
    if (self.manager.configuration.supportRotation) {
        return UIInterfaceOrientationMaskAll;
    }else {
        return UIInterfaceOrientationMaskPortrait;
    }
}

- (void)dealloc {
    self.manager.selectPhotoing = NO;
    [self.manager removeAllTempList];
    [self.manager removeAllAlbum];
    if (HXShowLog) NSSLog(@"dealloc");
}

@end
