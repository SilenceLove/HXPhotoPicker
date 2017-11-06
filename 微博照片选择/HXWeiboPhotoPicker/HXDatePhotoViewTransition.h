//
//  HXDatePhotoViewTransition.h
//  微博照片选择
//
//  Created by 洪欣 on 2017/10/27.
//  Copyright © 2017年 洪欣. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef enum : NSUInteger {
    HXDatePhotoViewTransitionTypePush = 0,
    HXDatePhotoViewTransitionTypePop = 1,
} HXDatePhotoViewTransitionType;

@interface HXDatePhotoViewTransition : NSObject<UIViewControllerAnimatedTransitioning>
+ (instancetype)transitionWithType:(HXDatePhotoViewTransitionType)type;
- (instancetype)initWithTransitionType:(HXDatePhotoViewTransitionType)type;
@end

