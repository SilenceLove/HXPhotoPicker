//
//  NSMutableArray+WeakRef.h
//  Runner
//
//  Created by taomingyan on 2020/10/30.
//  Copyright © 2020 The Chromium Authors. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

//数组中的引用为弱引用
@interface NSMutableArray (WeakRef)

//数组添加一个元素 当anObject不为空的时候添加，为空不做任何事
- (void)w_addObject:(id)anObject;

//数组删除一个元素 当anObject不为空的时候删除，为空不做任何事
- (void)w_removeObject:(id)anObject;

//获取数组中的某个元素 index为元素的索引值
//不越界返回该数组元素，越界返回nil
-(id)w_objectAtIndex:(NSInteger)index;

//插入anObject 不为空 index不越界插入该元素，否则不做任何事
- (void)w_insertObject:(id)anObject atIndex:(NSUInteger)index;

//index不越界删除该元素，否则不做任何事
- (void)w_removeObjectAtIndex:(NSUInteger)index;

//替换anObject 不为空 index不越界替换该元素，否则不做任何事
-(void)w_replaceObjectAtIndex:(NSUInteger)index withObject:(id)anObject;
@end

NS_ASSUME_NONNULL_END
