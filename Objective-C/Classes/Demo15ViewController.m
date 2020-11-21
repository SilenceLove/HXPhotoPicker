//
//  Demo15ViewController.m
//  HXPhotoPickerExample
//
//  Created by 洪欣 on 2020/5/27.
//  Copyright © 2020 洪欣. All rights reserved.
//

#import "Demo15ViewController.h"
#import "HXPhotoPicker.h"

@interface Demo15ViewController ()
@property (strong, nonatomic) NSMutableArray *models;
@end

@implementation Demo15ViewController
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
- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
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
    self.models = [NSMutableArray array];
    UIButton *showBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    [showBtn setTitle:@"显示弹窗" forState:UIControlStateNormal];
    if (@available(iOS 13.0, *)) {
        [showBtn setTitleColor:[UIColor colorWithDynamicProvider:^UIColor * _Nonnull(UITraitCollection * _Nonnull traitCollection) {
            if (traitCollection.userInterfaceStyle == UIUserInterfaceStyleDark) {
                return UIColor.whiteColor;
            }
            return UIColor.blackColor;
        }] forState:UIControlStateNormal];
    } else {
        [showBtn setTitleColor:UIColor.blackColor forState:UIControlStateNormal];
    }
    [showBtn addTarget:self action:@selector(didShowBtnClick:) forControlEvents:UIControlEventTouchUpInside];
    showBtn.frame = CGRectMake(100, 100, self.view.hx_w - 200, 50);
    [self.view addSubview:showBtn];
    
    UIBarButtonItem *addItem = [[UIBarButtonItem alloc] initWithTitle:@"加选项" style:UIBarButtonItemStylePlain target:self action:@selector(didAddItem)];
    
    UIBarButtonItem *deleteItem = [[UIBarButtonItem alloc] initWithTitle:@"删选项" style:UIBarButtonItemStylePlain target:self action:@selector(didDeleteItem)];
    
    self.navigationItem.rightBarButtonItems = @[addItem, deleteItem];
}
- (void)didAddItem {
    HXPhotoBottomViewModel *model = [[HXPhotoBottomViewModel alloc] init];
    model.title = [NSString stringWithFormat:@"选项%ld", self.models.count + 1];
    [self.models addObject:model];
}
- (void)didDeleteItem {
    if (self.models.count) {
        [self.models removeLastObject];
    }
}
- (void)didShowBtnClick:(UIButton *)button {
    if (!self.models.count) {
        [self.view hx_showImageHUDText:@"暂无选项"];
        return;
    }
    HXWeakSelf
    UILabel *titleLb = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, 40)];
    titleLb.backgroundColor = [UIColor whiteColor];
    titleLb.text = @"此处为tableViewHeaderView";
    titleLb.textColor = [UIColor lightGrayColor];
    titleLb.textAlignment = NSTextAlignmentCenter;
    titleLb.font = [UIFont hx_pingFangFontOfSize:14];
    UIView *lineView = [[UIView alloc] initWithFrame:CGRectMake(0, 39.5, titleLb.hx_w, 0.5)];
    lineView.backgroundColor = [UIColor colorWithRed:0.93 green:0.93 blue:0.93 alpha:1];
    [titleLb addSubview:lineView];
    [HXPhotoBottomSelectView showSelectViewWithModels:self.models
                                           headerView:titleLb
                                      showTopLineView:YES
                                          cancelTitle:nil
                                     selectCompletion:^(NSInteger index, HXPhotoBottomViewModel * _Nonnull model) {
        [weakSelf.view hx_showImageHUDText:[NSString stringWithFormat:@"选择了第%ld项", index + 1]];
    }
                                          cancelClick:^{
        [weakSelf.view hx_showImageHUDText:@"取消选择"];
    }];
}
@end
