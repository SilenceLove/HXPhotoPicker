//
//  HXDateVideoEditViewController.h
//  照片选择器
//
//  Created by 洪欣 on 2017/12/31.
//  Copyright © 2017年 洪欣. All rights reserved.
//  

#import <UIKit/UIKit.h>
#import "HXPhotoManager.h"

@class HXDateVideoEditViewController;
@class HXDataVideoEditBottomView;
@protocol HXDateVideoEditViewControllerDelegate <NSObject>
@optional
- (void)dateVideoEditViewControllerDidClipClick:(HXDateVideoEditViewController *)dateVideoEditViewController beforeModel:(HXPhotoModel *)beforeModel afterModel:(HXPhotoModel *)afterModel;
@end
@interface HXDateVideoEditViewController : UIViewController
@property (weak, nonatomic) id<HXDateVideoEditViewControllerDelegate> delegate;
@property (strong, nonatomic) HXPhotoModel *model;
@property (strong, nonatomic) HXPhotoManager *manager;
@property (assign, nonatomic) BOOL outside;
@property (strong, nonatomic) AVAsset *avAsset;
@end


@protocol HXDataVideoEditBottomViewDelegate <NSObject>
@optional
- (void)videoEditBottomViewDidCancelClick:(HXDataVideoEditBottomView *)bottomView;
- (void)videoEditBottomViewDidDoneClick:(HXDataVideoEditBottomView *)bottomView;
@end
@interface HXDataVideoEditBottomView : UIView
@property (strong, nonatomic) NSMutableArray *dataArray;
@property (weak, nonatomic) id<HXDataVideoEditBottomViewDelegate> delegate;
- (instancetype)initWithManager:(HXPhotoManager *)manager;
@end

@interface HXDataVideoEditBottomViewCell : UICollectionViewCell
@property (strong, nonatomic) UIImageView *imageView;
@end

