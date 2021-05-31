//
//  LaWeakRefUtil.m
//  student
//
//  Created by taomingyan on 2020/11/9.
//  Copyright © 2020 pplingo. All rights reserved.
//

#import "LaWeakRefUtil.h"

@implementation LaWeakRefUtil

+(WeakReference) makeWeakReference:(id) object {
    __weak id weakref = object;
    return ^{
        return weakref;
    };
}

+(id) weakReferenceNonretainedObjectValue:(WeakReference) ref {
    return ref ? ref() : nil;
}

@end
