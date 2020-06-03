//
//  HXPhotoViewTransition.h
//  照片选择器
//
//  Created by 洪欣 on 2017/10/27.
//  Copyright © 2017年 洪欣. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef enum : NSUInteger {
    HXPhotoViewTransitionTypePush = 0,
    HXPhotoViewTransitionTypePop = 1,
} HXPhotoViewTransitionType;

@interface HXPhotoViewTransition : NSObject<UIViewControllerAnimatedTransitioning>
+ (instancetype)transitionWithType:(HXPhotoViewTransitionType)type;
- (instancetype)initWithTransitionType:(HXPhotoViewTransitionType)type;
@end

