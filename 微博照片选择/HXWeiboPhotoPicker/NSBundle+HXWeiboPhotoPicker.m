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
    static NSBundle *tzBundle = nil;
    if (tzBundle == nil) {
        NSString *path = [[NSBundle mainBundle] pathForResource:@"HXWeiboPhotoPicker" ofType:@"bundle"];
        if (!path) {
            path = [[NSBundle mainBundle] pathForResource:@"HXWeiboPhotoPicker" ofType:@"bundle" inDirectory:@"Frameworks/HXWeiboPhotoPicker.framework/"];
        }
        tzBundle = [NSBundle bundleWithPath:path];
    }
    return tzBundle;
}
@end
