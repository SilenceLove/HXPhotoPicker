//
//  HXPhotoPreviewViewController.m
//  照片选择器
//
//  Created by 洪欣 on 2017/10/14.
//  Copyright © 2017年 洪欣. All rights reserved.
//

#import "HXPhotoPreviewViewController.h"
#import "UIImage+HXExtension.h"
#import "HXPhotoPreviewBottomView.h"
#import "UIButton+HXExtension.h"
#import "HXPhotoViewTransition.h"
#import "HXPhotoInteractiveTransition.h"
#import "HXPhotoViewPresentTransition.h"
#import "HXPhotoCustomNavigationBar.h"
#import "HXCircleProgressView.h"
#import "HXPhotoEditViewController.h"
#import "UIViewController+HXExtension.h"
#import "HXVideoEditViewController.h"
#import "HXPhotoPersentInteractiveTransition.h"

#import "UIImageView+HXExtension.h"

@interface HXPhotoPreviewViewController ()
<
UICollectionViewDataSource,
UICollectionViewDelegate,
HXPhotoPreviewBottomViewDelegate,
HXPhotoEditViewControllerDelegate,
HXVideoEditViewControllerDelegate
>
@property (strong, nonatomic) UICollectionViewFlowLayout *flowLayout;
@property (strong, nonatomic) HXPhotoModel *currentModel;
@property (strong, nonatomic) UIView *customTitleView;
@property (strong, nonatomic) UILabel *titleLb;
@property (strong, nonatomic) UILabel *subTitleLb;
@property (strong, nonatomic) HXPhotoPreviewViewCell *tempCell;
@property (strong, nonatomic) UIButton *selectBtn;
@property (assign, nonatomic) BOOL orientationDidChange;
@property (assign, nonatomic) NSInteger beforeOrientationIndex;
@property (strong, nonatomic) HXPhotoInteractiveTransition *interactiveTransition;
@property (strong, nonatomic) HXPhotoPersentInteractiveTransition *persentInteractiveTransition;

@property (strong, nonatomic) HXPhotoCustomNavigationBar *navBar;
@property (strong, nonatomic) UINavigationItem *navItem;
@property (assign, nonatomic) BOOL isAddInteractiveTransition;
@property (strong, nonatomic) UIView *dismissTempTopView;
@property (strong, nonatomic) UIPageControl *bottomPageControl;
@property (strong, nonatomic) UIButton *darkCancelBtn;
@property (strong, nonatomic) UIButton *darkDeleteBtn;
@property (assign, nonatomic) BOOL statusBarShouldBeHidden;
@property (assign, nonatomic) BOOL layoutSubviewsCompletion;
@end

