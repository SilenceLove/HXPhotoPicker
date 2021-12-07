//
//  HXPhotoViewController.m
//  HXPhotoPickerExample
//
//  Created by Silence on 2017/10/14.
//  Copyright © 2017年 Silence. All rights reserved.
//

#import "HXPhotoViewController.h"
#import "UIImage+HXExtension.h"
#import "HXPhoto3DTouchViewController.h"
#import "HXPhotoPreviewViewController.h"
#import "UIButton+HXExtension.h" 
#import "HXCustomCameraViewController.h"
#import "HXCustomNavigationController.h"
#import "HXCustomCameraController.h"
#import "HXCustomPreviewView.h"
#import "HXPhotoEditViewController.h"
#import "HXPhotoViewFlowLayout.h"
#import "HXCircleProgressView.h"
#import "UIViewController+HXExtension.h"

#import "UIImageView+HXExtension.h"

#if __has_include(<SDWebImage/UIImageView+WebCache.h>)
#import <SDWebImage/UIImageView+WebCache.h>
#elif __has_include("UIImageView+WebCache.h")
#import "UIImageView+WebCache.h"
#endif

#import "HXAlbumlistView.h" 
#import "NSArray+HXExtension.h"
#import "HXVideoEditViewController.h"
#import "HXPhotoEdit.h"
#import "HX_PhotoEditViewController.h"
#import "UIColor+HXExtension.h"
#import "HXAssetManager.h"

@interface HXPhotoViewController ()
<
UICollectionViewDataSource,
UICollectionViewDelegate,
UICollectionViewDelegateFlowLayout,
UIViewControllerPreviewingDelegate,
HXPhotoViewCellDelegate,
HXPhotoBottomViewDelegate,
HXPhotoPreviewViewControllerDelegate,
HXCustomCameraViewControllerDelegate,
HXPhotoEditViewControllerDelegate,
HXVideoEditViewControllerDelegate,
HX_PhotoEditViewControllerDelegate
//PHPhotoLibraryChangeObserver
>
@property (strong, nonatomic) UICollectionViewFlowLayout *flowLayout;
@property (strong, nonatomic) UICollectionView *collectionView;

@property (strong, nonatomic) NSMutableArray *allArray;
@property (assign, nonatomic) NSInteger photoCount;
@property (assign, nonatomic) NSInteger videoCount;
@property (strong, nonatomic) NSMutableArray *previewArray;
@property (strong, nonatomic) NSMutableArray *dateArray;

@property (weak, nonatomic) id<UIViewControllerPreviewing> previewingContext;

@property (assign, nonatomic) BOOL orientationDidChange;
@property (assign, nonatomic) BOOL needChangeViewFrame;
@property (strong, nonatomic) NSIndexPath *beforeOrientationIndexPath;

@property (weak, nonatomic) HXPhotoViewSectionFooterView *footerView;
@property (assign, nonatomic) BOOL showBottomPhotoCount;

@property (strong, nonatomic) HXAlbumTitleView *albumTitleView;
@property (strong, nonatomic) HXAlbumlistView *albumView;
@property (strong, nonatomic) UIView *albumBgView;
@property (strong, nonatomic) UILabel *authorizationLb;

@property (assign, nonatomic) BOOL firstDidAlbumTitleView;

@property (assign, nonatomic) BOOL collectionViewReloadCompletion;

@property (weak, nonatomic) HXPhotoCameraViewCell *cameraCell;

@property (assign, nonatomic) BOOL cellCanSetModel;
@property (copy, nonatomic) NSArray *collectionVisibleCells;
@property (assign, nonatomic) BOOL isNewEditDismiss;

@property (assign, nonatomic) BOOL firstOn;
@property (assign, nonatomic) BOOL assetDidChanged;

@property (assign, nonatomic) CGPoint panSelectStartPoint;
@property (strong, nonatomic) NSMutableArray *panSelectIndexPaths;
@property (assign, nonatomic) NSInteger currentPanSelectType;
@property (strong, nonatomic) HXHUD *imagePromptView;
@end

@implementation HXPhotoViewController
#pragma mark - < life cycle >
- (void)dealloc {
    if (_collectionView) {
        [self.collectionView.layer removeAllAnimations];
    }
    if (self.manager.configuration.open3DTouchPreview) {
        if (self.previewingContext) {
            if (@available(iOS 9.0, *)) {
                [self unregisterForPreviewingWithContext:self.previewingContext];
            }
        }
    }
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidChangeStatusBarOrientationNotification object:nil];
}
- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
    [super traitCollectionDidChange:previousTraitCollection];
#ifdef __IPHONE_13_0
    if (@available(iOS 13.0, *)) {
        if ([self.traitCollection hasDifferentColorAppearanceComparedToTraitCollection:previousTraitCollection]) {
            [self changeColor];
            [self changeStatusBarStyle];
            [self setNeedsStatusBarAppearanceUpdate];
            UIColor *authorizationColor = self.manager.configuration.authorizationTipColor;
            _authorizationLb.textColor = [HXPhotoCommon photoCommon].isDark ? [UIColor whiteColor] : authorizationColor;
        }
    }
#endif
}
- (UIStatusBarStyle)preferredStatusBarStyle {
    if ([HXPhotoCommon photoCommon].isDark) {
        return UIStatusBarStyleLightContent;
    }
    return self.manager.configuration.statusBarStyle;
}
- (BOOL)prefersStatusBarHidden {
    return NO;
}
- (UIStatusBarAnimation)preferredStatusBarUpdateAnimation {
    return UIStatusBarAnimationFade;
}
- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self changeStatusBarStyle];
#pragma clang diagnostic push
#pragma clang diagnostic ignored"-Wdeprecated-declarations"
    [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationFade];
