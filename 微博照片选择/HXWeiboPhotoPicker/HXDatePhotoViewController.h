//
//  HXDatePhotoViewController.h
//  微博照片选择
//
//  Created by 洪欣 on 2017/10/14.
//  Copyright © 2017年 洪欣. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "HXPhotoManager.h"

@class HXDatePhotoViewController,HXDatePhotoViewCell,HXDatePhotoBottomView;
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
@end

@interface HXDatePhotoViewCell : UICollectionViewCell
@property (weak, nonatomic) id<HXDatePhotoViewCellDelegate> delegate;
@property (assign, nonatomic) NSInteger section;
@property (assign, nonatomic) NSInteger item;
@property (strong, nonatomic, readonly) UIImageView *imageView;
@property (strong, nonatomic) CALayer *selectMaskLayer;
@property (strong, nonatomic) HXPhotoModel *model;
- (void)cancelRequest;
@end

@interface HXDatePhotoCameraViewCell : UICollectionViewCell
@property (strong, nonatomic) HXPhotoModel *model;
@end

@interface HXDatePhotoViewSectionHeaderView : UICollectionReusableView
@property (strong, nonatomic) HXPhotoDateModel *model;
@end

@interface HXDatePhotoViewSectionFooterView : UICollectionReusableView
@property (assign, nonatomic) NSInteger photoCount;
@property (assign, nonatomic) NSInteger videoCount;
@end

@protocol HXDatePhotoBottomViewDelegate <NSObject>
@optional
- (void)datePhotoBottomViewDidPreviewBtn;
- (void)datePhotoBottomViewDidDoneBtn;
@end

@interface HXDatePhotoBottomView : UIView
@property (weak, nonatomic) id<HXDatePhotoBottomViewDelegate> delegate;
@property (strong, nonatomic) HXPhotoManager *manager;
@property (assign, nonatomic) BOOL previewBtnEnabled;
@property (assign, nonatomic) BOOL doneBtnEnabled;
@property (assign, nonatomic) NSInteger selectCount;
@end
