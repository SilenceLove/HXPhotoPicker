//
//  Demo2ViewController.m
//  HXPhotoPickerExample
//
//  Created by 洪欣 on 17/2/17.
//  Copyright © 2017年 洪欣. All rights reserved.
//

#import "Demo2ViewController.h" 
#import "HXPhotoPicker.h"
#import "SettingViewController.h"

static const CGFloat kPhotoViewMargin = 12.0;

@interface Demo2ViewController ()<HXPhotoViewDelegate,UIImagePickerControllerDelegate, HXPhotoViewCellCustomProtocol>

@property (strong, nonatomic) HXPhotoManager *manager;
@property (weak, nonatomic) HXPhotoView *photoView;
@property (strong, nonatomic) UIScrollView *scrollView;

@property (strong, nonatomic) UIButton *bottomView;

@property (assign, nonatomic) BOOL needDeleteItem;

@property (assign, nonatomic) BOOL showHud;

@end

@implementation Demo2ViewController
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
- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self changeStatus];
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
- (UIButton *)bottomView {
    if (!_bottomView) {
        _bottomView = [UIButton buttonWithType:UIButtonTypeCustom];
        [_bottomView setTitle:@"删除" forState:UIControlStateNormal];
        [_bottomView setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [_bottomView setBackgroundColor:[UIColor redColor]];
        _bottomView.frame = CGRectMake(0, self.view.hx_h - 50 - hxBottomMargin, self.view.hx_w, 50 + hxBottomMargin);
        _bottomView.alpha = 0;
    }
    return _bottomView;
} 
- (HXPhotoManager *)manager {
    if (!_manager) {
        _manager = [[HXPhotoManager alloc] initWithType:HXPhotoManagerSelectedTypePhotoAndVideo];
//        _manager.configuration.openCamera = NO;
        _manager.configuration.type = HXConfigurationTypeWXChat;
//        _manager.configuration.requestImageAfterFinishingSelection = YES;
//        _manager.configuration.lookLivePhoto = YES;
//        _manager.configuration.photoEditConfigur.onlyCliping = YES;
//        _manager.configuration.navBarBackgroundImage = [UIImage imageNamed:@"APPCityPlayer_bannerGame"];
        HXWeakSelf
//        _manager.configuration.showOriginalBytes = YES;
//        _manager.configuration.photoEditConfigur.aspectRatio = HXPhotoEditAspectRatioType_Original;
//        _manager.configuration.photoEditConfigur.customAspectRatio = CGSizeMake(1, 1);
        _manager.configuration.photoListBottomView = ^(HXPhotoBottomView *bottomView) {
//            bottomView.bgView.translucent = NO;
//            if ([HXPhotoCommon photoCommon].isDark) {
//                bottomView.bgView.barTintColor = [UIColor blackColor];
//            }else {
//                bottomView.bgView.barTintColor = [UIColor colorWithRed:60.f / 255.f green:131.f / 255.f blue:238.f / 255.f alpha:1];
//            }
        };
        _manager.configuration.previewBottomView = ^(HXPhotoPreviewBottomView *bottomView) {
//            bottomView.bgView.translucent = NO;
//            bottomView.tipView.translucent = NO;
//            if ([HXPhotoCommon photoCommon].isDark) {
//                bottomView.bgView.barTintColor = [UIColor blackColor];
//                bottomView.tipView.barTintColor = [UIColor blackColor];
//            }else {
//                bottomView.bgView.barTintColor = [UIColor colorWithRed:60.f / 255.f green:131.f / 255.f blue:238.f / 255.f alpha:1];
//                bottomView.tipView.barTintColor = [UIColor colorWithRed:60.f / 255.f green:131.f / 255.f blue:238.f / 255.f alpha:1];
//            }
        };
        
//        _manager.configuration.photoEditConfigur.requestChartletModels = ^(void (^ _Nonnull chartletModels)(NSArray<HXPhotoEditChartletTitleModel *> * _Nonnull)) {
//            // 模仿网络请求获取贴图资源
//            HXPhotoEditChartletTitleModel *netModel = [HXPhotoEditChartletTitleModel modelWithNetworkNURL:[NSURL URLWithString:@"http://tsnrhapp.oss-cn-hangzhou.aliyuncs.com/chartle/xxy_s_highlighted.png"]];
//            NSString *prefix = @"http://tsnrhapp.oss-cn-hangzhou.aliyuncs.com/chartle/xxy%d.png";
//            NSMutableArray *netModels = @[].mutableCopy;
//            for (int i = 1; i <= 40; i++) {
//                [netModels addObject:[HXPhotoEditChartletModel modelWithNetworkNURL:[NSURL URLWithString:[NSString stringWithFormat:prefix ,i]]]];
//            }
//            netModel.models = netModels.copy;
//            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0f * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
//                // 这里没有模仿做缓存处理，需要自己做缓存处理
//                if (chartletModels) {
//                    chartletModels(@[netModel]);
//                }
//            });
//        };
        _manager.configuration.shouldUseCamera = ^(UIViewController *viewController, HXPhotoConfigurationCameraType cameraType, HXPhotoManager *manager) {
            
            // 这里拿使用系统相机做例子
            UIImagePickerController *imagePickerController = [[UIImagePickerController alloc] init];
            imagePickerController.delegate = (id)weakSelf;
            imagePickerController.allowsEditing = NO;
            NSString *requiredMediaTypeImage = ( NSString *)kUTTypeImage;
            NSString *requiredMediaTypeMovie = ( NSString *)kUTTypeMovie;
            NSArray *arrMediaTypes;
            if (cameraType == HXPhotoConfigurationCameraTypePhoto) {
                arrMediaTypes=[NSArray arrayWithObjects:requiredMediaTypeImage,nil];
            }else if (cameraType == HXPhotoConfigurationCameraTypeVideo) {
                arrMediaTypes=[NSArray arrayWithObjects:requiredMediaTypeMovie,nil];
            }else {
                arrMediaTypes=[NSArray arrayWithObjects:requiredMediaTypeImage, requiredMediaTypeMovie,nil];
            }
            [imagePickerController setMediaTypes:arrMediaTypes];
            // 设置录制视频的质量
            [imagePickerController setVideoQuality:UIImagePickerControllerQualityTypeHigh];
            //设置最长摄像时间
            [imagePickerController setVideoMaximumDuration:60.f];
            imagePickerController.sourceType = UIImagePickerControllerSourceTypeCamera;
            imagePickerController.navigationController.navigationBar.tintColor = [UIColor whiteColor];
            imagePickerController.modalPresentationStyle=UIModalPresentationOverCurrentContext;
            [viewController presentViewController:imagePickerController animated:YES completion:nil];
        };
    }
    return _manager;
}
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString *,id> *)info {
    [picker dismissViewControllerAnimated:YES completion:nil];
    
    NSString *mediaType = [info objectForKey:UIImagePickerControllerMediaType];
    HXWeakSelf
    if ([mediaType isEqualToString:(NSString *)kUTTypeImage]) {
        UIImage *image = [info objectForKey:UIImagePickerControllerOriginalImage];
        if (self.manager.configuration.saveSystemAblum) {
            [HXPhotoTools savePhotoToCustomAlbumWithName:self.manager.configuration.customAlbumName photo:image location:nil complete:^(HXPhotoModel *model, BOOL success) {
                if (success) {
                    if (weakSelf.manager.configuration.useCameraComplete) {
                        weakSelf.manager.configuration.useCameraComplete(model);
                    }
                }else {
                    [weakSelf.view hx_showImageHUDText:@"保存图片失败"];
                }
            }];
        }else {
            HXPhotoModel *model = [HXPhotoModel photoModelWithImage:image];
            if (self.manager.configuration.useCameraComplete) {
                self.manager.configuration.useCameraComplete(model);
            }
        }
    }else  if ([mediaType isEqualToString:(NSString *)kUTTypeMovie]) {
        NSURL *url = info[UIImagePickerControllerMediaURL];
        
        if (self.manager.configuration.saveSystemAblum) {
            [HXPhotoTools saveVideoToCustomAlbumWithName:self.manager.configuration.customAlbumName videoURL:url location:nil complete:^(HXPhotoModel *model, BOOL success) {
                if (success) {
                    if (weakSelf.manager.configuration.useCameraComplete) {
                        weakSelf.manager.configuration.useCameraComplete(model);
                    }
                }else {
                    [weakSelf.view hx_showImageHUDText:@"保存视频失败"];
                }
            }];
        }else {
            HXPhotoModel *model = [HXPhotoModel photoModelWithVideoURL:url];
            if (self.manager.configuration.useCameraComplete) {
                self.manager.configuration.useCameraComplete(model);
            }
        }
    }
}
- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [picker dismissViewControllerAnimated:YES completion:nil];
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
                return [UIColor hx_colorWithHexStr:@"#191918"];
            }
            return UIColor.whiteColor;
        }];
    }
