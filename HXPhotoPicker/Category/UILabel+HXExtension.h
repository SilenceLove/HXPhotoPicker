//
//  UILabel+HXExtension.h
//  HXPhotoPickerExample
//
//  Created by Silence on 2018/12/28.
//  Copyright © 2018年 Silence. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UILabel (HXExtension)

/**
 获取文本内容的宽度，获取宽度前先给label高度

 @return 宽度
 */
- (CGFloat)hx_getTextWidth;

/**
 获取文本内容的高度，获取高度前先给label宽度
 
 @return 高度
 */
- (CGFloat)hx_getTextHeight;

+ (CGFloat)hx_getTextWidthWithText:(NSString *)text height:(CGFloat)height font:(UIFont *)font;
+ (CGFloat)hx_getTextWidthWithText:(NSString *)text height:(CGFloat)height fontSize:(CGFloat)fontSize;
+ (CGFloat)hx_getTextHeightWithText:(NSString *)text width:(CGFloat)width font:(UIFont *)font;
+ (CGFloat)hx_getTextHeightWithText:(NSString *)text width:(CGFloat)width fontSize:(CGFloat)fontSize;
@end

NS_ASSUME_NONNULL_END
