//
//  HXPresentTransition.m
//  微博照片选择
//
//  Created by 洪欣 on 17/2/21.
//  Copyright © 2017年 洪欣. All rights reserved.
//

#import "HXPresentTransition.h"
#import "HXPhotoView.h"
#import "HXPhotoSubViewCell.h"
#import "HXPhotoPreviewViewController.h"
#import "HXPhotoPreviewViewCell.h"
#import "HXVideoPreviewViewController.h"

@interface HXPresentTransition ()
@property (assign, nonatomic) HXPresentTransitionType type;
@property (assign, nonatomic) HXPresentTransitionVcType vcType;
@property (strong, nonatomic) HXPhotoView *photoView ;
@end

@implementation HXPresentTransition

+ (instancetype)transitionWithTransitionType:(HXPresentTransitionType)type VcType:(HXPresentTransitionVcType)vcType withPhotoView:(HXPhotoView *)photoView  {
    return [[self alloc] initWithTransitionType:type VcType:vcType withPhotoView:photoView];
}

- (instancetype)initWithTransitionType:(HXPresentTransitionType)type VcType:(HXPresentTransitionVcType)vcType withPhotoView:(HXPhotoView *)photoView {
    self = [super init];
    if (self) {
        self.photoView = photoView;
        self.type = type;
        self.vcType = vcType;
    }
    return self;
}

- (NSTimeInterval)transitionDuration:(id<UIViewControllerContextTransitioning>)transitionContext{
    return 0.25;
}

- (void)animateTransition:(id<UIViewControllerContextTransitioning>)transitionContext{
    switch (_type) {
        case HXPresentTransitionTypePresent:
            [self presentAnimation:transitionContext];
            break;
            
        case HXPresentTransitionTypeDismiss:
            [self dismissAnimation:transitionContext];
            break;
    }
}
- (void)presentAnim:(id<UIViewControllerContextTransitioning>)transitionContext Image:(UIImage *)image Model:(HXPhotoModel *)model FromVC:(UIViewController *)fromVC ToVC:(UIViewController *)toVC cell:(HXPhotoSubViewCell *)cell{
    model.tempImage = image;
    UIView *containerView = [transitionContext containerView];
    UIImageView *tempView = [[UIImageView alloc] initWithImage:image];
    tempView.clipsToBounds = YES;
    tempView.contentMode = UIViewContentModeScaleAspectFill;
    tempView.frame = [cell.imageView convertRect:cell.imageView.bounds toView:containerView];
    if (!image) {
        tempView.image = cell.imageView.image;
    }
    // vc1可以隐藏了
    fromVC.view.hidden = YES;
    if (self.vcType == HXPresentTransitionVcTypePhoto) {
        HXPhotoPreviewViewController *vc = (HXPhotoPreviewViewController *)toVC;
        vc.collectionView.hidden = YES;
    }
    //将视图和vc2的view都加入ContainerView中
    [containerView addSubview:toVC.view];
    [containerView addSubview:tempView];
    CGFloat imgWidht = model.endImageSize.width;
    CGFloat imgHeight = model.endImageSize.height;
    CGFloat width = [UIScreen mainScreen].bounds.size.width;
    CGFloat height = [UIScreen mainScreen].bounds.size.height;
    
    [UIView animateWithDuration:[self transitionDuration:transitionContext] animations:^{
        tempView.frame = CGRectMake((width - imgWidht) / 2, (height - imgHeight) / 2 + (kNavigationBarHeight / 2), imgWidht, imgHeight);
    } completion:^(BOOL finished) {
        fromVC.view.hidden = NO;
        if (self.vcType == HXPresentTransitionVcTypePhoto) {
            HXPhotoPreviewViewController *vc = (HXPhotoPreviewViewController *)toVC;
            vc.collectionView.hidden = NO;
        }else {
            HXVideoPreviewViewController *vc = (HXVideoPreviewViewController *)toVC;
            [vc.maskView removeFromSuperview];
        }
        tempView.hidden = YES;
        [transitionContext completeTransition:YES];
    }];
}
/**
 *  实现present动画
 */
- (void)presentAnimation:(id<UIViewControllerContextTransitioning>)transitionContext{
    //通过viewControllerForKey取出转场前后的两个控制器，这里toVC就是vc1、fromVC就是vc2
    UIViewController *toVC = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
    UIViewController *fromVC = [transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
    UICollectionView *collectionView = (UICollectionView *)self.photoView.collectionView;
//    HXPhotoView *photoView;
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
    __weak typeof(self) weakSelf = self;
    [HXPhotoTools getHighQualityFormatPhotoForPHAsset:model.asset size:CGSizeMake(model.endImageSize.width * 0.8, model.endImageSize.height * 0.8) completion:^(UIImage *image, NSDictionary *info) {
        [weakSelf presentAnim:transitionContext Image:image Model:model FromVC:fromVC ToVC:toVC cell:cell];
    } error:^(NSDictionary *info) {
        [weakSelf presentAnim:transitionContext Image:model.thumbPhoto Model:model FromVC:fromVC ToVC:toVC cell:cell];
    }];
}

/**
 *  实现dimiss动画
 */
- (void)dismissAnimation:(id<UIViewControllerContextTransitioning>)transitionContext{
    //注意在dismiss的时候fromVC就是vc2了，toVC才是VC1了，注意理解这个逻辑关系
    UIViewController *fromVC = [transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
    UIViewController *toVC = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
    HXPhotoModel *model;
    UIImageView *tempView;
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
    if (self.vcType == HXPresentTransitionVcTypePhoto) {
        HXPhotoPreviewViewController *vc = (HXPhotoPreviewViewController *)fromVC;
        model = vc.modelList[vc.index];
        HXPhotoPreviewViewCell *previewCell = (HXPhotoPreviewViewCell *)[vc.collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForItem:vc.index inSection:0]];
        if (model.type == HXPhotoModelMediaTypePhotoGif) {
            [previewCell stopGifImage];
//            tempView = [[UIImageView alloc] initWithImage:previewCell.imageView.image];
        }
//        else {
            tempView = [[UIImageView alloc] initWithImage:previewCell.imageView.image];
//        } 
    }else {
        HXVideoPreviewViewController *vc = (HXVideoPreviewViewController *)fromVC;
        model = vc.model;
        tempView = [[UIImageView alloc] init];
        if (model.previewPhoto) {
            tempView.image = model.previewPhoto;
        }else {
            tempView.image = model.thumbPhoto;
        }
    }

    HXPhotoSubViewCell *cell = (HXPhotoSubViewCell *)[collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForItem:model.endCollectionIndex inSection:0]];
    if (!tempView.image) {
        tempView = [[UIImageView alloc] initWithImage:cell.imageView.image]; 
    }
    tempView.clipsToBounds = YES;
    tempView.contentMode = UIViewContentModeScaleAspectFill;
    CGFloat height = [UIScreen mainScreen].bounds.size.height;
    UIView *containerView = [transitionContext containerView];
    [containerView addSubview:tempView];
    tempView.frame = CGRectMake(0, 0, model.endImageSize.width, model.endImageSize.height);
    tempView.center = CGPointMake(containerView.frame.size.width / 2, (height - kNavigationBarHeight) / 2 + kNavigationBarHeight);
    CGRect rect = [collectionView convertRect:cell.frame toView:[UIApplication sharedApplication].keyWindow];
    cell.hidden = YES;
    fromVC.view.hidden = YES;
    
    [UIView animateWithDuration:[self transitionDuration:transitionContext] animations:^{
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
