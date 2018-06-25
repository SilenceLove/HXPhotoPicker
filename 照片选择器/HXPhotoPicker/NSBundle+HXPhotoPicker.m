//
//  NSBundle+HXPhotopicker.m
//  照片选择器
//
//  Created by 洪欣 on 2017/7/25.
//  Copyright © 2017年 洪欣. All rights reserved.
//

#import "NSBundle+HXPhotoPicker.h"

@implementation NSBundle (HXPhotoPicker)
+ (instancetype)hx_photopickerBundle {
    static NSBundle *hxBundle = nil;
    if (hxBundle == nil) {
        NSString *path = [[NSBundle mainBundle] pathForResource:@"HXPhotoPicker" ofType:@"bundle"];
        if (!path) {
            path = [[NSBundle mainBundle] pathForResource:@"HXPhotoPicker" ofType:@"bundle" inDirectory:@"Frameworks/HXPhotoPicker.framework/"];
        }
        hxBundle = [NSBundle bundleWithPath:path];
    }
    return hxBundle;
}
+ (NSString *)hx_localizedStringForKey:(NSString *)key
{
    return [self hx_localizedStringForKey:key value:nil];
}

+ (NSString *)hx_localizedStringForKey:(NSString *)key value:(NSString *)value
{
    static NSBundle *bundle = nil;
    if (bundle == nil) {
        NSString *language = [NSLocale preferredLanguages].firstObject;
        if ([language hasPrefix:@"en"]) {
            language = @"en";
        } else if ([language hasPrefix:@"zh"]) {
            if ([language rangeOfString:@"Hans"].location != NSNotFound) {
                language = @"zh-Hans"; // 简体中文
            } else { // zh-Hant\zh-HK\zh-TW
                language = @"zh-Hant"; // 繁體中文
            }
        } else if ([language hasPrefix:@"ja"]){
            // 日文
            language = @"ja";
        }else if ([language hasPrefix:@"ko"]) {
            // 韩文
            language = @"ko";
        }else {
            language = @"en";
        }
         
        bundle = [NSBundle bundleWithPath:[[NSBundle hx_photopickerBundle] pathForResource:language ofType:@"lproj"]];
    }
    value = [bundle localizedStringForKey:key value:value table:nil];
    return [[NSBundle mainBundle] localizedStringForKey:key value:value table:nil];
}
@end
