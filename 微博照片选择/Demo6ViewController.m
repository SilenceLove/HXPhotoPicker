//
//  Demo6ViewController.m
//  微博照片选择
//
//  Created by 洪欣 on 2017/7/26.
//  Copyright © 2017年 洪欣. All rights reserved.
//

#import "Demo6ViewController.h"
#import "Demo6SubViewController.h"
#import "HXPhotoViewController.h"
#import "HXFullScreenCameraViewController.h"
#import "HXCameraViewController.h"

@interface Demo6ViewController ()<UIActionSheetDelegate,HXPhotoViewControllerDelegate,HXCameraViewControllerDelegate,HXFullScreenCameraViewControllerDelegate,UIAlertViewDelegate>
@property (strong, nonatomic) HXPhotoManager *manager;
@end

@implementation Demo6ViewController

- (HXPhotoManager *)manager {
    if (!_manager) {
        _manager = [[HXPhotoManager alloc] initWithType:HXPhotoManagerSelectedTypePhotoAndVideo];
        _manager.outerCamera = YES;
        _manager.openCamera = NO;
    }
    return _manager;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor whiteColor];
    
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    [button setTitle:@"相机📷/相册" forState:UIControlStateNormal];
    [button setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [button setBackgroundColor:[UIColor whiteColor]];
    button.frame = CGRectMake(0, 0, 200, 40);
    [button addTarget:self action:@selector(didBtnClick) forControlEvents:UIControlEventTouchUpInside];
    button.center = CGPointMake(self.view.hx_w / 2, self.view.hx_h / 2 - 50);
    [self.view addSubview:button];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}

- (void)didBtnClick {
    UIActionSheet *sheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:@"取消" destructiveButtonTitle:nil otherButtonTitles:@"相机",@"相册", nil];
    
    [sheet showInView:self.view];
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 0) {
        if(![UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
            [self.view showImageHUDText:@"此设备不支持相机!"];
            return;
        }
        AVAuthorizationStatus authStatus = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
        if (authStatus == AVAuthorizationStatusRestricted || authStatus == AVAuthorizationStatusDenied) {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"无法使用相机" message:@"请在设置-隐私-相机中允许访问相机" delegate:self cancelButtonTitle:@"取消" otherButtonTitles:@"设置", nil];
            [alert show];
            return;
        }
        HXCameraType type = 0;
        if (self.manager.type == HXPhotoManagerSelectedTypePhotoAndVideo) {
            if (self.manager.endSelectedVideos.count >= self.manager.videoMaxNum && self.manager.endSelectedPhotos.count < self.manager.photoMaxNum + self.manager.networkPhotoUrls.count) {
                type = HXCameraTypePhoto;
            }else if (self.manager.endSelectedPhotos.count >= self.manager.photoMaxNum + self.manager.networkPhotoUrls.count && self.manager.endSelectedVideos.count < self.manager.videoMaxNum) {
                type = HXCameraTypeVideo;
            }else if (self.manager.endSelectedPhotos.count + self.manager.endSelectedVideos.count >= self.manager.maxNum + self.manager.networkPhotoUrls.count) {
                [self.view showImageHUDText:@"已达最大数!"];
                return;
            }else {
                type = HXCameraTypePhotoAndVideo;
            }
        }else if (self.manager.type == HXPhotoManagerSelectedTypePhoto) {
            if (self.manager.endSelectedPhotos.count >= self.manager.photoMaxNum + self.manager.networkPhotoUrls.count) {
                [self.view showImageHUDText:@"照片已达最大数"];
                return;
            }
            type = HXCameraTypePhoto;
        }else if (self.manager.type == HXPhotoManagerSelectedTypeVideo) {
            if (self.manager.endSelectedVideos.count >= self.manager.videoMaxNum) {
                [self.view showImageHUDText:@"视频已达最大数!"];
                return;
            }
            type = HXCameraTypeVideo;
        }

        if (self.manager.showFullScreenCamera) {
            HXFullScreenCameraViewController *vc1 = [[HXFullScreenCameraViewController alloc] init];
            vc1.delegate = self;
            vc1.type = type;
            vc1.photoManager = self.manager;
            if (self.manager.singleSelected) {
                [self presentViewController:[[UINavigationController alloc] initWithRootViewController:vc1] animated:YES completion:nil];
            }else {
                [self presentViewController:vc1 animated:YES completion:nil];
            }
        }else {
            HXCameraViewController *vc = [[HXCameraViewController alloc] init];
            vc.delegate = self;
            vc.type = type;
            vc.photoManager = self.manager;
            if (self.manager.singleSelected) {
                [self presentViewController:[[UINavigationController alloc] initWithRootViewController:vc] animated:YES completion:nil];
            }else {
                [self presentViewController:vc animated:YES completion:nil];
            }
        }
    }else if (buttonIndex == 1){
        HXPhotoViewController *vc = [[HXPhotoViewController alloc] init];
        vc.manager = self.manager;
        vc.delegate = self;
        [self presentViewController:[[UINavigationController alloc] initWithRootViewController:vc] animated:YES completion:nil];
    }
}
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 1) {
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]];
    }
}
- (void)fullScreenCameraDidNextClick:(HXPhotoModel *)model {
    [self cameraDidNextClick:model];
}

