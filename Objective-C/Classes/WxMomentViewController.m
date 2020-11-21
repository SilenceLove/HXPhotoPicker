//
//  WxMomentViewController.m
//  HXPhotoPickerExample
//
//  Created by 洪欣 on 2020/8/4.
//  Copyright © 2020 洪欣. All rights reserved.
//

#import "WxMomentViewController.h"
#import "WxMomentHeaderView.h"
#import "HXPhotoPicker.h"
#import "HXPhotoCustomNavigationBar.h"
#import "WxMomentPublishViewController.h"
#import "WxMomentViewCell.h"

@interface WxMomentViewController ()<UITableViewDataSource, UITableViewDelegate, HXCustomCameraViewControllerDelegate, HXCustomNavigationControllerDelegate>
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (strong, nonatomic) WxMomentHeaderView *headerView;
@property (strong, nonatomic) HXPhotoCustomNavigationBar *customNavBar;
@property (strong, nonatomic) UINavigationItem *navItem;
@property (strong, nonatomic) HXPhotoManager *photoManager;
@property (strong, nonatomic) CAGradientLayer *topMaskLayer;
@property (strong, nonatomic) UIView *topView;
@property (assign, nonatomic) BOOL getLocalCompletion;
@end

@implementation WxMomentViewController

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
    return UIStatusBarStyleLightContent;
}
- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}
#pragma clang diagnostic push
#pragma clang diagnostic ignored"-Wdeprecated-declarations"
- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent animated:YES];
    [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationFade];
    [self.navigationController setNavigationBarHidden:YES animated:YES];
}
- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.navigationController setNavigationBarHidden:NO animated:YES];
}
- (void)changeStatus {
#ifdef __IPHONE_13_0
    if (@available(iOS 13.0, *)) {
        if (UITraitCollection.currentTraitCollection.userInterfaceStyle == UIUserInterfaceStyleDark) {
            [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent animated:YES];
            return;
        }
    }
#endif
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent animated:YES];
}
#pragma clang diagnostic pop
- (void)photoListAddClick {
#ifdef __IPHONE_14_0
    if (@available(iOS 14, *)) {
        [[PHPhotoLibrary sharedPhotoLibrary] presentLimitedLibraryPickerFromViewController:[UIApplication sharedApplication].keyWindow.rootViewController.navigationController];
    }
#endif
}
- (HXPhotoManager *)photoManager {
    if (!_photoManager) {
        _photoManager = [[HXPhotoManager alloc] initWithType:HXPhotoManagerSelectedTypePhotoAndVideo];
//        _photoManager.assetFilter = ^BOOL(HXAlbumModel *albumModel, PHAsset *asset) {
//            if (!asset.location) {
//                return YES;
//            }
//            // 经纬度
////            asset.location.coordinate;
//
//            return NO;
//        };
//        _photoManager.assetCollectionFilter = ^BOOL(PHAssetCollection *collection) {
//            
//            return YES;
//        };
        
        _photoManager.configuration.type = HXConfigurationTypeWXMoment;
        _photoManager.configuration.localFileName = @"hx_WxMomentPhotoModels";
        _photoManager.configuration.showOriginalBytes = YES;
        _photoManager.configuration.showOriginalBytesLoading = YES;
//        _photoManager.configuration.clarityScale = 2.f;
        HXWeakSelf
        // 添加一个可以更改可查看照片的数据
        _photoManager.configuration.navigationBar = ^(UINavigationBar *navigationBar, UIViewController *viewController) {
            
#ifdef __IPHONE_14_0
            if (@available(iOS 14, *)) {
                if ([HXPhotoTools authorizationStatus] == PHAuthorizationStatusLimited) {
                    if ([viewController isKindOfClass:[HXPhotoViewController class]]) {
                        viewController.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"添加" style:UIBarButtonItemStylePlain target:weakSelf action:@selector(photoListAddClick)];
                    }
                }
            }
#endif
        };
#if HasSDWebImage
        // 先导入了SDWebImage
        _photoManager.configuration.photoEditConfigur.requestChartletModels = ^(void (^ _Nonnull chartletModels)(NSArray<HXPhotoEditChartletTitleModel *> * _Nonnull)) {
            
            HXPhotoEditChartletTitleModel *netModel = [HXPhotoEditChartletTitleModel modelWithNetworkNURL:[NSURL URLWithString:@"http://tsnrhapp.oss-cn-hangzhou.aliyuncs.com/chartle/xxy_s_highlighted.png"]];
            NSString *prefix = @"http://tsnrhapp.oss-cn-hangzhou.aliyuncs.com/chartle/xxy%d.png";
            NSMutableArray *netModels = @[].mutableCopy;
            for (int i = 1; i <= 40; i++) {
                [netModels addObject:[HXPhotoEditChartletModel modelWithNetworkNURL:[NSURL URLWithString:[NSString stringWithFormat:prefix ,i]]]];
            }
            netModel.models = netModels.copy;
            
            if (chartletModels) {
                chartletModels(@[netModel]);
            }
        };
#endif
    }
    return _photoManager;
}
- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationController.interactivePopGestureRecognizer.delegate = (id)self;
    self.title = nil;
    self.view.backgroundColor = [UIColor whiteColor];
