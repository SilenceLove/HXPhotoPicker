//
//  HXPhotoInteractiveTransition.m
//  HXPhotoPickerExample
//
//  Created by Silence on 2017/10/28.
//  Copyright © 2017年 Silence. All rights reserved.
//

#import "HXPhotoInteractiveTransition.h"
#import "HXPhotoPreviewViewController.h"
#import "HXPhotoViewController.h"
#import "HXPhotoPreviewBottomView.h"
@interface HXPhotoInteractiveTransition ()<UIGestureRecognizerDelegate>
@property (nonatomic, weak) id<UIViewControllerContextTransitioning> transitionContext;
@property (nonatomic, weak) HXPhotoPreviewViewController *vc;
@property (nonatomic, weak) HXPhotoViewController *toVC;
@property (strong, nonatomic) UIView *bgView;
@property (weak, nonatomic) HXPhotoViewCell *tempCell;
@property (weak, nonatomic) HXPhotoPreviewViewCell *fromCell;
@property (assign, nonatomic) CGRect imageInitialFrame;
@property (assign, nonatomic) CGPoint transitionImgViewCenter;
@property (assign, nonatomic) CGFloat beginX;
@property (assign, nonatomic) CGFloat beginY;
@property (assign, nonatomic) CGPoint slidingGap;
@property (strong, nonatomic) UIPanGestureRecognizer *panGesture;
@property (assign, nonatomic) BOOL startPop;
@property (assign, nonatomic) BOOL isFinished;
@property (assign, nonatomic) BOOL beginInterPercentCompletion;
@end

