//
//  Demo4ViewController.m
//  微博照片选择
//
//  Created by 洪欣 on 2017/7/1.
//  Copyright © 2017年 洪欣. All rights reserved.
//

#import "Demo4ViewController.h"
#import "HXPhotoViewController.h"
#import "HXAlbumListViewController.h"
#import "HXCustomNavigationController.h"
#import "HXDatePhotoToolManager.h"

@interface Demo4ViewController ()<HXPhotoViewControllerDelegate,HXAlbumListViewControllerDelegate>
@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (strong, nonatomic) HXPhotoManager *manager;
@property (strong, nonatomic) HXDatePhotoToolManager *toolManager;
@end

@implementation Demo4ViewController
- (HXPhotoManager *)manager {
    if (!_manager) {
        _manager = [[HXPhotoManager alloc] initWithType:HXPhotoManagerSelectedTypePhotoAndVideo];
        _manager.singleSelected = YES;
        _manager.style = HXPhotoAlbumStylesSystem;
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
    if (self.manager.style == HXPhotoAlbumStylesWeibo) {
        self.manager.saveSystemAblum = NO;
        HXPhotoViewController *vc = [[HXPhotoViewController alloc] init];
        vc.manager = self.manager;
        vc.delegate = self;
        [self presentViewController:[[UINavigationController alloc] initWithRootViewController:vc] animated:YES completion:nil];
    }else {
        self.manager.saveSystemAblum = YES;
        HXAlbumListViewController *vc = [[HXAlbumListViewController alloc] init];
        vc.delegate = self;
        vc.manager = self.manager;
        HXCustomNavigationController *nav = [[HXCustomNavigationController alloc] initWithRootViewController:vc];
        
        [self presentViewController:nav animated:YES completion:nil];
    }
}
- (void)albumListViewController:(HXAlbumListViewController *)albumListViewController didDoneAllList:(NSArray<HXPhotoModel *> *)allList photos:(NSArray<HXPhotoModel *> *)photoList videos:(NSArray<HXPhotoModel *> *)videoList original:(BOOL)original {
    if (photoList.count > 0) {
        HXPhotoModel *model = photoList.firstObject;
        self.imageView.image = model.previewPhoto;
        NSSLog(@"%ld张图片",photoList.count);
    }else if (videoList.count > 0) { 
        __weak typeof(self) weakSelf = self;
        [HXPhotoTools getImageForSelectedPhoto:videoList type:0 completion:^(NSArray<UIImage *> *images) {
            weakSelf.imageView.image = images.firstObject;
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
- (void)photoViewControllerDidNext:(NSArray<HXPhotoModel *> *)allList Photos:(NSArray<HXPhotoModel *> *)photos Videos:(NSArray<HXPhotoModel *> *)videos Original:(BOOL)original {
    if (photos.count > 0) {
        HXPhotoModel *model = allList.firstObject;
        self.imageView.image = model.previewPhoto;
        NSSLog(@"%ld张图片",photos.count);
    }else if (videos.count > 0) {
        __weak typeof(self) weakSelf = self;
        [HXPhotoTools getImageForSelectedPhoto:photos type:0 completion:^(NSArray<UIImage *> *images) {
            weakSelf.imageView.image = images.firstObject;
        }];
        NSSLog(@"%ld个视频",videos.count);
    }
}

- (void)photoViewControllerDidCancel {
    
}
 

@end
