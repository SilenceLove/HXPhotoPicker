//
//  HXCameraViewController.h
//  微博照片选择
//
//  Created by 洪欣 on 17/2/13.
//  Copyright © 2017年 洪欣. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "HXPhotoModel.h"

typedef enum : NSUInteger {
    HXCameraTypePhoto = 0,
    HXCameraTypeVideo,
    HXCameraTypePhotoAndVideo
} HXCameraType;
@class HXCameraViewController;
@protocol HXCameraViewControllerDelegate <NSObject>
@optional
- (void)cameraDidNextClick:(HXPhotoModel *)model;
- (void)cameraViewController:(HXCameraViewController *)cameraViewController didNext:(HXPhotoModel *)model;
- (void)cameraViewControllerDidCancel:(HXCameraViewController *)cameraViewController;
@end

@class HXPhotoManager;
@interface HXCameraViewController : UIViewController
@property (weak, nonatomic) id<HXCameraViewControllerDelegate> delegate;
@property (assign, nonatomic) BOOL isVideo;
@property (strong, nonatomic) HXPhotoManager *photoManager;
@property (assign, nonatomic) HXCameraType type;
@end

