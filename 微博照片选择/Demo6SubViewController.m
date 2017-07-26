//
//  Demo6SubViewController.m
//  微博照片选择
//
//  Created by 洪欣 on 2017/7/26.
//  Copyright © 2017年 洪欣. All rights reserved.
//

#import "Demo6SubViewController.h"
#import "HXPhotoView.h"
@interface Demo6SubViewController ()<HXPhotoViewDelegate>

@end

@implementation Demo6SubViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor whiteColor];
    self.navigationController.navigationBar.translucent = NO;
    self.automaticallyAdjustsScrollViewInsets = YES;
    CGFloat width = self.view.frame.size.width;
    HXPhotoView *photoView = [HXPhotoView photoManager:self.manager];
    photoView.frame = CGRectMake(12, 100, width - 24, 0);
    photoView.delegate = self;
    photoView.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:photoView]; 
}

- (void)dealloc { 
    [self.manager emptySelectedList];
}

@end
