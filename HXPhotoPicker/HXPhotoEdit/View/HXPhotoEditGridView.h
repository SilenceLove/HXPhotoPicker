//
//  HXPhotoEditGridView.h
//  photoEditDemo
//
//  Created by Silence on 2020/6/29.
//  Copyright © 2020 Silence. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "HXPhotoEditGridLayer.h"
#import "HXPhotoEditGridMaskLayer.h"

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, HXPhotoEditGridViewAspectRatioType) {
    HXPhotoEditGridViewAspectRatioType_None, // 不设置比例
    HXPhotoEditGridViewAspectRatioType_Original, // 原图比例
    HXPhotoEditGridViewAspectRatioType_1x1,
    HXPhotoEditGridViewAspectRatioType_3x2,
    HXPhotoEditGridViewAspectRatioType_4x3,
    HXPhotoEditGridViewAspectRatioType_5x3,
    HXPhotoEditGridViewAspectRatioType_15x9,
    HXPhotoEditGridViewAspectRatioType_16x9,
    HXPhotoEditGridViewAspectRatioType_16x10,
    HXPhotoEditGridViewAspectRatioType_Custom
};
@protocol HXPhotoEditGridViewDelegate;
@interface HXPhotoEditGridView : UIView
@property (nonatomic, assign) CGRect gridRect;
@property (nonatomic, weak, readonly) HXPhotoEditGridMaskLayer *gridMaskLayer;
- (void)setGridRect:(CGRect)gridRect animated:(BOOL)animated;
- (void)setGridRect:(CGRect)gridRect maskLayer:(BOOL)isMaskLayer animated:(BOOL)animated;
- (void)setGridRect:(CGRect)gridRect maskLayer:(BOOL)isMaskLayer animated:(BOOL)animated completion:(void (^ _Nullable)(BOOL finished))completion;
/** 最小尺寸 CGSizeMake(80, 80); */
@property (nonatomic, assign) CGSize controlMinSize;
/** 最大尺寸 CGRectInset(self.bounds, 20, 20) */
@property (nonatomic, assign) CGRect controlMaxRect;
/** 原图尺寸 */
@property (nonatomic, assign) CGSize controlSize;

/** 显示遮罩层（触发拖动条件必须设置为YES）default is YES */
@property (nonatomic, assign) BOOL showMaskLayer;

/** 是否正在拖动 */
@property(nonatomic,readonly,getter=isDragging) BOOL dragging;

/** 比例是否水平翻转 */
@property (nonatomic, assign) BOOL aspectRatioHorizontally;
/** 设置固定比例 */
@property (nonatomic, assign) HXPhotoEditGridViewAspectRatioType aspectRatio;
/// 自定义固定比例
@property (assign, nonatomic) CGSize customRatioSize;
- (void)setAspectRatio:(HXPhotoEditGridViewAspectRatioType)aspectRatio animated:(BOOL)animated;

- (void)setupAspectRatio:(HXPhotoEditGridViewAspectRatioType)aspectRatio;

@property (nonatomic, weak) id<HXPhotoEditGridViewDelegate> delegate;
/** 遮罩颜色 */
@property (nonatomic, assign) CGColorRef maskColor;
@property (nonatomic, weak, readonly) HXPhotoEditGridLayer *gridLayer;

@property (nonatomic, assign) BOOL isRound;
/** 长宽比例描述 */
- (NSArray <NSString *>*)aspectRatioDescs;

- (void)setAspectRatioWithoutDelegate:(HXPhotoEditGridViewAspectRatioType)aspectRatio;;

- (void)changeSubviewFrame:(CGRect)frame;
@end

@protocol HXPhotoEditGridViewDelegate <NSObject>

- (void)gridViewDidBeginResizing:(HXPhotoEditGridView *)gridView;
- (void)gridViewDidResizing:(HXPhotoEditGridView *)gridView;
- (void)gridViewDidEndResizing:(HXPhotoEditGridView *)gridView;

/** 调整长宽比例 */
- (void)gridViewDidAspectRatio:(HXPhotoEditGridView *)gridView;
@end

NS_ASSUME_NONNULL_END
