//
//  HXCustomNavigationController.m
//  HXPhotoPicker-Demo
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
    [manager selectedListTransformBefore];
    manager.selectPhotoing = YES;
    
    if (manager.configuration.albumShowMode == HXPhotoAlbumShowModeDefault) {
        HXAlbumListViewController *vc = [[HXAlbumListViewController alloc] initWithManager:manager];
        self = [super initWithRootViewController:vc];
        self.modalPresentationStyle = UIModalPresentationOverFullScreen;
        self.modalPresentationCapturesStatusBarAppearance = YES;
        if (self) {
            self.hx_delegate = delegate;
            self.manager = manager;
            [self requestAuthorization];
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
        self.modalPresentationStyle = UIModalPresentationOverFullScreen;
        self.modalPresentationCapturesStatusBarAppearance = YES;
        if (self) {
            self.hx_delegate = delegate;
            self.manager = manager;
            [self requestAuthorization];
            self.doneBlock = doneBlock;
            self.cancelBlock = cancelBlock;
            vc.doneBlock = self.doneBlock;
            vc.cancelBlock = self.cancelBlock;
            vc.delegate = self;
        }
    }
    return self;
}
- (void)requestAuthorization {
    HXWeakSelf
    [HXPhotoTools requestAuthorization:nil handler:^(PHAuthorizationStatus status) {
        if (status == PHAuthorizationStatusAuthorized) {
            [weakSelf requestModel];
        }
    }];
}
- (void)requestModel {
    if (self.manager.configuration.albumShowMode == HXPhotoAlbumShowModeDefault) {
        [self.view hx_showLoadingHUDText:nil];
    }
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        HXWeakSelf
        [self.manager getCameraRollAlbumCompletion:^(HXAlbumModel *albumModel) {
            weakSelf.cameraRollAlbumModel = albumModel;
            dispatch_async(dispatch_get_main_queue(), ^{
                if (weakSelf.requestCameraRollCompletion) {
                    weakSelf.requestCameraRollCompletion();
                }
            });
        }];
        [self.manager getAllAlbumModelWithCompletion:^(NSMutableArray<HXAlbumModel *> *albums) {
            weakSelf.albums = albums.mutableCopy;
            dispatch_async(dispatch_get_main_queue(), ^{
                if (weakSelf.requestAllAlbumCompletion) {
                    weakSelf.requestAllAlbumCompletion();
                }
            });
        }];
    });
}
- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
//    [[PHPhotoLibrary sharedPhotoLibrary] registerChangeObserver:self];
}
//- (void)photoLibraryDidChange:(PHChange *)changeInstance {
//    for (HXAlbumModel *albumModel in self.albums) {
//        PHFetchResultChangeDetails *collectionChanges = [changeInstance changeDetailsForFetchResult:albumModel.assetResult];
//        if (collectionChanges) {
//            if ([collectionChanges hasIncrementalChanges]) {
//                if (collectionChanges.removedObjects.count > 0) {
//                    PHFetchResult *result = collectionChanges.fetchResultAfterChanges;
//                    if ([albumModel.localIdentifier isEqualToString:[HXPhotoCommon photoCommon].cameraRollLocalIdentifier]) {
//                        [HXPhotoCommon photoCommon].cameraRollResult = result;
//                    }
//                    albumModel.assetResult = result;
//                    dispatch_async(dispatch_get_main_queue(), ^{
//                        if (self.photoLibraryDidChange) {
//                            self.photoLibraryDidChange(albumModel);
//                        }
//                    });
//                }
//            }
//        }
//    }
//}
#pragma mark - < HXAlbumListViewControllerDelegate >
- (void)albumListViewControllerCancelDismissCompletion:(HXAlbumListViewController *)albumListViewController {
    if ([self.hx_delegate respondsToSelector:@selector(photoNavigationViewControllerCancelDismissCompletion:)]) {
        [self.hx_delegate photoNavigationViewControllerCancelDismissCompletion:self];
    }
}
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
- (void)photoViewControllerFinishDismissCompletion:(HXPhotoViewController *)photoViewController {
    if ([self.hx_delegate respondsToSelector:@selector(photoNavigationViewControllerFinishDismissCompletion:)]) {
        [self.hx_delegate photoNavigationViewControllerFinishDismissCompletion:self];
    }
}
- (void)photoViewControllerCancelDismissCompletion:(HXPhotoViewController *)photoViewController {
    if ([self.hx_delegate respondsToSelector:@selector(photoNavigationViewControllerCancelDismissCompletion:)]) {
        [self.hx_delegate photoNavigationViewControllerCancelDismissCompletion:self];
    }
}
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

- (UIStatusBarStyle)preferredStatusBarStyle {
    return [self.topViewController preferredStatusBarStyle];
}
- (BOOL)prefersStatusBarHidden {
    return [self.topViewController prefersStatusBarHidden];
}
- (UIStatusBarAnimation)preferredStatusBarUpdateAnimation {
    return UIStatusBarAnimationFade;
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
    if (_manager) {
        self.manager.selectPhotoing = NO;
    }
//    [[PHPhotoLibrary sharedPhotoLibrary] unregisterChangeObserver:self];
}

@end
