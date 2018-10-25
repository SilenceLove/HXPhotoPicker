//
//  HXDatePhotoPreviewViewController.m
//  照片选择器
//
//  Created by 洪欣 on 2017/10/14.
//  Copyright © 2017年 洪欣. All rights reserved.
//

#import "HXDatePhotoPreviewViewController.h"
#import "UIImage+HXExtension.h"
#import "HXDatePhotoPreviewBottomView.h"
#import "UIButton+HXExtension.h"
#import "HXDatePhotoViewTransition.h"
#import "HXDatePhotoInteractiveTransition.h"
#import "HXDatePhotoViewPresentTransition.h"
#import "HXPhotoCustomNavigationBar.h"
#import "HXCircleProgressView.h"
#import "HXDatePhotoEditViewController.h"
#import "UIViewController+HXExtension.h"
#import "HXDateVideoEditViewController.h"
#import "HXDatePhotoPersentInteractiveTransition.h"

#import "UIImageView+HXExtension.h"

@interface HXDatePhotoPreviewViewController ()
<
UICollectionViewDataSource,
UICollectionViewDelegate,
HXDatePhotoPreviewBottomViewDelegate,
HXDatePhotoEditViewControllerDelegate,
HXDateVideoEditViewControllerDelegate
>
@property (strong, nonatomic) UICollectionViewFlowLayout *flowLayout;
@property (strong, nonatomic) HXPhotoModel *currentModel;
@property (strong, nonatomic) UIView *customTitleView;
@property (strong, nonatomic) UILabel *titleLb;
@property (strong, nonatomic) UILabel *subTitleLb;
@property (strong, nonatomic) HXDatePhotoPreviewViewCell *tempCell;
@property (strong, nonatomic) UIButton *selectBtn;
@property (assign, nonatomic) BOOL orientationDidChange;
@property (assign, nonatomic) NSInteger beforeOrientationIndex;
@property (strong, nonatomic) HXDatePhotoInteractiveTransition *interactiveTransition;
@property (strong, nonatomic) HXDatePhotoPersentInteractiveTransition *persentInteractiveTransition;

@property (strong, nonatomic) HXPhotoCustomNavigationBar *navBar;
@property (strong, nonatomic) UINavigationItem *navItem;
@property (assign, nonatomic) BOOL isAddInteractiveTransition;
@property (strong, nonatomic) UIView *dismissTempTopView;
@property (strong, nonatomic) UIPageControl *bottomPageControl;
@property (strong, nonatomic) UIButton *darkCancelBtn;
@property (strong, nonatomic) UIButton *darkDeleteBtn;
@property (assign, nonatomic) BOOL statusBarShouldBeHidden;
@end

@implementation HXDatePhotoPreviewViewController
- (instancetype)init {
    self = [super init];
    if (self) {
        self.transitioningDelegate = self;
        self.modalPresentationStyle = UIModalPresentationCustom;
    }
    return self;
}
- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self setupUI];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(deviceOrientationChanged:) name:UIApplicationDidChangeStatusBarOrientationNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(deviceOrientationWillChanged:) name:UIApplicationWillChangeStatusBarOrientationNotification object:nil];
}
- (UIStatusBarStyle)preferredStatusBarStyle {
    return self.manager.configuration.statusBarStyle;
}
- (id<UIViewControllerAnimatedTransitioning>)navigationController:(UINavigationController *)navigationController animationControllerForOperation:(UINavigationControllerOperation)operation fromViewController:(UIViewController *)fromVC toViewController:(UIViewController *)toVC{
    if (operation == UINavigationControllerOperationPush) {
        return [HXDatePhotoViewTransition transitionWithType:HXDatePhotoViewTransitionTypePush];
    }else {
        if (![fromVC isKindOfClass:[self class]]) {
            return nil;
        }
        return [HXDatePhotoViewTransition transitionWithType:HXDatePhotoViewTransitionTypePop];
    }
}

- (id<UIViewControllerInteractiveTransitioning>)navigationController:(UINavigationController *)navigationController interactionControllerForAnimationController:(id<UIViewControllerAnimatedTransitioning>)animationController{
    return self.interactiveTransition.interation ? self.interactiveTransition : nil;
}
- (id<UIViewControllerAnimatedTransitioning>)animationControllerForPresentedController:(UIViewController *)presented presentingController:(UIViewController *)presenting sourceController:(UIViewController *)source{
    return [HXDatePhotoViewPresentTransition transitionWithTransitionType:HXDatePhotoViewPresentTransitionTypePresent photoView:self.photoView];
}

