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
#import "HXDatePhotoToolManager.h"
static const CGFloat kPhotoViewMargin = 12.0;
@interface Demo8ViewController ()<HXPhotoViewDelegate>
@property (strong, nonatomic) HXPhotoManager *manager;
@property (strong, nonatomic) HXPhotoView *photoView;
@property (strong, nonatomic) UIScrollView *scrollView;

@property (copy, nonatomic) NSArray *selectList;
@property (copy, nonatomic) NSArray *imageRequestIds;
@property (copy, nonatomic) NSArray *videoSessions;

@property (strong, nonatomic) HXDatePhotoToolManager *toolManager;
@end

@implementation Demo8ViewController
- (HXPhotoManager *)manager {
    if (!_manager) {
        _manager = [[HXPhotoManager alloc] initWithType:HXPhotoManagerSelectedTypePhotoAndVideo];
        _manager.openCamera = YES;
        //        _manager.outerCamera = YES;
        _manager.style = HXPhotoAlbumStylesSystem;
        _manager.photoMaxNum = 9;
        _manager.videoMaxNum = 9;
        _manager.maxNum = 18;
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
    
    UIBarButtonItem *item1 = [[UIBarButtonItem alloc] initWithTitle:@"写入" style:UIBarButtonItemStylePlain target:self action:@selector(didNavOneBtnClick)];
    UIBarButtonItem *item2 = [[UIBarButtonItem alloc] initWithTitle:@"取消" style:UIBarButtonItemStylePlain target:self action:@selector(didNavTwoBtnClick)];
    self.navigationItem.rightBarButtonItems = @[item1,item2];
}

- (void)didNavOneBtnClick {
    [self.view showLoadingHUDText:@"写入中"];
    __weak typeof(self) weakSelf = self;
    if (self.manager.style == HXPhotoAlbumStylesSystem) {
        // 相册风格为系统时  必须使用此方法写入临时文件
        [self.toolManager writeSelectModelListToTempPathWithList:self.selectList success:^(NSArray<NSURL *> *allURL, NSArray<NSURL *> *photoURL, NSArray<NSURL *> *videoURL) {
            NSSLog(@"\nall : %@ \nimage : %@ \nvideo : %@",allURL,photoURL,videoURL);
            [weakSelf.view handleLoading];
        } failed:^{
            [weakSelf.view handleLoading];
            [weakSelf.view showImageHUDText:@"写入失败"];
            NSSLog(@"写入失败");
        }];
        return;
    }
    [HXPhotoTools selectListWriteToTempPath:self.selectList requestList:^(NSArray *imageRequestIds, NSArray *videoSessions) {
        weakSelf.imageRequestIds = imageRequestIds;
        weakSelf.videoSessions = videoSessions;
        NSSLog(@"image请求 : %ld  视频压缩会话 : %ld",imageRequestIds.count,videoSessions.count);
    } completion:^(NSArray<NSURL *> *allUrl, NSArray<NSURL *> *imageUrls, NSArray<NSURL *> *videoUrls) {
        NSSLog(@"\nall : %@ \nimage : %@ \nvideo : %@",allUrl,imageUrls,videoUrls);
        [weakSelf.view handleLoading];
    } error:^{
        [weakSelf.view handleLoading];
        [weakSelf.view showImageHUDText:@"写入失败"];
        NSSLog(@"写入失败");
    }];
}

- (void)didNavTwoBtnClick {
    /**
        关于取消!!!
        
        图片：只能取消 正在请求资源的 不能取消正在写入临时目录的  简而言之就是图片写入取消不了 🤣🤣🤣
             当请求到结果后是取消不了的。这个也什么影响 图片请求速度很快写入也很快只有视频比较慢
     
        视频：可以取消正在压缩写入文件的
     
     */
    for (NSNumber *number in self.imageRequestIds) {
        [[PHImageManager defaultManager] cancelImageRequest:[number intValue]];
    }
    for (AVAssetExportSession *session in self.videoSessions) {
        [session cancelExport];
    }
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
