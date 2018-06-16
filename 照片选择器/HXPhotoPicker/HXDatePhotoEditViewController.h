//
//  HXDatePhotoEditViewController.h
//  照片选择器
//
//  Created by 洪欣 on 2017/10/27.
//  Copyright © 2017年 洪欣. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "HXPhotoManager.h"

@class HXDatePhotoEditViewController;
@protocol HXDatePhotoEditViewControllerDelegate <NSObject>
@optional
- (void)datePhotoEditViewControllerDidClipClick:(HXDatePhotoEditViewController *)datePhotoEditViewController beforeModel:(HXPhotoModel *)beforeModel afterModel:(HXPhotoModel *)afterModel;
@end

@interface HXDatePhotoEditViewController : UIViewController
@property (weak, nonatomic) id<HXDatePhotoEditViewControllerDelegate> delegate;
@property (strong, nonatomic) HXPhotoModel *model;
@property (strong, nonatomic) HXPhotoManager *manager;
@property (assign, nonatomic) BOOL outside;
@end

@class HXEditRatio;
@protocol HXDatePhotoEditBottomViewDelegate <NSObject>
@optional
- (void)bottomViewDidCancelClick;
- (void)bottomViewDidRestoreClick;
- (void)bottomViewDidRotateClick;
- (void)bottomViewDidClipClick;
- (void)bottomViewDidSelectRatioClick:(HXEditRatio *)ratio;
@end

@interface HXDatePhotoEditBottomView : UIView
@property (weak, nonatomic) id<HXDatePhotoEditBottomViewDelegate> delegate;
@property (assign, nonatomic) BOOL enabled;
- (instancetype)initWithManager:(HXPhotoManager *)manager;
@end

@interface HXEditGridLayer : CALayer
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