#pragma clang diagnostic pop
    if (self.needChangeViewFrame) {
        self.needChangeViewFrame = NO;
    }
    if (self.manager.viewWillAppear) {
        self.manager.viewWillAppear(self);
    }
}
- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if (self.manager.configuration.cameraCellShowPreview) {
        if (!self.cameraCell.startSession) {
            [self.cameraCell starRunning];
        }
    }
    if (self.manager.viewDidAppear) {
        self.manager.viewDidAppear(self);
    }
}
- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
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
#pragma clang diagnostic push
#pragma clang diagnostic ignored"-Wdeprecated-declarations"
- (void)changeStatusBarStyle {
    if ([HXPhotoCommon photoCommon].isDark) {
        [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent animated:YES];
        return;
    }
    [[UIApplication sharedApplication] setStatusBarStyle:self.manager.configuration.statusBarStyle animated:YES];
}
#pragma clang diagnostic pop
- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    if (self.orientationDidChange) {
        [self changeSubviewFrame];
        self.orientationDidChange = NO;
    }
}
- (void)viewDidLoad {
    [super viewDidLoad];
    self.assetDidChanged = NO;
    self.firstOn = YES;
    self.cellCanSetModel = YES;
    self.extendedLayoutIncludesOpaqueBars = YES;
    self.edgesForExtendedLayout = UIRectEdgeAll;
    if (self.manager.configuration.showBottomPhotoDetail) {
        self.showBottomPhotoCount = YES;
        self.manager.configuration.showBottomPhotoDetail = NO;
    }
    [self setupUI];
    [self changeSubviewFrame];
    if (self.manager.configuration.albumShowMode == HXPhotoAlbumShowModeDefault) {
        [self getPhotoList];
    }else if (self.manager.configuration.albumShowMode == HXPhotoAlbumShowModePopup) {
        [self authorizationHandler];
        HXWeakSelf
        self.hx_customNavigationController.reloadAsset = ^(BOOL initialAuthorization){
            if (initialAuthorization == YES) {
                if (weakSelf.manager.configuration.navigationBar) {
                    weakSelf.manager.configuration.navigationBar(weakSelf.navigationController.navigationBar, weakSelf);
                }
                [weakSelf authorizationHandler];
            }else {
                if (weakSelf.albumTitleView.selected) {
                    [weakSelf.albumTitleView deSelect];
                }
                [weakSelf.hx_customNavigationController.view hx_showLoadingHUDText:nil];
                weakSelf.collectionViewReloadCompletion = NO;
                weakSelf.albumTitleView.canSelect = YES;
                [weakSelf getAlbumList];
            }
        };
    }
    [self setupOtherConfiguration];
}
- (void)authorizationHandler {
    PHAuthorizationStatus status = [HXPhotoTools authorizationStatus];
    if (status == PHAuthorizationStatusAuthorized) {
        [self getAlbumList];
    }
#ifdef __IPHONE_14_0
    else if (@available(iOS 14, *)) {
        if (status == PHAuthorizationStatusLimited) {
            [self getAlbumList];
            return;
        }
#endif
    else if (status == PHAuthorizationStatusDenied ||
             status == PHAuthorizationStatusRestricted) {
        [self.hx_customNavigationController.view hx_handleLoading:NO];
        [self.view addSubview:self.authorizationLb];
        [HXPhotoTools showNoAuthorizedAlertWithViewController:self status:status];
    }
#ifdef __IPHONE_14_0
    }else if (status == PHAuthorizationStatusDenied ||
              status == PHAuthorizationStatusRestricted) {
         [self.hx_customNavigationController.view hx_handleLoading:NO];
         [self.view addSubview:self.authorizationLb];
         [HXPhotoTools showNoAuthorizedAlertWithViewController:self status:status];
     }
#endif
}
- (void)setupOtherConfiguration {
    if (self.manager.configuration.open3DTouchPreview) {
//#ifdef __IPHONE_13_0
//        if (@available(iOS 13.0, *)) {
//            [HXPhotoCommon photoCommon].isHapticTouch = YES;
//#else
//        if ((NO)) {
//#endif
//        }else {
            if ([self respondsToSelector:@selector(traitCollection)]) {
                if ([self.traitCollection respondsToSelector:@selector(forceTouchCapability)]) {
                    if (self.traitCollection.forceTouchCapability == UIForceTouchCapabilityAvailable) {
                        HXWeakSelf
                        self.previewingContext = [self registerForPreviewingWithDelegate:weakSelf sourceView:weakSelf.collectionView];
                    }
                }
            }
//        }
    }
    if (!self.manager.configuration.singleSelected && self.manager.configuration.allowSlidingSelection) {
        UIPanGestureRecognizer *selectPanGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(selectPanGestureRecognizerClick:)];
        [self.view addGestureRecognizer:selectPanGesture];
    }
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(deviceOrientationChanged:) name:UIApplicationDidChangeStatusBarOrientationNotification object:nil];
}
#pragma mark - < private >
- (void)setupUI {
    [self.view addSubview:self.collectionView];
    if ([HXPhotoTools authorizationStatusIsLimited]) {
        [self.view addSubview:self.limitView];
    }
    if (!self.manager.configuration.singleSelected) {
        [self.view addSubview:self.bottomView];
    }
    [self setupNav];
    [self changeColor];
}
- (void)setupNav {
    UIBarButtonItem *cancelItem = [[UIBarButtonItem alloc] initWithTitle:[NSBundle hx_localizedStringForKey:@"取消"] style:UIBarButtonItemStylePlain target:self action:@selector(didCancelClick)];
    if (self.manager.configuration.albumShowMode == HXPhotoAlbumShowModePopup) {
        if (self.manager.configuration.photoListCancelLocation == HXPhotoListCancelButtonLocationTypeLeft) {
            self.navigationItem.leftBarButtonItem = cancelItem;
        }else if (self.manager.configuration.photoListCancelLocation == HXPhotoListCancelButtonLocationTypeRight) {
            self.navigationItem.rightBarButtonItem = cancelItem;
        }
        if (self.manager.configuration.photoListTitleView) {
            self.navigationItem.titleView = self.manager.configuration.photoListTitleView(self.albumModel.albumName);
            HXWeakSelf
            self.manager.configuration.photoListTitleViewAction = ^(BOOL selected) {
                [weakSelf albumTitleViewDidAction:selected];
            };
        }else {
            self.navigationItem.titleView = self.albumTitleView;
        }
        [self.view addSubview:self.albumBgView];
        [self.view addSubview:self.albumView];
    }else {
        self.navigationItem.rightBarButtonItem = cancelItem;
    }
}
- (void)changeColor {
    UIColor *backgroundColor;
    UIColor *themeColor;
    UIColor *navBarBackgroudColor;
    UIColor *albumBgColor;
    UIColor *navigationTitleColor;
    if ([HXPhotoCommon photoCommon].isDark) {
        backgroundColor = [UIColor colorWithRed:0.075 green:0.075 blue:0.075 alpha:1];
        themeColor = [UIColor whiteColor];
        navBarBackgroudColor = [UIColor blackColor];
        albumBgColor = [UIColor colorWithRed:0.2 green:0.2 blue:0.2 alpha:1];
        navigationTitleColor = [UIColor whiteColor];
    }else {
        backgroundColor = self.manager.configuration.photoListViewBgColor;
        themeColor = self.manager.configuration.themeColor;
        navBarBackgroudColor = self.manager.configuration.navBarBackgroudColor;
        navigationTitleColor = self.manager.configuration.navigationTitleColor;
        albumBgColor = [UIColor blackColor];
    }
    self.view.backgroundColor = backgroundColor;
    self.collectionView.backgroundColor = backgroundColor;
    [self.navigationController.navigationBar setTintColor:themeColor];
    
    self.navigationController.navigationBar.barTintColor = navBarBackgroudColor;
    self.navigationController.navigationBar.barStyle = self.manager.configuration.navBarStyle;
    if (self.manager.configuration.navBarBackgroundImage) {
        [self.navigationController.navigationBar setBackgroundImage:self.manager.configuration.navBarBackgroundImage forBarMetrics:UIBarMetricsDefault];
    }
    
    if (self.manager.configuration.navigationTitleSynchColor) {
        self.navigationController.navigationBar.titleTextAttributes = @{NSForegroundColorAttributeName : themeColor};
    }else {
        if (navigationTitleColor) {
            self.navigationController.navigationBar.titleTextAttributes = @{NSForegroundColorAttributeName : navigationTitleColor};
        }else {
            self.navigationController.navigationBar.titleTextAttributes = @{NSForegroundColorAttributeName : [UIColor blackColor]};
        }
    }
    
    _albumBgView.backgroundColor = [albumBgColor colorWithAlphaComponent:0.5f];
    
    if (@available(iOS 15.0, *)) {
        UINavigationBarAppearance *appearance = [[UINavigationBarAppearance alloc] init];
        appearance.titleTextAttributes = self.navigationController.navigationBar.titleTextAttributes;
        switch (self.manager.configuration.navBarStyle) {
            case UIBarStyleDefault:
                appearance.backgroundEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleLight];
                break;
            default:
                appearance.backgroundEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleDark];
                break;
        }
        self.navigationController.navigationBar.standardAppearance = appearance;
        self.navigationController.navigationBar.scrollEdgeAppearance = appearance;
    }
}
- (void)deviceOrientationChanged:(NSNotification *)notify {
    self.beforeOrientationIndexPath = [self.collectionView indexPathsForVisibleItems].firstObject;
    self.orientationDidChange = YES;
    if (self.navigationController.topViewController != self) {
        self.needChangeViewFrame = YES;
    }
}
- (CGFloat)getAlbumHeight {
    NSInteger count = self.albumView.albumModelArray.count;
    if (!count) {
        return 0.f;
    }
    CGFloat cellHeight = self.manager.configuration.popupTableViewCellHeight;
    CGFloat albumHeight = cellHeight * count;
    UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
    CGFloat albumMaxHeight;
    if (orientation == UIInterfaceOrientationPortrait || orientation == UIInterfaceOrientationPortraitUpsideDown || HX_UI_IS_IPAD) {
        albumMaxHeight = self.manager.configuration.popupTableViewHeight;
    }else {
        albumMaxHeight = self.manager.configuration.popupTableViewHorizontalHeight;
    }
    if (albumHeight > albumMaxHeight) {
        albumHeight = albumMaxHeight;
    }
    return albumHeight;
}
- (void)changeSubviewFrame {
    CGFloat albumHeight = [self getAlbumHeight];
    UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
    CGFloat navBarHeight = hxNavigationBarHeight;
    NSInteger lineCount = self.manager.configuration.rowCount;
#pragma clang diagnostic push
#pragma clang diagnostic ignored"-Wdeprecated-declarations"
    if (orientation == UIInterfaceOrientationPortrait || orientation == UIInterfaceOrientationPortraitUpsideDown || HX_UI_IS_IPAD) {
        lineCount = self.manager.configuration.rowCount;
        [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationFade];
    }else if (orientation == UIInterfaceOrientationLandscapeRight || orientation == UIInterfaceOrientationLandscapeLeft){
        [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationFade];
        if ([UIApplication sharedApplication].statusBarHidden) {
            navBarHeight = self.navigationController.navigationBar.hx_h;
        }else {
            navBarHeight = self.navigationController.navigationBar.hx_h + 20;
        }
        lineCount = self.manager.configuration.horizontalRowCount;
    }
#pragma clang diagnostic pop
    CGFloat bottomMargin = hxBottomMargin;
    CGFloat leftMargin = 0;
    CGFloat rightMargin = 0;
    CGFloat width = [UIScreen mainScreen].bounds.size.width;
    CGFloat height = [UIScreen mainScreen].bounds.size.height;
    CGFloat viewWidth = [UIScreen mainScreen].bounds.size.width;
    
    
    if (!CGRectEqualToRect(self.view.bounds, [UIScreen mainScreen].bounds)) {
        self.view.frame = CGRectMake(0, 0, viewWidth, height);
    }
    if (HX_IS_IPhoneX_All &&
        (orientation == UIInterfaceOrientationLandscapeLeft || orientation == UIInterfaceOrientationLandscapeRight)) {
        bottomMargin = 21;
        leftMargin = 35;
        rightMargin = 35;
        width = [UIScreen mainScreen].bounds.size.width - 70;
    }
    CGFloat itemWidth = (width - (lineCount - 1)) / lineCount;
    CGFloat itemHeight = itemWidth;
    self.flowLayout.itemSize = CGSizeMake(itemWidth, itemHeight);
    CGFloat bottomViewY = height - 50 - bottomMargin;
    
    if (!self.manager.configuration.singleSelected) {
        self.collectionView.contentInset = UIEdgeInsetsMake(navBarHeight, leftMargin, 50 + bottomMargin, rightMargin);
    } else {
        self.collectionView.contentInset = UIEdgeInsetsMake(navBarHeight, leftMargin, bottomMargin, rightMargin);
    }

#ifdef __IPHONE_13_0
        if (@available(iOS 13.0, *)) {
            self.collectionView.scrollIndicatorInsets = UIEdgeInsetsMake(0, 0, 50.f, 0);
        }else {
            self.collectionView.scrollIndicatorInsets = self.collectionView.contentInset;
        }
#else
        self.collectionView.scrollIndicatorInsets = self.collectionView.contentInset;
#endif
    
    if (self.orientationDidChange) {
        [self.collectionView scrollToItemAtIndexPath:self.beforeOrientationIndexPath atScrollPosition:UICollectionViewScrollPositionTop animated:NO];
    }
    
    self.bottomView.frame = CGRectMake(0, bottomViewY, viewWidth, 50 + bottomMargin);
    
    if (self.manager.configuration.albumShowMode == HXPhotoAlbumShowModePopup) {
        self.albumView.hx_w = viewWidth;
        self.albumView.hx_h = albumHeight;
        BOOL titleViewSeleted = NO;
        if (self.manager.configuration.photoListTitleView) {
            if (self.manager.configuration.photoListTitleViewSelected) {
                titleViewSeleted = self.manager.configuration.photoListTitleViewSelected();
            }
            if (self.manager.configuration.updatePhotoListTitle) {
                self.manager.configuration.updatePhotoListTitle(self.albumModel.albumName);
            }
        }else {
            titleViewSeleted = self.albumTitleView.selected;
            self.albumTitleView.model = self.albumModel;
        }
        if (titleViewSeleted) {
            self.albumView.hx_y = navBarHeight;
            if (self.manager.configuration.singleSelected) {
                self.albumView.alpha = 1;
            }
        }else {
            self.albumView.hx_y = -(navBarHeight + self.albumView.hx_h);
            if (self.manager.configuration.singleSelected) {
                self.albumView.alpha = 0;
            }
        }
        if (self.manager.configuration.singleSelected) {
            self.albumBgView.frame = CGRectMake(0, navBarHeight, viewWidth, height - navBarHeight);
        }else {
            self.albumBgView.hx_size = CGSizeMake(viewWidth, height);
        }
        if (self.manager.configuration.popupAlbumTableView) {
            self.manager.configuration.popupAlbumTableView(self.albumView.tableView);
        }
    }
    
    self.navigationController.navigationBar.translucent = self.manager.configuration.navBarTranslucent;
    
    if (!self.manager.configuration.singleSelected) {
        if (self.manager.configuration.photoListBottomView) {
            self.manager.configuration.photoListBottomView(self.bottomView);
        }
    }
    if (self.manager.configuration.photoListCollectionView) {
        self.manager.configuration.photoListCollectionView(self.collectionView);
    }
    if (self.manager.configuration.navigationBar) {
        self.manager.configuration.navigationBar(self.navigationController.navigationBar, self);
    }
}
- (void)getCameraRollAlbum {
    self.albumModel = self.hx_customNavigationController.cameraRollAlbumModel;
    if (self.manager.configuration.updatePhotoListTitle) {
        self.manager.configuration.updatePhotoListTitle(self.albumModel.albumName);
    }else {
        self.albumTitleView.model = self.albumModel;
    }
    [self getPhotoList];
}
- (void)getAlbumList {
    HXWeakSelf
    if (self.hx_customNavigationController.cameraRollAlbumModel) {
        [self getCameraRollAlbum];
    }else {
        self.hx_customNavigationController.requestCameraRollCompletion = ^{
            [weakSelf getCameraRollAlbum];
        };
    }
    if (self.hx_customNavigationController.albums) {
        [self setAlbumModelArray];
    }else {
        self.hx_customNavigationController.requestAllAlbumCompletion = ^{
            [weakSelf setAlbumModelArray];
        };
    }
}
- (void)setAlbumModelArray {
    self.firstDidAlbumTitleView = NO;
    self.albumView.albumModelArray = self.hx_customNavigationController.albums;
    self.albumView.hx_h = [self getAlbumHeight];
    self.albumView.hx_y = -(self.collectionView.contentInset.top + self.albumView.hx_h);
    self.albumTitleView.canSelect = YES;
}
- (void)getPhotoList {
    [self startGetAllPhotoModel];
}
- (void)didCancelClick {
    if (self.manager.configuration.albumShowMode == HXPhotoAlbumShowModePopup) {
        if (self.manager.configuration.photoListChangeTitleViewSelected) {
            self.manager.configuration.photoListChangeTitleViewSelected(NO);
        }
        [self.manager cancelBeforeSelectedList];
    }
    if ([self.delegate respondsToSelector:@selector(photoViewControllerDidCancel:)]) {
        [self.delegate photoViewControllerDidCancel:self];
    }
    if (self.cancelBlock) {
        self.cancelBlock(self, self.manager);
    }
    self.manager.selectPhotoing = NO;
    BOOL selectPhotoCancelDismissAnimated = self.manager.selectPhotoCancelDismissAnimated;
    [self dismissViewControllerAnimated:selectPhotoCancelDismissAnimated completion:^{
        if ([self.delegate respondsToSelector:@selector(photoViewControllerCancelDismissCompletion:)]) {
            [self.delegate photoViewControllerCancelDismissCompletion:self];
        }
    }];
}
- (NSInteger)dateItem:(HXPhotoModel *)model {
    NSInteger dateItem = [self.allArray indexOfObject:model];
    return dateItem;
}
- (void)scrollToPoint:(HXPhotoViewCell *)cell rect:(CGRect)rect {
    UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
    CGFloat navBarHeight = hxNavigationBarHeight;
    if (orientation == UIInterfaceOrientationLandscapeRight || orientation == UIInterfaceOrientationLandscapeLeft){
        if ([UIApplication sharedApplication].statusBarHidden) {
            navBarHeight = self.navigationController.navigationBar.hx_h;
        }else {
            navBarHeight = self.navigationController.navigationBar.hx_h + 20;
        }
    }
    
    if (rect.origin.y < navBarHeight) {
        [self.collectionView setContentOffset:CGPointMake(0, cell.frame.origin.y - navBarHeight)];
    }else if (rect.origin.y + rect.size.height > self.view.hx_h - 50.5 - hxBottomMargin) {
        [self.collectionView setContentOffset:CGPointMake(0, cell.frame.origin.y - self.view.hx_h + 50.5 + hxBottomMargin + rect.size.height)];
    }
}
- (void)selectPanGestureRecognizerClick:(UIPanGestureRecognizer *)panGesture {
    if (self.albumTitleView.selected) {
        return;
    }
    if (panGesture.state == UIGestureRecognizerStateBegan) {
        // 获取起始点
        self.panSelectStartPoint = [panGesture locationInView:self.collectionView];
        NSIndexPath *indexPath = [self.collectionView indexPathForItemAtPoint:self.panSelectStartPoint];
        // 是否可以选择视频
        BOOL canSelectVideo = self.manager.videoSelectedType != HXPhotoManagerVideoSelectedTypeSingle;
        if (indexPath) {
            // 起始点在cell上
            HXPhotoModel *firstModel = self.allArray[indexPath.item];
            if (firstModel.subType == HXPhotoModelMediaSubTypeVideo) {
                if (canSelectVideo) {
                    self.currentPanSelectType = !firstModel.selected;
                }
            }else {
                self.currentPanSelectType = !firstModel.selected;
            }
        }else {
            // 起始点不在cell上
            self.currentPanSelectType = -1;
        }
    }else if (panGesture.state == UIGestureRecognizerStateChanged) {
        CGPoint currentPoint = [panGesture locationInView:self.collectionView];
        NSInteger firstLine = 0;
        NSInteger lastLine = 0;
        NSIndexPath *firstIndexPath = [self.collectionView indexPathForItemAtPoint:self.panSelectStartPoint];
        if (!firstIndexPath) {
            // 起始点不在cell上直接不可滑动选择
            return;
        }
        NSIndexPath *lastIndexPath = [self.collectionView indexPathForItemAtPoint:currentPoint];
        if (!lastIndexPath) {
            return;
        }
        NSInteger rowCount = self.manager.configuration.rowCount;
        UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
        if (orientation == UIInterfaceOrientationLandscapeRight || orientation == UIInterfaceOrientationLandscapeLeft){
            rowCount = self.manager.configuration.horizontalRowCount;
        }
        if ((firstIndexPath.item + 1) % rowCount == 0) {
            firstLine = (firstIndexPath.item + 1) / rowCount;
        }else {
            firstLine = (firstIndexPath.item + 1) / rowCount + 1;
        }
        if ((lastIndexPath.item + 1) % rowCount == 0) {
            lastLine = (lastIndexPath.item + 1) / rowCount;
        }else {
            lastLine = (lastIndexPath.item + 1) / rowCount + 1;
        }
        NSMutableArray *indexPaths = [NSMutableArray array];
        CGFloat startX;
        CGFloat maxX;
        BOOL xReverse = NO;
        if (currentPoint.x > self.panSelectStartPoint.x) {
            // 向右
            maxX = [self panSelectGetMaxXWithPoint:currentPoint];
            startX = [self panSelectGetMinXWithPoint:self.panSelectStartPoint];
        }else {
            // 向左
            xReverse = YES;
            maxX = [self panSelectGetMaxXWithPoint:self.panSelectStartPoint];
            startX = [self panSelectGetMinXWithPoint:currentPoint];
        }
        CGFloat maxY;
        CGFloat startY;
        BOOL yReverse = NO;
        if (currentPoint.y > self.panSelectStartPoint.y) {
            // 向下
            maxY = [self panSelectGetMaxYWithPoint:currentPoint];
            startY = [self panSelectGetMinYWithPoint:self.panSelectStartPoint];
        }else {
            // 向上
            yReverse = YES;
            maxY = [self panSelectGetMaxYWithPoint:self.panSelectStartPoint];
            startY = [self panSelectGetMinYWithPoint:currentPoint];
        }
        NSInteger distanceW = self.flowLayout.minimumInteritemSpacing + self.flowLayout.itemSize.width;
        NSInteger distanceH = self.flowLayout.minimumInteritemSpacing + self.flowLayout.itemSize.height;
        BOOL canSelectVideo = self.manager.videoSelectedType != HXPhotoManagerVideoSelectedTypeSingle;
        NSIndexPath *sIndexPath = [self.collectionView indexPathForItemAtPoint:self.panSelectStartPoint];
        if (sIndexPath && ![indexPaths containsObject:sIndexPath]) {
            HXPhotoModel *model = self.allArray[sIndexPath.item];
            if (model.subType == HXPhotoModelMediaSubTypeVideo) {
                if (canSelectVideo) {
                    [indexPaths addObject:sIndexPath];
                }
            }else {
                [indexPaths addObject:sIndexPath];
            }
        }
        while (yReverse ? maxY > startY : startY < maxY) {
            CGFloat tempStartX = startX;
            CGFloat tempMaxX = maxX;
            NSInteger currentLine = 0;
            NSIndexPath *currentIndexPath;
            if (yReverse) {
                currentIndexPath = [self.collectionView indexPathForItemAtPoint:CGPointMake(tempMaxX - 1, maxY - 1)];
            }else {
                currentIndexPath = [self.collectionView indexPathForItemAtPoint:CGPointMake(tempStartX + 1, startY + 1)];
            }
            if ((currentIndexPath.item + 1) % rowCount == 0) {
                currentLine = (currentIndexPath.item + 1) / rowCount;
            }else {
                currentLine = (currentIndexPath.item + 1) / rowCount + 1;
            }
            if (currentLine == firstLine) {
                if (lastLine != firstLine) {
                    if (yReverse) {
                        tempMaxX = [self panSelectGetMaxXWithPoint:self.panSelectStartPoint];
                        tempStartX = 2;
                    }else {
                        if (xReverse) {
                            tempStartX = [self panSelectGetMinXWithPoint:self.panSelectStartPoint];
                        }
                        tempMaxX = HX_ScreenWidth - 2;
                    }
                }
            }else if (currentLine == lastLine) {
                if (yReverse) {
                    tempStartX = [self panSelectGetMinXWithPoint:currentPoint];
                    tempMaxX = HX_ScreenWidth - 2;
                }else {
                    tempStartX = 2;
                    if (xReverse) {
                        tempMaxX = [self panSelectGetMaxXWithPoint:currentPoint];
                    }
                }
            }else if (currentLine != firstLine && currentLine != lastLine) {
                tempStartX = 2;
                tempMaxX = HX_ScreenWidth - 2;
            }
            while (yReverse ? tempMaxX > tempStartX : tempStartX < tempMaxX) {
                NSIndexPath *indexPath;
                if (yReverse) {
                    indexPath = [self panSelectCurrentIndexPathWithPoint:CGPointMake(tempMaxX, maxY) indexPaths:indexPaths canSelectVideo:canSelectVideo];
                }else {
                    indexPath = [self panSelectCurrentIndexPathWithPoint:CGPointMake(tempStartX, startY) indexPaths:indexPaths canSelectVideo:canSelectVideo];
                }
                if (indexPath) {
                    [indexPaths addObject:indexPath];
                }
                if (yReverse) {
                    tempMaxX -= distanceW / 2;
                }else {
                    tempStartX += distanceW / 2;
                }
            }
            if (yReverse) {
                maxY -= distanceH / 2;
            }else {
                startY += distanceH / 2;
            }
        }
        NSIndexPath *eIndexPath = [self.collectionView indexPathForItemAtPoint:currentPoint];
        if (eIndexPath && ![indexPaths containsObject:eIndexPath]) {
            HXPhotoModel *model = self.allArray[eIndexPath.item];
            if (self.currentPanSelectType == 0) {
                if (model.selected) {
                    if (model.subType == HXPhotoModelMediaSubTypeVideo) {
                        if (canSelectVideo) {
                            [indexPaths addObject:eIndexPath];
                        }
                    }else {
                        [indexPaths addObject:eIndexPath];
                    }
                }
            }else if (self.currentPanSelectType == 1) {
                if (!model.selected) {
                    if (model.subType == HXPhotoModelMediaSubTypeVideo) {
                        if (canSelectVideo) {
                            [indexPaths addObject:eIndexPath];
                        }
                    }else {
                        [indexPaths addObject:eIndexPath];
                    }
                }
            }
        }
        if (self.currentPanSelectType == -1) {
            NSIndexPath *firstIndexPath = indexPaths.firstObject;
            HXPhotoModel *firstModel;
            if (firstIndexPath) {
                firstModel = self.allArray[firstIndexPath.item];
                self.currentPanSelectType = !firstModel.selected;
            }
        }
        NSMutableArray *reloadSelectArray = [NSMutableArray array];
        for (NSIndexPath *indexPath in indexPaths) {
            HXPhotoModel *model = self.allArray[indexPath.item];
            if (model.type == HXPhotoModelMediaTypeCamera ||
                model.type == HXPhotoModelMediaTypeLimit) {
                continue;
            }
            if (model.subType == HXPhotoModelMediaSubTypeVideo && !canSelectVideo) {
                continue;
            }
            if (self.currentPanSelectType == 0) {
                // 取消选择
                if (model.selected) {
                    [self.manager beforeSelectedListdeletePhotoModel:model];
                    if (![reloadSelectArray containsObject:indexPath]) {
                        [reloadSelectArray addObject:indexPath];
                    }
                }
            }else if (self.currentPanSelectType == 1) {
                // 选择
                if (!model.selected) {
                    if (model.isICloud) {
                        // 是iCloud上的资源就过滤掉
                        continue;
                    }
                    // 是否可以选择
                    NSString *str = [self.manager maximumOfJudgment:model];
                    if (!str) {
                        HXPhotoViewCell *cell = (HXPhotoViewCell *)[self.collectionView cellForItemAtIndexPath:indexPath];
                        model.thumbPhoto = cell.imageView.image;
                        [self.manager beforeSelectedListAddPhotoModel:model];
                        if (![reloadSelectArray containsObject:indexPath]) {
                            [reloadSelectArray addObject:indexPath];
                        }
                    }else {
                        if (self.imagePromptView && [self.imagePromptView.text isEqualToString:str]) {
                            continue;
                        }
                        [self showImagePromptViewWithText:str];
                    }
                }else {
                    HXPhotoViewCell *cell = (HXPhotoViewCell *)[self.collectionView cellForItemAtIndexPath:indexPath];
                    if (![cell.selectBtn.currentTitle isEqualToString:model.selectIndexStr] || !cell.selectBtn.selected) {
                        if (![reloadSelectArray containsObject:indexPath]) {
                            [reloadSelectArray addObject:indexPath];
                        }
                    }
                }
            }
        }
        NSPredicate * filterPredicate = [NSPredicate predicateWithFormat:@"NOT (SELF IN %@)",indexPaths];
        NSArray * filterArray = [self.panSelectIndexPaths filteredArrayUsingPredicate:filterPredicate];
        for (NSIndexPath *indexPath in filterArray) {
            HXPhotoModel *model = self.allArray[indexPath.item];
            if (model.type == HXPhotoModelMediaTypeCamera ||
                model.type == HXPhotoModelMediaTypeLimit) {
                continue;
            }
            if (model.subType == HXPhotoModelMediaSubTypeVideo && !canSelectVideo) {
                continue;
            }
            if (self.currentPanSelectType == 0) {
                if (!model.selected) {
                    [self.manager beforeSelectedListAddPhotoModel:model];
                    if (![reloadSelectArray containsObject:indexPath]) {
                        [reloadSelectArray addObject:indexPath];
                    }
                }
            }else if (self.currentPanSelectType == 1) {
                if (model.selected) {
                    [self.manager beforeSelectedListdeletePhotoModel:model];
                    if (![reloadSelectArray containsObject:indexPath]) {
                        [reloadSelectArray addObject:indexPath];
                    }
                }
            }
        }
        if (self.currentPanSelectType == 0) {
            for (HXPhotoModel *model in [self.manager selectedArray]) {
                if (model.currentAlbumIndex != self.albumModel.index) {
                    continue;
                }
                if (!model.dateCellIsVisible) {
                    continue;
                }
                NSIndexPath *indexPath = [NSIndexPath indexPathForItem:[self dateItem:model] inSection:0];
                HXPhotoViewCell *cell = (HXPhotoViewCell *)[self.collectionView cellForItemAtIndexPath:indexPath];
                if (cell && ![cell.selectBtn.currentTitle isEqualToString:model.selectIndexStr]) {
                    if (![reloadSelectArray containsObject:indexPath]) {
                        [reloadSelectArray addObject:indexPath];
                    }
                }
            }
        }
        [reloadSelectArray addObjectsFromArray:[self getVisibleVideoCellIndexPathsWithCurrentIndexPaths:reloadSelectArray]];
        if (reloadSelectArray.count) {
            [self.collectionView reloadItemsAtIndexPaths:reloadSelectArray];
            self.bottomView.selectCount = [self.manager selectedCount];
        }
        self.panSelectIndexPaths = indexPaths;
    }else if (panGesture.state == UIGestureRecognizerStateEnded ||
              panGesture.state == UIGestureRecognizerStateCancelled) {
        self.panSelectIndexPaths = nil;
        self.currentPanSelectType = -1;
    }
}
- (CGFloat)panSelectGetMinYWithPoint:(CGPoint)point {
    NSIndexPath *indexPath = [self.collectionView indexPathForItemAtPoint:point];
    UICollectionViewCell *cell = [self.collectionView cellForItemAtIndexPath:indexPath];
    return cell.hx_y + 2;
}
- (CGFloat)panSelectGetMaxYWithPoint:(CGPoint)point {
    NSIndexPath *indexPath = [self.collectionView indexPathForItemAtPoint:point];
    UICollectionViewCell *cell = [self.collectionView cellForItemAtIndexPath:indexPath];
    return CGRectGetMaxY(cell.frame) - 2;
}
- (CGFloat)panSelectGetMinXWithPoint:(CGPoint)point {
    NSIndexPath *indexPath = [self.collectionView indexPathForItemAtPoint:point];
    UICollectionViewCell *cell = [self.collectionView cellForItemAtIndexPath:indexPath];
    return cell.hx_x + 2;
}
- (CGFloat)panSelectGetMaxXWithPoint:(CGPoint)point {
    NSIndexPath *indexPath = [self.collectionView indexPathForItemAtPoint:point];
    UICollectionViewCell *cell = [self.collectionView cellForItemAtIndexPath:indexPath];
    return CGRectGetMaxX(cell.frame) - 2;
}
- (NSIndexPath *)panSelectCurrentIndexPathWithPoint:(CGPoint)point indexPaths:(NSMutableArray *)indexPaths canSelectVideo:(BOOL)canSelectVideo {
    NSIndexPath *indexPath = [self.collectionView indexPathForItemAtPoint:point];
    if (indexPath && ![indexPaths containsObject:indexPath]) {
        HXPhotoModel *model = self.allArray[indexPath.item];
        if (self.currentPanSelectType == 0) {
            if (!model.selected && ![self.panSelectIndexPaths containsObject:indexPath]) {
                return nil;
            }
        }else if (self.currentPanSelectType == 1) {
            if (model.selected && ![self.panSelectIndexPaths containsObject:indexPath]) {
                return nil;
            }
        }
        if (model.subType == HXPhotoModelMediaSubTypeVideo) {
            if (canSelectVideo) {
                return indexPath;
            }
        }else {
            return indexPath;
        }
    }
    return nil;
}
- (NSMutableArray *)getVisibleVideoCellIndexPathsWithCurrentIndexPaths:(NSMutableArray *)currentIndexPath {
    NSMutableArray *array = [NSMutableArray arrayWithCapacity:self.collectionView.visibleCells.count];
    for (UICollectionViewCell *tempCell in self.collectionView.visibleCells) {
        if ([tempCell isKindOfClass:[HXPhotoViewCell class]]) {
            HXPhotoViewCell *cell = (HXPhotoViewCell *)tempCell;
            BOOL canSelect = NO;
            if (!cell.model.selected) {
                if (cell.model.subType == HXPhotoModelMediaSubTypePhoto) {
                    canSelect = self.manager.beforeCanSelectPhoto;
                }else if (cell.model.subType == HXPhotoModelMediaSubTypeVideo) {
                    canSelect = [self.manager beforeCanSelectVideoWithModel:cell.model];
                }
            }else {
                canSelect = YES;
            }
            if ((cell.videoMaskLayer.hidden && !canSelect) || (!cell.videoMaskLayer.hidden && canSelect)) {
                NSIndexPath *indexPath = [self.collectionView indexPathForCell:tempCell];
                if (![currentIndexPath containsObject:indexPath]) {
                    [array addObject:indexPath];
                }
            }
        }
    }
    return array;
}
- (void)showImagePromptViewWithText:(NSString *)text {
    [UIView cancelPreviousPerformRequestsWithTarget:self];
    [self.imagePromptView removeFromSuperview];
    CGFloat hudW = [UILabel hx_getTextWidthWithText:text height:15 fontSize:14];
    if (hudW > self.view.hx_w - 60) {
        hudW = self.view.hx_w - 60;
    }
    
    CGFloat hudH = [UILabel hx_getTextHeightWithText:text width:hudW fontSize:14];
    if (hudW < 100) {
        hudW = 100;
    }
    self.imagePromptView = [[HXHUD alloc] initWithFrame:CGRectMake(0, 0, hudW + 20, 110 + hudH - 15) imageName:@"hx_alert_failed" text:text];
    self.imagePromptView.alpha = 0;
    [self.view addSubview:self.imagePromptView];
    self.imagePromptView.center = CGPointMake(self.view.hx_w / 2, self.view.hx_h / 2);
    self.imagePromptView.transform = CGAffineTransformMakeScale(0.4, 0.4);
    [UIView animateWithDuration:0.25 delay:0 usingSpringWithDamping:0.5 initialSpringVelocity:1.0 options:0 animations:^{
        self.imagePromptView.alpha = 1;
        self.imagePromptView.transform = CGAffineTransformIdentity;
    } completion:nil];
    [self performSelector:@selector(hideImagePromptView) withObject:nil afterDelay:1.75f inModes:@[NSRunLoopCommonModes]];
}
- (void)hideImagePromptView {
    [UIView animateWithDuration:0.25f animations:^{
        self.imagePromptView.alpha = 0;
        self.imagePromptView.transform = CGAffineTransformMakeScale(0.5, 0.5);
    } completion:^(BOOL finished) {
        [self.imagePromptView removeFromSuperview];
        self.imagePromptView = nil;
    }];
}
#pragma mark - < public >
- (void)startGetAllPhotoModel {
    HXWeakSelf
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [self.manager getPhotoListWithAlbumModel:self.albumModel
                                        complete:^(NSMutableArray * _Nullable allList, NSMutableArray * _Nullable previewList, NSUInteger photoCount, NSUInteger videoCount, HXPhotoModel * _Nullable firstSelectModel, HXAlbumModel * _Nullable albumModel) {
            if ((weakSelf.albumModel != albumModel && !weakSelf.assetDidChanged) ||
                !weakSelf) {
                return;
            }
            weakSelf.assetDidChanged = NO;
            if (weakSelf.collectionViewReloadCompletion) {
                return ;
            }
            weakSelf.photoCount = photoCount + weakSelf.manager.cameraPhotoCount;
            weakSelf.videoCount = videoCount + weakSelf.manager.cameraVideoCount;
            [weakSelf setPhotoModelsWithAllList:allList previewList:previewList firstSelectModel:firstSelectModel];
        }];
    });
}
- (void)setPhotoModelsWithAllList:(NSMutableArray *)allList
                      previewList:(NSMutableArray *)previewList
                 firstSelectModel:(HXPhotoModel *)firstSelectModel {
    self.collectionViewReloadCompletion = YES;
    
    self.allArray = allList.mutableCopy;
    if (self.allArray.count && self.showBottomPhotoCount) {
        if (!self.photoCount && !self.videoCount) {
            self.manager.configuration.showBottomPhotoDetail = NO;
        }else {
            self.manager.configuration.showBottomPhotoDetail = YES;
        }
    }
    self.previewArray = previewList.mutableCopy;
    [self reloadCollectionViewWithFirstSelectModel:firstSelectModel];
}
- (void)reloadCollectionViewWithFirstSelectModel:(HXPhotoModel *)firstSelectModel {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (!self.firstOn) {
            self.cellCanSetModel = NO;
            [self.hx_customNavigationController.view hx_handleLoading];
        }else {
            [self.hx_customNavigationController.view hx_handleLoading:NO];
        }
        [self.collectionView reloadData];
        [self collectionViewReloadFinishedWithFirstSelectModel:firstSelectModel];
        if (!self.firstOn) {
            dispatch_async(dispatch_get_main_queue(),^{
                // 在 collectionView reload完成之后一个一个的cell去获取image，防止一次性获取造成卡顿
                self.collectionVisibleCells = [self.collectionView.visibleCells sortedArrayUsingComparator:^NSComparisonResult(HXPhotoViewCell *obj1, HXPhotoViewCell *obj2) {
                    // visibleCells 这个数组的数据顺序是乱的，所以在获取image之前先将可见cell排序
                    NSIndexPath *indexPath1 = [self.collectionView indexPathForCell:obj1];
                    NSIndexPath *indexPath2 = [self.collectionView indexPathForCell:obj2];
                    if (indexPath1.item > indexPath2.item) {
                        return NSOrderedDescending;
                    }else {
                        return NSOrderedAscending;
                    }
                }];
                // 排序完成之后从上到下依次获取image
                [self cellSetModelData:self.collectionVisibleCells.firstObject];
            });
        }
    });
}
- (void)cellSetModelData:(HXPhotoViewCell *)cell {
    if ([cell isKindOfClass:[HXPhotoViewCell class]]) {
        HXWeakSelf
        cell.alpha = 0;
        [cell setModelDataWithHighQuality:YES completion:^(HXPhotoViewCell *myCell) {
            [UIView animateWithDuration:0.125 animations:^{
                myCell.alpha = 1;
            }];
            NSInteger count = weakSelf.collectionVisibleCells.count;
            NSInteger index = [weakSelf.collectionVisibleCells indexOfObject:myCell];
            if (index < count - 1) {
                [weakSelf cellSetModelData:weakSelf.collectionVisibleCells[index + 1]];
            }else {
                // 可见cell已全部设置
                weakSelf.cellCanSetModel = YES;
                weakSelf.collectionVisibleCells = nil;
            }
        }];
    }else {
        cell.hidden = NO;
        NSInteger count = self.collectionVisibleCells.count;
        NSInteger index = [self.collectionVisibleCells indexOfObject:cell];
        if (index < count - 1) {
            [self cellSetModelData:self.collectionVisibleCells[index + 1]];
        }else {
            self.cellCanSetModel = YES;
            self.collectionVisibleCells = nil;
        }
    }
}
- (void)collectionViewReloadFinishedWithFirstSelectModel:(HXPhotoModel *)firstSelectModel {
    if (self.allArray.count == 0) {
        return;
    }
    if (!self.manager.configuration.singleSelected) {
        self.bottomView.selectCount = self.manager.selectedArray.count;
    }
    NSIndexPath *scrollIndexPath;
    UICollectionViewScrollPosition position = UICollectionViewScrollPositionNone;
    if (!self.manager.configuration.reverseDate) {
        if (self.allArray.count > 0) {
            if (firstSelectModel) {
                scrollIndexPath = [NSIndexPath indexPathForItem:[self.allArray indexOfObject:firstSelectModel] inSection:0];
                position = UICollectionViewScrollPositionCenteredVertically;
            }else {
                NSInteger forItem = (self.allArray.count - 1) <= 0 ? 0 : self.allArray.count - 1;
                scrollIndexPath = [NSIndexPath indexPathForItem:forItem inSection:0];
                position = UICollectionViewScrollPositionBottom;
            }
        }
    }else {
        if (firstSelectModel) {
            scrollIndexPath = [NSIndexPath indexPathForItem:[self.allArray indexOfObject:firstSelectModel] inSection:0];
            position = UICollectionViewScrollPositionCenteredVertically;
        }else {
            scrollIndexPath = [NSIndexPath indexPathForItem:0 inSection:0];
            position = UICollectionViewScrollPositionTop;
        }
    }
    if (scrollIndexPath) {
        [self.collectionView scrollToItemAtIndexPath:scrollIndexPath atScrollPosition:position animated:NO];
    }
}
- (HXPhotoViewCell *)currentPreviewCell:(HXPhotoModel *)model {
    if (!model || ![self.allArray containsObject:model]) {
        return nil;
    }
    
    NSIndexPath *indexPath = [NSIndexPath indexPathForItem:[self dateItem:model] inSection:0];
    return (HXPhotoViewCell *)[self.collectionView cellForItemAtIndexPath:indexPath];
}
- (BOOL)scrollToModel:(HXPhotoModel *)model {
    BOOL isContainsModel = [self.allArray containsObject:model];
    if (isContainsModel) {
        [self.collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForItem:[self dateItem:model] inSection:0] atScrollPosition:UICollectionViewScrollPositionNone animated:NO];
        [self.collectionView reloadItemsAtIndexPaths:@[[NSIndexPath indexPathForItem:[self dateItem:model] inSection:0]]];
    }
    return isContainsModel;
}

