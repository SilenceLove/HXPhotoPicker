//
//  LFClippingView.h
//  LFImagePickerController
//
//  Created by LamTsanFeng on 2017/3/13.
//  Copyright © 2017年 LamTsanFeng. All rights reserved.
//

#import "LFScrollView.h"
#import "LFEditingProtocol.h"

@protocol LFClippingViewDelegate;

@interface LFClippingView : LFScrollView <LFEditingProtocol>

@property (nonatomic, strong) UIImage *image;

@property (nonatomic, assign, getter=isImageViewHidden) BOOL imageViewHidden;

@property (nonatomic, weak) id<LFClippingViewDelegate> clippingDelegate;
/** 首次缩放后需要记录最小缩放值 */
@property (nonatomic, readonly) CGFloat first_minimumZoomScale;

/** 原始坐标 */
@property (nonatomic, readonly) CGRect originalRect;
/** 开始的基础坐标 */
@property (nonatomic, readonly) CGRect normalRect;

/** 是否重置中 */
@property (nonatomic, readonly) BOOL isReseting;
/** 是否旋转中 */
@property (nonatomic, readonly) BOOL isRotating;
/** 是否缩放中 */
//@property (nonatomic, readonly) BOOL isZooming;
/** 是否可还原 */
@property (nonatomic, readonly) BOOL canReset;

/** 可编辑范围 */
@property (nonatomic, assign) CGRect editRect;
/** 剪切范围 */
@property (nonatomic, assign) CGRect cropRect;

/** 缩小到指定坐标 */
- (void)zoomOutToRect:(CGRect)toRect;
/** 放大到指定坐标(必须大于当前坐标) */
- (void)zoomInToRect:(CGRect)toRect;
/** 旋转 */
- (void)rotateClockwise:(BOOL)clockwise;
/** 还原 */
- (void)reset;
/** 取消 */
- (void)cancel;

@end

@protocol LFClippingViewDelegate <NSObject>

/** 同步缩放视图（调用zoomOutToRect才会触发） */
- (void (^)(CGRect))lf_clippingViewWillBeginZooming:(LFClippingView *)clippingView;
- (void)lf_clippingViewDidZoom:(LFClippingView *)clippingView;
- (void)lf_clippingViewDidEndZooming:(LFClippingView *)clippingView;

/** 移动视图 */
- (void)lf_clippingViewWillBeginDragging:(LFClippingView *)clippingView;
- (void)lf_clippingViewDidEndDecelerating:(LFClippingView *)clippingView;


@end
