//
//  NSMutableDictionary+WeakRef.m
//  student
//
//  Created by taomingyan on 2020/11/8.
//  Copyright © 2020 pplingo. All rights reserved.
//

#import "NSMutableDictionary+WeakRef.h"
#import "LaWeakRefUtil.h"

@implementation NSMutableDictionary (WeakRef)

-(void)w_setObject:(id)anObject forKey:(id<NSCopying>)aKey{
    if((anObject != nil) && (aKey != nil)){
        [self setObject:[LaWeakRefUtil makeWeakReference:anObject] forKey:aKey];
    }
}

- (id)w_objectForKey:(id)aKey{
    if (aKey != nil) {
        return [LaWeakRefUtil weakReferenceNonretainedObjectValue:[self objectForKey:aKey]];
    }
    
    return nil;
}

@end
