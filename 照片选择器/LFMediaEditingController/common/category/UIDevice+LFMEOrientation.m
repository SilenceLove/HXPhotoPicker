//
//  UIDevice+LFOrientation.m
//  LFImagePickerController
//
//  Created by LamTsanFeng on 2017/4/26.
//  Copyright © 2017年 LamTsanFeng. All rights reserved.
//

#import "UIDevice+LFMEOrientation.h"

@implementation UIDevice (LFMEOrientation)

//调用私有方法实现
+ (void)LFME_setOrientation:(UIInterfaceOrientation)orientation {
    SEL selector = NSSelectorFromString([NSString stringWithFormat:@"%@%@%@", @"se",@"tOr",@"ientation:"]);
    if ([[self currentDevice] respondsToSelector:selector]) {        
        NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:[self instanceMethodSignatureForSelector:selector]];
        [invocation setSelector:selector];
        [invocation setTarget:[self currentDevice]];
        int val = orientation;
        [invocation setArgument:&val atIndex:2];
        [invocation invoke];
    }
}

@end
