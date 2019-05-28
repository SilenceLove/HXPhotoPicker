//
//  Demo10ViewController.m
//  照片选择器
//
//  Created by 洪欣 on 2018/7/21.
//  Copyright © 2018年 洪欣. All rights reserved.
//

#import "Demo10ViewController.h"
#import "HXPhotoPicker.h"
static const CGFloat kPhotoViewMargin = 12.0;
@interface Demo10ViewController ()
@property (strong, nonatomic) HXPhotoManager *manager;
@property (strong, nonatomic) HXPhotoView *photoView;
@end

@implementation Demo10ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.view.backgroundColor = [UIColor whiteColor]; 
    HXPhotoView *photoView = [HXPhotoView photoManager:self.manager];
    photoView.frame = CGRectMake(kPhotoViewMargin, hxNavigationBarHeight + kPhotoViewMargin, self.view.hx_w - kPhotoViewMargin * 2, 0);
//    photoView.showAddCell = YES; 
    photoView.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:photoView];
    self.photoView = photoView;
    
    HXWeakSelf
    [self.manager getSelectedModelArrayComplete:^(NSArray<HXPhotoModel *> *modelArray) {
        if (modelArray.count) {
            [weakSelf.manager addModelArray:modelArray];
            [weakSelf.photoView refreshView];
        }
    }];
    
    UIBarButtonItem *saveItem = [[UIBarButtonItem alloc] initWithTitle:@"保存草稿" style:UIBarButtonItemStylePlain target:self action:@selector(savaClick)];
    UIBarButtonItem *deleteItem = [[UIBarButtonItem alloc] initWithTitle:@"删除" style:UIBarButtonItemStylePlain target:self action:@selector(didNavBtnClick)];
    
    self.navigationItem.rightBarButtonItems = @[deleteItem,saveItem];
}
- (void)savaClick {
    if (!self.manager.afterSelectedArray.count) {
        [self.view hx_showImageHUDText:@"请先选择资源!"];
        return;
    }
    [self.view hx_showLoadingHUDText:nil];
    HXWeakSelf
    [self.manager saveSelectModelArraySuccess:^{
        [weakSelf.view hx_handleLoading];
    } failed:^{
        [weakSelf.view hx_handleLoading];
        [weakSelf.view hx_showImageHUDText:@"保存草稿失败"];
    }];
}
- (void)didNavBtnClick {
    BOOL success = [self.manager deleteLocalSelectModelArray];
    if (!success) {
        
    }
}
- (HXPhotoManager *)manager {
    if (!_manager) {
        _manager = [[HXPhotoManager alloc] initWithType:HXPhotoManagerSelectedTypePhotoAndVideo];
        _manager.configuration.openCamera = YES;
        _manager.configuration.lookLivePhoto = YES;
        _manager.configuration.photoMaxNum = 9;
        _manager.configuration.videoMaxNum = 9;
        _manager.configuration.maxNum = 18;
        _manager.configuration.videoMaximumSelectDuration = 500.f;
        _manager.configuration.saveSystemAblum = YES;
        _manager.configuration.showDateSectionHeader = NO;
//        _manager.configuration.requestImageAfterFinishingSelection = YES;
        // 设置保存的文件名称
        _manager.configuration.localFileName = @"suibianshishi";
    }
    return _manager;
}

@end
