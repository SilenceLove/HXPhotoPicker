//
//  TimeTool.h
//  taomy
//

#import <Foundation/Foundation.h>

#define TimeZoneUtc [NSTimeZone timeZoneWithAbbreviation:@"UTC"]
#define TimeZoneLocal [NSTimeZone localTimeZone]

@interface LaTimeUtil : NSObject

//获取当前未格式化的系统时间 格式yyyy-MM-dd HH:mm:ss
//例如 [LaTimeUtil getCurrentUTCTimeWithFormat:@"yyyy-MM-dd HH:mm:ss"]
+ (NSString *)getCurrentLocalTimeWithFormat:(NSString *)format;

//获取当前未格式化的系统时间 格式yyyy-MM-dd HH:mm:ss
//例如 [LaTimeUtil getCurrentUTCTimeWithFormat:@"yyyy-MM-dd HH:mm:ss"]
+ (NSString *)getCurrentUTCTimeWithFormat:(NSString *)format;

//例如 [LaTimeUtil inputTime:@"2020-11-11 12:00:00" inputFormat:@"yyyy-mm-dd HH:mm:ss" outputFormat:@"mm月dd日"];
+(NSString *)convertTime:(NSString *)inputTime inputFormat:(NSString *)inputFormat outputFormat:(NSString *)outputFormat;

//时间字符串转换成Date 格式 2020-12-11T01:45:45.000Z
//e.g. [LaTimeUtil toDate:time format:@"yyyy-MM-ddTHH:mm:ss.SSSZ" locale:TimeZoneUtc]
+(NSDate *)toDate:(NSString *)time format:(NSString *)format locale:(NSTimeZone *)locale;

//utc时间字符串转换成Date 格式 2020-12-11T01:45:45.000Z
//时间字符串转换成Date 格式 2020-12-11T01:45:45.000Z
//e.g. [LaTimeUtil toString:date format:@"yyyy-MM-dd HH:mm:ss" locale:TimeZoneLocal]
+(NSString *)toString:(NSDate *)date format:(NSString *)format locale:(NSTimeZone *)locale;
@end
