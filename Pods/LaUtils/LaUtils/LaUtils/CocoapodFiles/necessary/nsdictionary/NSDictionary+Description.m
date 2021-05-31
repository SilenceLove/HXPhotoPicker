//
//  NSDictionary+Description.m
//  student
//
//  Created by gao on 2020/11/4.
//  Copyright © 2020 pplingo. All rights reserved.
//

#import "NSDictionary+Description.h"
#import <Foundation/Foundation.h>

@implementation NSDictionary (Description)

- (NSString *)description
{
    NSMutableString *str = [NSMutableString string];
    
    [str appendString:@"{\n"];
    
    // 遍历字典的所有键值对
    [self enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        [str appendFormat:@"\t%@ = %@,\n", key, obj];
    }];
    
    [str appendString:@"}"];
    
    // 查出最后一个,的范围
    NSRange range = [str rangeOfString:@"," options:NSBackwardsSearch];
    if (range.length != 0) {
        // 删掉最后一个,
        [str deleteCharactersInRange:range];
    }
    
    return str;
}
@end
