//
//  NSBundle+HXPhotopicker.m
//  HXPhotoPickerExample
//
//  Created by Silence on 2017/7/25.
//  Copyright © 2017年 Silence. All rights reserved.
//

#import "NSBundle+HXPhotoPicker.h"
#import "HXPhotoCommon.h" 

@implementation NSBundle (HXPhotoPicker)
+ (instancetype)hx_photoPickerBundle {
    static NSBundle *hxBundle = nil;
    if (hxBundle == nil) {
        NSBundle *bundle = [NSBundle bundleForClass:NSClassFromString(@"HXPhotoPicker")];
        NSString *path = [bundle pathForResource:@"HXPhotoPicker" ofType:@"bundle"];
        //使用framework形式
        if (!path) {
            NSURL *associateBundleURL = [[NSBundle mainBundle] URLForResource:@"Frameworks" withExtension:nil];
            if (associateBundleURL) {
                associateBundleURL = [associateBundleURL URLByAppendingPathComponent:@"HXPhotoPicker"];
                associateBundleURL = [associateBundleURL URLByAppendingPathExtension:@"framework"];
                NSBundle *associateBunle = [NSBundle bundleWithURL:associateBundleURL];
                path = [associateBunle pathForResource:@"HXPhotoPicker" ofType:@"bundle"];
            }
        }
        hxBundle = path ? [NSBundle bundleWithPath:path]: [NSBundle mainBundle];
    }
    return hxBundle;
}
+ (NSString *)hx_localizedStringForKey:(NSString *)key {
    return [self hx_localizedStringForKey:key value:nil];
}
+ (NSString *)hx_localizedStringForKey:(NSString *)key value:(NSString *)value {
    NSBundle *bundle = [HXPhotoCommon photoCommon].languageBundle;
    value = [bundle localizedStringForKey:key value:value table:nil];
    if (!value) {
        value = key;
    }
    return value;
}
@end
