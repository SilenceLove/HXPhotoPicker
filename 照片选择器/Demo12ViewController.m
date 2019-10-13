//
//  Demo12ViewController.m
//  照片选择器
//
//  Created by 洪欣 on 2018/7/24.
//  Copyright © 2018年 洪欣. All rights reserved.
//

#import "Demo12ViewController.h"
#import "HXPhotoPicker.h"

static const CGFloat kPhotoViewMargin = 12.0;
@interface Demo12ViewController () <HXPhotoViewDelegate>
@property (strong, nonatomic) HXPhotoManager *manager;
@property (weak, nonatomic) HXPhotoView *photoView;
@property (strong, nonatomic) UIScrollView *scrollView;
@end

@implementation Demo12ViewController

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
- (HXPhotoManager *)manager {
    if (!_manager) {
        _manager = [[HXPhotoManager alloc] initWithType:HXPhotoManagerSelectedTypePhotoAndVideo];
//        _manager.configuration.openCamera = NO;
        _manager.configuration.saveSystemAblum = YES;
        _manager.configuration.photoMaxNum = 9; //
        _manager.configuration.videoMaxNum = 1;  //
        _manager.configuration.maxNum = 10;
        _manager.configuration.reverseDate = YES;
        _manager.configuration.selectTogether = YES;
    }
    return _manager;
}
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
    //    self.navigationController.navigationBar.translucent = NO;
    self.automaticallyAdjustsScrollViewInsets = YES;
    
    UIScrollView *scrollView = [[UIScrollView alloc] initWithFrame:self.view.bounds];
    scrollView.alwaysBounceVertical = YES;
    [self.view addSubview:scrollView];
    self.scrollView = scrollView;
    
    CGFloat width = scrollView.frame.size.width;
    HXPhotoView *photoView = [HXPhotoView photoManager:self.manager];
    photoView.frame = CGRectMake(kPhotoViewMargin, kPhotoViewMargin, width - kPhotoViewMargin * 2, 0);
    photoView.lineCount = 3;
    photoView.previewStyle = HXPhotoViewPreViewShowStyleDark;
    photoView.outerCamera = YES;
    photoView.delegate = self;
    //    photoView.showAddCell = NO; 
    [scrollView addSubview:photoView];
    self.photoView = photoView;
    NSURL *url = [[NSBundle mainBundle] URLForResource:@"QQ空间视频_20180301091047" withExtension:@"mp4"];
    
    HXCustomAssetModel *assetModel1 = [HXCustomAssetModel assetWithLocaImageName:@"1" selected:YES];
    HXCustomAssetModel *assetModel2 = [HXCustomAssetModel assetWithLocaImageName:@"2" selected:NO];
    HXCustomAssetModel *assetModel3 = [HXCustomAssetModel assetWithNetworkImageURL:[NSURL URLWithString:@"http://tsnrhapp.oss-cn-hangzhou.aliyuncs.com/1466408576222.jpg"] selected:YES];
    HXCustomAssetModel *assetModel4 = [HXCustomAssetModel assetWithNetworkImageURL:[NSURL URLWithString:@"http://tsnrhapp.oss-cn-hangzhou.aliyuncs.com/0034821a-6815-4d64-b0f2-09103d62630d.jpg"] selected:NO];
    HXCustomAssetModel *assetModel5 = [HXCustomAssetModel assetWithLocalVideoURL:url selected:YES];
    // 模拟视频数量超过视频最大选择数
    HXCustomAssetModel *assetModel6 = [HXCustomAssetModel assetWithLocalVideoURL:url selected:YES]; 
    [self.manager addCustomAssetModel:@[assetModel1, assetModel2, assetModel3, assetModel4, assetModel5, assetModel6]];
    [self.photoView refreshView];
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"外部预览" style:UIBarButtonItemStylePlain target:self action:@selector(previewClick)];
}
- (void)previewClick {
    HXCustomAssetModel *assetModel1 = [HXCustomAssetModel assetWithLocaImageName:@"1" selected:YES];
    // selected 为NO 的会过滤掉
    HXCustomAssetModel *assetModel2 = [HXCustomAssetModel assetWithLocaImageName:@"2" selected:NO];
    HXCustomAssetModel *assetModel3 = [HXCustomAssetModel assetWithNetworkImageURL:[NSURL URLWithString:@"http://tsnrhapp.oss-cn-hangzhou.aliyuncs.com/1466408576222.jpg"] selected:YES];
    HXCustomAssetModel *assetModel4 = [HXCustomAssetModel assetWithNetworkImageURL:[NSURL URLWithString:@"http://tsnrhapp.oss-cn-hangzhou.aliyuncs.com/0034821a-6815-4d64-b0f2-09103d62630d.jpg"] selected:NO];
    NSURL *url = [[NSBundle mainBundle] URLForResource:@"QQ空间视频_20180301091047" withExtension:@"mp4"];
    HXCustomAssetModel *assetModel5 = [HXCustomAssetModel assetWithLocalVideoURL:url selected:YES];
    
    HXPhotoManager *photoManager = [HXPhotoManager managerWithType:HXPhotoManagerSelectedTypePhotoAndVideo];
    photoManager.configuration.saveSystemAblum = YES;
    photoManager.configuration.photoMaxNum = 0;
    photoManager.configuration.videoMaxNum = 0;
    photoManager.configuration.maxNum = 10;
    photoManager.configuration.selectTogether = YES;
    photoManager.configuration.photoCanEdit = NO;
    photoManager.configuration.videoCanEdit = NO;
    
    HXWeakSelf
    // 长按事件
    photoManager.configuration.previewRespondsToLongPress = ^(UILongPressGestureRecognizer *longPress, HXPhotoModel *photoModel, HXPhotoManager *manager, HXPhotoPreviewViewController *previewViewController) {
        hx_showAlert(previewViewController, @"提示", @"长按事件", @"确定", nil, nil, nil);
    };
    
    // 跳转预览界面时动画起始的view
    photoManager.configuration.customPreviewFromView = ^UIView *(NSInteger currentIndex) {
        HXPhotoSubViewCell *viewCell = [weakSelf.photoView collectionViewCellWithIndex:currentIndex];
        return viewCell;
    };
    // 跳转预览界面时展现动画的image
    photoManager.configuration.customPreviewFromImage = ^UIImage *(NSInteger currentIndex) {
        HXPhotoSubViewCell *viewCell = [weakSelf.photoView collectionViewCellWithIndex:currentIndex];
        return viewCell.imageView.image;
    };
    // 退出预览界面时终点view
    photoManager.configuration.customPreviewToView = ^UIView *(NSInteger currentIndex) {
        HXPhotoSubViewCell *viewCell = [weakSelf.photoView collectionViewCellWithIndex:currentIndex];
        return viewCell;
    };
    [photoManager addCustomAssetModel:@[assetModel1, assetModel2, assetModel3, assetModel4, assetModel5]];
    
    [self hx_presentPreviewPhotoControllerWithManager:photoManager
                                         previewStyle:HXPhotoViewPreViewShowStyleDark
                                         currentIndex:0
                                            photoView:nil];
}
- (void)photoView:(HXPhotoView *)photoView changeComplete:(NSArray<HXPhotoModel *> *)allList photos:(NSArray<HXPhotoModel *> *)photos videos:(NSArray<HXPhotoModel *> *)videos original:(BOOL)isOriginal {
    
//    [allList hx_requestImageWithOriginal:isOriginal completion:^(NSArray<UIImage *> * _Nullable imageArray) {
//        NSSLog(@"%@",imageArray);
//    }];
}
- (void)photoView:(HXPhotoView *)photoView updateFrame:(CGRect)frame
{
    NSSLog(@"%@",NSStringFromCGRect(frame));
    self.scrollView.contentSize = CGSizeMake(self.scrollView.frame.size.width, CGRectGetMaxY(frame) + kPhotoViewMargin);
}
@end
