//
//  HXPhotoPreviewBottomView.h
//  HXPhotoPickerExample
//
//  Created by Silence on 2017/10/16.
//  Copyright © 2017年 Silence. All rights reserved.
//

#import <UIKit/UIKit.h>

@class HXPhotoModel, HXPhotoPreviewBottomView, HXPhotoManager;
@protocol HXPhotoPreviewBottomViewDelegate <NSObject>
@optional
- (void)photoPreviewBottomViewDidItem:(HXPhotoModel *)model currentIndex:(NSInteger)currentIndex beforeIndex:(NSInteger)beforeIndex;
- (void)photoPreviewBottomViewDidDone:(HXPhotoPreviewBottomView *)bottomView;
- (void)photoPreviewBottomViewDidEdit:(HXPhotoPreviewBottomView *)bottomView;
@end

@interface HXPhotoPreviewBottomView : UIView
@property (strong, nonatomic) UIToolbar *bgView;
@property (weak, nonatomic) id<HXPhotoPreviewBottomViewDelegate> delagate;
@property (strong, nonatomic) NSMutableArray *modelArray;
@property (assign, nonatomic) NSInteger selectCount;
@property (assign, nonatomic) NSInteger currentIndex;
@property (assign, nonatomic) BOOL hideEditBtn;
@property (assign, nonatomic) BOOL enabled;
@property (assign, nonatomic) BOOL outside;

@property (strong, nonatomic) UIToolbar *tipView;
@property (strong, nonatomic) UILabel *tipLb;
- (void)changeTipViewState:(HXPhotoModel *)model;
- (void)reloadData;
- (void)insertModel:(HXPhotoModel *)model;
- (void)deleteModel:(HXPhotoModel *)model;
- (instancetype)initWithFrame:(CGRect)frame modelArray:(NSArray *)modelArray manager:(HXPhotoManager *)manager;
- (void)deselected;
- (void)deselectedWithIndex:(NSInteger)index;
@end


@interface HXPhotoPreviewBottomViewCell : UICollectionViewCell
@property (strong, nonatomic) HXPhotoModel *model;
@property (strong, nonatomic) UIColor *selectColor;
- (void)cancelRequest;
@end
