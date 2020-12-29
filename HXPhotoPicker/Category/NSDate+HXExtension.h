//
//  NSDate+HXExtension.h
//  HXPhotoPickerExample
//
//  Created by Silence on 2017/10/14.
//  Copyright © 2017年 Silence. All rights reserved.
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

@end
