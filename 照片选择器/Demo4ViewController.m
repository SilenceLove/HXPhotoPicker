//
//  Demo4ViewController.m
//  照片选择器
//
//  Created by 洪欣 on 2017/7/1.
//  Copyright © 2017年 洪欣. All rights reserved.
//

#import "Demo4ViewController.h"
#import "HXPhotoPicker.h"

@interface Demo4ViewController ()<HXAlbumListViewControllerDelegate, HXPhotoViewControllerDelegate>
@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (strong, nonatomic) HXPhotoManager *manager;
@property (strong, nonatomic) HXDatePhotoToolManager *toolManager;
@end

@implementation Demo4ViewController
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
        _manager.configuration.singleSelected = YES;
        _manager.configuration.albumListTableView = ^(UITableView *tableView) {
//            NSSLog(@"%@",tableView);
        };
        _manager.configuration.singleJumpEdit = NO;
        _manager.configuration.movableCropBox = YES;
        _manager.configuration.movableCropBoxEditSize = YES;
//        _manager.configuration.requestImageAfterFinishingSelection = NO;
//        _manager.configuration.albumShowMode = HXPhotoAlbumShowModePopup;
//        _manager.configuration.movableCropBoxCustomRatio = CGPointMake(1, 1);
    }
    return _manager;
}

- (HXDatePhotoToolManager *)toolManager {
    if (!_toolManager) {
        _toolManager = [[HXDatePhotoToolManager alloc] init];
    }
    return _toolManager;
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
    
    UIBarButtonItem *photo = [[UIBarButtonItem alloc] initWithTitle:@"编辑照片" style:UIBarButtonItemStylePlain target:self action:@selector(editPhoto)];
    
    UIBarButtonItem *video = [[UIBarButtonItem alloc] initWithTitle:@"编辑视频" style:UIBarButtonItemStylePlain target:self action:@selector(editVideo)];
    
    self.navigationItem.rightBarButtonItems = @[photo, video];
}

- (void)editPhoto {
    HXPhotoModel *photoModel = [HXPhotoModel photoModelWithImage:[UIImage imageNamed:@"1"]];
    
    HXWeakSelf
    [self hx_presentPhotoEditViewControllerWithManager:self.manager photoModel:photoModel delegate:nil done:^(HXPhotoModel *beforeModel, HXPhotoModel *afterModel, HXPhotoEditViewController *viewController) {
        weakSelf.imageView.image = afterModel.thumbPhoto;
        NSSLog(@"%@", afterModel);
    } cancel:^(HXPhotoEditViewController *viewController) {
        NSSLog(@"%@", viewController);
    }];
}