- (id<UIViewControllerAnimatedTransitioning>)animationControllerForDismissedController:(UIViewController *)dismissed{
    return [HXDatePhotoViewPresentTransition transitionWithTransitionType:HXDatePhotoViewPresentTransitionTypeDismiss photoView:self.photoView];
}
- (id<UIViewControllerInteractiveTransitioning>)interactionControllerForDismissal:(id<UIViewControllerAnimatedTransitioning>)animator {
    return self.persentInteractiveTransition.interation ? self.persentInteractiveTransition : nil;
}
- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    if (self.orientationDidChange) {
        self.orientationDidChange = NO;
        [self changeSubviewFrame];
    }
}
- (void)deviceOrientationChanged:(NSNotification *)notify {
    self.orientationDidChange = YES;
}
- (void)deviceOrientationWillChanged:(NSNotification *)notify {
    self.beforeOrientationIndex = self.currentModelIndex;
}
- (HXDatePhotoPreviewViewCell *)currentPreviewCell:(HXPhotoModel *)model {
    if (!model) {
        return nil;
    }
    return (HXDatePhotoPreviewViewCell *)[self.collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForItem:self.currentModelIndex inSection:0]];
}
- (void)changeSubviewFrame {
    UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
    HXPhotoModel *model = self.modelArray[self.currentModelIndex];
    if (orientation == UIInterfaceOrientationPortrait || UIInterfaceOrientationPortrait == UIInterfaceOrientationPortraitUpsideDown) {
        [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationFade];
        self.titleLb.hidden = NO;
        self.customTitleView.frame = CGRectMake(0, 0, 150, 44);
        self.titleLb.frame = CGRectMake(0, 9, 150, 14);
        self.subTitleLb.frame = CGRectMake(0, CGRectGetMaxY(self.titleLb.frame) + 4, 150, 12);
        self.titleLb.text = model.barTitle;
        self.subTitleLb.text = model.barSubTitle;
    }else if (orientation == UIInterfaceOrientationLandscapeRight || orientation == UIInterfaceOrientationLandscapeLeft){
        [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationFade];
        self.customTitleView.frame = CGRectMake(0, 0, 200, 30);
        self.titleLb.hidden = YES;
        self.subTitleLb.frame = CGRectMake(0, 0, 200, 30);
        self.subTitleLb.text = [NSString stringWithFormat:@"%@  %@",model.barTitle,model.barSubTitle];
    }
    CGFloat bottomMargin = hxBottomMargin;
    //    CGFloat leftMargin = 0;
    //    CGFloat rightMargin = 0;
    CGFloat width = self.view.hx_w;
    CGFloat itemMargin = 20;
    if (HX_IS_IPhoneX_All && (orientation == UIInterfaceOrientationLandscapeLeft || orientation == UIInterfaceOrientationLandscapeRight)) {
        bottomMargin = 21;
        //        leftMargin = 35;
        //        rightMargin = 35;
        //        width = self.view.hx_w - 70;
    }
//    self.flowLayout.itemSize = CGSizeMake(width, self.view.hx_h - hxTopMargin - bottomMargin);
    self.flowLayout.itemSize = CGSizeMake(width, self.view.hx_h);
    self.flowLayout.minimumLineSpacing = itemMargin;
    
    [self.collectionView setCollectionViewLayout:self.flowLayout];
    
    //    self.collectionView.contentInset = UIEdgeInsetsMake(0, leftMargin, 0, rightMargin);
//    self.collectionView.frame = CGRectMake(-(itemMargin / 2), hxTopMargin,self.view.hx_w + itemMargin, self.view.hx_h - hxTopMargin - bottomMargin);
    self.collectionView.frame = CGRectMake(-(itemMargin / 2), 0,self.view.hx_w + itemMargin, self.view.hx_h);
    self.collectionView.contentSize = CGSizeMake(self.modelArray.count * (self.view.hx_w + itemMargin), 0);
    
    [self.collectionView setContentOffset:CGPointMake(self.beforeOrientationIndex * (self.view.hx_w + itemMargin), 0)];
    
    [UIView performWithoutAnimation:^{
        [self.collectionView reloadItemsAtIndexPaths:@[[NSIndexPath indexPathForItem:self.beforeOrientationIndex inSection:0]]];
    }];
    
    CGFloat bottomViewHeight = self.view.hx_h - 50 - bottomMargin;
    if (self.outside) {
        if (self.exteriorPreviewStyle == HXPhotoViewPreViewShowStyleDefault) {
            self.navBar.frame = CGRectMake(0, 0, self.view.hx_w, hxNavigationBarHeight);
            self.bottomView.frame = CGRectMake(0, bottomViewHeight, self.view.hx_w, 50 + bottomMargin);
        }else if (self.exteriorPreviewStyle == HXPhotoViewPreViewShowStyleDark) {
            CGFloat topMargin = HX_IS_IPhoneX_All ? 45 : 30;
            if (self.previewShowDeleteButton) {
                self.darkDeleteBtn.frame = CGRectMake(self.view.hx_w - 100 - 15, topMargin, 100, 30);
            }
            self.darkCancelBtn.frame = CGRectMake(15, topMargin, 30, 30);
            self.bottomPageControl.frame = CGRectMake(0, self.view.hx_h - 30, self.view.hx_w, 10);
        }
    }else {
        self.bottomView.frame = CGRectMake(0, bottomViewHeight, self.view.hx_w, 50 + bottomMargin);
    }
    
    if (self.manager.configuration.previewCollectionView) {
        self.manager.configuration.previewCollectionView(self.collectionView);
    }
}
- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [[UIApplication sharedApplication] setStatusBarStyle:self.manager.configuration.statusBarStyle];
    if (self.exteriorPreviewStyle == HXPhotoViewPreViewShowStyleDark) {
        self.statusBarShouldBeHidden = YES;
        [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationFade];
    }
}
- (BOOL)prefersStatusBarHidden {
    if (!self) {
        return [super prefersStatusBarHidden];
    }
    return self.statusBarShouldBeHidden;
}
- (UIStatusBarAnimation)preferredStatusBarUpdateAnimation {
    return UIStatusBarAnimationFade;
}
- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    HXPhotoModel *model = self.modelArray[self.currentModelIndex];
    self.currentModel = model;
    HXDatePhotoPreviewViewCell *cell = (HXDatePhotoPreviewViewCell *)[self.collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForItem:self.currentModelIndex inSection:0]];
    if (!cell) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.25 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            HXDatePhotoPreviewViewCell *tempCell = (HXDatePhotoPreviewViewCell *)[self.collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForItem:self.currentModelIndex inSection:0]];
            self.tempCell = tempCell;
            [tempCell requestHDImage];
        });
    }else {
        self.tempCell = cell;
        [cell requestHDImage];
    }
    if (!self.isAddInteractiveTransition) {
        if (!self.outside) {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.25 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                //初始化手势过渡的代理
                self.interactiveTransition = [[HXDatePhotoInteractiveTransition alloc] init];
                //给当前控制器的视图添加手势
                [self.interactiveTransition addPanGestureForViewController:self];
            });
        }else if (!self.disableaPersentInteractiveTransition) {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.25 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                //初始化手势过渡的代理
                self.persentInteractiveTransition = [[HXDatePhotoPersentInteractiveTransition alloc] init];
                //给当前控制器的视图添加手势
                [self.persentInteractiveTransition addPanGestureForViewController:self photoView:self.photoView];
            });
        }
        self.isAddInteractiveTransition = YES;
    }
}
- (void)viewWillDisappear:(BOOL)animated {
    if (self.exteriorPreviewStyle == HXPhotoViewPreViewShowStyleDark) {
        self.statusBarShouldBeHidden = NO;
        [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationFade];
    }
    HXDatePhotoPreviewViewCell *cell = (HXDatePhotoPreviewViewCell *)[self.collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForItem:self.currentModelIndex inSection:0]];
    cell.stopCancel = self.stopCancel;
    [cell cancelRequest];
    self.stopCancel = NO;
}
- (void)setupUI {
    self.navigationItem.titleView = self.customTitleView;
    [self.view addSubview:self.collectionView];
    if (self.exteriorPreviewStyle == HXPhotoViewPreViewShowStyleDefault) {
        self.view.backgroundColor = [UIColor whiteColor];
        [self.view addSubview:self.bottomView];
    }else if (self.exteriorPreviewStyle == HXPhotoViewPreViewShowStyleDark) {
        self.view.backgroundColor = [UIColor blackColor];
    }
    self.beforeOrientationIndex = self.currentModelIndex;
    [self changeSubviewFrame];
    HXPhotoModel *model = self.modelArray[self.currentModelIndex];
    self.bottomView.outside = self.outside;
    
    if (self.manager.type == HXPhotoManagerSelectedTypeVideo && !self.manager.configuration.videoCanEdit) {
        self.bottomView.hideEditBtn = YES;
    }else if (self.manager.type == HXPhotoManagerSelectedTypePhoto && !self.manager.configuration.photoCanEdit) {
        self.bottomView.hideEditBtn = YES;
    }else {
        if (!self.manager.configuration.videoCanEdit && !self.manager.configuration.photoCanEdit) {
            self.bottomView.hideEditBtn = YES;
        }
    }
    
    if (!self.outside) {
        if (self.manager.configuration.navigationTitleSynchColor) {
            self.titleLb.textColor = self.manager.configuration.themeColor;
            self.subTitleLb.textColor = self.manager.configuration.themeColor;
        }else {
            UIColor *titleColor = [self.navigationController.navigationBar.titleTextAttributes objectForKey:NSForegroundColorAttributeName];
            if (titleColor) {
                self.titleLb.textColor = titleColor;
                self.subTitleLb.textColor = titleColor;
            }
            if (self.manager.configuration.navigationTitleColor) {
                self.titleLb.textColor = self.manager.configuration.navigationTitleColor;
                self.subTitleLb.textColor = self.manager.configuration.navigationTitleColor;
            }
        }
        if (model.subType == HXPhotoModelMediaSubTypeVideo) {
            self.bottomView.enabled = self.manager.configuration.videoCanEdit;
        } else {
            if (!self.manager.configuration.selectTogether) {
                if (self.manager.selectedVideoArray.count > 0) {
                    self.bottomView.enabled = NO;
                }else {
                    if ([self.manager beforeSelectPhotoCountIsMaximum] && !model.selected) {
                        self.bottomView.enabled = NO;
                    }else {
                        self.bottomView.enabled = self.manager.configuration.photoCanEdit;
                    }
                }
            }else {
                if ([self.manager beforeSelectPhotoCountIsMaximum] && !model.selected) {
                    self.bottomView.enabled = NO;
                }else {
                    self.bottomView.enabled = self.manager.configuration.photoCanEdit;
                }
            }
        }
        self.bottomView.selectCount = [self.manager selectedCount];
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:self.selectBtn];
        self.selectBtn.selected = model.selected;
        [self.selectBtn setTitle:model.selectIndexStr forState:UIControlStateSelected];
        self.selectBtn.backgroundColor = self.selectBtn.selected ? self.manager.configuration.themeColor : nil;
        if ([self.manager.selectedArray containsObject:model]) {
            self.bottomView.currentIndex = [[self.manager selectedArray] indexOfObject:model];
        }else {
            [self.bottomView deselected];
        }
        if (self.manager.configuration.singleSelected) {
            self.selectBtn.hidden = YES;
            if (self.manager.configuration.singleJumpEdit) {
                self.bottomView.hideEditBtn = YES;
            }
        }else {
            #pragma mark - < 单选视频时隐藏选择按钮 >
            if (model.needHideSelectBtn) {
                self.selectBtn.hidden = YES;
                self.selectBtn.userInteractionEnabled = NO;
            }
        }
    }else {
        self.bottomView.selectCount = [self.manager afterSelectedCount];
        if ([self.manager.afterSelectedArray containsObject:model]) {
            self.bottomView.currentIndex = [[self.manager afterSelectedArray] indexOfObject:model];
        }else {
            [self.bottomView deselected];
        }
        if (model.subType == HXPhotoModelMediaSubTypeVideo) {
            self.bottomView.enabled = self.manager.configuration.videoCanEdit;
        } else {
            self.bottomView.enabled = self.manager.configuration.photoCanEdit;
        }
        if (self.exteriorPreviewStyle == HXPhotoViewPreViewShowStyleDefault) {
            [self.view addSubview:self.navBar];
            [self.navBar setTintColor:self.manager.configuration.themeColor];
            if (self.manager.configuration.navBarBackgroudColor) {
                self.navBar.barTintColor = self.manager.configuration.navBarBackgroudColor;
            }
            if (self.manager.configuration.navigationBar) {
                self.manager.configuration.navigationBar(self.navBar, self);
            }
            if (self.manager.configuration.navigationTitleSynchColor) {
                self.titleLb.textColor = self.manager.configuration.themeColor;
                self.subTitleLb.textColor = self.manager.configuration.themeColor;
            }else {
                UIColor *titleColor = [self.navBar.titleTextAttributes objectForKey:NSForegroundColorAttributeName];
                if (titleColor) {
                    self.titleLb.textColor = titleColor;
                    self.subTitleLb.textColor = titleColor;
                }
                if (self.manager.configuration.navigationTitleColor) {
                    self.titleLb.textColor = self.manager.configuration.navigationTitleColor;
                    self.subTitleLb.textColor = self.manager.configuration.navigationTitleColor;
                }
            }
        }else if (self.exteriorPreviewStyle == HXPhotoViewPreViewShowStyleDark) {
            
            [self.view addSubview:self.darkCancelBtn];
            if (self.previewShowDeleteButton) {
                [self.view addSubview:self.darkDeleteBtn];
            }
            if ([self.manager.afterSelectedArray containsObject:model]) {
                self.bottomPageControl.currentPage = [[self.manager afterSelectedArray] indexOfObject:model];
            }
            [self.view addSubview:self.bottomPageControl];
        }
    }
    if (self.manager.configuration.previewBottomView) {
        self.manager.configuration.previewBottomView(self.bottomView);
    }
}
- (void)didSelectClick:(UIButton *)button {
    if (self.modelArray.count <= 0 || self.outside) {
        [self.view showImageHUDText:[NSBundle hx_localizedStringForKey:@"没有照片可选!"]];
        return;
    }
    HXPhotoModel *model = self.modelArray[self.currentModelIndex];
    if (model.isICloud) {
        HXDatePhotoPreviewViewCell *cell = (HXDatePhotoPreviewViewCell *)[self.collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForItem:self.currentModelIndex inSection:0]];
        [cell cancelRequest];
        [cell requestHDImage];
        [self.view showImageHUDText:[NSBundle hx_localizedStringForKey:@"正在下载iCloud上的资源"]];
        return;
    }
    if (button.selected) {
        button.selected = NO;
        [self.manager beforeSelectedListdeletePhotoModel:model];
    }else {
        NSString *str = [self.manager maximumOfJudgment:model];
        if (str) {
            [self.view showImageHUDText:str];
            return;
        }
        HXDatePhotoPreviewViewCell *cell = (HXDatePhotoPreviewViewCell *)[self.collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForItem:self.currentModelIndex inSection:0]];
        
#if __has_include(<YYWebImage/YYWebImage.h>) || __has_include("YYWebImage.h")
        if (model.type == HXPhotoModelMediaTypePhotoGif) {
            if (cell.animatedImageView.image.images.count > 0) {
                model.thumbPhoto = cell.animatedImageView.image.images.firstObject;
                model.previewPhoto = cell.animatedImageView.image.images.firstObject;
            }else {
                model.thumbPhoto = cell.animatedImageView.image;
                model.previewPhoto = cell.animatedImageView.image;
            }
        }else {
            model.thumbPhoto = cell.animatedImageView.image;
            model.previewPhoto = cell.animatedImageView.image;
        }
#else
        if (model.type == HXPhotoModelMediaTypePhotoGif) {
            if (cell.imageView.image.images.count > 0) {
                model.thumbPhoto = cell.imageView.image.images.firstObject;
                model.previewPhoto = cell.imageView.image.images.firstObject;
            }else {
                model.thumbPhoto = cell.imageView.image;
                model.previewPhoto = cell.imageView.image;
            }
        }else {
            model.thumbPhoto = cell.imageView.image;
            model.previewPhoto = cell.imageView.image;
        }
