//
//  HXPhotoViewTransition.m
//  HXPhotoPickerExample
//
//  Created by Silence on 2017/10/27.
//  Copyright © 2017年 Silence. All rights reserved.
//

#import "HXPhotoViewTransition.h"
#import "HXPhotoViewController.h"
#import "HXPhotoPreviewViewController.h"
#import "HXPhotoPreviewBottomView.h"
#import "HXPhotoEdit.h"
#import "HXAssetManager.h"

@interface HXPhotoViewTransition ()
@property (assign, nonatomic) HXPhotoViewTransitionType type;
@property (strong, nonatomic) UIImageView *imageView;
@property (assign, nonatomic) PHImageRequestID requestID;
@end

@implementation HXPhotoViewTransition

+ (instancetype)transitionWithType:(HXPhotoViewTransitionType)type {
    return [[self alloc] initWithTransitionType:type];
}

- (instancetype)initWithTransitionType:(HXPhotoViewTransitionType)type {
    self = [super init];
    if (self)  {
        self.type = type;
    }
    return self;
}
- (void)animateTransition:(nonnull id<UIViewControllerContextTransitioning>)transitionContext {
    switch (self.type) {
        case HXPhotoViewTransitionTypePush:
            [self pushAnimation:transitionContext];
            break;
        default:
            [self popAnimation:transitionContext];
            break;
    }
}