@implementation HXPhotoPreviewViewController
#pragma mark - < transition delegate >
- (id<UIViewControllerAnimatedTransitioning>)navigationController:(UINavigationController *)navigationController animationControllerForOperation:(UINavigationControllerOperation)operation fromViewController:(UIViewController *)fromVC toViewController:(UIViewController *)toVC{
    if (operation == UINavigationControllerOperationPush) {
        if (![toVC isKindOfClass:[self class]]) {
            return nil;
        }
        return [HXPhotoViewTransition transitionWithType:HXPhotoViewTransitionTypePush];
    }else {
        if (![fromVC isKindOfClass:[self class]]) {
            return nil;
        }
        return [HXPhotoViewTransition transitionWithType:HXPhotoViewTransitionTypePop];
    }
}
- (id<UIViewControllerInteractiveTransitioning>)navigationController:(UINavigationController *)navigationController interactionControllerForAnimationController:(id<UIViewControllerAnimatedTransitioning>)animationController{
    return self.interactiveTransition.interation ? self.interactiveTransition : nil;
}
- (id<UIViewControllerAnimatedTransitioning>)animationControllerForPresentedController:(UIViewController *)presented presentingController:(UIViewController *)presenting sourceController:(UIViewController *)source {
    return [HXPhotoViewPresentTransition transitionWithTransitionType:HXPhotoViewPresentTransitionTypePresent photoView:self.photoView];
}
- (id<UIViewControllerAnimatedTransitioning>)animationControllerForDismissedController:(UIViewController *)dismissed {
    return [HXPhotoViewPresentTransition transitionWithTransitionType:HXPhotoViewPresentTransitionTypeDismiss photoView:self.photoView];
}
- (id<UIViewControllerInteractiveTransitioning>)interactionControllerForDismissal:(id<UIViewControllerAnimatedTransitioning>)animator {
    return self.persentInteractiveTransition.interation ? self.persentInteractiveTransition : nil;
}
#pragma mark - < life cycle >
- (instancetype)init {
    self = [super init];
    if (self) {
        self.transitioningDelegate = self;
        self.modalPresentationStyle = UIModalPresentationCustom;
    }
    return self;
}
- (void)dealloc {
    if (self.photoViewController && HX_IOS9Earlier) {
        // 处理ios8 导航栏转场动画崩溃问题
        self.photoViewController.navigationController.delegate = nil;
        self.photoViewController = nil;
    }
    if (_collectionView) {
        HXPhotoPreviewViewCell *cell = (HXPhotoPreviewViewCell *)[self.collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForItem:self.currentModelIndex inSection:0]];
        [cell cancelRequest];
    }
    if ([UIApplication sharedApplication].statusBarHidden) {
        [self changeStatusBarWithHidden:NO];
        [self.navigationController setNavigationBarHidden:NO animated:NO];
        [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationFade];
    }
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidChangeStatusBarOrientationNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillChangeStatusBarOrientationNotification object:nil];
    if (HXShowLog) NSSLog(@"dealloc");
}
- (UIStatusBarStyle)preferredStatusBarStyle {
    return self.manager.configuration.statusBarStyle;
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
- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    if (self.orientationDidChange) {
        self.orientationDidChange = NO;
        [self changeSubviewFrame];
    }
    if (self.bottomView.currentIndex == -1 && !self.layoutSubviewsCompletion) {
        if (self.outside) {
            if ([self.manager.afterSelectedArray containsObject:self.currentModel]) {
                self.bottomView.currentIndex = [[self.manager afterSelectedArray] indexOfObject:self.currentModel];
            }
        }else {
            if ([self.manager.selectedArray containsObject:self.currentModel]) {
                self.bottomView.currentIndex = [[self.manager selectedArray] indexOfObject:self.currentModel];
            }
        }
    }
    self.layoutSubviewsCompletion = YES;
}
- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [UINavigationBar appearance].translucent = YES;
    [[UIApplication sharedApplication] setStatusBarStyle:self.manager.configuration.statusBarStyle];
    if (self.exteriorPreviewStyle == HXPhotoViewPreViewShowStyleDark) {
        [self changeStatusBarWithHidden:YES];
        [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationFade];
    }
}
- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    HXPhotoModel *model = self.modelArray[self.currentModelIndex];
    self.currentModel = model;
    HXPhotoPreviewViewCell *cell = (HXPhotoPreviewViewCell *)[self.collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForItem:self.currentModelIndex inSection:0]];
    if (!cell) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.25 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            HXPhotoPreviewViewCell *tempCell = (HXPhotoPreviewViewCell *)[self.collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForItem:self.currentModelIndex inSection:0]];
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
                self.interactiveTransition = [[HXPhotoInteractiveTransition alloc] init];
                //给当前控制器的视图添加手势
                [self.interactiveTransition addPanGestureForViewController:self];
            });
        }else if (!self.disableaPersentInteractiveTransition) {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.25 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                //初始化手势过渡的代理
                self.persentInteractiveTransition = [[HXPhotoPersentInteractiveTransition alloc] init];
                //给当前控制器的视图添加手势
                [self.persentInteractiveTransition addPanGestureForViewController:self photoView:self.photoView];
            });
        }
        self.isAddInteractiveTransition = YES;
    }
}
- (void)viewWillDisappear:(BOOL)animated {
    if (self.exteriorPreviewStyle == HXPhotoViewPreViewShowStyleDark) {
        [self changeStatusBarWithHidden:NO];
        [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationFade];
    }
    HXPhotoPreviewViewCell *cell = (HXPhotoPreviewViewCell *)[self.collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForItem:self.currentModelIndex inSection:0]];
    cell.stopCancel = self.stopCancel;
    [cell cancelRequest];
    self.stopCancel = NO;
}
- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self setupUI];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(deviceOrientationChanged:) name:UIApplicationDidChangeStatusBarOrientationNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(deviceOrientationWillChanged:) name:UIApplicationWillChangeStatusBarOrientationNotification object:nil];
    
    [self addGesture];
}
#pragma mark - < private >
- (void)setExteriorPreviewStyle:(HXPhotoViewPreViewShowStyle)exteriorPreviewStyle {
    _exteriorPreviewStyle = exteriorPreviewStyle;
    if (exteriorPreviewStyle == HXPhotoViewPreViewShowStyleDark) {
        self.statusBarShouldBeHidden = YES;
    }
}
- (void)addGesture {
    UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(respondsToLongPress:)];
    [self.view addGestureRecognizer:longPress];
}
- (void)respondsToLongPress:(UILongPressGestureRecognizer *)sender {
    if (sender.state == UIGestureRecognizerStateBegan) {
        if (self.manager.configuration.previewRespondsToLongPress) {
            HXPhotoModel *model;
            if (self.modelArray.count) model = self.modelArray[self.currentModelIndex];
            self.manager.configuration.previewRespondsToLongPress(sender, model, self.manager, self);
        }
    }
}
- (void)deviceOrientationChanged:(NSNotification *)notify {
    self.orientationDidChange = YES;
}
- (void)deviceOrientationWillChanged:(NSNotification *)notify {
    self.beforeOrientationIndex = self.currentModelIndex;
}
- (void)changeSubviewFrame {
    UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
    HXPhotoModel *model = self.modelArray[self.currentModelIndex];
    if (orientation == UIInterfaceOrientationPortrait || UIInterfaceOrientationPortrait == UIInterfaceOrientationPortraitUpsideDown) {
        if (self.exteriorPreviewStyle == HXPhotoViewPreViewShowStyleDark) {
            [self changeStatusBarWithHidden:YES];
            [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationFade];
        }else {
            [self changeStatusBarWithHidden:NO];
            [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationFade];
        }
        self.titleLb.hidden = NO;
        self.customTitleView.frame = CGRectMake(0, 0, 150, 44);
        self.titleLb.frame = CGRectMake(0, 9, 150, 14);
        self.subTitleLb.frame = CGRectMake(0, CGRectGetMaxY(self.titleLb.frame) + 4, 150, 12);
        self.titleLb.text = model.barTitle;
        self.subTitleLb.text = model.barSubTitle;
    }else if (orientation == UIInterfaceOrientationLandscapeRight || orientation == UIInterfaceOrientationLandscapeLeft){
        if (self.exteriorPreviewStyle == HXPhotoViewPreViewShowStyleDark) {
            [self changeStatusBarWithHidden:YES];
            [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationFade];
        }else {
            [self changeStatusBarWithHidden:NO];
            [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationFade];
        }
        self.customTitleView.frame = CGRectMake(0, 0, 200, 30);
        self.titleLb.hidden = YES;
        self.subTitleLb.frame = CGRectMake(0, 0, 200, 30);
        self.subTitleLb.text = [NSString stringWithFormat:@"%@  %@",model.barTitle,model.barSubTitle];
    }
    CGFloat bottomMargin = hxBottomMargin;
    CGFloat width = self.view.hx_w;
    CGFloat itemMargin = 20;
    if (HX_IS_IPhoneX_All && (orientation == UIInterfaceOrientationLandscapeLeft || orientation == UIInterfaceOrientationLandscapeRight)) {
        bottomMargin = 21;
    }
    
    self.flowLayout.itemSize = CGSizeMake(width, self.view.hx_h);
    self.flowLayout.minimumLineSpacing = itemMargin;
    [self.collectionView setCollectionViewLayout:self.flowLayout];
    
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
    
    if (self.manager.configuration.previewBottomView) {
        self.manager.configuration.previewBottomView(self.bottomView);
    }
    if (self.manager.configuration.previewCollectionView) {
        self.manager.configuration.previewCollectionView(self.collectionView);
    }
    if (!self.outside) {
        if (self.manager.configuration.navigationBar) {
            self.manager.configuration.navigationBar(self.navigationController.navigationBar, self);
        }
    }else {
        if (self.exteriorPreviewStyle == HXPhotoViewPreViewShowStyleDefault) {
            if (self.manager.configuration.navigationBar) {
                self.manager.configuration.navigationBar(self.navBar, self);
            }
        }
    }
}
- (void)setupUI {
    [self.view addSubview:self.collectionView];
    if (self.exteriorPreviewStyle == HXPhotoViewPreViewShowStyleDefault) {
        self.view.backgroundColor = [UIColor whiteColor];
        [self.view addSubview:self.bottomView];
    }else if (self.exteriorPreviewStyle == HXPhotoViewPreViewShowStyleDark) {
        self.view.backgroundColor = [UIColor blackColor];
    }
    self.beforeOrientationIndex = self.currentModelIndex;
    
    HXPhotoModel *model = self.modelArray[self.currentModelIndex];
    self.currentModel = model;
    self.bottomView.outside = self.outside;
    [self.bottomView changeTipViewState:model];
    
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
        self.navigationItem.titleView = self.customTitleView;
        [self.navigationController.navigationBar setTintColor:self.manager.configuration.themeColor];
        if (self.manager.configuration.navBarBackgroudColor) {
            [self.navigationController.navigationBar setBackgroundColor:nil];
            [self.navigationController.navigationBar setBackgroundImage:nil forBarMetrics:UIBarMetricsDefault];
            self.navigationController.navigationBar.barTintColor = self.manager.configuration.navBarBackgroudColor;
        }
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
            self.bottomView.enabled = self.manager.configuration.photoCanEdit;
        }
        self.bottomView.selectCount = [self.manager selectedCount];
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:self.selectBtn];
        self.selectBtn.selected = model.selected;
        [self.selectBtn setTitle:model.selectIndexStr forState:UIControlStateSelected];
        self.selectBtn.backgroundColor = self.selectBtn.selected ? self.manager.configuration.themeColor : nil;
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
        if (model.subType == HXPhotoModelMediaSubTypeVideo) {
            self.bottomView.enabled = self.manager.configuration.videoCanEdit;
        } else {
            self.bottomView.enabled = self.manager.configuration.photoCanEdit;
        }
        if (self.exteriorPreviewStyle == HXPhotoViewPreViewShowStyleDefault) {
            [self.view addSubview:self.navBar];
            [self.navBar setTintColor:self.manager.configuration.themeColor];
            if (self.manager.configuration.navBarBackgroudColor) {
                [self.navBar setBackgroundColor:nil];
                [self.navBar setBackgroundImage:nil forBarMetrics:UIBarMetricsDefault];
                self.navBar.barTintColor = self.manager.configuration.navBarBackgroudColor;
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
            if (self.manager.afterSelectedCount <= 15) {
                [self.view addSubview:self.bottomPageControl];
            }
        }
    }
    [self changeSubviewFrame];
}
- (void)didSelectClick:(UIButton *)button {
    if (self.modelArray.count <= 0 || self.outside) {
        [self.view hx_showImageHUDText:[NSBundle hx_localizedStringForKey:@"没有照片可选!"]];
        return;
    }
    HXPhotoModel *model = self.modelArray[self.currentModelIndex];
    if (model.isICloud) {
        HXPhotoPreviewViewCell *cell = (HXPhotoPreviewViewCell *)[self.collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForItem:self.currentModelIndex inSection:0]];
        [cell cancelRequest];
        [cell requestHDImage];
        [self.view hx_showImageHUDText:[NSBundle hx_localizedStringForKey:@"正在下载iCloud上的资源"]];
        return;
    }
    if (button.selected) {
        button.selected = NO;
        [self.manager beforeSelectedListdeletePhotoModel:model];
    }else {
        NSString *str = [self.manager maximumOfJudgment:model];
        if (str) {
            [self.view hx_showImageHUDText:str];
            return;
        }
        HXPhotoPreviewViewCell *cell = (HXPhotoPreviewViewCell *)[self.collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForItem:self.currentModelIndex inSection:0]];
        