#endif
        [self.manager beforeSelectedListAddPhotoModel:model];
        button.selected = YES;
        [button setTitle:model.selectIndexStr forState:UIControlStateSelected];
        CAKeyframeAnimation *anim = [CAKeyframeAnimation animationWithKeyPath:@"transform.scale"];
        anim.duration = 0.25;
        anim.values = @[@(1.2),@(0.8),@(1.1),@(0.9),@(1.0)];
        [button.layer addAnimation:anim forKey:@""];
    }
    button.backgroundColor = button.selected ? self.manager.configuration.themeColor : nil;
    if ([self.delegate respondsToSelector:@selector(datePhotoPreviewControllerDidSelect:model:)]) {
        [self.delegate datePhotoPreviewControllerDidSelect:self model:model];
    }
    self.bottomView.selectCount = [self.manager selectedCount];
    if (button.selected) {
        [self.bottomView insertModel:model];
    }else {
        [self.bottomView deleteModel:model];
    }
}
#pragma mark - < UICollectionViewDataSource >
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return [self.modelArray count];
}
- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    HXDatePhotoPreviewViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"DatePreviewCellId" forIndexPath:indexPath];
    HXPhotoModel *model = self.modelArray[indexPath.item];
    cell.model = model;
    HXWeakSelf
    [cell setCellDidPlayVideoBtn:^(BOOL play) {
        if (weakSelf.exteriorPreviewStyle == HXPhotoViewPreViewShowStyleDark) {
            return;
        }
        if (play) {
            if (weakSelf.bottomView.userInteractionEnabled) {
                [weakSelf setSubviewAlphaAnimate:YES];
            }
        }else {
            if (!weakSelf.bottomView.userInteractionEnabled) {
                [weakSelf setSubviewAlphaAnimate:YES];
            }
        }
    }];
    [cell setCellDownloadICloudAssetComplete:^(HXDatePhotoPreviewViewCell *myCell) {
        if ([weakSelf.delegate respondsToSelector:@selector(datePhotoPreviewDownLoadICloudAssetComplete:model:)]) {
            [weakSelf.delegate datePhotoPreviewDownLoadICloudAssetComplete:weakSelf model:myCell.model];
        }
    }];
    cell.cellDownloadImageComplete = ^(HXDatePhotoPreviewViewCell *myCell) {
        if ([weakSelf.delegate respondsToSelector:@selector(datePhotoPreviewCellDownloadImageComplete:model:)]) {
            [weakSelf.delegate datePhotoPreviewCellDownloadImageComplete:weakSelf model:myCell.model];
        }
    };
    [cell setCellTapClick:^{
        if (weakSelf.exteriorPreviewStyle == HXPhotoViewPreViewShowStyleDark &&
            weakSelf.outside) {
            [weakSelf dismissClick];
        }else {
            [weakSelf setSubviewAlphaAnimate:YES];
        }
    }];
    return cell;
}

