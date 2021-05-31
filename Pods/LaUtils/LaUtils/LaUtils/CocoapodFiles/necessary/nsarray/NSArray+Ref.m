//
//  NSArray+Ref.m
//  student
//
//  Created by taomingyan on 2020/11/8.
//  Copyright © 2020 pplingo. All rights reserved.
//

#import "NSArray+Ref.h"

@implementation NSArray (StrongRef)

-(id)s_objectAtIndex:(NSInteger)index{
    if (index >= 0 && (index < [self count])) {
        return [self objectAtIndex:index];
    }
    
    return nil;
}

@end
