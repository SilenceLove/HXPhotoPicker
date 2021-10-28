//
//  HXPhotoPersentInteractiveTransition.m
//  HXPhotoPickerExample
//
//  Created by Silence on 2018/9/8.
//  Copyright © 2018年 Silence. All rights reserved.
//

#import "HXPhotoPersentInteractiveTransition.h"
#import "HXPhotoPreviewViewController.h"
#import "HXPhotoPreviewBottomView.h"
#import "HXPhotoView.h"
#import "HXPhotoSubViewCell.h"

@interface HXPhotoPersentInteractiveTransition () <UIGestureRecognizerDelegate>
@property (nonatomic, weak) id<UIViewControllerContextTransitioning> transitionContext;
@property (nonatomic, weak) HXPhotoPreviewViewController *vc;
@property (strong, nonatomic) UIView *bgView;
@property (weak, nonatomic) HXPhotoSubViewCell *tempCell;
@property (weak, nonatomic) HXPhotoPreviewViewCell *fromCell;
@property (nonatomic, assign) CGPoint transitionImgViewCenter;
@property (nonatomic, assign) CGFloat beginX;
@property (nonatomic, assign) CGFloat beginY;
@property (weak, nonatomic) HXPhotoView *photoView;
@property (assign, nonatomic) BOOL isPanGesture;
@property (assign, nonatomic) CGPoint slidingGap;

@property (assign, nonatomic) CGRect imageInitialFrame;
@property (strong, nonatomic) UIPanGestureRecognizer *panGesture;
@property (assign, nonatomic) BOOL beginInterPercentCompletion;
@end

