//
//  HXPhotoPersentInteractiveTransition.m
//  照片选择器
//
//  Created by 洪欣 on 2018/9/8.
//  Copyright © 2018年 洪欣. All rights reserved.
//

#import "HXPhotoPersentInteractiveTransition.h"
#import "HXPhotoPreviewViewController.h"
#import "HXPhotoPreviewBottomView.h"
#import "HXPhotoView.h"
#import "HXPhotoSubViewCell.h"

@interface HXPhotoPersentInteractiveTransition () <UIGestureRecognizerDelegate>
@property (nonatomic, weak) id<UIViewControllerContextTransitioning> transitionContext;
@property (nonatomic, weak) UIViewController *vc;
@property (strong, nonatomic) UIImageView *imageView;
@property (strong, nonatomic) UIView *bgView;
@property (weak, nonatomic) HXPhotoSubViewCell *tempCell;
@property (weak, nonatomic) HXPhotoPreviewViewCell *fromCell;
@property (strong, nonatomic) UIImageView *tempImageView;
@property (nonatomic, assign) CGPoint transitionImgViewCenter;
@property (nonatomic, assign) CGFloat beginX;
@property (nonatomic, assign) CGFloat beginY;
@property (strong, nonatomic) AVPlayerLayer *playerLayer;
@property (strong, nonatomic) HXPhotoView *photoView;
@property (assign, nonatomic) BOOL isPanGesture;


@property (assign, nonatomic) CGFloat scrollViewZoomScale;
@property (assign, nonatomic) CGSize scrollViewContentSize;
@property (assign, nonatomic) CGPoint scrollViewContentOffset;
@property (assign, nonatomic) CGRect imageInitialFrame;
@property (strong, nonatomic) UIPanGestureRecognizer *panGesture;

@property (assign, nonatomic) BOOL atFirstPan;
@end

@implementation HXPhotoPersentInteractiveTransition
- (void)addPanGestureForViewController:(UIViewController *)viewController photoView:(HXPhotoView *)photoView {
    self.panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(gestureRecognizeDidUpdate:)];
    self.panGesture.delegate = self;
    self.vc = viewController;
    if ([viewController isKindOfClass:[HXPhotoPreviewViewController class]]) {
        HXPhotoPreviewViewController *previewVC = (HXPhotoPreviewViewController *)self.vc;
        HXWeakSelf
        previewVC.currentCellScrollViewDidScroll = ^(CGFloat offsetY) {
            if (offsetY < 0) {
                weakSelf.atFirstPan = YES;
            }else if (offsetY == 0) {
                if (self.interation) {
                    weakSelf.atFirstPan = NO;
                }
            }else {
                weakSelf.atFirstPan = NO;
            }
        };
    }
    self.photoView = photoView;
    [viewController.view addGestureRecognizer:self.panGesture];
//    UIPinchGestureRecognizer *pinchGestureRecognizer = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(pinchView:)];
//    pinchGestureRecognizer.delegate = self;
//    [viewController.view addGestureRecognizer:pinchGestureRecognizer];

//    UIRotationGestureRecognizer *rotaitonGest = [[UIRotationGestureRecognizer alloc]initWithTarget:self action:@selector(rotationView:)];
//    rotaitonGest.delegate =self;
//    [viewController.view addGestureRecognizer:rotaitonGest];
    
