//
//  LaWeakRefUtil.h
//  student
//
//  Created by taomingyan on 2020/11/9.
//  Copyright © 2020 pplingo. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

#define WeakSelf __weak typeof(self) selfWeak = self;

#define WeakObj(o) __weak typeof(o) o##Weak = o;

typedef id _Nonnull (^WeakReference)(void);

@interface LaWeakRefUtil : NSObject

+(WeakReference) makeWeakReference:(id) object;

+(id) weakReferenceNonretainedObjectValue:(WeakReference) ref;

@end

NS_ASSUME_NONNULL_END
