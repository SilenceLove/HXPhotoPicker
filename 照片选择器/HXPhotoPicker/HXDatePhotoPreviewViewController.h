//
//  HXDatePhotoPreviewViewController.h
//  照片选择器
//
//  Created by 洪欣 on 2017/10/14.
//  Copyright © 2017年 洪欣. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <PhotosUI/PhotosUI.h>
#import "HXPhotoManager.h"
#import "HXPhotoView.h"

#if __has_include(<YYWebImage/YYWebImage.h>)
#import <YYWebImage/YYWebImage.h>
#elif __has_include("YYWebImage.h")
#import "YYWebImage.h"
#endif

@class HXDatePhotoPreviewViewController,HXDatePhotoPreviewBottomView,HXDatePhotoPreviewViewCell;
@protocol HXDatePhotoPreviewViewControllerDelegate <NSObject>
@optional
- (void)datePhotoPreviewControllerDidSelect:(HXDatePhotoPreviewViewController *)previewController model:(HXPhotoModel *)model;
- (void)datePhotoPreviewControllerDidDone:(HXDatePhotoPreviewViewController *)previewController;
- (void)datePhotoPreviewDidEditClick:(HXDatePhotoPreviewViewController *)previewController;
- (void)datePhotoPreviewSingleSelectedClick:(HXDatePhotoPreviewViewController *)previewController model:(HXPhotoModel *)model;
- (void)datePhotoPreviewDownLoadICloudAssetComplete:(HXDatePhotoPreviewViewController *)previewController model:(HXPhotoModel *)model;
- (void)datePhotoPreviewSelectLaterDidEditClick:(HXDatePhotoPreviewViewController *)previewController beforeModel:(HXPhotoModel *)beforeModel afterModel:(HXPhotoModel *)afterModel;
- (void)datePhotoPreviewDidDeleteClick:(HXDatePhotoPreviewViewController *)previewController deleteModel:(HXPhotoModel *)model deleteIndex:(NSInteger)index;
- (void)datePhotoPreviewCellDownloadImageComplete:(HXDatePhotoPreviewViewController *)previewController model:(HXPhotoModel *)model;
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
@property (assign, nonatomic) BOOL previewShowDeleteButton;
@property (assign, nonatomic) BOOL stopCancel;
/**  预览大图时是否禁用手势返回  */
@property (assign, nonatomic) BOOL disableaPersentInteractiveTransition;
/**  使用HXPhotoView预览大图时的风格样式  */
@property (assign, nonatomic) HXPhotoViewPreViewShowStyle exteriorPreviewStyle;

- (HXDatePhotoPreviewViewCell *)currentPreviewCell:(HXPhotoModel *)model;
- (void)setSubviewAlphaAnimate:(BOOL)animete duration:(NSTimeInterval)duration;
- (void)setupDarkBtnAlpha:(CGFloat)alpha;
@end


@interface HXDatePhotoPreviewViewCell : UICollectionViewCell
@property (assign, nonatomic) BOOL stopCancel;
@property (strong, nonatomic) HXPhotoModel *model;

#if __has_include(<YYWebImage/YYWebImage.h>) || __has_include("YYWebImage.h")
@property (strong, nonatomic) YYAnimatedImageView *animatedImageView;
#endif

@property (strong, nonatomic, readonly) UIImageView *imageView;
@property (strong, nonatomic, readonly) AVPlayerLayer *playerLayer;
@property (strong, nonatomic, readonly) UIImage *gifImage;
@property (strong, nonatomic) UIButton *videoPlayBtn;
@property (assign, nonatomic) BOOL dragging;
@property (nonatomic, copy) void (^cellTapClick)(void);
@property (nonatomic, copy) void (^cellDidPlayVideoBtn)(BOOL play);
@property (nonatomic, copy) void (^cellDownloadICloudAssetComplete)(HXDatePhotoPreviewViewCell *myCell);
@property (nonatomic, copy) void (^cellDownloadImageComplete)(HXDatePhotoPreviewViewCell *myCell);
- (void)againAddImageView;
- (void)resetScale;
- (void)requestHDImage;
- (void)cancelRequest;
@end
