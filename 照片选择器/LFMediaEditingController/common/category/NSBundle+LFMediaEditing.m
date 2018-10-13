//
//  NSBundle+LFMediaEditing.m
//  LFMediaEditingController
//
//  Created by TsanFeng Lam on 2018/3/15.
//  Copyright © 2018年 LamTsanFeng. All rights reserved.
//

#import "NSBundle+LFMediaEditing.h"
#import "LFBaseEditingController.h"

NSString *const LFMediaEditingStrings = @"LFMediaEditingController";

@implementation NSBundle (LFMediaEditing)

+ (instancetype)LFME_imagePickerBundle
{
    static NSBundle *lfMediaEditingBundle = nil;
    if (lfMediaEditingBundle == nil) {
        // 这里不使用mainBundle是为了适配pod 1.x和0.x
        lfMediaEditingBundle = [NSBundle bundleWithPath:[[NSBundle bundleForClass:[LFBaseEditingController class]] pathForResource:@"LFMediaEditingController" ofType:@"bundle"]];
    }
    return lfMediaEditingBundle;
}

+ (UIImage *)LFME_imageNamed:(NSString *)name inDirectory:(NSString *)subpath
{
    //  [UIImage imageNamed:[NSString stringWithFormat:@"%@/%@", kBundlePath, name]]
    NSString *extension = name.pathExtension.length ? name.pathExtension : @"png";
    NSString *defaultName = [name stringByDeletingPathExtension];
    NSString *bundleName = [defaultName stringByAppendingString:@"@2x"];
    //    CGFloat scale = [UIScreen mainScreen].scale;
    //    if (scale == 3) {
    //        bundleName = [name stringByAppendingString:@"@3x"];
    //    } else {
    //        bundleName = [name stringByAppendingString:@"@2x"];
    //    }
    UIImage *image = [UIImage imageWithContentsOfFile:[[self LFME_imagePickerBundle] pathForResource:bundleName ofType:extension inDirectory:subpath]];
    if (image == nil) {
        image = [UIImage imageWithContentsOfFile:[[self LFME_imagePickerBundle] pathForResource:defaultName ofType:extension inDirectory:subpath]];
    }
    if (image == nil) {
        image = [UIImage imageNamed:name];
    }
    return image;
}

+ (UIImage *)LFME_imageNamed:(NSString *)name
{
    return [self LFME_imageNamed:name inDirectory:nil];
}

+ (UIImage *)LFME_stickersImageNamed:(NSString *)name
{
    return [self LFME_imageNamed:name inDirectory:@"stickers"];
}

+ (NSString *)LFME_stickersPath
{
    return [[self LFME_imagePickerBundle] pathForResource:@"stickers" ofType:nil];
}

+ (NSString *)LFME_localizedStringForKey:(NSString *)key
{
    return [self LFME_localizedStringForKey:key value:nil];
}
+ (NSString *)LFME_localizedStringForKey:(NSString *)key value:(NSString *)value
{
    value = [[self LFME_imagePickerBundle] localizedStringForKey:key value:value table:LFMediaEditingStrings];
    return [[NSBundle mainBundle] localizedStringForKey:key value:value table:LFMediaEditingStrings];
}

@end
