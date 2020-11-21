//
//  Demo6ViewController.m
//  HXPhotoPickerExample
//
//  Created by 洪欣 on 2017/7/26.
//  Copyright © 2017年 洪欣. All rights reserved.
//

#import "Demo6ViewController.h"
#import "Demo6SubViewController.h"
#import "HXPhotoPicker.h"
@interface Demo6ViewController ()<UIActionSheetDelegate,UIAlertViewDelegate,HXCustomCameraViewControllerDelegate,HXAlbumListViewControllerDelegate>
@property (strong, nonatomic) HXPhotoManager *manager;
@property (strong, nonatomic) UIButton *titleBtn;
@end

@implementation Demo6ViewController

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
    [super traitCollectionDidChange:previousTraitCollection];
#ifdef __IPHONE_13_0
    if (@available(iOS 13.0, *)) {
        [self preferredStatusBarUpdateAnimation];
        [self changeStatus];
    }
#endif
}
- (UIStatusBarStyle)preferredStatusBarStyle {
#ifdef __IPHONE_13_0
    if (@available(iOS 13.0, *)) {
        if (UITraitCollection.currentTraitCollection.userInterfaceStyle == UIUserInterfaceStyleDark) {
            return UIStatusBarStyleLightContent;
        }
    }
#endif
    return UIStatusBarStyleDefault;
}
- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self changeStatus];
}
#pragma clang diagnostic push
#pragma clang diagnostic ignored"-Wdeprecated-declarations"
- (void)changeStatus {
#ifdef __IPHONE_13_0
    if (@available(iOS 13.0, *)) {
        if (UITraitCollection.currentTraitCollection.userInterfaceStyle == UIUserInterfaceStyleDark) {
            [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent animated:YES];
            return;
        }
    }
#endif
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault animated:YES];
}
#pragma clang diagnostic pop
- (HXPhotoManager *)manager {
    if (!_manager) {
        _manager = [[HXPhotoManager alloc] initWithType:HXPhotoManagerSelectedTypePhotoAndVideo];
        _manager.configuration.type = HXConfigurationTypeWXMoment;
        _manager.configuration.photoEditConfigur.onlyCliping = YES;
        _manager.configuration.photoEditConfigur.aspectRatio = HXPhotoEditAspectRatioType_1x1;
        _manager.configuration.photoEditConfigur.isRoundCliping = YES;
    }
    return _manager;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    // Fallback on earlier versions
    self.view.backgroundColor = [UIColor whiteColor];
#ifdef __IPHONE_13_0
    if (@available(iOS 13.0, *)) {
        self.view.backgroundColor = [UIColor colorWithDynamicProvider:^UIColor * _Nonnull(UITraitCollection * _Nonnull traitCollection) {
            if (traitCollection.userInterfaceStyle == UIUserInterfaceStyleDark) {
                return UIColor.blackColor;
            }
            return UIColor.whiteColor;
        }];
    }
#endif
    
    UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
    [button setTitle:@"相机📷/相册" forState:UIControlStateNormal];
    [button setBackgroundColor:[UIColor whiteColor]];
    button.frame = CGRectMake(0, 0, 200, 40);
    [button addTarget:self action:@selector(didBtnClick) forControlEvents:UIControlEventTouchUpInside];
    button.center = CGPointMake(self.view.hx_w / 2, self.view.hx_h / 2 - 50);
    [self.view addSubview:button];
    
    
//    self.titleBtn = [UIButton buttonWithType:UIButtonTypeCustom];
//    [self.titleBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
//    self.titleBtn.hx_size = CGSizeMake(200, 30);
//    [self.titleBtn addTarget:self action:@selector(didButtonClick:) forControlEvents:UIControlEventTouchUpInside];
//
//    HXWeakSelf
//    self.manager.configuration.photoListTitleView = ^UIView *(NSString *title) {
//        [weakSelf.titleBtn setTitle:title forState:UIControlStateNormal];
//        return weakSelf.titleBtn;
//    };
//    self.manager.configuration.photoListChangeTitleViewSelected = ^(BOOL selected) {
//        weakSelf.titleBtn.selected = selected;
//    };
//    self.manager.configuration.photoListTitleViewSelected = ^BOOL{
//        return weakSelf.titleBtn.selected;
//    };
//    self.manager.configuration.updatePhotoListTitle = ^(NSString *title) {
//        [weakSelf.titleBtn setTitle:title forState:UIControlStateNormal];
//    };
    
}

- (void)didButtonClick:(UIButton *)button {
    button.selected = !button.selected;
    self.manager.configuration.photoListTitleViewAction(button.selected);
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}

- (void)didBtnClick {
    HXPhotoBottomViewModel *model1 = [[HXPhotoBottomViewModel alloc] init];
    model1.title = [NSBundle hx_localizedStringForKey:@"拍摄"];
    model1.subTitle = [NSBundle hx_localizedStringForKey:@"照片或视频"];
    model1.cellHeight = 65.f;
    
    HXPhotoBottomViewModel *model2 = [[HXPhotoBottomViewModel alloc] init];
    model2.title = [NSBundle hx_localizedStringForKey:@"从手机相册选择"];
    HXWeakSelf
    [HXPhotoBottomSelectView showSelectViewWithModels:@[model1, model2] headerView:nil cancelTitle:nil selectCompletion:^(NSInteger index, HXPhotoBottomViewModel * _Nonnull model) {
        [weakSelf actionClickedButtonAtIndex:index];
    } cancelClick:nil];
}

- (void)actionClickedButtonAtIndex:(NSInteger)buttonIndex {
    HXWeakSelf
    if (buttonIndex == 0) {
        if(![UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
            [self.view hx_showImageHUDText:@"此设备不支持相机!"];
            return;
        }
        AVAuthorizationStatus authStatus = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
        if (authStatus == AVAuthorizationStatusRestricted || authStatus == AVAuthorizationStatusDenied) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored"-Wdeprecated-declarations"
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"无法使用相机" message:@"请在设置-隐私-相机中允许访问相机" delegate:self cancelButtonTitle:@"取消" otherButtonTitles:@"设置", nil];
            [alert show];
#pragma clang diagnostic pop
            return;
        }
        [self hx_presentCustomCameraViewControllerWithManager:self.manager done:^(HXPhotoModel *model, HXCustomCameraViewController *viewController) {
            [weakSelf.manager afterListAddCameraTakePicturesModel:model];
            Demo6SubViewController *vc = [[Demo6SubViewController alloc] init];
            vc.manager = weakSelf.manager;
            [weakSelf.navigationController pushViewController:vc animated:NO];
        } cancel:^(HXCustomCameraViewController *viewController) {
            NSSLog(@"取消了");
        }];
    }else if (buttonIndex == 1){
        [self hx_presentSelectPhotoControllerWithManager:self.manager didDone:^(NSArray<HXPhotoModel *> *allList, NSArray<HXPhotoModel *> *photoList, NSArray<HXPhotoModel *> *videoList, BOOL isOriginal, UIViewController *viewController, HXPhotoManager *manager) {
            Demo6SubViewController *vc = [[Demo6SubViewController alloc] init];
            vc.manager = weakSelf.manager;
            [weakSelf.navigationController pushViewController:vc animated:NO];
        } cancel:^(UIViewController *viewController, HXPhotoManager *manager) {
            
        }];
    }
}


@end
