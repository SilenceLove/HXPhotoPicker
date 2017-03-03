//
//  HXNaviTransition.h
//  微博照片选择
//
//  Created by 洪欣 on 17/2/9.
//  Copyright © 2017年 洪欣. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSUInteger, HXTransitionType) {
    HXTransitionTypePush = 0,
    HXTransitionTypePop
};

typedef NS_ENUM(NSUInteger, HXTransitionVcType) {
    HXTransitionVcTypePhoto = 0,
    HXTransitionVcTypeVideo
};

@interface HXTransition : NSObject<UIViewControllerAnimatedTransitioning>
+ (instancetype)transitionWithType:(HXTransitionType)type VcType:(HXTransitionVcType)vcType;
- (instancetype)initWithTransitionType:(HXTransitionType)type VcType:(HXTransitionVcType)vcType;
@end
