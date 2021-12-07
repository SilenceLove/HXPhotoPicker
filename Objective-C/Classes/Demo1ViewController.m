//
//  Demo1ViewController.m
//  HXPhotoPickerExample
//
//  Created by Silence on 17/2/17.
//  Copyright © 2017年 Silence. All rights reserved.
//

#import "Demo1ViewController.h"
#import "HXPhotoPicker.h"
#import <SystemConfiguration/CaptiveNetwork.h>

@interface Demo1ViewController ()<HXCustomNavigationControllerDelegate,UIImagePickerControllerDelegate,UIScrollViewDelegate>
@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (weak, nonatomic) IBOutlet UILabel *total;
//@property (weak, nonatomic) IBOutlet UILabel *photo;
//@property (weak, nonatomic) IBOutlet UILabel *video;
@property (weak, nonatomic) IBOutlet UILabel *original;
@property (weak, nonatomic) IBOutlet UISwitch *camera;
@property (strong, nonatomic) HXPhotoManager *manager;
@property (weak, nonatomic) IBOutlet UITextField *photoText;
@property (weak, nonatomic) IBOutlet UITextField *videoText;
@property (weak, nonatomic) IBOutlet UITextField *totalText;
@property (weak, nonatomic) IBOutlet UITextField *columnText;
@property (weak, nonatomic) IBOutlet UISwitch *addCamera; 
@property (weak, nonatomic) IBOutlet UISwitch *showHeaderSection;
@property (weak, nonatomic) IBOutlet UISwitch *reverse;
@property (weak, nonatomic) IBOutlet UISegmentedControl *selectedTypeView;
@property (weak, nonatomic) IBOutlet UISwitch *saveAblum;
@property (weak, nonatomic) IBOutlet UISwitch *icloudSwitch;
@property (weak, nonatomic) IBOutlet UISwitch *downloadICloudAsset;
@property (weak, nonatomic) IBOutlet UISegmentedControl *tintColor;
@property (weak, nonatomic) IBOutlet UISwitch *hideOriginal;
@property (weak, nonatomic) IBOutlet UISwitch *synchTitleColor;
@property (weak, nonatomic) IBOutlet UISegmentedControl *navBgColor;
@property (weak, nonatomic) IBOutlet UISegmentedControl *navTitleColor;
@property (weak, nonatomic) IBOutlet UISwitch *useCustomCamera;
@property (strong, nonatomic) UIColor *bottomViewBgColor; 
@property (weak, nonatomic) IBOutlet UITextField *clarityText;
@property (weak, nonatomic) IBOutlet UISwitch *photoCanEditSwitch;
@property (weak, nonatomic) IBOutlet UISwitch *videoCanEditSwitch;
@property (weak, nonatomic) IBOutlet UISegmentedControl *albumShowModeSwitch;
@property (weak, nonatomic) IBOutlet UISwitch *createTimeSortSwitch;

@end

@implementation Demo1ViewController

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
        _manager = [[HXPhotoManager alloc] initWithType:HXPhotoManagerSelectedTypePhotoAndVideo];
        _manager.configuration.videoMaxNum = 5;
        _manager.configuration.deleteTemporaryPhoto = NO;
        _manager.configuration.lookLivePhoto = YES;
        _manager.configuration.saveSystemAblum = YES;
        _manager.configuration.selectTogether = YES;
        _manager.configuration.creationDateSort = YES;
//        _manager.configuration.supportRotation = NO;
//        _manager.configuration.cameraCellShowPreview = NO;
//        _manager.configuration.themeColor = [UIColor redColor];
        _manager.configuration.navigationBar = ^(UINavigationBar *navigationBar, UIViewController *viewController) {
//            [navigationBar setBackgroundImage:[UIImage imageNamed:@"APPCityPlayer_bannerGame"] forBarMetrics:UIBarMetricsDefault];
//            navigationBar.barTintColor = [UIColor redColor];
        };
