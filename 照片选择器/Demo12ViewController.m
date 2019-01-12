//
//  Demo12ViewController.m
//  照片选择器
//
//  Created by 洪欣 on 2018/7/24.
//  Copyright © 2018年 洪欣. All rights reserved.
//

#import "Demo12ViewController.h"
#import "HXPhotoPicker.h"

static const CGFloat kPhotoViewMargin = 12.0;
@interface Demo12ViewController () <HXPhotoViewDelegate>
@property (strong, nonatomic) HXPhotoManager *manager;
@property (weak, nonatomic) HXPhotoView *photoView;
@property (strong, nonatomic) UIScrollView *scrollView;
@end

@implementation Demo12ViewController

- (HXPhotoManager *)manager {
    if (!_manager) {
        _manager = [[HXPhotoManager alloc] initWithType:HXPhotoManagerSelectedTypePhotoAndVideo];
//        _manager.configuration.openCamera = NO;
        _manager.configuration.saveSystemAblum = YES;
        _manager.configuration.photoMaxNum = 9; //
        _manager.configuration.videoMaxNum = 1;  //
        _manager.configuration.maxNum = 10;
        _manager.configuration.reverseDate = YES;
        _manager.configuration.selectTogether = YES;
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
    HXPhotoView *photoView = [HXPhotoView photoManager:self.manager];
    photoView.frame = CGRectMake(kPhotoViewMargin, kPhotoViewMargin, width - kPhotoViewMargin * 2, 0);
    photoView.lineCount = 3;
    photoView.previewStyle = HXPhotoViewPreViewShowStyleDark;
    photoView.outerCamera = YES;
    photoView.delegate = self;
    //    photoView.showAddCell = NO;
    photoView.backgroundColor = [UIColor whiteColor];
    [scrollView addSubview:photoView];
    self.photoView = photoView;
    NSURL *url = [[NSBundle mainBundle] URLForResource:@"QQ空间视频_20180301091047" withExtension:@"mp4"];
    
    HXCustomAssetModel *assetModel1 = [HXCustomAssetModel assetWithLocaImageName:@"1" selected:YES];
    HXCustomAssetModel *assetModel2 = [HXCustomAssetModel assetWithLocaImageName:@"2" selected:NO];
    HXCustomAssetModel *assetModel3 = [HXCustomAssetModel assetWithNetworkImageURL:[NSURL URLWithString:@"http://tsnrhapp.oss-cn-hangzhou.aliyuncs.com/1466408576222.jpg"] selected:YES];
    HXCustomAssetModel *assetModel4 = [HXCustomAssetModel assetWithNetworkImageURL:[NSURL URLWithString:@"http://tsnrhapp.oss-cn-hangzhou.aliyuncs.com/0034821a-6815-4d64-b0f2-09103d62630d.jpg"] selected:NO];
    HXCustomAssetModel *assetModel5 = [HXCustomAssetModel assetWithLocalVideoURL:url selected:YES];
    // 模拟视频数量超过视频最大选择数
    HXCustomAssetModel *assetModel6 = [HXCustomAssetModel assetWithLocalVideoURL:url selected:YES]; 
    [self.manager addCustomAssetModel:@[assetModel1, assetModel2, assetModel3, assetModel4, assetModel5, assetModel6]];
    [self.photoView refreshView]; 
}
- (void)photoView:(HXPhotoView *)photoView changeComplete:(NSArray<HXPhotoModel *> *)allList photos:(NSArray<HXPhotoModel *> *)photos videos:(NSArray<HXPhotoModel *> *)videos original:(BOOL)isOriginal {
    
//    [allList hx_requestImageWithOriginal:isOriginal completion:^(NSArray<UIImage *> * _Nullable imageArray) {
//        NSSLog(@"%@",imageArray);
//    }];
}
- (void)photoView:(HXPhotoView *)photoView updateFrame:(CGRect)frame
{
    NSSLog(@"%@",NSStringFromCGRect(frame));
    self.scrollView.contentSize = CGSizeMake(self.scrollView.frame.size.width, CGRectGetMaxY(frame) + kPhotoViewMargin);
}
@end
