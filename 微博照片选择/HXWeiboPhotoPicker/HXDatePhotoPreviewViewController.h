//
//  HXDatePhotoPreviewViewController.h
//  微博照片选择
//
//  Created by 洪欣 on 2017/10/14.
//  Copyright © 2017年 洪欣. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <PhotosUI/PhotosUI.h>
#import "HXPhotoManager.h"

@class HXDatePhotoPreviewViewController,HXDatePhotoPreviewBottomView,HXDatePhotoPreviewViewCell,HXPhotoView;
@protocol HXDatePhotoPreviewViewControllerDelegate <NSObject>
@optional
- (void)datePhotoPreviewControllerDidSelect:(HXDatePhotoPreviewViewController *)previewController model:(HXPhotoModel *)model;
- (void)datePhotoPreviewControllerDidDone:(HXDatePhotoPreviewViewController *)previewController;
- (void)datePhotoPreviewDidEditClick:(HXDatePhotoPreviewViewController *)previewController;
- (void)datePhotoPreviewSingleSelectedClick:(HXDatePhotoPreviewViewController *)previewController model:(HXPhotoModel *)model;
- (void)datePhotoPreviewDownLoadICloudAssetComplete:(HXDatePhotoPreviewViewController *)previewController model:(HXPhotoModel *)model;
- (void)datePhotoPreviewSelectLaterDidEditClick:(HXDatePhotoPreviewViewController *)previewController beforeModel:(HXPhotoModel *)beforeModel afterModel:(HXPhotoModel *)afterModel;
@end

@interface HXDatePhotoPreviewViewController : UIViewController<UIViewControllerTransitioningDelegate,UINavigationControllerDelegate>
@property (weak, nonatomic) id<HXDatePhotoPreviewViewControllerDelegate> delegate;
@property (strong, nonatomic) HXPhotoManager *manager;
@property (strong, nonatomic) NSMutableArray *modelArray;
@property (assign, nonatomic) NSInteger currentModelIndex;
@property (assign, nonatomic) BOOL outside;
@property (assign, nonatomic) BOOL selectPreview;
@property (strong, nonatomic) UICollectionView *collectionView;
@property (strong, nonatomic) HXDatePhotoPreviewBottomView *bottomView;
@property (strong, nonatomic) HXPhotoView *photoView;
@property (assign, nonatomic) BOOL stopCancel;
- (HXDatePhotoPreviewViewCell *)currentPreviewCell:(HXPhotoModel *)model;
- (void)setSubviewAlphaAnimate:(BOOL)animete;
@end


@interface HXDatePhotoPreviewViewCell : UICollectionViewCell
@property (assign, nonatomic) BOOL stopCancel;
@property (strong, nonatomic) HXPhotoModel *model;
@property (strong, nonatomic, readonly) UIImageView *imageView;
@property (strong, nonatomic, readonly) AVPlayerLayer *playerLayer;
@property (strong, nonatomic, readonly) UIImage *gifImage;
@property (strong, nonatomic) UIButton *videoPlayBtn;
@property (assign, nonatomic) BOOL dragging;
@property (nonatomic, copy) void (^cellTapClick)();
@property (nonatomic, copy) void (^cellDidPlayVideoBtn)(BOOL play);
@property (nonatomic, copy) void (^cellDownloadICloudAssetComplete)(HXDatePhotoPreviewViewCell *myCell);
- (void)againAddImageView;
- (void)resetScale;
- (void)requestHDImage;
- (void)cancelRequest;
@end
