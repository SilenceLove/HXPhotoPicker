//
//  Demo12ViewController.m
//  HXPhotoPickerExample
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
//        _manager.configuration.openCamera = NO;
        _manager.configuration.saveSystemAblum = YES;
        _manager.configuration.photoMaxNum = 9; //
        _manager.configuration.videoMaxNum = 0;  //
        _manager.configuration.maxNum = 10;
        _manager.configuration.reverseDate = YES;
        _manager.configuration.lookLivePhoto = YES;
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
#if (!HasSDWebImage && !HasYYKitOrWebImage)
    hx_showAlert(self, @"pod导入SDWebImage或YYWebImage后再查看此demo", @"如果需要使用网络视频也需导入AFNetWorking", @"确定", nil, nil, nil);
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
    photoView.lineCount = 3;
    photoView.previewStyle = HXPhotoViewPreViewShowStyleDark;
    photoView.outerCamera = YES;
    photoView.delegate = self;
    //    photoView.showAddCell = NO; 
    [scrollView addSubview:photoView];
    self.photoView = photoView;
    NSURL *url = [[NSBundle mainBundle] URLForResource:@"LocalSampleVideo" withExtension:@"mp4"];
//    NSURL *imageURL = [[NSBundle mainBundle] URLForResource:@"0AA996F1-6566-4CA3-845F-5698DD9726A0" withExtension:@"jpg"];
    
    NSURL *gifURL = [[NSBundle mainBundle] URLForResource:@"IMG_0168" withExtension:@"GIF"];
    
    HXCustomAssetModel *assetModel1 = [HXCustomAssetModel assetWithLocaImageName:@"1" selected:YES];
    HXCustomAssetModel *assetModel2 = [HXCustomAssetModel assetWithLocaImageName:@"2" selected:NO];
    HXCustomAssetModel *assetModel3 = [HXCustomAssetModel assetWithNetworkImageURL:[NSURL URLWithString:@"http://tsnrhapp.oss-cn-hangzhou.aliyuncs.com/1466408576222.jpg"] selected:YES];
    HXCustomAssetModel *assetModel4 = [HXCustomAssetModel assetWithNetworkImageURL:[NSURL URLWithString:@"http://tsnrhapp.oss-cn-hangzhou.aliyuncs.com/0034821a-6815-4d64-b0f2-09103d62630d.jpg"] selected:NO];
    HXCustomAssetModel *assetModel5 = [HXCustomAssetModel assetWithLocalVideoURL:url selected:YES];
    

     HXCustomAssetModel *assetModel6 = [HXCustomAssetModel assetWithImagePath:gifURL selected:YES];
