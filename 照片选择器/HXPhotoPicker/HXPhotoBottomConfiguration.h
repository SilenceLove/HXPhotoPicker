//
//  HXPhotoBottomConfiguration.h
//  照片选择器
//
//  Created by 洪欣 on 2019/10/30.
//  Copyright © 2019 洪欣. All rights reserved.
//

#import <UIKit/UIKit.h>

// 未完成

NS_ASSUME_NONNULL_BEGIN

/// 自定义照片列表底部视图配置类
@interface HXPhotoBottomConfiguration : NSObject

/// 底部视图，高度固定 50 + SafeBottom
/// 只要不为 nil 就代表有底部视图
@property (strong, nonatomic) UIView *bottomView;

/// 预览事件，点击预览时调用这个block
/// .previewAssetBlock()
@property (copy, nonatomic) void (^ previewAssetBlock)(void);

/// 预览按钮的状态，当状态改变时都会调用这个block
/// .previewButtonStatus = ^(BOOL enabled) {
///     在回调里改变预览按钮状态
/// }
@property (copy, nonatomic) void (^ previewButtonStatus)(BOOL enabled);

/// 编辑事件，点击编辑时调用这个block
/// .editAsseteBlock()
@property (copy, nonatomic) void (^ editAsseteBlock)(void);

/// 编辑按钮的状态，当状态改变时都会调用这个block
/// .editButtonStatus = ^(BOOL enabled) {
///     在回调里改变编辑按钮状态
/// }
@property (copy, nonatomic) void (^ editButtonStatus)(BOOL enabled);

/// 原图事件，点击原图按钮时调用这个block，传入是否选中状态
/// .clickOriginalBlock(YES) / .clickOriginalBlock(NO)
/// 照片原图大小调用 manager 的 requestPhotosBytesWithCompletion 这个方法获取
@property (copy, nonatomic) void (^ clickOriginalBlock)(BOOL isSelected);

/// 完成事件，点击完成按钮时调用这个block
/// .selectCompleteBlock()
@property (copy, nonatomic) void (^ selectCompleteBlock)(void);

/// 完成按钮的状态，当状态改变时都会调用这个block
/// .doneButtonStatus = ^(BOOL enabled, NSInteger total, NSInteger selectCount) {
///     在回调里改变完成按钮状态
///     enabled->按钮状态，total->总数，selectCount->已选数量
/// }
@property (copy, nonatomic) void (^ doneButtonStatus)(BOOL enabled, NSInteger total, NSInteger selectCount);

@end

NS_ASSUME_NONNULL_END
