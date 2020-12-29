//
//  HXPhotoPreviewViewController.h
//  HXPhotoPickerExample
//
//  Created by Silence on 2017/10/14.
//  Copyright © 2017年 Silence. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <PhotosUI/PhotosUI.h>
#import "HXPhotoManager.h"
#import "HXPhotoView.h"
#import "HXPhotoPreviewImageViewCell.h"
#import "HXPhotoPreviewVideoViewCell.h"
#import "HXPhotoPreviewLivePhotoCell.h"

@class
HXPhotoPreviewViewController,
HXPhotoPreviewBottomView,
HXPhotoPreviewViewCell;
@protocol HXPhotoPreviewViewControllerDelegate <NSObject>
@optional

/// 选择某个model
/// 根据 model.selected 来判断是否选中
/// @param previewController 照片预览控制器
/// @param model 当前选择的模型
- (void)photoPreviewControllerDidSelect:(HXPhotoPreviewViewController *)previewController
                                      model:(HXPhotoModel *)model;

/// 点击
/// @param previewController 照片预览控制器
- (void)photoPreviewControllerDidDone:(HXPhotoPreviewViewController *)previewController;

/// 预览界面编辑完成之后的回调
/// @param previewController 照片预览控制器
/// @param model 编辑之后的模型
/// @param beforeModel 编辑之前的模型
- (void)photoPreviewDidEditClick:(HXPhotoPreviewViewController *)previewController
                         model:(HXPhotoModel *)model
                    beforeModel:(HXPhotoModel *)beforeModel;

/// 单选模式下选择了某个model
/// @param previewController 照片预览控制器
/// @param model 当前选择的model
- (void)photoPreviewSingleSelectedClick:(HXPhotoPreviewViewController *)previewController
                                  model:(HXPhotoModel *)model;

/// 预览界面加载iCloud上的照片完成后的回调
/// @param previewController 照片预览控制器
/// @param model 当前model
- (void)photoPreviewDownLoadICloudAssetComplete:(HXPhotoPreviewViewController *)previewController
                                          model:(HXPhotoModel *)model;

/// 在HXPhotoView上预览时编辑model完成之后的回调
/// @param previewController 照片预览控制器
/// @param beforeModel 编辑之前的model
/// @param afterModel 编辑之后的model
- (void)photoPreviewSelectLaterDidEditClick:(HXPhotoPreviewViewController *)previewController
                                beforeModel:(HXPhotoModel *)beforeModel
                                 afterModel:(HXPhotoModel *)afterModel;

/// 在HXPhotoView上预览时删除model的回调
/// @param previewController 照片预览控制器
/// @param model 被删除的model
/// @param index model下标
- (void)photoPreviewDidDeleteClick:(HXPhotoPreviewViewController *)previewController
                       deleteModel:(HXPhotoModel *)model
                       deleteIndex:(NSInteger)index;

/// 预览时网络图片下载完成的回调，用于刷新前一个界面的展示
/// @param previewController 照片预览控制器
/// @param model 当前预览的model
- (void)photoPreviewCellDownloadImageComplete:(HXPhotoPreviewViewController *)previewController
                                        model:(HXPhotoModel *)model;

/// 取消预览
/// @param previewController self
/// @param model 取消时展示的model
- (void)photoPreviewControllerDidCancel:(HXPhotoPreviewViewController *)previewController
                                  model:(HXPhotoModel *)model;


- (void)photoPreviewControllerFinishDismissCompletion:(HXPhotoPreviewViewController *)previewController;
- (void)photoPreviewControllerCancelDismissCompletion:(HXPhotoPreviewViewController *)previewController;
@end

/// 单独使用 HXPhotoPreviewViewController 来预览图片
/// 请使用 <UIViewController+HXExtension> 中的方法
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
/// 停止取消
@property (assign, nonatomic) BOOL stopCancel;
/// 预览时显示删除按钮
@property (assign, nonatomic) BOOL previewShowDeleteButton;
/// 预览大图时是否禁用手势返回
@property (assign, nonatomic) BOOL disableaPersentInteractiveTransition;
/// 使用HXPhotoView预览大图时的风格样式
@property (assign, nonatomic) HXPhotoViewPreViewShowStyle exteriorPreviewStyle;
/// 预览时是否显示底部pageControl
@property (assign, nonatomic) BOOL showBottomPageControl;
/// 处理ios8 导航栏转场动画崩溃问题
@property (strong, nonatomic) UIViewController *photoViewController;
@property (copy, nonatomic) void (^ currentCellScrollViewDidScroll)(UIScrollView *scrollView);

- (HXPhotoPreviewViewCell *)currentPreviewCell:(HXPhotoModel *)model;
- (void)changeStatusBarWithHidden:(BOOL)hidden;
- (void)setSubviewAlphaAnimate:(BOOL)animete duration:(NSTimeInterval)duration;
- (void)setupDarkBtnAlpha:(CGFloat)alpha;
- (void)setCellImage:(UIImage *)image;
@end 