- (void)setSubviewAlphaAnimate:(BOOL)animete duration:(NSTimeInterval)duration {
    if (self.exteriorPreviewStyle == HXPhotoViewPreViewShowStyleDark) {
        return;
    }
    BOOL hide = NO;
    if (self.bottomView.alpha == 1) {
        hide = YES;
    }
    if (!hide) {
        [self.navigationController setNavigationBarHidden:hide animated:NO];
    }
    self.statusBarShouldBeHidden = hide;
    self.bottomView.userInteractionEnabled = !hide;
    [self preferredStatusBarUpdateAnimation];
    if (animete) {
        [[UIApplication sharedApplication] setStatusBarHidden:hide withAnimation:UIStatusBarAnimationFade];
        [UIView animateWithDuration:duration animations:^{
            self.navigationController.navigationBar.alpha = hide ? 0 : 1;
            if (self.outside) {
                self.navBar.alpha = hide ? 0 : 1;
            }
            self.view.backgroundColor = hide ? [UIColor blackColor] : [UIColor whiteColor];
            self.collectionView.backgroundColor = hide ? [UIColor blackColor] : [UIColor whiteColor];
            self.bottomView.alpha = hide ? 0 : 1;
        } completion:^(BOOL finished) {
            if (hide) {
                [self.navigationController setNavigationBarHidden:hide animated:NO];
            }
        }];
    }else {
        [[UIApplication sharedApplication] setStatusBarHidden:hide];
        self.navigationController.navigationBar.alpha = hide ? 0 : 1;
        if (self.outside) {
            self.navBar.alpha = hide ? 0 : 1;
        }
        self.view.backgroundColor = hide ? [UIColor blackColor] : [UIColor whiteColor];
        self.collectionView.backgroundColor = hide ? [UIColor blackColor] : [UIColor whiteColor];
        self.bottomView.alpha = hide ? 0 : 1;
        if (hide) {
            [self.navigationController setNavigationBarHidden:hide];
        }
    }
}
- (void)setSubviewAlphaAnimate:(BOOL)animete {
    [self setSubviewAlphaAnimate:animete duration:0.15];
}
- (void)collectionView:(UICollectionView *)collectionView willDisplayCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath {
    [(HXDatePhotoPreviewViewCell *)cell resetScale];
}
- (void)collectionView:(UICollectionView *)collectionView didEndDisplayingCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath {
    [(HXDatePhotoPreviewViewCell *)cell cancelRequest];
}
#pragma mark - < UICollectionViewDelegate >
- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if (scrollView != self.collectionView) {
        return;
    }
    CGFloat width = [UIScreen mainScreen].bounds.size.width;
    CGFloat offsetx = self.collectionView.contentOffset.x;
    NSInteger currentIndex = (offsetx + (width + 20) * 0.5) / (width + 20);
    if (currentIndex > self.modelArray.count - 1) {
        currentIndex = self.modelArray.count - 1;
    }
    if (currentIndex < 0) {
        currentIndex = 0;
    }
    if (self.modelArray.count > 0) {
        if (self.exteriorPreviewStyle == HXPhotoViewPreViewShowStyleDark) {
            self.bottomPageControl.currentPage = currentIndex;
        }
        HXPhotoModel *model = self.modelArray[currentIndex];
        if (model.subType == HXPhotoModelMediaSubTypeVideo) {
            // 为视频时
//            self.bottomView.enabled = self.manager.configuration.videoCanEdit;
            if (self.manager.configuration.singleSelected) {
                if (!self.manager.configuration.singleJumpEdit) {
                    self.bottomView.hideEditBtn = !self.manager.configuration.videoCanEdit;
                }else {
                    self.bottomView.hideEditBtn = YES;
                }
            }else {
                self.bottomView.hideEditBtn = !self.manager.configuration.videoCanEdit;
            }
        }else {
            if (self.manager.configuration.singleSelected) {
                if (!self.manager.configuration.singleJumpEdit) {
                    self.bottomView.hideEditBtn = !self.manager.configuration.photoCanEdit;
                }else {
                    self.bottomView.hideEditBtn = YES;
                }
            }else {
                self.bottomView.hideEditBtn = !self.manager.configuration.photoCanEdit;
            }
            if (!self.manager.configuration.selectTogether) {
                // 照片,视频不能同时选择时
                if (self.manager.selectedVideoArray.count > 0) {
                    // 如果有选择视频那么照片就不能编辑
                    self.bottomView.enabled = NO;
                }else {
                    // 没有选择视频时
                    if ([self.manager beforeSelectPhotoCountIsMaximum] && !model.selected) {
                        // 当选择照片数达到最大数且当前照片没选中时就不能编辑
                        self.bottomView.enabled = NO;
                    }else {
                        // 反之就能
                        self.bottomView.enabled = self.manager.configuration.photoCanEdit;
                    }
                }
            }else {
                // 能同时选择时
                if ([self.manager beforeSelectPhotoCountIsMaximum] && !model.selected) {
                    // 当选择照片数达到最大数且当前照片没选中时就不能编辑
                    self.bottomView.enabled = NO;
                }else {
                    // 反之就能
                    self.bottomView.enabled = self.manager.configuration.photoCanEdit;
                }
            }
        }
        UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
        if (orientation == UIInterfaceOrientationPortrait || UIInterfaceOrientationPortrait == UIInterfaceOrientationPortraitUpsideDown) {
            self.titleLb.text = model.barTitle;
            self.subTitleLb.text = model.barSubTitle;
        }else if (orientation == UIInterfaceOrientationLandscapeRight || orientation == UIInterfaceOrientationLandscapeLeft){
            self.subTitleLb.text = [NSString stringWithFormat:@"%@  %@",model.barTitle,model.barSubTitle];
        }
        self.selectBtn.selected = model.selected;
        [self.selectBtn setTitle:model.selectIndexStr forState:UIControlStateSelected];
        self.selectBtn.backgroundColor = self.selectBtn.selected ? self.manager.configuration.themeColor : nil;
        if (self.outside) {
            /*
             if ([[self.manager afterSelectedArray] containsObject:model]) {
                self.bottomView.currentIndex = [[self.manager afterSelectedArray] indexOfObject:model];
             }else {
                [self.bottomView deselected];
             }
             */
            if ([self.modelArray containsObject:model]) {
                self.bottomView.currentIndex = [self.modelArray indexOfObject:model];
            }else {
                [self.bottomView deselected];
            }
        }else {
            if (!self.manager.configuration.singleSelected) {
#pragma mark - < 单选视频时隐藏选择按钮 >
                if (model.needHideSelectBtn) {
                    self.selectBtn.hidden = YES;
                    self.selectBtn.userInteractionEnabled = NO;
                }else {
                    self.selectBtn.hidden = NO;
                    self.selectBtn.userInteractionEnabled = YES;
                }
            }
            if ([[self.manager selectedArray] containsObject:model]) {
                self.bottomView.currentIndex = [[self.manager selectedArray] indexOfObject:model];
            }else {
                [self.bottomView deselected];
            }
        }
    }
    self.currentModelIndex = currentIndex;
}
- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    if (self.modelArray.count > 0) {
        HXDatePhotoPreviewViewCell *cell = (HXDatePhotoPreviewViewCell *)[self.collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForItem:self.currentModelIndex inSection:0]];
        HXPhotoModel *model = self.modelArray[self.currentModelIndex];
        self.currentModel = model;
        [cell requestHDImage];
    }
}
- (void)datePhotoPreviewBottomViewDidItem:(HXPhotoModel *)model currentIndex:(NSInteger)currentIndex beforeIndex:(NSInteger)beforeIndex {
    if ([self.modelArray containsObject:model]) {
        NSInteger index = [self.modelArray indexOfObject:model];
        if (self.currentModelIndex == index) {
            return;
        }
        self.currentModelIndex = index;
        [self.collectionView setContentOffset:CGPointMake(self.currentModelIndex * (self.view.hx_w + 20), 0) animated:NO];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self scrollViewDidEndDecelerating:self.collectionView];
        });
    }else {
        if (beforeIndex == -1) {
            [self.bottomView deselectedWithIndex:currentIndex];
        }
        self.bottomView.currentIndex = beforeIndex;
    }
}
- (void)datePhotoPreviewBottomViewDidEdit:(HXDatePhotoPreviewBottomView *)bottomView {
    if (!self.modelArray.count) {
        [self.view showImageHUDText:[NSBundle hx_localizedStringForKey:@"当前没有可编辑的资源"]];
        return;
    }
    if (self.currentModel.networkPhotoUrl) {
        if (self.currentModel.downloadError) {
            [self.view showImageHUDText:[NSBundle hx_localizedStringForKey:@"下载失败"]];
            return;
        }
        if (!self.currentModel.downloadComplete) {
            [self.view showImageHUDText:[NSBundle hx_localizedStringForKey:@"照片正在下载"]];
            return;
        }
    }
    HXPhotoModel *model = [self.modelArray objectAtIndex:self.currentModelIndex];
    if (self.currentModel.subType == HXPhotoModelMediaSubTypePhoto) {
        if (self.manager.configuration.replacePhotoEditViewController) {
#pragma mark - < 替换图片编辑 >
            if (self.manager.configuration.shouldUseEditAsset) {
                self.manager.configuration.shouldUseEditAsset(self, self.outside, self.manager, model);
            }
            HXWeakSelf
            self.manager.configuration.usePhotoEditComplete = ^(HXPhotoModel *beforeModel, HXPhotoModel *afterModel) {
                [weakSelf datePhotoEditViewControllerDidClipClick:nil beforeModel:beforeModel afterModel:afterModel];
            };
        }else {
            HXDatePhotoEditViewController *vc = [[HXDatePhotoEditViewController alloc] init];
            vc.model = [self.modelArray objectAtIndex:self.currentModelIndex];
            vc.delegate = self;
            vc.manager = self.manager;
            if (self.outside) {
                vc.outside = YES;
                [self presentViewController:vc animated:NO completion:nil];
            }else {
                [self.navigationController pushViewController:vc animated:NO];
            }
        }
    }else {
        if (self.manager.configuration.replaceVideoEditViewController) {
#pragma mark - < 替换视频编辑 >
            if (self.manager.configuration.shouldUseEditAsset) {
                self.manager.configuration.shouldUseEditAsset(self, self.outside, self.manager, model);
            }
            __weak typeof(self) weakSelf = self;
            self.manager.configuration.useVideoEditComplete = ^(HXPhotoModel *beforeModel, HXPhotoModel *afterModel) {
                [weakSelf datePhotoEditViewControllerDidClipClick:nil beforeModel:beforeModel afterModel:afterModel];
            };
        }else {
//            [self.view showImageHUDText:[NSBundle hx_localizedStringForKey:@"功能还在开发中^_^"]];
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"要使用视频编辑功能，请先替换视频编辑界面" message:nil delegate:nil cancelButtonTitle:nil otherButtonTitles:@"好的", nil];
            [alert show];
//            HXDateVideoEditViewController *vc = [[HXDateVideoEditViewController alloc] init];
//            vc.model = [self.modelArray objectAtIndex:self.currentModelIndex];
//            vc.delegate = self;
//            vc.manager = self.manager;
//            if (self.outside) {
//                vc.outside = YES;
//                [self presentViewController:vc animated:NO completion:nil];
//            }else {
//                [self.navigationController pushViewController:vc animated:NO];
//            }
        }
    }
}
- (void)datePhotoPreviewBottomViewDidDone:(HXDatePhotoPreviewBottomView *)bottomView {
    if (self.outside) {
        [self dismissViewControllerAnimated:YES completion:nil];
        return;
    }
    if (self.modelArray.count == 0) {
        [self.view showImageHUDText:[NSBundle hx_localizedStringForKey:@"没有照片可选!"]];
        return;
    }
    HXPhotoModel *model = self.modelArray[self.currentModelIndex];
    if (self.manager.configuration.singleSelected) {
        if (model.type == HXPhotoModelMediaTypeVideo ) {
            if (model.asset.duration > self.manager.configuration.videoMaxDuration) {
                [self.view showImageHUDText: [NSBundle hx_localizedStringForKey:@"视频过大,无法选择"]];
                return;
            }else if (model.asset.duration < 3.f) {
                [self.view showImageHUDText: [NSBundle hx_localizedStringForKey:@"视频少于3秒,无法选择"]];
                return;
            }
        }else if (model.type == HXPhotoModelMediaTypeCameraVideo) {
            if (model.videoDuration > self.manager.configuration.videoMaxDuration) {
                [self.view showImageHUDText: [NSBundle hx_localizedStringForKey:@"视频过大,无法选择"]];
                return;
            }else if (model.videoDuration < 3.f) {
                [self.view showImageHUDText: [NSBundle hx_localizedStringForKey:@"视频少于3秒,无法选择"]];
                return;
            }
        }
        if ([self.delegate respondsToSelector:@selector(datePhotoPreviewSingleSelectedClick:model:)]) {
            [self.delegate datePhotoPreviewSingleSelectedClick:self model:model];
        }
        return;
    }
    BOOL max = NO;
    if ([self.manager selectedCount] == self.manager.configuration.maxNum) {
        // 已经达到最大选择数
        max = YES;
    }
    if (self.manager.type == HXPhotoManagerSelectedTypePhotoAndVideo) {
        if ((model.type == HXPhotoModelMediaTypePhoto || model.type == HXPhotoModelMediaTypePhotoGif) || (model.type == HXPhotoModelMediaTypeCameraPhoto || model.type == HXPhotoModelMediaTypeLivePhoto)) {
            if (self.manager.configuration.videoMaxNum > 0) {
                if (!self.manager.configuration.selectTogether) { // 是否支持图片视频同时选择
                    if (self.manager.selectedVideoArray.count > 0 ) {
                        // 已经选择了视频,不能再选图片
                        max = YES;
                    }
                }
            }
            if ([self.manager beforeSelectPhotoCountIsMaximum]) {
                max = YES;
                // 已经达到图片最大选择数
            }
        }
    }else if (self.manager.type == HXPhotoManagerSelectedTypePhoto) {
        if ([self.manager beforeSelectPhotoCountIsMaximum]) {
            // 已经达到图片最大选择数
            max = YES;
        }
    }
    if ([self.manager selectedCount] == 0) {
        if (model.type == HXPhotoModelMediaTypeVideo ) {
            if (model.asset.duration > self.manager.configuration.videoMaxDuration) {
                [self.view showImageHUDText: [NSBundle hx_localizedStringForKey:@"视频过大,无法选择"]];
                return;
            }else if (model.asset.duration < 3.f) {
                [self.view showImageHUDText: [NSBundle hx_localizedStringForKey:@"视频少于3秒,无法选择"]];
                return;
            }
        }else if (model.type == HXPhotoModelMediaTypeCameraVideo) {
            if (model.videoDuration > self.manager.configuration.videoMaxDuration) {
                [self.view showImageHUDText: [NSBundle hx_localizedStringForKey:@"视频过大,无法选择"]];
                return;
            }else if (model.videoDuration < 3.f) {
                [self.view showImageHUDText: [NSBundle hx_localizedStringForKey:@"视频少于3秒,无法选择"]];
                return;
            }
        }
        if (!self.selectBtn.selected && !max && self.modelArray.count > 0) {
//            model.selected = YES;
            HXDatePhotoPreviewViewCell *cell = (HXDatePhotoPreviewViewCell *)[self.collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForItem:self.currentModelIndex inSection:0]];
#if __has_include(<YYWebImage/YYWebImage.h>) || __has_include("YYWebImage.h")
            if (model.type == HXPhotoModelMediaTypePhotoGif) {
                if (cell.animatedImageView.image.images.count > 0) {
                    model.thumbPhoto = cell.animatedImageView.image.images.firstObject;
                    model.previewPhoto = cell.animatedImageView.image.images.firstObject;
                }else {
                    model.thumbPhoto = cell.animatedImageView.image;
                    model.previewPhoto = cell.animatedImageView.image;
                }
            }else {
                model.thumbPhoto = cell.animatedImageView.image;
                model.previewPhoto = cell.animatedImageView.image;
            }
#else
            if (model.type == HXPhotoModelMediaTypePhotoGif) {
                if (cell.imageView.image.images.count > 0) {
                    model.thumbPhoto = cell.imageView.image.images.firstObject;
                    model.previewPhoto = cell.imageView.image.images.firstObject;
                }else {
                    model.thumbPhoto = cell.imageView.image;
                    model.previewPhoto = cell.imageView.image;
                }
            }else {
                model.thumbPhoto = cell.imageView.image;
                model.previewPhoto = cell.imageView.image;
            }
#endif
            [self.manager beforeSelectedListAddPhotoModel:model];
            
//            if (model.type == HXPhotoModelMediaTypePhoto || (model.type == HXPhotoModelMediaTypePhotoGif || model.type == HXPhotoModelMediaTypeLivePhoto)) { // 为图片时
//                [self.manager.selectedPhotos addObject:model];
//            }else if (model.type == HXPhotoModelMediaTypeVideo) { // 为视频时
//                [self.manager.selectedVideos addObject:model];
//            }else if (model.type == HXPhotoModelMediaTypeCameraPhoto) {
//                // 为相机拍的照片时
//                [self.manager.selectedPhotos addObject:model];
//                [self.manager.selectedCameraPhotos addObject:model];
//                [self.manager.selectedCameraList addObject:model];
//            }else if (model.type == HXPhotoModelMediaTypeCameraVideo) {
//                // 为相机录的视频时
//                [self.manager.selectedVideos addObject:model];
//                [self.manager.selectedCameraVideos addObject:model];
//                [self.manager.selectedCameraList addObject:model];
//            }
//            [self.manager.selectedList addObject:model];
//            model.selectIndexStr = [NSString stringWithFormat:@"%ld",[self.manager.selectedList indexOfObject:model] + 1];
        }
    }
    if ([self.delegate respondsToSelector:@selector(datePhotoPreviewControllerDidDone:)]) {
        [self.delegate datePhotoPreviewControllerDidDone:self];
    }
}
#pragma mark - < HXDatePhotoEditViewControllerDelegate >
- (void)datePhotoEditViewControllerDidClipClick:(HXDatePhotoEditViewController *)datePhotoEditViewController beforeModel:(HXPhotoModel *)beforeModel afterModel:(HXPhotoModel *)afterModel {
    if (self.outside) {
        [self.modelArray replaceObjectAtIndex:[self.modelArray indexOfObject:beforeModel] withObject:afterModel];
        if ([self.delegate respondsToSelector:@selector(datePhotoPreviewSelectLaterDidEditClick:beforeModel:afterModel:)]) {
            [self.delegate datePhotoPreviewSelectLaterDidEditClick:self beforeModel:beforeModel afterModel:afterModel];
        }
        [self dismissClick];
        return;
    }
//    if (self.manager.configuration.saveSystemAblum) {
//        [HXPhotoTools savePhotoToCustomAlbumWithName:self.manager.customAlbumName photo:afterModel.thumbPhoto];
//    }
    if (beforeModel.selected) {
        [self.manager beforeSelectedListdeletePhotoModel:beforeModel];
        
//        beforeModel.selected = NO;
//        beforeModel.selectIndexStr = @"";
//        if (beforeModel.type == HXPhotoModelMediaTypeCameraPhoto) {
//            [self.manager.selectedCameraList removeObject:beforeModel];
//            [self.manager.selectedCameraPhotos removeObject:beforeModel];
//        }else {
//            beforeModel.thumbPhoto = nil;
//            beforeModel.previewPhoto = nil;
//        }
//        [self.manager.selectedList removeObject:beforeModel];
//        [self.manager.selectedPhotos removeObject:beforeModel];
    }
    [self.manager beforeSelectedListAddEditPhotoModel:afterModel];

//    [self.manager.cameraPhotos addObject:afterModel];
//    [self.manager.cameraList addObject:afterModel];
//    [self.manager.selectedCameraPhotos addObject:afterModel];
//    [self.manager.selectedCameraList addObject:afterModel];
//    [self.manager.selectedPhotos addObject:afterModel];
//    [self.manager.selectedList addObject:afterModel];
//    afterModel.selected = YES;
//    afterModel.selectIndexStr = [NSString stringWithFormat:@"%ld",[self.manager.selectedList indexOfObject:afterModel] + 1];
    if ([self.delegate respondsToSelector:@selector(datePhotoPreviewDidEditClick:)]) {
        [self.delegate datePhotoPreviewDidEditClick:self];
    }
}
- (void)dismissClick {
    [self dismissViewControllerAnimated:YES completion:nil];
}
- (void)deleteClick {
    if (!self.modelArray.count) {
        [self.view showImageHUDText:[NSBundle hx_localizedStringForKey:@"当前没有可删除的资源"]];
        return;
    }
    NSString *message;
    if (self.currentModel.subType == HXPhotoModelMediaSubTypePhoto) {
        message = [NSBundle hx_localizedStringForKey:@"确定删除这张照片吗?"];
    }else {
        message = [NSBundle hx_localizedStringForKey:@"确定删除这个视频吗?"];
    }
    HXWeakSelf
    hx_showAlert(self, message, nil, [NSBundle hx_localizedStringForKey:@"取消"], [NSBundle hx_localizedStringForKey:@"删除"], ^{
        
    }, ^{
        HXPhotoModel *tempModel = weakSelf.currentModel;
        NSInteger tempIndex = weakSelf.currentModelIndex;
        
        [weakSelf.modelArray removeObject:weakSelf.currentModel];
        [weakSelf.collectionView deleteItemsAtIndexPaths:@[[NSIndexPath indexPathForItem:weakSelf.currentModelIndex inSection:0]]];
        [weakSelf.bottomView deleteModel:weakSelf.currentModel];
        if (weakSelf.exteriorPreviewStyle == HXPhotoViewPreViewShowStyleDark) {
            weakSelf.bottomPageControl.numberOfPages = weakSelf.modelArray.count;
        }
        if ([weakSelf.delegate respondsToSelector:@selector(datePhotoPreviewDidDeleteClick:deleteModel:deleteIndex:)]) {
            [weakSelf.delegate datePhotoPreviewDidDeleteClick:weakSelf deleteModel:tempModel deleteIndex:tempIndex];
        }
        [weakSelf scrollViewDidScroll:weakSelf.collectionView];
        [weakSelf scrollViewDidEndDecelerating:weakSelf.collectionView];
        if (!weakSelf.modelArray.count) {
            [weakSelf dismissClick];
        }
    });
}
#pragma mark - < 懒加载 >
- (UIPageControl *)bottomPageControl {
    if (!_bottomPageControl) {
        _bottomPageControl = [[UIPageControl alloc] init];
        _bottomPageControl.currentPageIndicatorTintColor = [UIColor whiteColor];
        _bottomPageControl.pageIndicatorTintColor = [[UIColor whiteColor] colorWithAlphaComponent:0.5f];
        _bottomPageControl.numberOfPages = self.modelArray.count;
    }
    return _bottomPageControl;
}
- (UIView *)dismissTempTopView {
    if (!_dismissTempTopView) {
        _dismissTempTopView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.hx_w, hxNavigationBarHeight)];
        _dismissTempTopView.backgroundColor = [UIColor blackColor];
    }
    return _dismissTempTopView;
}
- (void)setupDarkBtnAlpha:(CGFloat)alpha {
    if (self.exteriorPreviewStyle == HXPhotoViewPreViewShowStyleDark) {
        self.darkDeleteBtn.alpha = alpha;
        self.darkCancelBtn.alpha = alpha;
        self.bottomPageControl.alpha = alpha;
    }
}
- (UIButton *)darkCancelBtn {
    if (!_darkCancelBtn) {
        _darkCancelBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [_darkCancelBtn setBackgroundImage:[HXPhotoTools hx_imageNamed:@"hx_faceu_cancel@3x.png"] forState:UIControlStateNormal];
        _darkCancelBtn.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
        _darkCancelBtn.contentVerticalAlignment = UIControlContentVerticalAlignmentTop;
        [_darkCancelBtn addTarget:self action:@selector(dismissClick) forControlEvents:UIControlEventTouchUpInside];
    }
    return _darkCancelBtn;
}
- (UIButton *)darkDeleteBtn {
    if (!_darkDeleteBtn) {
        _darkDeleteBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [_darkDeleteBtn setTitle:[NSBundle hx_localizedStringForKey:@"删除"] forState:UIControlStateNormal];
        _darkDeleteBtn.titleLabel.font = [UIFont systemFontOfSize:16];
        _darkDeleteBtn.contentHorizontalAlignment = UIControlContentHorizontalAlignmentRight;
        [_darkDeleteBtn addTarget:self action:@selector(deleteClick) forControlEvents:UIControlEventTouchUpInside];
    }
    return _darkDeleteBtn;
}
- (HXPhotoCustomNavigationBar *)navBar {
    if (!_navBar) {
        CGFloat width = [UIScreen mainScreen].bounds.size.width;
        _navBar = [[HXPhotoCustomNavigationBar alloc] initWithFrame:CGRectMake(0, 0, width, hxNavigationBarHeight)];
        _navBar.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        [_navBar pushNavigationItem:self.navItem animated:NO];
        [_navBar setTintColor:self.manager.configuration.themeColor];
    }
    return _navBar;
}
- (UINavigationItem *)navItem {
    if (!_navItem) {
        _navItem = [[UINavigationItem alloc] init];
        if (self.previewShowDeleteButton) {
            _navItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:[NSBundle hx_localizedStringForKey:@"返回"] style:UIBarButtonItemStylePlain target:self action:@selector(dismissClick)];
            _navItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:[NSBundle hx_localizedStringForKey:@"删除"] style:UIBarButtonItemStylePlain target:self action:@selector(deleteClick)];
        }else {
            _navItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:[NSBundle hx_localizedStringForKey:@"取消"] style:UIBarButtonItemStylePlain target:self action:@selector(dismissClick)];
        }
        if (self.exteriorPreviewStyle == HXPhotoViewPreViewShowStyleDefault) {
            _navItem.titleView = self.customTitleView;
        }
    }
    return _navItem;
}
- (UIView *)customTitleView {
    if (!_customTitleView) {
        _customTitleView = [[UIView alloc] init];
        [_customTitleView addSubview:self.titleLb];
        [_customTitleView addSubview:self.subTitleLb];
    }
    return _customTitleView;
}
- (UILabel *)titleLb {
    if (!_titleLb) {
        _titleLb = [[UILabel alloc] init];
        _titleLb.textAlignment = NSTextAlignmentCenter;
        if (iOS8_2Later) {
            _titleLb.font = [UIFont systemFontOfSize:14 weight:UIFontWeightMedium];
        }else {
            _titleLb.font = [UIFont systemFontOfSize:14];
        }
        _titleLb.textColor = [UIColor blackColor];
    }
    return _titleLb;
}
- (UILabel *)subTitleLb {
    if (!_subTitleLb) {
        _subTitleLb = [[UILabel alloc] initWithFrame:CGRectMake(0, CGRectGetMaxY(self.titleLb.frame) + 4, 150, 12)];
        _subTitleLb.textAlignment = NSTextAlignmentCenter;
        if (iOS8_2Later) {
            _subTitleLb.font = [UIFont systemFontOfSize:11 weight:UIFontWeightRegular];
        }else {
            _subTitleLb.font = [UIFont systemFontOfSize:11];
        }
        _subTitleLb.textColor = [UIColor blackColor];
    }
    return _subTitleLb;
}
- (HXDatePhotoPreviewBottomView *)bottomView {
    if (!_bottomView) {
        if (self.outside) {
            _bottomView = [[HXDatePhotoPreviewBottomView alloc] initWithFrame:CGRectMake(0, self.view.hx_h - 50 - hxBottomMargin, self.view.hx_w, 50 + hxBottomMargin) modelArray:self.manager.afterSelectedArray manager:self.manager];
        }else {
            _bottomView = [[HXDatePhotoPreviewBottomView alloc] initWithFrame:CGRectMake(0, self.view.hx_h - 50 - hxBottomMargin, self.view.hx_w, 50 + hxBottomMargin) modelArray:self.manager.selectedArray manager:self.manager];
        }
        _bottomView.delagate = self;
    }
    return _bottomView;
}
- (UIButton *)selectBtn {
    if (!_selectBtn) {
        _selectBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [_selectBtn setBackgroundImage:[HXPhotoTools hx_imageNamed:@"hx_compose_guide_check_box_default_2@2x.png"] forState:UIControlStateNormal];
        [_selectBtn setBackgroundImage:[[UIImage alloc] init] forState:UIControlStateSelected];
        if ([self.manager.configuration.themeColor isEqual:[UIColor whiteColor]]) {
            [_selectBtn setTitleColor:[UIColor blackColor] forState:UIControlStateSelected];
        }else {
            [_selectBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateSelected];
        }
        if (self.manager.configuration.selectedTitleColor) {
            [_selectBtn setTitleColor:self.manager.configuration.selectedTitleColor forState:UIControlStateSelected];
        }
        _selectBtn.titleLabel.font = [UIFont systemFontOfSize:14];
        _selectBtn.adjustsImageWhenDisabled = YES;
        [_selectBtn addTarget:self action:@selector(didSelectClick:) forControlEvents:UIControlEventTouchUpInside];
        _selectBtn.hx_size = CGSizeMake(24, 24);
        [_selectBtn setEnlargeEdgeWithTop:0 right:0 bottom:20 left:20];
        _selectBtn.layer.cornerRadius = 12;
    }
    return _selectBtn;
}
- (UICollectionView *)collectionView {
    if (!_collectionView) {
//        _collectionView = [[UICollectionView alloc] initWithFrame:CGRectMake(-10, hxTopMargin,self.view.hx_w + 20, self.view.hx_h - hxTopMargin - hxBottomMargin) collectionViewLayout:self.flowLayout];
        _collectionView = [[UICollectionView alloc] initWithFrame:CGRectMake(-10, 0,self.view.hx_w + 20, self.view.hx_h) collectionViewLayout:self.flowLayout];
        if (self.exteriorPreviewStyle == HXPhotoViewPreViewShowStyleDefault) {
            _collectionView.backgroundColor = [UIColor whiteColor];
        }else if (self.exteriorPreviewStyle == HXPhotoViewPreViewShowStyleDark) {
            _collectionView.backgroundColor = [UIColor blackColor];
        }
        _collectionView.dataSource = self;
        _collectionView.delegate = self;
        _collectionView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        _collectionView.pagingEnabled = YES;
        _collectionView.showsVerticalScrollIndicator = NO;
        _collectionView.showsHorizontalScrollIndicator = NO;
        [_collectionView registerClass:[HXDatePhotoPreviewViewCell class] forCellWithReuseIdentifier:@"DatePreviewCellId"];
#ifdef __IPHONE_11_0
        if (@available(iOS 11.0, *)) {
            _collectionView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
#else
        if ((NO)) {
#endif
        } else {
            self.automaticallyAdjustsScrollViewInsets = NO;
        }
    }
    return _collectionView;
}
- (UICollectionViewFlowLayout *)flowLayout {
    if (!_flowLayout) {
        _flowLayout = [[UICollectionViewFlowLayout alloc] init];
        _flowLayout.minimumInteritemSpacing = 0;
        _flowLayout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
        
        if (self.outside) {
            _flowLayout.sectionInset = UIEdgeInsetsMake(0, 10, 0, 10);
        }else {
#ifdef __IPHONE_11_0
            if (@available(iOS 11.0, *)) {
#else
                if ((NO)) {
#endif
                    _flowLayout.sectionInset = UIEdgeInsetsMake(0, 10, 0, 10);
                }else {
                    _flowLayout.sectionInset = UIEdgeInsetsMake(0, 10, 0, 10);
                }
            }
        }
        return _flowLayout;
    }
- (NSMutableArray *)modelArray {
    if (!_modelArray) {
        _modelArray = [NSMutableArray array];
    }
    return _modelArray;
}
- (void)dealloc {
    if (_collectionView) {
        HXDatePhotoPreviewViewCell *cell = (HXDatePhotoPreviewViewCell *)[self.collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForItem:self.currentModelIndex inSection:0]];
        [cell cancelRequest];
    }
    if ([UIApplication sharedApplication].statusBarHidden) {
        [self.navigationController setNavigationBarHidden:NO animated:NO];
        [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationFade];
    }
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidChangeStatusBarOrientationNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillChangeStatusBarOrientationNotification object:nil];
    if (HXShowLog) NSSLog(@"dealloc");
}
@end