#ifdef __IPHONE_13_0
    if (@available(iOS 13.0, *)) {
        self.view.backgroundColor = [UIColor colorWithDynamicProvider:^UIColor * _Nonnull(UITraitCollection * _Nonnull traitCollection) {
            if (traitCollection.userInterfaceStyle == UIUserInterfaceStyleDark) {
                return [UIColor hx_colorWithHexStr:@"#191918"];
            }
            return UIColor.whiteColor;
        }];
    }
#endif
    [self.view addSubview:self.topView];
    [self.view addSubview:self.customNavBar];
#ifdef __IPHONE_11_0
    if (@available(iOS 11.0, *)) {
        self.tableView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
#else
    if ((NO)) {
#endif
    } else {
        self.automaticallyAdjustsScrollViewInsets = NO;
    }
    self.tableView.tableHeaderView = self.headerView;
    [self.tableView registerNib:[UINib nibWithNibName:NSStringFromClass([WxMomentViewCell class]) bundle:nil] forCellReuseIdentifier:@"WxMomentViewCellId"];
    // 获取保存在本地文件中的模型数组
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [self.photoManager getLocalModelsInFile];
        self.getLocalCompletion = YES;
    });
}
- (void)backClick {
    [self.navigationController popViewControllerAnimated:YES];
}
- (void)didNavItemClick {
    if (!self.getLocalCompletion) {
        [self.photoManager getLocalModelsInFile];
    }
    if (self.photoManager.localModels.count) {
        // 有保存草稿的数据，将草稿数据添加后直接跳转
        [self.photoManager addLocalModels];
        [self setupManagerConfig];
        [self presentMomentPublish];
        return;
    }
    HXPhotoBottomViewModel *model1 = [[HXPhotoBottomViewModel alloc] init];
    model1.title = [NSBundle hx_localizedStringForKey:@"拍摄"];
    model1.subTitle = [NSBundle hx_localizedStringForKey:@"照片或视频"];
    model1.subTitleDarkColor = [UIColor hx_colorWithHexStr:@"#999999"];
    model1.cellHeight = 65.f;
    
    HXPhotoBottomViewModel *model2 = [[HXPhotoBottomViewModel alloc] init];
    model2.title = [NSBundle hx_localizedStringForKey:@"从手机相册选择"];
    [HXPhotoBottomSelectView showSelectViewWithModels:@[model1, model2] headerView:nil cancelTitle:nil selectCompletion:^(NSInteger index, HXPhotoBottomViewModel * _Nonnull model) {
        [self setupManagerConfig];
        // 去掉dismiss的动画方便选择完成后present
        self.photoManager.selectPhotoFinishDismissAnimated = NO;
        self.photoManager.cameraFinishDismissAnimated = NO;
        if (index == 0) {
            [self hx_presentCustomCameraViewControllerWithManager:self.photoManager delegate:self];
        }else if (index == 1){
            [self hx_presentSelectPhotoControllerWithManager:self.photoManager delegate:self];
        }
    } cancelClick:nil];
}
- (void)setupManagerConfig {
    // 因为公用的同一个manager所以这些需要在跳转前设置一下
    self.photoManager.type = HXPhotoManagerSelectedTypePhotoAndVideo;
    self.photoManager.configuration.singleJumpEdit = NO;
    self.photoManager.configuration.singleSelected = NO;
    self.photoManager.configuration.lookGifPhoto = YES;
    self.photoManager.configuration.lookLivePhoto = YES;
    self.photoManager.configuration.photoEditConfigur.aspectRatio = HXPhotoEditAspectRatioType_None;
    self.photoManager.configuration.photoEditConfigur.onlyCliping = NO;
}
- (void)presentMomentPublish {
    // 恢复dismiss的动画
    self.photoManager.selectPhotoFinishDismissAnimated = YES;
    self.photoManager.cameraFinishDismissAnimated = YES;
    
    WxMomentPublishViewController *vc = [[WxMomentPublishViewController alloc] init];
    vc.photoManager = self.photoManager;

    vc.modalPresentationStyle = UIModalPresentationOverFullScreen;
    vc.modalPresentationCapturesStatusBarAppearance = YES;
    [self presentViewController:vc animated:YES completion:nil];
}
#pragma mark - < HXCustomCameraViewControllerDelegate >
- (void)customCameraViewController:(HXCustomCameraViewController *)viewController didDone:(HXPhotoModel *)model {
    [self.photoManager afterListAddCameraTakePicturesModel:model];
}
- (void)customCameraViewControllerFinishDismissCompletion:(HXPhotoPreviewViewController *)previewController {
    [self presentMomentPublish];
}
#pragma mark - < HXCustomNavigationControllerDelegate >
- (void)photoNavigationViewControllerFinishDismissCompletion:(HXCustomNavigationController *)photoNavigationViewController {
    [self presentMomentPublish];
}
#pragma mark - < UITableViewDataSource >
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 10;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    WxMomentViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"WxMomentViewCellId"];
    
    return cell;
}

