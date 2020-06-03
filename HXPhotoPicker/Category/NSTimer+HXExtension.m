//
//  NSTimer+HXExtension.m
//  照片选择器
//
//  Created by 洪欣 on 2019/1/3.
//  Copyright © 2019年 洪欣. All rights reserved.
//

#import "NSTimer+HXExtension.h"

@implementation NSTimer (HXExtension)
+ (id)hx_scheduledTimerWithTimeInterval:(NSTimeInterval)inTimeInterval block:(void (^)(void))inBlock repeats:(BOOL)inRepeats
{
    void (^block)(void) = [inBlock copy];
    id ret = [self scheduledTimerWithTimeInterval:inTimeInterval target:self selector:@selector(hx_executeSimpleBlock:) userInfo:block repeats:inRepeats]; 
    return ret;
}

+ (id)hx_timerWithTimeInterval:(NSTimeInterval)inTimeInterval block:(void (^)(void))inBlock repeats:(BOOL)inRepeats
{
    void (^block)(void) = [inBlock copy];
    id ret = [self timerWithTimeInterval:inTimeInterval target:self selector:@selector(hx_executeSimpleBlock:) userInfo:block repeats:inRepeats];
    return ret;
}

+ (void)hx_executeSimpleBlock:(NSTimer *)inTimer;
{
    if([inTimer userInfo])
    {
        void (^block)(void) = (void (^)(void))[inTimer userInfo];
        block();
    }
}
@end
