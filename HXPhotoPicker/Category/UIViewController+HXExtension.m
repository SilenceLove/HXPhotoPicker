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
- (void)hx_presentAlbumListViewControllerWithManager:(HXPhotoManager *)manager
                                            delegate:(id)delegate {
    HXAlbumListViewController *vc = [[HXAlbumListViewController alloc] initWithManager:manager];
    vc.delegate = delegate ? delegate : (id)self; 
    HXCustomNavigationController *nav = [[HXCustomNavigationController alloc] initWithRootViewController:vc];
    nav.supportRotation = manager.configuration.supportRotation;
    nav.modalPresentationStyle = UIModalPresentationOverFullScreen;
    nav.modalPresentationCapturesStatusBarAppearance = YES;
    [self presentViewController:nav animated:YES completion:nil];
}
- (void)hx_presentSelectPhotoControllerWithManager:(HXPhotoManager *)manager
                                           didDone:(void (^)(NSArray<HXPhotoModel *> *, NSArray<HXPhotoModel *> *, NSArray<HXPhotoModel *> *, BOOL, UIViewController *, HXPhotoManager *))models
                                            cancel:(void (^)(UIViewController *, HXPhotoManager *))cancel {
    
    viewControllerDidDoneBlock modelBlock = ^(NSArray<HXPhotoModel *> *allList, NSArray<HXPhotoModel *> *photoList, NSArray<HXPhotoModel *> *videoList, BOOL original, UIViewController *viewController, HXPhotoManager *manager) {
        if (models) {
            models(allList, photoList, videoList, original, viewController, manager);
        }
    };
    viewControllerDidCancelBlock cancelBlock = ^(UIViewController *viewController, HXPhotoManager *manager) {
        if (cancel) {
            cancel(viewController, manager);
        }
    };
    HXCustomNavigationController *nav = [[HXCustomNavigationController alloc] initWithManager:manager doneBlock:modelBlock cancelBlock:cancelBlock];
    nav.modalPresentationStyle = UIModalPresentationOverFullScreen;
    nav.modalPresentationCapturesStatusBarAppearance = YES;
    [self presentViewController:nav animated:YES completion:nil];
}

- (void)hx_presentCustomCameraViewControllerWithManager:(HXPhotoManager *)manager
                                               delegate:(id)delegate {
    if(![UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
        [self.view hx_showImageHUDText:[NSBundle hx_localizedStringForKey:@"无法使用相机!"]];
        return;
    }
    HXWeakSelf
    [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(BOOL granted) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (granted) {
                HXCustomCameraViewController *vc = [[HXCustomCameraViewController alloc] init];
                vc.delegate = delegate ? delegate : (id)weakSelf;
                vc.manager = manager;
                vc.isOutside = YES;
                HXCustomNavigationController *nav = [[HXCustomNavigationController alloc] initWithRootViewController:vc];
                nav.isCamera = YES;
                nav.supportRotation = manager.configuration.supportRotation;
                nav.modalPresentationStyle = UIModalPresentationOverFullScreen;
                nav.modalPresentationCapturesStatusBarAppearance = YES;
                [weakSelf presentViewController:nav animated:YES completion:nil];
            }else {
                hx_showAlert(weakSelf, [NSBundle hx_localizedStringForKey:@"无法使用相机"], [NSBundle hx_localizedStringForKey:@"请在设置-隐私-相机中允许访问相机"], [NSBundle hx_localizedStringForKey:@"取消"], [NSBundle hx_localizedStringForKey:@"设置"] , nil, ^{
                    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]];
                });
            }
        });
    }];
}

- (void)hx_presentCustomCameraViewControllerWithManager:(HXPhotoManager *)manager
                                                   done:(HXCustomCameraViewControllerDidDoneBlock)done
                                                 cancel:(HXCustomCameraViewControllerDidCancelBlock)cancel {
    if(![UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
        [self.view hx_showImageHUDText:[NSBundle hx_localizedStringForKey:@"无法使用相机!"]];
        return;
    }
    HXWeakSelf
    [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(BOOL granted) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (granted) {
                HXCustomCameraViewController *vc = [[HXCustomCameraViewController alloc] init];
                vc.doneBlock = done;
                vc.cancelBlock = cancel;
                vc.manager = manager;
                vc.isOutside = YES;
                vc.delegate = (id)weakSelf;
                HXCustomNavigationController *nav = [[HXCustomNavigationController alloc] initWithRootViewController:vc];
                nav.isCamera = YES;
                nav.supportRotation = manager.configuration.supportRotation;
                nav.modalPresentationStyle = UIModalPresentationOverFullScreen;
                nav.modalPresentationCapturesStatusBarAppearance = YES;
                [weakSelf presentViewController:nav animated:YES completion:nil];
            }else {
                hx_showAlert(weakSelf, [NSBundle hx_localizedStringForKey:@"无法使用相机"], [NSBundle hx_localizedStringForKey:@"请在设置-隐私-相机中允许访问相机"], [NSBundle hx_localizedStringForKey:@"取消"], [NSBundle hx_localizedStringForKey:@"设置"] , nil, ^{
                    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]];
                });
            }
        });
    }];
}

