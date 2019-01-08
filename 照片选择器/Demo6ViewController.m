//
//  Demo6ViewController.m
//  照片选择器
//
//  Created by 洪欣 on 2017/7/26.
//  Copyright © 2017年 洪欣. All rights reserved.
//

#import "Demo6ViewController.h"
#import "Demo6SubViewController.h"
#import "HXPhotoPicker.h"
@interface Demo6ViewController ()<UIActionSheetDelegate,UIAlertViewDelegate,HXCustomCameraViewControllerDelegate,HXAlbumListViewControllerDelegate>
@property (strong, nonatomic) HXPhotoManager *manager;
@end

@implementation Demo6ViewController

- (HXPhotoManager *)manager {
    if (!_manager) {
        _manager = [[HXPhotoManager alloc] initWithType:HXPhotoManagerSelectedTypePhotoAndVideo];
        _manager.configuration.openCamera = YES;
        _manager.configuration.saveSystemAblum = NO;
        _manager.configuration.themeColor = [UIColor blackColor];
    }
    return _manager;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor whiteColor];
    
    UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
    [button setTitle:@"相机📷/相册" forState:UIControlStateNormal];
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
    HXWeakSelf
    if (buttonIndex == 0) {
        if(![UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
            [self.view hx_showImageHUDText:@"此设备不支持相机!"];
            return;
        }
        AVAuthorizationStatus authStatus = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
        if (authStatus == AVAuthorizationStatusRestricted || authStatus == AVAuthorizationStatusDenied) {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"无法使用相机" message:@"请在设置-隐私-相机中允许访问相机" delegate:self cancelButtonTitle:@"取消" otherButtonTitles:@"设置", nil];
            [alert show];
            return;
        }
        [self hx_presentCustomCameraViewControllerWithManager:self.manager done:^(HXPhotoModel *model, HXCustomCameraViewController *viewController) {
            [weakSelf.manager afterListAddCameraTakePicturesModel:model];
            Demo6SubViewController *vc = [[Demo6SubViewController alloc] init];
            vc.manager = weakSelf.manager;
            [weakSelf.navigationController pushViewController:vc animated:YES];
        } cancel:^(HXCustomCameraViewController *viewController) {
            NSSLog(@"取消了");
        }];
    }else if (buttonIndex == 1){
        [self hx_presentSelectPhotoControllerWithManager:self.manager didDone:^(NSArray<HXPhotoModel *> *allList, NSArray<HXPhotoModel *> *photoList, NSArray<HXPhotoModel *> *videoList, BOOL isOriginal, UIViewController *viewController, HXPhotoManager *manager) {
            Demo6SubViewController *vc = [[Demo6SubViewController alloc] init];
            vc.manager = weakSelf.manager;
            [weakSelf.navigationController pushViewController:vc animated:YES];
        } cancel:^(UIViewController *viewController, HXPhotoManager *manager) {
            
        }];
    }
}
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 1) {
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]];
    }
}
- (void)customCameraViewController:(HXCustomCameraViewController *)viewController didDone:(HXPhotoModel *)model {
//    [self.manager afterListAddCameraTakePicturesModel:model];
//    Demo6SubViewController *vc = [[Demo6SubViewController alloc] init];
//    vc.manager = self.manager;
//    [self.navigationController pushViewController:vc animated:YES];
}
- (void)albumListViewController:(HXAlbumListViewController *)albumListViewController didDoneAllList:(NSArray<HXPhotoModel *> *)allList photos:(NSArray<HXPhotoModel *> *)photoList videos:(NSArray<HXPhotoModel *> *)videoList original:(BOOL)original {
}


@end
