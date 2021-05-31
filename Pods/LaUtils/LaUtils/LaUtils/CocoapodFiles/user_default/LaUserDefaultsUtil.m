//
//  LaUserDefaultsUtil.h
//  student
//
//  Created by Taomy on 2020/11/4.
//  Copyright © 2020年 pplingo. All rights reserved.
//

#import "LaUserDefaultsUtil.h"

@implementation LaUserDefaultsUtil

// 存储单个object对象
+ (void)setObject:(id)object forKey:(NSString *)key {
    NSUserDefaults * userDefault = [NSUserDefaults standardUserDefaults];
    [userDefault setObject:object forKey:key];
    [userDefault synchronize];
}

// 获取单个object对象
+ (id)objectForkey:(NSString *)key {
    return [[NSUserDefaults standardUserDefaults] objectForKey:key];
}

// 删除某个package中单个object对象
+ (void)removeObjectForKey:(NSString *)key inPackage:(NSString *)packageId {
    
    if (!packageId) {
        return;
    }
    
    NSMutableDictionary * mutableDic = [NSMutableDictionary dictionaryWithDictionary:[[self class] objectForkey:packageId]];
    
    if (mutableDic)
    {
        [mutableDic removeObjectForKey:key];
        NSUserDefaults * userDefault = [NSUserDefaults standardUserDefaults];
        [userDefault setObject:mutableDic forKey:packageId];
        [userDefault synchronize];
    }
}

// 在某个集合中存储object对象
+ (void)setObject:(id)object forKey:(NSString *)key inPackage:(NSString *)packageId {
    
    if (!packageId) {
        return;
    }
    
    NSMutableDictionary * mutableDic = [NSMutableDictionary dictionaryWithDictionary:[[self class] objectForkey:packageId]];
    
    if (mutableDic) {
        
        //    NSDictionary * dic = [NSDictionary dictionaryWithObjectsAndKeys:object,key, nil];
        
        //更新本地的数据前，先将本地的所有数据取出来后，再将新数据add或者update
        
        [mutableDic setObject:object forKey:key];
        NSUserDefaults * userDefault = [NSUserDefaults standardUserDefaults];
        [userDefault setObject:mutableDic forKey:packageId];
        [userDefault synchronize];
        
    } else {
    
        NSMutableDictionary * dic = [NSMutableDictionary dictionaryWithCapacity:5];
        [dic setObject:object forKey:key];
        
        NSUserDefaults * userDefault = [NSUserDefaults standardUserDefaults];
        [userDefault setObject:dic forKey:packageId];
        [userDefault synchronize];
    }
}

// 获取某个集合中存储的object对象
+ (id)objectForkey:(NSString *)key inPackage:(NSString *)packageId {
    
    if (!packageId) {
        return nil;
    }
    
    NSDictionary * dic = [[NSUserDefaults standardUserDefaults] objectForKey:packageId];
    return [dic objectForKey:key];
}

// 删除某个集合
+ (BOOL)deletePackage:(NSString *)packageId {
    
    if (!packageId) {
        return NO;
    }
    
    NSUserDefaults * userDefault = [NSUserDefaults standardUserDefaults];
    if ([userDefault objectForKey:packageId]) {
        [userDefault removeObjectForKey:packageId];
        [userDefault synchronize];
        return YES;
    } else {
        return YES;
    }
}

@end
