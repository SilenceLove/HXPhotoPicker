//
//  WxMomentPublishViewController.m
//  HXPhotoPickerExample
//
//  Created by 洪欣 on 2020/8/4.
//  Copyright © 2020 洪欣. All rights reserved.
//

#import "WxMomentPublishViewController.h"
#import "HXPhotoPicker.h"
#import "HXPhotoCustomNavigationBar.h"
#import "UITextView+Placeholder.h"

@interface WxMomentPublishViewController ()<HXPhotoViewDelegate>
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *navbarHeightConstraint;
@property (weak, nonatomic) IBOutlet UINavigationBar *navbar;
@property (weak, nonatomic) IBOutlet UITextView *textView;
@property (weak, nonatomic) IBOutlet HXPhotoView *photoView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *photoViewHeightConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *bottomViewHeightConstraint;
@property (weak, nonatomic) IBOutlet UIImageView *deleteImageView;
@property (weak, nonatomic) IBOutlet UILabel *deleteTitleLb;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *bottomViewBottomConstraint;
@property (weak, nonatomic) IBOutlet UIView *bottomView;
@property (assign, nonatomic) BOOL needDeleteItem;
@property (strong, nonatomic) HXPhotoCustomNavigationBar *customNavBar;
@property (strong, nonatomic) UINavigationItem *navItem;
@property (strong, nonatomic) UIButton *publishBtn;
// 没有完全显示之前不加动画
@property (assign, nonatomic) BOOL didAppear;
@property (strong, nonatomic) NSMutableDictionary *assetURLDict;
@end

@implementation WxMomentPublishViewController
- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [self.view endEditing:YES];
}
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
    return UIStatusBarStyleDefault;
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
        [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDarkContent animated:YES];
        return;
    }
#endif
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault animated:YES];
}
- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
#ifdef __IPHONE_13_0
    if (@available(iOS 13.0, *)) {
        [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDarkContent animated:YES];
        return;
    }
#endif
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault animated:YES];
}
#pragma clang diagnostic pop
- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    self.didAppear = YES;
}
- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    self.navbarHeightConstraint.constant = hxNavigationBarHeight;
    self.didAppear = NO;
    
    self.textView.tintColor = [UIColor hx_colorWithHexStr:@"#07C160"];

    self.view.backgroundColor = [UIColor whiteColor];
#ifdef __IPHONE_13_0
    if (@available(iOS 13.0, *)) {
        self.view.backgroundColor = [UIColor colorWithDynamicProvider:^UIColor * _Nonnull(UITraitCollection * _Nonnull traitCollection) {
            if (traitCollection.userInterfaceStyle == UIUserInterfaceStyleDark) {
                return [UIColor hx_colorWithHexStr:@"#191918"];
            }
            return UIColor.whiteColor;
        }];
        self.photoView.backgroundColor = [UIColor colorWithDynamicProvider:^UIColor * _Nonnull(UITraitCollection * _Nonnull traitCollection) {
            if (traitCollection.userInterfaceStyle == UIUserInterfaceStyleDark) {
                return [UIColor hx_colorWithHexStr:@"#191918"];
            }
            return UIColor.whiteColor;
        }];
        self.textView.backgroundColor = [UIColor colorWithDynamicProvider:^UIColor * _Nonnull(UITraitCollection * _Nonnull traitCollection) {
            if (traitCollection.userInterfaceStyle == UIUserInterfaceStyleDark) {
                return [UIColor hx_colorWithHexStr:@"#191918"];
            }
            return UIColor.whiteColor;
        }];
    }
