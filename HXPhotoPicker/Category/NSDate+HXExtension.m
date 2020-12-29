//
//  NSDate+HXExtension.m
//  HXPhotoPickerExample
//
//  Created by Silence on 2017/10/14.
//  Copyright © 2017年 Silence. All rights reserved.
//

#import "NSDate+HXExtension.h"
#import "HXPhotoCommon.h" 

@implementation NSDate (HXExtension)
/**
 *  是否为今天
 */
- (BOOL)hx_isToday {
    NSCalendar *calendar = [NSCalendar currentCalendar];
    int unit = NSCalendarUnitDay | NSCalendarUnitMonth |  NSCalendarUnitYear;
    
    // 1.获得当前时间的年月日
    NSDateComponents *nowCmps = [calendar components:unit fromDate:[NSDate date]];
    
    // 2.获得self的年月日
    NSDateComponents *selfCmps = [calendar components:unit fromDate:self];
    return
    (selfCmps.year == nowCmps.year) &&
    (selfCmps.month == nowCmps.month) &&
    (selfCmps.day == nowCmps.day);
}
/**
 *  是否为昨天
 */
- (BOOL)hx_isYesterday {
    NSDateFormatter *fmt = [[NSDateFormatter alloc] init];
    fmt.dateFormat = @"yyyyMMdd";
    
    // 生成只有年月日的字符串对象
    NSString *selfString = [fmt stringFromDate:self];
    NSString *nowString = [fmt stringFromDate:[NSDate date]];
    
    // 生成只有年月日的日期对象
    NSDate *selfDate = [fmt dateFromString:selfString];
    NSDate *nowDate = [fmt dateFromString:nowString];
    
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSCalendarUnit unit = NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay;
    NSDateComponents *cmps = [calendar components:unit fromDate:selfDate toDate:nowDate options:0];
    return cmps.year == 0
    && cmps.month == 0
    && cmps.day == 1;
}
/**
 *  是否为今年
 */
- (BOOL)hx_isThisYear {
    NSCalendar *calendar = [NSCalendar currentCalendar];
    int unit = NSCalendarUnitYear;
    
    // 1.获得当前时间的年月日
    NSDateComponents *nowCmps = [calendar components:unit fromDate:[NSDate date]];
    
    // 2.获得self的年月日
    NSDateComponents *selfCmps = [calendar components:unit fromDate:self];
    
    return nowCmps.year == selfCmps.year;
}

/**
 是否为同一周内 
 */
