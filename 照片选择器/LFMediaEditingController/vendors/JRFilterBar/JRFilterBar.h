//
//  JRStrainImageShowView.h
//  JRCollectionView
//
//  Created by Mr.D on 2018/8/2.
//  Copyright © 2018年 Mr.D. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LFColorMatrixType.h"

@protocol JRFilterBarDelegate;

@interface JRFilterBar : UIView
/** 初始化图片 */
@property (nonatomic, readonly) UIImage *defaultImg;
/** 默认选择图片类型 */
@property (nonatomic, readonly) LFColorMatrixType defalutEffectType;
/** 默认字体和框框颜色 */
@property (nonatomic, strong) UIColor *defaultColor;
/** 已选字体和框框颜色 */
@property (nonatomic, strong) UIColor *selectColor;

@property (nonatomic, weak) id<JRFilterBarDelegate> delegate;

- (instancetype)initWithFrame:(CGRect)frame defaultImg:(UIImage *)defaultImg defalutEffectType:(LFColorMatrixType)defalutEffectType colorNum:(NSUInteger)colorNum;


@end

@protocol JRFilterBarDelegate <NSObject>

- (void)jr_filterBar:(JRFilterBar *)jr_filterBar didSelectImage:(UIImage *)image effectType:(LFColorMatrixType)effectType;

@end