#endif
    [self.view addSubview:self.customNavBar];
    
    self.bottomViewHeightConstraint.constant = 80 + hxBottomMargin;
    self.bottomViewBottomConstraint.constant = -self.bottomViewHeightConstraint.constant;
    
    self.photoView.spacing = 5.f;
    self.photoView.delegate = self;
    self.photoView.deleteCellShowAlert = YES;
    self.photoView.outerCamera = YES;
    self.photoView.previewShowDeleteButton = YES;
    self.photoView.manager = self.photoManager;
}
- (void)backClick {
    if (self.photoManager.afterSelectedArray.count) {
        HXWeakSelf
        hx_showAlert(self, @"将此次编辑保留?", nil, @"不保留", @"保留", ^{
            [weakSelf.photoManager deleteLocalModelsInFile];
            [weakSelf back];
        }, ^{
            [weakSelf.view hx_showLoadingHUDText:nil];
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                BOOL success = [weakSelf.photoManager saveLocalModelsToFile];
                dispatch_async(dispatch_get_main_queue(), ^{
                    [weakSelf.view hx_handleLoading];
                    if (success) {
                        [weakSelf back];
                    }else {
                        [weakSelf.view hx_showImageHUDText:@"保存失败"];
                    }
                });
            });
        });
    }else {
        // 清空草稿
        [self.photoManager deleteLocalModelsInFile];
        [self back];
    }
}
- (void)back {
    // 因为manager上个界面也持有了，并不会释放。所以手动清空一下已选的数据
    [self.photoManager clearSelectedList];
    [self dismissViewControllerAnimated:YES completion:nil];
}
- (void)didPublishClick:(UIButton *)button {
    // 发布的时候也清空草稿
    [self.photoManager deleteLocalModelsInFile];
//    self.assetURLDict = [NSMutableDictionary dictionary];
    [self.view hx_showLoadingHUDText:nil];
    HXWeakSelf
    __block NSInteger count = 0;
    // 获取的都是原图
    for (HXPhotoModel *photoModel in self.photoManager.afterSelectedArray) {
        if (photoModel.type == HXPhotoModelMediaTypeLivePhoto ||
            photoModel.cameraPhotoType == HXPhotoModelMediaTypeCameraPhotoTypeLocalLivePhoto ||
            photoModel.cameraPhotoType == HXPhotoModelMediaTypeCameraPhotoTypeNetWorkLivePhoto) {
                [photoModel requestLivePhotoAssetsWithSuccess:^(NSURL * _Nullable imageURL, NSURL * _Nullable videoURL, BOOL isNetwork, HXPhotoModel * _Nullable model) {
                    if (isNetwork) {
                        // URL是网络地址
                        
                    }else {
                        
                    }
                    count++;
                    // 可以直接通过manager取地址，不过如果中间获取失败了可能为nil
                    // 为nil的情况需要单独处理
//                    [weakSelf.assetURLDict setObject:@{@"imageURL": imageURL, @"videoURL": videoURL} forKey:model.selectIndexStr];
                    if (count == weakSelf.photoManager.afterSelectedCount) {
                        [weakSelf.view hx_handleLoading];
                        [weakSelf fetchAssetURLCompletion];
                    }
                } failed:^(NSDictionary * _Nullable info, HXPhotoModel * _Nullable model) {
                    count++;
                    if (count == weakSelf.photoManager.afterSelectedCount) {
                        [weakSelf.view hx_handleLoading];
                        [weakSelf fetchAssetURLCompletion];
                    }
                }];
        }else {
            [photoModel getAssetURLWithSuccess:^(NSURL * _Nullable URL, HXPhotoModelMediaSubType mediaType, BOOL isNetwork, HXPhotoModel * _Nullable model) {
                count++;
                if (mediaType == HXPhotoModelMediaSubTypePhoto) {
//                    NSData *imageData = [NSData dataWithContentsOfURL:URL];
//                    UIImage *image = [UIImage imageWithData:imageData];
//                    UIImage *image = [UIImage imageWithContentsOfFile:URL.path];
                    // 图片
                    if (isNetwork) {
                        // URL是网络图片地址
                        
                    }
                }else if (mediaType == HXPhotoModelMediaSubTypeVideo) {
                    // 视频
                    if (isNetwork) {
                        // URL是网络视频地址
                        
                    }
                }
                // 可以直接通过manager取地址，不过如果中间获取失败了可能为nil
                // 为nil的情况需要单独处理
//                [weakSelf.assetURLDict setObject:URL forKey:model.selectIndexStr];
                if (count == weakSelf.photoManager.afterSelectedCount) {
                    [weakSelf.view hx_handleLoading];
                    [weakSelf fetchAssetURLCompletion];
                }
            } failed:^(NSDictionary * _Nullable info, HXPhotoModel * _Nullable model) {
                // 获取失败
                count++;
                if (count == weakSelf.photoManager.afterSelectedCount) {
                    [weakSelf.view hx_handleLoading];
                    [weakSelf fetchAssetURLCompletion];
                }
            }];
        }
    }
}
- (void)fetchAssetURLCompletion {
    // 可以直接通过manager取地址，不过如果中间获取失败了可能为nil，为nil的情况需要单独处理
    // 因为这里没有添加自定义资源，所以不做过多的类型判断
    for (HXPhotoModel *photoModel in self.photoManager.afterSelectedArray) {
        if (photoModel.subType == HXPhotoModelMediaSubTypePhoto) {
            if (photoModel.type == HXPhotoModelMediaTypeLivePhoto) {
                // livephoto被编辑后需要单独处理
                if (photoModel.photoEdit) {
                    NSSLog(@"\nLivePhoto被编辑后变成了静态图，图片地址%@", photoModel.imageURL);
                }else {
                    NSSLog(@"\n\nLivePhoto-图片地址：%@\nLivePhoto-视频地址：%@", photoModel.imageURL, photoModel.videoURL);
                }
            }else if (photoModel.type == HXPhotoModelMediaTypePhotoGif){
                NSSLog(@"\nGIF图片地址：%@", photoModel.imageURL);
            }else {
                NSSLog(@"\n图片地址：%@", photoModel.imageURL);
            }
        }else if (photoModel.subType == HXPhotoModelMediaSubTypeVideo) {
            NSSLog(@"\n视频地址：%@", photoModel.videoURL);
        }
    }
    /*
    // 因为获取得到的顺序是错乱的，需要先排序一下
    NSArray *keys = [self.assetURLDict.allKeys sortedArrayUsingComparator:^NSComparisonResult(NSString * obj1, NSString * obj2) {
        if (obj1.integerValue > obj2.integerValue) {
            return NSOrderedDescending;
        }else if (obj1.integerValue < obj2.integerValue) {
            return NSOrderedAscending;
        }else {
            return NSOrderedSame;
        }
    }];
    // 排序完后的顺序就是当前选择的顺序
    for (NSString *key in keys) {
        // 如果有传入网络图片/视频这个URL就可能是网络/视频，注意在获取的时候区分
        id obj = self.assetURLDict[key];
        if ([obj isKindOfClass:[NSURL class]]) {
            NSSLog(@"%@", obj);
        }else if ([obj isKindOfClass:[NSDictionary class]]) {
            NSURL *imageURL = obj[@"imageURL"];
            NSURL *videoURL = obj[@"videoURL"];
            NSSLog(@"LivePhoto：\nimageURL - %@\nvideoURL - %@", imageURL, videoURL);
        }
    }
     */
    HXWeakSelf
    NSString *tipString;
    HXPhotoModel *photoModel = self.photoManager.afterSelectedArray.firstObject;
    // 因为图片和视频不能同时选择，所以可以只判断第一个model是什么类型就可以知道这次获取的地址是什么类型
    if (photoModel.subType == HXPhotoModelMediaSubTypePhoto) {
        tipString = @"图片地址获取完成";
    }else if (photoModel.subType == HXPhotoModelMediaSubTypeVideo) {
        tipString = @"视频地址获取完成";
    }
    hx_showAlert(self, tipString, @"已打印在控制台", @"确定", nil, ^{
        [weakSelf back];
    }, nil);
}
- (void)photoView:(HXPhotoView *)photoView changeComplete:(NSArray<HXPhotoModel *> *)allList photos:(NSArray<HXPhotoModel *> *)photos videos:(NSArray<HXPhotoModel *> *)videos original:(BOOL)isOriginal {
    if (allList.count) {
        self.publishBtn.enabled = YES;
        [self.publishBtn setBackgroundColor:[UIColor hx_colorWithHexStr:@"#07C160"]];
    }else {
        self.publishBtn.enabled = NO;
        [self.publishBtn setBackgroundColor:[UIColor hx_colorWithHexStr:@"#f8f8f8"]];
    }
}

