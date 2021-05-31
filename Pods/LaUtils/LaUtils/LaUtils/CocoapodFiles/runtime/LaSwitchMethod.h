//
//  LaSwitchMethod.h
//  student
//
//  Created by taomingyan on 2020/11/10.
//  Copyright © 2020 pplingo. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface LaSwitchMethod : NSObject

+(void)switchClass:(Class)o_class selector:(SEL)o_selector withTargetClass:(Class)t_class targetSelector:(SEL)t_selector;
@end

NS_ASSUME_NONNULL_END
