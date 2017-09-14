//
//  Demo8ViewController.m
//  微博照片选择
//
//  Created by 洪欣 on 2017/9/14.
//  Copyright © 2017年 洪欣. All rights reserved.
//

#import "Demo8ViewController.h"
#import "HXPhotoViewController.h"
#import "HXPhotoView.h"

static const CGFloat kPhotoViewMargin = 12.0;
@interface Demo8ViewController ()<HXPhotoViewDelegate>
@property (strong, nonatomic) HXPhotoManager *manager;
@property (strong, nonatomic) HXPhotoView *photoView;
@property (strong, nonatomic) UIScrollView *scrollView;

@property (copy, nonatomic) NSArray *selectList;
@end

@implementation Demo8ViewController
- (HXPhotoManager *)manager {
    if (!_manager) {
        _manager = [[HXPhotoManager alloc] initWithType:HXPhotoManagerSelectedTypePhotoAndVideo];
        _manager.openCamera = YES;
        _manager.cacheAlbum = YES;
        _manager.lookLivePhoto = YES;
//        _manager.lookGifPhoto = NO;
        //        _manager.outerCamera = YES;
        _manager.open3DTouchPreview = YES;
        _manager.cameraType = HXPhotoManagerCameraTypeSystem;
        _manager.photoMaxNum = 9;
        _manager.videoMaxNum = 9;
        _manager.maxNum = 18;
        _manager.saveSystemAblum = NO;
    }
    return _manager;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.view.backgroundColor = [UIColor whiteColor];
    //    self.navigationController.navigationBar.translucent = NO;
    self.automaticallyAdjustsScrollViewInsets = YES;
    
    UIScrollView *scrollView = [[UIScrollView alloc] initWithFrame:self.view.bounds];
    scrollView.alwaysBounceVertical = YES;
    [self.view addSubview:scrollView];
    self.scrollView = scrollView;
    
    CGFloat width = scrollView.frame.size.width;
    HXPhotoView *photoView = [[HXPhotoView alloc] initWithFrame:CGRectMake(kPhotoViewMargin, kPhotoViewMargin, width - kPhotoViewMargin * 2, 0) manager:self.manager];
    photoView.delegate = self;
    photoView.backgroundColor = [UIColor whiteColor];
    [photoView refreshView];
    [scrollView addSubview:photoView];
    self.photoView = photoView;
    
    UIBarButtonItem *item1 = [[UIBarButtonItem alloc] initWithTitle:@"写入Temp" style:UIBarButtonItemStylePlain target:self action:@selector(didNavOneBtnClick)];
    
    self.navigationItem.rightBarButtonItems = @[item1];
}

- (void)didNavOneBtnClick {
    [self.view showLoadingHUDText:@"写入中"];
    __weak typeof(self) weakSelf = self;
    [HXPhotoTools selectListWriteToTempPath:self.selectList completion:^(NSArray<NSURL *> *allUrl, NSArray<NSURL *> *imageUrls, NSArray<NSURL *> *videoUrls) {
        NSSLog(@"\nall : %@ \nimage : %@ \nvideo : %@",allUrl,imageUrls,videoUrls);
        [weakSelf.view handleLoading];
    } error:^{
        [weakSelf.view handleLoading];
        [weakSelf.view showImageHUDText:@"写入失败"];
        NSSLog(@"写入失败");
    }];
}

- (void)photoView:(HXPhotoView *)photoView changeComplete:(NSArray<HXPhotoModel *> *)allList photos:(NSArray<HXPhotoModel *> *)photos videos:(NSArray<HXPhotoModel *> *)videos original:(BOOL)isOriginal {
    self.selectList = allList;
    NSSLog(@"%@",allList);
}

- (void)photoView:(HXPhotoView *)photoView updateFrame:(CGRect)frame {
    NSSLog(@"%@",NSStringFromCGRect(frame));
    self.scrollView.contentSize = CGSizeMake(self.scrollView.frame.size.width, CGRectGetMaxY(frame) + kPhotoViewMargin);
    
}

@end
