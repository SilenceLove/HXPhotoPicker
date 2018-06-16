//
//  HXDatePhotoViewPresentTransition.h
//  照片选择器
//
//  Created by 洪欣 on 2017/10/28.
//  Copyright © 2017年 洪欣. All rights reserved.
//

#import <UIKit/UIKit.h>
typedef enum : NSUInteger {
    HXDatePhotoViewPresentTransitionTypePresent = 0,
    HXDatePhotoViewPresentTransitionTypeDismiss = 1,
} HXDatePhotoViewPresentTransitionType;
@class HXPhotoView;
@interface HXDatePhotoViewPresentTransition : NSObject<UIViewControllerAnimatedTransitioning>
+ (instancetype)transitionWithTransitionType:(HXDatePhotoViewPresentTransitionType)type photoView:(HXPhotoView *)photoView;

- (instancetype)initWithTransitionType:(HXDatePhotoViewPresentTransitionType)type photoView:(HXPhotoView *)photoView;
@end
