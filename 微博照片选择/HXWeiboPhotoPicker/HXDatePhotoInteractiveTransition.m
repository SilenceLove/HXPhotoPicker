//
//  HXDatePhotoInteractiveTransition.m
//  微博照片选择
//
//  Created by 洪欣 on 2017/10/28.
//  Copyright © 2017年 洪欣. All rights reserved.
//

#import "HXDatePhotoInteractiveTransition.h"

@interface HXDatePhotoInteractiveTransition ()
@property (nonatomic, weak) UIViewController *vc;
@end

@implementation HXDatePhotoInteractiveTransition

- (void)addPanGestureForViewController:(UIViewController *)viewController{
    UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handleGesture:)];
    self.vc = viewController;
    [viewController.view addGestureRecognizer:pan];
}
/**
 *  手势过渡的过程
 */
- (void)handleGesture:(UIPanGestureRecognizer *)panGesture{
    //手势百分比
    CGFloat persent = 0;
    
    CGFloat transitionY = [panGesture translationInView:panGesture.view].y;
    persent = transitionY / panGesture.view.frame.size.width;
    if (persent > 1.f) {
        persent = 1.f;
    }
    switch (panGesture.state) {
        case UIGestureRecognizerStateBegan:
            if (transitionY < 0) {
                [self cancelInteractiveTransition];
                return;
            }
            //手势开始的时候标记手势状态，并开始相应的事件
            self.interation = YES;
            [self startGesture];
            break;
        case UIGestureRecognizerStateChanged:{
            if (persent < 0) {
                persent = 0;
            }
            //手势过程中，通过updateInteractiveTransition设置pop过程进行的百分比
            [self updateInteractiveTransition:persent];
            break;
        }
        case UIGestureRecognizerStateEnded:{
            //手势完成后结束标记并且判断移动距离是否过半，过则finishInteractiveTransition完成转场操作，否者取消转场操作
            self.interation = NO;
            if (transitionY < 0) {
                [self cancelInteractiveTransition];
            }else {
                [self finishInteractiveTransition];
            }
            break;
        }
        default:
            break;
    }
}
- (void)startGesture{
    [self.vc.navigationController popViewControllerAnimated:YES];
}
@end