//    [viewController.view setMultipleTouchEnabled:YES];
}
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    if ([otherGestureRecognizer.view isKindOfClass:[UICollectionView class]]) {
        return NO;
    }
    if ([otherGestureRecognizer.view isKindOfClass:[UIScrollView class]]) {
        UIScrollView *scrollView = (UIScrollView *)otherGestureRecognizer.view;
        if (scrollView.contentOffset.y <= 0 &&
            !scrollView.zooming && self.atFirstPan) {
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
- (void)rotationView:(UIRotationGestureRecognizer *)rotationGest {
    
    CGFloat rotation = rotationGest.rotation;
    NSSLog(@"旋转   %f",rotation);
    self.tempImageView.transform = CGAffineTransformMakeRotation(rotation);
    
}
- (void)pinchView:(UIPinchGestureRecognizer *)pinchGestureRecognizer {
    CGFloat scale = pinchGestureRecognizer.scale;
    NSLog(@"%f",scale);
    switch (pinchGestureRecognizer.state) {
        case UIGestureRecognizerStateBegan: {
            if (scale > 1) {
                
                return;
            }
            self.isPanGesture = NO;
            HXPhotoPreviewViewController *previewVC = (HXPhotoPreviewViewController *)self.vc; 
            if (![previewVC bottomView].userInteractionEnabled) {
                [[UIApplication sharedApplication] setStatusBarHidden:NO];
            }
            [previewVC setStopCancel:YES];
            self.interation = YES;
            [self.vc dismissViewControllerAnimated:YES completion:nil];
        }   break;
        case UIGestureRecognizerStateChanged:
            if (self.interation) {
                
                self.tempImageView.transform = CGAffineTransformMakeScale(scale, scale);
                
                [self updateInterPercent:1 - scale];
                
                [self updateInteractiveTransition:scale];
            }
            break;
        case UIGestureRecognizerStateEnded:
            if (self.interation) {
                
                self.interation = NO;
                if (scale > 0.7f){
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
- (void)gestureRecognizeDidUpdate:(UIPanGestureRecognizer *)gestureRecognizer {
    CGFloat scale = 0;
    
    CGPoint translation = [gestureRecognizer translationInView:gestureRecognizer.view];
    CGFloat transitionY = translation.y;
    scale = transitionY / ((gestureRecognizer.view.frame.size.height - 50) / 2);
    if (scale > 1.f) {
        scale = 1.f;
    }
    switch (gestureRecognizer.state) {
        case UIGestureRecognizerStateBegan: {
            if (scale < 0) {
                [self.vc.view removeGestureRecognizer:self.panGesture];
                [self.vc.view addGestureRecognizer:self.panGesture];
                return;
            }
            self.isPanGesture = YES;
            if (![(HXPhotoPreviewViewController *)self.vc bottomView].userInteractionEnabled) {
                [[UIApplication sharedApplication] setStatusBarHidden:NO];
            }
            [(HXPhotoPreviewViewController *)self.vc setStopCancel:YES];
            self.beginX = [gestureRecognizer locationInView:gestureRecognizer.view].x;
            self.beginY = [gestureRecognizer locationInView:gestureRecognizer.view].y;
            self.interation = YES;
            [self.vc dismissViewControllerAnimated:YES completion:nil];
        } break;
        case UIGestureRecognizerStateChanged:
            if (self.interation) {
                if (scale < 0.f) {
                    scale = 0.f;
                }
                CGFloat imageViewScale = 1 - scale * 0.5;
                if (imageViewScale < 0.4) {
                    imageViewScale = 0.4;
                }
                self.tempImageView.center = CGPointMake(self.transitionImgViewCenter.x + translation.x, self.transitionImgViewCenter.y + translation.y);
                self.tempImageView.transform = CGAffineTransformMakeScale(imageViewScale, imageViewScale);
                
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
    
    HXPhotoPreviewViewController *fromVC = (HXPhotoPreviewViewController *)[transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
    
    UIViewController *toVC = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
    
    HXPhotoModel *model = [fromVC.modelArray objectAtIndex:fromVC.currentModelIndex];
    
    HXPhotoPreviewViewCell *fromCell = [fromVC currentPreviewCell:model];
    
    UICollectionView *collectionView = (UICollectionView *)self.photoView.collectionView;
    if ([toVC isKindOfClass:[UINavigationController class]]) {
        UINavigationController *nav = (UINavigationController *)toVC;
        toVC = nav.viewControllers.lastObject;
    }else if ([toVC isKindOfClass:[UITabBarController class]]) {
        UITabBarController *tabBar = (UITabBarController *)toVC;
        if ([tabBar.selectedViewController isKindOfClass:[UINavigationController class]]) {
            UINavigationController *nav = (UINavigationController *)tabBar.selectedViewController;
            toVC = nav.viewControllers.lastObject;
        }else {
            toVC = tabBar.selectedViewController;
        }
    }
    HXPhotoSubViewCell *toCell = (HXPhotoSubViewCell *)[collectionView cellForItemAtIndexPath:[self.photoView currentModelIndexPath:model]];
    
    self.fromCell = fromCell;
    self.scrollViewZoomScale = [self.fromCell getScrollViewZoomScale];
    self.scrollViewContentSize = [self.fromCell getScrollViewContentSize];
    self.scrollViewContentOffset = [self.fromCell getScrollViewContentOffset];
    
    UIView *containerView = [transitionContext containerView];
    CGRect tempImageViewFrame;
    if (model.subType == HXPhotoModelMediaSubTypePhoto) {
#if HasYYKitOrWebImage
        self.tempImageView = fromCell.animatedImageView;
        self.imageInitialFrame = fromCell.animatedImageView.frame;
        tempImageViewFrame = [fromCell.animatedImageView convertRect:fromCell.animatedImageView.bounds toView:containerView];
#else
        self.tempImageView = fromCell.imageView;
        self.imageInitialFrame = fromCell.imageView.frame;
        tempImageViewFrame = [fromCell.imageView convertRect:fromCell.imageView.bounds toView:containerView];
#endif
    }else {
        if (!fromCell.playerLayer.player) {
#if HasYYKitOrWebImage
            self.tempImageView = fromCell.animatedImageView;
            tempImageViewFrame = [fromCell.animatedImageView convertRect:fromCell.animatedImageView.bounds toView:containerView];
#else
            self.tempImageView = fromCell.imageView;
            tempImageViewFrame = [fromCell.imageView convertRect:fromCell.imageView.bounds toView:containerView];
#endif
        }else {
            tempImageViewFrame = containerView.bounds;
            [fromCell.playerLayer removeFromSuperlayer];
            self.playerLayer = fromCell.playerLayer;
            self.tempImageView = [[UIImageView alloc] init];
            self.tempImageView.layer.masksToBounds = YES;
            [self.tempImageView.layer addSublayer:self.playerLayer];
        }
//        if (HX_IS_IPhoneX_All) {
//            tempImageViewFrame = CGRectMake(tempImageViewFrame.origin.x, tempImageViewFrame.origin.y + hxTopMargin, tempImageViewFrame.size.width, tempImageViewFrame.size.height);
//        }
    }
    self.tempImageView.clipsToBounds = YES;
    self.tempImageView.contentMode = UIViewContentModeScaleAspectFill;
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
    self.tempImageView.layer.anchorPoint = CGPointMake(scaleX, scaleY);
    
    [fromCell resetScale:NO];
    [fromCell refreshImageSize];
    
    self.tempImageView.frame = tempImageViewFrame;
    self.transitionImgViewCenter = self.tempImageView.center;
    
    [containerView addSubview:self.bgView];
    [containerView addSubview:self.tempImageView];
    [containerView addSubview:fromVC.view]; 
    
    if (!fromVC.bottomView.userInteractionEnabled) {
        self.bgView.backgroundColor = [UIColor blackColor];
    }else {
        if (fromVC.exteriorPreviewStyle == HXPhotoViewPreViewShowStyleDark) {
            self.bgView.backgroundColor = [UIColor blackColor];
        }else {
            self.bgView.backgroundColor = [UIColor whiteColor];
        }
    }
    fromVC.collectionView.hidden = YES;
    toCell.hidden = YES;
    fromVC.view.backgroundColor = [UIColor clearColor];
    self.tempCell = toCell;
}
- (void)updateInterPercent:(CGFloat)scale{
    HXPhotoPreviewViewController *fromVC = (HXPhotoPreviewViewController *)[self.transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
    fromVC.view.alpha = scale;
    self.bgView.alpha = fromVC.view.alpha;
}
- (void)interPercentCancel{
    id<UIViewControllerContextTransitioning> transitionContext = self.transitionContext;
    HXPhotoPreviewViewController *fromVC = (HXPhotoPreviewViewController *)[transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
    UIViewController *toVC = [self.transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
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
    } completion:^(BOOL finished) {
        fromVC.collectionView.hidden = NO;
        if (!fromVC.bottomView.userInteractionEnabled) {
            fromVC.view.backgroundColor = [UIColor blackColor];
        }else {
            if (fromVC.exteriorPreviewStyle == HXPhotoViewPreViewShowStyleDark) {
                fromVC.view.backgroundColor = [UIColor blackColor];
            }else {
                fromVC.view.backgroundColor = [UIColor whiteColor];
            }
        }
        self.tempCell.hidden = NO;
        self.tempCell = nil;
        
        self.tempImageView.layer.anchorPoint = CGPointMake(0.5f, 0.5f);
        [self.fromCell againAddImageView];
         
        [self.fromCell setScrollViewZoomScale:self.scrollViewZoomScale];
        self.tempImageView.frame = self.imageInitialFrame;
        [self.fromCell setScrollViewContnetSize:self.scrollViewContentSize];
        if (self.scrollViewContentOffset.y < 0) {
            self.scrollViewContentOffset = CGPointMake(self.scrollViewContentOffset.x, 0);
        }
        [self.fromCell setScrollViewContentOffset:self.scrollViewContentOffset];
        
        self.playerLayer = nil;
        [self.bgView removeFromSuperview];
        self.bgView = nil;
        [transitionContext completeTransition:![transitionContext transitionWasCancelled]];
    }];
}
//完成
- (void)interPercentFinish {
    id<UIViewControllerContextTransitioning> transitionContext = self.transitionContext;
    UIView *containerView = [transitionContext containerView];
    HXPhotoPreviewViewController *fromVC = (HXPhotoPreviewViewController *)[transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
    
    UIViewController *toVC = [self.transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
    
    NSTimeInterval duration = fromVC.manager.configuration.popInteractiveTransitionDuration;
    UIViewAnimationOptions option = fromVC.manager.configuration.transitionAnimationOption;
    
    CGRect tempImageViewFrame = self.tempImageView.frame;
    if (self.tempCell) {
        self.tempImageView.layer.anchorPoint = CGPointMake(0.5, 0.5);
    }
    self.tempImageView.transform = CGAffineTransformIdentity;
    self.tempImageView.frame = tempImageViewFrame;
    self.playerLayer.frame = CGRectMake(0, 0, self.tempCell.imageView.hx_w, self.tempCell.imageView.hx_h);
    
    [UIView animateWithDuration:duration delay:0.0 usingSpringWithDamping:0.8 initialSpringVelocity:0.1 options:option animations:^{
        if (self.tempCell) {
            self.tempImageView.frame = [self.tempCell.imageView convertRect:self.tempCell.imageView.bounds toView: containerView];
        }else {
//            self.tempImageView.center = self.transitionImgViewCenter;
            self.tempImageView.alpha = 0;
            self.tempImageView.transform = CGAffineTransformMakeScale(0.3, 0.3);
        }
        fromVC.view.alpha = 0;
        self.bgView.alpha = 0;
        toVC.navigationController.navigationBar.alpha = 1;
    }completion:^(BOOL finished) {
        self.tempCell.hidden = NO;
        self.playerLayer = nil;
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
