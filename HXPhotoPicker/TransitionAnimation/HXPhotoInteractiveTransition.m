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
@property (nonatomic, weak) UIViewController *vc;
@property (weak, nonatomic) HXPreviewContentView *contentView;
@property (strong, nonatomic) UIView *bgView;
@property (weak, nonatomic) HXPhotoViewCell *tempCell;
@property (weak, nonatomic) HXPhotoPreviewViewCell *fromCell;
@property (assign, nonatomic) CGRect imageInitialFrame;
@property (assign, nonatomic) CGPoint transitionImgViewCenter;
@property (assign, nonatomic) CGFloat beginX;
@property (assign, nonatomic) CGFloat beginY;


@property (assign, nonatomic) CGFloat scrollViewZoomScale;
@property (assign, nonatomic) CGSize scrollViewContentSize;
@property (assign, nonatomic) CGPoint scrollViewContentOffset;
@property (strong, nonatomic) UIPanGestureRecognizer *panGesture;

@property (assign, nonatomic) BOOL beginInterPercentCompletion;
@end

@implementation HXPhotoInteractiveTransition
- (void)addPanGestureForViewController:(UIViewController *)viewController {
    self.panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(gestureRecognizeDidUpdate:)];
    self.panGesture.delegate = self;
    self.vc = viewController;
    if ([viewController isKindOfClass:[HXPhotoPreviewViewController class]]) {
        HXPhotoPreviewViewController *previewVC = (HXPhotoPreviewViewController *)self.vc;
        HXWeakSelf
        previewVC.currentCellScrollViewDidScroll = ^(UIScrollView *scrollView) {
            CGFloat offsetY = scrollView.contentOffset.y;
            if (offsetY < 0) {
                weakSelf.atFirstPan = YES;
            }else if (offsetY == 0) {
                if (weakSelf.interation) {
                    weakSelf.atFirstPan = NO;
                }
            }else {
                weakSelf.atFirstPan = NO;
            }
        };
    }
    [viewController.view addGestureRecognizer:self.panGesture];
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    if ([otherGestureRecognizer.view isKindOfClass:[UIScrollView class]] &&
        ![otherGestureRecognizer.view isKindOfClass:[UICollectionView class]]) {
        UIScrollView *scrollView = (UIScrollView *)otherGestureRecognizer.view;
        if (scrollView.contentOffset.y <= 0 &&
            !scrollView.zooming &&
            !scrollView.isZoomBouncing &&
            self.atFirstPan) {
            return YES;
        }
    }
    return NO;
}
- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer {
    HXPhotoPreviewViewController *previewVC = (HXPhotoPreviewViewController *)self.vc;
    HXPhotoPreviewViewCell *viewCell = [previewVC currentPreviewCell:previewVC.modelArray[previewVC.currentModelIndex]];
    if (viewCell.scrollView.zooming ||
        viewCell.scrollView.zoomScale < 1.0f ||
        viewCell.scrollView.isZoomBouncing) {

        return NO;
    }
    [viewCell.scrollView setContentOffset:viewCell.scrollView.contentOffset animated:NO];
    return YES;
}
- (void)gestureRecognizeDidUpdate:(UIPanGestureRecognizer *)gestureRecognizer {
    CGFloat scale = [self panGestureScale:gestureRecognizer];
    switch (gestureRecognizer.state) {
        case UIGestureRecognizerStateBegan: {
            if (scale < 0) {
                [self.vc.view removeGestureRecognizer:self.panGesture];
                [self.vc.view addGestureRecognizer:self.panGesture];
                return;
            }
            [self panGestureBegan:gestureRecognizer];
        }   break;
        case UIGestureRecognizerStateChanged:
            [self panGestureChanged:gestureRecognizer];
            break;
        case UIGestureRecognizerStateEnded:
            [self panGestureEnd:gestureRecognizer];
            break;
        default:
            [self panGestureOther:gestureRecognizer];
            break;
    }
}
- (CGFloat)panGestureScale:(UIPanGestureRecognizer *)panGesture {
    CGFloat scale = 0;
    CGPoint translation = [panGesture translationInView:panGesture.view];
    CGFloat transitionY = translation.y;
    scale = transitionY / ((panGesture.view.frame.size.height - 50) / 2);
    if (scale > 1.f) {
        scale = 1.f;
    }
    return scale;
}
- (void)panGestureBegan:(UIPanGestureRecognizer *)panGesture {
    self.beginInterPercentCompletion = NO;
    HXPhotoPreviewViewController *previewVC = (HXPhotoPreviewViewController *)self.vc;
    [previewVC setStopCancel:YES];
    self.beginX = [panGesture locationInView:panGesture.view].x;
    self.beginY = [panGesture locationInView:panGesture.view].y;
    self.interation = YES;
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
        self.contentView.center = CGPointMake(self.transitionImgViewCenter.x + translation.x, self.transitionImgViewCenter.y + translation.y);
        self.contentView.transform = CGAffineTransformMakeScale(imageViewScale, imageViewScale);
        
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
        self.interation = NO;
        if (scale < 0.15f){
            [self cancelInteractiveTransition];
            [self interPercentCancel];
        }else {
            [self finishInteractiveTransition];
            [self interPercentFinish];
        }
    }
    self.beginInterPercentCompletion = NO;
}
- (void)panGestureOther:(UIPanGestureRecognizer *)panGesture {
    self.vc.view.userInteractionEnabled = YES;
    if (self.interation) {
        self.interation = NO;
        [self cancelInteractiveTransition];
        [self interPercentCancel];
    }
}
- (void)beginInterPercent {
    id<UIViewControllerContextTransitioning> transitionContext = self.transitionContext;
    
    HXPhotoPreviewViewController *fromVC = (HXPhotoPreviewViewController *)[transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
    
    HXPhotoViewController *toVC = (HXPhotoViewController *)[transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
    
    HXPhotoModel *model = [fromVC.modelArray objectAtIndex:fromVC.currentModelIndex];
    
    HXPhotoPreviewViewCell *fromCell = [fromVC currentPreviewCell:model];
    HXPhotoViewCell *toCell = [toVC currentPreviewCell:model];
    self.fromCell = fromCell;
    self.scrollViewZoomScale = [self.fromCell getScrollViewZoomScale];
    self.scrollViewContentSize = [self.fromCell getScrollViewContentSize];
    self.scrollViewContentOffset = [self.fromCell getScrollViewContentOffset];
    
    UIView *containerView = [transitionContext containerView];
    CGRect tempImageViewFrame;
    self.contentView = fromCell.previewContentView;
    self.imageInitialFrame = fromCell.previewContentView.frame;
    tempImageViewFrame = [fromCell.previewContentView convertRect:fromCell.previewContentView.bounds toView:containerView];
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
    self.contentView.layer.anchorPoint = CGPointMake(scaleX, scaleY);
    
    [fromCell resetScale:NO];
    [fromCell refreshImageSize];
    self.contentView.frame = tempImageViewFrame;
    self.transitionImgViewCenter = self.contentView.center;
    
    [containerView addSubview:toVC.view];
    [containerView addSubview:fromVC.view];
    [toVC.view insertSubview:self.bgView belowSubview:toVC.bottomView];
    [toVC.view insertSubview:self.contentView belowSubview:toVC.bottomView];
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
    }else {
        toVC.bottomView.alpha = 1;
        self.bgView.backgroundColor = [HXPhotoCommon photoCommon].isDark ? [UIColor blackColor] : fromVC.manager.configuration.previewPhotoViewBgColor;
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
    if (self.contentView.model.subType == HXPhotoModelMediaSubTypeVideo) {
        [self.contentView.videoView hideOtherView:YES];
    }
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
    if (self.contentView.model.subType == HXPhotoModelMediaSubTypeVideo) {
        [self.contentView.videoView showOtherView];
    }
    self.panGesture.enabled = NO;
    [UIView animateWithDuration:0.2f animations:^{
        fromVC.view.alpha = 1;
        self.contentView.transform = CGAffineTransformIdentity;
        self.contentView.center = self.transitionImgViewCenter;
        
        self.bgView.alpha = 1;
        if (!fromVC.bottomView.userInteractionEnabled) {
            toVC.bottomView.alpha = 0;
        }else {
            toVC.bottomView.alpha = 1;
        }
    } completion:^(BOOL finished) {
        toVC.navigationController.navigationBar.userInteractionEnabled = YES;
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
            
            self.contentView.layer.anchorPoint = CGPointMake(0.5f, 0.5f);
            [self.fromCell againAddImageView];
            [self.fromCell setScrollViewZoomScale:self.scrollViewZoomScale];
            self.contentView.frame = self.imageInitialFrame;
            [self.fromCell setScrollViewContnetSize:self.scrollViewContentSize];
            if (self.scrollViewContentOffset.y < 0) {
                self.scrollViewContentOffset = CGPointMake(self.scrollViewContentOffset.x, 0);
            }
            [self.fromCell setScrollViewContentOffset:self.scrollViewContentOffset];
             
            [self.bgView removeFromSuperview];
            self.bgView = nil;
            self.fromCell = nil;
            [transitionContext completeTransition:![transitionContext transitionWasCancelled]];
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                self.panGesture.enabled = YES;
            });
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
    
    if (self.contentView.model.subType == HXPhotoModelMediaSubTypeVideo) {
        [self.contentView.videoView hideOtherView:NO];
    }
    CGRect tempImageViewFrame = self.contentView.frame;
    self.contentView.layer.anchorPoint = CGPointMake(0.5, 0.5);
    self.contentView.transform = CGAffineTransformIdentity;
    self.contentView.frame = tempImageViewFrame;
    [self.contentView layoutIfNeeded];
    
    [UIView animateWithDuration:duration delay:0.0 usingSpringWithDamping:0.8 initialSpringVelocity:0.1 options:option animations:^{
        if (self.tempCell) {
            self.contentView.frame = [self.tempCell.imageView convertRect:self.tempCell.imageView.bounds toView: containerView]; 
        }else {
            self.contentView.center = self.transitionImgViewCenter;
            self.contentView.alpha = 0;
            self.contentView.transform = CGAffineTransformMakeScale(0.3, 0.3);
        }
        fromVC.view.alpha = 0;
        self.bgView.alpha = 0;
        toVC.navigationController.navigationBar.alpha = 1;
        toVC.bottomView.alpha = 1;
    }completion:^(BOOL finished) {
        toVC.navigationController.navigationBar.userInteractionEnabled = YES;
        if (finished) {
            if (!fromVC.bottomView.userInteractionEnabled && HX_IOS11_Later) {
                // 处理 ios11 当导航栏隐藏时手势返回的问题
                [toVC.navigationController.navigationBar.layer removeAllAnimations];
                [toVC.navigationController setNavigationBarHidden:NO];
            }
            [self.tempCell bottomViewPrepareAnimation];
            self.tempCell.hidden = NO;
            [self.tempCell bottomViewStartAnimation];
            [self.contentView cancelRequest];
            [self.contentView removeFromSuperview];
            [self.bgView removeFromSuperview];
            self.contentView = nil;
            [transitionContext completeTransition:![transitionContext transitionWasCancelled]];
        }
    }];  
}
- (void)startInteractiveTransition:(id<UIViewControllerContextTransitioning>)transitionContext {
    self.transitionContext = transitionContext;
    [self beginInterPercent];
}
@end
