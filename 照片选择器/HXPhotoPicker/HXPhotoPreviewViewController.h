//
//  HXPhotoPreviewViewController.h
//  照片选择器
//
//  Created by 洪欣 on 2017/10/14.
//  Copyright © 2017年 洪欣. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <PhotosUI/PhotosUI.h>
#import "HXPhotoManager.h"
#import "HXPhotoView.h"

#if __has_include(<SDWebImage/UIImageView+WebCache.h>)
#import <SDWebImage/UIImageView+WebCache.h>
#elif __has_include("UIImageView+WebCache.h")
#import "UIImageView+WebCache.h"
#endif

#if __has_include(<YYWebImage/YYWebImage.h>)
#import <YYWebImage/YYWebImage.h>
#elif __has_include("YYWebImage.h")
#import "YYWebImage.h"
#elif __has_include(<YYKit/YYKit.h>)
#import <YYKit/YYKit.h>
#elif __has_include("YYKit.h")
#import "YYKit.h"
#endif

@class
HXPhotoPreviewViewController,
HXPhotoPreviewBottomView,
HXPhotoPreviewViewCell;
@protocol HXPhotoPreviewViewControllerDelegate <NSObject>
@optional
- (void)photoPreviewControllerDidSelect:(HXPhotoPreviewViewController *)previewController
                                      model:(HXPhotoModel *)model;

- (void)photoPreviewControllerDidDone:(HXPhotoPreviewViewController *)previewController;

- (void)photoPreviewDidEditClick:(HXPhotoPreviewViewController *)previewController
                               model:(HXPhotoModel *)model
                         beforeModel:(HXPhotoModel *)beforeModel;

- (void)photoPreviewSingleSelectedClick:(HXPhotoPreviewViewController *)previewController
                                      model:(HXPhotoModel *)model;

- (void)photoPreviewDownLoadICloudAssetComplete:(HXPhotoPreviewViewController *)previewController
                                              model:(HXPhotoModel *)model;

- (void)photoPreviewSelectLaterDidEditClick:(HXPhotoPreviewViewController *)previewController
                                    beforeModel:(HXPhotoModel *)beforeModel
                                     afterModel:(HXPhotoModel *)afterModel;

- (void)photoPreviewDidDeleteClick:(HXPhotoPreviewViewController *)previewController
                       deleteModel:(HXPhotoModel *)model
                       deleteIndex:(NSInteger)index;

- (void)photoPreviewCellDownloadImageComplete:(HXPhotoPreviewViewController *)previewController
                                            model:(HXPhotoModel *)model;
@end

@interface HXPhotoPreviewViewController : UIViewController<UIViewControllerTransitioningDelegate,UINavigationControllerDelegate>
@property (weak, nonatomic) id<HXPhotoPreviewViewControllerDelegate> delegate;
@property (strong, nonatomic) HXPhotoManager *manager;
@property (strong, nonatomic) NSMutableArray *modelArray;
@property (assign, nonatomic) NSInteger currentModelIndex;
@property (assign, nonatomic) BOOL outside;
@property (assign, nonatomic) BOOL selectPreview;
@property (strong, nonatomic) UICollectionView *collectionView;
@property (strong, nonatomic) HXPhotoPreviewBottomView *bottomView;
@property (strong, nonatomic) HXPhotoView *photoView;
@property (assign, nonatomic) BOOL previewShowDeleteButton;
@property (assign, nonatomic) BOOL stopCancel;
/**  预览大图时是否禁用手势返回  */
@property (assign, nonatomic) BOOL disableaPersentInteractiveTransition;
/**  使用HXPhotoView预览大图时的风格样式  */
@property (assign, nonatomic) HXPhotoViewPreViewShowStyle exteriorPreviewStyle;

// 处理ios8 导航栏转场动画崩溃问题
@property (strong, nonatomic) UIViewController *photoViewController;

- (HXPhotoPreviewViewCell *)currentPreviewCell:(HXPhotoModel *)model;
- (void)changeStatusBarWithHidden:(BOOL)hidden;
- (void)setSubviewAlphaAnimate:(BOOL)animete duration:(NSTimeInterval)duration;
- (void)setupDarkBtnAlpha:(CGFloat)alpha;
@end


@interface HXPhotoPreviewViewCell : UICollectionViewCell
@property (assign, nonatomic) BOOL stopCancel;
@property (strong, nonatomic) HXPhotoModel *model;

#if HasYYKitOrWebImage
@property (strong, nonatomic) YYAnimatedImageView *animatedImageView;
#endif

@property (strong, nonatomic, readonly) UIImageView *imageView;
@property (strong, nonatomic, readonly) AVPlayerLayer *playerLayer;
@property (strong, nonatomic, readonly) UIImage *gifImage;
@property (strong, nonatomic, readonly) UIScrollView *scrollView;
@property (strong, nonatomic) UIButton *videoPlayBtn;
@property (assign, nonatomic) CGFloat zoomScale;
@property (assign, nonatomic) BOOL dragging;
@property (strong, nonatomic) AVAsset *avAsset;
@property (nonatomic, copy) void (^cellTapClick)(void);
@property (nonatomic, copy) void (^cellDidPlayVideoBtn)(BOOL play);
@property (nonatomic, copy) void (^cellDownloadICloudAssetComplete)(HXPhotoPreviewViewCell *myCell);
@property (nonatomic, copy) void (^cellDownloadImageComplete)(HXPhotoPreviewViewCell *myCell);
- (void)againAddImageView;
- (void)refreshImageSize;
- (void)resetScale:(BOOL)animated;
- (void)resetScale:(CGFloat)scale animated:(BOOL)animated;
- (void)requestHDImage;
- (void)cancelRequest;
- (CGSize)getImageSize;

- (CGFloat)getScrollViewZoomScale;
- (void)setScrollViewZoomScale:(CGFloat)zoomScale;
- (CGSize)getScrollViewContentSize;
- (void)setScrollViewContnetSize:(CGSize)contentSize;
- (CGPoint)getScrollViewContentOffset;
- (void)setScrollViewContentOffset:(CGPoint)contentOffset;
@end
