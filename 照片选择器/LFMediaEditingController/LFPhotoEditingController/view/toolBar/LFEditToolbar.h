//
//  LFEditToolbar.h
//  LFImagePickerController
//
//  Created by LamTsanFeng on 2017/3/14.
//  Copyright © 2017年 LamTsanFeng. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSUInteger, LFEditToolbarType) {
    /** 绘画 */
    LFEditToolbarType_draw = 1 << 0,
    /** 贴图 */
    LFEditToolbarType_sticker = 1 << 1,
    /** 文本 */
    LFEditToolbarType_text = 1 << 2,
    /** 模糊 */
    LFEditToolbarType_splash = 1 << 3,
    /** 修剪 */
    LFEditToolbarType_crop = 1 << 4,
    /** 音频 */
    LFEditToolbarType_audio = 1 << 5,
    /** 剪辑 */
    LFEditToolbarType_clip = 1 << 6,
    /** 滤镜 */
    LFEditToolbarType_filter = 1 << 7,
    /** 所有 */
    LFEditToolbarType_All = ~0UL,
};

@protocol LFEditToolbarDelegate;

@interface LFEditToolbar : UIView

- (instancetype)initWithType:(LFEditToolbarType)type;

@property (nonatomic, weak) id<LFEditToolbarDelegate> delegate;

/** 当前激活主菜单 return -1 没有激活 */
- (NSUInteger)mainSelectAtIndex;

/** 允许撤销 */
- (void)setRevokeAtIndex:(NSUInteger)index;

/** 获取拾色器的颜色 */
- (NSArray <UIColor *>*)drawSliderColors;
- (UIColor *)drawSliderCurrentColor;
/** 设置绘画拾色器默认颜色 */
- (void)setDrawSliderColor:(UIColor *)color;
- (void)setDrawSliderColorAtIndex:(NSUInteger)index;

@end

@protocol LFEditToolbarDelegate <NSObject>


/**
 主菜单点击事件

 @param editToolbar self
 @param index 坐标（第几个按钮）
 */
- (void)lf_editToolbar:(LFEditToolbar *)editToolbar mainDidSelectAtIndex:(NSUInteger)index;
/** 二级菜单点击事件-撤销 */
- (void)lf_editToolbar:(LFEditToolbar *)editToolbar subDidRevokeAtIndex:(NSUInteger)index;
/** 二级菜单点击事件-按钮 */
- (void)lf_editToolbar:(LFEditToolbar *)editToolbar subDidSelectAtIndex:(NSIndexPath *)indexPath;
/** 撤销允许权限获取 */
- (BOOL)lf_editToolbar:(LFEditToolbar *)editToolbar canRevokeAtIndex:(NSUInteger)index;
/** 二级菜单滑动事件-绘画 */
- (void)lf_editToolbar:(LFEditToolbar *)editToolbar drawColorDidChange:(UIColor *)color;
@end
