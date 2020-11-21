//
//  Demo3ViewController.m
//  HXPhotoPickerExample
//
//  Created by 洪欣 on 17/2/17.
//  Copyright © 2017年 洪欣. All rights reserved.
//

#import "Demo3ViewController.h"
#import "HXPhotoPicker.h"
//#import "SDWebImageManager.h"

static const CGFloat kPhotoViewMargin = 12.0;

@interface Demo3ViewController ()<HXPhotoViewDelegate>

@property (strong, nonatomic) HXPhotoManager *manager;
@property (weak, nonatomic) HXPhotoView *photoView;
@property (strong, nonatomic) UIScrollView *scrollView;

@end

@implementation Demo3ViewController
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
- (HXPhotoManager *)manager
{
    if (!_manager) {
        _manager = [[HXPhotoManager alloc] initWithType:HXPhotoManagerSelectedTypePhoto];
        //        _manager.openCamera = NO; 
        _manager.configuration.saveSystemAblum = YES;
        _manager.configuration.photoMaxNum = 9; //
        _manager.configuration.videoMaxNum = 5;  //
        _manager.configuration.maxNum = 14;
    }
    return _manager;
}
- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
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

#if (!HasSDWebImage && !HasYYKitOrWebImage)
    hx_showAlert(self, @"pod导入SDWebImage或YYWebImage后再使用网络图片功能", nil, @"确定", nil, nil, nil);
    return;
#endif
//    self.navigationController.navigationBar.translucent = NO;
    self.automaticallyAdjustsScrollViewInsets = YES;
    
    UIScrollView *scrollView = [[UIScrollView alloc] initWithFrame:self.view.bounds];
    scrollView.alwaysBounceVertical = YES;
    [self.view addSubview:scrollView];
    self.scrollView = scrollView;
    
    CGFloat width = scrollView.frame.size.width;
    HXPhotoView *photoView = [HXPhotoView photoManager:self.manager];
    photoView.frame = CGRectMake(kPhotoViewMargin, kPhotoViewMargin, width - kPhotoViewMargin * 2, 0);
    photoView.lineCount = 5;
    photoView.delegate = self;
    photoView.showDeleteNetworkPhotoAlert = YES;
//    photoView.showAddCell = NO;  
    [scrollView addSubview:photoView];
    self.photoView = photoView;
    NSMutableArray *array = [NSMutableArray arrayWithObjects:@"http://oss-cn-hangzhou.aliyuncs.com/tsnrhapp/shop/photos/857980fd0acd3caf9e258e42788e38f5_0.gif",@"http://tsnrhapp.oss-cn-hangzhou.aliyuncs.com/0034821a-6815-4d64-b0f2-09103d62630d.jpg",@"http://tsnrhapp.oss-cn-hangzhou.aliyuncs.com/0be5118d-f550-403e-8e5c-6d0badb53648.jpg",@"http://tsnrhapp.oss-cn-hangzhou.aliyuncs.com/1466408576222.jpg", nil];
    NSMutableArray *assets = @[].mutableCopy;
    for (NSString *url in array) {
        HXCustomAssetModel *asset = [HXCustomAssetModel assetWithNetworkImageURL:[NSURL URLWithString:url] selected:YES];
        [assets addObject:asset];
    }
    [self.manager addCustomAssetModel:assets];
    [self.photoView refreshView];
    
//    photoView.manager = self.manager;
    UIBarButtonItem *item1 = [[UIBarButtonItem alloc] initWithTitle:@"添加网络" style:UIBarButtonItemStylePlain target:self action:@selector(addNetworkPhoto)];
    
    UIBarButtonItem *item2 = [[UIBarButtonItem alloc] initWithTitle:@"清空缓存" style:UIBarButtonItemStylePlain target:self action:@selector(lookClick)];
    
    self.navigationItem.rightBarButtonItems = @[item1,item2];
}

- (void)lookClick {
#if HasSDWebImage
    [[SDWebImageManager sharedManager] cancelAll];
    [[SDWebImageManager sharedManager].imageCache clearWithCacheType:SDImageCacheTypeAll completion:^{

    }];
#elif HasYYKitOrWebImage
    [[YYWebImageManager sharedManager].cache.diskCache removeAllObjects];
    [[YYWebImageManager sharedManager].cache.memoryCache removeAllObjects];
#endif
}
- (void)addNetworkPhoto {
    if (self.manager.afterSelectPhotoCountIsMaximum) {
        [self.view hx_showImageHUDText:@"图片已达到最大数"];
        return;
    }
    int x = arc4random() % 4;
    NSString *url;
    if (x == 0) {
        url = @"http://tsnrhapp.oss-cn-hangzhou.aliyuncs.com/0034821a-6815-4d64-b0f2-09103d62630d.jpg";
    }else if (x == 1) {
        url = @"http://tsnrhapp.oss-cn-hangzhou.aliyuncs.com/0be5118d-f550-403e-8e5c-6d0badb53648.jpg";
    }else {
        url = @"http://tsnrhapp.oss-cn-hangzhou.aliyuncs.com/1466408576222.jpg";
    }
    HXCustomAssetModel *asset = [HXCustomAssetModel assetWithLocalVideoURL:[NSURL URLWithString:url] selected:YES];
    [self.manager addCustomAssetModel:@[asset]];
    [self.photoView refreshView];
}

- (void)photoView:(HXPhotoView *)photoView changeComplete:(NSArray<HXPhotoModel *> *)allList photos:(NSArray<HXPhotoModel *> *)photos videos:(NSArray<HXPhotoModel *> *)videos original:(BOOL)isOriginal {
    NSSLog(@"所有:%ld - 照片:%ld - 视频:%ld",allList.count,photos.count,videos.count);
    
//    [self.toolManager writeSelectModelListToTempPathWithList:allList requestType:0 success:^(NSArray<NSURL *> *allURL, NSArray<NSURL *> *photoURL, NSArray<NSURL *> *videoURL) {
//        NSSLog(@"%@",allURL);
//    } failed:^{
//
//    }];
    
    
//    [self.view showLoadingHUDText:nil];
//    __weak typeof(self) weakSelf = self;
//    [self.toolManager getSelectedImageList:allList success:^(NSArray<UIImage *> *imageList) {
//        [weakSelf.view handleLoading];
//        NSSLog(@"%@",imageList);
//    } failed:^{
//        [weakSelf.view handleLoading];
//    }];
}

- (void)photoView:(HXPhotoView *)photoView deleteNetworkPhoto:(NSString *)networkPhotoUrl {
    NSSLog(@"%@",networkPhotoUrl);
}

- (void)photoView:(HXPhotoView *)photoView updateFrame:(CGRect)frame
{
    NSSLog(@"%@",NSStringFromCGRect(frame));
    self.scrollView.contentSize = CGSizeMake(self.scrollView.frame.size.width, CGRectGetMaxY(frame) + kPhotoViewMargin);
}

@end