#endif
    
    UIScrollView *scrollView = [[UIScrollView alloc] initWithFrame:self.view.bounds];
    scrollView.alwaysBounceVertical = YES;
    [self.view addSubview:scrollView];
    self.scrollView = scrollView;
    
    CGFloat width = scrollView.frame.size.width;
    HXPhotoView *photoView = [HXPhotoView photoManager:self.manager scrollDirection:UICollectionViewScrollDirectionVertical];
    photoView.frame = CGRectMake(0, kPhotoViewMargin, width, 0);
    photoView.collectionView.contentInset = UIEdgeInsetsMake(0, kPhotoViewMargin, 0, kPhotoViewMargin);
//    photoView.spacing = kPhotoViewMargin;
//    photoView.lineCount = 1;
    photoView.delegate = self;
//    photoView.cellCustomProtocol = self;
    photoView.outerCamera = YES;
    photoView.previewStyle = HXPhotoViewPreViewShowStyleDark;
    photoView.previewShowDeleteButton = YES;
    photoView.showAddCell = YES;
//    photoView.showDeleteNetworkPhotoAlert = YES;
//    photoView.adaptiveDarkness = NO;
//    photoView.previewShowBottomPageControl = NO;
    [photoView.collectionView reloadData];
    [scrollView addSubview:photoView];
    self.photoView = photoView;
    
    UIBarButtonItem *cameraItem = [[UIBarButtonItem alloc] initWithTitle:@"设置" style:UIBarButtonItemStylePlain target:self action:@selector(didNavBtnClick)];
    
    self.navigationItem.rightBarButtonItems = @[cameraItem];
    
    [self.view addSubview:self.bottomView];
