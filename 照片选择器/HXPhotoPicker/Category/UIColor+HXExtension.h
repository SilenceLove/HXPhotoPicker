//
//  UIColor+HXExtension.h
//  照片选择器
//
//  Created by 洪欣 on 2019/12/3.
//  Copyright © 2019 洪欣. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIColor (HXExtension)
+ (UIColor *)hx_colorWithHexStr:(NSString *)string;
+ (UIColor *)hx_colorWithHexStr:(NSString *)string alpha:(CGFloat)alpha;
+ (UIColor *)hx_colorWithR:(CGFloat)red g:(CGFloat)green b:(CGFloat)blue a:(CGFloat)alpha;
+ (NSString *)hx_hexStringWithColor:(UIColor *)color;
@end

NS_ASSUME_NONNULL_END