- (void)photoView:(HXPhotoView *)photoView updateFrame:(CGRect)frame {
    // 不要动画效果
//    if (self.didAppear) {
//        [UIView animateWithDuration:0.25 animations:^{
//            self.photoViewHeightConstraint.constant = frame.size.height;
//            [self.view layoutIfNeeded];
//        }];
//    }else {
        self.photoViewHeightConstraint.constant = frame.size.height;
//    }
}
- (void)photoView:(HXPhotoView *)photoView currentDeleteModel:(HXPhotoModel *)model currentIndex:(NSInteger)index {
    // 删除的时候需要将草稿删除
    if (self.photoManager.localModels) {
        NSMutableArray *localModels = self.photoManager.localModels.mutableCopy;
        if ([self.photoManager.localModels containsObject:model]) {
            [localModels removeObject:model];
        }
        self.photoManager.localModels = localModels.copy;
    }
}
- (BOOL)photoViewShouldDeleteCurrentMoveItem:(HXPhotoView *)photoView gestureRecognizer:(UILongPressGestureRecognizer *)longPgr indexPath:(NSIndexPath *)indexPath {
    return self.needDeleteItem;
}
- (void)photoView:(HXPhotoView *)photoView gestureRecognizerBegan:(UILongPressGestureRecognizer *)longPgr indexPath:(NSIndexPath *)indexPath {
    [UIView animateWithDuration:0.25 animations:^{
        self.bottomViewBottomConstraint.constant = 0;
        [self.view layoutIfNeeded];
    }];
}
- (void)photoView:(HXPhotoView *)photoView gestureRecognizerChange:(UILongPressGestureRecognizer *)longPgr indexPath:(NSIndexPath *)indexPath {
    CGPoint point = [longPgr locationInView:self.view];
    if (point.y >= self.bottomView.hx_y) {
        self.deleteImageView.highlighted = YES;
        self.deleteTitleLb.text = @"松手即可删除";
    }else {
        self.deleteImageView.highlighted = NO;
        self.deleteTitleLb.text = @"拖动到此处删除";
    }
}
- (void)photoView:(HXPhotoView *)photoView gestureRecognizerEnded:(UILongPressGestureRecognizer *)longPgr indexPath:(NSIndexPath *)indexPath {
    CGPoint point = [longPgr locationInView:self.view];
    if (point.y >= self.bottomView.hx_y) {
        self.needDeleteItem = YES;
        [self.photoView deleteModelWithIndex:indexPath.item];
    }else {
        self.needDeleteItem = NO;
    }
    [UIView animateWithDuration:0.25 animations:^{
        self.bottomViewBottomConstraint.constant = -self.bottomViewHeightConstraint.constant;
        [self.view layoutIfNeeded];
    } completion:^(BOOL finished) {
        self.deleteImageView.highlighted = NO;
        self.deleteTitleLb.text = @"拖动到此处删除";
    }];
}


