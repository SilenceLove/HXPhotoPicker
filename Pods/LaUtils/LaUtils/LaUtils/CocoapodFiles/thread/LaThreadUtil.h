//
//  LaThreadUtil.h
//  student
//
//  Created by taomingyan on 2020/11/10.
//  Copyright © 2020 pplingo. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef void(^RunBlock)(void);

@interface LaThreadUtil : NSObject

//在主线程同步执行
+(void)runInMainSyn:(RunBlock) block;

//在主线程异步执行
+(void)runInMainASyn:(RunBlock) block;

//在非主线程异步执行
+(void)runInOtherThread:(RunBlock) block;
@end

NS_ASSUME_NONNULL_END
