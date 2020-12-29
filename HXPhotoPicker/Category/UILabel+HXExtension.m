//
//  UILabel+HXExtension.m
//  HXPhotoPickerExample
//
//  Created by Silence on 2018/12/28.
//  Copyright © 2018年 Silence. All rights reserved.
//

#import "UILabel+HXExtension.h"
#import "UIView+HXExtension.h"

@implementation UILabel (HXExtension)
- (CGFloat)hx_getTextWidth {
    return [UILabel hx_getTextWidthWithText:self.text height:self.hx_h font:self.font];
}
- (CGFloat)hx_getTextHeight {
    return [UILabel hx_getTextHeightWithText:self.text width:self.hx_w font:self.font];
}
+ (CGFloat)hx_getTextWidthWithText:(NSString *)text height:(CGFloat)height font:(UIFont *)font {
    CGSize newSize = [text boundingRectWithSize:CGSizeMake(MAXFLOAT, height) options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName:font} context:nil].size;
    return newSize.width;
}
+ (CGFloat)hx_getTextWidthWithText:(NSString *)text height:(CGFloat)height fontSize:(CGFloat)fontSize {
    return [UILabel hx_getTextWidthWithText:text height:height font:[UIFont systemFontOfSize:fontSize]];
}

+ (CGFloat)hx_getTextHeightWithText:(NSString *)text width:(CGFloat)width font:(UIFont *)font {
    CGSize newSize = [text boundingRectWithSize:CGSizeMake(width, MAXFLOAT) options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName:font} context:nil].size;
    return newSize.height;
}
+ (CGFloat)hx_getTextHeightWithText:(NSString *)text width:(CGFloat)width fontSize:(CGFloat)fontSize  {
    return [UILabel hx_getTextHeightWithText:text width:width font:[UIFont systemFontOfSize:fontSize]];
}
@end
