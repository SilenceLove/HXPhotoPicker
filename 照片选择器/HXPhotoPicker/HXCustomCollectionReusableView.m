//
//  HXCustomCollectionReusableView.m
//  照片选择器
//
//  Created by 洪欣 on 2017/11/8.
//  Copyright © 2017年 洪欣. All rights reserved.
//

#import "HXCustomCollectionReusableView.h"

#ifdef __IPHONE_11_0
@implementation HXCustomLayer

- (CGFloat)zPosition {
    return 0;
}

@end
#endif

@implementation HXCustomCollectionReusableView
#ifdef __IPHONE_11_0
+ (Class)layerClass {
    return [HXCustomLayer class];
}
#endif
@end
