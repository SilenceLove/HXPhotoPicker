//
//  HXVideoPresentTransition.h
//  微博照片选择
//
//  Created by 洪欣 on 17/2/22.
//  Copyright © 2017年 洪欣. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSUInteger, HXVideoPresentTransitionType) {
    HXVideoPresentTransitionPresent = 0,
    HXVideoPresentTransitionDismiss
};

@interface HXVideoPresentTransition : NSObject<UIViewControllerAnimatedTransitioning>
+ (instancetype)transitionWithTransitionType:(HXVideoPresentTransitionType)type;

- (instancetype)initWithTransitionType:(HXVideoPresentTransitionType)type;
@end
