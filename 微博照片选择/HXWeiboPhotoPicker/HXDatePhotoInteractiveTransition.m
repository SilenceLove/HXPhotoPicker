//
//  HXDatePhotoInteractiveTransition.m
//  微博照片选择
//
//  Created by 洪欣 on 2017/10/28.
//  Copyright © 2017年 洪欣. All rights reserved.
//

#import "HXDatePhotoInteractiveTransition.h"
#import "HXDatePhotoPreviewViewController.h"
#import "HXDatePhotoViewController.h"
#import "HXDatePhotoPreviewBottomView.h"
@interface HXDatePhotoInteractiveTransition ()
@property (nonatomic, weak) id<UIViewControllerContextTransitioning> transitionContext;
@property (nonatomic, weak) UIViewController *vc;
@property (strong, nonatomic) UIImageView *imageView;
@property (strong, nonatomic) UIView *bgView;
@property (weak, nonatomic) HXDatePhotoViewCell *tempCell;
@property (strong, nonatomic) UIImageView *tempImageView;
@property (nonatomic, assign) CGPoint transitionImgViewCenter;
@property (nonatomic, assign) CGFloat transitionImgViewY;
@property (nonatomic, assign) CGFloat transitionImgViewX;
@end

@implementation HXDatePhotoInteractiveTransition
- (void)addPanGestureForViewController:(UIViewController *)viewController{
    UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(gestureRecognizeDidUpdate:)];
    self.vc = viewController;
    [viewController.view addGestureRecognizer:pan];
}
- (void)gestureRecognizeDidUpdate:(UIPanGestureRecognizer *)gestureRecognizer {
    CGFloat scale = 0;
    
    CGPoint translation = [gestureRecognizer translationInView:gestureRecognizer.view];
    CGFloat transitionY = translation.y;
    scale = transitionY / ((gestureRecognizer.view.frame.size.height - 50) / 2);
    if (scale > 1.f) {
        scale = 1.f;
    }
    switch (gestureRecognizer.state) {
        case UIGestureRecognizerStateBegan:
            if (scale < 0) {
                [gestureRecognizer cancelsTouchesInView];
                return;
            }
            if (![(HXDatePhotoPreviewViewController *)self.vc bottomView].userInteractionEnabled && iOS11_Later) {
                [(HXDatePhotoPreviewViewController *)self.vc setSubviewAlphaAnimate:NO];
            }
            self.interation = YES;
            [self.vc.navigationController popViewControllerAnimated:YES];
            break;
        case UIGestureRecognizerStateChanged:
            if (self.interation) {
                if (scale < 0.f) {
                    scale = 0.f;
                }
                CGFloat imageViewScale = 1 - scale * 0.5 * 0.5;
                if (imageViewScale < 0.5) {
                    imageViewScale = 0.5;
                }
                self.tempImageView.center = CGPointMake(self.transitionImgViewCenter.x + translation.x, self.transitionImgViewCenter.y + translation.y);
                self.tempImageView.transform = CGAffineTransformMakeScale(imageViewScale, imageViewScale);
                self.tempImageView.hx_y = self.transitionImgViewY + translation.y;
//                self.tempImageView.hx_x = self.transitionImgViewX + translation.x;
                
                [self updateInterPercent:1 - scale * scale];
                
                [self updateInteractiveTransition:scale];
            }
            break;
        case UIGestureRecognizerStateEnded:
            if (self.interation) {
                if (scale < 0.f) {
                    scale = 0.f;
                }
                self.interation = NO;
                if (scale < 0.15f){
                    [self cancelInteractiveTransition];
                    [self interPercentCancel];
                }else {
                    [self finishInteractiveTransition];
                    [self interPercentFinish];
                }
            }
            break;
        default:
            if (self.interation) {
                self.interation = NO;
                [self cancelInteractiveTransition];
                [self interPercentCancel];
            }
            break;
    }
}
- (void)beginInterPercent{
    id<UIViewControllerContextTransitioning> transitionContext = self.transitionContext;
    
    HXDatePhotoPreviewViewController *fromVC = (HXDatePhotoPreviewViewController *)[transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
    
    HXDatePhotoViewController *toVC = (HXDatePhotoViewController *)[transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
    
    HXPhotoModel *model = [fromVC.modelArray objectAtIndex:fromVC.currentModelIndex];
    
    HXDatePhotoPreviewViewCell *fromCell = [fromVC currentPreviewCell:model];
    HXDatePhotoViewCell *toCell = [toVC currentPreviewCell:model];
    
    self.tempImageView = [[UIImageView alloc] initWithImage:fromCell.imageView.image];
    self.tempImageView.clipsToBounds = YES;
    self.tempImageView.contentMode = UIViewContentModeScaleAspectFill;
    BOOL contains = YES;
    if (!toCell) {
        contains = [toVC scrollToModel:model];
        toCell = [toVC currentPreviewCell:model];
    }
    UIView *containerView = [transitionContext containerView];
    self.bgView = [[UIView alloc] initWithFrame:containerView.bounds];
    self.bgView.backgroundColor = [UIColor whiteColor];
    self.tempImageView.frame = [fromCell.imageView convertRect:fromCell.imageView.bounds toView:containerView];
    self.transitionImgViewCenter = self.tempImageView.center;
    self.transitionImgViewY = self.tempImageView.hx_y;
    self.transitionImgViewX = self.tempImageView.hx_x;
    [containerView addSubview:toVC.view];
    [containerView addSubview:fromVC.view];
    [toVC.view insertSubview:self.bgView belowSubview:toVC.bottomView];
    [toVC.view insertSubview:self.tempImageView belowSubview:toVC.bottomView];
    if (!fromVC.bottomView.userInteractionEnabled) {
        self.bgView.backgroundColor = [UIColor blackColor];
        [[UIApplication sharedApplication] setStatusBarHidden:NO];
        [toVC.navigationController setNavigationBarHidden:NO];
        toVC.navigationController.navigationBar.alpha = 0;
        toVC.bottomView.alpha = 0;
    }else {
        self.bgView.backgroundColor = [UIColor whiteColor];
    }
    toVC.navigationController.navigationBar.userInteractionEnabled = NO;
    fromVC.collectionView.hidden = YES;
    toCell.hidden = YES;
    fromVC.view.backgroundColor = [UIColor clearColor];
    
    CGRect rect = [toCell.imageView convertRect:toCell.imageView.bounds toView: containerView];
    if (toCell) {
        [toVC scrollToPoint:toCell rect:rect];
    }
    self.tempCell = toCell;
}
- (void)updateInterPercent:(CGFloat)scale{
    HXDatePhotoPreviewViewController *fromVC = (HXDatePhotoPreviewViewController *)[self.transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
    fromVC.view.alpha = scale;
    self.bgView.alpha = fromVC.view.alpha;
    
    if (!fromVC.bottomView.userInteractionEnabled) {
        HXDatePhotoViewController *toVC = (HXDatePhotoViewController *)[self.transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
        toVC.bottomView.alpha = 1 - scale;
        toVC.navigationController.navigationBar.alpha = 1 - scale;
    }
}
- (void)interPercentCancel{
    id<UIViewControllerContextTransitioning> transitionContext = self.transitionContext;
    HXDatePhotoPreviewViewController *fromVC = (HXDatePhotoPreviewViewController *)[transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
    HXDatePhotoViewController *toVC = (HXDatePhotoViewController *)[self.transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
    if (!fromVC.bottomView.userInteractionEnabled) {
        [[UIApplication sharedApplication] setStatusBarHidden:YES];
        [toVC.navigationController setNavigationBarHidden:YES];
        toVC.navigationController.navigationBar.alpha = 1;
    }
    [UIView animateWithDuration:0.2f animations:^{
        fromVC.view.alpha = 1;
        self.tempImageView.transform = CGAffineTransformIdentity;
        self.tempImageView.center = self.transitionImgViewCenter;
        self.bgView.alpha = 1;
        if (!fromVC.bottomView.userInteractionEnabled) {
            toVC.bottomView.alpha = 0;
        }
    } completion:^(BOOL finished) {
        toVC.navigationController.navigationBar.userInteractionEnabled = YES;
        fromVC.collectionView.hidden = NO;
        if (!fromVC.bottomView.userInteractionEnabled) {
            fromVC.view.backgroundColor = [UIColor blackColor];
        }else {
            fromVC.view.backgroundColor = [UIColor whiteColor];
        }
        self.tempCell.hidden = NO;
        self.tempCell = nil;
        [self.tempImageView removeFromSuperview];
        [self.bgView removeFromSuperview];
        self.bgView = nil;
        [transitionContext completeTransition:![transitionContext transitionWasCancelled]];
    }];
}
//完成
- (void)interPercentFinish {
    id<UIViewControllerContextTransitioning> transitionContext = self.transitionContext;
    UIView *containerView = [transitionContext containerView];
    HXDatePhotoPreviewViewController *fromVC = (HXDatePhotoPreviewViewController *)[transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
    HXDatePhotoViewController *toVC = (HXDatePhotoViewController *)[self.transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
    NSTimeInterval duration = fromVC.manager.configuration.popInteractiveTransitionDuration;
    UIViewAnimationOptions option = fromVC.manager.configuration.transitionAnimationOption;
    
    [UIView animateWithDuration:duration delay:0.0 usingSpringWithDamping:0.8 initialSpringVelocity:0.1 options:option animations:^{
        if (self.tempCell) {
            self.tempImageView.frame = [self.tempCell.imageView convertRect:self.tempCell.imageView.bounds toView: containerView];
        }else {
            self.tempImageView.center = self.transitionImgViewCenter;
            self.tempImageView.alpha = 0;
            self.tempImageView.transform = CGAffineTransformMakeScale(0.3, 0.3);
        }
        fromVC.view.alpha = 0;
        self.bgView.alpha = 0;
        toVC.navigationController.navigationBar.alpha = 1;
        toVC.bottomView.alpha = 1;
    }completion:^(BOOL finished) {
        toVC.navigationController.navigationBar.userInteractionEnabled = YES;
        [self.tempCell bottomViewPrepareAnimation];
        self.tempCell.hidden = NO;
        [self.tempCell bottomViewStartAnimation];
        [self.tempImageView removeFromSuperview];
        [self.bgView removeFromSuperview];

        [transitionContext completeTransition:![transitionContext transitionWasCancelled]];
    }];
    
}
- (void)startInteractiveTransition:(id<UIViewControllerContextTransitioning>)transitionContext {
    self.transitionContext = transitionContext;
    [self beginInterPercent];
}
@end
