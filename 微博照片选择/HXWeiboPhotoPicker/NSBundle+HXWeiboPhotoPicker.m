//
//  NSBundle+HXWeiboPhotoPicker.m
//  微博照片选择
//
//  Created by 洪欣 on 2017/7/25.
//  Copyright © 2017年 洪欣. All rights reserved.
//

#import "NSBundle+HXWeiboPhotoPicker.h"

@implementation NSBundle (HXWeiboPhotoPicker)
+ (instancetype)hx_photoPickerBundle {
    static NSBundle *hxBundle = nil;
    if (hxBundle == nil) {
        NSString *path = [[NSBundle mainBundle] pathForResource:@"HXWeiboPhotoPicker" ofType:@"bundle"];
        if (!path) {
            path = [[NSBundle mainBundle] pathForResource:@"HXWeiboPhotoPicker" ofType:@"bundle" inDirectory:@"Frameworks/HXWeiboPhotoPicker.framework/"];
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
        if ([language rangeOfString:@"zh-Hans"].location != NSNotFound) {
            language = @"zh-Hans";
        } else {
            language = @"en";
        }
         
        bundle = [NSBundle bundleWithPath:[[NSBundle hx_photoPickerBundle] pathForResource:language ofType:@"lproj"]];
    }
    value = [bundle localizedStringForKey:key value:value table:nil];
    return [[NSBundle mainBundle] localizedStringForKey:key value:value table:nil];
}
@end
