//
//  HXPhotoBottomSelectView.h
//  照片选择器
//
//  Created by 洪欣 on 2019/9/30.
//  Copyright © 2019 洪欣. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface HXPhotoBottomSelectView : UIView

@property (copy, nonatomic) NSArray *titles;
@property (strong, nonatomic) UIView *headerView;
@property (copy, nonatomic) NSString *cancelTitle;
@property (copy, nonatomic) void (^ selectCompletion)(NSInteger index, NSString * _Nullable title);
@property (copy, nonatomic) void (^ cancelClick)(void);

/// 显示底部选择视频
/// @param titles 标题数组
/// @param cancelTitle 取消按钮标题
/// @param adaptiveDarkness 是否自适应暗黑风格
/// @param selectCompletion 选择完成
/// @param cancelClick 取消选择
+ (instancetype)showSelectViewWithTitles:(NSArray * _Nullable)titles cancelTitle:(NSString * _Nullable)cancelTitle adaptiveDarkness:(BOOL)adaptiveDarkness selectCompletion:(void (^)(NSInteger index, NSString *title))selectCompletion cancelClick:(void (^ _Nullable)(void))cancelClick;
+ (instancetype)showSelectViewWithTitles:(NSArray * _Nullable)titles headerView:(UIView *)headerView selectCompletion:(void (^)(NSInteger index, NSString *title))selectCompletion cancelClick:(void (^ _Nullable)(void))cancelClick;
- (void)showView;
- (void)hideView;

/// 重新计算视图高度
- (void)recalculateHeight;
@end

@interface HXPhotoBottomSelectViewCell : UITableViewCell
@property (assign, nonatomic) BOOL adaptiveDarkness;
@property (copy, nonatomic) NSString *title;
@end
NS_ASSUME_NONNULL_END