@implementation HXPhotoPersentInteractiveTransition
- (void)addPanGestureForViewController:(UIViewController *)viewController photoView:(HXPhotoView *)photoView {
    self.panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(gestureRecognizeDidUpdate:)];
    self.panGesture.delegate = self;
    self.slidingGap = CGPointZero;
    self.vc = (HXPhotoPreviewViewController *)viewController;
    self.photoView = photoView;
    [viewController.view addGestureRecognizer:self.panGesture];
}
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    return !self.vc.collectionView.isDragging;
}
- (void)gestureRecognizeDidUpdate:(UIPanGestureRecognizer *)gestureRecognizer {
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
        } break;
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
            if (self.interation && self.beginInterPercentCompletion) {
                CGFloat scale = [self panGestureScale:gestureRecognizer];
                if (scale < 0.f) {
                    scale = 0.f;
                }
                CGPoint translation = [gestureRecognizer translationInView:gestureRecognizer.view];
                CGFloat imageViewScale = 1 - scale * 0.5;
                if (imageViewScale < 0.4) {
                    imageViewScale = 0.4;
                }
                self.fromCell.center = CGPointMake(self.transitionImgViewCenter.x + (translation.x - self.slidingGap.x), self.transitionImgViewCenter.y + (translation.y - self.slidingGap.y));
                self.fromCell.transform = CGAffineTransformMakeScale(imageViewScale, imageViewScale);
                
                [self updateInterPercent:1 - scale * scale];
                
                [self updateInteractiveTransition:scale];
            }
            break;
        case UIGestureRecognizerStateEnded:
            if (self.interation) {
                CGFloat scale = [self panGestureScale:gestureRecognizer];
                if (scale < 0.f) {
                    scale = 0.f;
                }
                self.interation = NO;
                if (scale < 0.2f){
                    [self cancelInteractiveTransition];
                    [self interPercentCancel];
                }else {
                    [self finishInteractiveTransition];
                    [self interPercentFinish];
                }
                self.beginInterPercentCompletion = NO;
            }
            self.slidingGap = CGPointZero;
            break;
        default:
            if (self.interation) {
                self.interation = NO;
                [self cancelInteractiveTransition];
                [self interPercentCancel];
                self.beginInterPercentCompletion = NO;
            }
            self.slidingGap = CGPointZero;
            break;
    }
}
- (void)panGestureBegan:(UIPanGestureRecognizer *)panGesture {
    CGPoint velocity = [panGesture velocityInView:self.vc.view];
    BOOL isVerticalGesture = (fabs(velocity.y) > fabs(velocity.x) && velocity.y > 0);
    if (!isVerticalGesture) {
        return;
    }
    self.isPanGesture = YES;
    if (![(HXPhotoPreviewViewController *)self.vc bottomView].userInteractionEnabled) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored"-Wdeprecated-declarations"
        [[UIApplication sharedApplication] setStatusBarHidden:NO];
#pragma clang diagnostic pop
    }
    [(HXPhotoPreviewViewController *)self.vc setStopCancel:YES];
    self.beginX = [panGesture locationInView:panGesture.view].x;
    self.beginY = [panGesture locationInView:panGesture.view].y;
    self.beginInterPercentCompletion = NO;
    self.interation = YES;
    [self.vc dismissViewControllerAnimated:YES completion:nil];
}
- (CGFloat)panGestureScale:(UIPanGestureRecognizer *)panGesture {
    CGFloat scale = 0;
    CGPoint translation = [panGesture translationInView:panGesture.view];
    CGFloat transitionY = translation.y;
    scale = (transitionY - self.slidingGap.y) / ((panGesture.view.frame.size.height - 50) / 2);
    if (scale > 1.f) {
        scale = 1.f;
    }
    return scale;
}
- (void)beginInterPercent{
    id<UIViewControllerContextTransitioning> transitionContext = self.transitionContext;
    
    HXPhotoPreviewViewController *fromVC = (HXPhotoPreviewViewController *)[transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
    
    HXPhotoModel *model = [fromVC.modelArray objectAtIndex:fromVC.currentModelIndex];
    
    HXPhotoPreviewViewCell *fromCell = [fromVC currentPreviewCell:model];
    
    UICollectionView *collectionView = (UICollectionView *)self.photoView.collectionView;
    HXPhotoSubViewCell *toCell = (HXPhotoSubViewCell *)[collectionView cellForItemAtIndexPath:[self.photoView currentModelIndexPath:model]];
    
    self.fromCell = fromCell;
    UIView *containerView = [transitionContext containerView];
    CGRect tempImageViewFrame;
    self.imageInitialFrame = fromCell.frame;
    tempImageViewFrame = [fromCell convertRect:fromCell.bounds toView:containerView];
    
    self.bgView = [[UIView alloc] initWithFrame:containerView.bounds];
    CGFloat scaleX;
    CGFloat scaleY;
    if (self.isPanGesture) {
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
    }else {
        scaleX = 0.5f;
        scaleY = 0.5f;
    }
    self.fromCell.layer.anchorPoint = CGPointMake(scaleX, scaleY);
    
    self.fromCell.frame = tempImageViewFrame;
    self.transitionImgViewCenter = self.fromCell.center;
    
    [containerView addSubview:self.bgView];
    [containerView addSubview:self.fromCell];
    [containerView addSubview:fromVC.view]; 
    
    if (!fromVC.bottomView.userInteractionEnabled) {
        self.bgView.backgroundColor = [UIColor blackColor];
    }else {
        if (fromVC.exteriorPreviewStyle == HXPhotoViewPreViewShowStyleDark) {
            self.bgView.backgroundColor = [UIColor blackColor];
        }else {
            self.bgView.backgroundColor = [HXPhotoCommon photoCommon].isDark ? [UIColor blackColor] : fromVC.manager.configuration.previewPhotoViewBgColor;
        }
    }
    fromVC.collectionView.hidden = YES;
    if (!toCell && fromVC.manager.configuration.customPreviewToView) {
        toCell = (id)fromVC.manager.configuration.customPreviewToView(fromVC.currentModelIndex);
    }
    toCell.hidden = YES;
    fromVC.view.backgroundColor = [UIColor clearColor];
    self.tempCell = toCell;
    if (self.fromCell.previewContentView.model.subType == HXPhotoModelMediaSubTypeVideo) {
        [self.fromCell.previewContentView.videoView hideOtherView:YES];
    }
    [self resetScrollView:NO];
    self.beginInterPercentCompletion = YES;
}
- (void)updateInterPercent:(CGFloat)scale{
    HXPhotoPreviewViewController *fromVC = (HXPhotoPreviewViewController *)[self.transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
    fromVC.view.alpha = scale;
    self.bgView.alpha = fromVC.view.alpha;
}
- (void)interPercentCancel {
    id<UIViewControllerContextTransitioning> transitionContext = self.transitionContext;
    HXPhotoPreviewViewController *fromVC = (HXPhotoPreviewViewController *)[transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
    UIViewController *toVC = [self.transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
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
    } completion:^(BOOL finished) {
        UIApplicationState applicationState = [UIApplication sharedApplication].applicationState;
        if (applicationState == UIApplicationStateBackground || finished) {
            fromVC.collectionView.hidden = NO;
            if (!fromVC.bottomView.userInteractionEnabled) {
                fromVC.view.backgroundColor = [UIColor blackColor];
            }else {
                if (fromVC.exteriorPreviewStyle == HXPhotoViewPreViewShowStyleDark) {
                    fromVC.view.backgroundColor = [UIColor blackColor];
                }else {
                    fromVC.view.backgroundColor = [HXPhotoCommon photoCommon].isDark ? [UIColor blackColor] : fromVC.manager.configuration.previewPhotoViewBgColor;
                }
            }
            self.tempCell.hidden = NO;
            self.tempCell = nil;
            [self resetScrollView:YES];
            self.fromCell.layer.anchorPoint = CGPointMake(0.5f, 0.5f);
            self.fromCell.frame = self.imageInitialFrame;
            [fromVC.collectionView addSubview:self.fromCell];
            [self.bgView removeFromSuperview];
            self.bgView = nil;
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
    
    UIViewController *toVC = [self.transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
    
    NSTimeInterval duration = fromVC.manager.configuration.popInteractiveTransitionDuration;
    UIViewAnimationOptions option = UIViewAnimationOptionLayoutSubviews;
    
    if (self.fromCell.previewContentView.model.subType == HXPhotoModelMediaSubTypeVideo) {
        [self.fromCell.previewContentView.videoView hideOtherView:NO];
    }
    
    if ([fromVC.delegate respondsToSelector:@selector(photoPreviewControllerDidCancel:model:)]) {
        HXPhotoModel *model;
        if (fromVC.modelArray.count) {
            model = fromVC.modelArray[fromVC.currentModelIndex];
        }
        [fromVC.delegate photoPreviewControllerDidCancel:fromVC model:model];
    }
    fromVC.manager.selectPhotoing = NO;
    
    if (self.tempCell && self.tempCell.layer.cornerRadius > 0) {
        UIView *maskView = [[UIView alloc] initWithFrame:self.fromCell.bounds];
        maskView.backgroundColor = [UIColor redColor];
        maskView.layer.cornerRadius = 0.f;
        maskView.layer.masksToBounds = true;
        self.fromCell.maskView = maskView;
    }
    CGRect toRect = [self.tempCell convertRect:self.tempCell.bounds toView:containerView];
    [UIView animateWithDuration:duration delay:0.0 usingSpringWithDamping:0.8 initialSpringVelocity:0.1 options:option animations:^{
        if (self.tempCell) {
            self.fromCell.transform = CGAffineTransformIdentity;
            self.fromCell.frame = toRect;
            self.fromCell.scrollView.contentOffset = CGPointZero;
            self.fromCell.previewContentView.frame = CGRectMake(0, 0, toRect.size.width, toRect.size.height);
            if (self.fromCell.maskView != nil) {
                self.fromCell.maskView.layer.cornerRadius = self.tempCell.layer.cornerRadius;
                self.fromCell.maskView.frame = (CGRect) { CGPointZero, toRect.size };
            }
        }else {
            self.fromCell.alpha = 0;
            self.fromCell.transform = CGAffineTransformMakeScale(0.3, 0.3);
        }
        fromVC.view.alpha = 0;
        self.bgView.alpha = 0;
        toVC.navigationController.navigationBar.alpha = 1;
    }completion:^(BOOL finished) {
        if (finished) {
            self.tempCell.hidden = NO;
            [self.fromCell cancelRequest];
            [self.fromCell removeFromSuperview];
            [self.bgView removeFromSuperview];
            self.fromCell = nil;
            self.bgView = nil;
            [transitionContext completeTransition:![transitionContext transitionWasCancelled]];
        }
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
