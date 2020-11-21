//
//  Demo14ViewController.m
//  HXPhotoPickerExample
//
//  Created by 洪欣 on 2020/5/22.
//  Copyright © 2020 洪欣. All rights reserved.
//

#import "Demo14ViewController.h"
#import "HXPhotoPicker.h"

static const CGFloat kPhotoViewMargin = 12.0;

@interface Demo14ViewController ()<HXPhotoViewDelegate>
@property (strong, nonatomic) HXPhotoManager *manager;
@property (weak, nonatomic) HXPhotoView *photoView;
@end

@implementation Demo14ViewController
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
- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self changeStatus];
    if (!HXPhotoViewCustomItemSize) {
        hx_showAlert(self, @"提示", @"请先将 HXPhotoViewCustomItemSize 此宏修改为 1 后再查看此功能", @"确定", nil, nil, nil);
    }
}
- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self changeStatus];
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
        _manager.configuration.lookLivePhoto = YES;
        _manager.configuration.photoMaxNum = 0;
        _manager.configuration.videoMaxNum = 0;
        _manager.configuration.maxNum = 100;
        _manager.configuration.selectTogether = YES;
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
    
    CGFloat width = self.view.frame.size.width;
    HXPhotoView *photoView = [HXPhotoView photoManager:self.manager scrollDirection:UICollectionViewScrollDirectionVertical];
    photoView.frame = CGRectMake(0, kPhotoViewMargin + hxNavigationBarHeight, width, 0);
    photoView.collectionView.contentInset = UIEdgeInsetsMake(0, kPhotoViewMargin, 0, kPhotoViewMargin);
    photoView.delegate = self;
    photoView.outerCamera = YES;
    photoView.previewStyle = HXPhotoViewPreViewShowStyleDark;
    photoView.showAddCell = YES;
    photoView.collectionView.scrollEnabled = YES;
    [photoView.collectionView reloadData];
    [self.view addSubview:photoView];
    self.photoView = photoView;
}
- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath isAddItem:(BOOL)isAddItem photoView:(HXPhotoView *)photoView{
//    if (isAddItem) {
//        return CGSizeMake(150, 150);
//    }
    CGFloat width;
    NSInteger index = indexPath.item + 1;
    if (index % 6 == 0) {
        width = self.view.hx_w - kPhotoViewMargin * 2;
    }else if ((index - 4) % 6 == 0  || (index - 5) % 6 == 0) {
        width = (self.view.hx_w - kPhotoViewMargin * 2 - photoView.spacing) / 2;
    }else {
        width = (self.view.hx_w - photoView.spacing * 2 - kPhotoViewMargin * 2) / 3;
    }
    
    return CGSizeMake(width, width);
}
- (CGFloat)photoViewHeight:(HXPhotoView *)photoView {
    return self.view.hx_h - kPhotoViewMargin * 2 - hxNavigationBarHeight;
}
@end
