//
//  HXPhotoPreviewViewController.m
//  HXPhotoPickerExample
//
//  Created by Silence on 2017/10/14.
//  Copyright © 2017年 Silence. All rights reserved.
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
#import "HX_PhotoEditViewController.h"
#import "UIViewController+HXExtension.h"
#import "HXVideoEditViewController.h"
#import "HXPhotoPersentInteractiveTransition.h"
#import "HXPhotoBottomSelectView.h"
#import "UIImageView+HXExtension.h"
#import "UIColor+HXExtension.h"

#define HXDARKVIEWWIDTH 30

@interface HXPhotoPreviewViewController ()
<
UICollectionViewDataSource,
UICollectionViewDelegate,
HXPhotoPreviewBottomViewDelegate,
HXPhotoEditViewControllerDelegate,
HXVideoEditViewControllerDelegate,
HX_PhotoEditViewControllerDelegate
>
@property (strong, nonatomic) UICollectionViewFlowLayout *flowLayout;
@property (strong, nonatomic) HXPhotoModel *currentModel;
@property (strong, nonatomic) UIView *customTitleView;
@property (strong, nonatomic) UILabel *titleLb;
@property (strong, nonatomic) UILabel *subTitleLb;
@property (strong, nonatomic) HXPhotoPreviewViewCell *tempCell;
@property (strong, nonatomic) UIButton *selectBtn;
@property (assign, nonatomic) BOOL orientationDidChange;
@property (assign, nonatomic) BOOL firstChangeFrame;
@property (assign, nonatomic) NSInteger beforeOrientationIndex;
@property (strong, nonatomic) HXPhotoInteractiveTransition *interactiveTransition;
@property (strong, nonatomic) HXPhotoPersentInteractiveTransition *persentInteractiveTransition;

@property (strong, nonatomic) HXPhotoCustomNavigationBar *navBar;
@property (strong, nonatomic) UINavigationItem *navItem;
@property (assign, nonatomic) BOOL isAddInteractiveTransition;
@property (strong, nonatomic) UIView *dismissTempTopView;
@property (strong, nonatomic) UIPageControl *bottomPageControl;
@property (strong, nonatomic) UIView *darkCancelView;
@property (strong, nonatomic) UIView *darkDeleteView;
@property (strong, nonatomic) UIButton *darkCancelBtn;
@property (strong, nonatomic) UIButton *darkDeleteBtn;
@property (assign, nonatomic) BOOL statusBarShouldBeHidden;
@property (assign, nonatomic) BOOL layoutSubviewsCompletion;
@property (assign, nonatomic) BOOL singleSelectedJumpEdit;
@property (assign, nonatomic) BOOL didAddBottomPageControl;
@end

@implementation HXPhotoPreviewViewController
- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
    [super traitCollectionDidChange:previousTraitCollection];
#ifdef __IPHONE_13_0
    if (@available(iOS 13.0, *)) {
        if ([self.traitCollection hasDifferentColorAppearanceComparedToTraitCollection:previousTraitCollection]) {
            [self changeColor];
            [self changeStatusBarStyle];
            [self setNeedsStatusBarAppearanceUpdate];
            [self.collectionView reloadData];
            dispatch_async(dispatch_get_main_queue(), ^{
                HXPhotoPreviewViewCell *cell = (HXPhotoPreviewViewCell *)[self.collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForItem:self.currentModelIndex inSection:0]];
                [cell requestHDImage];
            });
        }
    }
#endif
}
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
#pragma clang diagnostic push
#pragma clang diagnostic ignored"-Wdeprecated-declarations"
        [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationFade];
#pragma clang diagnostic pop
    }
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidChangeStatusBarOrientationNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillChangeStatusBarOrientationNotification object:nil];
}
- (UIStatusBarStyle)preferredStatusBarStyle {
    if ([HXPhotoCommon photoCommon].isDark) {
        return UIStatusBarStyleLightContent;
    }
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
    if (!CGRectEqualToRect(self.view.frame, [UIScreen mainScreen].bounds)) {
        self.view.frame = [UIScreen mainScreen].bounds;
    }
    if (self.orientationDidChange || self.firstChangeFrame) {
        [self changeSubviewFrame];
        self.orientationDidChange = NO;
        self.firstChangeFrame = NO;
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
#pragma clang diagnostic push
#pragma clang diagnostic ignored"-Wdeprecated-declarations"
- (void)changeStatusBarStyle {
    if ([HXPhotoCommon photoCommon].isDark) {
        [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent animated:YES];
        return;
    }
    [[UIApplication sharedApplication] setStatusBarStyle:self.manager.configuration.statusBarStyle animated:YES];
}
- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self changeStatusBarStyle];
    if (self.exteriorPreviewStyle == HXPhotoViewPreViewShowStyleDark) {
        [self changeStatusBarWithHidden:YES];
        if (![UIApplication sharedApplication].statusBarHidden) {
            [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationFade];
        }
    }
    if (self.manager.viewWillAppear) {
        self.manager.viewWillAppear(self);
    }
}
#pragma clang diagnostic pop
- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    HXPhotoModel *model = self.modelArray[self.currentModelIndex];
    self.currentModel = model;
    HXPhotoPreviewViewCell *cell = (HXPhotoPreviewViewCell *)[self.collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForItem:self.currentModelIndex inSection:0]];
    if (!cell) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.25 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            NSIndexPath *indexPath = [NSIndexPath indexPathForItem:self.currentModelIndex inSection:0];
            if ([HXPhotoTools isRTLLanguage]) {
                indexPath = [NSIndexPath indexPathForItem:self.modelArray.count - 1 - self.currentModelIndex inSection:0];
            }
            HXPhotoPreviewViewCell *tempCell = (HXPhotoPreviewViewCell *)[self.collectionView cellForItemAtIndexPath:indexPath];
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
    if (self.manager.viewDidAppear) {
        self.manager.viewDidAppear(self);
    }
}
- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    if (self.exteriorPreviewStyle == HXPhotoViewPreViewShowStyleDark) {
        if ([UIApplication sharedApplication].statusBarHidden) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored"-Wdeprecated-declarations"
            [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationFade];
#pragma clang diagnostic pop
        }
        [self changeStatusBarWithHidden:NO];
    }
    HXPhotoPreviewViewCell *cell = (HXPhotoPreviewViewCell *)[self.collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForItem:self.currentModelIndex inSection:0]];
    cell.stopCancel = self.stopCancel;
    [cell cancelRequest];
    self.stopCancel = NO;
    if (self.manager.viewWillDisappear) {
        self.manager.viewWillDisappear(self);
    }
}
- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    if (self.manager.viewDidDisappear) {
        self.manager.viewDidDisappear(self);
    }
}
- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view
    self.didAddBottomPageControl = NO;
    self.singleSelectedJumpEdit = NO;
    self.extendedLayoutIncludesOpaqueBars = YES;
    self.edgesForExtendedLayout = UIRectEdgeAll;
    [self setupUI];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(deviceOrientationChanged:) name:UIApplicationDidChangeStatusBarOrientationNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(deviceOrientationWillChanged:) name:UIApplicationWillChangeStatusBarOrientationNotification object:nil];
    
    [self addGesture];
    
}
- (void)setCellImage:(UIImage *)image {
    if (image) {
        HXPhotoPreviewViewCell *cell = (HXPhotoPreviewViewCell *)[self.collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForItem:self.currentModelIndex inSection:0]];
        cell.previewContentView.imageView.image = image;
    }
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
    if (orientation == UIInterfaceOrientationPortrait || orientation == UIInterfaceOrientationPortraitUpsideDown) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored"-Wdeprecated-declarations"
        if (self.exteriorPreviewStyle == HXPhotoViewPreViewShowStyleDark) {
            [self changeStatusBarWithHidden:YES];
            [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationFade];
        }else {
            [self changeStatusBarWithHidden:NO];
            [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationFade];
        }
