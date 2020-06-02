//
//  HXPhotoPreviewBottomConfiguration.h
//  照片选择器
//
//  Created by 洪欣 on 2019/10/30.
//  Copyright © 2019 洪欣. All rights reserved.
//

#import <UIKit/UIKit.h>

// 未完成

NS_ASSUME_NONNULL_BEGIN

/// 自定义照片预览界面底部视图配置类
@interface HXPhotoPreviewBottomConfiguration : NSObject

/// 底部视图，高度固定 50 + SafeBottom
/// 只要不为 nil 就代表有底部视图
@property (strong, nonatomic) UIView *bottomView;

/// 编辑事件，点击编辑时调用这个block
/// .editAsseteBlock()
@property (copy, nonatomic) void (^ editAsseteBlock)(void);

/// 编辑按钮的状态，当状态改变时都会调用这个block
/// .editButtonStatus = ^(BOOL enabled) {
///     在回调里改变编辑按钮状态
/// }
@property (copy, nonatomic) void (^ editButtonStatus)(BOOL enabled);

@end

NS_ASSUME_NONNULL_END
