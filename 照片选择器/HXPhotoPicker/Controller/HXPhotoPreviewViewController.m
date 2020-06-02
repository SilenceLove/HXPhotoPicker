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
@property (assign, nonatomic) BOOL firstChangeFrame;
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
- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
    [super traitCollectionDidChange:previousTraitCollection];
#ifdef __IPHONE_13_0
    if (@available(iOS 13.0, *)) {
        if ([self.traitCollection hasDifferentColorAppearanceComparedToTraitCollection:previousTraitCollection]) {
            [self changeColor];
            [self changeStatusBarStyle];
            [self setNeedsStatusBarAppearanceUpdate];
            [self.collectionView reloadData];
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
        [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationFade];
    }
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidChangeStatusBarOrientationNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillChangeStatusBarOrientationNotification object:nil];
    if (HXShowLog) NSSLog(@"dealloc");
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
- (void)changeStatusBarStyle {
    if ([HXPhotoCommon photoCommon].isDark) {
        [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent];
        return;
    }
    [[UIApplication sharedApplication] setStatusBarStyle:self.manager.configuration.statusBarStyle];
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
    [super viewWillDisappear:animated];
    if (self.exteriorPreviewStyle == HXPhotoViewPreViewShowStyleDark) {
        if ([UIApplication sharedApplication].statusBarHidden) {
            [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationFade];
        }
        [self changeStatusBarWithHidden:NO];
    }
    HXPhotoPreviewViewCell *cell = (HXPhotoPreviewViewCell *)[self.collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForItem:self.currentModelIndex inSection:0]];
    cell.stopCancel = self.stopCancel;
    [cell cancelRequest];
    self.stopCancel = NO;
}
- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view
    self.extendedLayoutIncludesOpaqueBars = YES;
    self.edgesForExtendedLayout = UIRectEdgeAll;
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
    if (orientation == UIInterfaceOrientationPortrait || orientation == UIInterfaceOrientationPortraitUpsideDown) {
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
    if (self.orientationDidChange) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
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
            CGFloat topMargin = HX_IS_IPhoneX_All ? 45 : 30;
//            if (self.previewShowDeleteButton) {
//                self.darkDeleteBtn.frame = CGRectMake(self.view.hx_w - 100 - 15, topMargin, 100, 30);
//            }
            self.darkCancelBtn.frame = CGRectMake(15, topMargin, 35, 35);
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
//        selectedTitleColor = [UIColor blackColor];
        selectBtnBgColor = self.manager.configuration.previewDarkSelectBgColor;
        selectBtnTitleColor = self.manager.configuration.previewDarkSelectTitleColor;
    }else {
        backgroundColor = (_bottomView && _bottomView.alpha == 0) ? [UIColor blackColor] : [UIColor whiteColor];
        themeColor = self.manager.configuration.themeColor;
        navBarBackgroudColor = self.manager.configuration.navBarBackgroudColor;
        navigationTitleColor = self.manager.configuration.navigationTitleColor;
        selectedTitleColor = self.manager.configuration.selectedTitleColor;
        selectBtnTitleColor = selectedTitleColor;
        selectBtnBgColor = themeColor;
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
            
            [self.view addSubview:self.darkCancelBtn];
//            if (self.previewShowDeleteButton) {
//                [self.view addSubview:self.darkDeleteBtn];
//            }
            if ([self.manager.afterSelectedArray containsObject:model]) {
                self.bottomPageControl.currentPage = [[self.manager afterSelectedArray] indexOfObject:model];
            }
            if (self.manager.afterSelectedCount <= 15) {
                [self.view addSubview:self.bottomPageControl];
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
    UIColor *themeColor = [HXPhotoCommon photoCommon].isDark ? [UIColor whiteColor] : self.manager.configuration.themeColor;
    button.backgroundColor = button.selected ? themeColor : nil;
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
    if ([self.delegate respondsToSelector:@selector(photoPreviewControllerDidCancel:model:)]) {
        HXPhotoModel *model;
        if (self.modelArray.count) {
            model = self.modelArray[self.currentModelIndex];
        }
        [self.delegate photoPreviewControllerDidCancel:self model:model];
    }
    [self dismissViewControllerAnimated:YES completion:nil];
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
    UIColor *bgColor = [HXPhotoCommon photoCommon].isDark ? [UIColor blackColor] : [UIColor whiteColor];
    if (animete) {
        [[UIApplication sharedApplication] setStatusBarHidden:hide withAnimation:UIStatusBarAnimationFade];
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
        [[UIApplication sharedApplication] setStatusBarHidden:hide];
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
    HXPhotoModel *model = self.modelArray[indexPath.item];
    HXPhotoPreviewViewCell *cell;
    HXWeakSelf
    if (model.subType == HXPhotoModelMediaSubTypePhoto) {
        if (model.type == HXPhotoModelMediaTypeLivePhoto) {
            cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"HXPhotoPreviewLivePhotoCell" forIndexPath:indexPath];
        }else {
            if (model.type == HXPhotoModelMediaTypeCameraPhoto &&
                model.cameraPhotoType == HXPhotoModelMediaTypeCameraPhotoTypeLocalLivePhoto) {
                    cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"HXPhotoPreviewLivePhotoCell" forIndexPath:indexPath];
            }else {
                cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"HXPhotoPreviewImageViewCell" forIndexPath:indexPath];
            }
        }
    }else if (model.subType == HXPhotoModelMediaSubTypeVideo) {
        cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"HXPhotoPreviewVideoViewCell" forIndexPath:indexPath];
    }
    cell.cellViewLongPressGestureRecognizerBlock = ^(UILongPressGestureRecognizer * _Nonnull longPress) {
        [weakSelf respondsToLongPress:longPress];
    };
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
            self.darkCancelBtn.hidden = hidden;
            self.darkDeleteBtn.hidden = hidden;
        }
        [UIView animateWithDuration:0.25 animations:^{
            if (cell.previewContentView.videoView.playBtnDidPlay) {
                cell.bottomSliderView.alpha = !hidden;
            }
            self.darkCancelBtn.alpha = !hidden;
            self.darkDeleteBtn.alpha = !hidden;
        } completion:^(BOOL finished) {
            if (cell.previewContentView.videoView.playBtnDidPlay) {
                cell.bottomSliderView.hidden = hidden;
            }
            self.darkCancelBtn.hidden = hidden;
            self.darkDeleteBtn.hidden = hidden;
        }];
    }else {
        self.darkCancelBtn.alpha = !hidden;
        self.darkCancelBtn.hidden = hidden;
        self.darkDeleteBtn.alpha = !hidden;
        self.darkDeleteBtn.hidden = hidden;
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
- (void)scrollDidScrollHiddenBottomSliderViewWithOffsetX:(CGFloat)offsetx nextModel:(HXPhotoModel *)nextModel {
    if (self.currentModel.subType == HXPhotoModelMediaSubTypeVideo &&
        self.exteriorPreviewStyle == HXPhotoViewPreViewShowStyleDark) {
            HXPhotoPreviewVideoViewCell *cell = (HXPhotoPreviewVideoViewCell *)[self.collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForItem:[self.modelArray indexOfObject:self.currentModel] inSection:0]];
        if (self.darkCancelBtn.hidden) {
            return;
        }
        float difference = fabs(offsetx - self.currentModel.previewContentOffsetX);
        CGFloat width = [UIScreen mainScreen].bounds.size.width;
        if (difference > width) {
            difference = width;
        }
        self.darkCancelBtn.alpha = 1 - (difference / width);
        cell.bottomSliderView.alpha = self.darkCancelBtn.alpha;
    }
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
        if (orientation == UIInterfaceOrientationPortrait || orientation == UIInterfaceOrientationPortraitUpsideDown) {
            self.titleLb.text = model.barTitle;
            self.subTitleLb.text = model.barSubTitle;
        }else if (orientation == UIInterfaceOrientationLandscapeRight || orientation == UIInterfaceOrientationLandscapeLeft){
            self.subTitleLb.text = [NSString stringWithFormat:@"%@  %@",model.barTitle,model.barSubTitle];
        }
        self.selectBtn.selected = model.selected;
        [self.selectBtn setTitle:model.selectIndexStr forState:UIControlStateSelected];
        
        UIColor *themeColor = [HXPhotoCommon photoCommon].isDark ? self.manager.configuration.previewDarkSelectBgColor : self.manager.configuration.themeColor;
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
    if (currentIndex > 0 && currentIndex < self.modelArray.count) {
        HXPhotoModel *nextModel;
        if (self.currentModel.previewContentOffsetX > offsetx) {
            NSInteger index = [self.modelArray indexOfObject:self.currentModel] - 1;
            if (index > 0 && index < self.modelArray.count) {
                nextModel = self.modelArray[index];
            }
        }else {
            NSInteger index = [self.modelArray indexOfObject:self.currentModel] + 1;
            if (index > 0 && index < self.modelArray.count) {
                nextModel = self.modelArray[index];
            }
        }
        if (nextModel && !self.orientationDidChange) {
            [self scrollDidScrollHiddenBottomSliderViewWithOffsetX:offsetx nextModel:nextModel];
        }
    }
}
- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    if (self.modelArray.count > 0) {
        HXPhotoPreviewViewCell *cell = (HXPhotoPreviewViewCell *)[self.collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForItem:self.currentModelIndex inSection:0]];
        HXPhotoModel *model = self.modelArray[self.currentModelIndex];
        model.previewContentOffsetX = scrollView.contentOffset.x;
        if (self.currentModel != model) {
            self.darkCancelBtn.alpha = 0;
            self.darkCancelBtn.hidden = YES;
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
            vc.modalPresentationCapturesStatusBarAppearance = YES;
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
            if (model.videoDuration >= self.manager.configuration.videoMaximumSelectDuration + 1) {
                [self.view hx_showImageHUDText:[NSString stringWithFormat:[NSBundle hx_localizedStringForKey:@"视频大于%ld秒，无法选择"], self.manager.configuration.videoMaximumSelectDuration]];
                return;
            }else if (model.videoDuration < self.manager.configuration.videoMinimumSelectDuration) {
                if (self.manager.configuration.selectVideoBeyondTheLimitTimeAutoEdit &&
                    self.manager.configuration.videoCanEdit) {
                    [self jumpVideoEdit];
                }else {
                    [self.view hx_showImageHUDText:[NSString stringWithFormat:[NSBundle hx_localizedStringForKey:@"视频少于%ld秒，无法选择"], self.manager.configuration.videoMinimumSelectDuration]];
                }
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
        _darkCancelBtn.alpha = 0;
        _darkCancelBtn.hidden = YES;
        _darkCancelBtn.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
        _darkCancelBtn.contentVerticalAlignment = UIControlContentVerticalAlignmentTop;
        [_darkCancelBtn addTarget:self action:@selector(dismissClick) forControlEvents:UIControlEventTouchUpInside];
    }
    return _darkCancelBtn;
}
- (UIButton *)darkDeleteBtn {
    if (!_darkDeleteBtn) {
        _darkDeleteBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        _darkDeleteBtn.alpha = 0;
        _darkDeleteBtn.hidden = YES;
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
    }
    return _navBar;
}
- (UINavigationItem *)navItem {
    if (!_navItem) {
        _navItem = [[UINavigationItem alloc] init];
//        if (self.previewShowDeleteButton) {
//            _navItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:[NSBundle hx_localizedStringForKey:@"返回"] style:UIBarButtonItemStylePlain target:self action:@selector(dismissClick)];
//            _navItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:[NSBundle hx_localizedStringForKey:@"删除"] style:UIBarButtonItemStylePlain target:self action:@selector(deleteClick)];
//        }else {
            _navItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:[NSBundle hx_localizedStringForKey:@"取消"] style:UIBarButtonItemStylePlain target:self action:@selector(dismissClick)];
//        }
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
        _selectBtn.titleLabel.font = [UIFont systemFontOfSize:14];
        _selectBtn.adjustsImageWhenDisabled = YES;
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
            