@interface HXDatePhotoPreviewViewCell ()<UIScrollViewDelegate,PHLivePhotoViewDelegate>
@property (strong, nonatomic) UIScrollView *scrollView;
@property (strong, nonatomic) UIImageView *imageView;
@property (assign, nonatomic) CGPoint imageCenter;
@property (strong, nonatomic) UIImage *gifImage;
@property (strong, nonatomic) UIImage *gifFirstFrame;
@property (assign, nonatomic) PHImageRequestID requestID;
@property (strong, nonatomic) PHLivePhotoView *livePhotoView;
@property (assign, nonatomic) BOOL livePhotoAnimating;
@property (strong, nonatomic) AVPlayerLayer *playerLayer;
@property (strong, nonatomic) AVPlayer *player;
@property (strong, nonatomic) HXCircleProgressView *progressView;
@property (strong, nonatomic) UIActivityIndicatorView *loadingView;
@end

@implementation HXDatePhotoPreviewViewCell
- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.requestID = -1;
        [self setup];
    }
    return self;
}
- (void)setup {
    [self.contentView addSubview:self.scrollView];
#if __has_include(<YYWebImage/YYWebImage.h>) || __has_include("YYWebImage.h")
    [self.scrollView addSubview:self.animatedImageView];
#else
    [self.scrollView addSubview:self.imageView];
#endif
    [self.contentView.layer addSublayer:self.playerLayer];
    [self.contentView addSubview:self.videoPlayBtn];
    //    [self.scrollView addSubview:self.livePhotoView];
    [self.contentView addSubview:self.progressView];
    [self.contentView addSubview:self.loadingView];
}
- (void)resetScale {
    [self.scrollView setZoomScale:1.0 animated:NO];
}
- (void)againAddImageView {
    [self refreshImageSize];
#if __has_include(<YYWebImage/YYWebImage.h>) || __has_include("YYWebImage.h")
    [self.scrollView addSubview:self.animatedImageView];
#else
    [self.scrollView addSubview:self.imageView];
#endif
    if (self.model.subType == HXPhotoModelMediaSubTypeVideo) {
        self.videoPlayBtn.hidden = NO;
        [self.contentView.layer addSublayer:self.playerLayer];
        [self.contentView addSubview:self.videoPlayBtn];
        self.videoPlayBtn.alpha = 0;
        [UIView animateWithDuration:0.2 animations:^{
            self.videoPlayBtn.alpha = 1;
        }];
    }
}
- (void)refreshImageSize {
    CGFloat width = self.frame.size.width;
    CGFloat height = self.frame.size.height;
    CGFloat imgWidth = self.model.imageSize.width;
    CGFloat imgHeight = self.model.imageSize.height;
    CGFloat w;
    CGFloat h;
    
    imgHeight = width / imgWidth * imgHeight;
    if (imgHeight > height) {
        w = height / self.model.imageSize.height * imgWidth;
        h = height;
        self.scrollView.maximumZoomScale = width / w + 0.5;
    }else {
        w = width;
        h = imgHeight;
        self.scrollView.maximumZoomScale = 2.5;
    }
#if __has_include(<YYWebImage/YYWebImage.h>) || __has_include("YYWebImage.h")
    self.animatedImageView.frame = CGRectMake(0, 0, w, h);
    self.animatedImageView.center = CGPointMake(width / 2, height / 2);
    self.playerLayer.frame = self.animatedImageView.frame;
#else
    self.imageView.frame = CGRectMake(0, 0, w, h);
    self.imageView.center = CGPointMake(width / 2, height / 2);
    self.playerLayer.frame = self.imageView.frame;
#endif
    self.videoPlayBtn.frame = self.playerLayer.frame;
}
- (void)setModel:(HXPhotoModel *)model {
    _model = model;
    [self cancelRequest];
    self.playerLayer.player = nil;
    self.player = nil;
    self.progressView.hidden = YES;
    [self.loadingView stopAnimating];
    self.progressView.progress = 0;
    
    [self resetScale];
    
    CGFloat width = self.frame.size.width;
    CGFloat height = self.frame.size.height;
    CGFloat imgWidth = self.model.imageSize.width;
    CGFloat imgHeight = self.model.imageSize.height;
    CGFloat w;
    CGFloat h;
    
    imgHeight = width / imgWidth * imgHeight;
    if (imgHeight > height) {
        w = height / self.model.imageSize.height * imgWidth;
        h = height;
        self.scrollView.maximumZoomScale = width / w + 0.5;
    }else {
        w = width;
        h = imgHeight;
        self.scrollView.maximumZoomScale = 2.5;
    }
    
#if __has_include(<YYWebImage/YYWebImage.h>) || __has_include("YYWebImage.h")
    self.animatedImageView.frame = CGRectMake(0, 0, w, h);
    self.animatedImageView.center = CGPointMake(width / 2, height / 2);
    self.playerLayer.frame = self.animatedImageView.frame;
    self.videoPlayBtn.frame = self.playerLayer.frame;
    self.animatedImageView.hidden = NO;
#else
    self.imageView.frame = CGRectMake(0, 0, w, h);
    self.imageView.center = CGPointMake(width / 2, height / 2);
    self.playerLayer.frame = self.imageView.frame;
    self.videoPlayBtn.frame = self.playerLayer.frame;
    self.imageView.hidden = NO;
#endif
    __weak typeof(self) weakSelf = self;
    if (model.type == HXPhotoModelMediaTypeCameraPhoto || model.type == HXPhotoModelMediaTypeCameraVideo) {
        if (model.networkPhotoUrl) {
            self.progressView.hidden = model.downloadComplete;
            CGFloat progress = (CGFloat)model.receivedSize / model.expectedSize;
            self.progressView.progress = progress;
#if __has_include(<YYWebImage/YYWebImage.h>) || __has_include("YYWebImage.h")
            [self.animatedImageView hx_setImageWithModel:model progress:^(CGFloat progress, HXPhotoModel *model) {
                if (weakSelf.model == model) {
                    weakSelf.progressView.progress = progress;
                }
            } completed:^(UIImage *image, NSError *error, HXPhotoModel *model) {
                if (weakSelf.model == model) {
                    if (error != nil) {
                        [weakSelf.progressView showError];
                    }else {
                        if (image) {
                            if (weakSelf.cellDownloadImageComplete) weakSelf.cellDownloadImageComplete(weakSelf);
                            weakSelf.progressView.progress = 1;
                            weakSelf.progressView.hidden = YES;
                            weakSelf.animatedImageView.image = image;
                            [weakSelf refreshImageSize];
                        }
                    }
                }
            }];
#else
            [self.imageView hx_setImageWithModel:model progress:^(CGFloat progress, HXPhotoModel *model) {
                if (weakSelf.model == model) {
                    weakSelf.progressView.progress = progress;
                }
            } completed:^(UIImage *image, NSError *error, HXPhotoModel *model) {
                if (weakSelf.model == model) {
                    if (error != nil) {
                        [weakSelf.progressView showError];
                    }else {
                        if (image) {
                            if (weakSelf.cellDownloadImageComplete) weakSelf.cellDownloadImageComplete(weakSelf);
                            weakSelf.progressView.progress = 1;
                            weakSelf.progressView.hidden = YES;
                            weakSelf.imageView.image = image;
                            [weakSelf refreshImageSize];
                        }
                    }
                }
            }];
#endif
        }else {
#if __has_include(<YYWebImage/YYWebImage.h>) || __has_include("YYWebImage.h")
            self.animatedImageView.image = model.thumbPhoto;
#else
            self.imageView.image = model.thumbPhoto;
#endif
            model.tempImage = nil;
        }
    }else {
        if (model.type == HXPhotoModelMediaTypeLivePhoto) {
            if (model.tempImage) {
#if __has_include(<YYWebImage/YYWebImage.h>) || __has_include("YYWebImage.h")
                self.animatedImageView.image = model.tempImage;
#else
                self.imageView.image = model.tempImage;
#endif
                model.tempImage = nil;
            }else {
                self.requestID = [HXPhotoTools getPhotoForPHAsset:model.asset size:CGSizeMake(self.hx_w * 0.5, self.hx_h * 0.5) completion:^(UIImage *image, NSDictionary *info) {
#if __has_include(<YYWebImage/YYWebImage.h>) || __has_include("YYWebImage.h")
                    weakSelf.animatedImageView.image = image;
#else
                    weakSelf.imageView.image = image;
#endif
                }];
            }
        }else {
            if (model.previewPhoto) {
#if __has_include(<YYWebImage/YYWebImage.h>) || __has_include("YYWebImage.h")
                self.animatedImageView.image = model.previewPhoto;
#else
                self.imageView.image = model.previewPhoto;
#endif
                model.tempImage = nil;
            }else {
                if (model.tempImage) {
#if __has_include(<YYWebImage/YYWebImage.h>) || __has_include("YYWebImage.h")
                    self.animatedImageView.image = model.tempImage;
#else
                    self.imageView.image = model.tempImage;
#endif
                    model.tempImage = nil;
                }else {
                    PHImageRequestID requestID;
                    if (imgHeight > imgWidth / 9 * 17) {
                        requestID = [HXPhotoTools getPhotoForPHAsset:model.asset size:CGSizeMake(self.hx_w * 0.6, self.hx_h * 0.6) completion:^(UIImage *image, NSDictionary *info) {
#if __has_include(<YYWebImage/YYWebImage.h>) || __has_include("YYWebImage.h")
                            weakSelf.animatedImageView.image = image;
#else
                            weakSelf.imageView.image = image;
#endif
                        }];
                    }else {
                        requestID = [HXPhotoTools getPhotoForPHAsset:model.asset size:CGSizeMake(model.endImageSize.width * 0.8, model.endImageSize.height * 0.8) completion:^(UIImage *image, NSDictionary *info) {
#if __has_include(<YYWebImage/YYWebImage.h>) || __has_include("YYWebImage.h")
                            weakSelf.animatedImageView.image = image;
#else
                            weakSelf.imageView.image = image;
#endif
                        }];
                    }
                    self.requestID = requestID;
                }
            }
        }
    }
    if (model.subType == HXPhotoModelMediaSubTypeVideo) {
        self.playerLayer.hidden = NO;
        //        self.videoPlayBtn.hidden = NO;
        self.videoPlayBtn.hidden = YES;
    }else {
        self.playerLayer.hidden = YES;
        self.videoPlayBtn.hidden = YES;
    }
}
- (void)requestHDImage {
    if (self.requestID) {
        [[PHImageManager defaultManager] cancelImageRequest:self.requestID];
        self.requestID = -1;
    }
    CGFloat width = self.frame.size.width;
    CGFloat height = self.frame.size.height;
    CGFloat imgWidth = self.model.imageSize.width;
    CGFloat imgHeight = self.model.imageSize.height;
    CGSize size;
    __weak typeof(self) weakSelf = self;
    CGFloat scale;
    if (HX_IS_IPhoneX_All) {
        scale = 3.0f;
    }else if ([UIScreen mainScreen].bounds.size.width == 320) {
        scale = 2.0;
    }else if ([UIScreen mainScreen].bounds.size.width == 375) {
        scale = 2.5;
    }else {
        scale = 3.0;
    }
    
    if (imgHeight > imgWidth / 9 * 17) {
        size = CGSizeMake(width * scale, height * scale);
    }else {
        size = CGSizeMake(self.model.endImageSize.width * scale, self.model.endImageSize.height * scale);
    }
    if (self.model.type == HXPhotoModelMediaTypeCameraPhoto) {
        if (self.model.networkPhotoUrl) {
            if (!self.model.downloadComplete) {
                self.progressView.hidden = NO;
                self.progressView.progress = (CGFloat)self.model.receivedSize / self.model.expectedSize;;
            }else if (self.model.downloadError) {
                [self.progressView showError];
            }
        }
    }else if (self.model.type == HXPhotoModelMediaTypeLivePhoto) {
        if (_livePhotoView.livePhoto) {
            [self.livePhotoView stopPlayback];
            [self.livePhotoView startPlaybackWithStyle:PHLivePhotoViewPlaybackStyleFull];
            return;
        }
        if (self.model.iCloudRequestID) {
            [[PHImageManager defaultManager] cancelImageRequest:self.model.iCloudRequestID];
            self.model.iCloudRequestID = -1;
        }
        self.requestID = [HXPhotoTools getLivePhotoForAsset:self.model.asset size:self.model.endImageSize startRequestICloud:^(PHImageRequestID iCloudRequestId) {
            if (weakSelf.model.isICloud) {
                weakSelf.progressView.hidden = NO;
            }
            weakSelf.requestID = iCloudRequestId;
        } progressHandler:^(double progress) {
            if (weakSelf.model.isICloud) {
                weakSelf.progressView.hidden = NO;
            }
            weakSelf.progressView.progress = progress;
        } completion:^(PHLivePhoto *livePhoto) {
            [weakSelf downloadICloudAssetComplete];
#if __has_include(<YYWebImage/YYWebImage.h>) || __has_include("YYWebImage.h")
            weakSelf.livePhotoView.frame = weakSelf.animatedImageView.frame;
            weakSelf.animatedImageView.hidden = YES;
#else
            weakSelf.livePhotoView.frame = weakSelf.imageView.frame;
            weakSelf.imageView.hidden = YES;
#endif
            [weakSelf.scrollView addSubview:weakSelf.livePhotoView];
            weakSelf.livePhotoView.livePhoto = livePhoto;
            [weakSelf.livePhotoView startPlaybackWithStyle:PHLivePhotoViewPlaybackStyleFull];
        } failed:^{
            weakSelf.progressView.hidden = YES;
            if (weakSelf.model.isICloud) {
                //                [weakSelf.progressView showError];
            }
        }];
    }else if (self.model.type == HXPhotoModelMediaTypePhoto) {
        self.requestID = [HXPhotoTools getHighQualityFormatPhoto:self.model.asset size:size startRequestIcloud:^(PHImageRequestID cloudRequestId) {
            if (weakSelf.model.isICloud) {
                weakSelf.progressView.hidden = NO;
            }
            weakSelf.requestID = cloudRequestId;
        } progressHandler:^(double progress) {
            if (weakSelf.model.isICloud) {
                weakSelf.progressView.hidden = NO;
            }
            weakSelf.progressView.progress = progress;
        } completion:^(UIImage *image) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [weakSelf downloadICloudAssetComplete];
                weakSelf.progressView.hidden = YES;
#if __has_include(<YYWebImage/YYWebImage.h>) || __has_include("YYWebImage.h")
                weakSelf.animatedImageView.image = image;
#else
                weakSelf.imageView.image = image;
#endif
            });
        } failed:^(NSDictionary *info) {
            dispatch_async(dispatch_get_main_queue(), ^{
                weakSelf.progressView.hidden = YES;
                if (weakSelf.model.isICloud) {
                    //                    [weakSelf.progressView showError];
                }
            });
        }];
    }else if (self.model.type == HXPhotoModelMediaTypePhotoGif) {
        if (self.gifImage) {
#if __has_include(<YYWebImage/YYWebImage.h>) || __has_include("YYWebImage.h")
            self.animatedImageView.image = self.gifImage;
#else
            self.imageView.image = self.gifImage;
#endif
        }else {
            if (self.model.asset) {
                self.requestID = [HXPhotoTools getImageData:self.model.asset startRequestIcloud:^(PHImageRequestID cloudRequestId) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        if (weakSelf.model.isICloud) {
                            weakSelf.progressView.hidden = NO;
                        }
                        weakSelf.requestID = cloudRequestId;
                    });
                } progressHandler:^(double progress) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        if (weakSelf.model.isICloud) {
                            weakSelf.progressView.hidden = NO;
                        }
                        weakSelf.progressView.progress = progress;
                    });
                } completion:^(NSData *imageData, UIImageOrientation orientation) {
                    dispatch_async(dispatch_get_main_queue(), ^{
//                        weakSelf.model.gifImageData = imageData;
                        [weakSelf downloadICloudAssetComplete];
                        weakSelf.progressView.hidden = YES;
                        UIImage *gifImage = [UIImage animatedGIFWithData:imageData];
                        if (gifImage.images.count == 0) {
                            weakSelf.gifFirstFrame = gifImage;
                        }else {
                            weakSelf.gifFirstFrame = gifImage.images.firstObject;
                        }
                        weakSelf.model.tempImage = nil;
#if __has_include(<YYWebImage/YYWebImage.h>) || __has_include("YYWebImage.h")
                        weakSelf.animatedImageView.image = gifImage;
#else
                        weakSelf.imageView.image = gifImage;
#endif
                        weakSelf.gifImage = gifImage;
                    });
                } failed:^(NSDictionary *info) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        weakSelf.progressView.hidden = YES;
                        if (weakSelf.model.isICloud) {
                            //                        [weakSelf.progressView showError];
                        }
                    });
                }];
            }else {
                self.progressView.hidden = YES;
                UIImage *gifImage = [UIImage animatedGIFWithData:self.model.gifImageData];
                if (gifImage.images.count == 0) {
                    self.gifFirstFrame = gifImage;
                }else {
                    self.gifFirstFrame = gifImage.images.firstObject;
                }
                self.model.tempImage = nil;
#if __has_include(<YYWebImage/YYWebImage.h>) || __has_include("YYWebImage.h")
                self.animatedImageView.image = gifImage;
#else
                self.imageView.image = gifImage;
#endif
                self.gifImage = gifImage;
            }
        }
    }
    if (self.player != nil) return;
    if (self.model.type == HXPhotoModelMediaTypeVideo) {
        if (self.model.avAsset) {
            self.progressView.hidden = YES;
            [self.loadingView stopAnimating];
            self.videoPlayBtn.hidden = NO;
            self.player = [AVPlayer playerWithPlayerItem:[AVPlayerItem playerItemWithAsset:self.model.avAsset]];
            self.playerLayer.player = weakSelf.player;
            [[NSNotificationCenter defaultCenter] addObserver:weakSelf selector:@selector(pausePlayerAndShowNaviBar) name:AVPlayerItemDidPlayToEndTimeNotification object:weakSelf.player.currentItem];
        }else {
            if (self.model.asset) {
                self.requestID = [HXPhotoTools getAVAssetWithPHAsset:self.model.asset startRequestIcloud:^(PHImageRequestID cloudRequestId) {
                    //            if (weakSelf.model.isICloud) {
                    //                weakSelf.progressView.hidden = NO;
                    //            }
                    [weakSelf.loadingView startAnimating];
                    weakSelf.videoPlayBtn.hidden = YES;
                    weakSelf.requestID = cloudRequestId;
                } progressHandler:^(double progress) {
                    //            if (weakSelf.model.isICloud) {
                    //                weakSelf.progressView.hidden = NO;
                    //            }
                    weakSelf.progressView.progress = progress;
                } completion:^(AVAsset *asset) {
                    [weakSelf downloadICloudAssetComplete];
                    weakSelf.model.avAsset = asset;
                    weakSelf.progressView.hidden = YES;
                    [weakSelf.loadingView stopAnimating];
                    weakSelf.videoPlayBtn.hidden = NO;
                    weakSelf.player = [AVPlayer playerWithPlayerItem:[AVPlayerItem playerItemWithAsset:asset]];
                    weakSelf.playerLayer.player = weakSelf.player;
                    [[NSNotificationCenter defaultCenter] addObserver:weakSelf selector:@selector(pausePlayerAndShowNaviBar) name:AVPlayerItemDidPlayToEndTimeNotification object:weakSelf.player.currentItem];
                } failed:^(NSDictionary *info) {
                    [weakSelf.loadingView stopAnimating];
                    weakSelf.videoPlayBtn.hidden = NO;
                    weakSelf.progressView.hidden = YES;
                    if (weakSelf.model.isICloud) {
                        //                [weakSelf.progressView showError];
                    }
                }];
            }else {
                self.progressView.hidden = YES;
                [self.loadingView stopAnimating];
                self.videoPlayBtn.hidden = NO;
                self.player = [AVPlayer playerWithPlayerItem:[AVPlayerItem playerItemWithAsset:[AVAsset assetWithURL:self.model.fileURL]]];
                self.playerLayer.player = weakSelf.player;
                [[NSNotificationCenter defaultCenter] addObserver:weakSelf selector:@selector(pausePlayerAndShowNaviBar) name:AVPlayerItemDidPlayToEndTimeNotification object:weakSelf.player.currentItem];
            }
        }
    }else if (self.model.type == HXPhotoModelMediaTypeCameraVideo ) {
        self.videoPlayBtn.hidden = NO;
        self.player = [AVPlayer playerWithPlayerItem:[AVPlayerItem playerItemWithURL:self.model.videoURL]];
        self.playerLayer.player = self.player;
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(pausePlayerAndShowNaviBar) name:AVPlayerItemDidPlayToEndTimeNotification object:self.player.currentItem];
    }
}
- (void)downloadICloudAssetComplete {
    self.progressView.hidden = YES;
    [self.loadingView stopAnimating];
    if (self.model.isICloud) {
        self.model.iCloudDownloading = NO;
        self.model.isICloud = NO;
        if (self.cellDownloadICloudAssetComplete) {
            self.cellDownloadICloudAssetComplete(self);
        }
    }
}
- (void)pausePlayerAndShowNaviBar {
//    [self.player pause];
//    self.videoPlayBtn.selected = NO;
    [self.player.currentItem seekToTime:CMTimeMake(0, 1)];
    [self.player play];
}
- (void)cancelRequest {
    if (self.requestID) {
        [[PHImageManager defaultManager] cancelImageRequest:self.requestID];
        self.requestID = -1;
    }
//    self.model.avAsset = nil;
    self.videoPlayBtn.hidden = YES;
    self.progressView.hidden = YES;
    self.progressView.progress = 0;
    if (self.model.type == HXPhotoModelMediaTypeLivePhoto) {
        if (_livePhotoView.livePhoto) {
            self.livePhotoView.livePhoto = nil;
            [self.livePhotoView removeFromSuperview];
#if __has_include(<YYWebImage/YYWebImage.h>) || __has_include("YYWebImage.h")
            self.animatedImageView.hidden = NO;
#else
            self.imageView.hidden = NO;
#endif
            [self stopLivePhoto];
        }
    }else if (self.model.type == HXPhotoModelMediaTypePhoto) {
        
#if __has_include(<YYWebImage/YYWebImage.h>) || __has_include("YYWebImage.h")
        [self.animatedImageView yy_cancelCurrentImageRequest];
#endif
    }else if (self.model.type == HXPhotoModelMediaTypePhotoGif) {
        if (!self.stopCancel) {
#if __has_include(<YYWebImage/YYWebImage.h>) || __has_include("YYWebImage.h")
            self.animatedImageView.image = nil;
            self.gifImage = nil;
            self.animatedImageView.image = self.gifFirstFrame;
#else
            self.imageView.image = nil;
            self.gifImage = nil;
            self.imageView.image = self.gifFirstFrame;
#endif
        }else {
            self.stopCancel = NO;
        }
    }
    if (self.model.subType == HXPhotoModelMediaSubTypeVideo) {
        if (self.player != nil && !self.stopCancel) {
            [[NSNotificationCenter defaultCenter] removeObserver:self name:AVPlayerItemDidPlayToEndTimeNotification object:self.player.currentItem];
            [self.player pause];
            self.videoPlayBtn.selected = NO;
            [self.player seekToTime:kCMTimeZero];
            self.playerLayer.player = nil;
            self.player = nil;
        }
        self.stopCancel = NO;
    }
}
- (void)singleTap:(UITapGestureRecognizer *)tap {
    if (self.cellTapClick) {
        self.cellTapClick();
    }
}
- (void)doubleTap:(UITapGestureRecognizer *)tap {
    if (_scrollView.zoomScale > 1.0) {
        [_scrollView setZoomScale:1.0 animated:YES];
    } else {
        CGFloat width = self.frame.size.width;
        CGFloat height = self.frame.size.height;
        CGPoint touchPoint;
        if (self.model.type == HXPhotoModelMediaTypeLivePhoto) {
            touchPoint = [tap locationInView:self.livePhotoView];
        }else {
#if __has_include(<YYWebImage/YYWebImage.h>) || __has_include("YYWebImage.h")
            touchPoint = [tap locationInView:self.animatedImageView];
#else
            touchPoint = [tap locationInView:self.imageView];
#endif
        }
        CGFloat newZoomScale = self.scrollView.maximumZoomScale;
        CGFloat xsize = width / newZoomScale;
        CGFloat ysize = height / newZoomScale;
        [self.scrollView zoomToRect:CGRectMake(touchPoint.x - xsize/2, touchPoint.y - ysize/2, xsize, ysize) animated:YES];
    }
}
#pragma mark - < PHLivePhotoViewDelegate >
- (void)livePhotoView:(PHLivePhotoView *)livePhotoView willBeginPlaybackWithStyle:(PHLivePhotoViewPlaybackStyle)playbackStyle {
    self.livePhotoAnimating = YES;
}
- (void)livePhotoView:(PHLivePhotoView *)livePhotoView didEndPlaybackWithStyle:(PHLivePhotoViewPlaybackStyle)playbackStyle {
    [self stopLivePhoto];
}
- (void)stopLivePhoto {
    self.livePhotoAnimating = NO;
    [self.livePhotoView stopPlayback];
}
#pragma mark - < UIScrollViewDelegate >
- (nullable UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView {
    if (self.model.subType == HXPhotoModelMediaSubTypeVideo) {
        return nil;
    }
    if (self.model.type == HXPhotoModelMediaTypeLivePhoto) {
        return self.livePhotoView;
    }else {
#if __has_include(<YYWebImage/YYWebImage.h>) || __has_include("YYWebImage.h")
        return self.animatedImageView;
#else
        return self.imageView;
#endif
    }
}
- (void)scrollViewDidZoom:(UIScrollView *)scrollView {
    CGFloat offsetX = (scrollView.frame.size.width > scrollView.contentSize.width) ? (scrollView.frame.size.width - scrollView.contentSize.width) * 0.5 : 0.0;
    CGFloat offsetY = (scrollView.frame.size.height > scrollView.contentSize.height) ? (scrollView.frame.size.height - scrollView.contentSize.height) * 0.5 : 0.0;
    
    if (self.model.type == HXPhotoModelMediaTypeLivePhoto) {
        self.livePhotoView.center = CGPointMake(scrollView.contentSize.width * 0.5 + offsetX, scrollView.contentSize.height * 0.5 + offsetY);
    }else {
#if __has_include(<YYWebImage/YYWebImage.h>) || __has_include("YYWebImage.h")
        self.animatedImageView.center = CGPointMake(scrollView.contentSize.width * 0.5 + offsetX, scrollView.contentSize.height * 0.5 + offsetY);
#else
        self.imageView.center = CGPointMake(scrollView.contentSize.width * 0.5 + offsetX, scrollView.contentSize.height * 0.5 + offsetY);
#endif
    }
}
- (void)didPlayBtnClick:(UIButton *)button {
    button.selected = !button.selected;
    if (button.selected) {
        [self.player play];
    }else {
        [self.player pause];
    }
    if (self.cellDidPlayVideoBtn) {
        self.cellDidPlayVideoBtn(button.selected);
    }
}
- (void)layoutSubviews {
    [super layoutSubviews];
//    self.playerLayer.frame = self.bounds;
//    self.videoPlayBtn.frame = self.bounds;
    self.scrollView.frame = self.bounds;
    self.scrollView.contentSize = CGSizeMake(self.hx_w, self.hx_h);
    self.progressView.center = CGPointMake(self.hx_w / 2, self.hx_h / 2);
    self.loadingView.center = self.progressView.center;
}
#pragma mark - < 懒加载 >
- (UIScrollView *)scrollView {
    if (!_scrollView) {
        _scrollView = [[UIScrollView alloc] init];
        _scrollView.showsHorizontalScrollIndicator = NO;
        _scrollView.showsVerticalScrollIndicator = NO;
        _scrollView.bouncesZoom = YES;
        _scrollView.minimumZoomScale = 1;
        _scrollView.multipleTouchEnabled = YES;
        _scrollView.delegate = self;
        _scrollView.scrollsToTop = NO;
        _scrollView.showsHorizontalScrollIndicator = NO;
        _scrollView.showsVerticalScrollIndicator = NO;
        _scrollView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        _scrollView.delaysContentTouches = NO;
        _scrollView.canCancelContentTouches = YES;
        _scrollView.alwaysBounceVertical = NO;
        UITapGestureRecognizer *tap1 = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(singleTap:)];
        [_scrollView addGestureRecognizer:tap1];
        UITapGestureRecognizer *tap2 = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(doubleTap:)];
        tap2.numberOfTapsRequired = 2;
        [tap1 requireGestureRecognizerToFail:tap2];
        [_scrollView addGestureRecognizer:tap2];
    }
    return _scrollView;
}
#if __has_include(<YYWebImage/YYWebImage.h>) || __has_include("YYWebImage.h")
- (YYAnimatedImageView *)animatedImageView {
    if (!_animatedImageView) {
        _animatedImageView = [[YYAnimatedImageView alloc] init];
    }
    return _animatedImageView;
}
#endif
- (UIImageView *)imageView {
    if (!_imageView) {
        _imageView = [[UIImageView alloc] init];
    }
    return _imageView;
}
- (PHLivePhotoView *)livePhotoView {
    if (!_livePhotoView) {
        _livePhotoView = [[PHLivePhotoView alloc] init];
        _livePhotoView.clipsToBounds = YES;
        _livePhotoView.contentMode = UIViewContentModeScaleAspectFill;
        _livePhotoView.delegate = self;
    }
    return _livePhotoView;
}
- (UIButton *)videoPlayBtn {
    if (!_videoPlayBtn) {
        _videoPlayBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [_videoPlayBtn setImage:[HXPhotoTools hx_imageNamed:@"hx_multimedia_videocard_play@2x.png"] forState:UIControlStateNormal];
        [_videoPlayBtn setImage:[[UIImage alloc] init] forState:UIControlStateSelected];
        [_videoPlayBtn addTarget:self action:@selector(didPlayBtnClick:) forControlEvents:UIControlEventTouchUpInside];
        _videoPlayBtn.hidden = YES;
    }
    return _videoPlayBtn;
}
- (HXCircleProgressView *)progressView {
    if (!_progressView) {
        _progressView = [[HXCircleProgressView alloc] init];
        _progressView.hidden = YES;
    }
    return _progressView;
}
- (UIActivityIndicatorView *)loadingView {
    if (!_loadingView) {
        _loadingView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
        [_loadingView stopAnimating];
    }
    return _loadingView;
}
- (AVPlayerLayer *)playerLayer {
    if (!_playerLayer) {
        _playerLayer = [[AVPlayerLayer alloc] init];
        _playerLayer.hidden = YES;
        _playerLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    }
    return _playerLayer;
}
- (void)dealloc {
    [self cancelRequest];
}
@end

