//
//  Demo11ViewController.m
//  照片选择器
//
//  Created by 洪欣 on 2018/7/21.
//  Copyright © 2018年 洪欣. All rights reserved.
//

#import "Demo11ViewController.h"
#import "HXPhotoPicker.h"

@interface Demo11ViewController ()<HXPhotoViewDelegate>
@property (weak, nonatomic) IBOutlet HXPhotoView *photoView1;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *photoView1HeightConstraint;

@property (weak, nonatomic) IBOutlet HXPhotoView *photoView2;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *photoView2HeightConstraint;

@property (weak, nonatomic) IBOutlet HXPhotoView *photoView3;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *photoView3HeightConstraint;
@end

@implementation Demo11ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    self.photoView1.delegate = self;
    self.photoView1.lineCount = 5;
    self.photoView2.delegate = self;
    self.photoView2.lineCount = 4;
    self.photoView3.delegate = self;
    self.photoView3.lineCount = 3;
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
    }
}

@end
