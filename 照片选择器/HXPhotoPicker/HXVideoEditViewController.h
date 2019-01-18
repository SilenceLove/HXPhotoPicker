//
//  HXVideoEditViewController.h
//  照片选择器
//
//  Created by 洪欣 on 2017/12/31.
//  Copyright © 2017年 洪欣. All rights reserved.
//  

#import <UIKit/UIKit.h>
#import "HXPhotoManager.h"

@class HXVideoEditViewController;
@class HXVideoEditBottomView;
@protocol HXVideoEditViewControllerDelegate <NSObject>
@optional
- (void)videoEditViewControllerDidClipClick:(HXVideoEditViewController *)videoEditViewController beforeModel:(HXPhotoModel *)beforeModel afterModel:(HXPhotoModel *)afterModel;
@end
@interface HXVideoEditViewController : UIViewController
@property (weak, nonatomic) id<HXVideoEditViewControllerDelegate> delegate;
@property (strong, nonatomic) HXPhotoModel *model;
@property (strong, nonatomic) HXPhotoManager *manager;
@property (assign, nonatomic) BOOL outside;
@property (strong, nonatomic) AVAsset *avAsset;
@end


@protocol HXVideoEditBottomViewDelegate <NSObject>
@optional
- (void)videoEditBottomViewDidCancelClick:(HXVideoEditBottomView *)bottomView;
- (void)videoEditBottomViewDidDoneClick:(HXVideoEditBottomView *)bottomView;
@end
@interface HXVideoEditBottomView : UIView
@property (strong, nonatomic) NSMutableArray *dataArray;
@property (weak, nonatomic) id<HXVideoEditBottomViewDelegate> delegate;
- (instancetype)initWithManager:(HXPhotoManager *)manager;
@end

@interface HXVideoEditBottomViewCell : UICollectionViewCell
@property (strong, nonatomic) UIImageView *imageView;
@end

