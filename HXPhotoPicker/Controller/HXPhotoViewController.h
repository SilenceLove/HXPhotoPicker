//
//  HXPhotoViewController.h
//  HXPhotoPickerExample
//
//  Created by Silence on 2017/10/14.
//  Copyright © 2017年 Silence. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "HXPhotoManager.h"
#import "HXCustomCollectionReusableView.h"
#import "HXPhotoLimitView.h"
#import "HXPickerResult.h"

@class
HXPhotoViewController ,
HXPhotoViewCell ,
HXPhotoBottomView ,
HXCustomPreviewView ,
HXAlbumListViewController,
HXCustomCameraController;
@protocol HXPhotoViewControllerDelegate <NSObject>
@optional

/**
 点击取消

 @param photoViewController self
 */
- (void)photoViewControllerDidCancel:(HXPhotoViewController *)photoViewController;

/**
 点击完成按钮

 @param photoViewController self
 @param allList 已选的所有列表(包含照片、视频)
 @param photoList 已选的照片列表
 @param videoList 已选的视频列表
 @param original 是否原图
 */
- (void)photoViewController:(HXPhotoViewController *)photoViewController
             didDoneAllList:(NSArray<HXPhotoModel *> *)allList
                     photos:(NSArray<HXPhotoModel *> *)photoList
                     videos:(NSArray<HXPhotoModel *> *)videoList
                   original:(BOOL)original;

- (void)photoViewController:(HXPhotoViewController *)photoViewController
          didDoneWithResult:(HXPickerResult *)result;

/**
 改变了选择

 @param model 改的模型
 @param selected 是否选中
 */
- (void)photoViewControllerDidChangeSelect:(HXPhotoModel *)model
                                  selected:(BOOL)selected;

- (void)photoViewControllerFinishDismissCompletion:(HXPhotoViewController *)photoViewController;
- (void)photoViewControllerCancelDismissCompletion:(HXPhotoViewController *)photoViewController;
@end

@interface HXPhotoViewController : UIViewController
@property (copy, nonatomic) viewControllerDidDoneBlock doneBlock;
@property (copy, nonatomic) viewControllerDidCancelBlock cancelBlock;
@property (weak, nonatomic) id<HXPhotoViewControllerDelegate> delegate;
@property (strong, nonatomic) HXPhotoManager *manager;
@property (strong, nonatomic) HXAlbumModel *albumModel;
@property (strong, nonatomic) HXPhotoBottomView *bottomView;
@property (strong, nonatomic) HXPhotoLimitView *limitView;
- (HXPhotoViewCell *)currentPreviewCell:(HXPhotoModel *)model;
- (BOOL)scrollToModel:(HXPhotoModel *)model;
- (void)scrollToPoint:(HXPhotoViewCell *)cell rect:(CGRect)rect;
- (void)startGetAllPhotoModel;
@end

@protocol HXPhotoViewCellDelegate <NSObject>
@optional
- (void)photoViewCell:(HXPhotoViewCell *)cell didSelectBtn:(UIButton *)selectBtn;
- (void)photoViewCellRequestICloudAssetComplete:(HXPhotoViewCell *)cell;
@end

@interface HXPhotoViewCell : UICollectionViewCell
@property (weak, nonatomic) id<HXPhotoViewCellDelegate> delegate;
@property (assign, nonatomic) NSInteger section;
@property (assign, nonatomic) NSInteger item;
@property (assign, nonatomic) BOOL canSelect;
@property (strong, nonatomic, readonly) UIImageView *imageView;
@property (strong, nonatomic) CALayer *selectMaskLayer;
@property (strong, nonatomic) HXPhotoModel *model;
@property (assign, nonatomic) BOOL singleSelected;
@property (strong, nonatomic) UIColor *selectBgColor;
@property (strong, nonatomic) UIColor *selectedTitleColor;
@property (strong, nonatomic) UIColor *darkSelectBgColor;
@property (strong, nonatomic) UIColor *darkSelectedTitleColor;
@property (strong, nonatomic, readonly) CALayer *videoMaskLayer;
@property (strong, nonatomic, readonly) UIButton *selectBtn;
- (void)resetNetworkImage;
- (void)cancelRequest;
- (void)startRequestICloudAsset;
- (void)bottomViewPrepareAnimation;
- (void)bottomViewStartAnimation;
- (void)setModel:(HXPhotoModel *)model emptyImage:(BOOL)emptyImage;
- (void)setModelDataWithHighQuality:(BOOL)highQuality completion:(void (^)(HXPhotoViewCell *myCell))completion;
@end

@interface HXPhotoCameraViewCell : UICollectionViewCell
@property (strong, nonatomic) HXPhotoModel *model;
@property (strong, nonatomic, readonly) HXCustomCameraController *cameraController;
@property (strong, nonatomic) UIImage *cameraImage;
@property (assign, nonatomic) BOOL cameraSelected;
@property (assign, nonatomic) BOOL startSession;
@property (strong, nonatomic) UIColor *bgColor;
- (void)starRunning;
- (void)stopRunning;
@end

@interface HXPhotoLimitViewCell : UICollectionViewCell
@property (strong, nonatomic) UIColor *bgColor;
@property (strong, nonatomic) UIColor *bgDarkColor;
@property (strong, nonatomic) UIColor *lineColor;
@property (strong, nonatomic) UIColor *lineDarkColor;
@property (strong, nonatomic) UIColor *textColor;
@property (strong, nonatomic) UIColor *textDarkColor;
@property (strong, nonatomic) UIFont *textFont;

- (void)config;
@end

@interface HXPhotoViewSectionFooterView : UICollectionReusableView
@property (assign, nonatomic) NSInteger photoCount;
@property (assign, nonatomic) NSInteger videoCount;
@property (strong, nonatomic) UIColor *bgColor;
@property (strong, nonatomic) UIColor *textColor;
@end

@protocol HXPhotoBottomViewDelegate <NSObject>
@optional
- (void)photoBottomViewDidPreviewBtn;
- (void)photoBottomViewDidDoneBtn;
- (void)photoBottomViewDidEditBtn;
@end

@interface HXPhotoBottomView : UIView
@property (weak, nonatomic) id<HXPhotoBottomViewDelegate> delegate;
@property (strong, nonatomic) HXPhotoManager *manager;
@property (assign, nonatomic) BOOL previewBtnEnabled;
@property (assign, nonatomic) BOOL doneBtnEnabled;
@property (assign, nonatomic) NSInteger selectCount;
@property (strong, nonatomic) UIButton *originalBtn;
@property (strong, nonatomic) UIToolbar *bgView;
- (void)requestPhotosBytes;
@end
