//
//  HXPhotoEditingView.h
//  photoEditDemo
//
//  Created by Silence on 2020/6/29.
//  Copyright © 2020 Silence. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class HXPhotoEditingView, HXPhotoClippingView, HXPhotoEditConfiguration;
@protocol HXPhotoEditingViewDelegate <NSObject>
/// 开始编辑目标
- (void)editingViewWillBeginEditing:(HXPhotoEditingView *)EditingView;
/// 停止编辑目标
- (void)editingViewDidEndEditing:(HXPhotoEditingView *)EditingView;

@optional
/// 即将进入剪切界面
- (void)editingViewWillAppearClip:(HXPhotoEditingView *)EditingView;
/// 进入剪切界面
- (void)editingViewDidAppearClip:(HXPhotoEditingView *)EditingView;
/// 即将离开剪切界面
- (void)editingViewWillDisappearClip:(HXPhotoEditingView *)EditingView;
/// 离开剪切界面
- (void)editingViewDidDisappearClip:(HXPhotoEditingView *)EditingView;

- (void)editingViewViewDidEndZooming:(HXPhotoEditingView *)editingView;
@end

@interface HXPhotoEditingView : UIScrollView

@property (nonatomic, weak, readonly) HXPhotoClippingView *clippingView;
@property (nonatomic, weak, readonly) UIView *clipZoomView;
@property (nonatomic, strong) UIImage *image;
@property (nonatomic, weak) id<HXPhotoEditingViewDelegate> clippingDelegate;
@property (strong, nonatomic) HXPhotoEditConfiguration *configuration;

/** 最小尺寸 CGSizeMake(80, 80) */
@property (nonatomic, assign) CGSize clippingMinSize;
/** 最大尺寸 CGRectInset(self.bounds , 20, 20) */
@property (nonatomic, assign) CGRect clippingMaxRect;
/// 启用绘画功能
@property (nonatomic, assign) BOOL drawEnable;
/// 启用模糊功能
@property (nonatomic, assign) BOOL splashEnable;
/// 启用贴图
@property (nonatomic, readonly) BOOL stickerEnable;

@property (assign, nonatomic) CGFloat drawLineWidth;

/// 开启编辑模式
@property (nonatomic, assign, getter=isClipping) BOOL clipping;
- (void)setClipping:(BOOL)clipping animated:(BOOL)animated;
- (void)setClipping:(BOOL)clipping animated:(BOOL)animated completion:(void (^ _Nullable)(void))completion;
/// 取消裁剪
/// @param animated 是否需要动画
- (void)cancelClipping:(BOOL)animated;
/// 还原
- (void)reset;
- (BOOL)canReset;
/// 旋转
- (void)rotate;
/// 镜像翻转
- (void)mirrorFlip;
/// 默认长宽比例
@property (nonatomic, assign) NSUInteger defaultAspectRatioIndex;
/// 固定长宽比例
@property (nonatomic, assign) BOOL fixedAspectRatio;
/// 自定义固定比例
@property (assign, nonatomic) CGSize customRatioSize;
/// 只要裁剪
@property (assign, nonatomic) BOOL onlyCliping;

/// 长宽比例
- (NSArray <NSString *>*)aspectRatioDescs;
- (void)setAspectRatioIndex:(NSUInteger)aspectRatioIndex;- (void)setAspectRatioIndex:(NSUInteger)aspectRatioIndex animated:(BOOL)animated;
- (NSUInteger)aspectRatioIndex;

- (void)resetToRridRectWithAspectRatioIndex:(NSInteger)aspectRatioIndex;

- (void)photoEditEnable:(BOOL)enable;

/// 创建编辑图片
- (void)createEditImage:(void (^)(UIImage *editImage))complete;
@property (nonatomic, strong, nullable) NSDictionary *photoEditData;

- (void)resetRotateAngle;
- (void)changeSubviewFrame;
- (void)clearCoverage;
@end

NS_ASSUME_NONNULL_END
