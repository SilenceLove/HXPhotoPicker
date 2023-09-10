//
//  ViewController.m
//  HXPhotoPickerExample
//
//  Created by Silence on 17/2/8.
//  Copyright © 2017年 Silence. All rights reserved.
//

#import "ViewController.h"
#import <SafariServices/SafariServices.h>
#import "HXPhotoPickerExample-Swift.h"
#import "OCPickerExampleViewController.h"

static NSString *const kCellIdentifier = @"cell_identifier";

@interface ListItem : NSObject

@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *subTitle;
@property (nonatomic, assign) Class viewControllClass;

- (instancetype)initWithTitle:(NSString *)title subTitle:(NSString *)subTitle viewControllClass:(Class)class;

@end

@interface ViewController ()<UITableViewDataSource,UITableViewDelegate>

@property (copy, nonatomic) NSArray *list;
//@property (nonatomic, strong) YYFPSLabel *label;
@property (nonatomic, assign) BOOL showAlertCompletion;

@end

@implementation ViewController
 
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
//    if (!self.showAlertCompletion) {
//        hx_showAlert(self, @"提示", @"关于如何获取照片和视频，在README和Demo8中都写有很详细的说明", @"了解", nil, nil, nil);
//        self.showAlertCompletion = YES;
//    }
    self.navigationController.interactivePopGestureRecognizer.enabled = NO;
}
- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    self.navigationController.interactivePopGestureRecognizer.enabled = YES;
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
- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
    [super traitCollectionDidChange:previousTraitCollection];
#ifdef __IPHONE_13_0
    if (@available(iOS 13.0, *)) {
        [self preferredStatusBarUpdateAnimation];
        self.view.backgroundColor = [UIColor systemBackgroundColor];
//        self.label.textColor = UITraitCollection.currentTraitCollection.userInterfaceStyle == UIUserInterfaceStyleDark ? [UIColor whiteColor] : [UIColor blackColor];
        [self changeStatus];
    }
#endif
}
- (NSArray *)list
{
    if (!_list) {
        _list = @[[[ListItem alloc] initWithTitle:@"ObjC版本"
                                     subTitle:@"v3.0"
                                viewControllClass: [SFSafariViewController class]]
        ];
    }
    return _list;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    // 请不要设置导航栏的背景图片为空
//    [[UINavigationBar appearance] setShadowImage:[UIImage new]];
//    [[UINavigationBar appearance] setBackgroundImage:[UIImage imageNamed:@"APPCityPlayer_bannerGame"] forBarMetrics:UIBarMetricsDefault];

    self.showAlertCompletion = NO;
    self.title = @"Picker";
    UITableView *tableView;
    if (@available(iOS 13.0, *)) {
        tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStyleInsetGrouped];
    } else {
        tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStyleGrouped];
    }
    tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    tableView.tableFooterView = [[UIView alloc] init];
    tableView.dataSource = self;
    tableView.delegate = self;
    tableView.rowHeight = 70;
    [self.view addSubview:tableView];
}
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section == 0) {
        if (@available(iOS 14.0, *)) {
            return 3;
        }else {
            return 2;
        }
    }
    return self.list.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kCellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:kCellIdentifier];
        cell.detailTextLabel.numberOfLines = 0;
        cell.detailTextLabel.textColor = [UIColor grayColor];
    }
    if (indexPath.section == 1) {
        ListItem *item = self.list[indexPath.row];
        cell.textLabel.text = item.title;
        cell.detailTextLabel.text = item.subTitle;
    }else {
        if (indexPath.row == 0) {
            cell.textLabel.text = @"Swift示例";
            cell.detailTextLabel.text = @"查看Swift版本的示例 v4.0";
        }
#ifdef __IPHONE_14_0
        else if (indexPath.row == 1) {
            cell.textLabel.text = @"SwiftUI示例";
            cell.detailTextLabel.text = @"查看示例";
        }
#endif
        else  {
            cell.textLabel.text = @"OC调用Swift";
            cell.detailTextLabel.text = @"查看示例";
        }
    }
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    if (indexPath.section == 0) {
        self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"返回" style:UIBarButtonItemStylePlain target:nil action:nil];
        if (indexPath.row == 0) {
            UIViewController *viewController;
            if (@available(iOS 13.0, *)) {
                viewController = [[HomeViewController alloc] initWithStyle:UITableViewStyleInsetGrouped];
            } else {
                viewController = [[HomeViewController alloc] initWithStyle:UITableViewStyleGrouped];
            }
            [self.navigationController pushViewController:viewController animated:YES];
        }
#ifdef __IPHONE_14_0
        else if (indexPath.row == 1) {
            if (@available(iOS 14.0, *)) {
                UIViewController * vc = [SwiftPhotoPicker swiftUI];
                [self.navigationController pushViewController:vc animated:YES];
                return;
            }
        }
#endif
        OCPickerExampleViewController *vc = [[OCPickerExampleViewController alloc] init];
        [self.navigationController pushViewController:vc animated:YES];
        return;
    }
    ListItem *item = self.list[indexPath.row];
    if (item.viewControllClass == SFSafariViewController.class) {
        SFSafariViewController *vc = [[SFSafariViewController alloc] initWithURL:[NSURL URLWithString:@"https://github.com/SilenceLove/HXPhotoPickerObjC"]];
        [self presentViewController:vc animated:YES completion:nil];
    }else {
        UIViewController *viewController = [[item.viewControllClass alloc] init];
        viewController.title = item.title;
        self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"返回" style:UIBarButtonItemStylePlain target:nil action:nil];
        [self.navigationController pushViewController:viewController animated:YES];
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (section == 0) {
        return @"Swift（Version：4.0）";
    }
    return @"Objective-C（Version：3.0）";
}
@end

@implementation ListItem

- (instancetype)initWithTitle:(NSString *)title subTitle:(NSString *)subTitle viewControllClass:(Class)class
{
    self = [super init];
    if (self) {
        self.title = title;
        self.subTitle = subTitle;
        self.viewControllClass = class;
    }
    return self;
}

@end
