//
//  LaSwitchMethod.m
//  student
//
//  Created by taomingyan on 2020/11/10.
//  Copyright © 2020 pplingo. All rights reserved.
//

#import "LaSwitchMethod.h"
#import <objc/runtime.h>

static void replaceClass(Class paramOriClass, SEL paramOriSel, Class paramReplaceClass, SEL paramReplaceSEL)
{
    Method m1 = class_getInstanceMethod(paramOriClass, paramOriSel);
    
    Method m2 = class_getInstanceMethod(paramReplaceClass, paramReplaceSEL);
    method_exchangeImplementations(m1, m2);
}

@implementation LaSwitchMethod

+(void)switchClass:(Class)o_class selector:(SEL)o_selector withTargetClass:(Class)t_class targetSelector:(SEL)t_selector{
    replaceClass(o_class, o_selector, t_class, t_selector);
}
@end
