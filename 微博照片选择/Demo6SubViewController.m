//
//  Demo6SubViewController.m
//  微博照片选择
//
//  Created by 洪欣 on 2017/7/26.
//  Copyright © 2017年 洪欣. All rights reserved.
//

#import "Demo6SubViewController.h"
#import "HXPhotoView.h"

static const CGFloat kPhotoViewMargin = 12.0;

@interface Demo6SubViewController ()<HXPhotoViewDelegate>

@property (strong, nonatomic) UIScrollView *scrollView;

@end

@implementation Demo6SubViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
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
    photoView.delegate = self;
    photoView.backgroundColor = [UIColor whiteColor];
    [scrollView addSubview:photoView];
}

- (void)dealloc { 
    [self.manager clearSelectedList];
}

#pragma mark - HXPhotoViewDelegate

- (void)photoView:(HXPhotoView *)photoView updateFrame:(CGRect)frame
{
    self.scrollView.contentSize = CGSizeMake(self.scrollView.frame.size.width, CGRectGetMaxY(frame) + kPhotoViewMargin);
}

@end
