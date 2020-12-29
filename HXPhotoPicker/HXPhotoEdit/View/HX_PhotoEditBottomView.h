//
//  HX_PhotoEditBottomView.h
//  photoEditDemo
//
//  Created by Silence on 2020/6/20.
//  Copyright © 2020 Silence. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface HX_PhotoEditBottomView : UIView
/// 主题色
/// 默认微信主题色
@property (strong, nonatomic) UIColor *themeColor;
@property (copy, nonatomic) void (^ didToolsBtnBlock)(NSInteger tag, BOOL isSelected);
@property (copy, nonatomic) void (^ didDoneBtnBlock)(void);
+ (instancetype)initView;
- (void)endCliping;
@end

NS_ASSUME_NONNULL_END
