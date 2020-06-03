//
//  NSBundle+HXPhotopicker.m
//  照片选择器
//
//  Created by 洪欣 on 2017/7/25.
//  Copyright © 2017年 洪欣. All rights reserved.
//

#import "NSBundle+HXPhotoPicker.h"
#import "HXPhotoCommon.h" 

@implementation NSBundle (HXPhotoPicker)
+ (instancetype)hx_photoPickerBundle {
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
+ (NSString *)hx_localizedStringForKey:(NSString *)key {
    return [self hx_localizedStringForKey:key value:nil];
}
+ (NSString *)hx_localizedStringForKey:(NSString *)key value:(NSString *)value {
    NSBundle *bundle = [HXPhotoCommon photoCommon].languageBundle;
    value = [bundle localizedStringForKey:key value:value table:nil];
    return [[NSBundle mainBundle] localizedStringForKey:key value:value table:nil];
}
@end
