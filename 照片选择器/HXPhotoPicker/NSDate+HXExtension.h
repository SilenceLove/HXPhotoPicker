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
- (BOOL)isToday;

/**
 是否昨天

 @return yes or no
 */
- (BOOL)isYesterday;

/**
 是否今年
 
 @return yes or no
 */
- (BOOL)isThisYear;

/**
 和今天是否在同一周
 
 @return yes or no
 */
- (BOOL)isSameWeek;

- (NSString *)getNowWeekday;

/**
 按指定格式获取当前的时间

 @param format 格式
 @return 日期字符串
 */
- (NSString *)dateStringWithFormat:(NSString *)format;
@end