- (BOOL)hx_isSameWeek {
    NSCalendar *calendar = [NSCalendar currentCalendar];
    int unit = NSCalendarUnitWeekday | NSCalendarUnitMonth | NSCalendarUnitYear | kCFCalendarUnitDay | kCFCalendarUnitHour | kCFCalendarUnitMinute ;
    
    //1.获得当前时间的 年月日
    NSDateComponents *nowCmps = [calendar components:unit fromDate:[NSDate date]];
    NSDateComponents *sourceCmps = [calendar components:unit fromDate:self];
    
    // 对比时间差
    NSDateComponents *dateCom = [calendar components:unit fromDate:[NSDate date] toDate:self options:0];
    NSInteger subDay = labs(dateCom.day);
    NSInteger subMonth = labs(dateCom.month);
    NSInteger subYear = labs(dateCom.year);
    
    if (subYear == 0 && subMonth == 0) { //当相关的差值等于零的时候说明在一个年、月、日的时间范围内，不是按照零点到零点的时间算的
        if (subDay > 6) { //相差天数大于6肯定不在一周内
            return NO;
        } else { //相差的天数大于或等于后面的时间所对应的weekday则不在一周内
            if (dateCom.day >= 0 && dateCom.hour >=0 && dateCom.minute >= 0) { //比较的时间大于当前时间
                //西方一周的开始是从周日开始算的，周日是1，周一是2，而我们是从周一开始算新的一周
                NSInteger chinaWeekday = sourceCmps.weekday == 1 ? 7 : sourceCmps.weekday - 1;
                if (subDay >= chinaWeekday) {
                    return NO;
                } else {
                    return YES;
                }
            } else {
                NSInteger chinaWeekday = sourceCmps.weekday == 1 ? 7 : nowCmps.weekday - 1;
                if (subDay >= chinaWeekday) { //比较的时间比当前时间小，已经过去的时间
                    return NO;
                } else {
                    return YES;
                }
            }
        }
    } else { //时间范围差值超过了一年或一个月的时间范围肯定就不在一个周内了
        return NO;
    }
}
- (NSString *)hx_getNowWeekday {
    NSDateFormatter *dateday = [[NSDateFormatter alloc] init];
    
    HXPhotoLanguageType type = [HXPhotoCommon photoCommon].languageType;
    NSLocale *locale = [[NSLocale alloc] initWithLocaleIdentifier:@"zh-Hans"];
    if (type == HXPhotoLanguageTypeSc) {
        locale = [[NSLocale alloc] initWithLocaleIdentifier:@"zh-Hans"];
    }else if (type == HXPhotoLanguageTypeTc) {
        locale = [[NSLocale alloc] initWithLocaleIdentifier:@"zh-Hant"];
    }else if (type == HXPhotoLanguageTypeJa) {
        locale = [[NSLocale alloc] initWithLocaleIdentifier:@"ja"];
    }else if (type == HXPhotoLanguageTypeKo) {
        locale = [[NSLocale alloc] initWithLocaleIdentifier:@"ko"];
    }else if (type == HXPhotoLanguageTypeEn) {
        locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en"];
    }
    if (locale) {
        [dateday setLocale:locale];
    }
    [dateday setDateFormat:@"MMM dd"];
    [dateday setDateFormat:@"EEE"];
//    switch (type) {
//        case HXPhotoLanguageTypeSc :
//        case HXPhotoLanguageTypeTc :
//        case HXPhotoLanguageTypeJa : {
//            // 中 / 日 / 繁
//            [dateday setDateFormat:@"MM月dd日"];
//            [dateday setDateFormat:@"EEEE"];
//        } break;
//        case HXPhotoLanguageTypeKo : {
//            // 韩语
//            [dateday setDateFormat:@"MM월dd일"];
//            [dateday setDateFormat:@"EEEE"];
//        } break;
//        case HXPhotoLanguageTypeEn : {
//            // 英文
//            [dateday setDateFormat:@"MMM dd"];
//            [dateday setDateFormat:@"EEE"];
//        } break;
//        default : {
//            NSString *language = [NSLocale preferredLanguages].firstObject;
//            if ([language hasPrefix:@"zh"] ||
//                [language hasPrefix:@"ja"]) {
//                // 中 / 日 / 繁
//                [dateday setDateFormat:@"MM月dd日"];
//                [dateday setDateFormat:@"EEEE"];
//            }else if ([language hasPrefix:@"ko"]) {
//                // 韩语
//                [dateday setDateFormat:@"MM월dd일"];
//                [dateday setDateFormat:@"EEEE"];
//            } else {
//                // 英文
//                [dateday setDateFormat:@"MMM dd"];
//                [dateday setDateFormat:@"EEE"];
//            }
//        }break;
//    }
    return [dateday stringFromDate:self];
}

- (NSString *)hx_dateStringWithFormat:(NSString *)format {
    NSDateFormatter *formater = [[NSDateFormatter alloc] init];
    formater.dateFormat = format;
    HXPhotoLanguageType type = [HXPhotoCommon photoCommon].languageType;
    NSLocale *locale;
    switch (type) {
        case HXPhotoLanguageTypeEn:
            locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en"];
            break;
        case HXPhotoLanguageTypeSc:
            locale = [[NSLocale alloc] initWithLocaleIdentifier:@"zh-Hans"];
            break;
        case HXPhotoLanguageTypeTc:
            locale = [[NSLocale alloc] initWithLocaleIdentifier:@"zh-Hant"];
            break;
        case HXPhotoLanguageTypeJa:
            locale = [[NSLocale alloc] initWithLocaleIdentifier:@"ja"];
            break;
        case HXPhotoLanguageTypeKo:
            locale = [[NSLocale alloc] initWithLocaleIdentifier:@"ko"];
            break;
        default:
            break;
    }
    if (locale) {
        [formater setLocale:locale];
    }
    return [formater stringFromDate:self];
}
@end