#pragma mark - < HXCustomCameraViewControllerDelegate >
- (void)customCameraViewController:(HXCustomCameraViewController *)viewController didDone:(HXPhotoModel *)model {
    model.currentAlbumIndex = self.albumModel.index;
    if (!self.manager.configuration.singleSelected) {
        [self.manager beforeListAddCameraTakePicturesModel:model];
    }
    if ([HXPhotoTools authorizationStatusIsLimited]) {
        return;
    }
    if (model.asset) {
        [self.manager addTempCameraAssetModel:model];
    }
    if (model.type != HXPhotoModelMediaTypeCameraPhoto &&
        model.type != HXPhotoModelMediaTypeCameraVideo) {
        HXAlbumModel *albumModel = self.albumView.albumModelArray.firstObject;
        if (albumModel.count == 0) {
            albumModel.assetResult = [PHAsset fetchAssetsWithLocalIdentifiers:@[model.localIdentifier] options:nil];
        }
        albumModel.count++;
    }
    if (model.subType == HXPhotoModelMediaSubTypePhoto) {
        self.photoCount++;
    }else if (model.subType == HXPhotoModelMediaSubTypeVideo) {
        self.videoCount++;
    }
    if (self.albumModel.realCount != self.photoCount + self.videoCount) {
        self.albumModel.realCount = self.photoCount + self.videoCount;
    }
    [self collectionViewAddModel:model beforeModel:nil];
    if ([self.delegate respondsToSelector:@selector(photoViewControllerDidChangeSelect:selected:)]) {
        [self.delegate photoViewControllerDidChangeSelect:model selected:model.selected];
    }
}
- (void)collectionViewAddModel:(HXPhotoModel *)model beforeModel:(HXPhotoModel *)beforeModel {
    
    NSInteger cameraIndex = self.manager.configuration.openCamera ? 1 : 0;
    if (beforeModel) {
        NSInteger allIndex = cameraIndex;
        NSInteger previewIndex = 0;
        if ([self.allArray containsObject:beforeModel]) {
            allIndex = [self.allArray indexOfObject:beforeModel];
        }
        if ([self.previewArray containsObject:beforeModel]) {
            previewIndex = [self.previewArray indexOfObject:beforeModel];
        }
        [self.allArray insertObject:model atIndex:allIndex];
        [self.previewArray insertObject:model atIndex:previewIndex];
    }else {
        if (self.manager.configuration.reverseDate) {
            [self.allArray insertObject:model atIndex:cameraIndex];
            [self.previewArray insertObject:model atIndex:0];
        }else {
            NSInteger count = self.allArray.count - cameraIndex;
            [self.allArray insertObject:model atIndex:count];
            [self.previewArray addObject:model];
        }
    }
    if (beforeModel && [self.allArray containsObject:model]) {
        NSInteger index = [self.allArray indexOfObject:model];
        [self.collectionView insertItemsAtIndexPaths:@[[NSIndexPath indexPathForItem:index inSection:0]]];
    }else {
        if (self.manager.configuration.reverseDate) {
            [self.collectionView insertItemsAtIndexPaths:@[[NSIndexPath indexPathForItem:cameraIndex inSection:0]]];
        }else {
            NSInteger count = self.allArray.count - 1;
            [self.collectionView insertItemsAtIndexPaths:@[[NSIndexPath indexPathForItem:count - cameraIndex inSection:0]]];
        }
    }
    self.footerView.photoCount = self.photoCount;
    self.footerView.videoCount = self.videoCount;
    self.bottomView.selectCount = [self.manager selectedCount];
    if (self.manager.configuration.albumShowMode == HXPhotoAlbumShowModePopup) {
        [self.albumView refreshCamearCount];
    }else if (self.manager.configuration.albumShowMode == HXPhotoAlbumShowModeDefault) {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"CustomCameraViewControllerDidDoneNotification" object:nil];
    }
}
#pragma mark - < UICollectionViewDataSource >
- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.allArray.count;
}
- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    HXPhotoModel *model;
    if (indexPath.item < self.allArray.count) {
        model = self.allArray[indexPath.item];
    }
    model.dateCellIsVisible = YES;
    if (model.type == HXPhotoModelMediaTypeCamera) {
        HXPhotoCameraViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"HXPhotoCameraViewCellId" forIndexPath:indexPath];
        cell.bgColor = self.manager.configuration.photoListTakePhotoBgColor;
        cell.model = model;
        if (!self.cameraCell) {
            cell.cameraImage = [HXPhotoCommon photoCommon].cameraImage;
            self.cameraCell = cell;
        }
        if (!self.cellCanSetModel) {
            cell.hidden = YES;
        }
        return cell;
    }else if (model.type == HXPhotoModelMediaTypeLimit) {
        HXPhotoLimitViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"HXPhotoLimitViewCellId" forIndexPath:indexPath];
        cell.lineColor = self.manager.configuration.photoListLimitCellLineColor;
        cell.lineDarkColor = self.manager.configuration.photoListLimitCellLineDarkColor;
        cell.textColor = self.manager.configuration.photoListLimitCellTextColor;
        cell.textDarkColor = self.manager.configuration.photoListLimitCellTextDarkColor;
        cell.textFont = self.manager.configuration.photoListLimitCellTextFont;
        cell.bgColor = self.manager.configuration.photoListLimitCellBackgroundColor;
        cell.bgDarkColor = self.manager.configuration.photoListLimitCellBackgroundDarkColor;
        [cell config];
        return cell;
    }else {
        HXPhotoViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"HXPhotoViewCellID" forIndexPath:indexPath];
        cell.delegate = self;
        cell.darkSelectBgColor = self.manager.configuration.cellDarkSelectBgColor;
        cell.darkSelectedTitleColor = self.manager.configuration.cellDarkSelectTitleColor;
        if (!model.selected) {
            if (model.subType == HXPhotoModelMediaSubTypePhoto) {
                cell.canSelect = self.manager.beforeCanSelectPhoto;
            }else if (model.subType == HXPhotoModelMediaSubTypeVideo) {
                cell.canSelect = [self.manager beforeCanSelectVideoWithModel:model];
            }
        }else {
            cell.canSelect = YES;
        }
        UIColor *cellSelectedTitleColor = self.manager.configuration.cellSelectedTitleColor;
        UIColor *selectedTitleColor = self.manager.configuration.selectedTitleColor;
        UIColor *cellSelectedBgColor = self.manager.configuration.cellSelectedBgColor;
        if (cellSelectedTitleColor) {
            cell.selectedTitleColor = cellSelectedTitleColor;
        }else if (selectedTitleColor) {
            cell.selectedTitleColor = selectedTitleColor;
        }
        if (cellSelectedBgColor) {
            cell.selectBgColor = cellSelectedBgColor;
        }else {
            cell.selectBgColor = self.manager.configuration.themeColor;
        }
        if (self.cellCanSetModel) {
            [cell setModel:model emptyImage:NO];
            [cell setModelDataWithHighQuality:NO completion:nil];
        }else {
            [cell setModel:model emptyImage:YES];
        }
        cell.singleSelected = self.manager.configuration.singleSelected;
        return cell;
    }
}
#pragma mark - < UICollectionViewDelegate >
- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    if (self.navigationController.topViewController != self) {
        return;
    }
    HXPhotoModel *model = self.allArray[indexPath.item];
    if (model.type == HXPhotoModelMediaTypeCamera) {
        if(![UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
            [self.view hx_showImageHUDText:[NSBundle hx_localizedStringForKey:@"无法使用相机!"]];
            return;
        }
        HXWeakSelf
        [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(BOOL granted) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (granted) {
                    if (weakSelf.manager.configuration.replaceCameraViewController) {
                        HXPhotoConfigurationCameraType cameraType;
                        if (weakSelf.manager.type == HXPhotoManagerSelectedTypePhoto) {
                            cameraType = HXPhotoConfigurationCameraTypePhoto;
                        }else if (weakSelf.manager.type == HXPhotoManagerSelectedTypeVideo) {
                            cameraType = HXPhotoConfigurationCameraTypeVideo;
                        }else {
                            if (!weakSelf.manager.configuration.selectTogether) {
                                if (weakSelf.manager.selectedPhotoArray.count > 0) {
                                    cameraType = HXPhotoConfigurationCameraTypePhoto;
                                }else if (weakSelf.manager.selectedVideoArray.count > 0) {
                                    cameraType = HXPhotoConfigurationCameraTypeVideo;
                                }else {
                                    cameraType = HXPhotoConfigurationCameraTypePhotoAndVideo;
                                }
                            }else {
                                cameraType = HXPhotoConfigurationCameraTypePhotoAndVideo;
                            }
                        }
                        switch (weakSelf.manager.configuration.customCameraType) {
                            case HXPhotoCustomCameraTypePhoto:
                                cameraType = HXPhotoConfigurationCameraTypePhoto;
                                break;
                            case HXPhotoCustomCameraTypeVideo:
                                cameraType = HXPhotoConfigurationCameraTypeVideo;
                                break;
                            case HXPhotoCustomCameraTypePhotoAndVideo:
                                cameraType = HXPhotoConfigurationCameraTypePhotoAndVideo;
                                break;
                            default:
                                break;
                        }
                        if (weakSelf.manager.configuration.shouldUseCamera) {
                            weakSelf.manager.configuration.shouldUseCamera(weakSelf, cameraType, weakSelf.manager);
                        }
                        weakSelf.manager.configuration.useCameraComplete = ^(HXPhotoModel *model) {
                            if (round(model.videoDuration) < weakSelf.manager.configuration.videoMinimumSelectDuration) {
                                [weakSelf.view hx_showImageHUDText:[NSString stringWithFormat:[NSBundle hx_localizedStringForKey:@"视频少于%ld秒，无法选择"], weakSelf.manager.configuration.videoMinimumSelectDuration]];
                            }else if (round(model.videoDuration) >= weakSelf.manager.configuration.videoMaximumSelectDuration + 1) {
                                [weakSelf.view hx_showImageHUDText:[NSString stringWithFormat:[NSBundle hx_localizedStringForKey:@"视频大于%ld秒，无法选择"], weakSelf.manager.configuration.videoMaximumSelectDuration]];
                            }
                            [weakSelf customCameraViewController:nil didDone:model];
                        };
                        return;
                    }
                    HXCustomCameraViewController *vc = [[HXCustomCameraViewController alloc] init];
                    vc.delegate = weakSelf;
                    vc.manager = weakSelf.manager;
                    HXCustomNavigationController *nav = [[HXCustomNavigationController alloc] initWithRootViewController:vc];
                    nav.isCamera = YES;
                    nav.supportRotation = weakSelf.manager.configuration.supportRotation;
                    nav.modalPresentationStyle = UIModalPresentationOverFullScreen;
                    nav.modalPresentationCapturesStatusBarAppearance = YES;
                    [weakSelf presentViewController:nav animated:YES completion:nil];
                }else {
                    [HXPhotoTools showUnusableCameraAlert:weakSelf];
                }
            });
        }];
    }else if (model.type == HXPhotoModelMediaTypeLimit) {
        if (@available(iOS 14, *)) {
            [[PHPhotoLibrary sharedPhotoLibrary] presentLimitedLibraryPickerFromViewController:self];
        }
    }else {
        HXPhotoViewCell *cell = (HXPhotoViewCell *)[self.collectionView cellForItemAtIndexPath:indexPath];
        if (cell.model.isICloud) {
            if (!cell.model.iCloudDownloading) {
                [cell startRequestICloudAsset];
            }
            return;
        }
        if (!cell.canSelect) {
            [self.view hx_showImageHUDText:[self.manager maximumOfJudgment:cell.model]];
            return;
        }
        if (cell.model.subType == HXPhotoModelMediaSubTypeVideo) {
            if (cell.model.videoDuration >= self.manager.configuration.videoMaximumSelectDuration + 1) {
                if (self.manager.configuration.selectVideoBeyondTheLimitTimeAutoEdit &&
                    self.manager.configuration.videoCanEdit) {
                    if (cell.model.cameraVideoType == HXPhotoModelMediaTypeCameraVideoTypeNetWork) {
                        if (self.manager.configuration.selectNetworkVideoCanEdit) {
                            [self jumpVideoEditWithModel:cell.model];
                            return;
                        }
                    }else {
                        [self jumpVideoEditWithModel:cell.model];
                        return;
                    }
                }
            }
        }
        if (!self.manager.configuration.singleSelected) {
            HXPhotoPreviewViewController *previewVC = [[HXPhotoPreviewViewController alloc] init];
            if (HX_IOS9Earlier) {
                previewVC.photoViewController = self;
            }
            NSInteger currentIndex = [self.previewArray indexOfObject:cell.model];
            previewVC.delegate = self;
            previewVC.modelArray = self.previewArray;
            previewVC.manager = self.manager;
            previewVC.currentModelIndex = currentIndex;
            self.navigationController.delegate = previewVC;
            [self.navigationController pushViewController:previewVC animated:YES];
        }else {
            if (!self.manager.configuration.singleJumpEdit) {
                NSInteger currentIndex = [self.previewArray indexOfObject:cell.model];
                HXPhotoPreviewViewController *previewVC = [[HXPhotoPreviewViewController alloc] init];
                if (HX_IOS9Earlier) {
                    previewVC.photoViewController = self;
                }
                previewVC.delegate = self;
                previewVC.modelArray = self.previewArray;
                previewVC.manager = self.manager;
                previewVC.currentModelIndex = currentIndex;
                self.navigationController.delegate = previewVC;
                [self.navigationController pushViewController:previewVC animated:YES];
            }else {
                if (cell.model.subType == HXPhotoModelMediaSubTypePhoto) {
                    if (self.manager.configuration.useWxPhotoEdit) {
                        HX_PhotoEditViewController *vc = [[HX_PhotoEditViewController alloc] initWithConfiguration:self.manager.configuration.photoEditConfigur];
                        vc.photoModel = cell.model;
                        vc.delegate = self;
                        vc.onlyCliping = YES;
                        vc.supportRotation = YES;
                        vc.isAutoBack = NO;
                        vc.modalPresentationStyle = UIModalPresentationOverFullScreen;
                        vc.modalPresentationCapturesStatusBarAppearance = YES;
                        [self presentViewController:vc animated:YES completion:nil];
                    }else {
                        HXPhotoEditViewController *vc = [[HXPhotoEditViewController alloc] init];
                        vc.isInside = YES;
                        vc.model = cell.model;
                        vc.delegate = self;
                        vc.manager = self.manager;
                        vc.modalPresentationStyle = UIModalPresentationOverFullScreen;
                        vc.modalPresentationCapturesStatusBarAppearance = YES;
                        [self presentViewController:vc animated:YES completion:nil];
                    }
                }else {
                    NSInteger currentIndex = [self.previewArray indexOfObject:cell.model];
                    HXPhotoPreviewViewController *previewVC = [[HXPhotoPreviewViewController alloc] init];
                    if (HX_IOS9Earlier) {
                        previewVC.photoViewController = self;
                    }
                    previewVC.delegate = self;
                    previewVC.modelArray = self.previewArray;
                    previewVC.manager = self.manager;
                    previewVC.currentModelIndex = currentIndex;
                    self.navigationController.delegate = previewVC;
                    [self.navigationController pushViewController:previewVC animated:YES];
                }
            }
        }
    }
}
- (void)collectionView:(UICollectionView *)collectionView didEndDisplayingCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath {
    if ([cell isKindOfClass:[HXPhotoViewCell class]]) {
        [(HXPhotoViewCell *)cell cancelRequest];
    }
}
- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath {
    if ([kind isEqualToString:UICollectionElementKindSectionFooter]) {
        if (self.manager.configuration.showBottomPhotoDetail) {
            HXPhotoViewSectionFooterView *footerView = [collectionView dequeueReusableSupplementaryViewOfKind:kind withReuseIdentifier:@"sectionFooterId" forIndexPath:indexPath];
            footerView.textColor = self.manager.configuration.photoListBottomPhotoCountTextColor;
            footerView.bgColor = self.manager.configuration.photoListViewBgColor;
            footerView.photoCount = self.photoCount;
            footerView.videoCount = self.videoCount;
            self.footerView = footerView;
            return footerView;
        }
    }
    return [UICollectionReusableView new];
}
- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout referenceSizeForHeaderInSection:(NSInteger)section {
    return CGSizeZero;
}
- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout referenceSizeForFooterInSection:(NSInteger)section {
    return self.manager.configuration.showBottomPhotoDetail ? CGSizeMake(self.view.hx_w, 50) : CGSizeZero;
}
- (UIViewController *)previewViewControlerWithIndexPath:(NSIndexPath *)indexPath {
    HXPhotoViewCell *cell = (HXPhotoViewCell *)[self.collectionView cellForItemAtIndexPath:indexPath];
    if (!cell ||
        cell.model.type == HXPhotoModelMediaTypeCamera ||
        cell.model.type == HXPhotoModelMediaTypeLimit ||
        cell.model.isICloud) {
        return nil;
    }
    if (cell.model.networkPhotoUrl) {
        if (cell.model.downloadError) {
            return nil;
        }
        if (!cell.model.downloadComplete) {
            return nil;
        }
    }
    HXPhotoModel *_model = cell.model;
    HXPhoto3DTouchViewController *vc = [[HXPhoto3DTouchViewController alloc] init];
    vc.model = _model;
    vc.indexPath = indexPath;
    vc.image = cell.imageView.image;
    vc.modalPresentationCapturesStatusBarAppearance = YES;
    HXWeakSelf
    vc.downloadImageComplete = ^(HXPhoto3DTouchViewController *vc, HXPhotoModel *model) {
        if (!model.loadOriginalImage) {
            HXPhotoViewCell *myCell = (HXPhotoViewCell *)[weakSelf.collectionView cellForItemAtIndexPath:vc.indexPath];
            if (myCell) {
                [myCell resetNetworkImage];
            }
        }
    };
    vc.preferredContentSize = _model.previewViewSize;
    return vc;
}
- (UIViewController *)previewingContext:(id<UIViewControllerPreviewing>)previewingContext viewControllerForLocation:(CGPoint)location {
    NSIndexPath *indexPath = [self.collectionView indexPathForItemAtPoint:location];
    if (!indexPath) {
        return nil;
    }
    if (![[self.collectionView cellForItemAtIndexPath:indexPath] isKindOfClass:[HXPhotoViewCell class]]) {
        return nil;
    }
    HXPhotoViewCell *cell = (HXPhotoViewCell *)[self.collectionView cellForItemAtIndexPath:indexPath];
    if (!cell ||
        cell.model.type == HXPhotoModelMediaTypeCamera ||
        cell.model.type == HXPhotoModelMediaTypeLimit ||
        cell.model.isICloud) {
        return nil;
    }
    if (cell.model.networkPhotoUrl) {
        if (cell.model.downloadError) {
            return nil;
        }
        if (!cell.model.downloadComplete) {
            return nil;
        }
    }
    //设置突出区域
    previewingContext.sourceRect = [self.collectionView cellForItemAtIndexPath:indexPath].frame;
    return  [self previewViewControlerWithIndexPath:indexPath];
}
- (void)previewingContext:(id<UIViewControllerPreviewing>)previewingContext commitViewController:(UIViewController *)viewControllerToCommit {
    [self pushPreviewControler:viewControllerToCommit];
}
- (void)pushPreviewControler:(UIViewController *)viewController {
    HXPhoto3DTouchViewController *vc = (HXPhoto3DTouchViewController *)viewController;
    HXPhotoViewCell *cell = (HXPhotoViewCell *)[self.collectionView cellForItemAtIndexPath:vc.indexPath];
    if (!self.manager.configuration.singleSelected) {
        HXPhotoPreviewViewController *previewVC = [[HXPhotoPreviewViewController alloc] init];
        if (HX_IOS9Earlier) {
            previewVC.photoViewController = self;
        }
        previewVC.delegate = self;
        previewVC.modelArray = self.previewArray;
        previewVC.manager = self.manager;
#if HasSDWebImage
        cell.model.tempImage = vc.sdImageView.image;
#elif HasYYKitOrWebImage
        cell.model.tempImage = vc.animatedImageView.image;
#else
        cell.model.tempImage = vc.imageView.image;
#endif
        NSInteger currentIndex = [self.previewArray indexOfObject:cell.model];
        previewVC.currentModelIndex = currentIndex;
        self.navigationController.delegate = previewVC;
        [self.navigationController pushViewController:previewVC animated:NO];
    }else {
        if (!self.manager.configuration.singleJumpEdit) {
            HXPhotoPreviewViewController *previewVC = [[HXPhotoPreviewViewController alloc] init];
            if (HX_IOS9Earlier) {
                previewVC.photoViewController = self;
            }
            previewVC.delegate = self;
            previewVC.modelArray = self.previewArray;
            previewVC.manager = self.manager;
#if HasSDWebImage
            cell.model.tempImage = vc.sdImageView.image;
#elif HasYYKitOrWebImage
            cell.model.tempImage = vc.animatedImageView.image;
#else
            cell.model.tempImage = vc.imageView.image;
#endif
            NSInteger currentIndex = [self.previewArray indexOfObject:cell.model];
            previewVC.currentModelIndex = currentIndex;
            self.navigationController.delegate = previewVC;
            [self.navigationController pushViewController:previewVC animated:NO];
        }else {
            if (cell.model.subType == HXPhotoModelMediaSubTypePhoto) {
                if (self.manager.configuration.useWxPhotoEdit) {
//                    HX_PhotoEditViewController *vc = [[HX_PhotoEditViewController alloc] initWithConfiguration:self.manager.configuration.photoEditConfigur];
//                    vc.photoModel = cell.model;
//                    vc.delegate = self;
//                    vc.onlyCliping = YES;
//                    vc.modalPresentationStyle = UIModalPresentationOverFullScreen;
//                    vc.modalPresentationCapturesStatusBarAppearance = YES;
//                    [self presentViewController:vc animated:NO completion:nil];
                }else {
                    HXPhotoEditViewController *vc = [[HXPhotoEditViewController alloc] init];
                    vc.model = cell.model;
                    vc.delegate = self;
                    vc.manager = self.manager;
                    vc.modalPresentationStyle = UIModalPresentationOverFullScreen;
                    vc.modalPresentationCapturesStatusBarAppearance = YES;
                    [self presentViewController:vc animated:NO completion:nil];
                }
            }else {
                HXPhotoPreviewViewController *previewVC = [[HXPhotoPreviewViewController alloc] init];
                if (HX_IOS9Earlier) {
                    previewVC.photoViewController = self;
                }
                previewVC.delegate = self;
                previewVC.modelArray = self.previewArray;
                previewVC.manager = self.manager;
#if HasSDWebImage
                cell.model.tempImage = vc.sdImageView.image;
#elif HasYYKitOrWebImage
                cell.model.tempImage = vc.animatedImageView.image;
#else
                cell.model.tempImage = vc.imageView.image;
#endif
                NSInteger currentIndex = [self.previewArray indexOfObject:cell.model];
                previewVC.currentModelIndex = currentIndex;
                self.navigationController.delegate = previewVC;
                [self.navigationController pushViewController:previewVC animated:NO];
            }
        }
    }
}
#pragma mark - < HXPhotoViewCellDelegate >
- (void)photoViewCellRequestICloudAssetComplete:(HXPhotoViewCell *)cell {
    if (cell.model.dateCellIsVisible) {
        NSIndexPath *indexPath = [NSIndexPath indexPathForItem:[self dateItem:cell.model] inSection:0];
        if (indexPath) {
            [self.collectionView reloadItemsAtIndexPaths:@[indexPath]];
        }
        [self.manager addICloudModel:cell.model];
    }
}
- (void)photoViewCell:(HXPhotoViewCell *)cell didSelectBtn:(UIButton *)selectBtn {
    if (selectBtn.selected) {
        if (cell.model.type != HXPhotoModelMediaTypeCameraVideo &&
            cell.model.type != HXPhotoModelMediaTypeCameraPhoto) {
            cell.model.thumbPhoto = nil;
            cell.model.previewPhoto = nil;
        }
        [self.manager beforeSelectedListdeletePhotoModel:cell.model];
        cell.model.selectIndexStr = @"";
        cell.selectMaskLayer.hidden = YES;
        selectBtn.selected = NO;
    }else {
        if (self.manager.shouldSelectModel) {
            NSString *str = self.manager.shouldSelectModel(cell.model);
            if (str) {
                [self.view hx_showImageHUDText: [NSBundle hx_localizedStringForKey:str]];
                return;
            }
        }
        NSString *str = [self.manager maximumOfJudgment:cell.model];
        if (str) {
            if ([str isEqualToString:@"selectVideoBeyondTheLimitTimeAutoEdit"]) {
                [self jumpVideoEditWithModel:cell.model];
            }else {
                [self.view hx_showImageHUDText:str];
            }
            return;
        }
        if (cell.model.type != HXPhotoModelMediaTypeCameraVideo &&
            cell.model.type != HXPhotoModelMediaTypeCameraPhoto) {
            cell.model.thumbPhoto = cell.imageView.image;
            cell.model.previewPhoto = cell.imageView.image;
        }
        [self.manager beforeSelectedListAddPhotoModel:cell.model];
        cell.selectMaskLayer.hidden = NO;
        selectBtn.selected = YES;
        [selectBtn setTitle:cell.model.selectIndexStr forState:UIControlStateSelected];
        CAKeyframeAnimation *anim = [CAKeyframeAnimation animationWithKeyPath:@"transform.scale"];
        anim.duration = 0.25;
        anim.values = @[@(1.2),@(0.8),@(1.1),@(0.9),@(1.0)];
        [selectBtn.layer addAnimation:anim forKey:@""];
    }
    
    NSMutableArray *indexPathList = [NSMutableArray array];
    if (!selectBtn.selected) {
        for (HXPhotoModel *model in [self.manager selectedArray]) {
            if (model.currentAlbumIndex == self.albumModel.index) {
                if (model.dateCellIsVisible) {
                    NSIndexPath *indexPath = [NSIndexPath indexPathForItem:[self dateItem:model] inSection:0];
                    HXPhotoViewCell *cell = (HXPhotoViewCell *)[self.collectionView cellForItemAtIndexPath:indexPath];
                    if (cell && ![cell.selectBtn.currentTitle isEqualToString:model.selectIndexStr] &&
                        ![indexPathList containsObject:indexPath]) {
                        [indexPathList addObject:indexPath];
                    }
                }
            }
        }
    }
    [indexPathList addObjectsFromArray:[self getVisibleVideoCellIndexPathsWithCurrentIndexPaths:indexPathList]];
    if (indexPathList.count) {
        [self.collectionView reloadItemsAtIndexPaths:indexPathList];
    }
    
    self.bottomView.selectCount = [self.manager selectedCount];
    if ([self.delegate respondsToSelector:@selector(photoViewControllerDidChangeSelect:selected:)]) {
        [self.delegate photoViewControllerDidChangeSelect:cell.model selected:selectBtn.selected];
    }
}
#pragma mark - < HXPhotoPreviewViewControllerDelegate >
- (void)photoPreviewCellDownloadImageComplete:(HXPhotoPreviewViewController *)previewController model:(HXPhotoModel *)model {
    if (model.dateCellIsVisible && !model.loadOriginalImage) {
        NSIndexPath *indexPath = [NSIndexPath indexPathForItem:[self dateItem:model] inSection:0];
        HXPhotoViewCell *cell = (HXPhotoViewCell *)[self.collectionView cellForItemAtIndexPath:indexPath];
        if (cell) {
            [cell resetNetworkImage];
        }
    }
}
- (void)photoPreviewDownLoadICloudAssetComplete:(HXPhotoPreviewViewController *)previewController model:(HXPhotoModel *)model {
    if (model.iCloudRequestID) {
        [[PHImageManager defaultManager] cancelImageRequest:model.iCloudRequestID];
    }
    if (model.dateCellIsVisible) {
        NSIndexPath *indexPath = [NSIndexPath indexPathForItem:[self dateItem:model] inSection:0];
        [self.collectionView reloadItemsAtIndexPaths:@[indexPath]];
    }
    [self.manager addICloudModel:model];
}
- (void)photoPreviewControllerDidSelect:(HXPhotoPreviewViewController *)previewController model:(HXPhotoModel *)model {
    NSMutableArray *indexPathList = [NSMutableArray array];
    if (model.currentAlbumIndex == self.albumModel.index) {
        [indexPathList addObject:[NSIndexPath indexPathForItem:[self dateItem:model] inSection:0]];
    }
    if (!model.selected) {
        NSInteger index = 0;
        for (HXPhotoModel *subModel in [self.manager selectedArray]) {
            if (subModel.currentAlbumIndex == self.albumModel.index && subModel.dateCellIsVisible) {
                NSIndexPath *indexPath = [NSIndexPath indexPathForItem:[self dateItem:subModel] inSection:0];
                HXPhotoViewCell *cell = (HXPhotoViewCell *)[self.collectionView cellForItemAtIndexPath:indexPath];
                if (cell && ![cell.selectBtn.currentTitle isEqualToString:model.selectIndexStr] &&
                    ![indexPathList containsObject:indexPath]) {
                    [indexPathList addObject:indexPath];
                }
            }
            index++;
        }
    }
    [indexPathList addObjectsFromArray:[self getVisibleVideoCellIndexPathsWithCurrentIndexPaths:indexPathList]];
    if (indexPathList.count) {
        [self.collectionView reloadItemsAtIndexPaths:indexPathList];
    }
    
    self.bottomView.selectCount = [self.manager selectedCount];
    if ([self.delegate respondsToSelector:@selector(photoViewControllerDidChangeSelect:selected:)]) {
        [self.delegate photoViewControllerDidChangeSelect:model selected:model.selected];
    }
}
- (void)photoPreviewControllerDidDone:(HXPhotoPreviewViewController *)previewController {
    [self photoBottomViewDidDoneBtn];
}
- (void)photoPreviewDidEditClick:(HXPhotoPreviewViewController *)previewController model:(HXPhotoModel *)model beforeModel:(HXPhotoModel *)beforeModel {
    if (model.subType == HXPhotoModelMediaSubTypePhoto) {
        if (self.manager.configuration.useWxPhotoEdit) {
            [self.collectionView reloadData];
            [self.bottomView requestPhotosBytes];
            return;
        }
    }
    model.currentAlbumIndex = self.albumModel.index;
    
    [self photoPreviewControllerDidSelect:nil model:beforeModel];
    [self collectionViewAddModel:model beforeModel:beforeModel];
    
//    [self photoBottomViewDidDoneBtn];
}
- (void)photoPreviewSingleSelectedClick:(HXPhotoPreviewViewController *)previewController model:(HXPhotoModel *)model {
    [self.manager beforeSelectedListAddPhotoModel:model];
    [self photoBottomViewDidDoneBtn];
}
#pragma mark - < HX_PhotoEditViewControllerDelegate >
- (void)photoEditingController:(HX_PhotoEditViewController *)photoEditingVC didFinishPhotoEdit:(HXPhotoEdit *)photoEdit photoModel:(HXPhotoModel *)photoModel {
    if (self.manager.configuration.singleSelected) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored"-Wdeprecated-declarations"
        [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationFade];
#pragma clang diagnostic pop
        self.isNewEditDismiss = YES;
        [self.manager beforeSelectedListAddPhotoModel:photoModel];
        [self photoBottomViewDidDoneBtn];
        return;
    }
    [self.collectionView reloadData];
    [self.bottomView requestPhotosBytes];
    if (photoEditingVC.isAutoBack) {
        return;
    }
    if (photoEditingVC.navigationController.viewControllers.count <= 1) {
        [photoEditingVC dismissViewControllerAnimated:YES completion:nil];
    }else {
        [photoEditingVC.navigationController popViewControllerAnimated:YES];
    }
}
- (void)photoEditingControllerDidCancel:(HX_PhotoEditViewController *)photoEditingVC {
    if (photoEditingVC.isAutoBack) {
        return;
    }
    if (photoEditingVC.navigationController.viewControllers.count <= 1) {
        [photoEditingVC dismissViewControllerAnimated:YES completion:nil];
    }else {
        [photoEditingVC.navigationController popViewControllerAnimated:YES];
    }
}
#pragma mark - < HXPhotoEditViewControllerDelegate >
- (void)photoEditViewControllerDidClipClick:(HXPhotoEditViewController *)photoEditViewController beforeModel:(HXPhotoModel *)beforeModel afterModel:(HXPhotoModel *)afterModel {
    if (self.manager.configuration.singleSelected) {
        [self.manager beforeSelectedListAddPhotoModel:afterModel];
        [self photoBottomViewDidDoneBtn];
        return;
    }
    [self.manager beforeSelectedListdeletePhotoModel:beforeModel];
    
    [self photoPreviewControllerDidSelect:nil model:beforeModel];
    
    afterModel.currentAlbumIndex = self.albumModel.index;
    [self.manager beforeListAddCameraTakePicturesModel:afterModel];
    [self collectionViewAddModel:afterModel beforeModel:beforeModel];
}
#pragma mark - < HXVideoEditViewControllerDelegate >
- (void)videoEditViewControllerDidDoneClick:(HXVideoEditViewController *)videoEditViewController beforeModel:(HXPhotoModel *)beforeModel afterModel:(HXPhotoModel *)afterModel {
    [self photoEditViewControllerDidClipClick:nil beforeModel:beforeModel afterModel:afterModel];
    if (afterModel.needHideSelectBtn && !self.manager.configuration.singleSelected) {
        self.isNewEditDismiss = YES;
        [self.manager beforeSelectedListAddPhotoModel:afterModel];
        [self photoBottomViewDidDoneBtn];
    }
}
#pragma mark - < HXPhotoBottomViewDelegate >
- (void)photoBottomViewDidPreviewBtn {
    if (self.navigationController.topViewController != self || [self.manager selectedCount] == 0) {
        return;
    }
    HXPhotoPreviewViewController *previewVC = [[HXPhotoPreviewViewController alloc] init];
    if (HX_IOS9Earlier) {
        previewVC.photoViewController = self;
    }
    previewVC.delegate = self;
    previewVC.modelArray = [NSMutableArray arrayWithArray:[self.manager selectedArray]];
    previewVC.manager = self.manager;
    previewVC.currentModelIndex = 0;
    previewVC.selectPreview = YES;
    self.navigationController.delegate = previewVC;
    [self.navigationController pushViewController:previewVC animated:YES];
}
- (void)photoBottomViewDidDoneBtn {
    if (self.manager.configuration.requestImageAfterFinishingSelection) {
        if ([self.navigationController.viewControllers.lastObject isKindOfClass:[HXPhotoPreviewViewController class]]) {
            self.navigationController.navigationBar.userInteractionEnabled = NO;
        }
        if (self.manager.configuration.albumShowMode == HXPhotoAlbumShowModePopup) {
            if (self.manager.configuration.photoListTitleView) {
                self.navigationController.navigationItem.titleView.userInteractionEnabled = NO;
            }else {
                self.albumTitleView.userInteractionEnabled = NO;
            }
        }
        self.navigationController.viewControllers.lastObject.view.userInteractionEnabled = NO;
        [self.navigationController.viewControllers.lastObject.view hx_showLoadingHUDText:nil];
        HXWeakSelf
        BOOL requestOriginal = self.manager.original;
        if (self.manager.configuration.hideOriginalBtn) {
            requestOriginal = self.manager.configuration.requestOriginalImage;
        }
//        if (requestOriginal) {
            [self.manager.selectedArray hx_requestImageSeparatelyWithOriginal:requestOriginal completion:^(NSArray<UIImage *> * _Nullable imageArray, NSArray<HXPhotoModel *> * _Nullable errorArray) {
                if (!weakSelf) {
                    return;
                }
                [weakSelf afterFinishingGetVideoURL];
            }];
//        }else {
//            [self.manager.selectedArray hx_requestImageWithOriginal:requestOriginal completion:^(NSArray<UIImage *> * _Nullable imageArray, NSArray<HXPhotoModel *> * _Nullable errorArray) {
//                if (!weakSelf) {
//                    return;
//                }
//                [weakSelf afterFinishingGetVideoURL];
//            }];
//        }
        return;
    }
    [self dismissVC];
}
- (void)afterFinishingGetVideoURL {
    NSArray *videoArray = self.manager.selectedVideoArray;
    if (videoArray.count) {
        BOOL requestOriginal = self.manager.original;
        if (self.manager.configuration.hideOriginalBtn) {
            requestOriginal = self.manager.configuration.requestOriginalImage;
        }
        HXWeakSelf
        __block NSInteger videoCount = videoArray.count;
        __block NSInteger videoIndex = 0;
        BOOL endOriginal = self.manager.configuration.exportVideoURLForHighestQuality ? requestOriginal : NO;
        for (HXPhotoModel *pm in videoArray) {
            [pm exportVideoWithPresetName:endOriginal ? AVAssetExportPresetHighestQuality : AVAssetExportPresetMediumQuality startRequestICloud:nil iCloudProgressHandler:nil exportProgressHandler:nil success:^(NSURL * _Nullable videoURL, HXPhotoModel * _Nullable model) {
                if (!weakSelf) {
                    return;
                }
                videoIndex++;
                if (videoIndex == videoCount) {
                    [weakSelf dismissVC];
                }
            } failed:^(NSDictionary * _Nullable info, HXPhotoModel * _Nullable model) {
                if (!weakSelf) {
                    return;
                }
                videoIndex++;
                if (videoIndex == videoCount) {
                    [weakSelf dismissVC];
                }
            }];
        }
    }else {
        [self dismissVC];
    }
}
- (void)dismissVC {
    [self.manager selectedListTransformAfter];
    if (self.manager.configuration.albumShowMode == HXPhotoAlbumShowModePopup) {
        if (self.manager.configuration.photoListChangeTitleViewSelected) {
            self.manager.configuration.photoListChangeTitleViewSelected(NO);
        }
        if (self.manager.configuration.photoListTitleView) {
            self.navigationItem.titleView.userInteractionEnabled = YES;
        }else {
            self.albumTitleView.userInteractionEnabled = YES;
        }
    }
    self.navigationController.navigationBar.userInteractionEnabled = YES;
    self.navigationController.viewControllers.lastObject.view.userInteractionEnabled = YES;
    [self.navigationController.viewControllers.lastObject.view hx_handleLoading];
    [self cleanSelectedList];
    if (self.manager.configuration.singleSelected) {
        [self.manager clearSelectedList];
    }
    self.manager.selectPhotoing = NO;
    BOOL selectPhotoFinishDismissAnimated = self.manager.selectPhotoFinishDismissAnimated;
    if (self.isNewEditDismiss || [self.presentedViewController isKindOfClass:[HX_PhotoEditViewController class]] || [self.presentedViewController isKindOfClass:[HXVideoEditViewController class]]) {
        [self.presentingViewController dismissViewControllerAnimated:selectPhotoFinishDismissAnimated completion:^{
            if ([self.delegate respondsToSelector:@selector(photoViewControllerFinishDismissCompletion:)]) {
                [self.delegate photoViewControllerFinishDismissCompletion:self];
            }
        }];
    }else {
        [self dismissViewControllerAnimated:selectPhotoFinishDismissAnimated completion:^{
            if ([self.delegate respondsToSelector:@selector(photoViewControllerFinishDismissCompletion:)]) {
                [self.delegate photoViewControllerFinishDismissCompletion:self];
            }
        }];
    }
}
- (void)photoBottomViewDidEditBtn {
    HXPhotoModel *model = self.manager.selectedArray.firstObject;
    if (model.networkPhotoUrl) {
        if (model.downloadError) {
            [self.view hx_showImageHUDText:[NSBundle hx_localizedStringForKey:@"下载失败"]];
            return;
        }
        if (!model.downloadComplete) {
            [self.view hx_showImageHUDText:[NSBundle hx_localizedStringForKey:@"照片正在下载"]];
            return;
        }
    }
    if (model.type == HXPhotoModelMediaTypePhotoGif ||
        model.cameraPhotoType == HXPhotoModelMediaTypeCameraPhotoTypeNetWorkGif) {
        if (model.photoEdit) {
            [self jumpEditViewControllerWithModel:model];
        }else {
            HXWeakSelf
            hx_showAlert(self, [NSBundle hx_localizedStringForKey:@"编辑后，GIF将会变为静态图，确定继续吗？"], nil, [NSBundle hx_localizedStringForKey:@"取消"], [NSBundle hx_localizedStringForKey:@"确定"], nil, ^{
                [weakSelf jumpEditViewControllerWithModel:model];
            });
        }
        return;
    }
    if (model.type == HXPhotoModelMediaTypeLivePhoto) {
        if (model.photoEdit) {
            [self jumpEditViewControllerWithModel:model];
        }else {
            HXWeakSelf
            hx_showAlert(self, [NSBundle hx_localizedStringForKey:@"编辑后，LivePhoto将会变为静态图，确定继续吗？"], nil, [NSBundle hx_localizedStringForKey:@"取消"], [NSBundle hx_localizedStringForKey:@"确定"], nil, ^{
                [weakSelf jumpEditViewControllerWithModel:model];
            });
        }
        return;
    }
    [self jumpEditViewControllerWithModel:model];
}
- (void)jumpEditViewControllerWithModel:(HXPhotoModel *)model {
    if (model.subType == HXPhotoModelMediaSubTypePhoto) {
        if (self.manager.configuration.replacePhotoEditViewController) {
#pragma mark - < 替换图片编辑 >
            if (self.manager.configuration.shouldUseEditAsset) {
                self.manager.configuration.shouldUseEditAsset(self, NO,self.manager, model);
            }
            HXWeakSelf
            self.manager.configuration.usePhotoEditComplete = ^(HXPhotoModel *beforeModel, HXPhotoModel *afterModel) {
                [weakSelf photoEditViewControllerDidClipClick:nil beforeModel:beforeModel afterModel:afterModel];
            };
        }else {
            if (self.manager.configuration.useWxPhotoEdit) {
                HX_PhotoEditViewController *vc = [[HX_PhotoEditViewController alloc] initWithConfiguration:self.manager.configuration.photoEditConfigur];
                vc.photoModel = self.manager.selectedPhotoArray.firstObject;
                vc.delegate = self;
                vc.supportRotation = YES;
                vc.modalPresentationStyle = UIModalPresentationOverFullScreen;
                vc.modalPresentationCapturesStatusBarAppearance = YES;
                [self presentViewController:vc animated:YES completion:nil];
            }else {
                HXPhotoEditViewController *vc = [[HXPhotoEditViewController alloc] init];
                vc.isInside = YES;
                vc.model = self.manager.selectedPhotoArray.firstObject;
                vc.delegate = self;
                vc.manager = self.manager;
                vc.modalPresentationStyle = UIModalPresentationOverFullScreen;
                vc.modalPresentationCapturesStatusBarAppearance = YES;
                [self presentViewController:vc animated:YES completion:nil];
            }
        }
    }else if (model.subType == HXPhotoModelMediaSubTypeVideo) {
        if (self.manager.configuration.replaceVideoEditViewController) {
#pragma mark - < 替换视频编辑 >
            if (self.manager.configuration.shouldUseEditAsset) {
                self.manager.configuration.shouldUseEditAsset(self, NO, self.manager, model);
            }
            HXWeakSelf
            self.manager.configuration.useVideoEditComplete = ^(HXPhotoModel *beforeModel, HXPhotoModel *afterModel) {
                [weakSelf photoEditViewControllerDidClipClick:nil beforeModel:beforeModel afterModel:afterModel];
            };
        }else {
            [self jumpVideoEditWithModel:self.manager.selectedVideoArray.firstObject];
        }
    }
}
- (void)jumpVideoEditWithModel:(HXPhotoModel *)model {
    HXVideoEditViewController *vc = [[HXVideoEditViewController alloc] init];
    vc.model = model;
    vc.delegate = self;
    vc.manager = self.manager;
    vc.isInside = YES;
    vc.modalPresentationStyle = UIModalPresentationOverFullScreen;
    vc.modalPresentationCapturesStatusBarAppearance = YES;
    [self presentViewController:vc animated:YES completion:nil];
}
- (void)cleanSelectedList {
    NSArray *allList;
    NSArray *photoList;
    NSArray *videoList;
    BOOL isOriginal;
    if (!self.manager.configuration.singleSelected) {
        allList = self.manager.afterSelectedArray.copy;
        photoList = self.manager.afterSelectedPhotoArray.copy;
        videoList = self.manager.afterSelectedVideoArray.copy;
        isOriginal = self.manager.afterOriginal;
    }else {
        allList = self.manager.selectedArray.copy;
        photoList = self.manager.selectedPhotoArray.copy;
        videoList = self.manager.selectedVideoArray.copy;
        isOriginal = self.manager.original;
    }
    if ([self.delegate respondsToSelector:@selector(photoViewController:didDoneAllList:photos:videos:original:)]) {
        [self.delegate photoViewController:self
                                didDoneAllList:allList
                                        photos:photoList
                                        videos:videoList
                                      original:isOriginal];
    }
    if ([self.delegate respondsToSelector:@selector(photoViewController:didDoneWithResult:)]) {
        HXPickerResult *result = [[HXPickerResult alloc] initWithModels:allList isOriginal:isOriginal];
        [self.delegate photoViewController:self
                         didDoneWithResult:result];
    }
    if (self.doneBlock) {
        self.doneBlock(allList, photoList, videoList, isOriginal, self, self.manager);
    } 
}
#pragma mark - < 懒加载 >
- (UILabel *)authorizationLb {
    if (!_authorizationLb) {
        _authorizationLb = [[UILabel alloc] initWithFrame:CGRectMake(0, 200, self.view.hx_w, 100)];
        _authorizationLb.text = [NSBundle hx_localizedStringForKey:@"无法访问照片\n请点击这里前往设置中允许访问照片"];
        _authorizationLb.textAlignment = NSTextAlignmentCenter;
        _authorizationLb.numberOfLines = 0;
        UIColor *authorizationColor = self.manager.configuration.authorizationTipColor;
        _authorizationLb.textColor = [HXPhotoCommon photoCommon].isDark ? [UIColor whiteColor] : authorizationColor;
        _authorizationLb.font = [UIFont systemFontOfSize:15];
        _authorizationLb.userInteractionEnabled = YES;
        [_authorizationLb addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(goSetup)]];
    }
    return _authorizationLb;
}
- (void)goSetup {
    NSURL *url = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
    if (@available(iOS 10.0, *)) {
        [[UIApplication sharedApplication] openURL:url options:@{} completionHandler:nil];
    }else {
        [[UIApplication sharedApplication] openURL:url];
    }
}
- (UIView *)albumBgView {
    if (!_albumBgView) {
        _albumBgView = [[UIView alloc] initWithFrame:self.view.bounds];
        _albumBgView.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.5f];
        [_albumBgView addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(didAlbumBgViewClick)]];
        _albumBgView.hidden = YES;
    }
    return _albumBgView;
}
- (void)didAlbumBgViewClick {
    if (self.manager.configuration.photoListChangeTitleViewSelected) {
        self.manager.configuration.photoListChangeTitleViewSelected(NO);
    }else {
        [self.albumTitleView deSelect];
    }
}
- (HXAlbumlistView *)albumView {
    if (!_albumView) {
        _albumView = [[HXAlbumlistView alloc] initWithManager:self.manager];
        HXWeakSelf
        _albumView.didSelectRowBlock = ^(HXAlbumModel *model) {
            [weakSelf.hx_customNavigationController clearAssetCache];
            if (weakSelf.manager.configuration.photoListChangeTitleViewSelected) {
                weakSelf.manager.configuration.photoListChangeTitleViewSelected(NO);
                [weakSelf albumTitleViewDidAction:NO];
            }else {
                [weakSelf.albumTitleView deSelect];
            }
            if (weakSelf.albumModel == model ||
                [weakSelf.albumModel.localIdentifier isEqualToString:model.localIdentifier]) {
                return;
            }
            weakSelf.albumModel = model;
            if (weakSelf.manager.configuration.updatePhotoListTitle) {
                weakSelf.manager.configuration.updatePhotoListTitle(model.albumName);
            }else {
                weakSelf.albumTitleView.model = model;
            }
            [weakSelf.hx_customNavigationController.view hx_showLoadingHUDText:nil];
            weakSelf.collectionViewReloadCompletion = NO;
            weakSelf.firstOn = NO;
            [weakSelf startGetAllPhotoModel];
        };
    }
    return _albumView;
}
- (HXAlbumTitleView *)albumTitleView {
    if (!_albumTitleView) {
        _albumTitleView = [[HXAlbumTitleView alloc] initWithManager:self.manager];
        HXWeakSelf
        _albumTitleView.didTitleViewBlock = ^(BOOL selected) {
            [weakSelf albumTitleViewDidAction:selected];
        };
    }
    return _albumTitleView;
}
- (void)albumTitleViewDidAction:(BOOL)selected {
    if (!self.albumView.albumModelArray.count) {
        return;
    }
    if (selected) {
        if (!self.firstDidAlbumTitleView) {
            HXAlbumModel *albumMd = self.albumView.albumModelArray.firstObject;
            if (albumMd.realCount != self.photoCount + self.videoCount) {
                albumMd.realCount = self.photoCount + self.videoCount;
                HXPhotoModel *photoModel = self.previewArray.lastObject;
                albumMd.realCoverAsset = photoModel.asset;
                albumMd.needReloadCount = YES;
            }
            [self.albumView refreshCamearCount];
            self.firstDidAlbumTitleView = YES;
        }else {
            BOOL needReload = self.albumModel.realCount != self.photoCount + self.videoCount;
            if (!needReload && self.albumModel.realCount == 0) {
                needReload = YES;
            }
            if (needReload) {
                self.albumModel.realCount = self.photoCount + self.videoCount;
                HXPhotoModel *photoModel = self.previewArray.lastObject;
                self.albumModel.realCoverAsset = photoModel.asset;
                self.albumModel.needReloadCount = YES;
                [self.albumView reloadAlbumAssetCountWithAlbumModel:self.albumModel];
            }
        }
        self.albumBgView.hidden = NO;
        self.albumBgView.alpha = 0;
        UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
        CGFloat navBarHeight = hxNavigationBarHeight;
        if (orientation == UIInterfaceOrientationPortrait || orientation == UIInterfaceOrientationPortraitUpsideDown || HX_UI_IS_IPAD) {
            navBarHeight = hxNavigationBarHeight;
        }else if (orientation == UIInterfaceOrientationLandscapeRight || orientation == UIInterfaceOrientationLandscapeLeft){
            if ([UIApplication sharedApplication].statusBarHidden) {
                navBarHeight = self.navigationController.navigationBar.hx_h;
            }else {
                navBarHeight = self.navigationController.navigationBar.hx_h + 20;
            }
        }
        [self.albumView selectCellScrollToCenter];
        if (self.manager.configuration.singleSelected) {
            [UIView animateWithDuration:0.1 delay:0.15 options:0 animations:^{
                self.albumView.alpha = 1;
            } completion:nil];
        }
        [UIView animateWithDuration:0.25 animations:^{
            self.albumBgView.alpha = 1;
            self.albumView.hx_y = navBarHeight;
        }];
    }else {
        if (self.manager.configuration.singleSelected) {
            [UIView animateWithDuration:0.1 animations:^{
                self.albumView.alpha = 0;
            }];
        }
        [UIView animateWithDuration:0.25 animations:^{
            self.albumBgView.alpha = 0;
            self.albumView.hx_y = -CGRectGetMaxY(self.albumView.frame);
        } completion:^(BOOL finished) {
            if (!selected) {
                self.albumBgView.hidden = YES;
            }
        }];
    }
}
- (HXPhotoLimitView *)limitView {
    if (!_limitView) {
        CGFloat y = self.view.hx_h - hxBottomMargin - 15 - 40;
        if (!self.manager.configuration.singleSelected) {
            y = self.view.hx_h - self.bottomView.hx_h - 10 - 40;
        }
        _limitView = [[HXPhotoLimitView alloc] initWithFrame:CGRectMake(12, y, self.view.hx_w - 24, 40)];
        [_limitView setBlurEffectStyle:self.manager.configuration.photoListLimitBlurStyle];
        [_limitView setTextColor:self.manager.configuration.photoListLimitTextColor];
        [_limitView setSettingColor:self.manager.configuration.photoListLimitSettingColor];
        [_limitView setCloseColor:self.manager.configuration.photoListLimitCloseColor];
    }
    return _limitView;
}
- (HXPhotoBottomView *)bottomView {
    if (!_bottomView) {
        _bottomView = [[HXPhotoBottomView alloc] initWithFrame:CGRectMake(0, self.view.hx_h - 50 - hxBottomMargin, self.view.hx_w, 50 + hxBottomMargin)];
        _bottomView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        _bottomView.manager = self.manager;
        _bottomView.delegate = self;
    }
    return _bottomView;
}
- (UICollectionView *)collectionView {
    if (!_collectionView) {
        CGFloat collectionHeight = self.view.hx_h;
        _collectionView = [[UICollectionView alloc] initWithFrame:CGRectMake(0, 0, self.view.hx_w, collectionHeight) collectionViewLayout:self.flowLayout];
        _collectionView.dataSource = self;
        _collectionView.delegate = self;
        _collectionView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        _collectionView.alwaysBounceVertical = YES;
        [_collectionView registerClass:[HXPhotoViewCell class] forCellWithReuseIdentifier:@"HXPhotoViewCellID"];
        [_collectionView registerClass:[HXPhotoCameraViewCell class] forCellWithReuseIdentifier:@"HXPhotoCameraViewCellId"];
        [_collectionView registerClass:[HXPhotoLimitViewCell class] forCellWithReuseIdentifier:@"HXPhotoLimitViewCellId"];
        [_collectionView registerClass:[HXPhotoViewSectionFooterView class] forSupplementaryViewOfKind:UICollectionElementKindSectionFooter withReuseIdentifier:@"sectionFooterId"];
        
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
        _flowLayout.minimumLineSpacing = 1;
        _flowLayout.minimumInteritemSpacing = 1;
        _flowLayout.sectionInset = UIEdgeInsetsMake(0.5, 0, 0.5, 0);
    }
    return _flowLayout;
}
@end
@interface HXPhotoCameraViewCell ()
@property (strong, nonatomic) UIButton *cameraBtn;
@property (strong, nonatomic) HXCustomCameraController *cameraController;
@property (nonatomic, strong) AVCaptureVideoPreviewLayer *previewLayer;
@property (strong, nonatomic) UIVisualEffectView *effectView;
@property (strong, nonatomic) UIView *previewView;
@property (strong, nonatomic) UIImageView *tempCameraView;
@end
    
