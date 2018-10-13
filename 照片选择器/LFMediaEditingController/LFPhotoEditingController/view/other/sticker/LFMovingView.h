//
//  LFMovingView.h
//  LFImagePickerController
//
//  Created by LamTsanFeng on 2017/2/24.
//  Copyright © 2017年 LamTsanFeng. All rights reserved.
//

#import <UIKit/UIKit.h>
typedef NS_ENUM(NSUInteger, LFMovingViewType) {
    LFMovingViewType_unknown,
    LFMovingViewType_imageView,
    LFMovingViewType_label,
};

@interface LFMovingView : UIView

/** 激活 */
+ (void)setActiveEmoticonView:(LFMovingView *)view;

/** 初始化 */
- (instancetype)initWithView:(UIView *)view type:(LFMovingViewType)type;

/** 更新坐标 */
- (void)updateFrameWithViewSize:(CGSize)viewSize;

/** 缩放率 0.2~3.0 */
- (void)setScale:(CGFloat)scale;
- (void)setScale:(CGFloat)scale rotation:(CGFloat)rotation;

/** 最小缩放率 默认0.2 */
@property (nonatomic, assign) CGFloat minScale;
/** 最大缩放率 默认3.0 */
@property (nonatomic, assign) CGFloat maxScale;

@property (nonatomic, readonly) UIView *view;
@property (nonatomic, readonly) LFMovingViewType type;
@property (nonatomic, readonly) CGFloat scale;
@property (nonatomic, readonly) CGFloat rotation;


@property (nonatomic, copy) void(^tapEnded)(LFMovingView *movingView, UIView *view, BOOL isActive);
@property (nonatomic, copy) BOOL(^moveCenter)(CGRect rect);

@end
