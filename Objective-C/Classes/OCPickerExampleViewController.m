//
//  OCPickerExampleViewController.m
//  HXPhotoPickerExample
//
//  Created by Silence on 2023/6/14.
//  Copyright © 2023 洪欣. All rights reserved.
//

#import "OCPickerExampleViewController.h"
#import "HXPhotoPickerExample-Swift.h"
#import "HXPhotoPicker.h"

@interface OCPickerExampleViewController ()

@end

@implementation OCPickerExampleViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.title = @"OC调用Swift";
    self.view.backgroundColor = UIColor.whiteColor;
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"打开选择器" style:UIBarButtonItemStyleDone target:self action:@selector(openPicker)];
}

- (void)openPicker {
    SwiftPickerConfiguration *config = [[SwiftPickerConfiguration alloc] init];
    config.isAutoBack = NO;
    HXWeakSelf
    [SwiftPicker openPicker:config fromVC:self finish:^(SwiftPickerResult * _Nonnull pickerResult, PhotoPickerController * _Nonnull photoPickerController) {
        [photoPickerController dismissViewControllerAnimated:YES completion:^{
            [weakSelf.view showLoading:@"正在获取URL，结果打印在控制台"];
            NSLog(@"选择完成，正在获取URL");
            [pickerResult getURLsWithOptions:OptionsAny urlReceivedHandler:^(SwiftAssetURLResult * _Nullable urlResult, NSInteger index) {
                NSLog(@"获取到第%ld个URL:%@", (long)index, [urlResult url]);
            } completionHandler:^(NSArray<NSURL *> * _Nonnull urls) {
                NSLog(@"URL全部获取完成:%@", urls);
                [weakSelf.view hide];
                PickerResultViewController *vc = [[PickerResultViewController alloc] initWithAssets:pickerResult.photoAssets];
                [weakSelf.navigationController pushViewController:vc animated:YES];
            }];
        }];
    } cancel:^(PhotoPickerController * _Nonnull photoPickerController) {
        NSLog(@"取消选择");
    }];
}

@end
