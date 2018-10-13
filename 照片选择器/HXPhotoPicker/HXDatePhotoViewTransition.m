//
//  HXDatePhotoViewTransition.m
//  照片选择器
//
//  Created by 洪欣 on 2017/10/27.
//  Copyright © 2017年 洪欣. All rights reserved.
//

#import "HXDatePhotoViewTransition.h"
#import "HXDatePhotoViewController.h"
#import "HXDatePhotoPreviewViewController.h"
#import "HXDatePhotoPreviewBottomView.h"
@interface HXDatePhotoViewTransition ()
@property (assign, nonatomic) HXDatePhotoViewTransitionType type;
@end

@implementation HXDatePhotoViewTransition

+ (instancetype)transitionWithType:(HXDatePhotoViewTransitionType)type {
    return [[self alloc] initWithTransitionType:type];
}

- (instancetype)initWithTransitionType:(HXDatePhotoViewTransitionType)type {
    self = [super init];
    if (self)  {
        self.type = type;
    }
    return self;
}
- (void)animateTransition:(nonnull id<UIViewControllerContextTransitioning>)transitionContext {
    switch (self.type) {
        case HXDatePhotoViewTransitionTypePush:
            [self pushAnimation:transitionContext];
            break;
        default:
            [self popAnimation:transitionContext];
            break;
    }
}

