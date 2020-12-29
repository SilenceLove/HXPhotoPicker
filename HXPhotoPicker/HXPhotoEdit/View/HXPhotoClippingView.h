//
//  HXPhotoClippingView.h
//  photoEditDemo
//
//  Created by Silence on 2020/6/29.
//  Copyright © 2020 Silence. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, HXPhotoClippingViewMirrorType) {
    HXPhotoClippingViewMirrorType_None = 0,     // 没有镜像翻转
    HXPhotoClippingViewMirrorType_Horizontal    // 水平翻转
};

@protocol HXPhotoClippingViewDelegate;
@class HXPhotoEditImageView, HXPhotoEditConfiguration;
@interface HXPhotoClippingView : UIScrollView
@property (nonatomic, strong, readonly) HXPhotoEditImageView *imageView;
@property (nonatomic, strong) UIImage *image;
/// 获取除图片以外的编辑图层
/// @param rect 大小
/// @param rotate 旋转角度
- (UIImage *)editOtherImagesInRect:(CGRect)rect rotate:(CGFloat)rotate;

@property (strong, nonatomic) HXPhotoEditConfiguration *configuration;

@property (nonatomic, weak) id<HXPhotoClippingViewDelegate> clippingDelegate;
/** 首次缩放后需要记录最小缩放值 */
@property (nonatomic, readonly) CGFloat first_minimumZoomScale;
/** 与父视图中心偏差坐标 */
@property (nonatomic, assign) CGPoint offsetSuperCenter;

/// 自定义固定比例
@property (assign, nonatomic) CGSize customRatioSize;
/** 是否重置中 */
@property (nonatomic, readonly) BOOL isReseting;
/** 是否旋转中 */
@property (nonatomic, readonly) BOOL isRotating;
/** 是否镜像翻转中 */
@property (nonatomic, assign) BOOL isMirrorFlip;
/** 是否水平翻转 */
@property (assign, nonatomic) HXPhotoClippingViewMirrorType mirrorType;
/** 旋转系数 */
@property (assign, nonatomic, readonly) NSInteger angle;
/** 是否缩放中 */
//@property (nonatomic, readonly) BOOL isZooming;
/** 是否可还原 */
@property (nonatomic, readonly) BOOL canReset;
/// 显示界面的缩放率
@property (nonatomic, assign) CGFloat screenScale;
/** 以某个位置作为可还原的参照物 */
- (BOOL)canResetWithRect:(CGRect)trueFrame;

/** 可编辑范围 */
@property (nonatomic, assign) CGRect editRect;
/** 剪切范围 */
@property (nonatomic, assign) CGRect cropRect;
/** 手势开关，一般编辑模式下开启 默认NO */
@property (nonatomic, assign) BOOL useGesture;

@property (nonatomic, assign) BOOL fixedAspectRatio;
- (void)zoomToRect:(CGRect)rect;
/** 缩小到指定坐标 */
- (void)zoomOutToRect:(CGRect)toRect;
/** 放大到指定坐标(必须大于当前坐标) */
- (void)zoomInToRect:(CGRect)toRect;
/** 旋转 */
- (void)rotateClockwise:(BOOL)clockwise;
/// 镜像翻转
- (void)mirrorFlip;
/** 还原 */
- (void)reset;
/** 还原到某个位置 */
- (void)resetToRect:(CGRect)rect;
/** 取消 */
- (void)cancel;
/** 数据 */
@property (nonatomic, strong, nullable) NSDictionary *photoEditData;
- (void)changeSubviewFrame;
- (void)resetRotateAngle;
- (void)clearCoverage;
@end

@protocol HXPhotoClippingViewDelegate <NSObject>

/** 同步缩放视图（调用zoomOutToRect才会触发） */
- (void (^ _Nullable)(CGRect))clippingViewWillBeginZooming:(HXPhotoClippingView *)clippingView;
- (void)clippingViewDidZoom:(HXPhotoClippingView *)clippingView;
- (void)clippingViewDidEndZooming:(HXPhotoClippingView *)clippingView;

/** 移动视图 */
- (void)clippingViewWillBeginDragging:(HXPhotoClippingView *)clippingView;
- (void)clippingViewDidEndDecelerating:(HXPhotoClippingView *)clippingView;

@end

NS_ASSUME_NONNULL_END
