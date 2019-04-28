//
//  NSDate+HXExtension.h
//  照片选择器
//
//  Created by 洪欣 on 2017/10/14.
//  Copyright © 2017年 洪欣. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSDate (HXExtension)

/**
 是否今天

 @return yes or no
 */
- (BOOL)hx_isToday;

/**
 是否昨天

 @return yes or no
 */
- (BOOL)hx_isYesterday;

/**
 是否今年
 
 @return yes or no
 */
- (BOOL)hx_isThisYear;

/**
 和今天是否在同一周
 
 @return yes or no
 */
- (BOOL)hx_isSameWeek;

- (NSString *)hx_getNowWeekday;

/**
 按指定格式获取当前的时间

 @param format 格式
 @return 日期字符串
 */
- (NSString *)hx_dateStringWithFormat:(NSString *)format;

/**
 是否是同一天

 @param date 需要比较的NSDate
 @return yes or no
 */
- (BOOL)hx_isSameDay:(NSDate*)date;
@end
