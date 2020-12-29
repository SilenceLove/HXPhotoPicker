//
//  HXCustomCameraViewController.h
//  HXPhotoPickerExample
//
//  Created by Silence on 2017/9/30.
//  Copyright © 2017年 Silence. All rights reserved.
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

/// 拍照/录制完成
/// @param viewController self
/// @param model 资源模型
- (void)customCameraViewController:(HXCustomCameraViewController *)viewController
                           didDone:(HXPhotoModel *)model;

/// 取消
/// @param viewController self
- (void)customCameraViewControllerDidCancel:(HXCustomCameraViewController *)viewController;

- (void)customCameraViewControllerFinishDismissCompletion:(HXCustomCameraViewController *)viewController;
- (void)customCameraViewControllerCancelDismissCompletion:(HXCustomCameraViewController *)viewController;
@end

@interface HXCustomCameraViewController : UIViewController
@property (weak, nonatomic) id<HXCustomCameraViewControllerDelegate> delegate;
@property (strong, nonatomic) HXPhotoManager *manager;
@property (assign, nonatomic) BOOL isOutside;
@property (copy, nonatomic) HXCustomCameraViewControllerDidDoneBlock doneBlock;
@property (copy, nonatomic) HXCustomCameraViewControllerDidCancelBlock cancelBlock;

#pragma mark - < other >
- (UIImage *)jumpImage;
- (CGRect)jumpRect;
- (void)hidePlayerView;
- (void)showPlayerView;
- (void)hiddenTopBottomView;
- (void)showTopBottomView;
@end

@interface HXCustomCameraPlayVideoView : UIView
@property (strong, nonatomic) NSURL *videoURL;
@property (strong, nonatomic) AVPlayerLayer *playerLayer;
- (void)stopPlay;
@end