@implementation HXPhotoCameraViewCell
- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
    [super traitCollectionDidChange:previousTraitCollection];
#ifdef __IPHONE_13_0
    if (@available(iOS 13.0, *)) {
        if ([self.traitCollection hasDifferentColorAppearanceComparedToTraitCollection:previousTraitCollection]) {
            if ([HXPhotoCommon photoCommon].isDark) {
                self.cameraBtn.selected = YES;
            }else {
                self.cameraBtn.selected = self.startSession;
            }
        }
    }
#endif
}
- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setupUI];
    }
    return self;
}
- (void)setupUI  {
    self.startSession = NO;
    [self.contentView addSubview:self.previewView];
    [self.contentView addSubview:self.cameraBtn];
    if ([HXPhotoCommon photoCommon].isDark) {
        self.cameraBtn.selected = YES;
    }
}
- (void)setBgColor:(UIColor *)bgColor {
    _bgColor = bgColor;
    self.backgroundColor = bgColor;
}
- (void)setCameraImage:(UIImage *)cameraImage {
    _cameraImage = cameraImage;
    if (self.startSession) return;
    if (![UIImagePickerController isSourceTypeAvailable:
          UIImagePickerControllerSourceTypeCamera]) {
        return;
    }
    if ([AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo] != AVAuthorizationStatusAuthorized) {
        return;
    }
    if (cameraImage) {
        self.tempCameraView.image = cameraImage;
        [self.previewView addSubview:self.tempCameraView];
        [self.previewView addSubview:self.effectView];
        self.cameraSelected = YES;
        self.cameraBtn.selected = YES;
    }
}

