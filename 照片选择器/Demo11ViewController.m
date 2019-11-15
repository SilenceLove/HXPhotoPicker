//
//  Demo11ViewController.m
//  照片选择器
//
//  Created by 洪欣 on 2018/7/21.
//  Copyright © 2018年 洪欣. All rights reserved.
//

#import "Demo11ViewController.h"
#import "HXPhotoPicker.h"
#import "Masonry.h"

@interface Demo11ViewController ()<HXPhotoViewDelegate>
@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (weak, nonatomic) IBOutlet HXPhotoView *photoView1;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *photoView1HeightConstraint;

@property (weak, nonatomic) IBOutlet HXPhotoView *photoView2;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *photoView2HeightConstraint;

@property (weak, nonatomic) IBOutlet HXPhotoView *photoView3;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *photoView3HeightConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *placeTopConstraint;

@property (weak, nonatomic) IBOutlet UILabel *placeView;

@property (strong, nonatomic) HXPhotoView *masonryPhotoView;
@end

@implementation Demo11ViewController

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
    // Do any additional setup after loading the view from its nib.
    self.photoView1.delegate = self;
    self.photoView1.lineCount = 5;
    self.photoView2.delegate = self;
    self.photoView2.lineCount = 4;
    self.photoView3.delegate = self;
    self.photoView3.lineCount = 3;
    
    self.masonryPhotoView = [HXPhotoView photoManager:[[HXPhotoManager alloc] initWithType:HXPhotoManagerSelectedTypePhotoAndVideo]];
    self.masonryPhotoView.delegate = self;
    [self.scrollView addSubview:self.masonryPhotoView];
    [self.masonryPhotoView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(self.photoView3.mas_bottom).mas_offset(15);
        make.left.mas_equalTo(self.scrollView).mas_offset(12);
        make.right.mas_equalTo(self.scrollView).mas_offset(-12);
        make.height.mas_equalTo(0);
    }];
    
    [self.scrollView removeConstraint:self.placeTopConstraint];
    NSLayoutConstraint *topCons = [NSLayoutConstraint constraintWithItem:self.placeView attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self.masonryPhotoView attribute:NSLayoutAttributeBottom multiplier:1 constant:15];
    [self.scrollView addConstraint:topCons];
}
- (void)photoView:(HXPhotoView *)photoView updateFrame:(CGRect)frame {
    if (photoView == self.photoView1) {
        [UIView animateWithDuration:0.25 animations:^{
            self.photoView1HeightConstraint.constant = frame.size.height;
            [self.view layoutIfNeeded];
        }];
    }else if (photoView == self.photoView2) {
        [UIView animateWithDuration:0.25 animations:^{
            self.photoView2HeightConstraint.constant = frame.size.height;
            [self.view layoutIfNeeded];
        }];
    }else if (photoView == self.photoView3) {
        [UIView animateWithDuration:0.25 animations:^{
            self.photoView3HeightConstraint.constant = frame.size.height;
            [self.view layoutIfNeeded];
        }];
    }else if (photoView == self.masonryPhotoView) {
        [UIView animateWithDuration:0.25 animations:^{
            [self.masonryPhotoView mas_updateConstraints:^(MASConstraintMaker *make) {
                make.height.mas_equalTo(frame.size.height);
            }];
            [self.view layoutIfNeeded];
        }];
    }
}

@end