- (HXPhotoCustomNavigationBar *)customNavBar {
    if (!_customNavBar) {
        _customNavBar = [[HXPhotoCustomNavigationBar alloc] initWithFrame:CGRectMake(0, 0, HX_ScreenWidth, hxNavigationBarHeight)];
        _customNavBar.tintColor = [UIColor hx_colorWithHexStr:@"#333333"];
#ifdef __IPHONE_13_0
        if (@available(iOS 13.0, *)) {
            _customNavBar.tintColor = [UIColor colorWithDynamicProvider:^UIColor * _Nonnull(UITraitCollection * _Nonnull traitCollection) {
                if (traitCollection.userInterfaceStyle == UIUserInterfaceStyleDark) {
                    return [UIColor hx_colorWithHexStr:@"#ffffff"];
                }
                return [UIColor hx_colorWithHexStr:@"#333333"];
            }];
        }
#endif
        [_customNavBar setBackgroundImage:[UIImage hx_imageWithColor:[UIColor clearColor] havingSize:CGSizeMake(HX_ScreenWidth, hxNavigationBarHeight)] forBarMetrics:UIBarMetricsDefault];
        [_customNavBar setShadowImage:[UIImage new]];
        [_customNavBar pushNavigationItem:self.navItem animated:NO];
    }
    return _customNavBar;
}
- (UINavigationItem *)navItem {
    if (!_navItem) {
        _navItem = [[UINavigationItem alloc] init];
        _navItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"取消" style:UIBarButtonItemStylePlain target:self action:@selector(backClick)];
        _navItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:self.publishBtn];
    }
    return _navItem;
}
- (UIButton *)publishBtn {
    if (!_publishBtn) {
        _publishBtn = [UIButton buttonWithType:UIButtonTypeSystem];
        [_publishBtn setTitle:@"发表" forState:UIControlStateNormal];
        [_publishBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [_publishBtn setTitleColor:[UIColor hx_colorWithHexStr:@"#999999"] forState:UIControlStateDisabled];
        [_publishBtn setBackgroundColor:[UIColor hx_colorWithHexStr:@"#07C160"]];
        _publishBtn.titleLabel.font = [UIFont systemFontOfSize:15];
        _publishBtn.hx_size = CGSizeMake(60, 30);
        _publishBtn.layer.cornerRadius = 3;
        [_publishBtn addTarget:self action:@selector(didPublishClick:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _publishBtn;
}
@end
