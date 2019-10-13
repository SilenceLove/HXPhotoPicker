//
//  Demo5ViewController.m
//  照片选择器
//
//  Created by 洪欣 on 2017/7/5.
//  Copyright © 2017年 洪欣. All rights reserved.
//

#import "Demo5ViewController.h"
#import "HXPhotoView.h" 

static const CGFloat kPhotoViewMargin = 12.0;
static const CGFloat kPhotoViewSectionMargin = 20.0;

@interface Demo5ViewController ()<HXPhotoViewDelegate>

@property (strong, nonatomic) UIScrollView *scrollView;
@property (strong, nonatomic) HXPhotoView *onePhotoView;
@property (strong, nonatomic) HXPhotoManager *oneManager;
@property (strong, nonatomic) HXPhotoView *twoPhotoView;
@property (strong, nonatomic) HXPhotoManager *twoManager;
@property (strong, nonatomic) HXPhotoView *threePhotoView;
@property (strong, nonatomic) HXPhotoManager *threeManager;

@end

@implementation Demo5ViewController

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
- (HXPhotoManager *)oneManager {
    if (!_oneManager) {
        _oneManager = [[HXPhotoManager alloc] initWithType:HXPhotoManagerSelectedTypePhoto];
    }
    return _oneManager;
}

- (HXPhotoManager *)twoManager {
    if (!_twoManager) {
        _twoManager = [[HXPhotoManager alloc] initWithType:HXPhotoManagerSelectedTypeVideo];
        _twoManager.configuration.videoMaximumDuration = 10.f;
        _twoManager.configuration.videoMaxNum = 10;
        _twoManager.configuration.maxNum = 10;
    }
    return _twoManager;
}

- (HXPhotoManager *)threeManager {
    if (!_threeManager) {
        _threeManager = [[HXPhotoManager alloc] initWithType:HXPhotoManagerSelectedTypePhotoAndVideo];
        
    }
    return _threeManager;
}

- (void)viewDidLoad {
    [super viewDidLoad];
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
    
    self.scrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height)];
    self.scrollView.alwaysBounceVertical = YES;
    [self.view addSubview:self.scrollView];
    
    self.onePhotoView = [[HXPhotoView alloc] initWithFrame:CGRectMake(kPhotoViewMargin, kPhotoViewMargin, self.view.frame.size.width - kPhotoViewMargin * 2, 0) manager:self.oneManager];
    self.onePhotoView.outerCamera = YES;
    self.onePhotoView.delegate = self;
    [self.scrollView addSubview:self.onePhotoView];
    
    self.twoPhotoView = [[HXPhotoView alloc] initWithFrame:CGRectMake(kPhotoViewMargin, CGRectGetMaxY(self.onePhotoView.frame) + kPhotoViewSectionMargin, self.view.frame.size.width - kPhotoViewMargin * 2, 0) manager:self.twoManager];
    self.twoPhotoView.delegate = self;
    [self.scrollView addSubview:self.twoPhotoView];
    
    self.threePhotoView = [[HXPhotoView alloc] initWithFrame:CGRectMake(kPhotoViewMargin, CGRectGetMaxY(self.twoPhotoView.frame) + kPhotoViewSectionMargin, self.view.frame.size.width - kPhotoViewMargin * 2, 0) manager:self.threeManager];
    self.threePhotoView.delegate = self;
    [self.scrollView addSubview:self.threePhotoView];
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"清空" style:UIBarButtonItemStylePlain target:self action:@selector(didCleanClick)];
}
- (void)didCleanClick {
    [self.oneManager clearSelectedList];
    [self.twoManager clearSelectedList];
    [self.threeManager clearSelectedList];
    [self.onePhotoView refreshView];
    [self.twoPhotoView refreshView];
    [self.threePhotoView refreshView];
}
- (void)photoView:(HXPhotoView *)photoView changeComplete:(NSArray<HXPhotoModel *> *)allList photos:(NSArray<HXPhotoModel *> *)photos videos:(NSArray<HXPhotoModel *> *)videos original:(BOOL)isOriginal {
    if (self.onePhotoView == photoView) {
        NSSLog(@"onePhotoView - %@",allList);
    }else if (self.twoPhotoView == photoView) {
        NSSLog(@"twoPhotoView - %@",allList);
    }else if (self.threePhotoView == photoView) {
        NSSLog(@"threePhotoView - %@",allList);
    }
}
- (void)photoView:(HXPhotoView *)photoView updateFrame:(CGRect)frame {
    if (self.onePhotoView == photoView) {
        self.twoPhotoView.frame = CGRectMake(kPhotoViewMargin, CGRectGetMaxY(self.onePhotoView.frame) + kPhotoViewSectionMargin, self.view.frame.size.width - kPhotoViewMargin * 2, self.twoPhotoView.frame.size.height);
        self.threePhotoView.frame = CGRectMake(kPhotoViewMargin, CGRectGetMaxY(self.twoPhotoView.frame) + kPhotoViewSectionMargin, self.view.frame.size.width - kPhotoViewMargin * 2, self.threePhotoView.frame.size.height);
    }else if (self.twoPhotoView == photoView) {
        self.twoPhotoView.frame = CGRectMake(kPhotoViewMargin, CGRectGetMaxY(self.onePhotoView.frame) + kPhotoViewSectionMargin, self.view.frame.size.width - kPhotoViewMargin * 2, self.twoPhotoView.frame.size.height);
        self.threePhotoView.frame = CGRectMake(kPhotoViewMargin, CGRectGetMaxY(self.twoPhotoView.frame) + kPhotoViewSectionMargin, self.view.frame.size.width - kPhotoViewMargin * 2, self.threePhotoView.frame.size.height);
    }else if (self.threePhotoView == photoView) {
        self.threePhotoView.frame = CGRectMake(kPhotoViewMargin, CGRectGetMaxY(self.twoPhotoView.frame) + kPhotoViewSectionMargin, self.view.frame.size.width - kPhotoViewMargin * 2, frame.size.height);
    }
    self.scrollView.contentSize = CGSizeMake(self.view.frame.size.width, CGRectGetMaxY(self.threePhotoView.frame) + kPhotoViewMargin);
}

@end
