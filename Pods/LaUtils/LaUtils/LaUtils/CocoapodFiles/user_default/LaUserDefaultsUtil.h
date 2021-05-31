//
//  LaUserDefaultsUtil.h
//  student
//
//  Created by Taomy on 2020/11/4.
//  Copyright © 2020年 pplingo. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface LaUserDefaultsUtil : NSObject

// 存储单个object对象
+ (void)setObject:(id)object forKey:(NSString *)key;

// 获取单个object对象
+ (id)objectForkey:(NSString *)key;

// 在某个集合中存储object对象
+ (void)setObject:(id)object forKey:(NSString *)key inPackage:(NSString *)packageId;

// 获取某个集合中存储的object对象
+ (id)objectForkey:(NSString *)key inPackage:(NSString *)packageId;

// 删除某个package中单个object对象
+ (void)removeObjectForKey:(NSString *)key inPackage:(NSString *)packageId;

// 删除某个集合
+ (BOOL)deletePackage:(NSString *)packageId;
@end
