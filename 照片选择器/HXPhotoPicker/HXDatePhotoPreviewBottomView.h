//
//  HXDatePhotoPreviewBottomView.h
//  照片选择器
//
//  Created by 洪欣 on 2017/10/16.
//  Copyright © 2017年 洪欣. All rights reserved.
//

#import <UIKit/UIKit.h>

@class HXPhotoModel, HXDatePhotoPreviewBottomView, HXPhotoManager;
@protocol HXDatePhotoPreviewBottomViewDelegate <NSObject>
@optional
- (void)datePhotoPreviewBottomViewDidItem:(HXPhotoModel *)model currentIndex:(NSInteger)currentIndex beforeIndex:(NSInteger)beforeIndex;
- (void)datePhotoPreviewBottomViewDidDone:(HXDatePhotoPreviewBottomView *)bottomView;
- (void)datePhotoPreviewBottomViewDidEdit:(HXDatePhotoPreviewBottomView *)bottomView;
@end

@interface HXDatePhotoPreviewBottomView : UIView
@property (strong, nonatomic) UIToolbar *bgView;
@property (weak, nonatomic) id<HXDatePhotoPreviewBottomViewDelegate> delagate;
@property (strong, nonatomic) NSMutableArray *modelArray;
@property (assign, nonatomic) NSInteger selectCount;
@property (assign, nonatomic) NSInteger currentIndex;
@property (assign, nonatomic) BOOL hideEditBtn;
@property (assign, nonatomic) BOOL enabled;
@property (assign, nonatomic) BOOL outside;

@property (strong, nonatomic) UIToolbar *tipView;
@property (strong, nonatomic) UILabel *tipLb;
@property (assign, nonatomic) BOOL showTipView;
@property (copy, nonatomic) NSString *tipStr;

- (void)insertModel:(HXPhotoModel *)model;
- (void)deleteModel:(HXPhotoModel *)model;
- (instancetype)initWithFrame:(CGRect)frame modelArray:(NSArray *)modelArray manager:(HXPhotoManager *)manager;
- (void)deselected;
- (void)deselectedWithIndex:(NSInteger)index;
@end


@interface HXDatePhotoPreviewBottomViewCell : UICollectionViewCell
@property (strong, nonatomic) HXPhotoModel *model;
@property (strong, nonatomic) UIColor *selectColor;
- (void)cancelRequest;
@end
