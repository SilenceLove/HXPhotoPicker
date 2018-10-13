//
//  NSBundle+LFMediaEditing.h
//  LFMediaEditingController
//
//  Created by TsanFeng Lam on 2018/3/15.
//  Copyright © 2018年 LamTsanFeng. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface NSBundle (LFMediaEditing)

+ (instancetype)LFME_imagePickerBundle;

+ (UIImage *)LFME_imageNamed:(NSString *)name;
+ (UIImage *)LFME_stickersImageNamed:(NSString *)name;
+ (NSString *)LFME_stickersPath;

+ (NSString *)LFME_localizedStringForKey:(NSString *)key;
+ (NSString *)LFME_localizedStringForKey:(NSString *)key value:(NSString *)value;

@end
