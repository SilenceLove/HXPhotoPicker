//
//  HXPhotoEditViewController.h
//  HXPhotoPickerExample
//
//  Created by Silence on 2017/10/27.
//  Copyright © 2017年 Silence. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "HXPhotoManager.h"

@class HXPhotoEditViewController;

typedef void (^ HXPhotoEditViewControllerDidDoneBlock)(HXPhotoModel *beforeModel, HXPhotoModel *afterModel, HXPhotoEditViewController *viewController);
typedef void (^ HXPhotoEditViewControllerDidCancelBlock)(HXPhotoEditViewController *viewController);

@protocol HXPhotoEditViewControllerDelegate <NSObject>
@optional

/// 编辑完成
/// @param photoEditViewController 照片编辑控制器
/// @param beforeModel 编辑之前的模型
/// @param afterModel 编辑之后的模型
- (void)photoEditViewControllerDidClipClick:(HXPhotoEditViewController *)photoEditViewController beforeModel:(HXPhotoModel *)beforeModel afterModel:(HXPhotoModel *)afterModel;

/// 取消编辑
/// @param photoEditViewController 照片编辑控制器
- (void)photoEditViewControllerDidCancel:(HXPhotoEditViewController *)photoEditViewController;
@end

@interface HXPhotoEditViewController : UIViewController<UIViewControllerTransitioningDelegate>
@property (weak, nonatomic) id<HXPhotoEditViewControllerDelegate> delegate;
/// 需要编辑的照片模型
@property (strong, nonatomic) HXPhotoModel *model;
/// 照片管理类
@property (strong, nonatomic) HXPhotoManager *manager;

@property (copy, nonatomic) HXPhotoEditViewControllerDidDoneBlock doneBlock;
@property (copy, nonatomic) HXPhotoEditViewControllerDidCancelBlock cancelBlock;

@property (assign, nonatomic) BOOL outside;
@property (assign, nonatomic) BOOL isInside;
@property (assign, nonatomic) BOOL imageRequestComplete;
@property (assign, nonatomic) BOOL transitionCompletion;
@property (assign, nonatomic) BOOL isCancel;
@property (strong, nonatomic, readonly) UIImage *originalImage;
- (void)completeTransition:(UIImage *)image; 
- (void)showBottomView;
- (void)hideImageView;
- (UIImage *)getCurrentImage;
- (CGRect)getImageFrame;
@end

@class HXEditRatio;
@protocol HXPhotoEditBottomViewDelegate <NSObject>
@optional
- (void)bottomViewDidCancelClick;
- (void)bottomViewDidRestoreClick;
- (void)bottomViewDidRotateClick;
- (void)bottomViewDidClipClick;
- (void)bottomViewDidSelectRatioClick:(HXEditRatio *)ratio;
@end

@interface HXPhotoEditBottomView : UIView
@property (weak, nonatomic) id<HXPhotoEditBottomViewDelegate> delegate;
@property (assign, nonatomic) BOOL enabled;
- (instancetype)initWithManager:(HXPhotoManager *)manager;
@end

@interface HXEditGridLayer : UIView
@property (nonatomic, assign) CGRect clippingRect;
@property (nonatomic, strong) UIColor *bgColor;
@property (nonatomic, strong) UIColor *gridColor; 
@end

@interface HXEditCornerView : UIView
@property (nonatomic, strong) UIColor *bgColor;
@end

@interface HXEditRatio : NSObject
@property (nonatomic, assign) BOOL isLandscape;
@property (nonatomic, readonly) CGFloat ratio;
@property (nonatomic, strong) NSString *titleFormat; 
- (id)initWithValue1:(CGFloat)value1 value2:(CGFloat)value2;
@end
