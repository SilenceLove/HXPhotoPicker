//
//  HXVideoPresentTransition.m
//  微博照片选择
//
//  Created by 洪欣 on 17/2/22.
//  Copyright © 2017年 洪欣. All rights reserved.
//

#import "HXVideoPresentTransition.h"

@interface HXVideoPresentTransition ()
@property (assign, nonatomic) HXVideoPresentTransitionType type;
@end

@implementation HXVideoPresentTransition

+ (instancetype)transitionWithTransitionType:(HXVideoPresentTransitionType)type
{
    return [[self alloc] initWithTransitionType:type];
}

- (instancetype)initWithTransitionType:(HXVideoPresentTransitionType)type
{
    if (self = [super init]) {
        self.type = type;
    }
    return self;
}

- (NSTimeInterval)transitionDuration:(id<UIViewControllerContextTransitioning>)transitionContext{
    return 0.4;
}

- (void)animateTransition:(id<UIViewControllerContextTransitioning>)transitionContext{
    switch (_type) {
        case HXVideoPresentTransitionPresent:
            [self presentAnimation:transitionContext];
            break;
            
        case HXVideoPresentTransitionDismiss:
            [self dismissAnimation:transitionContext];
            break;
    }
}

/**
 *  实现present动画
 */
- (void)presentAnimation:(id<UIViewControllerContextTransitioning>)transitionContext{
    //通过viewControllerForKey取出转场前后的两个控制器，这里toVC就是vc1、fromVC就是vc2
    UIViewController *toVC = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
    UIViewController *fromVC = [transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
    
    UIView *tempView = [fromVC.view snapshotViewAfterScreenUpdates:NO];
    tempView.frame = fromVC.view.frame;
    
    fromVC.view.hidden = YES;
    //这里有个重要的概念containerView，如果要对视图做转场动画，视图就必须要加入containerView中才能进行，可以理解containerView管理者所有做转场动画的视图
    UIView *containerView = [transitionContext containerView];
 
    //将视图和vc2的view都加入ContainerView中
    [containerView addSubview:toVC.view];
    [containerView addSubview:tempView];
    CGFloat width = [UIScreen mainScreen].bounds.size.width;
    CGFloat height = [UIScreen mainScreen].bounds.size.height;
    toVC.view.frame = CGRectMake(0, -height, width, height);
    
    [UIView animateWithDuration:[self transitionDuration:transitionContext] animations:^{
        tempView.frame = CGRectMake(0, height, width, height);
        toVC.view.frame = CGRectMake(0, 0, width, height);
    } completion:^(BOOL finished) {
        [tempView removeFromSuperview];
        fromVC.view.hidden = NO;
        [transitionContext completeTransition:YES];
    }];
}

/**
 *  实现dimiss动画
 */
- (void)dismissAnimation:(id<UIViewControllerContextTransitioning>)transitionContext{
    UIViewController *fromVC = [transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
    UIViewController *toVC = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
    //参照present动画的逻辑，present成功后，containerView的最后一个子视图就是截图视图，我们将其取出准备动画
    UIView *containerView = [transitionContext containerView];
    UIView *tempView = [toVC.view snapshotViewAfterScreenUpdates:NO];
    CGFloat width = [UIScreen mainScreen].bounds.size.width;
    CGFloat height = [UIScreen mainScreen].bounds.size.height;
    tempView.frame = CGRectMake(0, height, width, height);
    [containerView addSubview:tempView];
    toVC.view.hidden = YES;
    //动画吧
    [UIView animateWithDuration:[self transitionDuration:transitionContext] animations:^{
        fromVC.view.frame = CGRectMake(0, -height, width, height);
        tempView.frame = CGRectMake(0, 0, width, height);
    } completion:^(BOOL finished) {
        [tempView removeFromSuperview];
        toVC.view.hidden = NO;
        [transitionContext completeTransition:YES];
    }];
}

@end
