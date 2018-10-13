//
//  HXDatePhotoViewController.h
//  照片选择器
//
//  Created by 洪欣 on 2017/10/14.
//  Copyright © 2017年 洪欣. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "HXPhotoManager.h"
#import "HXCustomCollectionReusableView.h"

@class
HXDatePhotoViewController ,
HXDatePhotoViewCell ,
HXDatePhotoBottomView ,
HXCustomCameraController ,
HXCustomPreviewView ,
HXAlbumListViewController;
@protocol HXDatePhotoViewControllerDelegate <NSObject>
@optional

/**
 点击取消

 @param datePhotoViewController self
 */
- (void)datePhotoViewControllerDidCancel:(HXDatePhotoViewController *)datePhotoViewController;

/**
 点击完成时获取图片image完成后的回调
 选中了原图返回的就是原图
 需 requestImageAfterFinishingSelection = YES 才会有回调
 
 @param datePhotoViewController self
 @param imageList 图片数组
 */
- (void)datePhotoViewController:(HXDatePhotoViewController *)datePhotoViewController
                didDoneAllImage:(NSArray<UIImage *> *)imageList
                       original:(BOOL)original;

- (void)datePhotoViewController:(HXDatePhotoViewController *)datePhotoViewController
                          allAssetList:(NSArray<PHAsset *> *)allAssetList
                           photoAssets:(NSArray<PHAsset *> *)photoAssetList
                           videoAssets:(NSArray<PHAsset *> *)videoAssetList
                              original:(BOOL)original;

/**
 点击完成按钮

 @param datePhotoViewController self
 @param allList 已选的所有列表(包含照片、视频)
 @param photoList 已选的照片列表
 @param videoList 已选的视频列表
 @param original 是否原图
 */
- (void)datePhotoViewController:(HXDatePhotoViewController *)datePhotoViewController
                 didDoneAllList:(NSArray<HXPhotoModel *> *)allList
                         photos:(NSArray<HXPhotoModel *> *)photoList
                         videos:(NSArray<HXPhotoModel *> *)videoList
                       original:(BOOL)original;

/**
 改变了选择

 @param model 改的模型
 @param selected 是否选中
 */
- (void)datePhotoViewControllerDidChangeSelect:(HXPhotoModel *)model
                                      selected:(BOOL)selected;
@end

@interface HXDatePhotoViewController : UIViewController
@property (copy, nonatomic) viewControllerDidDoneBlock doneBlock;
@property (copy, nonatomic) viewControllerDidDoneAllImageBlock allImageBlock;
@property (copy, nonatomic) viewControllerDidDoneAllAssetBlock allAssetBlock;
@property (copy, nonatomic) viewControllerDidCancelBlock cancelBlock;
@property (weak, nonatomic) id<HXDatePhotoViewControllerDelegate> delegate;
@property (strong, nonatomic) HXPhotoManager *manager;
@property (strong, nonatomic) HXAlbumModel *albumModel;
@property (strong, nonatomic) HXDatePhotoBottomView *bottomView;
- (HXDatePhotoViewCell *)currentPreviewCell:(HXPhotoModel *)model;
- (BOOL)scrollToModel:(HXPhotoModel *)model;
- (void)scrollToPoint:(HXDatePhotoViewCell *)cell rect:(CGRect)rect;
@end

@protocol HXDatePhotoViewCellDelegate <NSObject>
@optional
- (void)datePhotoViewCell:(HXDatePhotoViewCell *)cell didSelectBtn:(UIButton *)selectBtn;
- (void)datePhotoViewCellRequestICloudAssetComplete:(HXDatePhotoViewCell *)cell;
@end

@interface HXDatePhotoViewCell : UICollectionViewCell
@property (weak, nonatomic) id<HXDatePhotoViewCellDelegate> delegate;
@property (assign, nonatomic) NSInteger section;
@property (assign, nonatomic) NSInteger item;
@property (strong, nonatomic, readonly) UIImageView *imageView;
@property (strong, nonatomic) CALayer *selectMaskLayer;
@property (strong, nonatomic) HXPhotoModel *model;
@property (assign, nonatomic) BOOL singleSelected;
@property (strong, nonatomic) UIColor *selectBgColor;
@property (strong, nonatomic) UIColor *selectedTitleColor;
- (void)resetNetworkImage;
- (void)cancelRequest;
- (void)startRequestICloudAsset;
- (void)bottomViewPrepareAnimation;
- (void)bottomViewStartAnimation;
@end

@interface HXDatePhotoCameraViewCell : UICollectionViewCell
@property (strong, nonatomic) HXPhotoModel *model;
@property (strong, nonatomic, readonly) HXCustomCameraController *cameraController;
@property (strong, nonatomic, readonly) HXCustomPreviewView *previewView;
- (void)starRunning;
- (void)stopRunning;
@end

@interface HXDatePhotoViewSectionHeaderView : HXCustomCollectionReusableView
@property (strong, nonatomic) HXPhotoDateModel *model;
@property (assign, nonatomic) BOOL changeState;
@property (assign, nonatomic) BOOL translucent;
@property (strong, nonatomic) UIColor *suspensionBgColor;
@property (strong, nonatomic) UIColor *suspensionTitleColor;
@end

@interface HXDatePhotoViewSectionFooterView : UICollectionReusableView
@property (assign, nonatomic) NSInteger photoCount;
@property (assign, nonatomic) NSInteger videoCount;
@end

@protocol HXDatePhotoBottomViewDelegate <NSObject>
@optional
- (void)datePhotoBottomViewDidPreviewBtn;
- (void)datePhotoBottomViewDidDoneBtn;
- (void)datePhotoBottomViewDidEditBtn;
@end

@interface HXDatePhotoBottomView : UIView
@property (weak, nonatomic) id<HXDatePhotoBottomViewDelegate> delegate;
@property (strong, nonatomic) HXPhotoManager *manager;
@property (assign, nonatomic) BOOL previewBtnEnabled;
@property (assign, nonatomic) BOOL doneBtnEnabled;
@property (assign, nonatomic) NSInteger selectCount;
@property (strong, nonatomic) UIButton *originalBtn;
@property (strong, nonatomic) UIToolbar *bgView;
@end
