//
//  HXNaviTransition.m
//  微博照片选择
//
//  Created by 洪欣 on 17/2/9.
//  Copyright © 2017年 洪欣. All rights reserved.
//

#import "HXTransition.h"
#import "HXPhotoViewController.h"
#import "HXPhotoViewCell.h"
#import "HXPhotoPreviewViewController.h"
#import "HXPhotoPreviewViewCell.h"
#import "HXVideoPreviewViewController.h"
@interface HXTransition ()
@property (assign, nonatomic) HXTransitionType type;
@property (assign, nonatomic) HXTransitionVcType vcType;
@end

@implementation HXTransition

+ (instancetype)transitionWithType:(HXTransitionType)type VcType:(HXTransitionVcType)vcType
{
    return [[self alloc] initWithTransitionType:type VcType:vcType];
}

- (instancetype)initWithTransitionType:(HXTransitionType)type VcType:(HXTransitionVcType)vcType
{
    if (self = [super init]) {
        self.type = type;
        self.vcType = vcType;
    }
    return self;
}

- (NSTimeInterval)transitionDuration:(id<UIViewControllerContextTransitioning>)transitionContext
{
    return 0.25;
}

- (void)animateTransition:(id<UIViewControllerContextTransitioning>)transitionContext
{
    switch (self.type) {
        case HXTransitionTypePush:
            [self pushAnimation:transitionContext];
            break;
        default:
            [self popAnimation:transitionContext];
            break;
    }
}

