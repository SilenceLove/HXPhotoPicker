//
//  HXDatePhotoViewPresentTransition.m
//  照片选择器
//
//  Created by 洪欣 on 2017/10/28.
//  Copyright © 2017年 洪欣. All rights reserved.
//

#import "HXDatePhotoViewPresentTransition.h"
#import "HXPhotoView.h"
#import "HXPhotoSubViewCell.h"
#import "HXPhotoView.h"
#import "HXDatePhotoPreviewViewController.h"
#import "HXDatePhotoPreviewBottomView.h"

@interface HXDatePhotoViewPresentTransition ()
@property (strong, nonatomic) HXPhotoView *photoView ;
@property (assign, nonatomic) HXDatePhotoViewPresentTransitionType type;
@end

@implementation HXDatePhotoViewPresentTransition
+ (instancetype)transitionWithTransitionType:(HXDatePhotoViewPresentTransitionType)type photoView:(HXPhotoView *)photoView {
    return [[self alloc] initWithTransitionType:type photoView:photoView];
}

- (instancetype)initWithTransitionType:(HXDatePhotoViewPresentTransitionType)type photoView:(HXPhotoView *)photoView {
    self = [super init];
    if (self) {
        self.type = type;
        self.photoView = photoView;
    }
    return self;
}
- (NSTimeInterval)transitionDuration:(id<UIViewControllerContextTransitioning>)transitionContext{
    if (self.type == HXDatePhotoViewPresentTransitionTypePresent) {
        return 0.45f;
    }else {
        return 0.25f;
    }
}

- (void)animateTransition:(id<UIViewControllerContextTransitioning>)transitionContext{
    switch (self.type) {
        case HXDatePhotoViewPresentTransitionTypePresent:
            [self presentAnimation:transitionContext];
            break;
            
        case HXDatePhotoViewPresentTransitionTypeDismiss:
            [self dismissAnimation:transitionContext];
            break;
    }
}
- (void)presentAnim:(id<UIViewControllerContextTransitioning>)transitionContext Image:(UIImage *)image Model:(HXPhotoModel *)model FromVC:(UIViewController *)fromVC ToVC:(HXDatePhotoPreviewViewController *)toVC cell:(HXPhotoSubViewCell *)cell{
    model.tempImage = image;
    UIView *containerView = [transitionContext containerView];
    UIImageView *tempView = [[UIImageView alloc] initWithImage:image];
    UIView *tempBgView = [[UIView alloc] initWithFrame:containerView.bounds];
    tempView.clipsToBounds = YES;
    tempView.contentMode = UIViewContentModeScaleAspectFill;
    tempView.frame = [cell.imageView convertRect:cell.imageView.bounds toView:containerView];
    if (!image) {
        tempView.image = cell.imageView.image;
    }
    [tempBgView addSubview:tempView];
    [containerView addSubview:toVC.view];
    [toVC.view insertSubview:tempBgView atIndex:0];
    toVC.collectionView.hidden = YES;
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
    toVC.navigationController.navigationBar.userInteractionEnabled = NO;
    UIColor *tempColor = toVC.view.backgroundColor;
    toVC.view.backgroundColor = [tempColor colorWithAlphaComponent:0];
    cell.hidden = YES;
    [toVC setupDarkBtnAlpha:0.f];
    [UIView animateWithDuration:0.2 animations:^{
        toVC.view.backgroundColor = [tempColor colorWithAlphaComponent:1.f];
        [toVC setupDarkBtnAlpha:1.f];
    }];
    [UIView animateWithDuration:[self transitionDuration:transitionContext] delay:0 usingSpringWithDamping:0.75f initialSpringVelocity:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
//        tempView.frame = CGRectMake((width - imgWidht) / 2, (height - imgHeight) / 2 + hxTopMargin, imgWidht, imgHeight);
        tempView.frame = CGRectMake((width - imgWidht) / 2, (height - imgHeight) / 2, imgWidht, imgHeight);
    } completion:^(BOOL finished) {
        cell.hidden = NO;
        toVC.collectionView.hidden = NO;
        [tempBgView removeFromSuperview];
        [tempView removeFromSuperview];
        toVC.navigationController.navigationBar.userInteractionEnabled = YES;
        [transitionContext completeTransition:YES];
    }];
}
/**
 *  实现present动画
 */
