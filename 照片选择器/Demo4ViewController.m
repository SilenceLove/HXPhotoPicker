//
//  Demo4ViewController.m
//  照片选择器
//
//  Created by 洪欣 on 2017/7/1.
//  Copyright © 2017年 洪欣. All rights reserved.
//

#import "Demo4ViewController.h"
#import "HXPhotoPicker.h"

@interface Demo4ViewController ()<HXAlbumListViewControllerDelegate, HXDatePhotoViewControllerDelegate>
@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (strong, nonatomic) HXPhotoManager *manager;
@property (strong, nonatomic) HXDatePhotoToolManager *toolManager;
@end

@implementation Demo4ViewController
- (HXPhotoManager *)manager {
    if (!_manager) {
        _manager = [[HXPhotoManager alloc] initWithType:HXPhotoManagerSelectedTypePhotoAndVideo];
        _manager.configuration.singleSelected = YES;
        _manager.configuration.albumListTableView = ^(UITableView *tableView) {
//            NSSLog(@"%@",tableView);
        };
        _manager.configuration.singleJumpEdit = YES;
        _manager.configuration.movableCropBox = YES;
        _manager.configuration.movableCropBoxEditSize = YES;
        _manager.configuration.albumShowMode = HXPhotoAlbumShowModePopup;
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
}
- (IBAction)selectedPhoto:(id)sender {
    self.manager.configuration.saveSystemAblum = YES;
    
    __weak typeof(self) weakSelf = self;
    if (self.manager.configuration.requestImageAfterFinishingSelection) {
        [self hx_presentSelectPhotoControllerWithManager:self.manager didDone:^(NSArray<HXPhotoModel *> *allList, NSArray<HXPhotoModel *> *photoList, NSArray<HXPhotoModel *> *videoList, BOOL isOriginal, UIViewController *viewController, HXPhotoManager *manager) {
            
        } imageList:^(NSArray<UIImage *> *imageList, BOOL isOriginal) {
            // requestImageAfterFinishingSelection = YES 时 imageList才会有值
            NSSLog(@"%@",imageList);
            NSSLog(@"%ld张图片",imageList.count);
        } cancel:^(UIViewController *viewController, HXPhotoManager *manager) {
            NSSLog(@"取消了");
        }];
    }else {
        [self hx_presentSelectPhotoControllerWithManager:self.manager didDone:^(NSArray<HXPhotoModel *> *allList, NSArray<HXPhotoModel *> *photoList, NSArray<HXPhotoModel *> *videoList, BOOL isOriginal, UIViewController *viewController, HXPhotoManager *manager) {
            if (photoList.count > 0) {
                //            HXPhotoModel *model = photoList.firstObject;
                //            weakSelf.imageView.image = model.previewPhoto;
                [weakSelf.view showLoadingHUDText:@"获取图片中"];
                [weakSelf.toolManager getSelectedImageList:photoList requestType:0 success:^(NSArray<UIImage *> *imageList) {
                    [weakSelf.view handleLoading];
                    weakSelf.imageView.image = imageList.firstObject;
                } failed:^{
                    [weakSelf.view handleLoading];
                    [weakSelf.view showImageHUDText:@"获取失败"];
                }];
                NSSLog(@"%ld张图片",photoList.count);
            }else if (videoList.count > 0) {
                [weakSelf.toolManager getSelectedImageList:allList success:^(NSArray<UIImage *> *imageList) {
                    weakSelf.imageView.image = imageList.firstObject;
                } failed:^{
                    
                }];
                
                // 通个这个方法将视频压缩写入临时目录获取视频URL  或者 通过这个获取视频在手机里的原路径 model.fileURL  可自己压缩
                [weakSelf.view showLoadingHUDText:@"视频写入中"];
                [weakSelf.toolManager writeSelectModelListToTempPathWithList:videoList success:^(NSArray<NSURL *> *allURL, NSArray<NSURL *> *photoURL, NSArray<NSURL *> *videoURL) {
                    NSSLog(@"%@",videoURL);
                    [weakSelf.view handleLoading];
                } failed:^{
                    [weakSelf.view handleLoading];
                    [weakSelf.view showImageHUDText:@"写入失败"];
                    NSSLog(@"写入失败");
                }];
                NSSLog(@"%ld个视频",videoList.count);
            }
        } imageList:^(NSArray<UIImage *> *imageList, BOOL isOriginal) {
            // requestImageAfterFinishingSelection = YES 时 imageList才会有值
        } cancel:^(UIViewController *viewController, HXPhotoManager *manager) {
            NSSLog(@"取消了");
        }]; 
    }
    
//    [self hx_presentAlbumListViewControllerWithManager:self.manager delegate:self];
//    HXAlbumListViewController *vc = [[HXAlbumListViewController alloc] init];
//    vc.delegate = self;
//    vc.manager = self.manager;
//    HXCustomNavigationController *nav = [[HXCustomNavigationController alloc] initWithRootViewController:vc];
//    nav.supportRotation = self.manager.configuration.supportRotation;
//    [self presentViewController:nav animated:YES completion:nil];
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
        [self.view showLoadingHUDText:@"视频写入中"];
        [self.toolManager writeSelectModelListToTempPathWithList:videoList success:^(NSArray<NSURL *> *allURL, NSArray<NSURL *> *photoURL, NSArray<NSURL *> *videoURL) {
            NSSLog(@"%@",videoURL);
            [weakSelf.view handleLoading];
        } failed:^{
            [weakSelf.view handleLoading];
            [weakSelf.view showImageHUDText:@"写入失败"];
            NSSLog(@"写入失败");
        }];
        NSSLog(@"%ld个视频",videoList.count);
    }
}
- (void)datePhotoViewController:(HXDatePhotoViewController *)datePhotoViewController didDoneAllList:(NSArray<HXPhotoModel *> *)allList photos:(NSArray<HXPhotoModel *> *)photoList videos:(NSArray<HXPhotoModel *> *)videoList original:(BOOL)original {
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
        [self.view showLoadingHUDText:@"视频写入中"];
        [self.toolManager writeSelectModelListToTempPathWithList:videoList success:^(NSArray<NSURL *> *allURL, NSArray<NSURL *> *photoURL, NSArray<NSURL *> *videoURL) {
            NSSLog(@"%@",videoURL);
            [weakSelf.view handleLoading];
        } failed:^{
            [weakSelf.view handleLoading];
            [weakSelf.view showImageHUDText:@"写入失败"];
            NSSLog(@"写入失败");
        }];
        NSSLog(@"%ld个视频",videoList.count);
    }
}
@end