- (void)starRunning {
    if (![UIImagePickerController isSourceTypeAvailable:
          UIImagePickerControllerSourceTypeCamera]) {
        return;
    }
    AVAuthorizationStatus authStatus = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
    if (authStatus != AVAuthorizationStatusAuthorized) {
        return;
    }
    if (self.startSession) {
        return;
    }
    self.startSession = YES;
    HXWeakSelf
    [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(BOOL granted) {
        if (granted) {
            [weakSelf initSession];
        }
    }];
}
- (void)initSession {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [self.cameraController initSeesion];
        self.previewLayer = [AVCaptureVideoPreviewLayer layerWithSession:self.cameraController.captureSession];
        HXWeakSelf
        [self.cameraController setupPreviewLayer:self.previewLayer startSessionCompletion:^(BOOL success) {
            if (!weakSelf) {
                return;
            }
            if (success) {
                [weakSelf.cameraController.captureSession startRunning];
                dispatch_async(dispatch_get_main_queue(), ^{
                    [weakSelf.previewView.layer insertSublayer:weakSelf.previewLayer atIndex:0];
                    weakSelf.previewLayer.frame = weakSelf.bounds;
                    weakSelf.cameraBtn.selected = YES;
                    if (weakSelf.tempCameraView.image) {
                        if (weakSelf.cameraSelected) {
                            [UIView animateWithDuration:0.25 animations:^{
                                weakSelf.tempCameraView.alpha = 0;
                                if (HX_IOS9Later) {
                                    [weakSelf.effectView setEffect:nil];
                                }else {
                                    weakSelf.effectView.alpha = 0;
                                }
                            } completion:^(BOOL finished) {
                                [weakSelf.tempCameraView removeFromSuperview];
                                [weakSelf.effectView removeFromSuperview];
                            }];
                        }
                    }
                });
            }
        }];
    });
}
- (void)stopRunning {
    if (![UIImagePickerController isSourceTypeAvailable:
          UIImagePickerControllerSourceTypeCamera]) {
        return;
    }
    AVAuthorizationStatus authStatus = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
    if (authStatus != AVAuthorizationStatusAuthorized) {
        return;
    }
    if (!_cameraController) {
        return;
    }
    [self.cameraController stopSession];
}
    