- (void)pushAnimation:(id<UIViewControllerContextTransitioning>)transitionContext {
    HXPhotoViewController *fromVC = (HXPhotoViewController *)[transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
    HXPhotoPreviewViewController *toVC = (HXPhotoPreviewViewController *)[transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
    HXPhotoModel *model = [toVC.modelArray objectAtIndex:toVC.currentModelIndex];
    UIImage *image = model.thumbPhoto ?: model.previewPhoto;;
    if (model.photoEdit) {
        image = model.photoEdit.editPreviewImage;
    }else if (model.asset){
        image = model.thumbPhoto ?: model.previewPhoto;
        PHImageRequestOptions *options = [[PHImageRequestOptions alloc] init];
        self.requestID = [HXAssetManager requestImageDataForAsset:model.asset options:options completion:^(NSData * _Nonnull imageData, UIImageOrientation orientation, NSDictionary<NSString *,id> * _Nonnull info) {
            if (imageData) {
                UIImage *image = [UIImage imageWithData:imageData];
                if (orientation != UIImageOrientationUp) {
                    image = [image hx_normalizedImage];
                }
                self.imageView.image = image;
            }
        }];
    }
    [self pushAnim:transitionContext image:image model:model fromVC:fromVC toVC:toVC];
}
- (void)pushAnim:(id<UIViewControllerContextTransitioning>)transitionContext image:(UIImage *)image model:(HXPhotoModel *)model fromVC:(HXPhotoViewController *)fromVC toVC:(HXPhotoPreviewViewController *)toVC {
    model.tempImage = image;
    HXPhotoViewCell *fromCell = [fromVC currentPreviewCell:model];
    if (!image && fromCell) {
        model.tempImage = fromCell.imageView.image;
        image = fromCell.imageView.image;
    }
    UIView *containerView = [transitionContext containerView];
    model.endImageSize = CGSizeZero;
    CGFloat imgWidht = model.endImageSize.width;
    CGFloat imgHeight = model.endImageSize.height;
    CGFloat width = [UIScreen mainScreen].bounds.size.width;
    CGFloat height = [UIScreen mainScreen].bounds.size.height; 
    self.imageView = [[UIImageView alloc] initWithImage:image];
    UIView *tempBgView = [[UIView alloc] initWithFrame:containerView.bounds];
    tempBgView.backgroundColor = [HXPhotoCommon photoCommon].isDark ? [[UIColor blackColor] colorWithAlphaComponent:0] : [toVC.manager.configuration.previewPhotoViewBgColor colorWithAlphaComponent:0];
    self.imageView.clipsToBounds = YES;
    self.imageView.contentMode = UIViewContentModeScaleAspectFill;
    if (fromCell) {
        self.imageView.frame = [fromCell.imageView convertRect:fromCell.imageView.bounds toView: containerView];
    }else {
        self.imageView.hx_size = CGSizeMake(self.imageView.hx_w * 1.5, self.imageView.hx_h * 1.5);
        self.imageView.center = CGPointMake(width / 2, height / 2);
    }
    [tempBgView addSubview:self.imageView];
    [fromVC.view insertSubview:tempBgView belowSubview:fromVC.bottomView];
    [containerView addSubview:fromVC.view];
    [containerView addSubview:toVC.view];
    toVC.collectionView.hidden = YES;
    toVC.view.backgroundColor = [UIColor clearColor];
    toVC.bottomView.alpha = 0;
    fromCell.hidden = YES;
    
    toVC.navigationController.navigationBar.userInteractionEnabled = NO;
    UIViewAnimationOptions option = UIViewAnimationOptionLayoutSubviews;
    
    [UIView animateWithDuration:0.2 animations:^{
        tempBgView.backgroundColor = [HXPhotoCommon photoCommon].isDark ? [[UIColor blackColor] colorWithAlphaComponent:1] : [toVC.manager.configuration.previewPhotoViewBgColor colorWithAlphaComponent:1];
    }];
    
    [UIView animateWithDuration:[self transitionDuration:transitionContext] delay:0 usingSpringWithDamping:0.8f initialSpringVelocity:0 options:option animations:^{
        if (imgHeight <= height) {
            self.imageView.frame = CGRectMake((width - imgWidht) / 2, (height - imgHeight) / 2, imgWidht, imgHeight);
        }else {
            self.imageView.frame = CGRectMake(0, 0, imgWidht, imgHeight);
        }
        toVC.bottomView.alpha = 1;
    } completion:^(BOOL finished) {
        fromCell.hidden = NO;
        [[PHImageManager defaultManager] cancelImageRequest:self.requestID];
        [toVC setCellImage:self.imageView.image];
        toVC.view.backgroundColor = [HXPhotoCommon photoCommon].isDark ? [UIColor blackColor] : toVC.manager.configuration.previewPhotoViewBgColor;
        toVC.collectionView.hidden = NO;
        [tempBgView removeFromSuperview];
        [self.imageView removeFromSuperview];
        toVC.navigationController.navigationBar.userInteractionEnabled = YES;
        [transitionContext completeTransition:YES];
    }];
}
- (void)popAnimation:(id<UIViewControllerContextTransitioning>)transitionContext {
    HXPhotoPreviewViewController *fromVC = (HXPhotoPreviewViewController *)[transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
    HXPhotoViewController *toVC = (HXPhotoViewController *)[transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
    HXPhotoModel *model = [fromVC.modelArray objectAtIndex:fromVC.currentModelIndex];
    
    HXPhotoPreviewViewCell *fromCell = [fromVC currentPreviewCell:model];
    HXPhotoViewCell *toCell = [toVC currentPreviewCell:model];
    UIImageView *tempView;
#if HasYYKitOrWebImage
    tempView = [[UIImageView alloc] initWithImage:fromCell.previewContentView.image];
#else
    tempView = [[UIImageView alloc] initWithImage:fromCell.previewContentView.image];
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
#pragma clang diagnostic push
#pragma clang diagnostic ignored"-Wdeprecated-declarations"
        [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationFade];
#pragma clang diagnostic pop
        [containerView insertSubview:tempBgView belowSubview:fromVC.view];
    }else {
        [toVC.view insertSubview:tempBgView belowSubview:toVC.bottomView];
        tempBgView.backgroundColor = [HXPhotoCommon photoCommon].isDark ? [[UIColor blackColor] colorWithAlphaComponent:1] : [fromVC.manager.configuration.previewPhotoViewBgColor colorWithAlphaComponent:1];
    }
    toVC.navigationController.navigationBar.userInteractionEnabled = NO;
    
    fromVC.collectionView.hidden = YES;
    toCell.hidden = YES;
    fromVC.view.backgroundColor = [UIColor clearColor];
     
    tempView.frame = [fromCell.previewContentView convertRect:fromCell.previewContentView.bounds toView:containerView];
    
    CGRect rect = [toCell.imageView convertRect:toCell.imageView.bounds toView: containerView];
    if (toCell) {
        [toVC scrollToPoint:toCell rect:rect];
    }
    
    UIViewAnimationOptions option = UIViewAnimationOptionLayoutSubviews;
    
    [UIView animateWithDuration:0.2 animations:^{
        fromVC.view.backgroundColor = [UIColor clearColor];
        fromVC.bottomView.alpha = 0;
        if (!fromVC.bottomView.userInteractionEnabled) {
            tempBgView.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0];
            //            toVC.navigationController.navigationBar.alpha = 1;
            //            toVC.bottomView.alpha = 1;
        }else {
            tempBgView.backgroundColor = [HXPhotoCommon photoCommon].isDark ? [[UIColor blackColor] colorWithAlphaComponent:0] : [fromVC.manager.configuration.previewPhotoViewBgColor colorWithAlphaComponent:0];
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
#pragma clang diagnostic push
#pragma clang diagnostic ignored"-Wdeprecated-declarations"
                [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationFade];
#pragma clang diagnostic pop
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
}

- (NSTimeInterval)transitionDuration:(nullable id<UIViewControllerContextTransitioning>)transitionContext {
    if (self.type == HXPhotoViewTransitionTypePush) {
        HXPhotoViewController *fromVC = (HXPhotoViewController *)[transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
        return fromVC.manager.configuration.pushTransitionDuration;
    }else {
        HXPhotoPreviewViewController *fromVC = (HXPhotoPreviewViewController *)[transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
        return fromVC.manager.configuration.popTransitionDuration;
    }
}
@end