- (void)cameraDidNextClick:(HXPhotoModel *)model {
    // 判断类型
    if (model.type == HXPhotoModelMediaTypeCameraPhoto) {
        [self.manager.endCameraPhotos addObject:model];
        // 当选择图片个数没有达到最大个数时就添加到选中数组中
        if (self.manager.endSelectedPhotos.count != self.manager.photoMaxNum) {
            if (!self.manager.selectTogether) {
                if (self.manager.endSelectedList.count > 0) {
                    HXPhotoModel *phMd = self.manager.endSelectedList.firstObject;
                    if ((phMd.type == HXPhotoModelMediaTypePhoto || phMd.type == HXPhotoModelMediaTypeLivePhoto) || (phMd.type == HXPhotoModelMediaTypePhotoGif || phMd.type == HXPhotoModelMediaTypeCameraPhoto)) {
                        [self.manager.endSelectedCameraPhotos insertObject:model atIndex:0];
                        [self.manager.endSelectedPhotos addObject:model];
                        [self.manager.endSelectedList addObject:model];
                        [self.manager.endSelectedCameraList addObject:model];
                        model.selected = YES;
                    }
                }else {
                    [self.manager.endSelectedCameraPhotos insertObject:model atIndex:0];
                    [self.manager.endSelectedPhotos addObject:model];
                    [self.manager.endSelectedList addObject:model];
                    [self.manager.endSelectedCameraList addObject:model];
                    model.selected = YES;
                }
            }else {
                [self.manager.endSelectedCameraPhotos insertObject:model atIndex:0];
                [self.manager.endSelectedPhotos addObject:model];
                [self.manager.endSelectedList addObject:model];
                [self.manager.endSelectedCameraList addObject:model];
                model.selected = YES;
            }
        }
    }else if (model.type == HXPhotoModelMediaTypeCameraVideo) {
        [self.manager.endCameraVideos addObject:model];
        // 当选中视频个数没有达到最大个数时就添加到选中数组中
        if (self.manager.endSelectedVideos.count != self.manager.videoMaxNum) {
            if (!self.manager.selectTogether) {
                if (self.manager.endSelectedList.count > 0) {
                    HXPhotoModel *phMd = self.manager.endSelectedList.firstObject;
                    if (phMd.type == HXPhotoModelMediaTypeVideo || phMd.type == HXPhotoModelMediaTypeCameraVideo) {
                        [self.manager.endSelectedCameraVideos insertObject:model atIndex:0];
                        [self.manager.endSelectedVideos addObject:model];
                        [self.manager.endSelectedList addObject:model];
                        [self.manager.endSelectedCameraList addObject:model];
                        model.selected = YES;
                    }
                }else {
                    
                    [self.manager.endSelectedCameraVideos insertObject:model atIndex:0];
                    [self.manager.endSelectedVideos addObject:model];
                    [self.manager.endSelectedList addObject:model];
                    [self.manager.endSelectedCameraList addObject:model];
                    model.selected = YES;
                }
            }else {
                [self.manager.endSelectedCameraVideos insertObject:model atIndex:0];
                [self.manager.endSelectedVideos addObject:model];
                [self.manager.endSelectedList addObject:model];
                [self.manager.endSelectedCameraList addObject:model];
                model.selected = YES;
            }
        }
    }
    [self.manager.endCameraList addObject:model];
    NSInteger cameraIndex = self.manager.openCamera ? 1 : 0;
    
    int index = 0;
    for (NSInteger i = self.manager.endCameraPhotos.count - 1; i >= 0; i--) {
        HXPhotoModel *photoMD = self.manager.endCameraPhotos[i];
        photoMD.photoIndex = index;
        photoMD.albumListIndex = index + cameraIndex;
        index++;
    }
    index = 0;
    for (NSInteger i = self.manager.endCameraVideos.count - 1; i >= 0; i--) {
        HXPhotoModel *photoMD = self.manager.endCameraVideos[i];
        photoMD.videoIndex = index;
        index++;
    }
    index = 0;
    for (NSInteger i = self.manager.endCameraList.count - 1; i>= 0; i--) {
        HXPhotoModel *photoMD = self.manager.endCameraList[i];
        photoMD.albumListIndex = index + cameraIndex;
        index++;
    }
    [self photoViewControllerDidNext:self.manager.endSelectedList.mutableCopy Photos:self.manager.endSelectedPhotos.mutableCopy Videos:self.manager.endSelectedVideos.mutableCopy Original:self.manager.endIsOriginal];
}

- (void)photoViewControllerDidNext:(NSArray<HXPhotoModel *> *)allList Photos:(NSArray<HXPhotoModel *> *)photos Videos:(NSArray<HXPhotoModel *> *)videos Original:(BOOL)original {
    Demo6SubViewController *vc = [[Demo6SubViewController alloc] init];
    vc.manager = self.manager;
    [self.navigationController pushViewController:vc animated:YES];
}

@end