//    HXCustomAssetModel *assetModel6 = [HXCustomAssetModel assetWithLocalVideoURL:url1 selected:YES];
    
    HXCustomAssetModel *assetModel7 = [HXCustomAssetModel assetWithNetworkVideoURL:[NSURL URLWithString:@"http://oss-cn-hangzhou.aliyuncs.com/tsnrhapp/fff42798-8025-4170-a36d-3257be267f29.mp4"] videoCoverURL:[NSURL URLWithString:@"http://oss-cn-hangzhou.aliyuncs.com/tsnrhapp/d3c3bbe6-02ce-4f17-a75b-3387d52b0a4a.jpg"] videoDuration:13 selected:YES];
    
    HXCustomAssetModel *assetModel8 = [HXCustomAssetModel assetWithNetworkVideoURL:[NSURL URLWithString:@"http://oss-cn-hangzhou.aliyuncs.com/tsnrhapp/2280ec38-5873-4b3f-8784-a361645c8854.mp4"] videoCoverURL:[NSURL URLWithString:@"http://oss-cn-hangzhou.aliyuncs.com/tsnrhapp/5ed15ef7-3411-4f5e-839b-10664d796919.jpg"] videoDuration:61 selected:YES];
    
    
    
    [self.manager addCustomAssetModel:@[assetModel1, assetModel2, assetModel3, assetModel4, assetModel5, assetModel6, assetModel7, assetModel8]];
    [self.photoView refreshView];
    
    UIBarButtonItem *barItem1 = [[UIBarButtonItem alloc] initWithTitle:@"外部预览" style:UIBarButtonItemStylePlain target:self action:@selector(previewClick)];
    
    UIBarButtonItem *barItem2 = [[UIBarButtonItem alloc] initWithTitle:@"添加LivePhoto" style:UIBarButtonItemStylePlain target:self action:@selector(addLivePhotoClick)];
    
    self.navigationItem.rightBarButtonItems = @[barItem1, barItem2];
}
- (void)addLivePhotoClick {
    HXPhotoBottomViewModel *model1 = [[HXPhotoBottomViewModel alloc] init];
    model1.title = @"通过本地图片、视频生成-1";
    
    HXPhotoBottomViewModel *model2 = [[HXPhotoBottomViewModel alloc] init];
    model2.title = @"通过本地图片、视频生成-2";
    
    HXPhotoBottomViewModel *model3 = [[HXPhotoBottomViewModel alloc] init];
    model3.title = @"通过网络图片、视频生成-1";
    
    HXPhotoBottomViewModel *model4 = [[HXPhotoBottomViewModel alloc] init];
    model4.title = @"通过网络图片、视频生成-2";
    
    HXPhotoBottomViewModel *model5 = [[HXPhotoBottomViewModel alloc] init];
    model5.title = @"清空LivePhoto本地缓存";
    HXWeakSelf
    [HXPhotoBottomSelectView showSelectViewWithModels:@[model1, model2, model3, model4, model5] selectCompletion:^(NSInteger index, HXPhotoBottomViewModel * _Nonnull model) {
        HXCustomAssetModel *assetModel9;
        if (index == 0) {
            NSURL *imageURL = [[NSBundle mainBundle] URLForResource:@"d87" withExtension:@"jpeg"];
            NSURL *videoURL = [[NSBundle mainBundle] URLForResource:@"c81" withExtension:@"mp4"];
            assetModel9 = [HXCustomAssetModel livePhotoAssetWithLocalImagePath:imageURL localVideoURL:videoURL selected:YES];
        }else if (index == 1) {
            NSURL *vurl = [[NSBundle mainBundle] URLForResource:@"LocalSampleVideo" withExtension:@"mp4"];
            assetModel9 = [HXCustomAssetModel livePhotoAssetWithImage:[UIImage imageNamed:@"1"] localVideoURL:vurl selected:YES];
        }else if (index == 2){
            assetModel9 = [HXCustomAssetModel livePhotoAssetWithNetworkImageURL:[NSURL URLWithString:@"http://oss-cn-hangzhou.aliyuncs.com/tsnrhapp/5ed15ef7-3411-4f5e-839b-10664d796919.jpg"] networkVideoURL:[NSURL URLWithString:@"http://tsnrhapp.oss-cn-hangzhou.aliyuncs.com/chartle/fufeiduanpian.mp4"] selected:YES];
            
        }else if (index == 3){
            assetModel9 = [HXCustomAssetModel livePhotoAssetWithNetworkImageURL:[NSURL URLWithString:@"http://tsnrhapp.oss-cn-hangzhou.aliyuncs.com/chartle/wokeyidengdainishenhoufengm.png"] networkVideoURL:[NSURL URLWithString:@"http://tsnrhapp.oss-cn-hangzhou.aliyuncs.com/chartle/wokeyidengdaonishenhou.MP4"] selected:YES];
            
        }else if (index == 4) {
            [HXPhotoTools deleteLivePhotoCachesFile];
            return;
        }
        if (assetModel9) {
            [weakSelf.manager addCustomAssetModel:@[assetModel9]];
        }
        [weakSelf.photoView refreshView];
    } cancelClick:nil];
}
- (void)previewClick {
    HXCustomAssetModel *assetModel1 = [HXCustomAssetModel assetWithLocaImageName:@"1" selected:YES];
    // selected 为NO 的会过滤掉
    HXCustomAssetModel *assetModel2 = [HXCustomAssetModel assetWithLocaImageName:@"2" selected:NO];
    HXCustomAssetModel *assetModel3 = [HXCustomAssetModel assetWithNetworkImageURL:[NSURL URLWithString:@"http://tsnrhapp.oss-cn-hangzhou.aliyuncs.com/1466408576222.jpg"] selected:YES];
    HXCustomAssetModel *assetModel4 = [HXCustomAssetModel assetWithNetworkImageURL:[NSURL URLWithString:@"http://tsnrhapp.oss-cn-hangzhou.aliyuncs.com/0034821a-6815-4d64-b0f2-09103d62630d.jpg"] selected:NO];
    NSURL *url = [[NSBundle mainBundle] URLForResource:@"LocalSampleVideo" withExtension:@"mp4"];
    HXCustomAssetModel *assetModel5 = [HXCustomAssetModel assetWithLocalVideoURL:url selected:YES];
    NSURL *gifURL = [[NSBundle mainBundle] URLForResource:@"IMG_0168" withExtension:@"GIF"];
    HXCustomAssetModel *assetModel6 = [HXCustomAssetModel assetWithImagePath:gifURL selected:YES];
    
    HXCustomAssetModel *assetModel7 = [HXCustomAssetModel assetWithNetworkVideoURL:[NSURL URLWithString:@"http://oss-cn-hangzhou.aliyuncs.com/tsnrhapp/fff42798-8025-4170-a36d-3257be267f29.mp4"] videoCoverURL:[NSURL URLWithString:@"http://oss-cn-hangzhou.aliyuncs.com/tsnrhapp/d3c3bbe6-02ce-4f17-a75b-3387d52b0a4a.jpg"] videoDuration:13 selected:YES];
    
    HXCustomAssetModel *assetModel8 = [HXCustomAssetModel assetWithNetworkVideoURL:[NSURL URLWithString:@"http://oss-cn-hangzhou.aliyuncs.com/tsnrhapp/2280ec38-5873-4b3f-8784-a361645c8854.mp4"] videoCoverURL:[NSURL URLWithString:@"http://oss-cn-hangzhou.aliyuncs.com/tsnrhapp/5ed15ef7-3411-4f5e-839b-10664d796919.jpg"] videoDuration:61 selected:YES];
    
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
        HXPhotoBottomViewModel *model = [[HXPhotoBottomViewModel alloc] init];
        model.title = @"保存";
        model.subTitle = @"这是一个长按事件";
        [HXPhotoBottomSelectView showSelectViewWithModels:@[model] headerView:nil cancelTitle:nil selectCompletion:^(NSInteger index, HXPhotoBottomViewModel * _Nonnull model) {
            if (index == 0) {
                // 保存，处理...
            }
        } cancelClick:nil];
//        hx_showAlert(previewViewController, @"提示", @"长按事件", @"确定", nil, nil, nil);
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
    [photoManager addCustomAssetModel:@[assetModel1, assetModel2, assetModel3, assetModel4, assetModel5, assetModel6, assetModel7, assetModel8]];
    /// 这里需要注意一下
    /// 这里的photoManager 和 self.manager 不是同一个
    /// 虽然展示的是一样的内容但是是两个单独的东西
    /// 所以会出现通过外部预览时,网络图片是正方形被裁剪过了样子.这是因为photoManager这个里面的网络图片还未下载的原因
    /// 如果将 photoManager 换成 self.manager 则不会出现这样的现象
    [self hx_presentPreviewPhotoControllerWithManager:photoManager
                                         previewStyle:HXPhotoViewPreViewShowStyleDark
                                         currentIndex:7
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
