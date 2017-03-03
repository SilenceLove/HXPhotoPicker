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

- (HXPhotoManager *)manager
{
    if (!_manager) {
        _manager = [[HXPhotoManager alloc] initWithType:HXPhotoManagerSelectedTypePhotoAndVideo];
    }
    return _manager;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    self.view.backgroundColor = [UIColor whiteColor];
    self.navigationController.navigationBar.translucent = NO;
    self.automaticallyAdjustsScrollViewInsets = YES;
    HXPhotoView *photoView = [[HXPhotoView alloc] initWithFrame:CGRectMake((414 - 375) / 2, 100, 375, 400) WithManager:self.manager];
    photoView.delegate = self;
    photoView.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:photoView];
}

- (void)photoViewChangeComplete:(NSArray *)allList Photos:(NSArray *)photos Videos:(NSArray *)videos Original:(BOOL)isOriginal
{
    NSLog(@"%ld - %ld - %ld",allList.count,photos.count,videos.count);
}

- (void)photoViewUpdateFrame:(CGRect)frame
{
    NSLog(@"%@",NSStringFromCGRect(frame));
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