- (WxMomentHeaderView *)headerView {
    if (!_headerView) {
        _headerView = [WxMomentHeaderView initView];
        _headerView.photoManager = self.photoManager;
        _headerView.frame = CGRectMake(0, 0, HX_ScreenWidth, HX_ScreenWidth + 80);
    }
    return _headerView;
}
- (HXPhotoCustomNavigationBar *)customNavBar {
    if (!_customNavBar) {
        _customNavBar = [[HXPhotoCustomNavigationBar alloc] initWithFrame:CGRectMake(0, 0, HX_ScreenWidth, hxNavigationBarHeight)];
        _customNavBar.tintColor = [UIColor whiteColor];
        [_customNavBar setBackgroundImage:[UIImage hx_imageWithColor:[UIColor clearColor] havingSize:CGSizeMake(HX_ScreenWidth, hxNavigationBarHeight)] forBarMetrics:UIBarMetricsDefault];
        [_customNavBar setShadowImage:[UIImage new]];
        [_customNavBar pushNavigationItem:self.navItem animated:NO];
    }
    return _customNavBar;
}
- (UINavigationItem *)navItem {
    if (!_navItem) {
        _navItem = [[UINavigationItem alloc] init];
        _navItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"hotweibo_back_icon"] style:UIBarButtonItemStylePlain target:self action:@selector(backClick)];
        _navItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage hx_imageNamed:@"hx_camera_overturn"] style:UIBarButtonItemStylePlain target:self action:@selector(didNavItemClick)];
    }
    return _navItem;
}

- (UIView *)topView {
    if (!_topView) {
        _topView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, HX_ScreenWidth, hxNavigationBarHeight)];
        [_topView.layer addSublayer:self.topMaskLayer];
        self.topMaskLayer.frame = CGRectMake(0, 0, HX_ScreenWidth, hxNavigationBarHeight + 30);
    }
    return _topView;
}
- (CAGradientLayer *)topMaskLayer {
    if (!_topMaskLayer) {
        _topMaskLayer = [CAGradientLayer layer];
        _topMaskLayer.colors = @[
                                    (id)[[UIColor blackColor] colorWithAlphaComponent:0].CGColor,
                                    (id)[[UIColor blackColor] colorWithAlphaComponent:0.3].CGColor
                                    ];
        _topMaskLayer.startPoint = CGPointMake(0, 1);
        _topMaskLayer.endPoint = CGPointMake(0, 0);
        _topMaskLayer.locations = @[@(0.15f),@(0.9f)];
        _topMaskLayer.borderWidth  = 0.0;
    }
    return _topMaskLayer;
}
    
- (void)dealloc {
    NSSLog(@"dealloc");
}
@end