- (void)pushAnimation:(id<UIViewControllerContextTransitioning>)transitionContext
{
    HXPhotoViewController *fromVC = (HXPhotoViewController *)[transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
    UIViewController *toVC = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
    HXPhotoModel *model;
    if (self.vcType == HXTransitionVcTypePhoto) {
        HXPhotoPreviewViewController *vc = (HXPhotoPreviewViewController *)toVC;
        model = vc.modelList[vc.index];
    }else {
        HXVideoPreviewViewController *vc = (HXVideoPreviewViewController *)toVC;
        model = vc.model;
    }
    if (model.previewPhoto) {
        [self pushAnim:transitionContext Image:model.previewPhoto Model:model FromVC:fromVC ToVC:toVC];
    }else {
        __weak typeof(self) weakSelf = self;
        [HXPhotoTools FetchPhotoForPHAsset:model.asset Size:CGSizeMake(model.endImageSize.width * 2, model.endImageSize.height * 2) deliveryMode:PHImageRequestOptionsDeliveryModeHighQualityFormat completion:^(UIImage *image, NSDictionary *info) {
            model.previewPhoto = image;
            [weakSelf pushAnim:transitionContext Image:image Model:model FromVC:fromVC ToVC:toVC];
        } error:^(NSDictionary *info) {
            [weakSelf pushAnim:transitionContext Image:model.thumbPhoto Model:model FromVC:fromVC ToVC:toVC];
        }];
    }
}

- (void)pushAnim:(id<UIViewControllerContextTransitioning>)transitionContext Image:(UIImage *)image Model:(HXPhotoModel *)model FromVC:(HXPhotoViewController *)fromVC ToVC:(UIViewController *)toVC
{
    HXPhotoViewCell *fromCell = (HXPhotoViewCell *)[fromVC.collectionView cellForItemAtIndexPath:fromVC.currentIndexPath];
    UIView *containerView = [transitionContext containerView];
    CGFloat imgWidht = model.endImageSize.width;
    CGFloat imgHeight = model.endImageSize.height;
    CGFloat width = [UIScreen mainScreen].bounds.size.width;
    CGFloat height = [UIScreen mainScreen].bounds.size.height;
    UIImageView *tempView = [[UIImageView alloc] initWithImage:image];
    tempView.clipsToBounds = YES;
    tempView.contentMode = UIViewContentModeScaleAspectFill;
    tempView.frame = [fromCell.imageView convertRect:fromCell.imageView.bounds toView: containerView];
    if (fromVC.isPreview) {
        tempView.center = CGPointMake(width / 2, height / 2);
    }
    [containerView addSubview:toVC.view];
    [containerView addSubview:tempView];
    if (self.vcType == HXTransitionVcTypePhoto) {
        HXPhotoPreviewViewController *vc = (HXPhotoPreviewViewController *)toVC;
        vc.collectionView.hidden = YES;
    }
    [UIView animateWithDuration:[self transitionDuration:transitionContext] animations:^{
        tempView.frame = CGRectMake((width - imgWidht) / 2, (height - imgHeight) / 2 + 32, imgWidht, imgHeight);
    } completion:^(BOOL finished) {
        if (self.vcType == HXTransitionVcTypePhoto) {
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

- (void)popAnimation:(id<UIViewControllerContextTransitioning>)transitionContext
{
    UIViewController *fromVC = [transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
    HXPhotoViewController *toVC = (HXPhotoViewController *)[transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
    HXPhotoModel *model;
    UIImageView *tempView;
    if (self.vcType == HXTransitionVcTypePhoto) {
        HXPhotoPreviewViewController *vc = (HXPhotoPreviewViewController *)fromVC;
        model = vc.modelList[vc.index];
        HXPhotoPreviewViewCell *previewCell = (HXPhotoPreviewViewCell *)[vc.collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForItem:vc.index inSection:0]];
        tempView = previewCell.imageView;
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
    tempView.clipsToBounds = YES;
    tempView.contentMode = UIViewContentModeScaleAspectFill;
    NSInteger index = 0;
    if (toVC.albumModel.index == 0) {
        if (toVC.manager.cameraList.count > 0) {
            if (model.type != HXPhotoModelMediaTypeCameraPhoto && model.type != HXPhotoModelMediaTypeCameraVideo) {
                index = model.albumListIndex + toVC.manager.cameraList.count;
            }else {
                index = model.albumListIndex;
            }
        }else {
            index = model.albumListIndex;
        }
    }else {
        index = model.albumListIndex;
    }
    HXPhotoViewCell *cell = (HXPhotoViewCell *)[toVC.collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForItem:index inSection:0]];
    if (!cell) {
        if (model.currentAlbumIndex == toVC.albumModel.index) {
            [toVC.collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForItem:index inSection:0] atScrollPosition:UICollectionViewScrollPositionNone animated:NO];
            [toVC.collectionView reloadItemsAtIndexPaths:@[[NSIndexPath indexPathForItem:index inSection:0]]];
            cell = (HXPhotoViewCell *)[toVC.collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForItem:index inSection:0]];
        }
    }
    CGFloat height = [UIScreen mainScreen].bounds.size.height;
    UIView *containerView = [transitionContext containerView];
    [containerView insertSubview:toVC.view atIndex:0];
    [containerView addSubview:tempView];
    tempView.frame = CGRectMake(0, 0, model.endImageSize.width, model.endImageSize.height);
    tempView.center = CGPointMake(containerView.frame.size.width / 2, (height - 64) / 2 + 64);
    CGRect rect = [toVC.collectionView convertRect:cell.frame toView:[UIApplication sharedApplication].keyWindow];
    if (rect.origin.y < 64) {
        [toVC.collectionView setContentOffset:CGPointMake(0, cell.frame.origin.y - 65)];
        rect = CGRectMake(cell.frame.origin.x, 65, cell.frame.size.width, cell.frame.size.height);
    }else if (rect.origin.y + rect.size.height > height - 51) {
        [toVC.collectionView setContentOffset:CGPointMake(0, cell.frame.origin.y - height + 51 + rect.size.height)];
        rect = CGRectMake(cell.frame.origin.x, height - 51 - cell.frame.size.height, cell.frame.size.width, cell.frame.size.height);
    }
    cell.hidden = YES;
    fromVC.view.hidden = YES;
    if (toVC.albumModel.index != model.currentAlbumIndex && toVC.isPreview) {
        cell.hidden = NO;
        fromVC.view.hidden = NO;
    }
    [UIView animateWithDuration:[self transitionDuration:transitionContext] animations:^{
        if (toVC.albumModel.index == model.currentAlbumIndex) {
            tempView.frame = rect;
        }else {
            fromVC.view.alpha = 0;
            tempView.alpha = 0;
        }
    } completion:^(BOOL finished) {
        cell.hidden = NO;
        toVC.isPreview = NO;
        [tempView removeFromSuperview];
        [transitionContext completeTransition:YES];
    }];
}

@end
