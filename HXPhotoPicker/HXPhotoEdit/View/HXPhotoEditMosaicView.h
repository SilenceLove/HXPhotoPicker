//
//  HXPhotoEditMosaicView.h
//  photoEditDemo
//
//  Created by Silence on 2020/6/22.
//  Copyright © 2020 Silence. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface HXPhotoEditMosaicView : UIView
/// 主题色
/// 默认微信主题色
@property (strong, nonatomic) UIColor *themeColor;
@property (copy, nonatomic) void (^ didBtnBlock)(NSInteger tag);
@property (copy, nonatomic) void (^ undoBlock)(void);
@property (assign, nonatomic) BOOL undo;
+ (instancetype)initView;
@end

NS_ASSUME_NONNULL_END
