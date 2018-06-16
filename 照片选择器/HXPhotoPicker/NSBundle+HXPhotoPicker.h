//
//  NSBundle+HXPhotoPicker.h
//  照片选择器
//
//  Created by 洪欣 on 2017/7/25.
//  Copyright © 2017年 洪欣. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSBundle (HXPhotoPicker)
+ (instancetype)hx_photopickerBundle;
+ (NSString *)hx_localizedStringForKey:(NSString *)key value:(NSString *)value;
+ (NSString *)hx_localizedStringForKey:(NSString *)key;
@end
