#import "LaTimeUtil.h"
#import "LaNSStringMacro.h"

#define TimeZoneUtc [NSTimeZone timeZoneWithAbbreviation:@"UTC"]
#define TimeZoneLocal [NSTimeZone localTimeZone]

@implementation LaTimeUtil

//获取当前未格式化的系统时间 格式yyyy-MM-dd HH:mm:ss
+ (NSString *)getCurrentLocalTimeWithFormat:(NSString *)format{
    NSDateFormatter * formatter = [[NSDateFormatter alloc]init];
    [formatter setTimeZone:[NSTimeZone localTimeZone]];
    [formatter setDateFormat:format];
    NSString * dateTime = [formatter stringFromDate:[NSDate date]];
    return dateTime;
}

//获取当前未格式化的系统时间 格式yyyy-MM-dd HH:mm:ss
+ (NSString *)getCurrentUTCTimeWithFormat:(NSString *)format{
    NSDateFormatter * formatter = [[NSDateFormatter alloc]init];
    [formatter setTimeZone:[NSTimeZone timeZoneWithAbbreviation:@"UTC"]];
    [formatter setDateFormat:format];
    NSString * dateTime = [formatter stringFromDate:[NSDate date]];
    return dateTime;
}

//例如 [LaTimeUtil inputTime:@"2020-11-11" inputFormat:@"yyyy-mm-dd" outputFormat:@"mm月dd日"];
+(NSString *)convertTime:(NSString *)inputTime inputFormat:(NSString *)inputFormat outputFormat:(NSString *)outputFormat locale:(NSLocale *)locale{
    if (inputTime&&inputFormat&&outputFormat)
    {
        NSDateFormatter *inputFormatter = [[NSDateFormatter alloc] init];
        [inputFormatter setLocale:[NSLocale currentLocale]];
        [inputFormatter setDateFormat:inputFormat];
        NSDate* inputDate = [inputFormatter dateFromString:inputTime];
        
        NSDateFormatter *outputFormatter = [[NSDateFormatter alloc] init];
        [outputFormatter setLocale:[NSLocale currentLocale]];
        [outputFormatter setDateFormat:outputFormat];
        NSString *str = [outputFormatter stringFromDate:inputDate];
        return str;
    }
    else
    {
        return @"";
    }
}

//时间字符串转换成Date 格式 2020-12-11T01:45:45.000Z
+(NSDate *)toDate:(NSString *)time format:(NSString *)format locale:(NSTimeZone *)locale{
    if ([M_VerifyString(time) length] > 0) {
        if ([format isEqualToString:@"yyyy-MM-ddTHH:mm:ss.SSSZ"]) {
            NSString *nextTime = [[time stringByReplacingOccurrencesOfString:@"Z" withString:@""] stringByReplacingOccurrencesOfString:@"T" withString:@" "];
            NSDateFormatter *inputFormatter = [[NSDateFormatter alloc] init];
            [inputFormatter setTimeZone:locale];
            [inputFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss.SSS"];
            NSDate *date = [inputFormatter dateFromString:nextTime];
            return date;
        }
        else{
            NSDateFormatter *inputFormatter = [[NSDateFormatter alloc] init];
            [inputFormatter setTimeZone:locale];
            [inputFormatter setDateFormat:format];
            NSDate *date = [inputFormatter dateFromString:time];
            return date;
        }
    }
    return nil;
}

//时间字符串转换成Date 格式 2020-12-11T01:45:45.000Z
+(NSString *)toString:(NSDate *)date format:(NSString *)format locale:(NSTimeZone *)locale{
    if ([format isEqualToString:@"yyyy-MM-ddTHH:mm:ss.SSSZ"]) {
        NSDateFormatter *outputFormatter = [[NSDateFormatter alloc] init];
        [outputFormatter setTimeZone:locale];
        [outputFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss.SSS"];
        NSString *str = [NSString stringWithFormat:@"%@Z",[[outputFormatter stringFromDate:date] stringByReplacingOccurrencesOfString:@" " withString:@"T"]];
        return str;
    }else{
        NSDateFormatter *outputFormatter = [[NSDateFormatter alloc] init];
        [outputFormatter setTimeZone:locale];
        [outputFormatter setDateFormat:format];
        NSString *str = [outputFormatter stringFromDate:date];
        return str;
    }
}

@end
