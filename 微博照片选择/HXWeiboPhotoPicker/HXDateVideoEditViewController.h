//
//  HXDateVideoEditViewController.h
//  微博照片选择
//
//  Created by 洪欣 on 2017/12/31.
//  Copyright © 2017年 洪欣. All rights reserved.
//  

#import <UIKit/UIKit.h>
#import "HXPhotoManager.h"

@class HXDateVideoEditViewController;
@protocol HXDateVideoEditViewControllerDelegate <NSObject>
@optional
- (void)dateVideoEditViewControllerDidClipClick:(HXDateVideoEditViewController *)dateVideoEditViewController beforeModel:(HXPhotoModel *)beforeModel afterModel:(HXPhotoModel *)afterModel;
@end

@interface HXDateVideoEditViewController : UIViewController
@property (weak, nonatomic) id<HXDateVideoEditViewControllerDelegate> delegate;
@property (strong, nonatomic) HXPhotoModel *model;
@property (strong, nonatomic) HXPhotoManager *manager;
@property (assign, nonatomic) BOOL outside;
@end

@interface HXDataVideoEditBottomView : UIView

@end
