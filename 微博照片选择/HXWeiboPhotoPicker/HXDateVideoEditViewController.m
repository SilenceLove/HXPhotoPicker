//
//  HXDateVideoEditViewController.m
//  微博照片选择
//
//  Created by 洪欣 on 2017/12/31.
//  Copyright © 2017年 洪欣. All rights reserved.
//

#import "HXDateVideoEditViewController.h"

@interface HXDateVideoEditViewController ()

@end

@implementation HXDateVideoEditViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

@end

@interface HXDataVideoEditBottomView ()
@property (strong, nonatomic) UIButton *cancelBtn;
@property (strong, nonatomic) UIButton *doneBtn;
@property (strong, nonatomic) UICollectionView *collectionView;
@end

@implementation HXDataVideoEditBottomView
- (instancetype)initWithFrame:(CGRect)frame manager:(HXPhotoManager *)manager {
    self = [super initWithFrame:frame];
    if (self) {
        [self setup];
    }
    return self;
}
- (void)setup {
    
}
#pragma mark - < 懒加载 >
- (UIButton *)cancelBtn {
    if (!_cancelBtn) {
        _cancelBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        _cancelBtn.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
        [_cancelBtn setTitle:@"" forState:UIControlStateNormal];
        [_cancelBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    }
    return _cancelBtn;
}
- (UIButton *)doneBtn {
    if (!_doneBtn) {
        _doneBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        
    }
    return _doneBtn;
}
@end
