//
//  LaThreadUtil.m
//  student
//
//  Created by taomingyan on 2020/11/10.
//  Copyright © 2020 pplingo. All rights reserved.
//

#import "LaThreadUtil.h"

static dispatch_queue_t m_queue;

@interface LaThreadUtil()
@end

@implementation LaThreadUtil

//在主线程同步执行
+(void)runInMainSyn:(RunBlock) block{
    if ([NSThread isMainThread]) {
        block();
    } else {
        dispatch_sync(dispatch_get_main_queue(), block);
    }
}

//在主线程异步执行
+(void)runInMainASyn:(RunBlock) block{
    if ([NSThread isMainThread]) {
        block();
    } else {
        dispatch_async(dispatch_get_main_queue(), block);
    }
}

//在非主线程异步执行
+(void)runInOtherThread:(RunBlock) block{
    if (m_queue == nil) {
        m_queue = dispatch_queue_create(NULL, DISPATCH_QUEUE_CONCURRENT);
    }
    dispatch_async(m_queue, block);
}
@end
