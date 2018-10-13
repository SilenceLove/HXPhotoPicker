//
//  NSString+LFCoreTextSize.h
//  DrawCoreText
//
//  Created by LamTsanFeng on 16/9/19.
//  Copyright © 2016年 LamTsamFeng. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface NSString (LFMECoreText)
/**
 *  @author lincf, 16-09-19 11:09:35
 *
 *  计算文字大小
 *
 *  @param width 文字最大长度
 *  @param font1 字体
 *
 *  @return 文字大小
 */
- (CGSize)LFME_sizeWithConstrainedToWidth:(float)width fromFont:(UIFont *)font1;

/**
 *  @author lincf, 16-09-19 11:09:24
 *
 *  计算文字大小
 *
 *  @param width         文字最大长度
 *  @param font1         字体
 *  @param lineBreakMode 行模式
 *
 *  @return 文字大小
 */
- (CGSize)LFME_sizeWithConstrainedToWidth:(float)width fromFont:(UIFont *)font1 lineBreakMode:(CTLineBreakMode)lineBreakMode;

/**
 *  @author lincf, 16-09-19 11:09:24
 *
 *  计算文字大小
 *
 *  @param width         文字最大长度
 *  @param font1         字体
 *  @param lineSpace     行距
 *  @param lineBreakMode 行模式
 *
 *  @return 文字大小
 */
- (CGSize)LFME_sizeWithConstrainedToWidth:(float)width fromFont:(UIFont *)font1 lineSpace:(float)lineSpace lineBreakMode:(CTLineBreakMode)lineBreakMode;

/**
 *  @author lincf, 16-09-19 11:09:24
 *
 *  计算文字大小
 *
 *  @param size          最大范围 文字长度、文字高度
 *  @param font1         字体
 *  @param lineSpace     行距
 *  @param lineBreakMode 行模式
 *
 *  @return 文字大小
 */
- (CGSize)LFME_sizeWithConstrainedToSize:(CGSize)size fromFont:(UIFont *)font1 lineSpace:(float)lineSpace lineBreakMode:(CTLineBreakMode)lineBreakMode;


/**
 *  @author lincf, 16-09-19 17:09:20
 *
 *  绘制文字
 *
 *  @param context       画布
 *  @param p             坐标
 *  @param font          字体
 *  @param color         颜色
 *  @param height        高度
 *  @param width         宽度
 *  @param linespace     行间距
 *  @param lineBreakMode 行模式
 */
- (void)LFME_drawInContext:(CGContextRef)context withPosition:(CGPoint)p andFont:(UIFont *)font andTextColor:(UIColor *)color andHeight:(float)height andWidth:(float)width linespace:(float)linespace lineBreakMode:(CTLineBreakMode)lineBreakMode;

@end
