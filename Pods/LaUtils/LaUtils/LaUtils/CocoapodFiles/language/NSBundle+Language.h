//
//  NSBundle+Language.h
//  student
//
//  Created by taomingyan on 2020/11/30.
//  Copyright © 2020 pplingo. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSBundle (Language)

// 'en'  'zh-Hans'
+ (void)setLanguage:(NSString *)language;

@end

NS_ASSUME_NONNULL_END
