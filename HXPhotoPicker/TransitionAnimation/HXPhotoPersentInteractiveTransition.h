//
//  HXPhotoPersentInteractiveTransition.h
//  HXPhotoPickerExample
//
//  Created by Silence on 2018/9/8.
//  Copyright © 2018年 Silence. All rights reserved.
//

#import <UIKit/UIKit.h>

@class HXPhotoView;
@interface HXPhotoPersentInteractiveTransition : UIPercentDrivenInteractiveTransition
@property (nonatomic, assign) BOOL interation;
@property (assign, nonatomic) BOOL atFirstPan;
- (void)addPanGestureForViewController:(UIViewController *)viewController photoView:(HXPhotoView *)photoView ;
@end