@implementation HXPhotoInteractiveTransition
- (void)addPanGestureForViewController:(UIViewController *)viewController {
    self.panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(gestureRecognizeDidUpdate:)];
    self.slidingGap = CGPointZero;
    self.panGesture.delegate = self;
    self.vc = (HXPhotoPreviewViewController *)viewController;
    [viewController.view addGestureRecognizer:self.panGesture];
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    return !self.vc.collectionView.isDragging;
}
- (void)gestureRecognizeDidUpdate:(UIPanGestureRecognizer *)gestureRecognizer {
    if (self.isFinished) {
        return;
    }
    BOOL isTracking = NO;
    HXPhotoPreviewViewCell *cell = [self.vc currentPreviewCell];
    CGRect toRect = [cell.previewContentView convertRect:cell.previewContentView.bounds toView:cell.scrollView];
    if ((cell.scrollView.isZooming || cell.scrollView.contentOffset.y > 0 || cell.scrollView.isZoomBouncing || !cell.allowInteration || (toRect.origin.x != 0 && cell.previewContentView.hx_w > cell.scrollView.hx_w)) && !self.interation) {
        return;
    }else {
        isTracking = cell.scrollView.isTracking;
    }
    switch (gestureRecognizer.state) {
        case UIGestureRecognizerStateBegan: {
            [self panGestureBegan:gestureRecognizer];
        }   break;
        case UIGestureRecognizerStateChanged:
            if (!self.interation || !self.beginInterPercentCompletion) {
                if (isTracking) {
                    [self panGestureBegan:gestureRecognizer];
                    if (self.interation) {
                        self.slidingGap = [gestureRecognizer translationInView:gestureRecognizer.view];
                    }
                }
                return;
            }
            [self panGestureChanged:gestureRecognizer];
            break;
        case UIGestureRecognizerStateEnded:
            self.startPop = NO;
            [self panGestureEnd:gestureRecognizer];
            self.slidingGap = CGPointZero;
            break;
        default:
            self.startPop = NO;
            [self panGestureOther:gestureRecognizer];
            self.slidingGap = CGPointZero;
            break;
    }
}
- (CGFloat)panGestureScale:(UIPanGestureRecognizer *)panGesture {
    CGPoint translation = [panGesture translationInView:panGesture.view];
    CGFloat transitionY = translation.y;
    CGFloat scale = (transitionY - self.slidingGap.y) / ((panGesture.view.frame.size.height - 50) / 2);
    if (scale > 1.f) {
        scale = 1.f;
    }
    return scale;
}
- (void)panGestureBegan:(UIPanGestureRecognizer *)panGesture {
    if (self.interation || self.beginInterPercentCompletion || self.startPop) {
        return;
    }
    HXPhotoPreviewViewController *previewVC = (HXPhotoPreviewViewController *)self.vc;
    CGPoint velocity = [panGesture velocityInView:previewVC.view];
    BOOL isVerticalGesture = (fabs(velocity.y) > fabs(velocity.x) && velocity.y > 0);
    if (!isVerticalGesture) {
        return;
    }
    [previewVC setStopCancel:YES];
    self.beginX = [panGesture locationInView:panGesture.view].x;
    self.beginY = [panGesture locationInView:panGesture.view].y;
    self.interation = YES;
    self.beginInterPercentCompletion = NO;
    self.startPop = YES;
    [self.vc.navigationController popViewControllerAnimated:YES];
}
- (void)panGestureChanged:(UIPanGestureRecognizer *)panGesture {
    if (self.interation && self.beginInterPercentCompletion) {
        CGFloat scale = [self panGestureScale:panGesture];
        if (scale < 0.f) {
            scale = 0.f;
        }
        CGPoint translation = [panGesture translationInView:panGesture.view];
        CGFloat imageViewScale = 1 - scale * 0.5;
        if (imageViewScale < 0.4) {
            imageViewScale = 0.4;
        }
        self.fromCell.center = CGPointMake(self.transitionImgViewCenter.x + (translation.x - self.slidingGap.x), self.transitionImgViewCenter.y + (translation.y - self.slidingGap.y));
        self.fromCell.transform = CGAffineTransformMakeScale(imageViewScale, imageViewScale);
        
        [self updateInterPercent:1 - scale * scale];
        
        [self updateInteractiveTransition:scale];
    }
}
- (void)panGestureEnd:(UIPanGestureRecognizer *)panGesture {
    
    if (self.interation) {
        CGFloat scale = [self panGestureScale:panGesture];
        if (scale < 0.f) {
            scale = 0.f;
        }
        if (scale < 0.15f){
            [self cancelInteractiveTransition];
            [self interPercentCancel];
        }else {
            self.isFinished = YES;
            [self finishInteractiveTransition];
            [self interPercentFinish];
        }
    }
}
- (void)panGestureOther:(UIPanGestureRecognizer *)panGesture {
    self.vc.view.userInteractionEnabled = YES;
    if (self.interation) {
        [self cancelInteractiveTransition];
        [self interPercentCancel];
    }
}
- (void)beginInterPercent {
    id<UIViewControllerContextTransitioning> transitionContext = self.transitionContext;
    
    HXPhotoPreviewViewController *fromVC = (HXPhotoPreviewViewController *)[transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
    
    HXPhotoViewController *toVC = (HXPhotoViewController *)[transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
    UIView *containerView = [transitionContext containerView];
    [containerView addSubview:toVC.view];
    [containerView addSubview:fromVC.view];
    if (!self.startPop) {
        self.interation = NO;
        [self.vc.view removeGestureRecognizer:self.panGesture];
        self.isFinished = YES;
        [self cancelInteractiveTransition];
        NSTimeInterval duration = fromVC.manager.configuration.popInteractiveTransitionDuration;
        UIViewAnimationOptions option = UIViewAnimationOptionLayoutSubviews;
        [UIView animateWithDuration:duration delay:0 options:option animations:^{
        } completion:^(BOOL finished) {
            [self.transitionContext completeTransition:NO];
            self.isFinished = NO;
            [self.vc.view addGestureRecognizer:self.panGesture];
        }];
        return;
    }
    HXPhotoModel *model = [fromVC.modelArray objectAtIndex:fromVC.currentModelIndex];
    HXPhotoPreviewViewCell *fromCell = [fromVC currentPreviewCell:model];
    HXPhotoViewCell *toCell = [toVC currentPreviewCell:model];
    self.fromCell = fromCell;
    CGRect tempImageViewFrame;
    self.imageInitialFrame = fromCell.frame;
    tempImageViewFrame = [fromCell convertRect:fromCell.bounds toView:containerView];
    if (!toCell) {
        [toVC scrollToModel:model];
        toCell = [toVC currentPreviewCell:model];
    }
    self.bgView = [[UIView alloc] initWithFrame:containerView.bounds];
    self.bgView.backgroundColor = [HXPhotoCommon photoCommon].isDark ? [UIColor blackColor] : fromVC.manager.configuration.previewPhotoViewBgColor;
    CGFloat scaleX;
    CGFloat scaleY;
    if (self.beginX < tempImageViewFrame.origin.x) {
        scaleX = 0;
    }else if (self.beginX > CGRectGetMaxX(tempImageViewFrame)) {
        scaleX = 1.0f;
    }else {
        scaleX = (self.beginX - tempImageViewFrame.origin.x) / tempImageViewFrame.size.width;
    }
    if (self.beginY < tempImageViewFrame.origin.y) {
        scaleY = 0;
    }else if (self.beginY > CGRectGetMaxY(tempImageViewFrame)){
        scaleY = 1.0f;
    }else {
        scaleY = (self.beginY - tempImageViewFrame.origin.y) / tempImageViewFrame.size.height;
    }
    self.fromCell.layer.anchorPoint = CGPointMake(scaleX, scaleY);
    self.fromCell.frame = tempImageViewFrame;
    self.transitionImgViewCenter = self.fromCell.center;
    [toVC.view insertSubview:self.bgView belowSubview:toVC.bottomView];
    [toVC.view insertSubview:self.fromCell belowSubview:toVC.bottomView];
    if (!fromVC.bottomView.userInteractionEnabled) {
        self.bgView.backgroundColor = [UIColor blackColor];
#pragma clang diagnostic push
#pragma clang diagnostic ignored"-Wdeprecated-declarations"
        [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationFade];
#pragma clang diagnostic pop
        
        if (HX_IOS11_Later) {
            // 处理 ios11 当导航栏隐藏时手势返回的问题
            [toVC.navigationController.navigationBar.layer removeAllAnimations];
            // 找到动画异常的视图，然后移除layer动画 ！！！！！
            // 一层一层的慢慢的找,把每个有动画的全部移除
            [self removeAllAnimationsForView:toVC.navigationController.navigationBar];
            [toVC.navigationController setNavigationBarHidden:NO animated:YES];
        }else {
            [toVC.navigationController setNavigationBarHidden:NO];
        }
        toVC.navigationController.navigationBar.alpha = 0;
        toVC.bottomView.alpha = 0;
        toVC.limitView.alpha = 0;
    }else {
        toVC.limitView.alpha = 1;
        toVC.bottomView.alpha = 1;
        self.bgView.backgroundColor = [HXPhotoCommon photoCommon].isDark ? [UIColor blackColor] : fromVC.manager.configuration.previewPhotoViewBgColor;
    }
//    toVC.navigationController.navigationBar.userInteractionEnabled = NO;
    self.toVC = toVC;
    fromVC.collectionView.hidden = YES;
    toCell.hidden = YES;
    fromVC.view.backgroundColor = [UIColor clearColor];
    
    CGRect rect = [toCell.imageView convertRect:toCell.imageView.bounds toView: containerView];
    if (toCell) {
        [toVC scrollToPoint:toCell rect:rect];
    }
    self.tempCell = toCell;
    if (self.fromCell.previewContentView.model.subType == HXPhotoModelMediaSubTypeVideo) {
        [self.fromCell.previewContentView.videoView hideOtherView:YES];
    }
    [self resetScrollView:NO];
    self.beginInterPercentCompletion = YES;
}
- (void)removeAllAnimationsForView:(UIView *)view {
    for (UIView *navBarView in view.subviews) {
        [navBarView.layer removeAllAnimations];
        for (UIView *navBarSubView in navBarView.subviews) {
            [navBarSubView.layer removeAllAnimations];
            for (UIView *backView in navBarSubView.subviews) {
                [backView.layer removeAllAnimations];
                for (UIView *backSubView in backView.subviews) {
                    [backSubView.layer removeAllAnimations];
                    for (UIView *backSSubView in backSubView.subviews) {
                        [backSSubView.layer removeAllAnimations];
                        for (CALayer *subLayer in backSSubView.layer.sublayers) {
                            // !!!!!!!!
                            [subLayer removeAllAnimations];
                        }
                    }
                }
            }
        }
    }
}
- (void)updateInterPercent:(CGFloat)scale{
    HXPhotoPreviewViewController *fromVC = (HXPhotoPreviewViewController *)[self.transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
    fromVC.view.alpha = scale;
    self.bgView.alpha = fromVC.view.alpha;
    
    if (!fromVC.bottomView.userInteractionEnabled) {
        HXPhotoViewController *toVC = (HXPhotoViewController *)[self.transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
        toVC.bottomView.alpha = 1 - scale;
        toVC.limitView.alpha = 1 - scale;
        toVC.navigationController.navigationBar.alpha = 1 - scale;
    }
}
- (void)interPercentCancel{
    id<UIViewControllerContextTransitioning> transitionContext = self.transitionContext;
    HXPhotoPreviewViewController *fromVC = (HXPhotoPreviewViewController *)[transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
    HXPhotoViewController *toVC = (HXPhotoViewController *)[self.transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
    if (!fromVC.bottomView.userInteractionEnabled) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored"-Wdeprecated-declarations"
        [[UIApplication sharedApplication] setStatusBarHidden:YES];
#pragma clang diagnostic pop
        [toVC.navigationController setNavigationBarHidden:YES];
        toVC.navigationController.navigationBar.alpha = 1;
    }
    if (self.fromCell.previewContentView.model.subType == HXPhotoModelMediaSubTypeVideo) {
        [self.fromCell.previewContentView.videoView showOtherView];
    }
    self.panGesture.enabled = NO;
    [UIView animateWithDuration:0.2f animations:^{
        fromVC.view.alpha = 1;
        self.fromCell.transform = CGAffineTransformIdentity;
        self.fromCell.center = self.transitionImgViewCenter;
        self.bgView.alpha = 1;
        if (!fromVC.bottomView.userInteractionEnabled) {
            toVC.bottomView.alpha = 0;
            toVC.limitView.alpha = 0;
        }else {
            toVC.bottomView.alpha = 1;
            toVC.limitView.alpha = 1;
        }
    } completion:^(BOOL finished) {
//        toVC.navigationController.navigationBar.userInteractionEnabled = YES;
        if (finished) {
            fromVC.collectionView.hidden = NO;
            if (!fromVC.bottomView.userInteractionEnabled) {
                fromVC.view.backgroundColor = [UIColor blackColor];
                if (HX_IOS11_Later) {
                    // 处理 ios11 当导航栏隐藏时手势返回的问题
                    [toVC.navigationController setNavigationBarHidden:YES];
                }
            }else {
                fromVC.view.backgroundColor = [HXPhotoCommon photoCommon].isDark ? [UIColor blackColor] : fromVC.manager.configuration.previewPhotoViewBgColor;
            }
            self.tempCell.hidden = NO;
            self.tempCell = nil;
            [self resetScrollView:YES];
            self.fromCell.layer.anchorPoint = CGPointMake(0.5f, 0.5f);
            self.fromCell.frame = self.imageInitialFrame;
            [fromVC.collectionView addSubview:self.fromCell];
            [self.bgView removeFromSuperview];
            self.bgView = nil;
            self.fromCell = nil;
            self.toVC = nil;
            [self.transitionContext completeTransition:NO];
            self.transitionContext = nil;
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                self.panGesture.enabled = YES;
            });
            self.interation = NO;
            self.beginInterPercentCompletion = NO;
        }
    }];
}
//完成
- (void)interPercentFinish {
    id<UIViewControllerContextTransitioning> transitionContext = self.transitionContext;
    UIView *containerView = [transitionContext containerView];
    HXPhotoPreviewViewController *fromVC = (HXPhotoPreviewViewController *)[transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
    HXPhotoViewController *toVC = (HXPhotoViewController *)[self.transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
    NSTimeInterval duration = fromVC.manager.configuration.popInteractiveTransitionDuration;
    UIViewAnimationOptions option = UIViewAnimationOptionLayoutSubviews;
    
    if (self.fromCell.previewContentView.model.subType == HXPhotoModelMediaSubTypeVideo) {
        [self.fromCell.previewContentView.videoView hideOtherView:NO];
    }
    CGRect toRect = [self.tempCell convertRect:self.tempCell.bounds toView:containerView];
    [UIView animateWithDuration:duration delay:0.0 usingSpringWithDamping:0.8 initialSpringVelocity:0.1 options:option animations:^{
        if (self.tempCell) {
            self.fromCell.transform = CGAffineTransformIdentity;
            self.fromCell.frame = toRect;
            self.fromCell.scrollView.contentOffset = CGPointZero;
            self.fromCell.previewContentView.frame = CGRectMake(0, 0, toRect.size.width, toRect.size.height);
        }else {
            self.fromCell.center = self.transitionImgViewCenter;
            self.fromCell.alpha = 0;
            self.fromCell.transform = CGAffineTransformMakeScale(0.3, 0.3);
        }
        fromVC.view.alpha = 0;
        self.bgView.alpha = 0;
        toVC.navigationController.navigationBar.alpha = 1;
        toVC.bottomView.alpha = 1;
        toVC.limitView.alpha = 1;
    }completion:^(BOOL finished) {
//        toVC.navigationController.navigationBar.userInteractionEnabled = YES;
        if (finished) {
            if (!fromVC.bottomView.userInteractionEnabled && HX_IOS11_Later) {
                // 处理 ios11 当导航栏隐藏时手势返回的问题
                [toVC.navigationController.navigationBar.layer removeAllAnimations];
                [toVC.navigationController setNavigationBarHidden:NO];
            }
            [self.tempCell bottomViewPrepareAnimation];
            self.tempCell.hidden = NO;
            [self.tempCell bottomViewStartAnimation];
            
            [self.fromCell.previewContentView cancelRequest];
            [self.fromCell removeFromSuperview];
            [self.bgView removeFromSuperview];
            self.fromCell = nil;
            self.toVC = nil;
            [self.transitionContext completeTransition:YES];
            self.transitionContext = nil;
        }
        self.interation = NO;
        self.beginInterPercentCompletion = NO;
    }];  
}
- (void)startInteractiveTransition:(id<UIViewControllerContextTransitioning>)transitionContext {
    self.transitionContext = transitionContext;
    [self beginInterPercent];
}
- (void)resetScrollView:(BOOL)enabled {
    id<UIViewControllerContextTransitioning> transitionContext = self.transitionContext;
    HXPhotoPreviewViewController *fromVC = (HXPhotoPreviewViewController *)[transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
    fromVC.collectionView.scrollEnabled = enabled;
    self.fromCell.scrollView.scrollEnabled = enabled;
    self.fromCell.scrollView.pinchGestureRecognizer.enabled = enabled;
    self.fromCell.scrollView.clipsToBounds = enabled;
}
@end
