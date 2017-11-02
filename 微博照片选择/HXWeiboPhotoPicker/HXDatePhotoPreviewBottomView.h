//
//  HXDatePhotoPreviewBottomView.h
//  微博照片选择
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
@end

@interface HXDatePhotoPreviewBottomView : UIView
@property (weak, nonatomic) id<HXDatePhotoPreviewBottomViewDelegate> delagate;
@property (strong, nonatomic) NSMutableArray *modelArray;
@property (assign, nonatomic) NSInteger selectCount;
@property (assign, nonatomic) NSInteger currentIndex;
- (void)insertModel:(HXPhotoModel *)model;
- (void)deleteModel:(HXPhotoModel *)model;
- (instancetype)initWithFrame:(CGRect)frame modelArray:(NSArray *)modelArray;
- (void)deselected;
- (void)deselectedWithIndex:(NSInteger)index;
@end


@interface HXDatePhotoPreviewBottomViewCell : UICollectionViewCell
@property (strong, nonatomic) HXPhotoModel *model;
- (void)cancelRequest;
@end
