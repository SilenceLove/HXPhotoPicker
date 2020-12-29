//
//  SettingViewController.h
//  HXPhotoPickerExample
//
//  Created by Silence on 2019/2/2.
//  Copyright © 2019年 Silence. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN
@class HXPhotoManager;
@interface SettingViewController : UIViewController
@property (weak, nonatomic) HXPhotoManager *manager;
@property (copy, nonatomic) void (^ saveCompletion)(HXPhotoManager *manager);
@end

NS_ASSUME_NONNULL_END
