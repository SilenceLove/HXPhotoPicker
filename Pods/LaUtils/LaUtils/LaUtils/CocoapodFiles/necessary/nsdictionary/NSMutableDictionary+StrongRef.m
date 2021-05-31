//
//  NSMutableDictionary+StrongRef.m
//  student
//
//  Created by taomingyan on 2020/11/8.
//  Copyright © 2020 pplingo. All rights reserved.
//

#import "NSMutableDictionary+StrongRef.h"

@implementation NSMutableDictionary (StrongRef)

-(void)s_setObject:(id)anObject forKey:(id<NSCopying>)aKey{
    if((anObject != nil) && (aKey != nil)){
        [self setObject:anObject forKey:aKey];
    }
}

- (id)s_objectForKey:(id)aKey{
    if (aKey != nil) {
        return [self objectForKey:aKey];
    }
    
    return nil;
}

@end
