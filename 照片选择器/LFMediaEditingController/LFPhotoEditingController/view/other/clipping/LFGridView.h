//
//  LFGridView.h
//  ClippingText
//
//  Created by LamTsanFeng on 2017/3/7.
//  Copyright © 2017年 LamTsanFeng. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSUInteger, LFGridViewAspectRatioType) {
    LFGridViewAspectRatioType_None,
    LFGridViewAspectRatioType_Original,
    LFGridViewAspectRatioType_1x1,
    LFGridViewAspectRatioType_3x2,
    LFGridViewAspectRatioType_4x3,
    LFGridViewAspectRatioType_5x3,
    LFGridViewAspectRatioType_15x9,
    LFGridViewAspectRatioType_16x9,
    LFGridViewAspectRatioType_16x10,
};

@protocol LFGridViewDelegate;
@interface LFGridView : UIView

@property (nonatomic, assign) CGRect gridRect;
- (void)setGridRect:(CGRect)gridRect animated:(BOOL)animated;
- (void)setGridRect:(CGRect)gridRect maskLayer:(BOOL)isMaskLayer animated:(BOOL)animated;
/** 最小尺寸 CGSizeMake(80, 80); */
@property (nonatomic, assign) CGSize controlMinSize;
/** 最大尺寸 CGRectInset(self.bounds, 50, 50) */
@property (nonatomic, assign) CGRect controlMaxRect;
/** 原图尺寸 */
@property (nonatomic, assign) CGSize controlSize;

/** 显示遮罩层（触发拖动条件必须设置为YES）default is YES */
@property (nonatomic, assign) BOOL showMaskLayer;

/** 是否正在拖动 */
@property(nonatomic,readonly,getter=isDragging) BOOL dragging;

/** 设置固定比例 */
@property (nonatomic, assign) LFGridViewAspectRatioType aspectRatio;

@property (nonatomic, weak) id<LFGridViewDelegate> delegate;

/** 长宽比例描述 */
- (NSArray <NSString *>*)aspectRatioDescs:(BOOL)horizontally;

@end

@protocol LFGridViewDelegate <NSObject>

- (void)lf_gridViewDidBeginResizing:(LFGridView *)gridView;
- (void)lf_gridViewDidResizing:(LFGridView *)gridView;
- (void)lf_gridViewDidEndResizing:(LFGridView *)gridView;

/** 调整长宽比例 */
- (void)lf_gridViewDidAspectRatio:(LFGridView *)gridView;
@end
