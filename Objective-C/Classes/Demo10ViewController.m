//
//  Demo10ViewController.m
//  HXPhotoPickerExample
//
//  Created by 洪欣 on 2018/7/21.
//  Copyright © 2018年 洪欣. All rights reserved.
//

#import "Demo10ViewController.h"
#import "HXPhotoPicker.h"
static const CGFloat kPhotoViewMargin = 12.0;
@interface Demo10ViewController ()
@property (strong, nonatomic) HXPhotoManager *manager;
@property (strong, nonatomic) HXPhotoView *photoView;
@end

@implementation Demo10ViewController

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
- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
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
//    HXCustomAssetModel *assetModel = [HXCustomAssetModel livePhotoAssetWithNetworkImageURL:[NSURL URLWithString:@"http://oss-cn-hangzhou.aliyuncs.com/tsnrhapp/5ed15ef7-3411-4f5e-839b-10664d796919.jpg"] networkVideoURL:[NSURL URLWithString:@"http://tsnrhapp.oss-cn-hangzhou.aliyuncs.com/chartle/fufeiduanpian.mp4"] selected:YES];
//    [self.manager addCustomAssetModel:@[assetModel]];
    
    [self.manager getLocalModelsInFileWithAddData:YES];
    HXPhotoView *photoView = [HXPhotoView photoManager:self.manager];
    photoView.frame = CGRectMake(kPhotoViewMargin, hxNavigationBarHeight + kPhotoViewMargin, self.view.hx_w - kPhotoViewMargin * 2, 0);
//    photoView.showAddCell = YES;  
    [self.view addSubview:photoView];
    self.photoView = photoView;
    
    UIBarButtonItem *saveItem = [[UIBarButtonItem alloc] initWithTitle:@"保存草稿" style:UIBarButtonItemStylePlain target:self action:@selector(savaClick)];
    UIBarButtonItem *deleteItem = [[UIBarButtonItem alloc] initWithTitle:@"删除" style:UIBarButtonItemStylePlain target:self action:@selector(didNavBtnClick)];
    
    self.navigationItem.rightBarButtonItems = @[deleteItem,saveItem];
}
- (void)savaClick {
    if (!self.manager.afterSelectedArray.count) {
        [self.view hx_showImageHUDText:@"请先选择资源!"];
        return;
    }
    if (![self.manager saveLocalModelsToFile]) {
        [self.view hx_showImageHUDText:@"保存草稿失败"];
    }
}
- (void)didNavBtnClick {
    BOOL success = [self.manager deleteLocalModelsInFile];
    if (!success) {
        
    }
}
- (HXPhotoManager *)manager {
    if (!_manager) {
        _manager = [[HXPhotoManager alloc] initWithType:HXPhotoManagerSelectedTypePhotoAndVideo];
        _manager.configuration.openCamera = YES;
        _manager.configuration.lookLivePhoto = YES;
        _manager.configuration.photoMaxNum = 9;
        _manager.configuration.videoMaxNum = 9;
        _manager.configuration.maxNum = 18;
        _manager.configuration.videoMaximumSelectDuration = 500.f;
        _manager.configuration.saveSystemAblum = YES;
        _manager.configuration.showDateSectionHeader = NO;
//        _manager.configuration.requestImageAfterFinishingSelection = YES;
        // 设置保存的文件名称
        _manager.configuration.localFileName = @"suibianshishi";
    }
    return _manager;
}

@end
