//
//  HXPresentTransition.h
//  微博照片选择
//
//  Created by 洪欣 on 17/2/21.
//  Copyright © 2017年 洪欣. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSUInteger, HXPresentTransitionType) {
    HXPresentTransitionTypePresent = 0,
    HXPresentTransitionTypeDismiss
};

typedef NS_ENUM(NSUInteger, HXPresentTransitionVcType) {
    HXPresentTransitionVcTypePhoto = 0,
    HXPresentTransitionVcTypeVideo
};

@interface HXPresentTransition : NSObject<UIViewControllerAnimatedTransitioning>

+ (instancetype)transitionWithTransitionType:(HXPresentTransitionType)type VcType:(HXPresentTransitionVcType)vcType;

- (instancetype)initWithTransitionType:(HXPresentTransitionType)type VcType:(HXPresentTransitionVcType)vcType;

@end