- (void)editVideo {
    
    NSURL *url = [[NSBundle mainBundle] URLForResource:@"QQ空间视频_20180301091047" withExtension:@"mp4"];
    HXPhotoModel *videoModel = [HXPhotoModel photoModelWithVideoURL:url];
    
    HXWeakSelf
    [self hx_presentVideoEditViewControllerWithManager:self.manager videoModel:videoModel delegate:nil done:^(HXPhotoModel *beforeModel, HXPhotoModel *afterModel, HXVideoEditViewController *viewController) {
        
        weakSelf.imageView.image = afterModel.thumbPhoto;
        NSSLog(@"%@", afterModel);
    } cancel:^(HXVideoEditViewController *viewController) {
        NSSLog(@"%@", viewController);
    }];
    
}
- (IBAction)selectedPhoto:(id)sender {
    self.manager.configuration.saveSystemAblum = YES;
    HXWeakSelf
    [self hx_presentSelectPhotoControllerWithManager:self.manager didDone:^(NSArray<HXPhotoModel *> *allList, NSArray<HXPhotoModel *> *photoList, NSArray<HXPhotoModel *> *videoList, BOOL isOriginal, UIViewController *viewController, HXPhotoManager *manager) {
        HXPhotoModel *model = allList.firstObject;
        
        if (model.subType == HXPhotoModelMediaSubTypePhoto) {
            [weakSelf.view hx_showLoadingHUDText:@"获取图片中"];
            [model requestPreviewImageWithSize:PHImageManagerMaximumSize startRequestICloud:nil progressHandler:nil success:^(UIImage *image, HXPhotoModel *model, NSDictionary *info) {
                [weakSelf.view hx_handleLoading];
                weakSelf.imageView.image = image;
            } failed:^(NSDictionary *info, HXPhotoModel *model) {
                [weakSelf.view hx_handleLoading];
                [weakSelf.view hx_showImageHUDText:@"获取失败"];
            }];
        }else  if (model.subType == HXPhotoModelMediaSubTypeVideo) {
            [weakSelf.view hx_showLoadingHUDText:@"获取视频中"];
            [model exportVideoWithPresetName:AVAssetExportPresetHighestQuality startRequestICloud:nil iCloudProgressHandler:nil exportProgressHandler:^(float progress, HXPhotoModel *model) {
                NSSLog(@"视频导出进度 - %f",progress)
            } success:^(NSURL *videoURL, HXPhotoModel *model) {
                NSSLog(@"%@",videoURL);
                UIImage *image = [UIImage hx_thumbnailImageForVideo:videoURL atTime:0.1f];
                weakSelf.imageView.image = image;
                [weakSelf.view hx_handleLoading];
            } failed:^(NSDictionary *info, HXPhotoModel *model) {
                [weakSelf.view hx_handleLoading];
                [weakSelf.view hx_showImageHUDText:@"视频导出失败"];
            }];
            NSSLog(@"%ld个视频",videoList.count);
        }
    } cancel:^(UIViewController *viewController, HXPhotoManager *manager) {
        NSSLog(@"取消了");
    }];
}
- (void)albumListViewController:(HXAlbumListViewController *)albumListViewController didDoneAllList:(NSArray<HXPhotoModel *> *)allList photos:(NSArray<HXPhotoModel *> *)photoList videos:(NSArray<HXPhotoModel *> *)videoList original:(BOOL)original {
    if (photoList.count > 0) {
        HXPhotoModel *model = photoList.firstObject;
        self.imageView.image = model.previewPhoto;
        NSSLog(@"%ld张图片",photoList.count);
    }else if (videoList.count > 0) { 
        __weak typeof(self) weakSelf = self;
        [self.toolManager getSelectedImageList:allList success:^(NSArray<UIImage *> *imageList) {
            weakSelf.imageView.image = imageList.firstObject;
        } failed:^{
            
        }];
        
        // 通个这个方法将视频压缩写入临时目录获取视频URL  或者 通过这个获取视频在手机里的原路径 model.fileURL  可自己压缩
        [self.view hx_showLoadingHUDText:@"视频写入中"];
        [self.toolManager writeSelectModelListToTempPathWithList:videoList success:^(NSArray<NSURL *> *allURL, NSArray<NSURL *> *photoURL, NSArray<NSURL *> *videoURL) {
            NSSLog(@"%@",videoURL);
            [weakSelf.view hx_handleLoading];
        } failed:^{
            [weakSelf.view hx_handleLoading];
            [weakSelf.view hx_showImageHUDText:@"写入失败"];
            NSSLog(@"写入失败");
        }];
        NSSLog(@"%ld个视频",videoList.count);
    }
}
- (void)photoViewController:(HXPhotoViewController *)photoViewController didDoneAllList:(NSArray<HXPhotoModel *> *)allList photos:(NSArray<HXPhotoModel *> *)photoList videos:(NSArray<HXPhotoModel *> *)videoList original:(BOOL)original {
    if (photoList.count > 0) {
        HXPhotoModel *model = photoList.firstObject;
        self.imageView.image = model.previewPhoto;
        NSSLog(@"%ld张图片",photoList.count);
    }else if (videoList.count > 0) {
        __weak typeof(self) weakSelf = self;
        [self.toolManager getSelectedImageList:allList success:^(NSArray<UIImage *> *imageList) {
            weakSelf.imageView.image = imageList.firstObject;
        } failed:^{
            
        }];
        
        // 通个这个方法将视频压缩写入临时目录获取视频URL  或者 通过这个获取视频在手机里的原路径 model.fileURL  可自己压缩
        [self.view hx_showLoadingHUDText:@"视频写入中"];
        [self.toolManager writeSelectModelListToTempPathWithList:videoList success:^(NSArray<NSURL *> *allURL, NSArray<NSURL *> *photoURL, NSArray<NSURL *> *videoURL) {
            NSSLog(@"%@",videoURL);
            [weakSelf.view hx_handleLoading];
        } failed:^{
            [weakSelf.view hx_handleLoading];
            [weakSelf.view hx_showImageHUDText:@"写入失败"];
            NSSLog(@"写入失败");
        }];
        NSSLog(@"%ld个视频",videoList.count);
    }
}
@end