//        _manager.configuration.sectionHeaderTranslucent = NO;
//        _manager.configuration.navBarBackgroudColor = [UIColor redColor];
//        _manager.configuration.sectionHeaderSuspensionBgColor = [UIColor redColor];
//        _manager.configuration.sectionHeaderSuspensionTitleColor = [UIColor whiteColor];
//        _manager.configuration.statusBarStyle = UIStatusBarStyleLightContent;
//        _manager.configuration.selectedTitleColor = [UIColor redColor];
        
//        _manager.configuration.requestImageAfterFinishingSelection = YES;
        
        __weak typeof(self) weakSelf = self;
        _manager.configuration.photoListBottomView = ^(HXPhotoBottomView *bottomView) {
            if (weakSelf.manager.configuration.photoStyle != HXPhotoStyleDark) {
                bottomView.bgView.barTintColor = weakSelf.bottomViewBgColor;
            }
        };
        _manager.configuration.previewBottomView = ^(HXPhotoPreviewBottomView *bottomView) {
            if (weakSelf.manager.configuration.photoStyle != HXPhotoStyleDark) {
                bottomView.bgView.barTintColor = weakSelf.bottomViewBgColor;
                bottomView.tipView.barTintColor = bottomView.bgView.barTintColor;
            }
        };
        _manager.configuration.albumListCollectionView = ^(UICollectionView *collectionView) {
//            NSSLog(@"albumList:%@",collectionView);
        };
        _manager.configuration.photoListCollectionView = ^(UICollectionView *collectionView) {
//            NSSLog(@"photoList:%@",collectionView);
        };
        _manager.configuration.previewCollectionView = ^(UICollectionView *collectionView) {
//            NSSLog(@"preview:%@",collectionView);
        };
//        _manager.configuration.movableCropBox = YES;
//        _manager.configuration.movableCropBoxEditSize = YES;
//        _manager.configuration.movableCropBoxCustomRatio = CGPointMake(1, 1);
        
        // 使用自定义的相机  这里拿系统相机做示例
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
//        _manager.shouldSelectModel = ^NSString *(HXPhotoModel *model) {
//            // 如果return nil 则会走默认的判断是否达到最大值
//            //return nil;
//            return @"Demo1 116 - 120 行注释掉就能选啦~\(≧▽≦)/~";
//        };
        _manager.configuration.videoCanEdit = NO;
        _manager.configuration.photoCanEdit = NO;
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
        self.view.backgroundColor = [UIColor systemBackgroundColor];
    }