#if HasYYKitOrWebImage
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
    if ([self.delegate respondsToSelector:@selector(photoPreviewControllerDidSelect:model:)]) {
        [self.delegate photoPreviewControllerDidSelect:self model:model];
    }
    self.bottomView.selectCount = [self.manager selectedCount];
    if (button.selected) {
        [self.bottomView insertModel:model];
    }else {
        [self.bottomView deleteModel:model];
    }
}
- (void)dismissClick {
    self.manager.selectPhotoing = NO;
    [self dismissViewControllerAnimated:YES completion:nil];
    if (self.manager.configuration.restoreNavigationBar) {
        [UINavigationBar appearance].translucent = NO;
    }
}
- (void)deleteClick {
    if (!self.modelArray.count) {
        [self.view hx_showImageHUDText:[NSBundle hx_localizedStringForKey:@"当前没有可删除的资源"]];
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
        if ([weakSelf.delegate respondsToSelector:@selector(photoPreviewDidDeleteClick:deleteModel:deleteIndex:)]) {
            [weakSelf.delegate photoPreviewDidDeleteClick:weakSelf deleteModel:tempModel deleteIndex:tempIndex];
        }
        [weakSelf scrollViewDidScroll:weakSelf.collectionView];
        [weakSelf scrollViewDidEndDecelerating:weakSelf.collectionView];
        if (!weakSelf.modelArray.count) {
            [weakSelf dismissClick];
        }
    });
}
#pragma mark - < public >
- (HXPhotoPreviewViewCell *)currentPreviewCell:(HXPhotoModel *)model {
    if (!model) {
        return nil;
    }
    return (HXPhotoPreviewViewCell *)[self.collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForItem:self.currentModelIndex inSection:0]];
}
- (void)changeStatusBarWithHidden:(BOOL)hidden {
    self.statusBarShouldBeHidden = hidden;
    [self preferredStatusBarUpdateAnimation];
}
- (void)setSubviewAlphaAnimate:(BOOL)animete duration:(NSTimeInterval)duration {
    if (self.exteriorPreviewStyle == HXPhotoViewPreViewShowStyleDark) {
        return;
    }
    BOOL hide = NO;
    if (self.bottomView.alpha == 1) {
        hide = YES;
    }
    [self changeStatusBarWithHidden:hide];
    if (!hide) {
        [self.navigationController setNavigationBarHidden:hide animated:NO];
    }
    self.bottomView.userInteractionEnabled = !hide;
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
- (void)setupDarkBtnAlpha:(CGFloat)alpha {
    if (self.exteriorPreviewStyle == HXPhotoViewPreViewShowStyleDark) {
        self.darkDeleteBtn.alpha = alpha;
        self.darkCancelBtn.alpha = alpha;
        self.bottomPageControl.alpha = alpha;
    }
}

#pragma mark - < UICollectionViewDataSource >
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return [self.modelArray count];
}
- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    HXPhotoPreviewViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"DatePreviewCellId" forIndexPath:indexPath];
    HXWeakSelf
    cell.scrollViewDidScroll = ^(CGFloat offsetY) {
        if (weakSelf.currentCellScrollViewDidScroll) {
            weakSelf.currentCellScrollViewDidScroll(offsetY);
        }
    };
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
    [cell setCellDownloadICloudAssetComplete:^(HXPhotoPreviewViewCell *myCell) {
        if ([weakSelf.delegate respondsToSelector:@selector(photoPreviewDownLoadICloudAssetComplete:model:)]) {
            [weakSelf.delegate photoPreviewDownLoadICloudAssetComplete:weakSelf model:myCell.model];
        }
    }];
    cell.cellDownloadImageComplete = ^(HXPhotoPreviewViewCell *myCell) {
        if ([weakSelf.delegate respondsToSelector:@selector(photoPreviewCellDownloadImageComplete:model:)]) {
            [weakSelf.delegate photoPreviewCellDownloadImageComplete:weakSelf model:myCell.model];
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
    HXPhotoModel *model = self.modelArray[indexPath.item];
    cell.model = model;
    return cell;
}

#pragma mark - < UICollectionViewDelegate >
- (void)collectionView:(UICollectionView *)collectionView willDisplayCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath {
    [(HXPhotoPreviewViewCell *)cell resetScale:NO];
}
- (void)collectionView:(UICollectionView *)collectionView didEndDisplayingCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath {
    [(HXPhotoPreviewViewCell *)cell cancelRequest];
}
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
        [self.bottomView changeTipViewState:model];
        if (model.subType == HXPhotoModelMediaSubTypeVideo) {
            // 为视频时
            self.bottomView.enabled = self.manager.configuration.videoCanEdit;
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
            self.bottomView.enabled = self.manager.configuration.photoCanEdit;
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
            if ([self.modelArray containsObject:model] && self.layoutSubviewsCompletion) {
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
            if ([[self.manager selectedArray] containsObject:model] && self.layoutSubviewsCompletion) {
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
        HXPhotoPreviewViewCell *cell = (HXPhotoPreviewViewCell *)[self.collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForItem:self.currentModelIndex inSection:0]];
        HXPhotoModel *model = self.modelArray[self.currentModelIndex];
        self.currentModel = model;
        [cell requestHDImage];
    }
}
#pragma mark - < HXPhotoPreviewBottomViewDelegate >
- (void)photoPreviewBottomViewDidItem:(HXPhotoModel *)model currentIndex:(NSInteger)currentIndex beforeIndex:(NSInteger)beforeIndex {
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
        self.bottomView.currentIndex = beforeIndex;
    }
}
- (void)photoPreviewBottomViewDidEdit:(HXPhotoPreviewBottomView *)bottomView {
    if (!self.modelArray.count) {
        [self.view hx_showImageHUDText:[NSBundle hx_localizedStringForKey:@"当前没有可编辑的资源"]];
        return;
    }
    if (self.currentModel.networkPhotoUrl) {
        if (self.currentModel.downloadError) {
            [self.view hx_showImageHUDText:[NSBundle hx_localizedStringForKey:@"下载失败"]];
            return;
        }
        if (!self.currentModel.downloadComplete) {
            [self.view hx_showImageHUDText:[NSBundle hx_localizedStringForKey:@"照片正在下载"]];
            return;
        }
    }
    HXPhotoModel *model = [self.modelArray objectAtIndex:self.currentModelIndex];
    if (model.type == HXPhotoModelMediaTypePhotoGif ||
        model.cameraPhotoType == HXPhotoModelMediaTypeCameraPhotoTypeNetWorkGif) {
        HXWeakSelf
        hx_showAlert(self, [NSBundle hx_localizedStringForKey:@"编辑后，GIF将会变为静态图，确定继续吗？"], nil, [NSBundle hx_localizedStringForKey:@"取消"], [NSBundle hx_localizedStringForKey:@"确定"], nil, ^{
            [weakSelf jumpEditViewControllerWithModel:model];
        });
        return;
    }else if (model.type == HXPhotoModelMediaTypeLivePhoto) {
        HXWeakSelf
        hx_showAlert(self, [NSBundle hx_localizedStringForKey:@"编辑后，LivePhoto将会变为静态图，确定继续吗？"], nil, [NSBundle hx_localizedStringForKey:@"取消"], [NSBundle hx_localizedStringForKey:@"确定"], nil, ^{
            [weakSelf jumpEditViewControllerWithModel:model];
        });
    }else {
        [self jumpEditViewControllerWithModel:model];
    }
}
- (void)jumpEditViewControllerWithModel:(HXPhotoModel *)model {
    if (self.currentModel.subType == HXPhotoModelMediaSubTypePhoto) {
        if (self.manager.configuration.replacePhotoEditViewController) {
#pragma mark - < 替换图片编辑 >
            if (self.manager.configuration.shouldUseEditAsset) {
                self.manager.configuration.shouldUseEditAsset(self, self.outside, self.manager, model);
            }
            HXWeakSelf
            self.manager.configuration.usePhotoEditComplete = ^(HXPhotoModel *beforeModel, HXPhotoModel *afterModel) {
                [weakSelf photoEditViewControllerDidClipClick:nil beforeModel:beforeModel afterModel:afterModel];
            };
        }else {
            HXPhotoEditViewController *vc = [[HXPhotoEditViewController alloc] init];
            vc.isInside = YES;
            vc.model = [self.modelArray objectAtIndex:self.currentModelIndex];
            vc.delegate = self;
            vc.manager = self.manager;
            vc.outside = self.outside;
            vc.modalPresentationStyle = UIModalPresentationOverFullScreen;
            [self presentViewController:vc animated:YES completion:nil];
        }
    }else {
        if (self.manager.configuration.replaceVideoEditViewController) {
#pragma mark - < 替换视频编辑 >
            if (self.manager.configuration.shouldUseEditAsset) {
                self.manager.configuration.shouldUseEditAsset(self, self.outside, self.manager, model);
            }
            HXWeakSelf
            self.manager.configuration.useVideoEditComplete = ^(HXPhotoModel *beforeModel, HXPhotoModel *afterModel) {
                [weakSelf photoEditViewControllerDidClipClick:nil beforeModel:beforeModel afterModel:afterModel];
            };
        }else {
            HXPhotoPreviewViewCell *cell = (HXPhotoPreviewViewCell *)[self.collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForItem:self.currentModelIndex inSection:0]];
            HXVideoEditViewController *vc = [[HXVideoEditViewController alloc] init];
            vc.model = [self.modelArray objectAtIndex:self.currentModelIndex];
            vc.avAsset = cell.avAsset;
            vc.delegate = self;
            vc.manager = self.manager;
            vc.isInside = YES;
            vc.outside = self.outside;
            vc.modalPresentationStyle = UIModalPresentationOverFullScreen;
            [self presentViewController:vc animated:YES completion:nil];
        }
    }
}
- (void)photoPreviewBottomViewDidDone:(HXPhotoPreviewBottomView *)bottomView {
    if (self.manager.configuration.restoreNavigationBar) {
        [UINavigationBar appearance].translucent = NO;
    }
    if (self.outside) {
        self.manager.selectPhotoing = NO;
        [self dismissViewControllerAnimated:YES completion:nil];
        return;
    }
    if (self.modelArray.count == 0) {
        [self.view hx_showImageHUDText:[NSBundle hx_localizedStringForKey:@"没有照片可选!"]];
        return;
    }
    HXPhotoModel *model = self.modelArray[self.currentModelIndex];
    if (self.manager.shouldSelectModel) {
        NSString *str = self.manager.shouldSelectModel(model);
        if (str) {
            [self.view hx_showImageHUDText: [NSBundle hx_localizedStringForKey:str]];
            return;
        }
    }
    if (self.manager.configuration.singleSelected) {
        if (model.subType == HXPhotoModelMediaSubTypeVideo) {
            ;
            if (model.videoDuration >= self.manager.configuration.videoMaximumSelectDuration + 1) {
                [self.view hx_showImageHUDText:[NSString stringWithFormat:[NSBundle hx_localizedStringForKey:@"视频大于%ld秒，无法选择"], self.manager.configuration.videoMaximumSelectDuration]];
                return;
            }else if (model.videoDuration < self.manager.configuration.videoMinimumSelectDuration) {
                [self.view hx_showImageHUDText:[NSString stringWithFormat:[NSBundle hx_localizedStringForKey:@"视频少于%ld秒，无法选择"], self.manager.configuration.videoMinimumSelectDuration]];
                return;
            }
        }
        if ([self.delegate respondsToSelector:@selector(photoPreviewSingleSelectedClick:model:)]) {
            [self.delegate photoPreviewSingleSelectedClick:self model:model];
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
        if (model.subType == HXPhotoModelMediaSubTypeVideo) {
            if (model.videoDuration >= self.manager.configuration.videoMaximumSelectDuration + 1) {
                [self.view hx_showImageHUDText:[NSString stringWithFormat:[NSBundle hx_localizedStringForKey:@"视频大于%ld秒，无法选择"], self.manager.configuration.videoMaximumSelectDuration]];
                return;
            }else if (model.videoDuration < self.manager.configuration.videoMinimumSelectDuration) {
                [self.view hx_showImageHUDText:[NSString stringWithFormat:[NSBundle hx_localizedStringForKey:@"视频少于%ld秒，无法选择"], self.manager.configuration.videoMinimumSelectDuration]];
                return;
            }
        }
        if (!self.selectBtn.selected && !max && self.modelArray.count > 0) {
            //            model.selected = YES;
            HXPhotoPreviewViewCell *cell = (HXPhotoPreviewViewCell *)[self.collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForItem:self.currentModelIndex inSection:0]];
#if HasYYKitOrWebImage
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
        }
    }
    if ([self.delegate respondsToSelector:@selector(photoPreviewControllerDidDone:)]) {
        [self.delegate photoPreviewControllerDidDone:self];
    }
}
#pragma mark - < HXPhotoEditViewControllerDelegate >
- (void)photoEditViewControllerDidClipClick:(HXPhotoEditViewController *)photoEditViewController beforeModel:(HXPhotoModel *)beforeModel afterModel:(HXPhotoModel *)afterModel {
    if (self.outside) {
        [self.modelArray replaceObjectAtIndex:[self.modelArray indexOfObject:beforeModel] withObject:afterModel];
        if ([self.delegate respondsToSelector:@selector(photoPreviewSelectLaterDidEditClick:beforeModel:afterModel:)]) {
            [self.delegate photoPreviewSelectLaterDidEditClick:self beforeModel:beforeModel afterModel:afterModel];
        }
        [self dismissClick];
        return;
    }
    if (beforeModel.selected) {
        [self.manager beforeSelectedListdeletePhotoModel:beforeModel];
        [self.bottomView deleteModel:beforeModel];
    }
    [self.manager beforeListAddCameraPhotoModel:afterModel];
    
    if (!self.manager.configuration.singleSelected && !beforeModel.needHideSelectBtn) {
        NSString *str = [self.manager maximumOfJudgment:afterModel];
        if (!str) {
            [self.manager beforeSelectedListAddPhotoModel:afterModel];
            self.bottomView.selectCount = [self.manager selectedCount];
            [self.bottomView insertModel:afterModel];
        }
    }
    if (self.selectPreview) {
        self.modelArray = [NSMutableArray arrayWithArray:[self.manager selectedArray]];
    }
    
    if ([self.delegate respondsToSelector:@selector(photoPreviewDidEditClick:model:beforeModel:)]) {
        [self.delegate photoPreviewDidEditClick:self model:afterModel beforeModel:beforeModel];
    }
    [self.collectionView reloadData];
    if (self.selectPreview) {
        [self.collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForItem:self.modelArray.count - 1 inSection:0] atScrollPosition:UICollectionViewScrollPositionRight animated:NO];
    }else {
        [self scrollViewDidScroll:self.collectionView];
    }
}
#pragma mark - < HXVideoEditViewControllerDelegate >
- (void)videoEditViewControllerDidDoneClick:(HXVideoEditViewController *)videoEditViewController beforeModel:(HXPhotoModel *)beforeModel afterModel:(HXPhotoModel *)afterModel {
    [self photoEditViewControllerDidClipClick:nil beforeModel:beforeModel afterModel:afterModel];
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
- (UIButton *)darkCancelBtn {
    if (!_darkCancelBtn) {
        _darkCancelBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [_darkCancelBtn setBackgroundImage:[UIImage hx_imageNamed:@"hx_faceu_cancel"] forState:UIControlStateNormal];
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
        _customTitleView.hx_size = CGSizeMake(150, 44);
        [_customTitleView addSubview:self.titleLb];
        [_customTitleView addSubview:self.subTitleLb];
    }
    return _customTitleView;
}
- (UILabel *)titleLb {
    if (!_titleLb) {
        _titleLb = [[UILabel alloc] init];
        _titleLb.textAlignment = NSTextAlignmentCenter;
        if (HX_IOS82Later) {
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
        if (HX_IOS82Later) {
            _subTitleLb.font = [UIFont systemFontOfSize:11 weight:UIFontWeightRegular];
        }else {
            _subTitleLb.font = [UIFont systemFontOfSize:11];
        }
        _subTitleLb.textColor = [UIColor blackColor];
    }
    return _subTitleLb;
}
- (HXPhotoPreviewBottomView *)bottomView {
    if (!_bottomView) {
        if (self.outside) {
            _bottomView = [[HXPhotoPreviewBottomView alloc] initWithFrame:CGRectMake(0, self.view.hx_h - 50 - hxBottomMargin, self.view.hx_w, 50 + hxBottomMargin) modelArray:self.manager.afterSelectedArray manager:self.manager];
        }else {
            _bottomView = [[HXPhotoPreviewBottomView alloc] initWithFrame:CGRectMake(0, self.view.hx_h - 50 - hxBottomMargin, self.view.hx_w, 50 + hxBottomMargin) modelArray:self.manager.selectedArray manager:self.manager];
        }
        _bottomView.delagate = self;
    }
    return _bottomView;
}
- (UIButton *)selectBtn {
    if (!_selectBtn) {
        _selectBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [_selectBtn setBackgroundImage:[UIImage hx_imageNamed:@"hx_compose_guide_check_box_default_2"] forState:UIControlStateNormal];
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
        [_collectionView registerClass:[HXPhotoPreviewViewCell class] forCellWithReuseIdentifier:@"DatePreviewCellId"];
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
@end

@interface HXPhotoPreviewViewCell ()<UIScrollViewDelegate,PHLivePhotoViewDelegate>
@property (strong, nonatomic) UIScrollView *scrollView;
@property (strong, nonatomic) UIImageView *imageView;
@property (assign, nonatomic) CGPoint imageCenter;
@property (strong, nonatomic) UIImage *gifImage;
@property (strong, nonatomic) UIImage *gifFirstFrame;
@property (assign, nonatomic) PHImageRequestID requestID;
@property (assign, nonatomic) PHContentEditingInputRequestID gifRequestID;
@property (strong, nonatomic) PHLivePhotoView *livePhotoView;
@property (assign, nonatomic) BOOL livePhotoAnimating;
@property (strong, nonatomic) AVPlayerLayer *playerLayer;
@property (strong, nonatomic) AVPlayer *player;
@property (strong, nonatomic) HXCircleProgressView *progressView;
@property (strong, nonatomic) UIActivityIndicatorView *loadingView;
@end

@implementation HXPhotoPreviewViewCell
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
#if HasYYKitOrWebImage
    [self.scrollView addSubview:self.animatedImageView];
#else
    [self.scrollView addSubview:self.imageView];
#endif
    [self.contentView.layer addSublayer:self.playerLayer];
    [self.contentView addSubview:self.videoPlayBtn];
    [self.contentView addSubview:self.progressView];
    [self.contentView addSubview:self.loadingView];
}
- (CGFloat)getScrollViewZoomScale {
    return self.scrollView.zoomScale;
}
- (void)setScrollViewZoomScale:(CGFloat)zoomScale {
    [self.scrollView setZoomScale:zoomScale];
}
- (CGSize)getScrollViewContentSize {
    return self.scrollView.contentSize;
}
- (void)setScrollViewContnetSize:(CGSize)contentSize {
    [self.scrollView setContentSize:contentSize];
}
- (CGPoint)getScrollViewContentOffset {
    return self.scrollView.contentOffset;
}
- (void)setScrollViewContentOffset:(CGPoint)contentOffset {
    [self.scrollView setContentOffset:contentOffset];
}
- (void)resetScale:(BOOL)animated {
    if (self.model.type != HXPhotoModelMediaTypePhotoGif) {
        self.gifImage = nil;
    }
    [self resetScale:1.0f animated:animated];
}
- (void)resetScale:(CGFloat)scale animated:(BOOL)animated {
    [self.scrollView setZoomScale:scale animated:animated];
}
- (void)againAddImageView {
    [self refreshImageSize];
    [self.scrollView setZoomScale:1.0f];
#if HasYYKitOrWebImage
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
- (CGSize)getImageSize {
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
    }else {
        w = width;
        h = imgHeight;
    }
    return CGSizeMake(w, h);
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
#if HasYYKitOrWebImage
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

    [self resetScale:NO];

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
#if HasYYKitOrWebImage
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
HXWeakSelf
    if (model.type == HXPhotoModelMediaTypeCameraPhoto || model.type == HXPhotoModelMediaTypeCameraVideo) {
        if (model.networkPhotoUrl) {
            self.progressView.hidden = model.downloadComplete;
            CGFloat progress = (CGFloat)model.receivedSize / model.expectedSize;
            self.progressView.progress = progress;
#if HasYYKitOrWebImage
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
#if HasYYKitOrWebImage
            self.animatedImageView.image = model.thumbPhoto;
#else
            self.imageView.image = model.thumbPhoto;
#endif
            model.tempImage = nil;
        }
    }else {
        if (model.type == HXPhotoModelMediaTypeLivePhoto) {
            if (model.tempImage) {
#if HasYYKitOrWebImage
                self.animatedImageView.image = model.tempImage;
#else
                self.imageView.image = model.tempImage;
#endif
                model.tempImage = nil;
            }else {
                self.requestID = [model requestThumbImageWithSize:CGSizeMake(self.hx_w * 0.5, self.hx_h * 0.5) completion:^(UIImage *image, HXPhotoModel *model, NSDictionary *info) {
                    if (weakSelf.model != model) return;
#if HasYYKitOrWebImage
                    weakSelf.animatedImageView.image = image;
#else
                    weakSelf.imageView.image = image;
#endif
                }];
            }
        }else {
            if (model.previewPhoto) {
#if HasYYKitOrWebImage
                self.animatedImageView.image = model.previewPhoto;
#else
                self.imageView.image = model.previewPhoto;
#endif
                model.tempImage = nil;
            }else {
                if (model.tempImage) {
#if HasYYKitOrWebImage
                    self.animatedImageView.image = model.tempImage;
#else
                    self.imageView.image = model.tempImage;
#endif
                    model.tempImage = nil;
                }else {
                    CGSize requestSize;
                    if (imgHeight > imgWidth / 9 * 20 ||
                        imgWidth > imgHeight / 9 * 20) {
                        requestSize = CGSizeMake(self.hx_w * 0.6, self.hx_h * 0.6);
                    }else {
                        requestSize = CGSizeMake(model.endImageSize.width, model.endImageSize.height);
                    }
                    self.requestID =[model requestThumbImageWithSize:requestSize completion:^(UIImage *image, HXPhotoModel *model, NSDictionary *info) {
                        if (weakSelf.model != model) return;
#if HasYYKitOrWebImage
                        weakSelf.animatedImageView.image = image;
#else
                        weakSelf.imageView.image = image;
#endif
                    }];
                }
            }
        }
    }
    if (model.subType == HXPhotoModelMediaSubTypeVideo) {
        self.playerLayer.hidden = NO;
        self.videoPlayBtn.hidden = NO;
    }else {
        self.playerLayer.hidden = YES;
        self.videoPlayBtn.hidden = YES;
    }
}
- (void)requestHDImage {
    self.avAsset = nil;
    if (self.requestID) {
        [[PHImageManager defaultManager] cancelImageRequest:self.requestID];
        self.requestID = -1;
    }
    CGFloat width = self.frame.size.width;
    CGFloat height = self.frame.size.height;
    CGFloat imgWidth = self.model.imageSize.width;
    CGFloat imgHeight = self.model.imageSize.height;
    CGSize size;
    HXWeakSelf
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

    if (imgHeight > imgWidth / 9 * 20 ||
        imgWidth > imgHeight / 9 * 20) {
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
        self.requestID = [self.model requestLivePhotoWithSize:self.model.endImageSize startRequestICloud:^(PHImageRequestID iCloudRequestId, HXPhotoModel *model) {
            if (weakSelf.model != model) return;
            if (weakSelf.model.isICloud) {
                weakSelf.progressView.hidden = NO;
            }
            weakSelf.requestID = iCloudRequestId;
        } progressHandler:^(double progress, HXPhotoModel *model) {
            if (weakSelf.model != model) return;
            if (weakSelf.model.isICloud) {
                weakSelf.progressView.hidden = NO;
            }
            weakSelf.progressView.progress = progress;
        } success:^(PHLivePhoto *livePhoto, HXPhotoModel *model, NSDictionary *info) {
            if (weakSelf.model != model) return;
            [weakSelf downloadICloudAssetComplete];
#if HasYYKitOrWebImage
            weakSelf.livePhotoView.frame = weakSelf.animatedImageView.frame;
            weakSelf.animatedImageView.hidden = YES;
#else
            weakSelf.livePhotoView.frame = weakSelf.imageView.frame;
            weakSelf.imageView.hidden = YES;
#endif
            [weakSelf.scrollView addSubview:weakSelf.livePhotoView];
            weakSelf.livePhotoView.livePhoto = livePhoto;
            [weakSelf.livePhotoView startPlaybackWithStyle:PHLivePhotoViewPlaybackStyleFull];
        } failed:^(NSDictionary *info, HXPhotoModel *model) {
            if (weakSelf.model != model) return;
            weakSelf.progressView.hidden = YES;
        }];
    }else if (self.model.type == HXPhotoModelMediaTypePhoto) {
        self.requestID = [self.model requestPreviewImageWithSize:size startRequestICloud:^(PHImageRequestID iCloudRequestId, HXPhotoModel *model) {
            if (weakSelf.model != model) return;
            if (weakSelf.model.isICloud) {
                weakSelf.progressView.hidden = NO;
            }
            weakSelf.requestID = iCloudRequestId;
        } progressHandler:^(double progress, HXPhotoModel *model) {
            if (weakSelf.model != model) return;
            if (weakSelf.model.isICloud) {
                weakSelf.progressView.hidden = NO;
            }
            weakSelf.progressView.progress = progress;
        } success:^(UIImage *image, HXPhotoModel *model, NSDictionary *info) {
            if (weakSelf.model != model) return;
            [weakSelf downloadICloudAssetComplete];
            weakSelf.progressView.hidden = YES;
            CATransition *transition = [CATransition animation];
            transition.duration = 0.2f;
            transition.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
            transition.type = kCATransitionFade;
#if HasYYKitOrWebImage
            [weakSelf.animatedImageView.layer removeAllAnimations];
            weakSelf.animatedImageView.image = image;
            [weakSelf.animatedImageView.layer addAnimation:transition forKey:nil];
#else
            [weakSelf.imageView.layer removeAllAnimations];
            weakSelf.imageView.image = image;
            [weakSelf.imageView.layer addAnimation:transition forKey:nil];
#endif
        } failed:^(NSDictionary *info, HXPhotoModel *model) {
            if (weakSelf.model != model) return;
            weakSelf.progressView.hidden = YES;
        }];
    }else if (self.model.type == HXPhotoModelMediaTypePhotoGif) {
        if (self.gifImage) {
#if HasYYKitOrWebImage
            if (self.animatedImageView.image != self.gifImage) {
                self.animatedImageView.image = self.gifImage;
            }
#else
            if (self.imageView.image != self.gifImage) {
                self.imageView.image = self.gifImage;
            }
#endif
        }else {
            self.requestID = [self.model requestImageDataStartRequestICloud:^(PHImageRequestID iCloudRequestId, HXPhotoModel *model) {
                if (weakSelf.model != model) return;
                if (weakSelf.model.isICloud) {
                    weakSelf.progressView.hidden = NO;
                }
                weakSelf.requestID = iCloudRequestId;
            } progressHandler:^(double progress, HXPhotoModel *model) {
                if (weakSelf.model != model) return;
                if (weakSelf.model.isICloud) {
                    weakSelf.progressView.hidden = NO;
                }
                weakSelf.progressView.progress = progress;
            } success:^(NSData *imageData, UIImageOrientation orientation, HXPhotoModel *model, NSDictionary *info) {
                if (weakSelf.model != model) return;
                [weakSelf downloadICloudAssetComplete];
                weakSelf.progressView.hidden = YES;
#if HasYYKitOrWebImage
                YYImage *gifImage = [YYImage imageWithData:imageData];
                weakSelf.animatedImageView.image = gifImage;
                weakSelf.gifImage = gifImage;
#else
                UIImage *gifImage = [UIImage hx_animatedGIFWithData:imageData];
                weakSelf.imageView.image = gifImage;
                weakSelf.gifImage = gifImage;
                if (gifImage.images.count == 0) {
                    weakSelf.gifFirstFrame = gifImage;
                }else {
                    weakSelf.gifFirstFrame = gifImage.images.firstObject;
                }
#endif
                weakSelf.model.tempImage = nil;
            } failed:^(NSDictionary *info, HXPhotoModel *model) {
                if (weakSelf.model != model) return;
                weakSelf.progressView.hidden = YES;
            }];
        }
    }
    if (self.player != nil) return;
    if (self.model.subType == HXPhotoModelMediaSubTypeVideo) {
        [self.model requestAVAssetStartRequestICloud:^(PHImageRequestID iCloudRequestId, HXPhotoModel *model) {
            if (weakSelf.model != model) return;
            [weakSelf.loadingView startAnimating];
            weakSelf.videoPlayBtn.hidden = YES;
            weakSelf.requestID = iCloudRequestId;
        } progressHandler:^(double progress, HXPhotoModel *model) {
            if (weakSelf.model != model) return;
            weakSelf.progressView.progress = progress;
        } success:^(AVAsset *avAsset, AVAudioMix *audioMix, HXPhotoModel *model, NSDictionary *info) {
            if (weakSelf.model != model) return;
            weakSelf.avAsset = avAsset;
            [weakSelf downloadICloudAssetComplete];
            weakSelf.progressView.hidden = YES;
            [weakSelf.loadingView stopAnimating];
            weakSelf.videoPlayBtn.hidden = NO;
            weakSelf.player = [AVPlayer playerWithPlayerItem:[AVPlayerItem playerItemWithAsset:avAsset]];
            weakSelf.playerLayer.player = weakSelf.player;
            [[NSNotificationCenter defaultCenter] addObserver:weakSelf selector:@selector(pausePlayerAndShowNaviBar) name:AVPlayerItemDidPlayToEndTimeNotification object:weakSelf.player.currentItem];
        } failed:^(NSDictionary *info, HXPhotoModel *model) {
            if (weakSelf.model != model) return;
            [weakSelf.loadingView stopAnimating];
            weakSelf.videoPlayBtn.hidden = NO;
            weakSelf.progressView.hidden = YES;
        }];
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
    [self.player.currentItem seekToTime:CMTimeMake(0, 1)];
    [self.player play];
}
- (void)cancelRequest {
    if (self.requestID) {
        [[PHImageManager defaultManager] cancelImageRequest:self.requestID];
        self.requestID = -1;
    }
    //    self.videoPlayBtn.hidden = YES;
    self.progressView.hidden = YES;
    self.progressView.progress = 0;
    if (self.model.type == HXPhotoModelMediaTypeLivePhoto) {
        if (_livePhotoView.livePhoto) {
            self.livePhotoView.livePhoto = nil;
            [self.livePhotoView removeFromSuperview];
#if HasYYKitOrWebImage
            self.animatedImageView.hidden = NO;
#else
            self.imageView.hidden = NO;
#endif
            [self stopLivePhoto];
        }
    }else if (self.model.type == HXPhotoModelMediaTypePhoto) {
#if HasYYWebImage
        [self.animatedImageView yy_cancelCurrentImageRequest];
#elif HasYYKit
        [self.animatedImageView cancelCurrentImageRequest];
#elif HasSDWebImage
//        [self.imageView sd_cancelCurrentAnimationImagesLoad];
#endif
    }else if (self.model.type == HXPhotoModelMediaTypePhotoGif) {
        if (!self.stopCancel) {
#if HasYYKitOrWebImage
            self.animatedImageView.currentAnimatedImageIndex = 0;
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
#if HasYYKitOrWebImage
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
- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if (self.scrollViewDidScroll) {
        self.scrollViewDidScroll(scrollView.contentOffset.y);
    }
}
- (nullable UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView {
    if (self.model.subType == HXPhotoModelMediaSubTypeVideo) {
        return nil;
    }
    if (self.model.type == HXPhotoModelMediaTypeLivePhoto) {
        return self.livePhotoView;
    }else {
#if HasYYKitOrWebImage
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
#if HasYYKitOrWebImage
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
    if (!CGRectEqualToRect(self.scrollView.frame, self.bounds)) {
        self.scrollView.frame = self.bounds;
        self.scrollView.contentSize = CGSizeMake(self.hx_w, self.hx_h);
    }
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
#ifdef __IPHONE_11_0
    if (@available(iOS 11.0, *)) {
        _scrollView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
#else
        if ((NO)) {
#endif
        }
        UITapGestureRecognizer *tap1 = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(singleTap:)];
        [_scrollView addGestureRecognizer:tap1];
        UITapGestureRecognizer *tap2 = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(doubleTap:)];
        tap2.numberOfTapsRequired = 2;
        [tap1 requireGestureRecognizerToFail:tap2];
        [_scrollView addGestureRecognizer:tap2];
    }
    return _scrollView;
}
- (CGFloat)zoomScale {
    return self.scrollView.zoomScale;
}
#if HasYYKitOrWebImage
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
        [_videoPlayBtn setImage:[UIImage hx_imageNamed:@"hx_multimedia_videocard_play"] forState:UIControlStateNormal];
        [_videoPlayBtn setImage:[[UIImage alloc] init] forState:UIControlStateSelected];
        [_videoPlayBtn addTarget:self action:@selector(didPlayBtnClick:) forControlEvents:UIControlEventTouchUpInside];
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
            
