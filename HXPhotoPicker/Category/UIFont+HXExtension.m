//
//  UIFont+HXExtension.m
//  HXPhotoPickerExample
//
//  Created by Silence on 2017/10/14.
//  Copyright © 2017年 Silence. All rights reserved.
//

#import "UIFont+HXExtension.h"

@implementation UIFont (HXExtension)
+ (instancetype)hx_pingFangFontOfSize:(CGFloat)size {
    UIFont *font = [self fontWithName:@"PingFangSC-Regular" size:size];
    return font ? font : [UIFont systemFontOfSize:size];
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
+ (instancetype)hx_mediumHelveticaNeueOfSize:(CGFloat)size {
    UIFont *font = [self fontWithName:@"HelveticaNeue-Medium" size:size];
    return font ? font : [UIFont systemFontOfSize:size];
}
+ (instancetype)hx_mediumSFUITextOfSize:(CGFloat)size {
    return [self hx_mediumPingFangOfSize:size];
//    UIFont *font = [self fontWithName:@".SFUIText-Medium" size:size];
//    return font ? font : [UIFont systemFontOfSize:size];
}

@end