#pragma clang diagnostic pop
        self.titleLb.hidden = NO;
        self.customTitleView.frame = CGRectMake(0, 0, 150, 44);
        self.titleLb.frame = CGRectMake(0, 9, 150, 14);
        self.subTitleLb.frame = CGRectMake(0, CGRectGetMaxY(self.titleLb.frame) + 4, 150, 12);
        self.titleLb.text = model.barTitle;
        self.subTitleLb.text = model.barSubTitle;
    }else if (orientation == UIInterfaceOrientationLandscapeRight || orientation == UIInterfaceOrientationLandscapeLeft){
#pragma clang diagnostic push
#pragma clang diagnostic ignored"-Wdeprecated-declarations"
        if (self.exteriorPreviewStyle == HXPhotoViewPreViewShowStyleDark) {
            [self changeStatusBarWithHidden:YES];
            [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationFade];
        }else {
            [self changeStatusBarWithHidden:NO];
            [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationFade];
        }
#pragma clang diagnostic pop
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
    
    self.collectionView.contentSize = CGSizeMake(self.modelArray.count * (self.view.hx_w + itemMargin), self.view.hx_h);
    
    
    [self.collectionView setContentOffset:CGPointMake(self.beforeOrientationIndex * (self.view.hx_w + itemMargin), 0)];
    model.previewContentOffsetX = self.collectionView.contentOffset.x;
    
    if (self.orientationDidChange) {
        dispatch_async(dispatch_get_main_queue(), ^{
            HXPhotoPreviewViewCell *cell = [self currentPreviewCellWithIndex:self.currentModelIndex];
            [UIView animateWithDuration:0.25 animations:^{
                [cell refreshImageSize];
            }];
        });
    }
    
    CGFloat bottomViewHeight = self.view.hx_h - 50 - bottomMargin;
    if (self.outside) {
        if (self.exteriorPreviewStyle == HXPhotoViewPreViewShowStyleDefault) {
            self.navBar.frame = CGRectMake(0, 0, self.view.hx_w, hxNavigationBarHeight);
            self.bottomView.frame = CGRectMake(0, bottomViewHeight, self.view.hx_w, 50 + bottomMargin);
        }else if (self.exteriorPreviewStyle == HXPhotoViewPreViewShowStyleDark) {
            CGFloat topMargin = HX_IS_IPhoneX_All ? ((orientation == UIInterfaceOrientationLandscapeRight || orientation == UIInterfaceOrientationLandscapeLeft) ? 25 : 45) : 25;
            if (self.previewShowDeleteButton) {
                self.darkDeleteView.frame = CGRectMake(self.view.hx_w - HXDARKVIEWWIDTH - 15, topMargin, HXDARKVIEWWIDTH, HXDARKVIEWWIDTH);
            }
            self.darkCancelView.frame = CGRectMake(15, topMargin, HXDARKVIEWWIDTH, HXDARKVIEWWIDTH);
            CGFloat pageControlY = HX_IS_IPhoneX_All ? self.view.hx_h - 40 : self.view.hx_h - 30;
            self.bottomPageControl.frame = CGRectMake(0, pageControlY, self.view.hx_w, 10);
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
    self.navigationController.navigationBar.translucent = self.manager.configuration.navBarTranslucent;
    if (!self.outside) {
        if (self.manager.configuration.navigationBar) {
            self.manager.configuration.navigationBar(self.navigationController.navigationBar, self);
        }
    }else {
        self.navBar.translucent = self.manager.configuration.navBarTranslucent;
        if (self.exteriorPreviewStyle == HXPhotoViewPreViewShowStyleDefault) {
            if (self.manager.configuration.navigationBar) {
                self.manager.configuration.navigationBar(self.navBar, self);
            }
        }
    }
}
- (void)changeColor {
    UIColor *backgroundColor;
    UIColor *themeColor;
    UIColor *navBarBackgroudColor;
    UIColor *navigationTitleColor;
    UIColor *selectedTitleColor;
    UIColor *selectBtnBgColor;
    UIColor *selectBtnTitleColor;
    if ([HXPhotoCommon photoCommon].isDark) {
        backgroundColor = [UIColor blackColor];
        themeColor = [UIColor whiteColor];
        navBarBackgroudColor = [UIColor blackColor];
        navigationTitleColor = [UIColor whiteColor];
        selectBtnBgColor = self.manager.configuration.previewDarkSelectBgColor;
        selectBtnTitleColor = self.manager.configuration.previewDarkSelectTitleColor;
    }else {
        backgroundColor = (_bottomView && _bottomView.alpha == 0) ? [UIColor blackColor] : self.manager.configuration.previewPhotoViewBgColor;
        themeColor = self.manager.configuration.themeColor;
        navBarBackgroudColor = self.manager.configuration.navBarBackgroudColor;
        navigationTitleColor = self.manager.configuration.navigationTitleColor;
        selectedTitleColor = self.manager.configuration.selectedTitleColor;
        selectBtnTitleColor = selectedTitleColor;
        if (self.manager.configuration.previewSelectedBtnBgColor) {
            selectBtnBgColor = self.manager.configuration.previewSelectedBtnBgColor;
        }else {
            selectBtnBgColor = themeColor;
        }
    }
    if (self.exteriorPreviewStyle == HXPhotoViewPreViewShowStyleDefault) {
        self.collectionView.backgroundColor = backgroundColor;
    }else if (self.exteriorPreviewStyle == HXPhotoViewPreViewShowStyleDark) {
        self.collectionView.backgroundColor = [UIColor blackColor];
    }
    if (self.exteriorPreviewStyle == HXPhotoViewPreViewShowStyleDefault) {
        self.view.backgroundColor = backgroundColor;
        [self.view addSubview:self.bottomView];
    }else if (self.exteriorPreviewStyle == HXPhotoViewPreViewShowStyleDark) {
        self.view.backgroundColor = [UIColor blackColor];
    }
    if (!self.outside) {
        [self.navigationController.navigationBar setTintColor:themeColor];
        self.navigationController.navigationBar.barTintColor = navBarBackgroudColor;
        self.navigationController.navigationBar.barStyle = self.manager.configuration.navBarStyle;

        if (self.manager.configuration.navBarBackgroundImage) {
            [self.navigationController.navigationBar setBackgroundImage:self.manager.configuration.navBarBackgroundImage forBarMetrics:UIBarMetricsDefault];
        }
        
        if (self.manager.configuration.navigationTitleSynchColor) {
            self.titleLb.textColor = themeColor;
            self.subTitleLb.textColor = themeColor;
        }else {
            UIColor *titleColor = [self.navigationController.navigationBar.titleTextAttributes objectForKey:NSForegroundColorAttributeName];
            if (titleColor) {
                self.titleLb.textColor = titleColor;
                self.subTitleLb.textColor = titleColor;
            }
            if (navigationTitleColor) {
                self.titleLb.textColor = navigationTitleColor;
                self.subTitleLb.textColor = navigationTitleColor;
            }else {
                self.titleLb.textColor = [UIColor blackColor];
                self.subTitleLb.textColor = [UIColor blackColor];
            }
        }
        self.selectBtn.backgroundColor = self.selectBtn.selected ? selectBtnBgColor : nil;
    }else {
        if (self.exteriorPreviewStyle == HXPhotoViewPreViewShowStyleDefault) {
            [self.navBar setTintColor:themeColor];
            
            self.navBar.barTintColor = navBarBackgroudColor;
            self.navBar.barStyle = self.manager.configuration.navBarStyle;
            if (self.manager.configuration.navBarBackgroundImage) {
                [self.navBar setBackgroundImage:self.manager.configuration.navBarBackgroundImage forBarMetrics:UIBarMetricsDefault];
            }
            
            if (self.manager.configuration.navigationTitleSynchColor) {
                self.titleLb.textColor = themeColor;
                self.subTitleLb.textColor = themeColor;
            }else {
                UIColor *titleColor = [self.navBar.titleTextAttributes objectForKey:NSForegroundColorAttributeName];
                if (titleColor) {
                    self.titleLb.textColor = titleColor;
                    self.subTitleLb.textColor = titleColor;
                }
                if (navigationTitleColor) {
                    self.titleLb.textColor = navigationTitleColor;
                    self.subTitleLb.textColor = navigationTitleColor;
                }else {
                    self.titleLb.textColor = [UIColor blackColor];
                    self.subTitleLb.textColor = [UIColor blackColor];
                }
            }
        }
    }
    if ([selectBtnBgColor isEqual:[UIColor whiteColor]]) {
        [_selectBtn setTitleColor:[UIColor blackColor] forState:UIControlStateSelected];
    }else {
        [_selectBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateSelected];
    }
    if (selectBtnTitleColor) {
        [_selectBtn setTitleColor:selectBtnTitleColor forState:UIControlStateSelected];
    }
}
- (void)setupUI {
    [self.view addSubview:self.collectionView];
    self.beforeOrientationIndex = self.currentModelIndex;
    if (self.exteriorPreviewStyle == HXPhotoViewPreViewShowStyleDefault) {
        [self.view addSubview:self.bottomView];
    }
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
        if (model.subType == HXPhotoModelMediaSubTypeVideo) {
            self.bottomView.enabled = self.manager.configuration.videoCanEdit;
        } else {
            self.bottomView.enabled = self.manager.configuration.photoCanEdit;
        }
        self.bottomView.selectCount = [self.manager selectedCount];
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:self.selectBtn];
        self.selectBtn.selected = model.selected;
        [self.selectBtn setTitle:model.selectIndexStr forState:UIControlStateSelected];
        CGFloat selectTextWidth = [self.selectBtn.titleLabel hx_getTextWidth];
        if (selectTextWidth + 10 > 24 && self.selectBtn.selected) {
            self.selectBtn.hx_w = selectTextWidth + 10;
        }else {
            self.selectBtn.hx_w = 24;
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
        if (model.subType == HXPhotoModelMediaSubTypeVideo) {
            self.bottomView.enabled = self.manager.configuration.videoCanEdit;
        } else {
            self.bottomView.enabled = self.manager.configuration.photoCanEdit;
        }
        if (self.exteriorPreviewStyle == HXPhotoViewPreViewShowStyleDefault) {
            [self.view addSubview:self.navBar];
        }else if (self.exteriorPreviewStyle == HXPhotoViewPreViewShowStyleDark) {
            
            self.darkDeleteView.alpha = 1;
            self.darkDeleteView.hidden = NO;
            [self.view addSubview:self.darkCancelView];
            if (self.previewShowDeleteButton) {
                [self.view addSubview:self.darkDeleteView];
            }
            if ([self.manager.afterSelectedArray containsObject:model]) {
                self.bottomPageControl.currentPage = [[self.manager afterSelectedArray] indexOfObject:model];
            }
            BOOL canAddBottomPageControl =  HX_IOS14_Later ? YES : (self.manager.afterSelectedCount <= 15);
            if (canAddBottomPageControl && self.showBottomPageControl) {
                [self.view addSubview:self.bottomPageControl];
                self.didAddBottomPageControl = YES;
            }
        }
    }
    [self changeColor];
    self.firstChangeFrame = YES;
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
            if ([str isEqualToString:@"selectVideoBeyondTheLimitTimeAutoEdit"]) {
                [self jumpVideoEdit];
            }else {
                [self.view hx_showImageHUDText:str];
            }
            return;
        }
        HXPhotoPreviewViewCell *cell = (HXPhotoPreviewViewCell *)[self.collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForItem:self.currentModelIndex inSection:0]];
        model.thumbPhoto = cell.image;
        model.previewPhoto = cell.image;
        [self.manager beforeSelectedListAddPhotoModel:model];
        button.selected = YES;
        [button setTitle:model.selectIndexStr forState:UIControlStateSelected];
        CAKeyframeAnimation *anim = [CAKeyframeAnimation animationWithKeyPath:@"transform.scale"];
        anim.duration = 0.25;
        anim.values = @[@(1.2),@(0.8),@(1.1),@(0.9),@(1.0)];
        [button.layer addAnimation:anim forKey:@""];
    }
    CGFloat selectTextWidth = [self.selectBtn.titleLabel hx_getTextWidth];
    if (selectTextWidth + 10 > 24 && self.selectBtn.selected) {
        self.selectBtn.hx_w = selectTextWidth + 10;
    }else {
        self.selectBtn.hx_w = 24;
    }
    UIColor *btnBgColor = self.manager.configuration.previewSelectedBtnBgColor ?: self.manager.configuration.themeColor;
    if ([HXPhotoCommon photoCommon].isDark) {
        btnBgColor = self.manager.configuration.previewDarkSelectBgColor;
    }
    button.backgroundColor = button.selected ? btnBgColor : nil;
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
- (void)cancelDismissClick {
    self.manager.selectPhotoing = NO;
    if ([self.delegate respondsToSelector:@selector(photoPreviewControllerDidCancel:model:)]) {
        HXPhotoModel *model;
        if (self.modelArray.count) {
            model = self.modelArray[self.currentModelIndex];
        }
        [self.delegate photoPreviewControllerDidCancel:self model:model];
    }
    BOOL selectPhotoCancelDismissAnimated = self.manager.selectPhotoCancelDismissAnimated;
    [self dismissViewControllerAnimated:selectPhotoCancelDismissAnimated completion:^{
        if ([self.delegate respondsToSelector:@selector(photoPreviewControllerCancelDismissCompletion:)]) {
            [self.delegate photoPreviewControllerCancelDismissCompletion:self];
        }
    }];
}
- (void)dismissClick {
    self.manager.selectPhotoing = NO;
    BOOL selectPhotoFinishDismissAnimated = self.manager.selectPhotoFinishDismissAnimated;
    [self dismissViewControllerAnimated:selectPhotoFinishDismissAnimated completion:^{
        if ([self.delegate respondsToSelector:@selector(photoPreviewControllerFinishDismissCompletion:)]) {
            [self.delegate photoPreviewControllerFinishDismissCompletion:self];
        }
    }];
}
- (void)deleteClick {
    if (!self.modelArray.count) {
        [self.view hx_showImageHUDText:[NSBundle hx_localizedStringForKey:@"当前没有可删除的资源"]];
        return;
    }
    NSString *message;
    if (self.currentModel.subType == HXPhotoModelMediaSubTypePhoto) {
        message = [NSBundle hx_localizedStringForKey:@"要删除这张照片吗?"];
    }else {
        message = [NSBundle hx_localizedStringForKey:@"要删除此视频吗?"];
    }
    HXPhotoBottomViewModel *titleModel = [[HXPhotoBottomViewModel alloc] init];
    titleModel.title = message;
    titleModel.titleFont = [UIFont systemFontOfSize:13];
    titleModel.titleColor = [UIColor hx_colorWithHexStr:@"#666666"];
    titleModel.titleDarkColor = [UIColor hx_colorWithHexStr:@"#999999"];
    titleModel.cellHeight = 60.f;
    titleModel.canSelect = NO;
    
    HXPhotoBottomViewModel *deleteModel = [[HXPhotoBottomViewModel alloc] init];
    deleteModel.title = [NSBundle hx_localizedStringForKey:@"删除"];
    deleteModel.titleColor = [UIColor redColor];
    deleteModel.titleDarkColor = [[UIColor redColor] colorWithAlphaComponent:0.8f];
    HXWeakSelf
    [HXPhotoBottomSelectView showSelectViewWithModels:@[titleModel, deleteModel] selectCompletion:^(NSInteger index, HXPhotoBottomViewModel * _Nonnull model) {
        HXPhotoModel *tempModel = weakSelf.currentModel;
        NSInteger tempIndex = weakSelf.currentModelIndex;
        
        [weakSelf.modelArray removeObject:weakSelf.currentModel];
        [weakSelf.collectionView performBatchUpdates:^{
            [weakSelf.collectionView deleteItemsAtIndexPaths:@[[NSIndexPath indexPathForItem:weakSelf.currentModelIndex inSection:0]]];
        } completion:^(BOOL finished) {
            if (weakSelf.modelArray.count == 1) {
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2f * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    [weakSelf scrollViewDidScroll:weakSelf.collectionView];
                    [weakSelf scrollViewDidEndDecelerating:weakSelf.collectionView];
                });
            }else {
                [weakSelf scrollViewDidScroll:weakSelf.collectionView];
                [weakSelf scrollViewDidEndDecelerating:weakSelf.collectionView];
            }
        }];
        [weakSelf.bottomView deleteModel:weakSelf.currentModel];
        if (weakSelf.exteriorPreviewStyle == HXPhotoViewPreViewShowStyleDark) {
            weakSelf.bottomPageControl.numberOfPages = weakSelf.modelArray.count;
        }
        if ([weakSelf.delegate respondsToSelector:@selector(photoPreviewDidDeleteClick:deleteModel:deleteIndex:)]) {
            [weakSelf.delegate photoPreviewDidDeleteClick:weakSelf deleteModel:tempModel deleteIndex:tempIndex];
        }
        if (!weakSelf.modelArray.count) {
            [weakSelf dismissClick];
        }
    } cancelClick:nil];
}
#pragma mark - < public >
- (HXPhotoPreviewViewCell *)currentPreviewCellWithIndex:(NSInteger)index {
    if (index < 0) {
        index = 0;
    }
    if (index > self.modelArray.count - 1) {
        index = self.modelArray.count - 1;
    }
    return (HXPhotoPreviewViewCell *)[self.collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForItem:index inSection:0]];
}
- (HXPhotoPreviewViewCell *)currentPreviewCell:(HXPhotoModel *)model {
    if (!model) {
        return nil;
    }
    return (HXPhotoPreviewViewCell *)[self.collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForItem:self.currentModelIndex inSection:0]];
}
- (void)changeStatusBarWithHidden:(BOOL)hidden {
    self.statusBarShouldBeHidden = hidden;
//    [self preferredStatusBarUpdateAnimation];
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
    UIColor *bgColor = [HXPhotoCommon photoCommon].isDark ? [UIColor blackColor] : self.manager.configuration.previewPhotoViewBgColor;
    if (animete) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored"-Wdeprecated-declarations"
        [[UIApplication sharedApplication] setStatusBarHidden:hide withAnimation:UIStatusBarAnimationFade];
#pragma clang diagnostic pop
        [UIView animateWithDuration:duration animations:^{
            self.navigationController.navigationBar.alpha = hide ? 0 : 1;
            if (self.outside) {
                self.navBar.alpha = hide ? 0 : 1;
            }
            self.view.backgroundColor = hide ? [UIColor blackColor] : bgColor;
            self.collectionView.backgroundColor = hide ? [UIColor blackColor] : bgColor;
            self.bottomView.alpha = hide ? 0 : 1;
        } completion:^(BOOL finished) {
            if (hide) {
                [self.navigationController setNavigationBarHidden:hide animated:NO];
            }
        }];
    }else {
#pragma clang diagnostic push
#pragma clang diagnostic ignored"-Wdeprecated-declarations"
        [[UIApplication sharedApplication] setStatusBarHidden:hide];
#pragma clang diagnostic pop
        self.navigationController.navigationBar.alpha = hide ? 0 : 1;
        if (self.outside) {
            self.navBar.alpha = hide ? 0 : 1;
        }
        self.view.backgroundColor = hide ? [UIColor blackColor] : bgColor;
        self.collectionView.backgroundColor = hide ? [UIColor blackColor] : bgColor;
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
        self.darkDeleteView.alpha = alpha;
        self.darkCancelView.alpha = alpha;
        self.bottomPageControl.alpha = alpha;
    }
}

