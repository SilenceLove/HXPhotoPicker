//
//  HXCustomNavigationController.m
//  照片选择器
//
//  Created by 洪欣 on 2017/10/31.
//  Copyright © 2017年 洪欣. All rights reserved.
//

#import "HXCustomNavigationController.h"

@interface HXCustomNavigationController ()

@end

@implementation HXCustomNavigationController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}
-(BOOL)shouldAutorotate{
    if (self.isCamera) {
        return NO;
    }
    if (self.supportRotation) {
        return YES;
    }else {
        return NO;
    }
}

//支持的方向

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    if (self.isCamera) {
        return UIInterfaceOrientationMaskPortrait;
    }
    if (self.supportRotation) {
        return UIInterfaceOrientationMaskAll;
    }else {
        return UIInterfaceOrientationMaskPortrait;
    }
}

@end
