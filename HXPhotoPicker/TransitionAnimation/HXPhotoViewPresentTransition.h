//
//  HXPhotoViewPresentTransition.h
//  HXPhotoPickerExample
//
//  Created by Silence on 2017/10/28.
//  Copyright © 2017年 Silence. All rights reserved.
//

#import <UIKit/UIKit.h>
typedef enum : NSUInteger {
    HXPhotoViewPresentTransitionTypePresent = 0,
    HXPhotoViewPresentTransitionTypeDismiss = 1,
} HXPhotoViewPresentTransitionType;
@class HXPhotoView;
@interface HXPhotoViewPresentTransition : NSObject<UIViewControllerAnimatedTransitioning>
+ (instancetype)transitionWithTransitionType:(HXPhotoViewPresentTransitionType)type photoView:(HXPhotoView *)photoView;

- (instancetype)initWithTransitionType:(HXPhotoViewPresentTransitionType)type photoView:(HXPhotoView *)photoView;
@end
