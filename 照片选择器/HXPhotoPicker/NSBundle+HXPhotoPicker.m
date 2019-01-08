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

static NSBundle *hx_languageBundle = nil;

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

+ (void)hx_languageBundleDealloc {
    hx_languageBundle = nil;
}

+ (instancetype)hx_languageBundle {
    if (hx_languageBundle == nil) {
        NSString *language = [NSLocale preferredLanguages].firstObject;
        HXPhotoLanguageType type = [HXPhotoCommon photoCommon].languageType;
        switch (type) {
            case HXPhotoLanguageTypeSc : {
                language = @"zh-Hans"; // 简体中文
            } break;
            case HXPhotoLanguageTypeTc : {
                language = @"zh-Hant"; // 繁體中文
            } break;
            case HXPhotoLanguageTypeJa : {
                // 日文
                language = @"ja";
            } break;
            case HXPhotoLanguageTypeKo : {
                // 韩文
                language = @"ko";
            } break;
            case HXPhotoLanguageTypeEn : {
                language = @"en";
            } break;
            default : {
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
            }break;
        } 
        hx_languageBundle = [NSBundle bundleWithPath:[[NSBundle hx_photoPickerBundle] pathForResource:language ofType:@"lproj"]];
    }
    return hx_languageBundle;
}

+ (NSString *)hx_localizedStringForKey:(NSString *)key value:(NSString *)value {
    NSBundle *bundle = [self hx_languageBundle];
    value = [bundle localizedStringForKey:key value:value table:nil];
    return [[NSBundle mainBundle] localizedStringForKey:key value:value table:nil];
}
@end
