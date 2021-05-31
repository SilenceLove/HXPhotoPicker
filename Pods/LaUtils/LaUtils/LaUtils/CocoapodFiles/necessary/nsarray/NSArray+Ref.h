//
//  NSArray+Ref.h
//  student
//
//  Created by taomingyan on 2020/11/8.
//  Copyright © 2020 pplingo. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

#define M_VerifyArray(array) (([[(array) class] isSubclassOfClass:[NSArray class]])?(array):@[])

@interface NSArray (Ref)

//获取数组中的某个元素 index为元素的索引值
//不越界返回该数组元素，越界返回nil
-(id)s_objectAtIndex:(NSInteger)index;

@end

NS_ASSUME_NONNULL_END