#endif
    self.selectedTypeView.selectedSegmentIndex = 2;
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"清空选择" style:UIBarButtonItemStylePlain target:self action:@selector(didRightClick)];
    self.scrollView.delegate = self;
    if (HX_IS_IPhoneX_All) {
        self.clarityText.text = @"1.8";
    }else if ([UIScreen mainScreen].bounds.size.width == 320) {
        self.clarityText.text = @"1.2";
    }else if ([UIScreen mainScreen].bounds.size.width == 375) {
        self.clarityText.text = @"1.5";
    }else {
        self.clarityText.text = @"1.4";
    } 
}
- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    [self.view endEditing:YES];
}
- (void)didRightClick {
    [self.manager clearSelectedList];
    self.total.text = @"总数量：0   ( 照片：0   视频：0 )";
    self.original.text = @"NO";
}
- (IBAction)goAlbum:(id)sender {
    self.manager.configuration.clarityScale = self.clarityText.text.floatValue;
    if (self.tintColor.selectedSegmentIndex == 0) {
        self.manager.configuration.themeColor = self.view.tintColor;
        self.manager.configuration.cellSelectedTitleColor = nil;
    }else if (self.tintColor.selectedSegmentIndex == 1) {
        self.manager.configuration.themeColor = [UIColor redColor];
        self.manager.configuration.cellSelectedTitleColor = [UIColor redColor];
    }else if (self.tintColor.selectedSegmentIndex == 2) {
        self.manager.configuration.themeColor = [UIColor whiteColor];
        self.manager.configuration.cellSelectedTitleColor = [UIColor whiteColor];
    }else if (self.tintColor.selectedSegmentIndex == 3) {
        self.manager.configuration.themeColor = [UIColor blackColor];
        self.manager.configuration.cellSelectedTitleColor = [UIColor blackColor];
    }else if (self.tintColor.selectedSegmentIndex == 4) {
        self.manager.configuration.themeColor = [UIColor orangeColor];
        self.manager.configuration.cellSelectedTitleColor = [UIColor orangeColor];
    }else {
        self.manager.configuration.themeColor = self.view.tintColor;
        self.manager.configuration.cellSelectedTitleColor = nil;
    }
    
    if (self.navBgColor.selectedSegmentIndex == 0) {
        self.manager.configuration.navBarBackgroudColor = nil;
        self.manager.configuration.statusBarStyle = UIStatusBarStyleDefault;
//        self.manager.configuration.sectionHeaderTranslucent = YES;
        self.bottomViewBgColor = nil;
        self.manager.configuration.cellSelectedBgColor = nil;
        self.manager.configuration.selectedTitleColor = nil;
//        self.manager.configuration.sectionHeaderSuspensionBgColor = nil;
//        self.manager.configuration.sectionHeaderSuspensionTitleColor = nil;
    }else if (self.navBgColor.selectedSegmentIndex == 1) {
        self.manager.configuration.navBarBackgroudColor = [UIColor redColor];
        self.manager.configuration.statusBarStyle = UIStatusBarStyleLightContent;
//        self.manager.configuration.sectionHeaderTranslucent = NO;
        self.bottomViewBgColor = [UIColor redColor];
        self.manager.configuration.cellSelectedBgColor = [UIColor redColor];
        self.manager.configuration.selectedTitleColor = [UIColor redColor];
//        self.manager.configuration.sectionHeaderSuspensionBgColor = [UIColor redColor];
//        self.manager.configuration.sectionHeaderSuspensionTitleColor = [UIColor whiteColor];
    }else if (self.navBgColor.selectedSegmentIndex == 2) {
        self.manager.configuration.navBarBackgroudColor = [UIColor whiteColor];
        self.manager.configuration.statusBarStyle = UIStatusBarStyleDefault;
//        self.manager.configuration.sectionHeaderTranslucent = NO;
        self.bottomViewBgColor = [UIColor whiteColor];
        self.manager.configuration.cellSelectedBgColor = self.manager.configuration.themeColor;
        self.manager.configuration.cellSelectedTitleColor = [UIColor whiteColor];
        self.manager.configuration.selectedTitleColor = [UIColor whiteColor];
//        self.manager.configuration.sectionHeaderSuspensionBgColor = [UIColor whiteColor];
//        self.manager.configuration.sectionHeaderSuspensionTitleColor = [UIColor blackColor];
    }else if (self.navBgColor.selectedSegmentIndex == 3) {
        self.manager.configuration.navBarBackgroudColor = [UIColor blackColor];
        self.manager.configuration.statusBarStyle = UIStatusBarStyleLightContent;
//        self.manager.configuration.sectionHeaderTranslucent = NO;
        self.bottomViewBgColor = [UIColor blackColor];
        self.manager.configuration.cellSelectedBgColor = [UIColor blackColor];
        self.manager.configuration.selectedTitleColor = [UIColor blackColor];
//        self.manager.configuration.sectionHeaderSuspensionBgColor = [UIColor blackColor];
//        self.manager.configuration.sectionHeaderSuspensionTitleColor = [UIColor whiteColor];
    }else if (self.navBgColor.selectedSegmentIndex == 4) {
        self.manager.configuration.navBarBackgroudColor = [UIColor orangeColor];
        self.manager.configuration.statusBarStyle = UIStatusBarStyleLightContent;
//        self.manager.configuration.sectionHeaderTranslucent = NO;
        self.bottomViewBgColor = [UIColor orangeColor];
        self.manager.configuration.cellSelectedBgColor = [UIColor orangeColor];
        self.manager.configuration.selectedTitleColor = [UIColor orangeColor];
//        self.manager.configuration.sectionHeaderSuspensionBgColor = [UIColor orangeColor];
//        self.manager.configuration.sectionHeaderSuspensionTitleColor = [UIColor whiteColor];
    }else {
        self.manager.configuration.navBarBackgroudColor = nil;
        self.manager.configuration.statusBarStyle = UIStatusBarStyleDefault;
//        self.manager.configuration.sectionHeaderTranslucent = YES;
        self.bottomViewBgColor = nil;
        self.manager.configuration.cellSelectedBgColor = nil;
        self.manager.configuration.selectedTitleColor = nil;
//        self.manager.configuration.sectionHeaderSuspensionBgColor = nil;
//        self.manager.configuration.sectionHeaderSuspensionTitleColor = nil;
    }
    
    if (self.navTitleColor.selectedSegmentIndex == 0) {
        self.manager.configuration.navigationTitleColor = nil;
    }else if (self.navTitleColor.selectedSegmentIndex == 1) {
        self.manager.configuration.navigationTitleColor = [UIColor redColor];
    }else if (self.navTitleColor.selectedSegmentIndex == 2) {
        self.manager.configuration.navigationTitleColor = [UIColor whiteColor];
    }else if (self.navTitleColor.selectedSegmentIndex == 3) {
        self.manager.configuration.navigationTitleColor = [UIColor blackColor];
    }else if (self.navTitleColor.selectedSegmentIndex == 4) {
        self.manager.configuration.navigationTitleColor = [UIColor orangeColor];
    }else {
        self.manager.configuration.navigationTitleColor = nil;
    }
    self.manager.configuration.hideOriginalBtn = self.hideOriginal.on;
//    self.manager.configuration.filtrationICloudAsset = self.icloudSwitch.on;
    self.manager.configuration.photoMaxNum = self.photoText.text.integerValue;
    self.manager.configuration.videoMaxNum = self.videoText.text.integerValue;
    self.manager.configuration.maxNum = self.totalText.text.integerValue;
    self.manager.configuration.rowCount = self.columnText.text.integerValue;
//    self.manager.configuration.downloadICloudAsset = self.downloadICloudAsset.on;
    self.manager.configuration.saveSystemAblum = self.saveAblum.on;
    self.manager.configuration.showDateSectionHeader = self.showHeaderSection.on;
    self.manager.configuration.reverseDate = self.reverse.on;
    self.manager.configuration.navigationTitleSynchColor = self.synchTitleColor.on;
    self.manager.configuration.replaceCameraViewController = self.useCustomCamera.on;
    self.manager.configuration.openCamera = self.addCamera.on;
    self.manager.configuration.albumShowMode = self.albumShowModeSwitch.selectedSegmentIndex;
    self.manager.configuration.photoCanEdit = self.photoCanEditSwitch.on;
    self.manager.configuration.videoCanEdit = self.videoCanEditSwitch.on;
    self.manager.configuration.creationDateSort = self.createTimeSortSwitch.on;
    HXWeakSelf
//    [self hx_presentSelectPhotoControllerWithManager:self.manager delegate:self];
    [self hx_presentSelectPhotoControllerWithManager:self.manager didDone:^(NSArray<HXPhotoModel *> *allList, NSArray<HXPhotoModel *> *photoList, NSArray<HXPhotoModel *> *videoList, BOOL isOriginal, UIViewController *viewController, HXPhotoManager *manager) {
        weakSelf.total.text = [NSString stringWithFormat:@"总数量：%ld   ( 照片：%ld   视频：%ld )",allList.count, photoList.count, videoList.count];
        weakSelf.original.text = isOriginal ? @"YES" : @"NO";
        NSSLog(@"block - all - %@",allList);
        NSSLog(@"block - photo - %@",photoList);
        NSSLog(@"block - video - %@",videoList);
//        [photoList hx_requestImageWithOriginal:NO completion:^(NSArray<UIImage *> * _Nullable imageArray, NSArray<HXPhotoModel *> * _Nullable errorArray) {
//            NSSLog(@"images - %@", imageArray);
//        }];
    } cancel:^(UIViewController *viewController, HXPhotoManager *manager) {
        NSSLog(@"block - 取消了");
    }];
}
- (IBAction)selectTypeClick:(UISegmentedControl *)sender {
    if (sender.selectedSegmentIndex == 0) {
        self.manager.type = HXPhotoManagerSelectedTypePhoto;
    }else if (sender.selectedSegmentIndex == 1) {
        self.manager.type = HXPhotoManagerSelectedTypeVideo;
    }else {
        self.manager.type = HXPhotoManagerSelectedTypePhotoAndVideo;
    }
    [self.manager clearSelectedList];
}
//- (void)photoNavigationViewController:(HXCustomNavigationController *)photoNavigationViewController didDoneWithResult:(HXPickerResult *)result {
//    NSLog(@"开始");
//    [result getURLsWithVideoExportPreset:HXVideoExportPresetRatio_960x540 videoQuality:6 UrlHandler:^(HXAssetURLResult * _Nullable result, HXPhotoModel * _Nonnull photoModel, NSInteger index) {
//        NSLog(@"%@, %ld", result.url, index);
//    } completionHandler:^{
//        NSLog(@"结束");
//    }];
//}
- (void)albumListViewController:(HXAlbumListViewController *)albumListViewController didDoneAllList:(NSArray<HXPhotoModel *> *)allList photos:(NSArray<HXPhotoModel *> *)photoList videos:(NSArray<HXPhotoModel *> *)videoList original:(BOOL)original {
    self.total.text = [NSString stringWithFormat:@"总数量：%ld   ( 照片：%ld   视频：%ld )",allList.count, photoList.count, videoList.count];
    //    [NSString stringWithFormat:@"%ld个",allList.count];
    //    self.photo.text = [NSString stringWithFormat:@"%ld张",photos.count];
    //    self.video.text = [NSString stringWithFormat:@"%ld个",videos.count];
    self.original.text = original ? @"YES" : @"NO";
    NSSLog(@"delegate - all - %@",allList);
    NSSLog(@"delegate - photo - %@",photoList);
    NSSLog(@"delegate - video - %@",videoList);
}
- (IBAction)tb:(id)sender {
    UISwitch *sw = (UISwitch *)sender;
    self.manager.configuration.navigationTitleSynchColor = sw.on;
}
- (IBAction)yc:(id)sender {
    UISwitch *sw = (UISwitch *)sender;
    self.manager.configuration.hideOriginalBtn = sw.on;
}

- (IBAction)same:(id)sender {
    UISwitch *sw = (UISwitch *)sender;
    self.manager.configuration.selectTogether = sw.on;
}

- (IBAction)isLookGIFPhoto:(UISwitch *)sender {
    self.manager.configuration.lookGifPhoto = sender.on;
}

- (IBAction)isLookLivePhoto:(UISwitch *)sender {
    self.manager.configuration.lookLivePhoto = sender.on;
}
- (IBAction)photoCanEditClick:(id)sender {
    UISwitch *sw = (UISwitch *)sender;
    self.manager.configuration.photoCanEdit = sw.on;
}
- (IBAction)videoCaneEditClick:(UISwitch *)sender {
    self.manager.configuration.videoCanEdit = sender.on;
}

- (IBAction)addCamera:(id)sender {
    UISwitch *sw = (UISwitch *)sender;
    self.manager.configuration.openCamera = sw.on;
} 
- (IBAction)createTimeSortSwitch:(UISwitch *)sender {
    
}
- (void)dealloc {
    NSSLog(@"dealloc");
    self.scrollView.delegate = nil;
}
@end
