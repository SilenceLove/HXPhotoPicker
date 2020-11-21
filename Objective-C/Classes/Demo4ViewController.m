//
//  Demo4ViewController.m
//  HXPhotoPickerExample
//
//  Created by 洪欣 on 2017/7/1.
//  Copyright © 2017年 洪欣. All rights reserved.
//

#import "Demo4ViewController.h"
#import "HXPhotoPicker.h"
#import "HXPreviewVideoView.h"

@interface Demo4ViewController ()<HXAlbumListViewControllerDelegate, HXPhotoViewControllerDelegate>
@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (strong, nonatomic) HXPhotoManager *manager;
@property (weak, nonatomic) IBOutlet HXPreviewVideoView *videoView;
@property (strong, nonatomic) HXPhotoEdit *photoEdit;
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
- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.videoView cancelPlayer];
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
        _manager.configuration.type = HXConfigurationTypeWXChat;
        _manager.configuration.singleSelected = YES;
        _manager.configuration.lookGifPhoto = NO;
        _manager.configuration.albumListTableView = ^(UITableView *tableView) {
//            NSSLog(@"%@",tableView);
        };
        _manager.configuration.videoMaximumSelectDuration = 15.f;
        _manager.configuration.selectVideoBeyondTheLimitTimeAutoEdit = YES;
        _manager.configuration.singleJumpEdit = YES;
//        _manager.configuration.movableCropBox = YES;
        _manager.configuration.photoEditConfigur.onlyCliping = YES;
//        _manager.configuration.photoEditConfigur.aspectRatio = HXPhotoEditAspectRatioType_Custom;
//        _manager.configuration.photoEditConfigur.customAspectRatio = CGSizeMake(1, 1);
        
//        _manager.configuration.movableCropBoxEditSize = YES;
//        _manager.configuration.requestImageAfterFinishingSelection = NO;
//        _manager.configuration.albumShowMode = HXPhotoAlbumShowModePopup;
//        _manager.configuration.movableCropBoxCustomRatio = CGPointMake(16, 9);
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
    
    UIBarButtonItem *photo = [[UIBarButtonItem alloc] initWithTitle:@"编辑照片" style:UIBarButtonItemStylePlain target:self action:@selector(editPhoto)];
    
    UIBarButtonItem *video = [[UIBarButtonItem alloc] initWithTitle:@"编辑视频" style:UIBarButtonItemStylePlain target:self action:@selector(editVideo)];
    
    self.navigationItem.rightBarButtonItems = @[photo, video];
}

- (void)editPhoto {
    HXPhotoModel *photoModel = [HXPhotoModel photoModelWithImage:[UIImage imageNamed:@"1"]];
    photoModel.photoEdit = self.photoEdit;
    HXWeakSelf
    if (self.manager.configuration.useWxPhotoEdit) {
        [self hx_presentWxPhotoEditViewControllerWithConfiguration:self.manager.configuration.photoEditConfigur photoModel:photoModel delegate:nil finish:^(HXPhotoEdit * _Nonnull photoEdit, HXPhotoModel * _Nonnull photoModel, HX_PhotoEditViewController * _Nonnull viewController) {
            if (photoEdit) {
                // 有编辑过
                weakSelf.imageView.image = photoEdit.editPreviewImage;
            }else {
                // 为空则未进行编辑
                weakSelf.imageView.image = photoModel.thumbPhoto;
            }
            // 记录下当前编辑的记录，再次编辑可在上一次基础上进行编辑
            weakSelf.photoEdit = photoEdit;
            NSSLog(@"%@", photoModel);
        } cancel:^(HX_PhotoEditViewController * _Nonnull viewController) {
            NSSLog(@"取消：%@", viewController);
        }];
        
//        [self hx_presentWxPhotoEditViewControllerWithConfiguration:self.manager.configuration.photoEditConfigur editImage:photoModel.thumbPhoto photoEdit:self.photoEdit finish:^(HXPhotoEdit * _Nonnull photoEdit, HXPhotoModel * _Nonnull photoModel, HX_PhotoEditViewController * _Nonnull viewController) {
//
//        } cancel:^(HX_PhotoEditViewController * _Nonnull viewController) {
//
//        }];
    }else {
        [self hx_presentPhotoEditViewControllerWithManager:self.manager photoModel:photoModel delegate:nil done:^(HXPhotoModel *beforeModel, HXPhotoModel *afterModel, HXPhotoEditViewController *viewController) {
            weakSelf.imageView.image = afterModel.thumbPhoto;
            NSSLog(@"%@", afterModel);
        } cancel:^(HXPhotoEditViewController *viewController) {
            NSSLog(@"取消：%@", viewController);
        }];
    }
}

- (void)editVideo {
    
    NSURL *url = [[NSBundle mainBundle] URLForResource:@"LocalSampleVideo" withExtension:@"mp4"];
    HXPhotoModel *videoModel = [HXPhotoModel photoModelWithVideoURL:url];
    
    HXWeakSelf
    [self hx_presentVideoEditViewControllerWithManager:self.manager videoModel:videoModel delegate:nil done:^(HXPhotoModel *beforeModel, HXPhotoModel *afterModel, HXVideoEditViewController *viewController) {
        // 编辑之前的视频地址  beforeModel.videoURL
        // 编辑之后的视频地址  afterModel.videoURL
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
                weakSelf.photoEdit = nil;
            } failed:^(NSDictionary *info, HXPhotoModel *model) {
                [weakSelf.view hx_handleLoading];
                [weakSelf.view hx_showImageHUDText:@"获取失败"];
            }];
        }else  if (model.subType == HXPhotoModelMediaSubTypeVideo) {
            [weakSelf.videoView cancelPlayer];
            weakSelf.videoView.model = model;
//            [weakSelf.view hx_showLoadingHUDText:@"获取视频中"];
//            [model exportVideoWithPresetName:AVAssetExportPresetHighestQuality startRequestICloud:nil iCloudProgressHandler:nil exportProgressHandler:^(float progress, HXPhotoModel *model) {
//                NSSLog(@"视频导出进度 - %f",progress)
//            } success:^(NSURL *videoURL, HXPhotoModel *model) {
//                NSSLog(@"%@",videoURL);
//                UIImage *image = [UIImage hx_thumbnailImageForVideo:videoURL atTime:0.1f];
//                weakSelf.imageView.image = image;
//                [weakSelf.view hx_handleLoading];
//            } failed:^(NSDictionary *info, HXPhotoModel *model) {
//                [weakSelf.view hx_handleLoading];
//                [weakSelf.view hx_showImageHUDText:@"视频导出失败"];
//            }];
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
        self.photoEdit = nil;
        NSSLog(@"%ld张图片",photoList.count);
    }else if (videoList.count > 0) {
        
    }
}
- (void)photoViewController:(HXPhotoViewController *)photoViewController didDoneAllList:(NSArray<HXPhotoModel *> *)allList photos:(NSArray<HXPhotoModel *> *)photoList videos:(NSArray<HXPhotoModel *> *)videoList original:(BOOL)original {
    if (photoList.count > 0) {
        HXPhotoModel *model = photoList.firstObject;
        self.imageView.image = model.previewPhoto;
        self.photoEdit = nil;
        NSSLog(@"%ld张图片",photoList.count);
    }else if (videoList.count > 0) {
        
    }
}
@end
