//
//  HXVideoEditViewController.h
//  HXPhotoPickerExample
//
//  Created by Silence on 2017/12/31.
//  Copyright © 2017年 Silence. All rights reserved.
//  

#import <UIKit/UIKit.h>
#import "HXPhotoManager.h"

@class
HXVideoEditViewController,
HXVideoEditBottomView,
HXEditFrameView;

typedef void (^ HXVideoEditViewControllerDidDoneBlock)(HXPhotoModel *beforeModel, HXPhotoModel *afterModel, HXVideoEditViewController *viewController);
typedef void (^ HXVideoEditViewControllerDidCancelBlock)(HXVideoEditViewController *viewController);

@protocol HXVideoEditViewControllerDelegate <NSObject>
@optional

/// 编辑完成
/// @param videoEditViewController 视频编辑控制器
/// @param beforeModel 编辑之前的模型
/// @param afterModel 编辑之后的模型
- (void)videoEditViewControllerDidDoneClick:(HXVideoEditViewController *)videoEditViewController beforeModel:(HXPhotoModel *)beforeModel afterModel:(HXPhotoModel *)afterModel;

/// 取消编辑
/// @param videoEditViewController 视频编辑控制器
- (void)videoEditViewControllerDidCancelClick:(HXVideoEditViewController *)videoEditViewController;
@end
@interface HXVideoEditViewController : UIViewController<UIViewControllerTransitioningDelegate>
@property (weak, nonatomic) id<HXVideoEditViewControllerDelegate> delegate;

/// 需要编辑的模型
@property (strong, nonatomic) HXPhotoModel *model;
/// 照片管理类
@property (strong, nonatomic) HXPhotoManager *manager;

@property (copy, nonatomic) HXVideoEditViewControllerDidDoneBlock doneBlock;
@property (copy, nonatomic) HXVideoEditViewControllerDidCancelBlock cancelBlock;

@property (assign, nonatomic) BOOL outside;
@property (assign, nonatomic) BOOL isInside;
@property (strong, nonatomic) UIView *videoView;
@property (strong, nonatomic) AVPlayerLayer *playerLayer;
@property (strong, nonatomic) AVAsset *avAsset;

@property (strong, nonatomic) UIImageView *bgImageView;
@property (assign, nonatomic) BOOL requestComplete;
@property (assign, nonatomic) BOOL transitionCompletion;
@property (assign, nonatomic) BOOL isCancel;

- (void)completeTransition;
- (void)showBottomView;
- (CGRect)getVideoRect;
@end


@protocol HXVideoEditBottomViewDelegate <NSObject>
@optional
- (void)videoEditBottomViewDidCancelClick:(HXVideoEditBottomView *)bottomView;
- (void)videoEditBottomViewDidDoneClick:(HXVideoEditBottomView *)bottomView;
- (void)videoEditBottomViewValidRectChanged:(HXVideoEditBottomView *)bottomView;
- (void)videoEditBottomViewValidRectEndChanged:(HXVideoEditBottomView *)bottomView;

- (void)videoEditBottomViewIndicatorLinePanGestureBegan:(HXVideoEditBottomView *)bottomView frame:(CGRect)frame second:(CGFloat)second;
- (void)videoEditBottomViewIndicatorLinePanGestureChanged:(HXVideoEditBottomView *)bottomView second:(CGFloat)second;
- (void)videoEditBottomViewIndicatorLinePanGestureEnd:(HXVideoEditBottomView *)bottomView frame:(CGRect)frame second:(CGFloat)second;

@end
@interface HXVideoEditBottomView : UIView
@property (strong, nonatomic) UIButton *playBtn;
@property (assign, nonatomic) CGFloat itemHeight;
@property (assign, nonatomic) CGFloat itemWidth;
@property (assign, nonatomic) CGFloat validRectX;
@property (strong, nonatomic) HXPhotoModel *model;
@property (strong, nonatomic) UICollectionView *collectionView;
@property (strong, nonatomic) HXEditFrameView *editView;
@property (strong, nonatomic) AVAsset *avAsset;
@property (assign, nonatomic) CGFloat interval;
@property (assign, nonatomic) CGFloat contentWidth; 
@property (assign, nonatomic) CGFloat singleItemSecond;
@property (strong, nonatomic) NSMutableArray *dataArray;
@property (strong, nonatomic) UIView *indicatorLine;
@property (weak, nonatomic) id<HXVideoEditBottomViewDelegate> delegate;
@property (copy, nonatomic) void (^ scrollViewDidScroll)(void);
@property (copy, nonatomic) void (^ startTimer)(void);
@property (strong, nonatomic) UILabel *startTimeLb;
@property (strong, nonatomic) UILabel *endTimeLb;
@property (strong, nonatomic) UILabel *totalTimeLb;
- (instancetype)initWithManager:(HXPhotoManager *)manager;

- (void)removeLineView;
- (void)startLineAnimationWithDuration:(NSTimeInterval)duration;
- (void)panGestureStarAnimationWithDuration:(NSTimeInterval)duration;
- (void)updateTimeLbsFrame;
@end

@interface HXVideoEditBottomViewCell : UICollectionViewCell
@property (strong, nonatomic) UIImageView *imageView;
@end


@protocol HXEditFrameViewDelegate <NSObject>

- (void)editViewValidRectChanged;

- (void)editViewValidRectEndChanged;

@end
@interface HXEditFrameView : UIView
@property (assign, nonatomic) CGFloat itemHeight;
@property (assign, nonatomic) CGFloat itemWidth;
@property (assign, nonatomic) CGFloat validRectX;
@property (nonatomic, assign) CGRect validRect;
@property (assign, nonatomic) CGFloat contentWidth;
@property (assign, nonatomic) NSTimeInterval videoTime;
@property (nonatomic, weak) id <HXEditFrameViewDelegate> delegate;
- (instancetype)initWithManager:(HXPhotoManager *)manager;
@end
 
