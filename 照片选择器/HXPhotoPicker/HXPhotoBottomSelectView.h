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

/// 长按选中颜色
@property (strong, nonatomic) UIColor *selectColor;

/// 自定义属性
@property (strong, nonatomic) id customData;
@end

@interface HXPhotoBottomSelectView : UIView
@property (copy, nonatomic) NSArray *modelArray;
@property (copy, nonatomic) void (^ selectCompletion)(NSInteger index, HXPhotoBottomViewModel * _Nullable model);
@property (copy, nonatomic) void (^ cancelClick)(void);

/// 如果单独设置tableViewHeaderView，设置之后需要调用 recalculateHeight 方法重新计算高度
@property (strong, nonatomic) UIView *tableHeaderView;
/// 是否自适应暗黑模式
@property (assign, nonatomic) BOOL adaptiveDarkness;
/// 取消按钮的文字
@property (copy, nonatomic) NSString *cancelTitle;
/// 是否显示顶部横条视图，显示可拖动隐藏视图
@property (assign, nonatomic) BOOL showTopLineView;



/// 显示底部选择视图
/// @param models 模型数组
/// @param headerView tableViewHeaderView
/// @param showTopLineView 显示可拖动隐藏的视图
/// @param cancelTitle 取消按钮标题
/// @param selectCompletion 选择完成
/// @param cancelClick 取消选择
+ (instancetype)showSelectViewWithModels:(NSArray * _Nullable)models
                              headerView:(UIView * _Nullable)headerView
                         showTopLineView:(BOOL)showTopLineView
                             cancelTitle:(NSString * _Nullable)cancelTitle
                        selectCompletion:(void (^ _Nullable)(NSInteger index, HXPhotoBottomViewModel *model))selectCompletion
                             cancelClick:(void (^ _Nullable)(void))cancelClick;

+ (instancetype)showSelectViewWithModels:(NSArray * _Nullable)models
                              headerView:(UIView * _Nullable)headerView
                             cancelTitle:(NSString * _Nullable)cancelTitle
                        selectCompletion:(void (^ _Nullable)(NSInteger index, HXPhotoBottomViewModel *model))selectCompletion
                             cancelClick:(void (^ _Nullable)(void))cancelClick;

+ (instancetype)showSelectViewWithModels:(NSArray * _Nullable)models
                        selectCompletion:(void (^ _Nullable)(NSInteger index, HXPhotoBottomViewModel *model))selectCompletion
                             cancelClick:(void (^ _Nullable)(void))cancelClick;

/// 显示底部选择视图
/// @param titles 标题数组，标题颜色大小都是默认的
/// @param selectCompletion 选择完成
/// @param cancelClick 取消选择
+ (instancetype)showSelectViewWithTitles:(NSArray * _Nullable)titles
                        selectCompletion:(void (^ _Nullable)(NSInteger index, HXPhotoBottomViewModel *model))selectCompletion
                             cancelClick:(void (^ _Nullable)(void))cancelClick;

- (void)showView;
- (void)hideView;

/// 重新计算视图高度
- (void)recalculateHeight;
@end

@interface HXPhotoBottomSelectViewCell : UITableViewCell
@property (assign, nonatomic) BOOL adaptiveDarkness;
@property (strong, nonatomic) HXPhotoBottomViewModel *model;
@property (assign, nonatomic) BOOL showSelectBgView;
@property (copy, nonatomic) void (^ didCellBlock)(HXPhotoBottomSelectViewCell *myCell);
@end
NS_ASSUME_NONNULL_END
