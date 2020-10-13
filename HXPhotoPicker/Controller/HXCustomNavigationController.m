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
@property (assign, nonatomic) BOOL didPresentImagePicker;
@property (assign, nonatomic) BOOL initialAuthorization;
@property (strong, nonatomic) NSTimer *timer;
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
    self.initialAuthorization = NO;
    HXWeakSelf
#ifdef __IPHONE_14_0
    if (@available(iOS 14, *)) {
        [HXPhotoCommon photoCommon].photoLibraryDidChange = ^{
            if (!weakSelf.initialAuthorization) {
                if (weakSelf.timer) {
                    [weakSelf.timer invalidate];
                    weakSelf.timer = nil;
                }
                [weakSelf imagePickerDidFinish];
            }
        };
    }
#endif
    PHAuthorizationStatus status = [HXPhotoTools authorizationStatus];
    if (status == PHAuthorizationStatusAuthorized) {
        [self requestModel];
        return;
    }
#ifdef __IPHONE_14_0
    else if (@available(iOS 14, *)) {
        if (status == PHAuthorizationStatusLimited) {
            [self requestModel];
            return;
        }
    }
#endif
    if (status == PHAuthorizationStatusNotDetermined) {
        self.initialAuthorization = YES;
    }
    [HXPhotoTools requestAuthorization:nil handler:^(PHAuthorizationStatus status) {
        if (status == PHAuthorizationStatusAuthorized) {
            [weakSelf requestModel];
            if (weakSelf.reloadAsset) {
                weakSelf.reloadAsset(weakSelf.initialAuthorization);
            }
        }
#ifdef __IPHONE_14_0
        else if (@available(iOS 14, *)) {
            if (status == PHAuthorizationStatusLimited) {
                weakSelf.didPresentImagePicker = YES;
            }
#endif
        else if (status == PHAuthorizationStatusRestricted ||
                 status == PHAuthorizationStatusDenied) {
            if (weakSelf.reloadAsset) {
                weakSelf.reloadAsset(weakSelf.initialAuthorization);
            }
        }
#ifdef __IPHONE_14_0
        }else if (status == PHAuthorizationStatusRestricted ||
                  status == PHAuthorizationStatusDenied) {
             if (weakSelf.reloadAsset) {
                 weakSelf.reloadAsset(weakSelf.initialAuthorization);
             }
         }
#endif
    }];
}
- (void)presentViewController:(UIViewController *)viewControllerToPresent animated:(BOOL)flag completion:(void (^)(void))completion {
    if (!self.initialAuthorization) {
        [super presentViewController:viewControllerToPresent animated:flag completion:completion];
        return;
    }
#ifdef __IPHONE_14_0
    if (@available(iOS 14, *)) {
        if ([viewControllerToPresent isKindOfClass:[UIImagePickerController class]]) {
            UIImagePickerController *imagePickerController = (UIImagePickerController *)viewControllerToPresent;
            if (imagePickerController.sourceType == UIImagePickerControllerSourceTypePhotoLibrary) {
                HXWeakSelf
                self.timer = [NSTimer scheduledTimerWithTimeInterval:0.5 repeats:YES block:^(NSTimer * _Nonnull timer) {
                    if ([weakSelf.presentedViewController isKindOfClass:[UIImagePickerController class]]) {
                        weakSelf.didPresentImagePicker = YES;
                    }else {
                        if (weakSelf.didPresentImagePicker) {
                            weakSelf.didPresentImagePicker = NO;
                            [timer invalidate];
                            weakSelf.timer = nil;
                            [weakSelf imagePickerDidFinish];
                        }
                    }
                }];
            }
        }
    }
#endif
    [super presentViewController:viewControllerToPresent animated:flag completion:completion];
}
- (void)imagePickerDidFinish {
    [HXPhotoCommon photoCommon].cameraRollLocalIdentifier = nil;
    [HXPhotoCommon photoCommon].cameraRollResult = nil;
    self.cameraRollAlbumModel = nil;
    self.albums = nil;
    [self requestModel];
    if (self.reloadAsset) {
        self.reloadAsset(self.initialAuthorization);
    }
    if (self.initialAuthorization) {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"HXPhotoRequestAuthorizationCompletion" object:nil];
        self.initialAuthorization = NO;
    }
}
- (void)requestModel {
    [self.view hx_showLoadingHUDText:nil];
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
- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    if (_timer) {
        self.didPresentImagePicker = NO;
        [self.timer invalidate];
        self.timer = nil;
    }
}
- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}
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
    if (_timer) {
        [_timer invalidate];
        _timer = nil;
    }
    if (HXShowLog) NSLog(@"%@ dealloc", self);
}

@end
