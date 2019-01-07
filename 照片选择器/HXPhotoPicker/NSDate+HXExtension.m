//
//  NSDate+HXExtension.m
//  照片选择器
//
//  Created by 洪欣 on 2017/10/14.
//  Copyright © 2017年 洪欣. All rights reserved.
//

#import "NSDate+HXExtension.h"

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
    int unit = NSCalendarUnitWeekday | NSCalendarUnitMonth | NSCalendarUnitYear ;
    
    //1.获得当前时间的 年月日
    NSDateComponents *nowCmps = [calendar components:unit fromDate:[NSDate date]];
    
    //2.获得self
    NSDateComponents *selfCmps = [calendar components:unit fromDate:self];
    
    return (selfCmps.year == nowCmps.year) && (selfCmps.month == nowCmps.month) && (selfCmps.day == nowCmps.day);
}
- (NSString *)hx_getNowWeekday {
    NSDateFormatter *dateday = [[NSDateFormatter alloc] init];
    NSString *language = [NSLocale preferredLanguages].firstObject;
    
    if ([language hasPrefix:@"en"]) {
        // 英文
        [dateday setDateFormat:@"MMM dd"];
        [dateday setDateFormat:@"EEE"];
    } else if ([language hasPrefix:@"zh"]) {
        // 中文
        [dateday setDateFormat:@"MM月dd日"];
        [dateday setDateFormat:@"EEEE"];
    }else if ([language hasPrefix:@"ko"]) {
        // 韩语
        [dateday setDateFormat:@"MM월dd일"];
        [dateday setDateFormat:@"EEEE"];
    }else if ([language hasPrefix:@"ja"]) {
        // 日语
        [dateday setDateFormat:@"MM月dd日"];
        [dateday setDateFormat:@"EEEE"];
    } else {
        // 英文
        [dateday setDateFormat:@"MMM dd"];
        [dateday setDateFormat:@"EEE"];
    } 
    return [dateday stringFromDate:self];
}

- (NSString *)hx_dateStringWithFormat:(NSString *)format {
    NSDateFormatter *formater = [[NSDateFormatter alloc] init];
    formater.dateFormat = format;
    return[formater stringFromDate:self];
}

- (BOOL)hx_isSameDay:(NSDate*)date {
    NSCalendar* calendar = [NSCalendar currentCalendar];
    
    unsigned unitFlags = NSCalendarUnitYear | NSCalendarUnitMonth |  NSCalendarUnitDay;
    NSDateComponents* comp1 = [calendar components:unitFlags fromDate:self];
    NSDateComponents* comp2 = [calendar components:unitFlags fromDate:date];
    
    return [comp1 day]   == [comp2 day] &&
    [comp1 month] == [comp2 month] &&
    [comp1 year]  == [comp2 year];
}
@end