- (void)hx_presentPreviewPhotoControllerWithManager:(HXPhotoManager *)manager
                                       previewStyle:(HXPhotoViewPreViewShowStyle)previewStyle
                                       currentIndex:(NSUInteger)currentIndex
                                          photoView:(HXPhotoView * _Nullable)photoView {
    
    HXPhotoPreviewViewController *vc = [[HXPhotoPreviewViewController alloc] init];
    vc.disableaPersentInteractiveTransition = photoView.disableaInteractiveTransition;
    vc.outside = YES;
    vc.manager = manager ?: photoView.manager;
    vc.exteriorPreviewStyle = photoView ? photoView.previewStyle : previewStyle;
    vc.delegate = (id)self;
    if (manager.afterSelectedArray) {
        vc.modelArray = [NSMutableArray arrayWithArray:manager.afterSelectedArray];
    }
    if (currentIndex >= vc.modelArray.count) {
        vc.currentModelIndex = vc.modelArray.count - 1;
    }else if (currentIndex < 0) {
        vc.currentModelIndex = 0;
    }else {
        vc.currentModelIndex = currentIndex;
    }
    vc.previewShowDeleteButton = photoView.previewShowDeleteButton;
    vc.photoView = photoView;
    vc.modalPresentationStyle = UIModalPresentationOverFullScreen;
    vc.modalPresentationCapturesStatusBarAppearance = YES;
    [self presentViewController:vc animated:YES completion:nil];
}

- (void)hx_presentPhotoEditViewControllerWithManager:(HXPhotoManager *)manager
                                          photoModel:(HXPhotoModel *)photomodel
                                            delegate:(id)delegate
                                                done:(HXPhotoEditViewControllerDidDoneBlock)done
                                              cancel:(HXPhotoEditViewControllerDidCancelBlock)cancel {
    HXPhotoEditViewController *vc = [[HXPhotoEditViewController alloc] init];
    vc.isInside = YES;
    vc.delegate = delegate ?: self;
    vc.manager = manager;
    vc.model = photomodel;
    vc.doneBlock = done;
    vc.cancelBlock = cancel;
    vc.modalPresentationStyle = UIModalPresentationOverFullScreen;
    vc.modalPresentationCapturesStatusBarAppearance = YES;
    [self presentViewController:vc animated:YES completion:nil];
}

- (void)hx_presentPhotoEditViewControllerWithManager:(HXPhotoManager * _Nonnull)manager
                                           editPhoto:(UIImage * _Nonnull)editPhoto
                                                done:(HXPhotoEditViewControllerDidDoneBlock _Nullable)done
                                              cancel:(HXPhotoEditViewControllerDidCancelBlock _Nullable)cancel {
    HXPhotoModel *photoModel = [HXPhotoModel photoModelWithImage:editPhoto];
    [self hx_presentPhotoEditViewControllerWithManager:manager photoModel:photoModel delegate:nil done:done cancel:cancel];
}

- (void)hx_presentVideoEditViewControllerWithManager:(HXPhotoManager *)manager
                                          videoModel:(HXPhotoModel *)videoModel
                                            delegate:(id)delegate
                                                done:(HXVideoEditViewControllerDidDoneBlock)done
                                              cancel:(HXVideoEditViewControllerDidCancelBlock)cancel {
    HXVideoEditViewController *vc = [[HXVideoEditViewController alloc] init];
    vc.model = videoModel;
    vc.delegate = delegate ?: self;
    vc.manager = manager;
    vc.isInside = YES;
    vc.doneBlock = done;
    vc.cancelBlock = cancel;
    vc.modalPresentationStyle = UIModalPresentationOverFullScreen;
    vc.modalPresentationCapturesStatusBarAppearance = YES;
    [self presentViewController:vc animated:YES completion:nil];
}

- (void)hx_presentVideoEditViewControllerWithManager:(HXPhotoManager * _Nonnull)manager
                                            videoURL:(NSURL * _Nonnull)videoURL
                                                done:(HXVideoEditViewControllerDidDoneBlock _Nullable)done
                                              cancel:(HXVideoEditViewControllerDidCancelBlock _Nullable)cancel {
    HXPhotoModel *videoModel = [HXPhotoModel photoModelWithVideoURL:videoURL];
    [self hx_presentVideoEditViewControllerWithManager:manager videoModel:videoModel delegate:nil done:done cancel:cancel];
}

- (BOOL)hx_navigationBarWhetherSetupBackground {
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