- (void)setModel:(HXPhotoModel *)model {
    _model = model;
    if (!model.thumbPhoto) {
        model.thumbPhoto = [UIImage hx_imageNamed:model.cameraNormalImageNamed];
    }
    if (!model.previewPhoto) {
        model.previewPhoto = [UIImage hx_imageNamed:model.cameraPreviewImageNamed];
    }
    [self.cameraBtn setImage:model.thumbPhoto forState:UIControlStateNormal];
    [self.cameraBtn setImage:model.previewPhoto forState:UIControlStateSelected];
}
- (void)layoutSubviews {
    [super layoutSubviews];
    self.cameraBtn.frame = self.bounds;
    self.previewView.frame = self.bounds;
    self.effectView.frame = self.bounds;
    self.tempCameraView.frame = self.bounds;
}
- (void)willRemoveSubview:(UIView *)subview {
    [super willRemoveSubview:subview];
    [subview.layer removeAllAnimations];
}
- (void)dealloc {
    [self stopRunning];
}
- (UIButton *)cameraBtn {
    if (!_cameraBtn) {
        _cameraBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        _cameraBtn.userInteractionEnabled = NO;
    }
    return _cameraBtn;
}
- (UIVisualEffectView *)effectView {
    if (!_effectView) {
        UIBlurEffect *effect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleLight];
        _effectView = [[UIVisualEffectView alloc] initWithEffect:effect];
    }
    return _effectView;
}
- (UIView *)previewView {
    if (!_previewView) {
        _previewView = [[UIView alloc] init];
    }
    return _previewView;
}
- (HXCustomCameraController *)cameraController {
    if (!_cameraController) {
        _cameraController = [[HXCustomCameraController alloc] init];
    }
    return _cameraController;
}
- (UIImageView *)tempCameraView {
    if (!_tempCameraView) {
        _tempCameraView = [[UIImageView alloc] init];
        _tempCameraView.contentMode = UIViewContentModeScaleAspectFill;
        _tempCameraView.clipsToBounds = YES;
    }
    return _tempCameraView;
}
@end
    
@interface HXPhotoLimitViewCell()
@property (strong, nonatomic) CAShapeLayer *lineLayer;
@property (strong, nonatomic) UILabel *textLb;
@end

@implementation HXPhotoLimitViewCell

- (CAShapeLayer *)lineLayer {
    if (!_lineLayer) {
        _lineLayer = [CAShapeLayer layer];
        _lineLayer.lineWidth = 4;
        _lineLayer.lineCap = kCALineCapRound;
        _lineLayer.fillColor = [UIColor clearColor].CGColor;
        _lineLayer.contentsScale = [UIScreen mainScreen].scale;
    }
    return _lineLayer;
}
- (UILabel *)textLb {
    if (!_textLb) {
        _textLb = [[UILabel alloc] init];
        _textLb.text = [NSBundle hx_localizedStringForKey:@"更多"];
        _textLb.textAlignment = NSTextAlignmentCenter;
        _textLb.adjustsFontSizeToFitWidth = YES;
    }
    return _textLb;
}
- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self.contentView.layer addSublayer:self.lineLayer];
        [self.contentView addSubview:self.textLb];
    }
    return self;
}
    
- (void)config {
    self.backgroundColor = [HXPhotoCommon photoCommon].isDark ? self.bgDarkColor : self.bgColor;
    self.lineLayer.strokeColor = [HXPhotoCommon photoCommon].isDark ? self.lineDarkColor.CGColor : self.lineColor.CGColor;
    self.textLb.textColor = [HXPhotoCommon photoCommon].isDark ? self.textDarkColor : self.textColor;
    self.textLb.font = self.textFont;
}
- (void)layoutSubviews {
    [super layoutSubviews];
    self.lineLayer.frame = self.bounds;
    CGFloat centerX = self.hx_w * 0.5;
    CGFloat centerY = (self.hx_h - 20) * 0.5;
    CGFloat margin = 12.5;
    self.textLb.hx_x = 0;
    self.textLb.hx_y = centerY + 23;
    self.textLb.hx_w = self.hx_w;
    self.textLb.hx_h = [self.textLb hx_getTextHeight];
    
    UIBezierPath *path = [UIBezierPath bezierPath];
    
    [path moveToPoint:CGPointMake(centerX - margin, centerY)];
    [path addLineToPoint:CGPointMake(centerX + margin, centerY)];
    
    [path moveToPoint:CGPointMake(centerX, centerY - margin)];
    [path addLineToPoint:CGPointMake(centerX, centerY + margin)];
    
    self.lineLayer.path = path.CGPath;
}
    
- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
    [super traitCollectionDidChange:previousTraitCollection];

#ifdef __IPHONE_13_0
    if (@available(iOS 13.0, *)) {
        if ([self.traitCollection hasDifferentColorAppearanceComparedToTraitCollection:previousTraitCollection]) {
            [self config];
        }
    }
#endif
}
    
@end
    
@interface HXPhotoViewCell ()
@property (strong, nonatomic) UIImageView *imageView;
@property (strong, nonatomic) UIView *maskView;
@property (copy, nonatomic) NSString *localIdentifier;
@property (assign, nonatomic) PHImageRequestID requestID;
@property (assign, nonatomic) PHImageRequestID iCloudRequestID;
@property (strong, nonatomic) UILabel *stateLb;
@property (strong, nonatomic) CAGradientLayer *bottomMaskLayer;
@property (strong, nonatomic) UIButton *selectBtn;
@property (strong, nonatomic) UIImageView *iCloudIcon;
@property (strong, nonatomic) CALayer *iCloudMaskLayer;
@property (strong, nonatomic) HXCircleProgressView *progressView;
@property (strong, nonatomic) CALayer *videoMaskLayer;
@property (strong, nonatomic) UIView *highlightMaskView;
@property (strong, nonatomic) UIImageView *editTipIcon;
@property (strong, nonatomic) UIImageView *videoIcon;
@property (assign, nonatomic) CGFloat seletBtnNormalWidth;
@end

@implementation HXPhotoViewCell
- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
    [super traitCollectionDidChange:previousTraitCollection];

#ifdef __IPHONE_13_0
    if (@available(iOS 13.0, *)) {
        if ([self.traitCollection hasDifferentColorAppearanceComparedToTraitCollection:previousTraitCollection]) {
            self.selectMaskLayer.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.5].CGColor;

            UIColor *cellSelectedTitleColor;
            UIColor *cellSelectedBgColor;
            if ([HXPhotoCommon photoCommon].isDark) {
                cellSelectedTitleColor = self.darkSelectedTitleColor;
                cellSelectedBgColor = self.darkSelectBgColor;
            }else {
                cellSelectedTitleColor = self.selectedTitleColor;
                cellSelectedBgColor = self.selectBgColor;
            }
            if ([cellSelectedBgColor isEqual:[UIColor whiteColor]] && !cellSelectedTitleColor) {
                [self.selectBtn setTitleColor:[UIColor blackColor] forState:UIControlStateSelected];
            }else {
                [self.selectBtn setTitleColor:cellSelectedTitleColor forState:UIControlStateSelected];
            }
            self.selectBtn.tintColor = cellSelectedBgColor;
        }
    }
