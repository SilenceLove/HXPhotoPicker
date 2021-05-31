//
//  NSMutableArray+StrongRef.m
//  student
//
//  Created by taomingyan on 2020/11/8.
//  Copyright © 2020 pplingo. All rights reserved.
//

#import "NSMutableArray+StrongRef.h"

@implementation NSMutableArray (StrongRef)

- (void)s_addObject:(id)anObject{
    if(anObject != nil){
        [self addObject:anObject];
    }
}

- (void)s_removeObject:(id)anObject{
    if (anObject != nil) {
        [self removeObject:anObject];
    }
}

-(id)s_objectAtIndex:(NSInteger)index{
    if (index >= 0 && (index < [self count])) {
        return [self objectAtIndex:index];
    }
    
    return nil;
}

- (void)s_insertObject:(id)anObject atIndex:(NSUInteger)index{
    if (index >= 0 && (index < [self count]) && (anObject != nil)) {
        return [self insertObject:anObject atIndex:index];
    }
}

- (void)s_removeObjectAtIndex:(NSUInteger)index{
    if (index >= 0 && (index < [self count])) {
        return [self removeObjectAtIndex:index];
    }
}

-(void)s_replaceObjectAtIndex:(NSUInteger)index withObject:(id)anObject{
    if (index >= 0 && (index < [self count]) && (anObject != nil)) {
        return [self replaceObjectAtIndex:index withObject:anObject];
    }
}
@end
