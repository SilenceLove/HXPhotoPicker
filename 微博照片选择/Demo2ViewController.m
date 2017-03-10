//
//  Demo2ViewController.m
//  微博照片选择
//
//  Created by 洪欣 on 17/2/17.
//  Copyright © 2017年 洪欣. All rights reserved.
//

#import "Demo2ViewController.h"
#import "HXPhotoViewController.h"
#import "HXPhotoView.h"
@interface Demo2ViewController ()<HXPhotoViewDelegate>
@property (strong, nonatomic) HXPhotoManager *manager;
@end

@implementation Demo2ViewController

/**
    HXPhotoManager 照片管理类的属性介绍
 
    是否把相机功能放在外面 默认 NO   使用 HXPhotoView 时有用
    outerCamera;


    是否打开相机功能
    openCamera;


    是否开启查看GIF图片功能 - 默认开启
    lookGifPhoto;


    是否开启查看LivePhoto功能呢 - 默认开启
    lookLivePhoto;


    是否一开始就进入相机界面
    goCamera;


    最大选择数 默认10 - 建议必填
    maxNum;


    图片最大选择数 默认9 - 建议必填
    photoMaxNum;


    视频最大选择数  默认1
    videoMaxNum;


    图片和视频是否能够同时选择 默认支持
    selectTogether;


    相册列表每行多少个照片 默认4个
    rowCount;
 
 */

- (HXPhotoManager *)manager
{
    if (!_manager) {
        _manager = [[HXPhotoManager alloc] initWithType:HXPhotoManagerSelectedTypePhotoAndVideo];
//        _manager.openCamera = NO;
//        _manager.outerCamera = YES;
    }
    return _manager;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    self.view.backgroundColor = [UIColor whiteColor];
    self.navigationController.navigationBar.translucent = NO;
    self.automaticallyAdjustsScrollViewInsets = YES;
    CGFloat width = self.view.frame.size.width;
    HXPhotoView *photoView = [[HXPhotoView alloc] initWithFrame:CGRectMake(12, 100, width - 24, 0) WithManager:self.manager];
    photoView.delegate = self;
    photoView.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:photoView];
}

- (void)photoViewChangeComplete:(NSArray *)allList Photos:(NSArray *)photos Videos:(NSArray *)videos Original:(BOOL)isOriginal
{
    NSLog(@"%ld - %ld - %ld",allList.count,photos.count,videos.count);
}

- (void)photoViewUpdateFrame:(CGRect)frame WithView:(UIView *)view
{
    NSLog(@"%@",NSStringFromCGRect(frame));
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
