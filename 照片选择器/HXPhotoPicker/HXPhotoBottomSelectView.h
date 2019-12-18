//
//  HXPhotoBottomSelectView.h
//  照片选择器
//
//  Created by 洪欣 on 2019/9/30.
//  Copyright © 2019 洪欣. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface HXPhotoBottomViewModel : NSObject

/// 标题内容
@property (copy, nonatomic) NSString *title;

/// 标题字体
@property (strong, nonatomic) UIFont *titleFont;

/// 标题字体颜色
@property (strong, nonatomic) UIColor *titleColor;

/// 子标题内容
@property (copy, nonatomic) NSString *subTitle;

/// 子标题字体
@property (strong, nonatomic) UIFont *subTitleFont;

/// 子标题颜色
@property (strong, nonatomic) UIColor *subTitleColor;

/// 背景颜色
@property (strong, nonatomic) UIColor *backgroundColor;

/// 底部线颜色
@property (strong, nonatomic) UIColor *lineColor;

/// 选中颜色
@property (strong, nonatomic) UIColor *selectColor;

/// 自定义属性
@property (strong, nonatomic) id customData;
@end

@interface HXPhotoBottomSelectView : UIView
@property (copy, nonatomic) NSArray *modelArray;
@property (strong, nonatomic) UIView *tableHeaderView;
@property (assign, nonatomic) BOOL adaptiveDarkness;
@property (copy, nonatomic) NSString *cancelTitle;
@property (copy, nonatomic) void (^ selectCompletion)(NSInteger index, HXPhotoBottomSelectView * _Nullable model);
@property (copy, nonatomic) void (^ cancelClick)(void);


/// 显示底部选择视图
/// @param models 模型数组
/// @param headerView headerView
/// @param cancelTitle 取消按钮标题
/// @param selectCompletion 选择完成
/// @param cancelClick 取消选择
+ (instancetype)showSelectViewWithModels:(NSArray * _Nullable)models
                              headerView:(UIView * _Nullable)headerView
                             cancelTitle:(NSString * _Nullable)cancelTitle
                        selectCompletion:(void (^ _Nullable)(NSInteger index, HXPhotoBottomSelectView *model))selectCompletion
                             cancelClick:(void (^ _Nullable)(void))cancelClick;

- (void)showView;
- (void)hideView;

/// 重新计算视图高度
- (void)recalculateHeight;
@end

@interface HXPhotoBottomSelectViewCell : UITableViewCell
@property (assign, nonatomic) BOOL adaptiveDarkness;
@property (strong, nonatomic) HXPhotoBottomViewModel *model;
@end
NS_ASSUME_NONNULL_END
