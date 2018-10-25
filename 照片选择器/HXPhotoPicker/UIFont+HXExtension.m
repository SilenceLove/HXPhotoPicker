//
//  UIFont+HXExtension.m
//  照片选择器
//
//  Created by 洪欣 on 2017/10/14.
//  Copyright © 2017年 洪欣. All rights reserved.
//

#import "UIFont+HXExtension.h"

@implementation UIFont (HXExtension)
+ (instancetype)hx_pingFangFontOfSize:(CGFloat)size {
    return [UIFont fontWithName:@"PingFang-SC-Regular" size:size];
}
+ (instancetype)hx_regularPingFangOfSize:(CGFloat)size {
    UIFont *font = [self fontWithName:@"PingFangSC-Regular" size:size];
    return font ? font : [UIFont systemFontOfSize:size];
}
+ (instancetype)hx_mediumPingFangOfSize:(CGFloat)size {
    UIFont *font = [self fontWithName:@"PingFangSC-Medium" size:size];
    return font ? font : [UIFont systemFontOfSize:size];
}
+ (instancetype)hx_boldPingFangOfSize:(CGFloat)size {
    UIFont *font = [self fontWithName:@"PingFangSC-Semibold" size:size];
    return font ? font : [UIFont systemFontOfSize:size];
}
+ (instancetype)hx_helveticaNeueOfSize:(CGFloat)size {
    UIFont *font = [self fontWithName:@"HelveticaNeue" size:size];
    return font ? font : [UIFont systemFontOfSize:size];
}

@end
