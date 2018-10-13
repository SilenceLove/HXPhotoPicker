//
//  HXCustomCameraViewController.h
//  照片选择器
//
//  Created by 洪欣 on 2017/9/30.
//  Copyright © 2017年 洪欣. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

typedef NS_ENUM(NSUInteger, HXCustomCameraBottomViewMode) {
    HXCustomCameraBottomViewModePhoto,      //!< 拍照
    HXCustomCameraBottomViewModeVideo = 1,  //!< 录制
};

@class HXPhotoManager,HXCustomCameraViewController,HXPhotoModel;
 
typedef void (^ HXCustomCameraViewControllerDidDoneBlock)(HXPhotoModel *model, HXCustomCameraViewController *viewController);
typedef void (^ HXCustomCameraViewControllerDidCancelBlock)(HXCustomCameraViewController *viewController);

@protocol HXCustomCameraViewControllerDelegate <NSObject>
@optional
- (void)customCameraViewController:(HXCustomCameraViewController *)viewController didDone:(HXPhotoModel *)model;
- (void)customCameraViewControllerDidCancel:(HXCustomCameraViewController *)viewController;
@end

@interface HXCustomCameraViewController : UIViewController
@property (weak, nonatomic) id<HXCustomCameraViewControllerDelegate> delegate;
@property (strong, nonatomic) HXPhotoManager *manager;
@property (assign, nonatomic) BOOL isOutside;
@property (copy, nonatomic) HXCustomCameraViewControllerDidDoneBlock doneBlock;
@property (copy, nonatomic) HXCustomCameraViewControllerDidCancelBlock cancelBlock;
@end

@protocol HXCustomCameraBottomViewDelegate <NSObject>
@optional
- (void)playViewClick;
- (void)playViewAnimateCompletion;
- (void)playViewChangeMode:(HXCustomCameraBottomViewMode)mode;
@end

@interface HXCustomCameraBottomView : UIView
@property (weak, nonatomic) id<HXCustomCameraBottomViewDelegate> delegate;
@property (assign ,nonatomic) BOOL animating;
@property (assign, nonatomic) HXCustomCameraBottomViewMode mode;
- (instancetype)initWithFrame:(CGRect)frame manager:(HXPhotoManager *)manager isOutside:(BOOL)isOutside;
- (void)changeTime:(NSInteger)time;
- (void)startRecord;
- (void)stopRecord;
- (void)beganAnimate;
- (void)leftAnimate;
- (void)rightAnimate;
@end

@interface HXCustomCameraPlayVideoView : UIView
@property (strong, nonatomic) NSURL *videoURL;
@property (strong, nonatomic) AVPlayerLayer *playerLayer;
- (void)stopPlay;
@end
