//
//  NSMutableDictionary+WeakRef.h
//  student
//
//  Created by taomingyan on 2020/11/8.
//  Copyright © 2020 pplingo. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSMutableDictionary (WeakRef)

-(void)w_setObject:(id)anObject forKey:(id<NSCopying>)aKey;

- (id)w_objectForKey:(id)aKey;

@end

NS_ASSUME_NONNULL_END