- (void)presentAnimation:(id<UIViewControllerContextTransitioning>)transitionContext{
    HXDatePhotoPreviewViewController *toVC = (HXDatePhotoPreviewViewController *)[transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
    
    UIViewController *fromVC = [transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
    
    UICollectionView *collectionView = (UICollectionView *)self.photoView.collectionView;
    if ([fromVC isKindOfClass:[UINavigationController class]]) {
        UINavigationController *nav = (UINavigationController *)fromVC;
        fromVC = nav.viewControllers.lastObject;
    }else if ([fromVC isKindOfClass:[UITabBarController class]]) {
        UITabBarController *tabBar = (UITabBarController *)fromVC;
        if ([tabBar.selectedViewController isKindOfClass:[UINavigationController class]]) {
            UINavigationController *nav = (UINavigationController *)tabBar.selectedViewController;
            fromVC = nav.viewControllers.lastObject;
        }else {
            fromVC = tabBar.selectedViewController;
        }
    }
    HXPhotoSubViewCell *cell = (HXPhotoSubViewCell *)[collectionView cellForItemAtIndexPath:self.photoView.currentIndexPath];
    HXPhotoModel *model = cell.model;
    if (model.asset) {
        HXWeakSelf
        [HXPhotoTools getHighQualityFormatPhotoForPHAsset:model.asset size:CGSizeMake(model.endImageSize.width * 0.8, model.endImageSize.height * 0.8) completion:^(UIImage *image, NSDictionary *info) {
            [weakSelf presentAnim:transitionContext Image:image Model:model FromVC:fromVC ToVC:toVC cell:cell];
        } error:^(NSDictionary *info) {
            [weakSelf presentAnim:transitionContext Image:model.thumbPhoto Model:model FromVC:fromVC ToVC:toVC cell:cell];
        }];
    }else {
        [self presentAnim:transitionContext Image:model.thumbPhoto Model:model FromVC:fromVC ToVC:toVC cell:cell];
    }
}

/**
 *  实现dimiss动画
 */
- (void)dismissAnimation:(id<UIViewControllerContextTransitioning>)transitionContext {
    HXDatePhotoPreviewViewController *fromVC = (HXDatePhotoPreviewViewController *)[transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
    UIViewController *toVC = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
    if (!fromVC.modelArray.count) {
        UIView *containerView = [transitionContext containerView];
//        UIView *tempView = [fromVC.view snapshotViewAfterScreenUpdates:NO];
        [containerView addSubview:fromVC.view];
        [UIView animateWithDuration:[self transitionDuration:transitionContext] animations:^{
            fromVC.view.alpha = 0;
            fromVC.view.transform = CGAffineTransformMakeScale(1.5, 1.5);
        } completion:^(BOOL finished) {
//            [tempView removeFromSuperview];
            [transitionContext completeTransition:YES];
        }];
        return;
    }
    HXPhotoModel *model = [fromVC.modelArray objectAtIndex:fromVC.currentModelIndex];
    HXDatePhotoPreviewViewCell *fromCell = [fromVC currentPreviewCell:model];
    UIImageView *tempView;
    if (model.type == HXPhotoModelMediaTypeCameraPhoto) {
        tempView = [[UIImageView alloc] initWithImage:model.thumbPhoto];
    }else {
#if __has_include(<YYWebImage/YYWebImage.h>) || __has_include("YYWebImage.h")
        tempView = [[UIImageView alloc] initWithImage:fromCell.animatedImageView.image];
#else
        tempView = [[UIImageView alloc] initWithImage:fromCell.imageView.image];
#endif
    }
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
    
    HXPhotoSubViewCell *cell = (HXPhotoSubViewCell *)[collectionView cellForItemAtIndexPath:[self.photoView currentModelIndexPath:model]];
    if (!tempView.image) {
        tempView = [[UIImageView alloc] initWithImage:cell.imageView.image];
    }
    tempView.clipsToBounds = YES;
    tempView.contentMode = UIViewContentModeScaleAspectFill;
    
    
    UIView *containerView = [transitionContext containerView];
#if __has_include(<YYWebImage/YYWebImage.h>) || __has_include("YYWebImage.h") 
    tempView.frame = [fromCell.animatedImageView convertRect:fromCell.animatedImageView.bounds toView:containerView];
#else
    tempView.frame = [fromCell.imageView convertRect:fromCell.imageView.bounds toView:containerView];
#endif
    [containerView addSubview:tempView];
    if (model.type == HXPhotoModelMediaTypeCameraPhoto) {
        CGPoint center = tempView.center;
        tempView.hx_size = model.endImageSize;
        tempView.center = center;
    }
    
    CGRect rect = [cell convertRect:cell.bounds toView:containerView];
    cell.hidden = YES;
    fromVC.collectionView.hidden = YES;
//    fromVC.view.hidden = YES;
    
    [UIView animateWithDuration:[self transitionDuration:transitionContext] animations:^{
        fromVC.view.alpha = 0;
        if (cell) {
            tempView.frame = rect;
        }else {
            tempView.alpha = 0;
            tempView.transform = CGAffineTransformMakeScale(1.3, 1.3);
        }
    } completion:^(BOOL finished) {
        cell.hidden = NO;
        [tempView removeFromSuperview];
        [transitionContext completeTransition:YES];
    }];
}
@end
