//
//  HXDatePhotoViewController.h
//  微博照片选择
//
//  Created by 洪欣 on 2017/10/14.
//  Copyright © 2017年 洪欣. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "HXPhotoManager.h"
#import "HXCustomCollectionReusableView.h"

@class HXDatePhotoViewController,HXDatePhotoViewCell,HXDatePhotoBottomView,HXCustomCameraController;
@protocol HXDatePhotoViewControllerDelegate <NSObject>
@optional
- (void)datePhotoViewControllerDidCancel:(HXDatePhotoViewController *)datePhotoViewController;
- (void)datePhotoViewController:(HXDatePhotoViewController *)datePhotoViewController didDoneAllList:(NSArray<HXPhotoModel *> *)allList photos:(NSArray<HXPhotoModel *> *)photoList videos:(NSArray<HXPhotoModel *> *)videoList original:(BOOL)original;
- (void)datePhotoViewControllerDidChangeSelect:(HXPhotoModel *)model selected:(BOOL)selected;
@end

@interface HXDatePhotoViewController : UIViewController
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
- (void)cancelRequest;
- (void)startRequestICloudAsset;
@end

@interface HXDatePhotoCameraViewCell : UICollectionViewCell
@property (strong, nonatomic) HXPhotoModel *model;
@property (strong, nonatomic, readonly) HXCustomCameraController *cameraController;
- (void)starRunning;
- (void)stopRunning;
@end

@interface HXDatePhotoViewSectionHeaderView : HXCustomCollectionReusableView
@property (strong, nonatomic) HXPhotoDateModel *model;
@property (assign, nonatomic) BOOL changeState; 
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
@end
