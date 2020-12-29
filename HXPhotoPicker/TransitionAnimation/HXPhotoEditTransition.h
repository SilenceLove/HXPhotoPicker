//
//  HXPhotoEditTransition.h
//  HXPhotoPickerExample
//
//  Created by Silence on 2019/1/20.
//  Copyright © 2019年 Silence. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, HXPhotoEditTransitionType) {
    HXPhotoEditTransitionTypePresent,
    HXPhotoEditTransitionTypeDismiss
};
@class HXPhotoModel;
@interface HXPhotoEditTransition : NSObject<UIViewControllerAnimatedTransitioning>
+ (instancetype)transitionWithType:(HXPhotoEditTransitionType)type model:(HXPhotoModel *)model;
@end

NS_ASSUME_NONNULL_END
