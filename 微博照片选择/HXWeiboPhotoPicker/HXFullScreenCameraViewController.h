//
//  HXFullScreenCameraViewController.h
//  微博照片选择
//
//  Created by 洪欣 on 2017/5/22.
//  Copyright © 2017年 洪欣. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "HXCameraViewController.h"

@protocol HXFullScreenCameraViewControllerDelegate <NSObject>

- (void)fullScreenCameraDidNextClick:(HXPhotoModel *)model;

@end
@interface HXFullScreenCameraViewController : UIViewController

@property (weak, nonatomic) id<HXFullScreenCameraViewControllerDelegate> delegate;
@property (assign, nonatomic) BOOL isVideo;
@property (assign, nonatomic) HXCameraType type;
@property (strong, nonatomic) HXPhotoManager *photoManager;
@end
