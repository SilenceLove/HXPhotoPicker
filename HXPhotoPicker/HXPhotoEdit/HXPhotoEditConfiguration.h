//
//  HXPhotoEditConfiguration.h
//  photoEditDemo
//
//  Created by Silence on 2020/7/6.
//  Copyright © 2020 Silence. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "HXPhotoEditChartletModel.h"

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, HXPhotoEditAspectRatio) {
    HXPhotoEditAspectRatioType_None, // 不设置比例
    HXPhotoEditAspectRatioType_Original, // 原图比例
    HXPhotoEditAspectRatioType_1x1,
    HXPhotoEditAspectRatioType_3x2,
    HXPhotoEditAspectRatioType_4x3,
    HXPhotoEditAspectRatioType_5x3,
    HXPhotoEditAspectRatioType_15x9,
    HXPhotoEditAspectRatioType_16x9,
    HXPhotoEditAspectRatioType_16x10,
    HXPhotoEditAspectRatioType_Custom  // 自定义比例
};

@interface HXPhotoEditConfiguration : NSObject

/// 主题色
@property (strong, nonatomic) UIColor *themeColor;

/// 只要裁剪功能
@property (assign, nonatomic) BOOL onlyCliping;

/// 是否支持旋转
/// 旋转之后会重置编辑的内容
@property (assign, nonatomic) BOOL supportRotation;

#pragma mark - < 画笔相关 >
/// 画笔颜色数组
@property (copy, nonatomic) NSArray<UIColor *> *drawColors;

/// 默认选择的画笔颜色下标
/// 与 drawColors 对应，默认 2
@property (assign, nonatomic) NSInteger defaultDarwColorIndex;

/// 画笔默认宽度为最大宽度的50%
/// 画笔最大宽度
/// 默认 12.f
@property (assign, nonatomic) CGFloat brushLineMaxWidth;

/// 画笔最小宽度
/// 默认 2.f
@property (assign, nonatomic) CGFloat brushLineMinWidth;

#pragma mark - < 贴图相关 >
/// 贴图模型数组
@property (copy, nonatomic) NSArray<HXPhotoEditChartletTitleModel *> *chartletModels;

/// 请求获取贴图模型
/// block会在贴图列表弹出之后调用
/// 优先级高于 chartletModels
@property (copy, nonatomic) void (^ requestChartletModels)(void(^ chartletModels)(NSArray<HXPhotoEditChartletTitleModel *> *chartletModels));

#pragma mark - < 文字贴图相关 >
/// 文字颜色数组
@property (copy, nonatomic) NSArray<UIColor *> *textColors;
/// 文字字体
@property (strong, nonatomic) UIFont *textFont;
/// 最大文本长度限制
@property (assign, nonatomic) NSInteger maximumLimitTextLength;

#pragma mark - < 裁剪相关 >
/// 固定裁剪比例
@property (assign, nonatomic) HXPhotoEditAspectRatio aspectRatio;
/// 自定义固定比例
/// 设置自定义比例必须设置 aspectRatio = HXPhotoEditAspectRatioType_Custom，否则无效
@property (assign, nonatomic) CGSize customAspectRatio;

/// 圆形裁剪框，只要裁剪功能 并且 固定裁剪比例为 HXPhotoEditAspectRatioType_1x1 时有效
@property (assign, nonatomic) BOOL isRoundCliping;
@end

NS_ASSUME_NONNULL_END