#pragma mark - < UICollectionViewDataSource >
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return [self.modelArray count];
}
- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    NSInteger index = indexPath.item;
    if ([HXPhotoTools isRTLLanguage]) {
        index = self.modelArray.count - 1 - indexPath.item;
    }
    HXPhotoModel *model = self.modelArray[index];
    HXPhotoPreviewViewCell *cell;
    HXWeakSelf
    if (model.subType == HXPhotoModelMediaSubTypePhoto) {
        if (model.type == HXPhotoModelMediaTypeLivePhoto) {
            cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"HXPhotoPreviewLivePhotoCell" forIndexPath:indexPath];
        }else {
            if (model.type == HXPhotoModelMediaTypeCameraPhoto &&
               ( model.cameraPhotoType == HXPhotoModelMediaTypeCameraPhotoTypeLocalLivePhoto ||
                 model.cameraPhotoType == HXPhotoModelMediaTypeCameraPhotoTypeNetWorkLivePhoto)) {
                    cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"HXPhotoPreviewLivePhotoCell" forIndexPath:indexPath];
            }else {
                cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"HXPhotoPreviewImageViewCell" forIndexPath:indexPath];
            }
        }
    }else if (model.subType == HXPhotoModelMediaSubTypeVideo) {
        cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"HXPhotoPreviewVideoViewCell" forIndexPath:indexPath];
        if (self.exteriorPreviewStyle == HXPhotoViewPreViewShowStyleDark) {
            HXPhotoPreviewVideoViewCell *viewCell = (HXPhotoPreviewVideoViewCell *)cell;
            viewCell.bottomSliderView.alpha = 1;
            viewCell.bottomSliderView.hidden = NO;
            viewCell.didAddBottomPageControl = self.modelArray.count <= 1 ? NO : self.didAddBottomPageControl;
        }
    }else {
        cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"HXPhotoPreviewImageViewCell" forIndexPath:indexPath];
    }
    cell.allowPreviewDirectLoadOriginalImage = self.manager.configuration.allowPreviewDirectLoadOriginalImage;
    cell.cellViewLongPressGestureRecognizerBlock = ^(UILongPressGestureRecognizer * _Nonnull longPress) {
        [weakSelf respondsToLongPress:longPress];
    };
    cell.scrollViewDidScroll = ^(UIScrollView *scrollView) {
        if (weakSelf.currentCellScrollViewDidScroll) {
            weakSelf.currentCellScrollViewDidScroll(scrollView);
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
    [cell setCellTapClick:^(HXPhotoModel *model, HXPhotoPreviewViewCell *myCell) {
        if (weakSelf.exteriorPreviewStyle == HXPhotoViewPreViewShowStyleDark &&
            weakSelf.outside) {
            if (model.subType == HXPhotoModelMediaSubTypeVideo) {
                HXPhotoPreviewVideoViewCell *videoCell = (HXPhotoPreviewVideoViewCell *)myCell;
                BOOL hidden = YES;
                if (videoCell.bottomSliderView.hidden || videoCell.bottomSliderView.alpha == 0) {
                    hidden = NO;
                }
                [weakSelf setCurrentCellBottomSliderViewHidden:hidden animation:YES];
            }else {
                [weakSelf dismissClick];
            }
        }else {
            if (model.subType == HXPhotoModelMediaSubTypeVideo) {
                HXPhotoPreviewVideoViewCell *videoCell = (HXPhotoPreviewVideoViewCell *)myCell;
                if (weakSelf.bottomView.userInteractionEnabled) {
                    if (!videoCell.previewContentView.videoView.isPlayer) {
                        [videoCell.previewContentView.videoView didPlayBtnClickWithSelected:YES];
                    }
                }else {
                    if (videoCell.previewContentView.videoView.isPlayer) {
                        [videoCell.previewContentView.videoView didPlayBtnClickWithSelected:NO];
                        videoCell.previewContentView.videoView.playBtnHidden = NO;
                    }
                }
                
            }
            [weakSelf setSubviewAlphaAnimate:YES];
        }
    }];
    cell.model = model;
    return cell;
}

- (void)setCurrentCellBottomSliderViewHidden:(BOOL)hidden animation:(BOOL)animation {
    HXPhotoPreviewVideoViewCell *cell = (HXPhotoPreviewVideoViewCell *)[self currentPreviewCell:self.currentModel];
    if (cell.bottomSliderView.hidden == hidden && cell.bottomSliderView.alpha == !hidden) {
        return;
    }
    if (animation) {
        if (!hidden) {
            if (cell.previewContentView.videoView.playBtnDidPlay) {
                cell.bottomSliderView.hidden = hidden;
            }
            self.darkCancelView.hidden = hidden;
            self.darkDeleteView.hidden = hidden;
        }
        [UIView animateWithDuration:0.25 animations:^{
            if (cell.previewContentView.videoView.playBtnDidPlay) {
                cell.bottomSliderView.alpha = !hidden;
            }
            self.darkCancelView.alpha = !hidden;
            self.darkDeleteView.alpha = !hidden;
        } completion:^(BOOL finished) {
            if (cell.previewContentView.videoView.playBtnDidPlay) {
                cell.bottomSliderView.hidden = hidden;
            }
            self.darkCancelView.hidden = hidden;
            self.darkDeleteView.hidden = hidden;
        }];
    }else {
        self.darkCancelView.alpha = !hidden;
        self.darkCancelView.hidden = hidden;
        self.darkDeleteView.alpha = !hidden;
        self.darkDeleteView.hidden = hidden;
        if (cell.previewContentView.videoView.playBtnDidPlay) {
            cell.bottomSliderView.hidden = hidden;
            cell.bottomSliderView.alpha = !hidden;
        }
    }
}

#pragma mark - < UICollectionViewDelegate >
- (void)collectionView:(UICollectionView *)collectionView willDisplayCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath {
    self.persentInteractiveTransition.atFirstPan = NO;
    self.interactiveTransition.atFirstPan = NO;
    [(HXPhotoPreviewViewCell *)cell resetScale:NO];
}
- (void)collectionView:(UICollectionView *)collectionView didEndDisplayingCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath {
    HXPhotoPreviewViewCell *myCell = (HXPhotoPreviewViewCell *)cell;
    [myCell cancelRequest];
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
            self.bottomView.hideEditBtn = !self.manager.configuration.videoCanEdit;
        }else {
            self.bottomView.hideEditBtn = !self.manager.configuration.photoCanEdit;
            self.bottomView.enabled = self.manager.configuration.photoCanEdit;
        }
        UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
        if (orientation == UIInterfaceOrientationPortrait || orientation == UIInterfaceOrientationPortraitUpsideDown) {
            self.titleLb.text = model.barTitle;
            self.subTitleLb.text = model.barSubTitle;
        }else if (orientation == UIInterfaceOrientationLandscapeRight || orientation == UIInterfaceOrientationLandscapeLeft) {
            self.subTitleLb.text = [NSString stringWithFormat:@"%@  %@",model.barTitle,model.barSubTitle];
        }
        self.selectBtn.selected = model.selected;
        [self.selectBtn setTitle:model.selectIndexStr forState:UIControlStateSelected];
        CGFloat selectTextWidth = [self.selectBtn.titleLabel hx_getTextWidth];
        if (selectTextWidth + 10 > 24 && self.selectBtn.selected) {
            self.selectBtn.hx_w = selectTextWidth + 10;
        }else {
            self.selectBtn.hx_w = 24;
        }
        
        UIColor *themeColor = [HXPhotoCommon photoCommon].isDark ? self.manager.configuration.previewDarkSelectBgColor : self.manager.configuration.previewSelectedBtnBgColor;
        self.selectBtn.backgroundColor = self.selectBtn.selected ? themeColor : nil;
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
    if (currentIndex >= 0 && currentIndex < self.modelArray.count) {
        HXPhotoModel *nextModel;
        if (self.currentModel.previewContentOffsetX > offsetx) {
            NSInteger index = [self.modelArray indexOfObject:self.currentModel] - 1;
            if (index >= 0 && index < self.modelArray.count) {
                nextModel = self.modelArray[index];
            }
        }else if (self.currentModel.previewContentOffsetX < offsetx){
            NSInteger index = [self.modelArray indexOfObject:self.currentModel] + 1;
            if (index >= 0 && index < self.modelArray.count) {
                nextModel = self.modelArray[index];
            }
        }
        if (nextModel && !self.orientationDidChange) {
            [self scrollDidScrollHiddenBottomSliderViewWithOffsetX:offsetx nextModel:nextModel];
        }
    }
}
- (void)scrollDidScrollHiddenBottomSliderViewWithOffsetX:(CGFloat)offsetx nextModel:(HXPhotoModel *)nextModel {
    if (self.currentModel == nextModel) {
        return;
    }
    if (self.exteriorPreviewStyle == HXPhotoViewPreViewShowStyleDark) {
        float difference = fabs(offsetx - self.currentModel.previewContentOffsetX);
        CGFloat width = [UIScreen mainScreen].bounds.size.width;
        if (difference > width) {
            difference = width;
        }
        CGFloat scale = difference / width;
        if (self.previewShowDeleteButton) {
            self.darkDeleteView.hidden = NO;
            if (self.darkDeleteView.alpha < 1) {
                self.darkDeleteView.alpha = scale;
            }
        }
        self.darkCancelView.hidden = NO;
        if (self.darkCancelView.alpha < 1) {
            self.darkCancelView.alpha = scale;
        }
        if (nextModel.subType == HXPhotoModelMediaSubTypeVideo) {
            HXPhotoPreviewVideoViewCell *nextCell = (HXPhotoPreviewVideoViewCell *)[self.collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForItem:[self.modelArray indexOfObject:nextModel] inSection:0]];
            if (!nextCell.bottomSliderView.hidden || nextCell.bottomSliderView.alpha < 1) {
                nextCell.bottomSliderView.alpha = 1;
                nextCell.bottomSliderView.hidden = NO;
            }
        }
    }
}
- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    if (self.modelArray.count > 0) {
        HXPhotoPreviewViewCell *cell = (HXPhotoPreviewViewCell *)[self.collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForItem:self.currentModelIndex inSection:0]];
        HXPhotoModel *model = self.modelArray[self.currentModelIndex];
        model.previewContentOffsetX = scrollView.contentOffset.x;
        if (self.exteriorPreviewStyle == HXPhotoViewPreViewShowStyleDark &&
            self.previewShowDeleteButton) {
            if (model.subType == HXPhotoModelMediaSubTypePhoto) {
                self.darkDeleteView.alpha = 1;
            }else if (model.subType == HXPhotoModelMediaSubTypeVideo) {
                if (model != self.currentModel) {
                    self.darkDeleteView.alpha = 1;
                }
            }
            if (self.darkDeleteView.alpha == 0.005f) {
                self.darkDeleteView.hidden = YES;
            }else {
                self.darkDeleteView.hidden = NO;
            }
        }
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
    if (self.manager.configuration.singleSelected &&
        self.manager.configuration.singleJumpEdit) {
        self.singleSelectedJumpEdit = YES;
    }
    HXPhotoModel *model = [self.modelArray objectAtIndex:self.currentModelIndex];
    if (model.type == HXPhotoModelMediaTypePhotoGif ||
        model.cameraPhotoType == HXPhotoModelMediaTypeCameraPhotoTypeNetWorkGif ||
        model.cameraPhotoType == HXPhotoModelMediaTypeCameraPhotoTypeLocalGif) {
        if (model.photoEdit) {
            [self jumpEditViewControllerWithModel:model];
        }else {
            HXWeakSelf
            hx_showAlert(self, [NSBundle hx_localizedStringForKey:@"编辑后，GIF将会变为静态图，确定继续吗？"], nil, [NSBundle hx_localizedStringForKey:@"取消"], [NSBundle hx_localizedStringForKey:@"确定"], nil, ^{
                [weakSelf jumpEditViewControllerWithModel:model];
            });
        }
        return;
    }else if (model.type == HXPhotoModelMediaTypeLivePhoto) {
        if (model.photoEdit) {
            [self jumpEditViewControllerWithModel:model];
        }else {
            HXWeakSelf
            hx_showAlert(self, [NSBundle hx_localizedStringForKey:@"编辑后，LivePhoto将会变为静态图，确定继续吗？"], nil, [NSBundle hx_localizedStringForKey:@"取消"], [NSBundle hx_localizedStringForKey:@"确定"], nil, ^{
                [weakSelf jumpEditViewControllerWithModel:model];
            });
        }
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
            if (self.manager.configuration.useWxPhotoEdit) {
                HX_PhotoEditViewController *vc = [[HX_PhotoEditViewController alloc] initWithConfiguration:self.manager.configuration.photoEditConfigur];
                vc.photoModel = [self.modelArray objectAtIndex:self.currentModelIndex];
                vc.delegate = self;
                vc.supportRotation = YES;
                vc.modalPresentationStyle = UIModalPresentationOverFullScreen;
                vc.modalPresentationCapturesStatusBarAppearance = YES;
                [self presentViewController:vc animated:YES completion:nil];
            }else {
                HXPhotoEditViewController *vc = [[HXPhotoEditViewController alloc] init];
                vc.isInside = YES;
                vc.model = [self.modelArray objectAtIndex:self.currentModelIndex];
                vc.delegate = self;
                vc.manager = self.manager;
                vc.outside = self.outside;
                vc.modalPresentationStyle = UIModalPresentationOverFullScreen;
                vc.modalPresentationCapturesStatusBarAppearance = YES;
                [self presentViewController:vc animated:YES completion:nil];
            }
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
            [self jumpVideoEdit];
        }
    }
}
- (void)jumpVideoEdit {
    HXPhotoPreviewVideoViewCell *cell = (HXPhotoPreviewVideoViewCell *)[self.collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForItem:self.currentModelIndex inSection:0]];
    HXVideoEditViewController *vc = [[HXVideoEditViewController alloc] init];
    vc.model = [self.modelArray objectAtIndex:self.currentModelIndex];
    vc.avAsset = cell.previewContentView.avAsset;
    vc.delegate = self;
    vc.manager = self.manager;
    vc.isInside = YES;
    vc.outside = self.outside;
    vc.modalPresentationStyle = UIModalPresentationOverFullScreen;
    vc.modalPresentationCapturesStatusBarAppearance = YES;
    [self presentViewController:vc animated:YES completion:nil];
}
- (void)photoPreviewBottomViewDidDone:(HXPhotoPreviewBottomView *)bottomView {
    if (self.outside) {
        if ([self.delegate respondsToSelector:@selector(photoPreviewControllerDidCancel:model:)]) {
            HXPhotoModel *model;
            if (self.modelArray.count) {
                model = self.modelArray[self.currentModelIndex];
            }
            [self.delegate photoPreviewControllerDidCancel:self model:model];
        }
        self.manager.selectPhotoing = NO;
        BOOL selectPhotoFinishDismissAnimated = self.manager.selectPhotoFinishDismissAnimated;
        [self dismissViewControllerAnimated:selectPhotoFinishDismissAnimated completion:^{
            if ([self.delegate respondsToSelector:@selector(photoPreviewControllerFinishDismissCompletion:)]) {
                [self.delegate photoPreviewControllerFinishDismissCompletion:self];
            }
        }];
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
            if (round(model.videoDuration) >= self.manager.configuration.videoMaximumSelectDuration + 1) {
                if (self.manager.configuration.selectVideoBeyondTheLimitTimeAutoEdit &&
                    self.manager.configuration.videoCanEdit) {
                    self.singleSelectedJumpEdit = YES;
                    [self jumpVideoEdit];
                }else {
                    [self.view hx_showImageHUDText:[NSString stringWithFormat:[NSBundle hx_localizedStringForKey:@"视频大于%ld秒，无法选择"], self.manager.configuration.videoMaximumSelectDuration]];
                }
                return;
            }else if (round(model.videoDuration) < self.manager.configuration.videoMinimumSelectDuration) {
                [self.view hx_showImageHUDText:[NSString stringWithFormat:[NSBundle hx_localizedStringForKey:@"视频少于%ld秒，无法选择"], self.manager.configuration.videoMinimumSelectDuration]];
                return;
            }
        }else if (model.subType == HXPhotoModelMediaSubTypePhoto) {
            if (self.manager.configuration.useWxPhotoEdit) {
                if (self.manager.configuration.singleJumpEdit) {
                    self.singleSelectedJumpEdit = YES;
                    [self jumpEditViewControllerWithModel:model];
                    return;
                }
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
        NSString *str = [self.manager maximumOfJudgment:model];
        if (str) {
            if ([str isEqualToString:@"selectVideoBeyondTheLimitTimeAutoEdit"]) {
                [self jumpVideoEdit];
            }else {
                [self.view hx_showImageHUDText:str];
            }
            return;
        }
        if (!self.selectBtn.selected && !max && self.modelArray.count > 0) {
            //            model.selected = YES;
            HXPhotoPreviewViewCell *cell = (HXPhotoPreviewViewCell *)[self.collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForItem:self.currentModelIndex inSection:0]];
            model.thumbPhoto = cell.image;
            model.previewPhoto = cell.image;
            [self.manager beforeSelectedListAddPhotoModel:model];
        }
    }
    if ([self.delegate respondsToSelector:@selector(photoPreviewControllerDidDone:)]) {
        [self.delegate photoPreviewControllerDidDone:self];
    }
}
#pragma mark - < HX_PhotoEditViewControllerDelegate >
- (void)photoEditingController:(HX_PhotoEditViewController *)photoEditingVC didFinishPhotoEdit:(HXPhotoEdit *)photoEdit photoModel:(nonnull HXPhotoModel *)photoModel {
    if (self.singleSelectedJumpEdit) {
        if ([self.delegate respondsToSelector:@selector(photoPreviewSingleSelectedClick:model:)]) {
            [self.delegate photoPreviewSingleSelectedClick:self model:photoModel];
        }
        return;
    }
    [self.collectionView reloadData];
    if (self.outside) {
        [self.bottomView reloadData];
        if ([self.delegate respondsToSelector:@selector(photoPreviewSelectLaterDidEditClick:beforeModel:afterModel:)]) {
            [self.delegate photoPreviewSelectLaterDidEditClick:self beforeModel:photoModel afterModel:photoModel];
        }
    }else {
        if (!photoModel.selected && !self.manager.configuration.singleSelected) {
            NSString *str = [self.manager maximumOfJudgment:photoModel];
            if (!str) {
                [self.manager beforeSelectedListAddPhotoModel:photoModel];
                self.selectBtn.selected = YES;
                [self.selectBtn setTitle:photoModel.selectIndexStr forState:UIControlStateSelected];
                CGFloat selectTextWidth = [self.selectBtn.titleLabel hx_getTextWidth];
                if (selectTextWidth + 10 > 24 && self.selectBtn.selected) {
                    self.selectBtn.hx_w = selectTextWidth + 10;
                }else {
                    self.selectBtn.hx_w = 24;
                }
                UIColor *btnBgColor = self.manager.configuration.previewSelectedBtnBgColor ?: self.manager.configuration.themeColor;
                UIColor *themeColor = [HXPhotoCommon photoCommon].isDark ? [UIColor whiteColor] : btnBgColor;
                self.selectBtn.backgroundColor = themeColor;
                if ([self.delegate respondsToSelector:@selector(photoPreviewControllerDidSelect:model:)]) {
                    [self.delegate photoPreviewControllerDidSelect:self model:photoModel];
                }
                self.bottomView.selectCount = [self.manager selectedCount];
                [self.bottomView insertModel:photoModel];
            }
        }else {
            [self.bottomView reloadData];
        }
        if ([self.delegate respondsToSelector:@selector(photoPreviewDidEditClick:model:beforeModel:)]) {
            [self.delegate photoPreviewDidEditClick:self model:photoModel beforeModel:photoModel];
        }
    }
}
- (void)photoEditingControllerDidCancel:(HX_PhotoEditViewController *)photoEditingVC {
    self.singleSelectedJumpEdit = NO;
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
    }else {
        if (afterModel.subType == HXPhotoModelMediaSubTypeVideo) {
            if (self.manager.configuration.singleSelected) {
                if ([self.delegate respondsToSelector:@selector(photoPreviewSingleSelectedClick:model:)]) {
                    [self.delegate photoPreviewSingleSelectedClick:self model:afterModel];
                }
                return;
            }else if (beforeModel.needHideSelectBtn) {
                [self.manager beforeSelectedListAddPhotoModel:afterModel];
                if ([self.delegate respondsToSelector:@selector(photoPreviewControllerDidDone:)]) {
                    [self.delegate photoPreviewControllerDidDone:self];
                }
                return;
            }
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
    if (self.singleSelectedJumpEdit) {
        if ([self.delegate respondsToSelector:@selector(photoPreviewSingleSelectedClick:model:)]) {
            [self.delegate photoPreviewSingleSelectedClick:self model:afterModel];
        }
        return;
    }
    [self photoEditViewControllerDidClipClick:nil beforeModel:beforeModel afterModel:afterModel];
}
- (void)videoEditViewControllerDidCancelClick:(HXVideoEditViewController *)videoEditViewController {
    self.singleSelectedJumpEdit = NO;
}
#pragma mark - < 懒加载 >
- (UIPageControl *)bottomPageControl {
    if (!self.showBottomPageControl) {
        return nil;
    }
    if (!_bottomPageControl) {
        _bottomPageControl = [[UIPageControl alloc] init];
        _bottomPageControl.currentPageIndicatorTintColor = [UIColor whiteColor];
        _bottomPageControl.pageIndicatorTintColor = [[UIColor whiteColor] colorWithAlphaComponent:0.5f];
        _bottomPageControl.numberOfPages = self.modelArray.count;
        _bottomPageControl.enabled = NO;
        _bottomPageControl.hidesForSinglePage = YES;
#ifdef __IPHONE_14_0
        if (@available(iOS 14, *)) {
            _bottomPageControl.backgroundStyle = UIPageControlBackgroundStyleProminent;
            _bottomPageControl.allowsContinuousInteraction = NO;
        }
#endif
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
- (UIVisualEffectView *)creatBlurEffectView {
    UIBlurEffect *effect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleDark];
    UIVisualEffectView *effectView = [[UIVisualEffectView alloc] initWithEffect:effect];
    effectView.frame = CGRectMake(0, 0, HXDARKVIEWWIDTH, HXDARKVIEWWIDTH);
    effectView.layer.masksToBounds = YES;
    effectView.layer.cornerRadius = HXDARKVIEWWIDTH / 2.f;
    return effectView;
}
- (UIView *)darkDeleteView {
    if (!_darkDeleteView) {
        _darkDeleteView = [[UIView alloc] init];
        UIVisualEffectView *effectView = [self creatBlurEffectView];
        [_darkDeleteView addSubview:effectView];
        [_darkDeleteView addSubview:self.darkDeleteBtn];
        _darkDeleteView.alpha = 0;
        _darkDeleteView.hidden = YES;
    }
    return _darkDeleteView;
}
- (UIView *)darkCancelView {
    if (!_darkCancelView) {
        _darkCancelView = [[UIView alloc] init];
        UIVisualEffectView *effectView = [self creatBlurEffectView];
        [_darkCancelView addSubview:effectView];
        [_darkCancelView addSubview:self.darkCancelBtn];
    }
    return _darkCancelView;
}
- (UIButton *)darkCancelBtn {
    if (!_darkCancelBtn) {
        _darkCancelBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [_darkCancelBtn setImage:[UIImage hx_imageNamed:@"hx_preview_dark_close"] forState:UIControlStateNormal];
        [_darkCancelBtn addTarget:self action:@selector(cancelDismissClick) forControlEvents:UIControlEventTouchUpInside];
        _darkCancelBtn.frame = CGRectMake(0, 0, HXDARKVIEWWIDTH, HXDARKVIEWWIDTH);
    }
    return _darkCancelBtn;
}
- (UIButton *)darkDeleteBtn {
    if (!_darkDeleteBtn) {
        _darkDeleteBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [_darkDeleteBtn setImage:[UIImage hx_imageNamed:@"hx_preview_dark_delete"] forState:UIControlStateNormal];
        [_darkDeleteBtn addTarget:self action:@selector(deleteClick) forControlEvents:UIControlEventTouchUpInside];
        _darkDeleteBtn.frame = CGRectMake(0, 0, HXDARKVIEWWIDTH, HXDARKVIEWWIDTH);
    }
    return _darkDeleteBtn;
}
- (HXPhotoCustomNavigationBar *)navBar {
    if (!_navBar) {
        CGFloat width = [UIScreen mainScreen].bounds.size.width;
        _navBar = [[HXPhotoCustomNavigationBar alloc] initWithFrame:CGRectMake(0, 0, width, hxNavigationBarHeight)];
        _navBar.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        [_navBar pushNavigationItem:self.navItem animated:NO];
    }
    return _navBar;
}
- (UINavigationItem *)navItem {
    if (!_navItem) {
        _navItem = [[UINavigationItem alloc] init];
        if (self.previewShowDeleteButton) {
            _navItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:[NSBundle hx_localizedStringForKey:@"取消"] style:UIBarButtonItemStylePlain target:self action:@selector(cancelDismissClick)];
            _navItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:[NSBundle hx_localizedStringForKey:@"删除"] style:UIBarButtonItemStylePlain target:self action:@selector(deleteClick)];
        }else {
            _navItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:[NSBundle hx_localizedStringForKey:@"取消"] style:UIBarButtonItemStylePlain target:self action:@selector(cancelDismissClick)];
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
        _selectBtn.titleLabel.font = [UIFont hx_mediumPingFangOfSize:16];;
        [_selectBtn addTarget:self action:@selector(didSelectClick:) forControlEvents:UIControlEventTouchUpInside];
        _selectBtn.hx_size = CGSizeMake(24, 24);
        [_selectBtn hx_setEnlargeEdgeWithTop:0 right:0 bottom:20 left:20];
        _selectBtn.layer.cornerRadius = 12;
    }
    return _selectBtn;
}
- (UICollectionView *)collectionView {
    if (!_collectionView) {
        _collectionView = [[UICollectionView alloc] initWithFrame:CGRectMake(-10, 0,self.view.hx_w + 20, [UIScreen mainScreen].bounds.size.height) collectionViewLayout:self.flowLayout];
        _collectionView.dataSource = self;
        _collectionView.delegate = self;
        _collectionView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        _collectionView.pagingEnabled = YES;
        _collectionView.showsVerticalScrollIndicator = NO;
        _collectionView.showsHorizontalScrollIndicator = NO;
        
        [_collectionView registerClass:[HXPhotoPreviewImageViewCell class] forCellWithReuseIdentifier:@"HXPhotoPreviewImageViewCell"];
        [_collectionView registerClass:[HXPhotoPreviewLivePhotoCell class] forCellWithReuseIdentifier:@"HXPhotoPreviewLivePhotoCell"];
        [_collectionView registerClass:[HXPhotoPreviewVideoViewCell class] forCellWithReuseIdentifier:@"HXPhotoPreviewVideoViewCell"];
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
            