#endif
}
- (void)willRemoveSubview:(UIView *)subview {
    [super willRemoveSubview:subview];
    [subview.layer removeAllAnimations];
}
- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setupUI];
    }
    return self;
}
- (void)setupUI {
    [self.contentView addSubview:self.imageView];
    [self.contentView addSubview:self.maskView];
    [self.contentView addSubview:self.highlightMaskView];
    [self.contentView addSubview:self.progressView];
}
- (void)bottomViewPrepareAnimation {
    [self.maskView.layer removeAllAnimations];
    self.maskView.alpha = 0;
}
- (void)bottomViewStartAnimation {
    [UIView animateWithDuration:0.25 delay:0 options:UIViewAnimationOptionCurveEaseIn animations:^{
        self.maskView.alpha = 1;
    } completion:nil];
}
- (void)setSingleSelected:(BOOL)singleSelected {
    _singleSelected = singleSelected;
    if (singleSelected) {
        if (self.selectBtn.superview) {
            [self.selectBtn removeFromSuperview];
        }
    }
}
- (void)resetNetworkImage {
    if (self.model.networkPhotoUrl &&
        self.model.type == HXPhotoModelMediaTypeCameraPhoto) {
        self.model.loadOriginalImage = YES;
        self.model.previewViewSize = CGSizeZero;
        self.model.endImageSize = CGSizeZero;
        HXWeakSelf
        [self.imageView hx_setImageWithModel:self.model original:YES progress:nil completed:^(UIImage *image, NSError *error, HXPhotoModel *model) {
            if (weakSelf.model == model) {
                if (image.images.count) {
                    weakSelf.imageView.image = nil;
                    weakSelf.imageView.image = image.images.firstObject;
                }else {
                    weakSelf.imageView.image = image;
                }
            }
        }];
    }
}
- (void)setModel:(HXPhotoModel *)model emptyImage:(BOOL)emptyImage {
    _model = model;
    if (emptyImage) {
        self.imageView.image = nil;
    }
    self.maskView.hidden = YES;
}
- (void)setModelDataWithHighQuality:(BOOL)highQuality completion:(void (^)(HXPhotoViewCell *))completion {
    HXPhotoModel *model = self.model;
    self.videoIcon.hidden = YES;
    self.editTipIcon.hidden = model.photoEdit ? NO : YES;
    self.progressView.hidden = YES;
    self.progressView.progress = 0;
    self.maskView.hidden = !self.imageView.image;
    self.localIdentifier = model.asset.localIdentifier;
    if (model.photoEdit) {
        self.imageView.image = model.photoEdit.editPreviewImage;
        self.maskView.hidden = NO;
        if (completion) {
            completion(self);
        }
        self.requestID = 0;
    }else {
        HXWeakSelf
        if (model.type == HXPhotoModelMediaTypeCamera ||
            model.type == HXPhotoModelMediaTypeCameraPhoto ||
            model.type == HXPhotoModelMediaTypeCameraVideo ||
            model.type == HXPhotoModelMediaTypeLimit) {
            if (model.thumbPhoto.images.count) {
                self.imageView.image = nil;
                self.imageView.image = model.thumbPhoto.images.firstObject;
            }else {
                self.imageView.image = model.thumbPhoto;
            }
            if (model.networkPhotoUrl) {
                CGFloat progress = (CGFloat)model.receivedSize / model.expectedSize;
                self.progressView.progress = progress;
                if (model.downloadComplete && !model.downloadError) {
                    self.maskView.hidden = NO;
                    if (model.previewPhoto.images.count) {
                        self.imageView.image = nil;
                        self.imageView.image = model.previewPhoto.images.firstObject;
                    }else {
                        self.imageView.image = model.previewPhoto;
                    }
                    if (completion) {
                        completion(self);
                    }
                }else {
                    self.progressView.hidden = NO;
                    [self.imageView hx_setImageWithModel:model original:NO progress:^(CGFloat progress, HXPhotoModel *model) {
                        if (weakSelf.model == model) {
                            weakSelf.progressView.progress = progress;
                        }
                    } completed:^(UIImage *image, NSError *error, HXPhotoModel *model) {
                        if (weakSelf.model == model) {
                            if (error != nil) {
                                [weakSelf.progressView showError];
                            }else {
                                if (image) {
                                    weakSelf.maskView.hidden = NO;
                                    if (image.images.count) {
                                        weakSelf.imageView.image = nil;
                                        weakSelf.imageView.image = image.images.firstObject;
                                    }else {
                                        weakSelf.imageView.image = image;
                                    }
                                    weakSelf.progressView.progress = 1;
                                    weakSelf.progressView.hidden = YES;
                                }
                            }
                        }
                        if (completion) {
                            completion(weakSelf);
                        }
                    }];
                }
            }else {
                self.maskView.hidden = NO;
                if (completion) {
                    completion(self);
                }
            }
            self.requestID = 0;
        }else {
            PHImageRequestID imageRequestID;
            if (highQuality) {
                imageRequestID = [self.model highQualityRequestThumbImageWithWidth:[HXPhotoCommon photoCommon].requestWidth completion:^(UIImage * _Nullable image, HXPhotoModel * _Nullable model, NSDictionary * _Nullable info) {
                    if ([[info objectForKey:PHImageCancelledKey] boolValue]) {
                        return;
                    }
                    if ([weakSelf.localIdentifier isEqualToString:model.asset.localIdentifier]) {
                        if (weakSelf.maskView.hidden) {
                            weakSelf.maskView.hidden = NO;
                        }
                        weakSelf.imageView.image = image;
                    }
                    BOOL isDegraded = [[info objectForKey:PHImageResultIsDegradedKey] boolValue];
                    if (!isDegraded) {
                        weakSelf.requestID = 0;
                    }
                    if (completion) {
                        completion(weakSelf);
                    }
                }];
            }else {
                imageRequestID = [weakSelf.model requestThumbImageCompletion:^(UIImage *image, HXPhotoModel *model, NSDictionary *info) {
                    if ([[info objectForKey:PHImageCancelledKey] boolValue]) {
                        return;
                    }
                    if ([weakSelf.localIdentifier isEqualToString:model.asset.localIdentifier]) {
                        if (weakSelf.maskView.hidden) {
                            weakSelf.maskView.hidden = NO;
                        }
                        weakSelf.imageView.image = image;
                    }
                    BOOL isDegraded = [[info objectForKey:PHImageResultIsDegradedKey] boolValue];
                    if (!isDegraded) {
                        weakSelf.requestID = 0;
                    }
                    if (completion) {
                        completion(weakSelf);
                    }
                }];
            }
            if (imageRequestID && self.requestID && imageRequestID != self.requestID) {
                [[PHImageManager defaultManager] cancelImageRequest:self.requestID];
            }
            self.requestID = imageRequestID;
        }
    }
    if (model.type == HXPhotoModelMediaTypePhotoGif && !model.photoEdit) {
        self.stateLb.text = @"GIF";
        self.stateLb.hidden = NO;
        self.bottomMaskLayer.hidden = NO;
    }else if (model.type == HXPhotoModelMediaTypeLivePhoto && !model.photoEdit) {
        self.stateLb.text = @"Live";
        self.stateLb.hidden = NO;
        self.bottomMaskLayer.hidden = NO;
    }else {
        if (model.subType == HXPhotoModelMediaSubTypeVideo) {
            self.stateLb.text = model.videoTime;
            self.stateLb.hidden = NO;
            self.videoIcon.hidden = NO;
            self.bottomMaskLayer.hidden = NO;
        }else {
            if ((model.cameraPhotoType == HXPhotoModelMediaTypeCameraPhotoTypeNetWorkGif ||
                 model.cameraPhotoType == HXPhotoModelMediaTypeCameraPhotoTypeLocalGif) && !model.photoEdit) {
                self.stateLb.text = @"GIF";
                self.stateLb.hidden = NO;
                self.bottomMaskLayer.hidden = NO;
            }else if ((model.cameraPhotoType == HXPhotoModelMediaTypeCameraPhotoTypeLocalLivePhoto ||
                       model.cameraPhotoType == HXPhotoModelMediaTypeCameraPhotoTypeNetWorkLivePhoto) && !model.photoEdit) {
                self.stateLb.text = @"Live";
                self.stateLb.hidden = NO;
                self.bottomMaskLayer.hidden = NO;
            }else {
                self.stateLb.hidden = YES;
                if (model.photoEdit) {
                    self.bottomMaskLayer.hidden = NO;
                }else {
                    self.bottomMaskLayer.hidden = YES;
                }
            }
        }
    }
    self.selectMaskLayer.hidden = !model.selected;
    self.selectBtn.selected = model.selected;
    [self.selectBtn setTitle:model.selectIndexStr forState:UIControlStateSelected];
    
    self.iCloudIcon.hidden = !model.isICloud;
    self.iCloudMaskLayer.hidden = !model.isICloud;
    
    // 当前是否需要隐藏选择按钮
    if (model.needHideSelectBtn) {
        self.selectBtn.hidden = YES;
        self.selectBtn.userInteractionEnabled = NO;
    }else {
        self.selectBtn.hidden = model.isICloud;
        self.selectBtn.userInteractionEnabled = !model.isICloud;
    }
    
    if (model.isICloud) {
        self.videoMaskLayer.hidden = YES;
    }else {
        self.videoMaskLayer.hidden = self.canSelect;
    }
    
    if (model.iCloudDownloading) {
        if (model.isICloud) {
            self.progressView.hidden = NO;
            self.highlightMaskView.hidden = NO;
            self.progressView.progress = model.iCloudProgress;
            [self startRequestICloudAsset];
        }else {
            model.iCloudDownloading = NO;
            self.progressView.hidden = YES;
            self.highlightMaskView.hidden = YES;
        }
    }else {
        self.highlightMaskView.hidden = YES;
    }
    [self setSelectBtnFrame];
}
- (void)setSelectBgColor:(UIColor *)selectBgColor {
    _selectBgColor = selectBgColor;
    if ([HXPhotoCommon photoCommon].isDark) {
        selectBgColor = self.darkSelectBgColor;
    }
    self.selectBtn.tintColor = selectBgColor;
    if ([selectBgColor isEqual:[UIColor whiteColor]] && !self.selectedTitleColor) {
        [self.selectBtn setTitleColor:[UIColor blackColor] forState:UIControlStateSelected];
    }
}
- (void)setSelectedTitleColor:(UIColor *)selectedTitleColor {
    _selectedTitleColor = selectedTitleColor;
    if ([HXPhotoCommon photoCommon].isDark) {
        selectedTitleColor = self.darkSelectedTitleColor;
    }
    [self.selectBtn setTitleColor:selectedTitleColor forState:UIControlStateSelected];
}
- (void)startRequestICloudAsset {
    self.progressView.progress = 0;
    self.iCloudIcon.hidden = YES;
    self.iCloudMaskLayer.hidden = YES;
    HXWeakSelf
    if (self.model.type == HXPhotoModelMediaTypeVideo) {
        self.iCloudRequestID = [self.model requestAVAssetStartRequestICloud:^(PHImageRequestID iCloudRequestId, HXPhotoModel *model) {
            if ([weakSelf.localIdentifier isEqualToString:model.asset.localIdentifier]) {
                weakSelf.progressView.hidden = NO;
                weakSelf.highlightMaskView.hidden = NO;
                weakSelf.iCloudRequestID = iCloudRequestId;
            }
        } progressHandler:^(double progress, HXPhotoModel *model) {
            if ([weakSelf.localIdentifier isEqualToString:model.asset.localIdentifier]) {
                weakSelf.progressView.hidden = NO;
                weakSelf.highlightMaskView.hidden = NO;
                weakSelf.progressView.progress = progress;
            }
        } success:^(AVAsset *avAsset, AVAudioMix *audioMix, HXPhotoModel *model, NSDictionary *info) {
            if ([weakSelf.localIdentifier isEqualToString:model.asset.localIdentifier]) {
                weakSelf.model.isICloud = NO;
                weakSelf.progressView.progress = 1;
                weakSelf.highlightMaskView.hidden = YES;
                weakSelf.iCloudRequestID = 0;
                if ([weakSelf.delegate respondsToSelector:@selector(photoViewCellRequestICloudAssetComplete:)]) {
                    [weakSelf.delegate photoViewCellRequestICloudAssetComplete:weakSelf];
                }
            }
        } failed:^(NSDictionary *info, HXPhotoModel *model) {
            if ([weakSelf.localIdentifier isEqualToString:model.asset.localIdentifier]) {
                [weakSelf downloadError:info];
            }
        }];
    }else if (self.model.type == HXPhotoModelMediaTypeLivePhoto){
        self.iCloudRequestID = [self.model requestLivePhotoWithSize:CGSizeMake(self.model.previewViewSize.width * 1.5, self.model.previewViewSize.height * 1.5) startRequestICloud:^(PHImageRequestID iCloudRequestId, HXPhotoModel *model) {
            if ([weakSelf.localIdentifier isEqualToString:model.asset.localIdentifier]) {
                weakSelf.progressView.hidden = NO;
                weakSelf.highlightMaskView.hidden = NO;
                weakSelf.iCloudRequestID = iCloudRequestId;
            }
        } progressHandler:^(double progress, HXPhotoModel *model) {
            if ([weakSelf.localIdentifier isEqualToString:model.asset.localIdentifier]) {
                weakSelf.progressView.hidden = NO;
                weakSelf.highlightMaskView.hidden = NO;
                weakSelf.progressView.progress = progress;
            }
        } success:^(PHLivePhoto *livePhoto, HXPhotoModel *model, NSDictionary *info) {
            if ([weakSelf.localIdentifier isEqualToString:model.asset.localIdentifier]) {
                weakSelf.model.isICloud = NO;
                weakSelf.progressView.progress = 1;
                weakSelf.highlightMaskView.hidden = YES;
                weakSelf.iCloudRequestID = 0;
                if ([weakSelf.delegate respondsToSelector:@selector(photoViewCellRequestICloudAssetComplete:)]) {
                    [weakSelf.delegate photoViewCellRequestICloudAssetComplete:weakSelf];
                }
            }
        } failed:^(NSDictionary *info, HXPhotoModel *model) {
            if ([weakSelf.localIdentifier isEqualToString:model.asset.localIdentifier]) {
                [weakSelf downloadError:info];
            }
        }];
    }else {
        self.iCloudRequestID = [self.model requestImageDataStartRequestICloud:^(PHImageRequestID iCloudRequestId, HXPhotoModel *model) {
            if ([weakSelf.localIdentifier isEqualToString:model.asset.localIdentifier]) {
                weakSelf.progressView.hidden = NO;
                weakSelf.highlightMaskView.hidden = NO;
                weakSelf.iCloudRequestID = iCloudRequestId;
            }
        } progressHandler:^(double progress, HXPhotoModel *model) {
            if ([weakSelf.localIdentifier isEqualToString:model.asset.localIdentifier]) {
                weakSelf.progressView.hidden = NO;
                weakSelf.highlightMaskView.hidden = NO;
                weakSelf.progressView.progress = progress;
            }
        } success:^(NSData *imageData, UIImageOrientation orientation, HXPhotoModel *model, NSDictionary *info) {
            if ([weakSelf.localIdentifier isEqualToString:model.asset.localIdentifier]) {
                weakSelf.model.isICloud = NO;
                weakSelf.highlightMaskView.hidden = YES;
                weakSelf.progressView.progress = 1;
                weakSelf.iCloudRequestID = 0;
                if ([weakSelf.delegate respondsToSelector:@selector(photoViewCellRequestICloudAssetComplete:)]) {
                    [weakSelf.delegate photoViewCellRequestICloudAssetComplete:weakSelf];
                }
            }
        } failed:^(NSDictionary *info, HXPhotoModel *model) {
            if ([weakSelf.localIdentifier isEqualToString:model.asset.localIdentifier]) {
                [weakSelf downloadError:info];
            }
        }];
    }
}
- (void)downloadError:(NSDictionary *)info {
    if (![[info objectForKey:PHImageCancelledKey] boolValue]) {
        [[self hx_viewController].view hx_showImageHUDText:[NSBundle hx_localizedStringForKey:@"下载失败，请重试！"]];
    }
    self.highlightMaskView.hidden = YES;
    self.progressView.hidden = YES;
    self.progressView.progress = 0;
    self.iCloudIcon.hidden = !self.model.isICloud;
    self.iCloudMaskLayer.hidden = !self.model.isICloud;
}
- (void)cancelRequest {
    if (self.requestID) {
        [[PHImageManager defaultManager] cancelImageRequest:self.requestID];
        self.requestID = 0;
    }
    if (self.iCloudRequestID) {
        [[PHImageManager defaultManager] cancelImageRequest:self.iCloudRequestID];
        self.iCloudRequestID = 0;
    }
}
- (void)didSelectClick:(UIButton *)button {
    if (self.model.type == HXPhotoModelMediaTypeCamera ||
        self.model.type == HXPhotoModelMediaTypeLimit) {
        return;
    }
    if (self.model.isICloud) {
        return;
    }
    if ([self.delegate respondsToSelector:@selector(photoViewCell:didSelectBtn:)]) {
        [self.delegate photoViewCell:self didSelectBtn:button];
    }
    [self setSelectBtnFrame];
}
- (void)setHighlighted:(BOOL)highlighted {
    [super setHighlighted:highlighted];
    self.highlightMaskView.hidden = !highlighted;
}
- (void)layoutSubviews {
    [super layoutSubviews];
    self.imageView.frame = self.bounds;
    self.maskView.frame = self.bounds;
    self.stateLb.frame = CGRectMake(0, self.hx_h - 18, self.hx_w - 7, 18);
    self.bottomMaskLayer.frame = CGRectMake(0, self.hx_h - 25, self.hx_w, 27);
    [self setSelectBtnFrame];
    self.selectMaskLayer.frame = self.bounds;
    self.iCloudMaskLayer.frame = self.bounds;
    self.iCloudIcon.hx_x = self.hx_w - 3 - self.iCloudIcon.hx_w;
    self.iCloudIcon.hx_y = 3;
    self.progressView.center = CGPointMake(self.hx_w / 2, self.hx_h / 2);
    self.videoMaskLayer.frame = self.bounds;
    self.highlightMaskView.frame = self.bounds;
    self.editTipIcon.hx_x = 7;
    self.editTipIcon.hx_y = self.hx_h - 4 - self.editTipIcon.hx_h;
    self.videoIcon.hx_x = 7;
    self.videoIcon.hx_y = self.hx_h - 4 - self.videoIcon.hx_h;
    self.stateLb.hx_centerY = self.videoIcon.hx_centerY;
}
- (void)setSelectBtnFrame {
    CGFloat textWidth = [self.selectBtn.titleLabel hx_getTextWidth];
    if (textWidth + 10 > self.seletBtnNormalWidth && self.selectBtn.selected) {
        self.selectBtn.hx_w = textWidth + 10;
    }else {
        self.selectBtn.hx_w = self.seletBtnNormalWidth;
    }
    self.selectBtn.hx_x = self.hx_w - self.selectBtn.hx_w - 5;
    self.selectBtn.hx_y = 5;
}
- (void)dealloc {
    self.delegate = nil;
    self.model.dateCellIsVisible = NO;
}
#pragma mark - < 懒加载 >
- (UIView *)highlightMaskView {
    if (!_highlightMaskView) {
        _highlightMaskView = [[UIView alloc] initWithFrame:self.bounds];
        _highlightMaskView.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.5f];
        _highlightMaskView.hidden = YES;
    }
    return _highlightMaskView;
}
- (HXCircleProgressView *)progressView {
    if (!_progressView) {
        _progressView = [[HXCircleProgressView alloc] init];
        _progressView.hidden = YES;
    }
    return _progressView;
}
- (UIImageView *)editTipIcon {
    if (!_editTipIcon) {
        _editTipIcon = [[UIImageView alloc] initWithImage:[UIImage hx_imageNamed:@"hx_photo_edit_show_tip"]];
        _editTipIcon.hx_size = _editTipIcon.image.size;
    }
    return _editTipIcon;
}
- (UIImageView *)videoIcon {
    if (!_videoIcon) {
        _videoIcon = [[UIImageView alloc] initWithImage:[UIImage hx_imageNamed:@"hx_photo_asset_video_icon"]];
        _videoIcon.hx_size = _videoIcon.image.size;
    }
    return _videoIcon;
}
- (UIImageView *)imageView {
    if (!_imageView) {
        _imageView = [[UIImageView alloc] init];
        _imageView.contentMode = UIViewContentModeScaleAspectFill;
        _imageView.clipsToBounds = YES;
    }
    return _imageView;
}
- (UIView *)maskView {
    if (!_maskView) {
        _maskView = [[UIView alloc] init];
        [_maskView.layer addSublayer:self.bottomMaskLayer];
        [_maskView.layer addSublayer:self.selectMaskLayer];
        [_maskView.layer addSublayer:self.iCloudMaskLayer];
        [_maskView addSubview:self.iCloudIcon];
        [_maskView addSubview:self.selectBtn];
        [_maskView.layer addSublayer:self.videoMaskLayer];
        [_maskView addSubview:self.stateLb];
        [_maskView addSubview:self.editTipIcon];
        [_maskView addSubview:self.videoIcon];
    }
    return _maskView;
}
- (UIImageView *)iCloudIcon {
    if (!_iCloudIcon) {
        _iCloudIcon = [[UIImageView alloc] initWithImage:[UIImage hx_imageNamed:@"hx_yunxiazai"]];
        _iCloudIcon.hx_size = _iCloudIcon.image.size;
    }
    return _iCloudIcon;
}
- (CALayer *)selectMaskLayer {
    if (!_selectMaskLayer) {
        _selectMaskLayer = [CALayer layer];
        _selectMaskLayer.hidden = YES;
        _selectMaskLayer.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.5].CGColor;
    }
    return _selectMaskLayer;
}
- (CALayer *)iCloudMaskLayer {
    if (!_iCloudMaskLayer) {
        _iCloudMaskLayer = [CALayer layer];
        _iCloudMaskLayer.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.3].CGColor;
    }
    return _iCloudMaskLayer;
}
- (CALayer *)videoMaskLayer {
    if (!_videoMaskLayer) {
        _videoMaskLayer = [CALayer layer];
        _videoMaskLayer.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:0.8].CGColor;
    }
    return _videoMaskLayer;
}
- (UILabel *)stateLb {
    if (!_stateLb) {
        _stateLb = [[UILabel alloc] init];
        _stateLb.textColor = [UIColor whiteColor];
        _stateLb.textAlignment = NSTextAlignmentRight;
        _stateLb.font = [UIFont hx_mediumSFUITextOfSize:13];
    }
    return _stateLb;
}
- (CAGradientLayer *)bottomMaskLayer {
    if (!_bottomMaskLayer) {
        _bottomMaskLayer = [CAGradientLayer layer];
        _bottomMaskLayer.colors = @[
                                    (id)[[UIColor blackColor] colorWithAlphaComponent:0].CGColor ,
                                    (id)[[UIColor blackColor] colorWithAlphaComponent:0.15].CGColor ,
                                    (id)[[UIColor blackColor] colorWithAlphaComponent:0.35].CGColor ,
                                    (id)[[UIColor blackColor] colorWithAlphaComponent:0.6].CGColor
                                    ];
        _bottomMaskLayer.startPoint = CGPointMake(0, 0);
        _bottomMaskLayer.endPoint = CGPointMake(0, 1);
        _bottomMaskLayer.locations = @[@(0.15f),@(0.35f),@(0.6f),@(0.9f)];
        _bottomMaskLayer.borderWidth  = 0.0;
    }
    return _bottomMaskLayer;
}
- (UIButton *)selectBtn {
    if (!_selectBtn) {
        _selectBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [_selectBtn setBackgroundImage:[UIImage hx_imageNamed:@"hx_compose_guide_check_box_default"] forState:UIControlStateNormal];
        UIImage *bgImage = [[UIImage hx_imageNamed:@"hx_compose_guide_check_box_selected"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        bgImage = [bgImage resizableImageWithCapInsets:UIEdgeInsetsMake(bgImage.size.width / 2, bgImage.size.width / 2, bgImage.size.width / 2, bgImage.size.width / 2) resizingMode:UIImageResizingModeStretch];
        [_selectBtn setBackgroundImage:bgImage forState:UIControlStateSelected];
        [_selectBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateSelected];
        _selectBtn.titleLabel.font = [UIFont hx_mediumPingFangOfSize:16];
        _selectBtn.hx_size = _selectBtn.currentBackgroundImage.size;
        self.seletBtnNormalWidth = _selectBtn.hx_w;
        [_selectBtn addTarget:self action:@selector(didSelectClick:) forControlEvents:UIControlEventTouchUpInside];
        [_selectBtn hx_setEnlargeEdgeWithTop:0 right:0 bottom:15 left:15];
    }
    return _selectBtn;
}
@end

@interface HXPhotoViewSectionFooterView ()
@property (strong, nonatomic) UILabel *titleLb;
@end

@implementation HXPhotoViewSectionFooterView
- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
    [super traitCollectionDidChange:previousTraitCollection];
#ifdef __IPHONE_13_0
    if (@available(iOS 13.0, *)) {
        if ([self.traitCollection hasDifferentColorAppearanceComparedToTraitCollection:previousTraitCollection]) {
            if ([HXPhotoCommon photoCommon].isDark) {
                self.backgroundColor = [UIColor colorWithRed:0.075 green:0.075 blue:0.075 alpha:1];
            }else {
                self.backgroundColor = self.bgColor;
            }
            [self setVideoCount:self.videoCount];
        }
    }
#endif
}
- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setupUI];
    }
    return self;
}
- (void)setupUI {
    if ([HXPhotoCommon photoCommon].isDark) {
        self.backgroundColor = [UIColor colorWithRed:0.075 green:0.075 blue:0.075 alpha:1];
    }else {
        self.backgroundColor = self.bgColor;
    }
    [self addSubview:self.titleLb];
}
- (void)setVideoCount:(NSInteger)videoCount {
    _videoCount = videoCount;
    UIColor *textColor = [HXPhotoCommon photoCommon].isDark ? [UIColor whiteColor] : self.textColor;
    NSDictionary *dict = @{NSFontAttributeName : [UIFont hx_mediumSFUITextOfSize:15] ,
                           NSForegroundColorAttributeName : textColor
                           };
    
    NSAttributedString *photoCountStr = [[NSAttributedString alloc] initWithString:[@(self.photoCount).stringValue hx_countStrBecomeComma] attributes:dict];
    
    NSAttributedString *videoCountStr = [[NSAttributedString alloc] initWithString:[@(videoCount).stringValue hx_countStrBecomeComma] attributes:dict];
    
    
    if (self.photoCount > 0 && videoCount > 0) {
        NSString *photoStr;
        if (self.photoCount > 1) {
            photoStr = @"Photos";
        }else {
            photoStr = @"Photo";
        }
        NSString *videoStr;
        if (videoCount > 1) {
            videoStr = @"Videos";
        }else {
            videoStr = @"Video";
        }
        NSMutableAttributedString *atbStr = [[NSMutableAttributedString alloc] init];
        NSAttributedString *photoAtbStr = [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@" %@、",[NSBundle hx_localizedStringForKey:photoStr]] attributes:dict];
        [atbStr appendAttributedString:photoCountStr];
        [atbStr appendAttributedString:photoAtbStr];
        
        NSAttributedString *videoAtbStr = [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@" %@",[NSBundle hx_localizedStringForKey:videoStr]] attributes:dict];
        [atbStr appendAttributedString:videoCountStr];
        [atbStr appendAttributedString:videoAtbStr];

        self.titleLb.attributedText = atbStr;
    }else if (self.photoCount > 0) {
        NSString *photoStr;
        if (self.photoCount > 1) {
            photoStr = @"Photos";
        }else {
            photoStr = @"Photo";
        }
        NSMutableAttributedString *atbStr = [[NSMutableAttributedString alloc] init];
        NSAttributedString *photoAtbStr = [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@" %@",[NSBundle hx_localizedStringForKey:photoStr]] attributes:dict];
        [atbStr appendAttributedString:photoCountStr];
        [atbStr appendAttributedString:photoAtbStr];
        
        
        self.titleLb.attributedText = atbStr;
    }else {
        NSString *videoStr;
        if (videoCount > 1) {
            videoStr = @"Videos";
        }else {
            videoStr = @"Video";
        }
        NSMutableAttributedString *atbStr = [[NSMutableAttributedString alloc] init];
        
        NSAttributedString *videoAtbStr = [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@" %@",[NSBundle hx_localizedStringForKey:videoStr]] attributes:dict];
        [atbStr appendAttributedString:videoCountStr];
        [atbStr appendAttributedString:videoAtbStr];
        
        self.titleLb.attributedText = atbStr;
    }
}
- (void)layoutSubviews {
    [super layoutSubviews];
    self.titleLb.frame = CGRectMake(0, 0, self.hx_w, 50);
}
- (UILabel *)titleLb {
    if (!_titleLb) {
        _titleLb = [[UILabel alloc] init];
        _titleLb.textAlignment = NSTextAlignmentCenter;
    }
    return _titleLb;
}
@end

