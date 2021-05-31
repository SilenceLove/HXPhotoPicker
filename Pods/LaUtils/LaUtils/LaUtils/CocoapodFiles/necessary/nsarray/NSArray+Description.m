//
//  NSArray+Description.m
//  student
//
//  Created by gao on 2020/11/4.
//  Copyright © 2020 pplingo. All rights reserved.
//

#import "NSArray+Description.h"
#import <Foundation/Foundation.h>
 
@implementation NSArray (Description)
- (NSString *)description
{
    NSMutableString *str = [NSMutableString string];
    
    [str appendString:@"[\n"];
    
    // 遍历数组的所有元素
    [self enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        [str appendFormat:@"%@,\n", obj];
    }];
    
    [str appendString:@"]"];
    
    // 查出最后一个,的范围
    NSRange range = [str rangeOfString:@"," options:NSBackwardsSearch];
    if (range.length != 0) {
        // 删掉最后一个,
        [str deleteCharactersInRange:range];
    }
    
    return str;
}

@end
