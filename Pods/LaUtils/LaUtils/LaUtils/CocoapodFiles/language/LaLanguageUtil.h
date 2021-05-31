//
//  LaLanguageUtil.h
//  LaUtils
//
//  Created by taomingyan on 2020/11/30.
//

#import <Foundation/Foundation.h>
#import "NSBundle+Language.h"

NS_ASSUME_NONNULL_BEGIN

@interface LaLanguageUtil : NSObject

//设置App支持的语言列表 @[@"en", @"zh-Hans"]， 必须包含@"en", 这是默认的选项，如果不设置任何内容，皮配不到按照en设置
+(void)setSupportedLanguage:(NSArray *)languages;

//获取当前的语言设置
+(NSString *)currentLanguage;

// 'en'  'zh-Hans'
+ (void)setLanguage:(NSString *)language;
@end

NS_ASSUME_NONNULL_END