//    [UINavigationBar appearance].translucent = NO;
}
- (void)dealloc {
    NSSLog(@"dealloc");
}
- (void)didNavBtnClick {
    SettingViewController *vc = [[SettingViewController alloc] init];
    vc.manager = self.manager;
    HXWeakSelf
    vc.saveCompletion = ^(HXPhotoManager * _Nonnull manager) {
        weakSelf.manager = manager;
        [weakSelf.photoView refreshView];
    };
    [self.navigationController pushViewController:vc animated:YES];
//    if (self.manager.configuration.specialModeNeedHideVideoSelectBtn && !self.manager.configuration.selectTogether && self.manager.configuration.videoMaxNum == 1) {
//        if (self.manager.afterSelectedVideoArray.count) {
//            [self.view hx_showImageHUDText:@"请先删除视频"];
//            return;
//        }
//    }
//    [self.photoView goPhotoViewController];
}

- (void)photoView:(HXPhotoView *)photoView changeComplete:(NSArray<HXPhotoModel *> *)allList photos:(NSArray<HXPhotoModel *> *)photos videos:(NSArray<HXPhotoModel *> *)videos original:(BOOL)isOriginal {
//    [self changeStatus];
//    NSSLog(@"%@",[videos.firstObject videoURL]);
//    HXPhotoModel *photoModel = allList.firstObject;
    
//    [allList hx_requestImageWithOriginal:isOriginal completion:^(NSArray<UIImage *> * _Nullable imageArray, NSArray<HXPhotoModel *> * _Nullable errorArray) {
//        // imageArray 获取成功的image数组
//        // errorArray 获取失败的model数组
//        NSSLog(@"\nimage: %@\nerror: %@",imageArray,errorArray);
//    }];
}
- (void)photoViewCurrentSelected:(NSArray<HXPhotoModel *> *)allList photos:(NSArray<HXPhotoModel *> *)photos videos:(NSArray<HXPhotoModel *> *)videos original:(BOOL)isOriginal {
    for (HXPhotoModel *photoModel in allList) {
        NSSLog(@"当前选择----> %@", photoModel.selectIndexStr);
    }
}
- (void)photoView:(HXPhotoView *)photoView deleteNetworkPhoto:(NSString *)networkPhotoUrl {
    NSSLog(@"%@",networkPhotoUrl);
}

