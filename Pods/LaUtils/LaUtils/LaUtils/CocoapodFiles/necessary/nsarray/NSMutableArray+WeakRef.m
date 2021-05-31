//
//  NSMutableArray+WeakRef.m
//  Runner
//
//  Created by taomingyan on 2020/10/30.
//  Copyright © 2020 The Chromium Authors. All rights reserved.
//

#import "NSMutableArray+WeakRef.h"
#import "LaWeakRefUtil.h"

@implementation NSMutableArray (WeakRefMutableArray)

- (void)w_addObject:(id)anObject {
    if(anObject != nil){
        [self addObject:[LaWeakRefUtil makeWeakReference:anObject]];
    }
}

- (void)w_removeObject:(id)anObject {
    if (anObject != nil) {
        NSInteger index = -1;
        NSInteger itemIndex = 0;
        for (id item in self) {
            if ([[LaWeakRefUtil weakReferenceNonretainedObjectValue:item] isEqual:anObject]) {
                index = itemIndex;
                break;
            }
            itemIndex ++;
        }
        if(index != -1) [self removeObjectAtIndex:index];
    }
}

-(id)w_objectAtIndex:(NSInteger)index{
    if (index >= 0 && (index < [self count])) {
        return [LaWeakRefUtil weakReferenceNonretainedObjectValue:[self objectAtIndex:index]];
    }
    
    return nil;
}

- (void)w_insertObject:(id)anObject atIndex:(NSUInteger)index{
    if (index >= 0 && (index < [self count]) && (anObject != nil)) {
        return [self insertObject:[LaWeakRefUtil makeWeakReference:anObject] atIndex:index];
    }
}

- (void)w_removeObjectAtIndex:(NSUInteger)index{
    if (index >= 0 && (index < [self count])) {
        return [self removeObjectAtIndex:index];
    }
}

-(void)w_replaceObjectAtIndex:(NSUInteger)index withObject:(id)anObject{
    if (index >= 0 && (index < [self count]) && (anObject != nil)) {
        return [self replaceObjectAtIndex:index withObject:[LaWeakRefUtil makeWeakReference:anObject]];
    }
}

@end