- (void)pushAnimation:(id<UIViewControllerContextTransitioning>)transitionContext {
    HXDatePhotoViewController *fromVC = (HXDatePhotoViewController *)[transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
    HXDatePhotoPreviewViewController *toVC = (HXDatePhotoPreviewViewController *)[transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
    HXPhotoModel *model = [toVC.modelArray objectAtIndex:toVC.currentModelIndex];
    __weak typeof(self) weakSelf = self;
    [HXPhotoTools getHighQualityFormatPhotoForPHAsset:model.asset size:CGSizeMake(model.endImageSize.width * 0.8, model.endImageSize.height * 0.8) completion:^(UIImage *image, NSDictionary *info) {
        [weakSelf pushAnim:transitionContext image:image model:model fromVC:fromVC toVC:toVC];
    } error:^(NSDictionary *info) {
        [weakSelf pushAnim:transitionContext image:model.thumbPhoto model:model fromVC:fromVC toVC:toVC];
    }];
}
- (void)pushAnim:(id<UIViewControllerContextTransitioning>)transitionContext image:(UIImage *)image model:(HXPhotoModel *)model fromVC:(HXDatePhotoViewController *)fromVC toVC:(HXDatePhotoPreviewViewController *)toVC {
    model.tempImage = image;
    HXDatePhotoViewCell *fromCell = [fromVC currentPreviewCell:model];
    if (!image) {
        model.tempImage = fromCell.imageView.image;
        image = fromCell.imageView.image;
    }
    UIView *containerView = [transitionContext containerView];
    model.endDateImageSize = CGSizeZero;
    CGFloat imgWidht = model.endDateImageSize.width;
    CGFloat imgHeight = model.endDateImageSize.height;
    CGFloat width = [UIScreen mainScreen].bounds.size.width;
//    CGFloat height = [UIScreen mainScreen].bounds.size.height - hxTopMargin - hxBottomMargin;
    CGFloat height = [UIScreen mainScreen].bounds.size.height;
//    UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
//    if (orientation == UIInterfaceOrientationLandscapeRight || orientation == UIInterfaceOrientationLandscapeLeft){
//        if (HX_IS_IPhoneX_All) {
//            height = [UIScreen mainScreen].bounds.size.height - hxTopMargin - 21;
//        }
//    }
    UIImageView *tempView = [[UIImageView alloc] initWithImage:image];
    UIView *tempBgView = [[UIView alloc] initWithFrame:containerView.bounds];
    tempBgView.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:0];
    tempView.clipsToBounds = YES;
    tempView.contentMode = UIViewContentModeScaleAspectFill;
    if (fromCell) {
        tempView.frame = [fromCell.imageView convertRect:fromCell.imageView.bounds toView: containerView];
    }else {
        tempView.center = CGPointMake(width / 2, height / 2);
    }
    [tempBgView addSubview:tempView];
    [fromVC.view insertSubview:tempBgView belowSubview:fromVC.bottomView];
    [containerView addSubview:fromVC.view];
    [containerView addSubview:toVC.view];
    toVC.collectionView.hidden = YES;
    toVC.view.backgroundColor = [UIColor clearColor];
    toVC.bottomView.alpha = 0;
    fromCell.hidden = YES;
    // 弹簧动画，参数分别为：时长，延时，弹性（越小弹性越大），初始速度
    toVC.navigationController.navigationBar.userInteractionEnabled = NO;
    UIViewAnimationOptions option = fromVC.manager.configuration.transitionAnimationOption;
    
    [UIView animateWithDuration:0.2 animations:^{
        tempBgView.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:1];
    }];
    
    [UIView animateWithDuration:[self transitionDuration:transitionContext] delay:0 usingSpringWithDamping:0.8f initialSpringVelocity:0 options:option animations:^{
//        tempView.frame = CGRectMake((width - imgWidht) / 2, (height - imgHeight) / 2 + hxTopMargin, imgWidht, imgHeight);
        tempView.frame = CGRectMake((width - imgWidht) / 2, (height - imgHeight) / 2, imgWidht, imgHeight);
        toVC.bottomView.alpha = 1;
    } completion:^(BOOL finished) {
        fromCell.hidden = NO;
        
        toVC.view.backgroundColor = [UIColor whiteColor];
        toVC.collectionView.hidden = NO;
        [tempBgView removeFromSuperview];
        [tempView removeFromSuperview];
        toVC.navigationController.navigationBar.userInteractionEnabled = YES;
        [transitionContext completeTransition:YES];
    }];
}
- (void)popAnimation:(id<UIViewControllerContextTransitioning>)transitionContext {
    HXDatePhotoPreviewViewController *fromVC = (HXDatePhotoPreviewViewController *)[transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
    HXDatePhotoViewController *toVC = (HXDatePhotoViewController *)[transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
    HXPhotoModel *model = [fromVC.modelArray objectAtIndex:fromVC.currentModelIndex];
    
    HXDatePhotoPreviewViewCell *fromCell = [fromVC currentPreviewCell:model];
    HXDatePhotoViewCell *toCell = [toVC currentPreviewCell:model];
    UIImageView *tempView;
#if __has_include(<YYWebImage/YYWebImage.h>) || __has_include("YYWebImage.h")
    tempView = [[UIImageView alloc] initWithImage:fromCell.animatedImageView.image];
#else
    tempView = [[UIImageView alloc] initWithImage:fromCell.imageView.image];
#endif
    tempView.clipsToBounds = YES;
    tempView.contentMode = UIViewContentModeScaleAspectFill;
    BOOL contains = YES;
    if (!toCell) {
        contains = [toVC scrollToModel:model];
        toCell = [toVC currentPreviewCell:model];
    }
    UIView *containerView = [transitionContext containerView];
    UIView *tempBgView = [[UIView alloc] initWithFrame:containerView.bounds];
    [tempBgView addSubview:tempView];
    [containerView addSubview:toVC.view];
    [containerView addSubview:fromVC.view];
    if (transitionContext.interactive && !fromVC.bottomView.userInteractionEnabled) {
        tempBgView.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:1];
        [toVC.navigationController setNavigationBarHidden:NO];
        [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationFade];
        [containerView insertSubview:tempBgView belowSubview:fromVC.view];
    }else {
        [toVC.view insertSubview:tempBgView belowSubview:toVC.bottomView];
        tempBgView.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:1];
    }
    toVC.navigationController.navigationBar.userInteractionEnabled = NO;
    
    fromVC.collectionView.hidden = YES;
    toCell.hidden = YES;
    fromVC.view.backgroundColor = [UIColor clearColor];
    
#if __has_include(<YYWebImage/YYWebImage.h>) || __has_include("YYWebImage.h")
    tempView.frame = [fromCell.animatedImageView convertRect:fromCell.animatedImageView.bounds toView:containerView];
#else
    tempView.frame = [fromCell.imageView convertRect:fromCell.imageView.bounds toView:containerView];
#endif
    
    CGRect rect = [toCell.imageView convertRect:toCell.imageView.bounds toView: containerView];
    if (toCell) {
        [toVC scrollToPoint:toCell rect:rect];
    }
    
    UIViewAnimationOptions option = fromVC.manager.configuration.transitionAnimationOption;
    
    [UIView animateWithDuration:0.2 animations:^{
        fromVC.view.backgroundColor = [UIColor clearColor];
        fromVC.bottomView.alpha = 0;
        if (!fromVC.bottomView.userInteractionEnabled) {
            tempBgView.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0];
            //            toVC.navigationController.navigationBar.alpha = 1;
            //            toVC.bottomView.alpha = 1;
        }else {
            tempBgView.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:0];
        }
    }];
    
    [UIView animateWithDuration:[self transitionDuration:transitionContext] delay:0.0 usingSpringWithDamping:0.8 initialSpringVelocity:0.1 options:option animations:^{
        if (!contains || !toCell) {
            tempView.transform = CGAffineTransformMakeScale(0.3, 0.3);
            tempView.alpha = 0;
        }else {
            tempView.frame = [toCell.imageView convertRect:toCell.imageView.bounds toView: containerView];
        }
    }completion:^(BOOL finished) {
        //由于加入了手势必须判断
        if ([transitionContext transitionWasCancelled]) {//手势取消了，原来隐藏的imageView要显示出来
            //失败了隐藏tempView，显示fromVC.imageView
            fromVC.collectionView.hidden = NO;
            if (!fromVC.bottomView.userInteractionEnabled) {
                fromVC.view.backgroundColor = [UIColor blackColor];
                [toVC.navigationController setNavigationBarHidden:YES];
                [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationFade];
            }
        }else{//手势成功，cell的imageView也要显示出来
            //成功了移除tempView，下一次pop的时候又要创建，然后显示cell的imageView
            
        }
        toVC.navigationController.navigationBar.userInteractionEnabled = YES;
        [toCell bottomViewPrepareAnimation];
        toCell.hidden = NO;
        [toCell bottomViewStartAnimation];
        [tempBgView removeFromSuperview];
        [tempView removeFromSuperview];
        
        [transitionContext completeTransition:![transitionContext transitionWasCancelled]];
    }];
    
    /*
    [UIView animateWithDuration:[self transitionDuration:transitionContext] delay:0 options:option animations:^{
        if (!contains || !toCell) {
            tempView.transform = CGAffineTransformMakeScale(0.3, 0.3);
            tempView.alpha = 0;
        }else {
            tempView.frame = [toCell.imageView convertRect:toCell.imageView.bounds toView: containerView];
        }
        fromVC.view.backgroundColor = [UIColor clearColor];
        fromVC.bottomView.alpha = 0;
        if (!fromVC.bottomView.userInteractionEnabled) {
            tempBgView.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0];
            //            toVC.navigationController.navigationBar.alpha = 1;
            //            toVC.bottomView.alpha = 1;
        }else {
            tempBgView.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:0];
        }
    } completion:^(BOOL finished) {
        //由于加入了手势必须判断
        if ([transitionContext transitionWasCancelled]) {//手势取消了，原来隐藏的imageView要显示出来
            //失败了隐藏tempView，显示fromVC.imageView
            fromVC.collectionView.hidden = NO;
            if (!fromVC.bottomView.userInteractionEnabled) {
                fromVC.view.backgroundColor = [UIColor blackColor];
                [toVC.navigationController setNavigationBarHidden:YES];
                [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationFade];
            }
        }else{//手势成功，cell的imageView也要显示出来
            //成功了移除tempView，下一次pop的时候又要创建，然后显示cell的imageView
            
        }
        toVC.navigationController.navigationBar.userInteractionEnabled = YES;
        [toCell bottomViewPrepareAnimation];
        toCell.hidden = NO;
        [toCell bottomViewStartAnimation];
        [tempBgView removeFromSuperview];
        [tempView removeFromSuperview];
        
        [transitionContext completeTransition:![transitionContext transitionWasCancelled]];
    }];
    [UIView animateWithDuration:[self transitionDuration:transitionContext] delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        if (!contains || !toCell) {
            tempView.transform = CGAffineTransformMakeScale(0.3, 0.3);
            tempView.alpha = 0;
        }else {
            tempView.frame = [toCell.imageView convertRect:toCell.imageView.bounds toView: containerView];
        }
        fromVC.view.backgroundColor = [UIColor clearColor];
        fromVC.bottomView.alpha = 0;
        if (!fromVC.bottomView.userInteractionEnabled) {
            tempBgView.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0];
            //            toVC.navigationController.navigationBar.alpha = 1;
            //            toVC.bottomView.alpha = 1;
        }else {
            tempBgView.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:0];
        }
    } completion:^(BOOL finished) {
        //由于加入了手势必须判断
        if ([transitionContext transitionWasCancelled]) {//手势取消了，原来隐藏的imageView要显示出来
            //失败了隐藏tempView，显示fromVC.imageView
            fromVC.collectionView.hidden = NO;
            if (!fromVC.bottomView.userInteractionEnabled) {
                fromVC.view.backgroundColor = [UIColor blackColor];
                [toVC.navigationController setNavigationBarHidden:YES];
                [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationFade];
            }
        }else{//手势成功，cell的imageView也要显示出来
            //成功了移除tempView，下一次pop的时候又要创建，然后显示cell的imageView
            
        }
        toVC.navigationController.navigationBar.userInteractionEnabled = YES;
        [toCell bottomViewPrepareAnimation];
        toCell.hidden = NO;
        [toCell bottomViewStartAnimation];
        [tempBgView removeFromSuperview];
        [tempView removeFromSuperview];
        
        [transitionContext completeTransition:![transitionContext transitionWasCancelled]];
    }];
     */
}

- (NSTimeInterval)transitionDuration:(nullable id<UIViewControllerContextTransitioning>)transitionContext {
    if (self.type == HXDatePhotoViewTransitionTypePush) {
        HXDatePhotoViewController *fromVC = (HXDatePhotoViewController *)[transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
        return fromVC.manager.configuration.pushTransitionDuration;
    }else {
        HXDatePhotoPreviewViewController *fromVC = (HXDatePhotoPreviewViewController *)[transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
        return fromVC.manager.configuration.popTransitionDuration;
    }
}


@end
