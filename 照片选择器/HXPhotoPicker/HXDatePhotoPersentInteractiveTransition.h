//
//  HXDatePhotoPersentInteractiveTransition.h
//  照片选择器
//
//  Created by 洪欣 on 2018/9/8.
//  Copyright © 2018年 洪欣. All rights reserved.
//

#import <UIKit/UIKit.h>

@class HXPhotoView;
@interface HXDatePhotoPersentInteractiveTransition : UIPercentDrivenInteractiveTransition
@property (nonatomic, assign) BOOL interation;
- (void)addPanGestureForViewController:(UIViewController *)viewController photoView:(HXPhotoView *)photoView ;
@end