@interface HXPhotoBottomView ()
@property (strong, nonatomic) UIButton *previewBtn;
@property (strong, nonatomic) UIButton *doneBtn;
@property (strong, nonatomic) UIButton *editBtn;
@property (strong, nonatomic) UIActivityIndicatorView *loadingView;
@property (strong, nonatomic) UIColor *barTintColor;
@end

@implementation HXPhotoBottomView
- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
    [super traitCollectionDidChange:previousTraitCollection];
#ifdef __IPHONE_13_0
    if (@available(iOS 13.0, *)) {
        if ([self.traitCollection hasDifferentColorAppearanceComparedToTraitCollection:previousTraitCollection]) {
            [self setManager:self.manager];
            [self setSelectCount:self.selectCount];
        }
    }
#endif
}
- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setupUI];
    }
    return self;
}
- (void)setupUI {
    [self addSubview:self.bgView];
    [self addSubview:self.previewBtn];
    [self addSubview:self.originalBtn];
    [self addSubview:self.doneBtn];
    [self addSubview:self.editBtn];
    [self changeDoneBtnFrame];
}
- (void)setManager:(HXPhotoManager *)manager {
    _manager = manager;
    self.bgView.translucent = manager.configuration.bottomViewTranslucent;
    self.barTintColor = manager.configuration.bottomViewBgColor;
    self.bgView.barStyle = manager.configuration.bottomViewBarStyle;
    self.originalBtn.hidden = self.manager.configuration.hideOriginalBtn;
    if (manager.type == HXPhotoManagerSelectedTypePhoto) {
        self.editBtn.hidden = !manager.configuration.photoCanEdit;
    }else if (manager.type == HXPhotoManagerSelectedTypeVideo) {
        self.editBtn.hidden = !manager.configuration.videoCanEdit;
    }else {
        if (!manager.configuration.videoCanEdit && !manager.configuration.photoCanEdit) {
            self.editBtn.hidden = YES;
        }
    }
    self.originalBtn.selected = self.manager.original;
    
    UIColor *themeColor;
    UIColor *selectedTitleColor;
    UIColor *originalBtnImageTintColor;
    if ([HXPhotoCommon photoCommon].isDark) {
        themeColor = [UIColor whiteColor];
        originalBtnImageTintColor = themeColor;
        selectedTitleColor = [UIColor whiteColor];
        self.bgView.barTintColor = [UIColor blackColor];
    }else {
        self.bgView.barTintColor = self.barTintColor;
        themeColor = self.manager.configuration.themeColor;
        if (self.manager.configuration.originalBtnImageTintColor) {
            originalBtnImageTintColor = self.manager.configuration.originalBtnImageTintColor;
        }else {
            originalBtnImageTintColor = themeColor;
        }
        if (self.manager.configuration.bottomDoneBtnTitleColor) {
            selectedTitleColor = self.manager.configuration.bottomDoneBtnTitleColor;
        }else {
            selectedTitleColor = self.manager.configuration.selectedTitleColor;
        }
    }
    
    [self.previewBtn setTitleColor:themeColor forState:UIControlStateNormal];
    [self.previewBtn setTitleColor:[themeColor colorWithAlphaComponent:0.5] forState:UIControlStateDisabled];
    
    [self.originalBtn setTitleColor:themeColor forState:UIControlStateNormal];
    [self.originalBtn setTitleColor:[themeColor colorWithAlphaComponent:0.5] forState:UIControlStateDisabled];
    
    UIImageRenderingMode rederingMode = self.manager.configuration.changeOriginalTinColor ? UIImageRenderingModeAlwaysTemplate : UIImageRenderingModeAlwaysOriginal;
    UIImage *originalNormalImage = [[UIImage hx_imageNamed:self.manager.configuration.originalNormalImageName] imageWithRenderingMode:rederingMode];
    UIImage *originalSelectedImage = [[UIImage hx_imageNamed:self.manager.configuration.originalSelectedImageName] imageWithRenderingMode:rederingMode];
    [self.originalBtn setImage:originalNormalImage forState:UIControlStateNormal];
    [self.originalBtn setImage:originalSelectedImage forState:UIControlStateSelected];
    self.originalBtn.imageView.tintColor = originalBtnImageTintColor;
    
    [self.editBtn setTitleColor:themeColor forState:UIControlStateNormal];
    [self.editBtn setTitleColor:[themeColor colorWithAlphaComponent:0.5] forState:UIControlStateDisabled];
    
    if ([themeColor isEqual:[UIColor whiteColor]]) {
        [self.doneBtn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        [self.doneBtn setTitleColor:[[UIColor blackColor] colorWithAlphaComponent:0.3] forState:UIControlStateDisabled];
    }
    if (selectedTitleColor) {
        [self.doneBtn setTitleColor:selectedTitleColor forState:UIControlStateNormal];
        [self.doneBtn setTitleColor:[selectedTitleColor colorWithAlphaComponent:0.3] forState:UIControlStateDisabled];
    }
    if (self.manager.configuration.showOriginalBytesLoading) {
        self.loadingView.color = themeColor;
    }
}
- (void)setSelectCount:(NSInteger)selectCount {
    _selectCount = selectCount;
    if (selectCount <= 0) {
        self.previewBtn.enabled = NO;
        self.doneBtn.enabled = NO;
        [self.doneBtn setTitle:[NSBundle hx_localizedStringForKey:@"完成"] forState:UIControlStateNormal];
    }else {
        self.previewBtn.enabled = YES;
        self.doneBtn.enabled = YES;
        if (self.manager.configuration.doneBtnShowDetail) {
            if (!self.manager.configuration.selectTogether) {
                if (self.manager.selectedPhotoCount > 0) {
                    NSInteger maxCount = self.manager.configuration.photoMaxNum > 0 ? self.manager.configuration.photoMaxNum : self.manager.configuration.maxNum;
                    [self.doneBtn setTitle:[NSString stringWithFormat:@"%@(%ld/%ld)",[NSBundle hx_localizedStringForKey:@"完成"],(long)selectCount,(long)maxCount] forState:UIControlStateNormal];
                }else {
                    NSInteger maxCount = self.manager.configuration.videoMaxNum > 0 ? self.manager.configuration.videoMaxNum : self.manager.configuration.maxNum;
                    [self.doneBtn setTitle:[NSString stringWithFormat:@"%@(%ld/%ld)",[NSBundle hx_localizedStringForKey:@"完成"],(long)selectCount,(long)maxCount] forState:UIControlStateNormal];
                }
            }else {
                [self.doneBtn setTitle:[NSString stringWithFormat:@"%@(%ld/%lu)",[NSBundle hx_localizedStringForKey:@"完成"],(long)selectCount,(unsigned long)self.manager.configuration.maxNum] forState:UIControlStateNormal];
            }
        }else {
            [self.doneBtn setTitle:[NSString stringWithFormat:@"%@(%ld)",[NSBundle hx_localizedStringForKey:@"完成"],(long)selectCount] forState:UIControlStateNormal];
        }
    }
    UIColor *themeColor = self.manager.configuration.bottomDoneBtnBgColor ?: self.manager.configuration.themeColor;
    UIColor *doneBtnDarkBgColor = self.manager.configuration.bottomDoneBtnDarkBgColor ?: [UIColor colorWithRed:0.2 green:0.2 blue:0.2 alpha:1];
    UIColor *doneBtnBgColor = [HXPhotoCommon photoCommon].isDark ? doneBtnDarkBgColor : themeColor;
    UIColor *doneBtnEnabledBgColor = self.manager.configuration.bottomDoneBtnEnabledBgColor ?: [doneBtnBgColor colorWithAlphaComponent:0.5];
    self.doneBtn.backgroundColor = self.doneBtn.enabled ? doneBtnBgColor : doneBtnEnabledBgColor;
    
    if (!self.manager.configuration.selectTogether) {
        if (self.manager.selectedPhotoArray.count) {
            self.editBtn.enabled = self.manager.configuration.photoCanEdit;
        }else if (self.manager.selectedVideoArray.count) {
            self.editBtn.enabled = self.manager.configuration.videoCanEdit;
        }else {
            self.editBtn.enabled = NO;
        }
    }else {
        if (self.manager.selectedArray.count) {
            HXPhotoModel *model = self.manager.selectedArray.firstObject;
            if (model.subType == HXPhotoModelMediaSubTypePhoto) {
                self.editBtn.enabled = self.manager.configuration.photoCanEdit;
            }else {
                self.editBtn.enabled = self.manager.configuration.videoCanEdit;
            }
        }else {
            self.editBtn.enabled = NO;
        }
    }
    [self changeDoneBtnFrame];
    [self requestPhotosBytes];
}
- (void)requestPhotosBytes {
    if (!self.manager.configuration.showOriginalBytes) { 
        return;
    }
    if (self.originalBtn.selected) {
        if (self.manager.configuration.showOriginalBytesLoading) {
            [self resetOriginalBtn];
            [self updateLoadingViewWithHidden:NO];
        }
        HXWeakSelf
        [self.manager requestPhotosBytesWithCompletion:^(NSString *totalBytes, NSUInteger totalDataLengths) {
            if (weakSelf.manager.configuration.showOriginalBytesLoading) {
                [weakSelf updateLoadingViewWithHidden:YES];
            }
            if (totalDataLengths > 0) {
                [weakSelf.originalBtn setTitle:[NSString stringWithFormat:@"%@(%@)",[NSBundle hx_localizedStringForKey:@"原图"], totalBytes] forState:UIControlStateNormal];
            }else {
                [weakSelf.originalBtn setTitle:[NSBundle hx_localizedStringForKey:@"原图"] forState:UIControlStateNormal];
            }
            [weakSelf updateOriginalBtnFrame];
        }];
    }else {
        if (self.manager.configuration.showOriginalBytesLoading) {
            [self updateLoadingViewWithHidden:YES];
        }
        [self resetOriginalBtn];
    }
}
- (void)resetOriginalBtn {
    [self.manager.dataOperationQueue cancelAllOperations];
    [self.originalBtn setTitle:[NSBundle hx_localizedStringForKey:@"原图"] forState:UIControlStateNormal];
    [self updateOriginalBtnFrame];
}
- (void)changeDoneBtnFrame {
    CGFloat width = self.doneBtn.titleLabel.hx_getTextWidth;
    self.doneBtn.hx_w = width + 20;
    if (self.doneBtn.hx_w < 60) {
        self.doneBtn.hx_w = 60;
    }
    self.doneBtn.hx_x = self.hx_w - 12 - self.doneBtn.hx_w;
}
- (void)updateOriginalBtnFrame {
    if (self.editBtn.hidden) {
        self.originalBtn.frame = CGRectMake(CGRectGetMaxX(self.previewBtn.frame) + 10, 0, 30, 50);
        
    }else {
        self.originalBtn.frame = CGRectMake(CGRectGetMaxX(self.editBtn.frame) + 10, 0, 30, 50);
    }
    self.originalBtn.hx_w = self.originalBtn.titleLabel.hx_getTextWidth + 30;
    if (CGRectGetMaxX(self.originalBtn.frame) > self.doneBtn.hx_x - 25) {
        CGFloat w = self.doneBtn.hx_x - 5 - self.originalBtn.hx_x;
        self.originalBtn.hx_w = w < 0 ? 30 : w;
    }
    
    self.originalBtn.titleEdgeInsets = UIEdgeInsetsMake(0, 5 , 0, 0);
}
- (void)updateLoadingViewWithHidden:(BOOL)hidden {
    if (hidden && self.loadingView.hidden) {
        return;
    }
    if (!hidden && !self.loadingView.hidden) {
        return;
    }
    self.loadingView.hx_x = CGRectGetMaxX(self.originalBtn.frame) - 5;
    self.loadingView.hx_centerY = self.originalBtn.hx_h / 2;
    if (hidden) {
        [self.loadingView stopAnimating];
    }else {
        [self.loadingView startAnimating];
    }
    self.loadingView.hidden = hidden;
}
- (void)didDoneBtnClick {
    if ([self.delegate respondsToSelector:@selector(photoBottomViewDidDoneBtn)]) {
        [self.delegate photoBottomViewDidDoneBtn];
    }
}
- (void)didPreviewClick {
    if ([self.delegate respondsToSelector:@selector(photoBottomViewDidPreviewBtn)]) {
        [self.delegate photoBottomViewDidPreviewBtn];
    }
}
- (void)didEditBtnClick {
    if ([self.delegate respondsToSelector:@selector(photoBottomViewDidEditBtn)]) {
        [self.delegate photoBottomViewDidEditBtn];
    }
}
- (void)didOriginalClick:(UIButton *)button {
    button.selected = !button.selected;
    [self requestPhotosBytes];
    [self.manager setOriginal:button.selected]; 
}
- (void)layoutSubviews {
    [super layoutSubviews];
    
    self.bgView.frame = self.bounds;
    self.previewBtn.frame = CGRectMake(12, 0, 0, 50);
    self.previewBtn.hx_w = self.previewBtn.titleLabel.hx_getTextWidth;
    self.previewBtn.center = CGPointMake(self.previewBtn.center.x, 25);
    
    self.editBtn.frame = CGRectMake(CGRectGetMaxX(self.previewBtn.frame) + 10, 0, 0, 50);
    self.editBtn.hx_w = self.editBtn.titleLabel.hx_getTextWidth;
    
    self.doneBtn.frame = CGRectMake(0, 0, 60, 30);
    self.doneBtn.center = CGPointMake(self.doneBtn.center.x, 25);
    [self changeDoneBtnFrame];
    
    [self updateOriginalBtnFrame];
}
- (UIToolbar *)bgView {
    if (!_bgView) {
        _bgView = [[UIToolbar alloc] init];
    }
    return _bgView;
}
- (UIButton *)previewBtn {
    if (!_previewBtn) {
        _previewBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [_previewBtn setTitle:[NSBundle hx_localizedStringForKey:@"预览"] forState:UIControlStateNormal];
        _previewBtn.titleLabel.font = [UIFont systemFontOfSize:16];
        _previewBtn.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
        [_previewBtn addTarget:self action:@selector(didPreviewClick) forControlEvents:UIControlEventTouchUpInside];
        _previewBtn.enabled = NO;
    }
    return _previewBtn;
}
- (UIButton *)doneBtn {
    if (!_doneBtn) {
        _doneBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [_doneBtn setTitle:[NSBundle hx_localizedStringForKey:@"完成"] forState:UIControlStateNormal];
        _doneBtn.titleLabel.font = [UIFont hx_mediumPingFangOfSize:16];
        [_doneBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [_doneBtn setTitleColor:[[UIColor whiteColor] colorWithAlphaComponent:0.5] forState:UIControlStateDisabled];
        _doneBtn.layer.cornerRadius = 3;
        _doneBtn.enabled = NO;
        [_doneBtn addTarget:self action:@selector(didDoneBtnClick) forControlEvents:UIControlEventTouchUpInside];
    }
    return _doneBtn;
}
- (UIButton *)originalBtn {
    if (!_originalBtn) {
        _originalBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [_originalBtn setTitle:[NSBundle hx_localizedStringForKey:@"原图"] forState:UIControlStateNormal];
        [_originalBtn addTarget:self action:@selector(didOriginalClick:) forControlEvents:UIControlEventTouchUpInside];
        _originalBtn.titleLabel.font = [UIFont systemFontOfSize:16];
        _originalBtn.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
    }
    return _originalBtn;
}
- (UIButton *)editBtn {
    if (!_editBtn) {
        _editBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [_editBtn setTitle:[NSBundle hx_localizedStringForKey:@"编辑"] forState:UIControlStateNormal];
        _editBtn.titleLabel.font = [UIFont systemFontOfSize:16];
        _editBtn.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
        [_editBtn addTarget:self action:@selector(didEditBtnClick) forControlEvents:UIControlEventTouchUpInside];
        _editBtn.enabled = NO;
    }
    return _editBtn;
}
- (UIActivityIndicatorView *)loadingView {
    if (!_loadingView) {
        _loadingView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
        _loadingView.hidden = YES;
        [self addSubview:_loadingView];
    }
    return _loadingView;
}
@end
