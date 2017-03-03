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

@protocol HXCameraViewControllerDelegate <NSObject>

- (void)cameraDidNextClick:(HXPhotoModel *)model;

@end

@interface HXCameraViewController : UIViewController
@property (weak, nonatomic) id<HXCameraViewControllerDelegate> delegate;
@property (assign, nonatomic) BOOL isVideo;
@property (assign, nonatomic) HXCameraType type;
@end
