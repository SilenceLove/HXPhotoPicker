//
//  NSBundle+HXPhotoPicker.h
//  HXPhotoPickerExample
//
//  Created by Silence on 2017/7/25.
//  Copyright © 2017年 Silence. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSBundle (HXPhotoPicker)
+ (instancetype)hx_photoPickerBundle;
+ (NSString *)hx_localizedStringForKey:(NSString *)key value:(NSString *)value;
+ (NSString *)hx_localizedStringForKey:(NSString *)key;
@end
