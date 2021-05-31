//
//  LaLanguageUtil.m
//  LaUtils
//
//  Created by taomingyan on 2020/11/30.
//

#import "LaLanguageUtil.h"
#import "NSBundle+Language.h"
#import "LaUserDefaultsUtil.h"
#import "NSArray+Ref.h"

#define LaLanguageUtilSettingDefault @"en"
#define LaLanguageUtilSettingLanguage @"LaLanguageUtilSettingLanguage"

static NSArray *p_languages;

@interface LaLanguageUtil(){
;
}
@property(class, strong)NSArray *m_languages;
@end

@implementation LaLanguageUtil

+(NSArray *)m_languages{
    return p_languages;
}

+(void)setM_languages:(NSArray *)languages{
    p_languages = languages;
}

//设置App支持的语言列表 @[@"en", @"zh-Hans"]
+(void)setSupportedLanguage:(NSArray *)languages{
    [LaLanguageUtil setM_languages:languages];
    if([LaUserDefaultsUtil objectForkey:LaLanguageUtilSettingLanguage]){
        [NSBundle setLanguage:([LaUserDefaultsUtil objectForkey:LaLanguageUtilSettingLanguage])];
    }
}

//获取当前的语言设置
+(NSString *)currentLanguage{
    //如果用户设置过语言，返回用户设置的语言
    if([LaUserDefaultsUtil objectForkey:LaLanguageUtilSettingLanguage]){
        return [LaUserDefaultsUtil objectForkey:LaLanguageUtilSettingLanguage];
    }else{//用户没有设置过语言，读取系统设置中的语言
        NSArray*languages = [NSLocale preferredLanguages];
        if ([languages s_objectAtIndex:0]) { //系统语言设置
            for(NSString *lanItem in [LaLanguageUtil m_languages]){
                if([[languages s_objectAtIndex:0] hasPrefix:lanItem]){ //如果能够匹配上配置列表里的某个item
                    return lanItem;
                }
            }

            // 如果能够匹配上中文的某些配置，返回配置选项中用zh-开头的项目
            if([[languages s_objectAtIndex:0] hasPrefix:@"zh-Han"] || [[languages s_objectAtIndex:0] hasPrefix:@"zh-Han"]){
                for(NSString *lanItem in [LaLanguageUtil m_languages]){
                    if([lanItem hasPrefix:@"zh-"]){
                        return lanItem;
                    }
                }
                return LaLanguageUtilSettingDefault;
            }else{
                return LaLanguageUtilSettingDefault;
            }
        }
        
        return LaLanguageUtilSettingDefault;
    }
}

// 'en'  'zh-Hans'
+ (void)setLanguage:(NSString *)language{
    if(language){
        [NSBundle setLanguage:language];
        [LaUserDefaultsUtil setObject:language forKey:LaLanguageUtilSettingLanguage];
    }
}
@end