//- (CGFloat)photoViewHeight:(HXPhotoView *)photoView {
//    return 140;
//}
- (void)photoView:(HXPhotoView *)photoView updateFrame:(CGRect)frame {
    NSSLog(@"%@",NSStringFromCGRect(frame));
    self.scrollView.contentSize = CGSizeMake(self.scrollView.frame.size.width, CGRectGetMaxY(frame) + kPhotoViewMargin);
    
}
- (void)photoView:(HXPhotoView *)photoView currentDeleteModel:(HXPhotoModel *)model currentIndex:(NSInteger)index {
    NSSLog(@"%@ --> index - %ld",model,index);
}
- (BOOL)photoView:(HXPhotoView *)photoView collectionViewShouldSelectItemAtIndexPath:(NSIndexPath *)indexPath model:(HXPhotoModel *)model {
    return YES;
}

- (BOOL)photoViewShouldDeleteCurrentMoveItem:(HXPhotoView *)photoView gestureRecognizer:(UILongPressGestureRecognizer *)longPgr indexPath:(NSIndexPath *)indexPath {
    return self.needDeleteItem;
}
- (void)photoView:(HXPhotoView *)photoView gestureRecognizerBegan:(UILongPressGestureRecognizer *)longPgr indexPath:(NSIndexPath *)indexPath {
    [UIView animateWithDuration:0.25 animations:^{
        self.bottomView.alpha = 0.5;
    }];
    NSSLog(@"长按手势开始了 - %ld",indexPath.item);
}
- (void)photoView:(HXPhotoView *)photoView gestureRecognizerChange:(UILongPressGestureRecognizer *)longPgr indexPath:(NSIndexPath *)indexPath {
    CGPoint point = [longPgr locationInView:self.view];
    if (point.y >= self.bottomView.hx_y) {
        [UIView animateWithDuration:0.25 animations:^{
            self.bottomView.alpha = 1;
        }];
    }else {
        [UIView animateWithDuration:0.25 animations:^{
            self.bottomView.alpha = 0.5;
        }];
    }
    NSSLog(@"长按手势改变了 %@ - %ld",NSStringFromCGPoint(point), indexPath.item);
}
- (void)photoView:(HXPhotoView *)photoView gestureRecognizerEnded:(UILongPressGestureRecognizer *)longPgr indexPath:(NSIndexPath *)indexPath {
    CGPoint point = [longPgr locationInView:self.view];
    if (point.y >= self.bottomView.hx_y) {
        self.needDeleteItem = YES;
        [self.photoView deleteModelWithIndex:indexPath.item]; 
    }else {
        self.needDeleteItem = NO;
    }
    NSSLog(@"长按手势结束了 - %ld",indexPath.item);
    [UIView animateWithDuration:0.25 animations:^{
        self.bottomView.alpha = 0;
    }];
}

#pragma mark - < HXPhotoViewCellCustomProtocol >
//- (UIView *)customView:(HXPhotoSubViewCell *)cell indexPath:(NSIndexPath *)indexPath {
//    [cell hx_radiusWithRadius:10 corner:UIRectCornerAllCorners];
//    [cell.imageView hx_radiusWithRadius:10 corner:UIRectCornerAllCorners];
//    UIView *view = [[UIView alloc] init];
//    [view hx_radiusWithRadius:10 corner:UIRectCornerAllCorners];
//    view.backgroundColor = [UIColor redColor];
//
//    return view;
//}
//- (CGRect)customViewFrame:(HXPhotoSubViewCell *)cell indexPath:(NSIndexPath *)indexPath {
//    if (indexPath.item == 4) {
//        return CGRectMake(40, 40, 40, 40);
//    }
//    return CGRectMake(10, 10, 40, 40);
//}
//- (BOOL)shouldHiddenBottomType:(HXPhotoSubViewCell *)cell indexPath:(NSIndexPath *)indexPath {
//    if (indexPath.item == 2) {
//        return YES;
//    }
//    return NO;
//}

@end
