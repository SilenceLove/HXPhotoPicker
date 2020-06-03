//
//  HXPhotoViewController.m
//  照片选择器
//
//  Created by 洪欣 on 2017/10/14.
//  Copyright © 2017年 洪欣. All rights reserved.
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
#import "HXDownloadProgressView.h"
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
HXVideoEditViewControllerDelegate
>
@property (strong, nonatomic) UICollectionViewFlowLayout *flowLayout;
@property (strong, nonatomic) UICollectionView *collectionView;
@property (strong, nonatomic) HXPhotoViewFlowLayout *customLayout;

@property (strong, nonatomic) NSMutableArray *allArray;
@property (strong, nonatomic) NSMutableArray *previewArray;
@property (strong, nonatomic) NSMutableArray *photoArray;
@property (strong, nonatomic) NSMutableArray *videoArray;
@property (strong, nonatomic) NSMutableArray *dateArray;

@property (assign, nonatomic) NSInteger currentSectionIndex;
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
@property (strong, nonatomic) HXPhotoModel *firstSelectModel;

@property (assign, nonatomic) BOOL collectionViewReloadCompletion;

@property (weak, nonatomic) HXPhotoCameraViewCell *cameraCell;
@end

@implementation HXPhotoViewController
#pragma mark - < life cycle >
- (void)dealloc {
    if (HXShowLog) NSSLog(@"dealloc");
    [self.manager removeAllTempList];
    if (self.manager.configuration.albumShowMode == HXPhotoAlbumShowModePopup) {
        [self.manager removeAllAlbum];
    }
    if (_collectionView) {
        [self.collectionView.layer removeAllAnimations];
    }
    if (self.manager.configuration.open3DTouchPreview) {
        if (self.previewingContext) {
            [self unregisterForPreviewingWithContext:self.previewingContext];
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
            _authorizationLb.textColor = [HXPhotoCommon photoCommon].isDark ? [UIColor whiteColor] : [UIColor blackColor];
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
- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self changeStatusBarStyle];
    if (self.needChangeViewFrame) {
        self.needChangeViewFrame = NO;
    }
}
- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if (self.manager.configuration.cameraCellShowPreview && !self.cameraCell.startSession) {
        [self.cameraCell starRunning]; 
    }
}
- (void)changeStatusBarStyle {
    if ([HXPhotoCommon photoCommon].isDark) {
        [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent];
        return;
    }
    [[UIApplication sharedApplication] setStatusBarStyle:self.manager.configuration.statusBarStyle];
}
- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    if (self.orientationDidChange) {
        [self changeSubviewFrame];
        self.orientationDidChange = NO;
    }
}
- (void)viewDidLoad {
    [super viewDidLoad];
    self.extendedLayoutIncludesOpaqueBars = YES;
    self.edgesForExtendedLayout = UIRectEdgeAll;
    if (self.manager.configuration.showBottomPhotoDetail) {
        self.showBottomPhotoCount = YES;
        self.manager.configuration.showBottomPhotoDetail = NO;
    }
    if (self.manager.configuration.albumShowMode == HXPhotoAlbumShowModeDefault) {
        [self setupUI];
        [self changeSubviewFrame];
        [self.view hx_showLoadingHUDText:nil];
        [self getPhotoList];
    }else if (self.manager.configuration.albumShowMode == HXPhotoAlbumShowModePopup) { 
        [self setupUI];
        [self changeSubviewFrame];
        // 获取当前应用对照片的访问授权状态
        HXWeakSelf
        [self.view hx_showLoadingHUDText:nil delay:0.1f];
        [HXPhotoTools requestAuthorization:self handler:^(PHAuthorizationStatus status) {
            if (status == PHAuthorizationStatusAuthorized) {
                [weakSelf getAlbumList];
            }else {
                [weakSelf.view hx_handleLoading];
                [weakSelf.view addSubview:weakSelf.authorizationLb];
            }
        }];
    }

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
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(deviceOrientationChanged:) name:UIApplicationDidChangeStatusBarOrientationNotification object:nil];
}
#pragma mark - < private >
- (void)setupUI {
    self.currentSectionIndex = 0;
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:[NSBundle hx_localizedStringForKey:@"取消"] style:UIBarButtonItemStyleDone target:self action:@selector(didCancelClick)];
    [self.view addSubview:self.collectionView];
    if (!self.manager.configuration.singleSelected) {
        [self.view addSubview:self.bottomView];
    }
    if (self.manager.configuration.albumShowMode == HXPhotoAlbumShowModePopup) {
        [self.albumTitleView layoutSubviews];
        self.navigationItem.titleView = self.albumTitleView;
        [self.view addSubview:self.albumBgView];
        [self.view addSubview:self.albumView];
    }
    [self changeColor];
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
        backgroundColor = [UIColor whiteColor];
        themeColor = self.manager.configuration.themeColor;
        navBarBackgroudColor = self.manager.configuration.navBarBackgroudColor;
        navigationTitleColor = self.manager.configuration.navigationTitleColor;
        albumBgColor = [UIColor blackColor];
    }
    self.view.backgroundColor = backgroundColor;
    self.collectionView.backgroundColor = backgroundColor;
    [self.navigationController.navigationBar setTintColor:themeColor];
    
    self.navigationController.navigationBar.barTintColor = navBarBackgroudColor;
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
    
}
- (void)deviceOrientationChanged:(NSNotification *)notify {
    self.beforeOrientationIndexPath = [self.collectionView indexPathsForVisibleItems].firstObject;
    self.orientationDidChange = YES;
    if (self.navigationController.topViewController != self) {
        self.needChangeViewFrame = YES;
    }
}
- (void)changeSubviewFrame {
    CGFloat albumHeight = self.manager.configuration.popupTableViewHeight;
    UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
    CGFloat navBarHeight = hxNavigationBarHeight;
    NSInteger lineCount = self.manager.configuration.rowCount;
    if (orientation == UIInterfaceOrientationPortrait || orientation == UIInterfaceOrientationPortraitUpsideDown) {
        navBarHeight = hxNavigationBarHeight;
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
        albumHeight = self.manager.configuration.popupTableViewHorizontalHeight;
    }
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
    if (self.manager.configuration.showDateSectionHeader) {
        self.customLayout.itemSize = CGSizeMake(itemWidth, itemHeight);
    }else {
        self.flowLayout.itemSize = CGSizeMake(itemWidth, itemHeight);
    }
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
        if (self.albumTitleView.selected) {
            self.albumView.hx_y = navBarHeight;
        }else {
            self.albumView.hx_y = -(navBarHeight + self.albumView.hx_h);
        }
        self.albumBgView.hx_size = CGSizeMake(viewWidth, height);
        if (self.manager.configuration.popupAlbumTableView) {
            self.manager.configuration.popupAlbumTableView(self.albumView.tableView);
        }
        self.albumTitleView.model = self.albumModel;
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
- (void)getAlbumList {
    HXWeakSelf
    self.manager.allAlbumListBlock = ^(NSMutableArray<HXAlbumModel *> *albums) {
        dispatch_async(dispatch_get_main_queue(), ^{
            weakSelf.albumView.albumModelArray = albums;
        });
        [weakSelf.manager removeAllAlbum];
    };
    self.manager.getCameraRollAlbumModel = ^(HXAlbumModel *albumModel) {
        dispatch_async(dispatch_get_main_queue(), ^{
            weakSelf.albumModel = albumModel;
            weakSelf.albumTitleView.model = albumModel;
            [weakSelf.albumTitleView setupAlpha:YES];
            [weakSelf getPhotoList];
        });
    };
    
    if (self.manager.cameraRollAlbumModel) {
        [self.albumTitleView setupAlpha:YES];
        self.albumModel = self.manager.cameraRollAlbumModel;
        self.albumTitleView.model = self.albumModel;
        [self getPhotoList];
    }else {
        if (!self.manager.getCameraRoolAlbuming) {
            dispatch_async(self.manager.loadAssetQueue, ^{
                [self.manager getCameraRollAlbumCompletion:nil];
            });
        }
    }
    dispatch_async(self.manager.loadAssetQueue, ^{
        if (!self.manager.getAlbumListing && !self.manager.albums) {
            [self.manager getAllAlbumModelFilter:NO needSelect:YES select:nil completion:nil];
        }else {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (self.manager.albums) {
                    self.albumView.albumModelArray = self.manager.albums;
                }
            });
        }
    });
}
- (void)getPhotoList {
    if (!self.albumModel.result &&
        self.albumModel.collection) {
        dispatch_async(self.manager.loadAssetQueue, ^{
            // 提前加载照片列表数据
            PHFetchResult *result = [PHAsset fetchAssetsInAssetCollection:self.albumModel.collection options:self.albumModel.option];
            self.albumModel.result = result;
            self.albumModel.count = result.count;
            [self startGetAllPhotoModel];
        });
    }else {
        [self startGetAllPhotoModel];
    }
}
- (void)didCancelClick {
    if (self.manager.configuration.albumShowMode == HXPhotoAlbumShowModePopup) {
        [self.manager cancelBeforeSelectedList];
    }
    if ([self.delegate respondsToSelector:@selector(photoViewControllerDidCancel:)]) {
        [self.delegate photoViewControllerDidCancel:self];
    }
    if (self.cancelBlock) {
        self.cancelBlock(self, self.manager);
    }
    self.manager.selectPhotoing = NO;
    [self dismissViewControllerAnimated:YES completion:nil];
}
- (NSInteger)dateItem:(HXPhotoModel *)model {
    NSInteger dateItem;
    if (self.manager.configuration.showDateSectionHeader) {
        HXPhotoDateModel *dateModel = [self.dateArray objectAtIndex:model.dateSection];
        dateItem = [dateModel.photoModelArray indexOfObject:model];
    }else {
        dateItem = [self.allArray indexOfObject:model];
    }
    model.dateItem = dateItem;
    return dateItem;
}
- (void)scrollToPoint:(HXPhotoViewCell *)cell rect:(CGRect)rect {
    UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
    CGFloat navBarHeight = hxNavigationBarHeight;
    if (orientation == UIInterfaceOrientationPortrait || orientation == UIInterfaceOrientationPortraitUpsideDown) {
        navBarHeight = hxNavigationBarHeight;
    }else if (orientation == UIInterfaceOrientationLandscapeRight || orientation == UIInterfaceOrientationLandscapeLeft){
        if ([UIApplication sharedApplication].statusBarHidden) {
            navBarHeight = self.navigationController.navigationBar.hx_h;
        }else {
            navBarHeight = self.navigationController.navigationBar.hx_h + 20;
        }
    }
    if (self.manager.configuration.showDateSectionHeader) {
        navBarHeight += 50;
    }
    if (rect.origin.y < navBarHeight) {
        [self.collectionView setContentOffset:CGPointMake(0, cell.frame.origin.y - navBarHeight)];
    }else if (rect.origin.y + rect.size.height > self.view.hx_h - 50.5 - hxBottomMargin) {
        [self.collectionView setContentOffset:CGPointMake(0, cell.frame.origin.y - self.view.hx_h + 50.5 + hxBottomMargin + rect.size.height)];
    }
}
#pragma mark - < public >
- (void)startGetAllPhotoModel {
    self.collectionViewReloadCompletion = NO;
    HXWeakSelf
    self.manager.photoListBlock = ^(NSArray *allList, NSArray *previewList, NSArray *photoList, NSArray *videoList, NSArray *dateList, HXPhotoModel *firstSelectModel, HXAlbumModel *albumModel) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (strongSelf.albumModel != albumModel) {
            return;
        }
        if (strongSelf.manager.configuration.albumShowMode == HXPhotoAlbumShowModeDefault) {
            if (strongSelf.allArray.count) {
                return;
            }
        }
        if (strongSelf.collectionViewReloadCompletion) {
            return ;
        }
        strongSelf.collectionViewReloadCompletion = YES;
        strongSelf.dateArray = [NSMutableArray arrayWithArray:dateList];
        strongSelf.photoArray = [NSMutableArray arrayWithArray:photoList];
        strongSelf.videoArray = [NSMutableArray arrayWithArray:videoList];
        strongSelf.allArray = [NSMutableArray arrayWithArray:allList];
        strongSelf.firstSelectModel = firstSelectModel;
        if (strongSelf.allArray.count && strongSelf.showBottomPhotoCount) {
            strongSelf.manager.configuration.showBottomPhotoDetail = YES;
        }
        strongSelf.previewArray = [NSMutableArray arrayWithArray:previewList];
        [strongSelf reloadCollectionViewWithFirstSelectModel:firstSelectModel];
        [strongSelf.manager removeAllTempList];
    };
    dispatch_async(self.manager.loadAssetQueue, ^{
        if (self.manager.configuration.albumShowMode == HXPhotoAlbumShowModeDefault) {
            if (!self.manager.getPhotoListing && !self.manager.tempAlbumModel && !self.allArray.count) {
                [self.manager getPhotoListWithAlbumModel:self.albumModel complete:nil];
            }else {
                if (self.manager.tempAlbumModel && !self.allArray.count && !self.manager.getPhotoListing) {
                    [self.manager getPhotoListWithAlbumModel:self.manager.tempAlbumModel complete:nil];
                }else {
                    if (self.collectionViewReloadCompletion) {
                        return ;
                    }
                    self.collectionViewReloadCompletion = YES;
                    [self reloadCollectionViewWithFirstSelectModel:self.firstSelectModel];
                }
            }
        }else if (self.manager.configuration.albumShowMode == HXPhotoAlbumShowModePopup) {
            if (!self.manager.getPhotoListing && !self.allArray.count) {
                [self.manager getPhotoListWithAlbumModel:self.albumModel complete:nil];
            }else {
                if (self.collectionViewReloadCompletion) {
                    return ;
                }
                self.collectionViewReloadCompletion = YES;
                [self reloadCollectionViewWithFirstSelectModel:self.firstSelectModel];
            }
        }
    });
}
- (void)reloadCollectionViewWithFirstSelectModel:(HXPhotoModel *)firstSelectModel {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.view hx_handleLoading:NO];
        if (self.manager.configuration.albumShowMode == HXPhotoAlbumShowModePopup) {
            CATransition *transition = [CATransition animation];
            transition.type = kCATransitionPush;
            transition.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
            transition.fillMode = kCAFillModeForwards;
            transition.duration = 0.05f;
            transition.subtype = kCATransitionFade;
            [[self.collectionView layer] addAnimation:transition forKey:@""];
        }
        [self.collectionView reloadData];
        if (!self.manager.configuration.singleSelected) {
            self.bottomView.selectCount = self.manager.selectedArray.count;
        }
        NSIndexPath *scrollIndexPath;
        UICollectionViewScrollPosition position = UICollectionViewScrollPositionNone;
        if (!self.manager.configuration.reverseDate) {
            if (self.manager.configuration.showDateSectionHeader && self.dateArray.count > 0) {
                HXPhotoDateModel *dateModel = self.dateArray.lastObject;
                if (dateModel.photoModelArray.count > 0) {
                    if (firstSelectModel) {
                        scrollIndexPath = [NSIndexPath indexPathForItem:[self dateItem:firstSelectModel] inSection:firstSelectModel.dateSection];
                        position = UICollectionViewScrollPositionCenteredVertically;
                    }else {
                        NSInteger forItem = (dateModel.photoModelArray.count - 1) <= 0 ? 0 : dateModel.photoModelArray.count - 1;
                        NSInteger inSection = (self.dateArray.count - 1) <= 0 ? 0 : self.dateArray.count - 1;
                        
                        scrollIndexPath = [NSIndexPath indexPathForItem:forItem inSection:inSection];
                        position = UICollectionViewScrollPositionBottom;
                    }
                }
            }else {
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
            }
        }else {
            if (firstSelectModel) {
                scrollIndexPath = self.manager.configuration.showDateSectionHeader ? [NSIndexPath indexPathForItem:[self dateItem:firstSelectModel] inSection:firstSelectModel.dateSection] : [NSIndexPath indexPathForItem:[self.allArray indexOfObject:firstSelectModel] inSection:0];
                position = UICollectionViewScrollPositionCenteredVertically;
            }
        }
        if (scrollIndexPath) {
            [self.collectionView scrollToItemAtIndexPath:scrollIndexPath atScrollPosition:position animated:NO];
        }
        if (self.manager.configuration.showDateSectionHeader &&
            self.collectionView.contentOffset.y > 0) {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.05f * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [self.collectionView.collectionViewLayout layoutAttributesForElementsInRect:self.collectionView.bounds];
            });
        }
    });
}
- (HXPhotoViewCell *)currentPreviewCell:(HXPhotoModel *)model {
    if (!model || ![self.allArray containsObject:model]) {
        return nil;
    }
    
    NSIndexPath *indexPath = [NSIndexPath indexPathForItem:[self dateItem:model] inSection:model.dateSection];
    return (HXPhotoViewCell *)[self.collectionView cellForItemAtIndexPath:indexPath];
}
- (BOOL)scrollToModel:(HXPhotoModel *)model {
    BOOL isContainsModel = [self.allArray containsObject:model];
    if (isContainsModel) {
        [self.collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForItem:[self dateItem:model] inSection:model.dateSection] atScrollPosition:UICollectionViewScrollPositionNone animated:NO];
        [self.collectionView reloadItemsAtIndexPaths:@[[NSIndexPath indexPathForItem:[self dateItem:model] inSection:model.dateSection]]];
    }
    return isContainsModel;
}

#pragma mark - < HXCustomCameraViewControllerDelegate >
- (void)customCameraViewController:(HXCustomCameraViewController *)viewController didDone:(HXPhotoModel *)model {
    model.currentAlbumIndex = self.albumModel.index;
    model.clarityScale = self.manager.configuration.clarityScale;
    if (!self.manager.configuration.singleSelected) {
        [self.manager beforeListAddCameraTakePicturesModel:model];
    }
    [self collectionViewAddModel:model beforeModel:nil];
    
    if (self.manager.configuration.singleSelected) {
        if (model.subType == HXPhotoModelMediaSubTypePhoto) {
            HXPhotoEditViewController *vc = [[HXPhotoEditViewController alloc] init];
            vc.isInside = YES;
            vc.delegate = self;
            vc.manager = self.manager;
            vc.model = model;
            vc.modalPresentationStyle = UIModalPresentationOverFullScreen;
            vc.modalPresentationCapturesStatusBarAppearance = YES;
            [self presentViewController:vc animated:YES completion:nil];
        }else {
            HXPhotoPreviewViewController *previewVC = [[HXPhotoPreviewViewController alloc] init];
            if (HX_IOS9Earlier) {
                previewVC.photoViewController = self;
            }
            previewVC.delegate = self;
            previewVC.modelArray = self.previewArray;
            previewVC.manager = self.manager;
            previewVC.currentModelIndex = [self.previewArray indexOfObject:model];
            self.navigationController.delegate = previewVC;
            [self.navigationController pushViewController:previewVC animated:NO];
        }
    }
}
- (void)collectionViewAddModel:(HXPhotoModel *)model beforeModel:(HXPhotoModel *)beforeModel {
    // 判断类型
    if (model.subType == HXPhotoModelMediaSubTypePhoto) {
        if (beforeModel) {
            NSInteger index = 0;
            if ([self.photoArray containsObject:beforeModel]) {
                index = [self.photoArray indexOfObject:beforeModel];
            }
            [self.photoArray insertObject:model atIndex:index];
        }else {
            if (self.manager.configuration.reverseDate) {
                [self.photoArray insertObject:model atIndex:0];
            }else {
                [self.photoArray addObject:model];
            }
        }
    }else if (model.subType == HXPhotoModelMediaSubTypeVideo) {
        if (beforeModel) {
            NSInteger index = 0;
            if ([self.videoArray containsObject:beforeModel]) {
                index = [self.videoArray indexOfObject:beforeModel];
            }
            [self.videoArray insertObject:model atIndex:index];
        }else {
            if (self.manager.configuration.reverseDate) {
                [self.videoArray insertObject:model atIndex:0];
            }else {
                [self.videoArray addObject:model];
            }
        }
    }
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
    if (self.manager.configuration.showDateSectionHeader) {
        if (beforeModel && [self.allArray containsObject:beforeModel]) {
            NSIndexPath *indexPath = [NSIndexPath indexPathForItem:[self dateItem:beforeModel] inSection:beforeModel.dateSection];
            NSInteger index = indexPath.item;
            HXPhotoDateModel *dateModel = [self.dateArray objectAtIndex:indexPath.section];
            NSMutableArray *array = [NSMutableArray arrayWithArray:dateModel.photoModelArray];
            if ([array containsObject:beforeModel]) {
                index = [array indexOfObject:beforeModel];
            }
            model.dateSection = indexPath.section;
            model.dateItem = index;
            [array insertObject:model atIndex:index];
            dateModel.photoModelArray = array;
            if (!dateModel.location && model.location) {
                dateModel.location = model.location;
                [self.collectionView reloadSections:[NSIndexSet indexSetWithIndex:indexPath.section]];
            }else {
                [self.collectionView insertItemsAtIndexPaths:@[indexPath]];
            }
        }else {
            if (self.manager.configuration.reverseDate) {
                model.dateSection = 0;
                HXPhotoDateModel *dateModel = self.dateArray.firstObject;
                NSMutableArray *array = [NSMutableArray arrayWithArray:dateModel.photoModelArray];
                [array insertObject:model atIndex:cameraIndex];
                dateModel.photoModelArray = array;
                if (!dateModel.location && model.location) {
                    dateModel.location = model.location;
                    [self.collectionView reloadSections:[NSIndexSet indexSetWithIndex:0]];
                }else {
                    [self.collectionView insertItemsAtIndexPaths:@[[NSIndexPath indexPathForItem:cameraIndex inSection:0]]];
                }
            }else {
                model.dateSection = self.dateArray.count - 1;
                HXPhotoDateModel *dateModel = self.dateArray.lastObject;
                NSMutableArray *array = [NSMutableArray arrayWithArray:dateModel.photoModelArray];
                NSInteger count = array.count - cameraIndex;
                [array insertObject:model atIndex:count];
                dateModel.photoModelArray = array;
                if (!dateModel.location && model.location) {
                    dateModel.location = model.location;
                    [self.collectionView reloadSections:[NSIndexSet indexSetWithIndex:self.dateArray.count - 1]];
                }else {
                    [self.collectionView insertItemsAtIndexPaths:@[[NSIndexPath indexPathForItem:count inSection:self.dateArray.count - 1]]];
                }
            }
        }
    }else {
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
    }
    self.footerView.photoCount = self.photoArray.count;
    self.footerView.videoCount = self.videoArray.count;
    self.bottomView.selectCount = [self.manager selectedCount];
    if (self.manager.configuration.albumShowMode == HXPhotoAlbumShowModePopup) {
        [self.albumView refreshCamearCount];
    }else if (self.manager.configuration.albumShowMode == HXPhotoAlbumShowModeDefault) {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"CustomCameraViewControllerDidDoneNotification" object:nil];
    }
}
#pragma mark - < UICollectionViewDataSource >
- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    if (self.manager.configuration.showDateSectionHeader) {
        return [self.dateArray count];
    }
    return 1;
}
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    if (self.manager.configuration.showDateSectionHeader) {
        HXPhotoDateModel *dateModel = [self.dateArray objectAtIndex:section];
        return [dateModel.photoModelArray count];
    }
    return self.allArray.count;
}
- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    HXPhotoModel *model;
    if (self.manager.configuration.showDateSectionHeader) {
        HXPhotoDateModel *dateModel = [self.dateArray objectAtIndex:indexPath.section];
        if (indexPath.item < dateModel.photoModelArray.count) {
            model = dateModel.photoModelArray[indexPath.item];
        }
    }else {
        if (indexPath.item < self.allArray.count) {
            model = self.allArray[indexPath.item];
        }
    }
    model.rowCount = self.manager.configuration.rowCount;
    model.dateCellIsVisible = YES;
    if (model.type == HXPhotoModelMediaTypeCamera) {
        HXPhotoCameraViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"DateCameraCellId" forIndexPath:indexPath];
        cell.model = model;
        cell.cameraImage = [HXPhotoCommon photoCommon].cameraImage;
        if (!self.cameraCell) {
            self.cameraCell = cell;
        }
        return cell;
    }else {
        if (self.manager.configuration.specialModeNeedHideVideoSelectBtn) {
            if (self.manager.videoSelectedType == HXPhotoManagerVideoSelectedTypeSingle && !self.manager.videoCanSelected && model.subType == HXPhotoModelMediaSubTypeVideo) {
                model.videoUnableSelect = YES;
            }else {
                model.videoUnableSelect = NO;
            }
        }
        HXPhotoViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"DateCellId" forIndexPath:indexPath];
        cell.delegate = self;
        
        cell.darkSelectBgColor = self.manager.configuration.cellDarkSelectBgColor;
        cell.darkSelectedTitleColor = self.manager.configuration.cellDarkSelectTitleColor;
        
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
        cell.model = model;
        cell.singleSelected = self.manager.configuration.singleSelected;
        return cell;
    }
}
#pragma mark - < UICollectionViewDelegate >
- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    if (self.navigationController.topViewController != self) {
        return;
    }
    HXPhotoModel *model;
    if (self.manager.configuration.showDateSectionHeader) {
        HXPhotoDateModel *dateModel = [self.dateArray objectAtIndex:indexPath.section];
        model = dateModel.photoModelArray[indexPath.item];
    }else {
        model = self.allArray[indexPath.item];
    }
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
                            if (model.videoDuration < weakSelf.manager.configuration.videoMinimumSelectDuration) {
                                [weakSelf.view hx_showImageHUDText:[NSString stringWithFormat:[NSBundle hx_localizedStringForKey:@"视频少于%ld秒，无法选择"], weakSelf.manager.configuration.videoMinimumSelectDuration]];
                            }else if (model.videoDuration >= weakSelf.manager.configuration.videoMaximumSelectDuration + 1) {
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
                    hx_showAlert(weakSelf, [NSBundle hx_localizedStringForKey:@"无法使用相机"], [NSBundle hx_localizedStringForKey:@"请在设置-隐私-相机中允许访问相机"], [NSBundle hx_localizedStringForKey:@"取消"], [NSBundle hx_localizedStringForKey:@"设置"] , nil, ^{
                        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]];
                    }); 
                }
            });
        }];
    }else {
        HXPhotoViewCell *cell = (HXPhotoViewCell *)[self.collectionView cellForItemAtIndexPath:indexPath];
        if (cell.model.videoUnableSelect) {
            [self.view hx_showImageHUDText:[NSBundle hx_localizedStringForKey:@"视频不能和图片同时选择"]];
            return;
        }
        if (cell.model.isICloud) {
            if (self.manager.configuration.downloadICloudAsset) {
                if (!cell.model.iCloudDownloading) {
                    [cell startRequestICloudAsset];
                }
            }else {
                [self.view hx_showImageHUDText:[NSBundle hx_localizedStringForKey:@"尚未从iCloud上下载，请至系统相册下载完毕后选择"]];
            }
            return;
        }
        if (cell.model.subType == HXPhotoModelMediaSubTypeVideo) {
            if (cell.model.videoDuration >= self.manager.configuration.videoMaximumSelectDuration + 1) {
                if (self.manager.configuration.selectVideoBeyondTheLimitTimeAutoEdit &&
                    self.manager.configuration.videoCanEdit) {
                    [self jumpVideoEditWithModel:cell.model];
                    return;
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
                    HXPhotoEditViewController *vc = [[HXPhotoEditViewController alloc] init];
                    vc.isInside = YES;
                    vc.model = cell.model;
                    vc.delegate = self;
                    vc.manager = self.manager;
                    vc.modalPresentationStyle = UIModalPresentationOverFullScreen;
                    vc.modalPresentationCapturesStatusBarAppearance = YES;
                    [self presentViewController:vc animated:YES completion:nil];
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
- (void)collectionView:(UICollectionView *)collectionView willDisplayCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath {
    if ([cell isKindOfClass:[HXPhotoCameraViewCell class]]) {
        [(HXPhotoCameraViewCell *)cell addOutputDelegate];
    }
}
- (void)collectionView:(UICollectionView *)collectionView didEndDisplayingCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath {
    if ([cell isKindOfClass:[HXPhotoViewCell class]]) {
        [(HXPhotoViewCell *)cell cancelRequest];
    }else if ([cell isKindOfClass:[HXPhotoCameraViewCell class]]) {
        [(HXPhotoCameraViewCell *)cell removeOutputDelegate];
    }
}
- (void)collectionView:(UICollectionView *)collectionView didEndDisplayingSupplementaryView:(UICollectionReusableView *)view forElementOfKind:(NSString *)elementKind atIndexPath:(NSIndexPath *)indexPath {
    if ([elementKind isEqualToString:UICollectionElementKindSectionHeader]) {
        //        NSSLog(@"headerSection消失");
    }
}
- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath {
    if ([kind isEqualToString:UICollectionElementKindSectionHeader] && self.manager.configuration.showDateSectionHeader) {
        HXPhotoViewSectionHeaderView *headerView = [collectionView dequeueReusableSupplementaryViewOfKind:kind withReuseIdentifier:@"sectionHeaderId" forIndexPath:indexPath];
        headerView.translucent = self.manager.configuration.sectionHeaderTranslucent;
        if ([HXPhotoCommon photoCommon].isDark) {
            headerView.suspensionBgColor = [UIColor blackColor];
            headerView.suspensionTitleColor = [UIColor whiteColor];
        }else {
            headerView.suspensionBgColor = self.manager.configuration.sectionHeaderSuspensionBgColor;
            headerView.suspensionTitleColor = self.manager.configuration.sectionHeaderSuspensionTitleColor;
        }
        headerView.model = self.dateArray[indexPath.section];
        return headerView;
    }else if ([kind isEqualToString:UICollectionElementKindSectionFooter]) {
        if (self.manager.configuration.showBottomPhotoDetail) {
            HXPhotoViewSectionFooterView *footerView = [collectionView dequeueReusableSupplementaryViewOfKind:kind withReuseIdentifier:@"sectionFooterId" forIndexPath:indexPath];
            footerView.photoCount = self.photoArray.count;
            footerView.videoCount = self.videoArray.count;
            self.footerView = footerView;
            return footerView;
        }
    }
    return nil;
}
- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout referenceSizeForHeaderInSection:(NSInteger)section {
    if (self.manager.configuration.showDateSectionHeader) {
        return CGSizeMake(self.view.hx_w, 50);
    }
    return CGSizeZero;
}
- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout referenceSizeForFooterInSection:(NSInteger)section {
    if (self.manager.configuration.showDateSectionHeader) {
        if (section == self.dateArray.count - 1) {
            return self.manager.configuration.showBottomPhotoDetail ? CGSizeMake(self.view.hx_w, 50) : CGSizeZero;
        }else {
            return CGSizeZero;
        }
    }else {
        return self.manager.configuration.showBottomPhotoDetail ? CGSizeMake(self.view.hx_w, 50) : CGSizeZero;
    }
}
#pragma mark - < preview Haptic Touch >
//#ifdef __IPHONE_13_0
//- (UIContextMenuConfiguration *)collectionView:(UICollectionView *)collectionView contextMenuConfigurationForItemAtIndexPath:(NSIndexPath *)indexPath point:(CGPoint)point  API_AVAILABLE(ios(13.0)) {
//    HXPhotoModel *_model;
//    if (self.manager.configuration.showDateSectionHeader) {
//        HXPhotoDateModel *dateModel = [self.dateArray objectAtIndex:indexPath.section];
//        _model = [dateModel.photoModelArray objectAtIndex:indexPath.item];
//    }else {
//        _model = [self.allArray objectAtIndex:indexPath.item];
//    }
//    HXWeakSelf
//    UIContextMenuConfiguration *menuConfiguration = [UIContextMenuConfiguration configurationWithIdentifier:_model.localIdentifier ?: _model.cameraIdentifier previewProvider:^UIViewController * _Nullable{
//        return [weakSelf previewViewControlerWithIndexPath:indexPath];
//    } actionProvider:nil];
//    return menuConfiguration;
//}
//- (void)collectionView:(UICollectionView *)collectionView willPerformPreviewActionForMenuWithConfiguration:(UIContextMenuConfiguration *)configuration animator:(id<UIContextMenuInteractionCommitAnimating>)animator API_AVAILABLE(ios(13.0)) {
//    [self pushPreviewControler:animator.previewViewController];
//}
//#endif
- (UIViewController *)previewViewControlerWithIndexPath:(NSIndexPath *)indexPath {
    HXPhotoViewCell *cell = (HXPhotoViewCell *)[self.collectionView cellForItemAtIndexPath:indexPath];
    if (!cell || cell.model.type == HXPhotoModelMediaTypeCamera || cell.model.isICloud) {
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
    if (!cell || cell.model.type == HXPhotoModelMediaTypeCamera || cell.model.isICloud) {
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
                HXPhotoEditViewController *vc = [[HXPhotoEditViewController alloc] init];
                vc.model = cell.model;
                vc.delegate = self;
                vc.manager = self.manager;
                vc.modalPresentationStyle = UIModalPresentationOverFullScreen;
                vc.modalPresentationCapturesStatusBarAppearance = YES;
                [self presentViewController:vc animated:NO completion:nil];
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
        NSIndexPath *indexPath = [NSIndexPath indexPathForItem:[self dateItem:cell.model] inSection:cell.model.dateSection];
        if (indexPath) {
            [self.collectionView reloadItemsAtIndexPaths:@[indexPath]];
        }
        [self.manager addICloudModel:cell.model];
    }
}
- (void)photoViewCell:(HXPhotoViewCell *)cell didSelectBtn:(UIButton *)selectBtn {
    if (selectBtn.selected) {
        if (cell.model.type != HXPhotoModelMediaTypeCameraVideo && cell.model.type != HXPhotoModelMediaTypeCameraPhoto) {
            cell.model.thumbPhoto = nil;
            cell.model.previewPhoto = nil;
        }
        [self.manager beforeSelectedListdeletePhotoModel:cell.model];
        cell.model.selectIndexStr = @"";
        cell.selectMaskLayer.hidden = YES;
        selectBtn.selected = NO;
    }else {
        NSString *str = [self.manager maximumOfJudgment:cell.model];
        if (str) {
            if ([str isEqualToString:@"selectVideoBeyondTheLimitTimeAutoEdit"]) {
                [self jumpVideoEditWithModel:cell.model];
            }else {
                [self.view hx_showImageHUDText:str];
            }
            return;
        }
        if (cell.model.type != HXPhotoModelMediaTypeCameraVideo && cell.model.type != HXPhotoModelMediaTypeCameraPhoto) {
            cell.model.thumbPhoto = cell.imageView.image;
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
        NSInteger index = 0;
        for (HXPhotoModel *model in [self.manager selectedArray]) {
            model.selectIndexStr = [NSString stringWithFormat:@"%ld",index + 1];
            if (model.currentAlbumIndex == self.albumModel.index) {
                if (model.dateCellIsVisible) {
                    NSIndexPath *indexPath = [NSIndexPath indexPathForItem:[self dateItem:model] inSection:model.dateSection];
                    [indexPathList addObject:indexPath];
                }
            }
            index++;
        }
//        if (indexPathList.count > 0) {
//            [self.collectionView reloadItemsAtIndexPaths:indexPathList];
//        }
    }
    
    if (self.manager.videoSelectedType == HXPhotoManagerVideoSelectedTypeSingle) {
        for (UICollectionViewCell *tempCell in self.collectionView.visibleCells) {
            if ([tempCell isKindOfClass:[HXPhotoViewCell class]]) {
                if ([(HXPhotoViewCell *)tempCell model].subType == HXPhotoModelMediaSubTypeVideo) {
                    [indexPathList addObject:[self.collectionView indexPathForCell:tempCell]];
                }
            }
        }
        if (indexPathList.count) {
            [self.collectionView reloadItemsAtIndexPaths:indexPathList];
        }
    }else {
        if (!selectBtn.selected) {
            if (indexPathList.count) {
                [self.collectionView reloadItemsAtIndexPaths:indexPathList];
            }
        }
    }
    
    self.bottomView.selectCount = [self.manager selectedCount];
    if ([self.delegate respondsToSelector:@selector(photoViewControllerDidChangeSelect:selected:)]) {
        [self.delegate photoViewControllerDidChangeSelect:cell.model selected:selectBtn.selected];
    }
}
#pragma mark - < HXPhotoPreviewViewControllerDelegate >
- (void)photoPreviewCellDownloadImageComplete:(HXPhotoPreviewViewController *)previewController model:(HXPhotoModel *)model {
    if (model.dateCellIsVisible && !model.loadOriginalImage) {
        NSIndexPath *indexPath = [NSIndexPath indexPathForItem:[self dateItem:model] inSection:model.dateSection];
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
        NSIndexPath *indexPath = [NSIndexPath indexPathForItem:[self dateItem:model] inSection:model.dateSection];
        [self.collectionView reloadItemsAtIndexPaths:@[indexPath]];
    }
    [self.manager addICloudModel:model];
}
- (void)photoPreviewControllerDidSelect:(HXPhotoPreviewViewController *)previewController model:(HXPhotoModel *)model {
    NSMutableArray *indexPathList = [NSMutableArray array];
    if (model.currentAlbumIndex == self.albumModel.index) {
        [indexPathList addObject:[NSIndexPath indexPathForItem:[self dateItem:model] inSection:model.dateSection]];
    }
    if (!model.selected) {
        NSInteger index = 0;
        for (HXPhotoModel *subModel in [self.manager selectedArray]) {
            subModel.selectIndexStr = [NSString stringWithFormat:@"%ld",index + 1];
            if (subModel.currentAlbumIndex == self.albumModel.index && subModel.dateCellIsVisible) {
                NSIndexPath *indexPath = [NSIndexPath indexPathForItem:[self dateItem:subModel] inSection:subModel.dateSection];
                [indexPathList addObject:indexPath];
            }
            index++;
        }
    }
    
    if (self.manager.videoSelectedType == HXPhotoManagerVideoSelectedTypeSingle) {
        for (UICollectionViewCell *tempCell in self.collectionView.visibleCells) {
            if ([tempCell isKindOfClass:[HXPhotoViewCell class]]) {
                if ([(HXPhotoViewCell *)tempCell model].subType == HXPhotoModelMediaSubTypeVideo &&
                    [(HXPhotoViewCell *)tempCell model] != model) {
                    [indexPathList addObject:[self.collectionView indexPathForCell:tempCell]];
                }
            }
        }
    }
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
    model.currentAlbumIndex = self.albumModel.index;
    
    [self photoPreviewControllerDidSelect:nil model:beforeModel];
    [self collectionViewAddModel:model beforeModel:beforeModel];
    
//    [self photoBottomViewDidDoneBtn];
}
- (void)photoPreviewSingleSelectedClick:(HXPhotoPreviewViewController *)previewController model:(HXPhotoModel *)model {
    [self.manager beforeSelectedListAddPhotoModel:model];
    [self photoBottomViewDidDoneBtn];
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
//    [self customCameraViewController:nil didDone:afterModel];
    
    afterModel.currentAlbumIndex = self.albumModel.index;
    afterModel.clarityScale = self.manager.configuration.clarityScale;
    [self.manager beforeListAddCameraTakePicturesModel:afterModel];
    [self collectionViewAddModel:afterModel beforeModel:beforeModel];
}
#pragma mark - < HXVideoEditViewControllerDelegate >
- (void)videoEditViewControllerDidDoneClick:(HXVideoEditViewController *)videoEditViewController beforeModel:(HXPhotoModel *)beforeModel afterModel:(HXPhotoModel *)afterModel {
    [self photoEditViewControllerDidClipClick:nil beforeModel:beforeModel afterModel:afterModel];
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
            self.albumTitleView.userInteractionEnabled = NO;
        }
        self.navigationController.viewControllers.lastObject.view.userInteractionEnabled = NO;
        [self.navigationController.viewControllers.lastObject.view hx_showLoadingHUDText:nil];
        HXWeakSelf
        if (self.manager.original) {
            [self.manager.selectedArray hx_requestImageSeparatelyWithOriginal:self.manager.original completion:^(NSArray<UIImage *> * _Nullable imageArray, NSArray<HXPhotoModel *> * _Nullable errorArray) {
                if (!weakSelf) {
                    return;
                }
                [weakSelf afterFinishingGetVideoURL];
            }];
        }else {
            [self.manager.selectedArray hx_requestImageWithOriginal:self.manager.original completion:^(NSArray<UIImage *> * _Nullable imageArray, NSArray<HXPhotoModel *> * _Nullable errorArray) {
                if (!weakSelf) {
                    return;
                }
                [weakSelf afterFinishingGetVideoURL];
            }];
        }
        return;
    }
    [self dismissVC];
}
- (void)afterFinishingGetVideoURL {
    NSArray *videoArray = self.manager.selectedVideoArray;
    if (videoArray.count) {
        HXWeakSelf
        __block NSInteger videoCount = videoArray.count;
        __block NSInteger videoIndex = 0;
        BOOL endOriginal = self.manager.configuration.exportVideoURLForHighestQuality ? self.manager.original : NO;
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
        self.albumTitleView.userInteractionEnabled = YES;
    }
    self.navigationController.navigationBar.userInteractionEnabled = YES;
    self.navigationController.viewControllers.lastObject.view.userInteractionEnabled = YES;
    [self.navigationController.viewControllers.lastObject.view hx_handleLoading];
    [self cleanSelectedList];
    self.manager.selectPhotoing = NO;
    [self dismissViewControllerAnimated:YES completion:nil];
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
        HXWeakSelf
        hx_showAlert(self, [NSBundle hx_localizedStringForKey:@"编辑后，GIF将会变为静态图，确定继续吗？"], nil, [NSBundle hx_localizedStringForKey:@"取消"], [NSBundle hx_localizedStringForKey:@"确定"], nil, ^{
            [weakSelf jumpEditViewControllerWithModel:model];
        });
        return;
    }
    if (model.type == HXPhotoModelMediaTypeLivePhoto) {
        HXWeakSelf
        hx_showAlert(self, [NSBundle hx_localizedStringForKey:@"编辑后，LivePhoto将会变为静态图，确定继续吗？"], nil, [NSBundle hx_localizedStringForKey:@"取消"], [NSBundle hx_localizedStringForKey:@"确定"], nil, ^{
            [weakSelf jumpEditViewControllerWithModel:model];
        });
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
            HXPhotoEditViewController *vc = [[HXPhotoEditViewController alloc] init];
            vc.isInside = YES;
            vc.model = self.manager.selectedPhotoArray.firstObject;
            vc.delegate = self;
            vc.manager = self.manager;
            vc.modalPresentationStyle = UIModalPresentationOverFullScreen;
            vc.modalPresentationCapturesStatusBarAppearance = YES;
            [self presentViewController:vc animated:YES completion:nil]; 
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
        _authorizationLb.textColor = [HXPhotoCommon photoCommon].isDark ? [UIColor whiteColor] : [UIColor blackColor];
        _authorizationLb.font = [UIFont systemFontOfSize:15];
        _authorizationLb.userInteractionEnabled = YES;
        [_authorizationLb addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(goSetup)]];
    }
    return _authorizationLb;
}
- (void)goSetup {
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]];
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
    [self.albumTitleView deSelect];
}
- (HXAlbumlistView *)albumView {
    if (!_albumView) {
        _albumView = [[HXAlbumlistView alloc] initWithManager:self.manager];
        HXWeakSelf
        _albumView.didSelectRowBlock = ^(HXAlbumModel *model) {
            [weakSelf.albumTitleView deSelect];
            if (weakSelf.albumModel == model) {
                return;
            }
            weakSelf.albumModel = model;
            weakSelf.albumTitleView.model = model;
            [weakSelf.view hx_showLoadingHUDText:nil];
            weakSelf.collectionViewReloadCompletion = NO;
            [weakSelf.manager getPhotoListWithAlbumModel:weakSelf.albumModel complete:nil];
        };
    }
    return _albumView;
}
- (HXAlbumTitleView *)albumTitleView {
    if (!_albumTitleView) {
        _albumTitleView = [[HXAlbumTitleView alloc] initWithManager:self.manager];
        HXWeakSelf
        _albumTitleView.didTitleViewBlock = ^(BOOL selected) {
            if (!weakSelf.allArray.count) {
                return;
            }
            if (selected) {
                if (!weakSelf.firstDidAlbumTitleView) {
                    [weakSelf.albumView refreshCamearCount];
                    weakSelf.firstDidAlbumTitleView = YES;
                }
                weakSelf.albumBgView.hidden = NO;
                weakSelf.albumBgView.alpha = 0;
                UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
                CGFloat navBarHeight = hxNavigationBarHeight;
                if (orientation == UIInterfaceOrientationPortrait || orientation == UIInterfaceOrientationPortraitUpsideDown) {
                    navBarHeight = hxNavigationBarHeight;
                }else if (orientation == UIInterfaceOrientationLandscapeRight || orientation == UIInterfaceOrientationLandscapeLeft){
                    if ([UIApplication sharedApplication].statusBarHidden) {
                        navBarHeight = weakSelf.navigationController.navigationBar.hx_h;
                    }else {
                        navBarHeight = weakSelf.navigationController.navigationBar.hx_h + 20;
                    }
                }
                [weakSelf.albumView selectCellScrollToCenter];
                [UIView animateWithDuration:0.25 animations:^{
                    weakSelf.albumBgView.alpha = 1;
                    weakSelf.albumView.hx_y = navBarHeight;
                }];
            }else {
                [UIView animateWithDuration:0.25 animations:^{
                    weakSelf.albumBgView.alpha = 0;
                    weakSelf.albumView.hx_y = -CGRectGetMaxY(weakSelf.albumView.frame);
                } completion:^(BOOL finished) {
                    if (!selected) {
                        weakSelf.albumBgView.hidden = YES;
                    }
                }];
            }
        };
    }
    return _albumTitleView;
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
- (HXPhotoViewFlowLayout *)customLayout {
    if (!_customLayout) {
        _customLayout = [[HXPhotoViewFlowLayout alloc] init];
        _customLayout.minimumLineSpacing = 1;
        _customLayout.minimumInteritemSpacing = 1;
        _customLayout.sectionInset = UIEdgeInsetsMake(0.5, 0, 0.5, 0);
    }
    return _customLayout;
}
- (UICollectionView *)collectionView {
    if (!_collectionView) {
        CGFloat collectionHeight = self.view.hx_h;
        if (self.manager.configuration.showDateSectionHeader) {
            _collectionView = [[UICollectionView alloc] initWithFrame:CGRectMake(0, 0, self.view.hx_w, collectionHeight) collectionViewLayout:self.customLayout];
        }else {
            _collectionView = [[UICollectionView alloc] initWithFrame:CGRectMake(0, 0, self.view.hx_w, collectionHeight) collectionViewLayout:self.flowLayout];
        }
        _collectionView.dataSource = self;
        _collectionView.delegate = self;
        _collectionView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        _collectionView.alwaysBounceVertical = YES;
        [_collectionView registerClass:[HXPhotoViewCell class] forCellWithReuseIdentifier:@"DateCellId"];
        [_collectionView registerClass:[HXPhotoCameraViewCell class] forCellWithReuseIdentifier:@"DateCameraCellId"];
        [_collectionView registerClass:[HXPhotoViewSectionHeaderView class] forSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:@"sectionHeaderId"];
        [_collectionView registerClass:[HXPhotoViewSectionFooterView class] forSupplementaryViewOfKind:UICollectionElementKindSectionFooter withReuseIdentifier:@"sectionFooterId"];
        
#ifdef __IPHONE_11_0
        if (@available(iOS 11.0, *)) {
//            if ([self hx_navigationBarWhetherSetupBackground]) {
//                self.navigationController.navigationBar.translucent = YES;
//            }
            _collectionView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
#else
        if ((NO)) {
#endif
        } else {
//            if ([self hx_navigationBarWhetherSetupBackground]) {
//                self.navigationController.navigationBar.translucent = YES;
//            }
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
- (NSMutableArray *)allArray {
    if (!_allArray) {
        _allArray = [NSMutableArray array];
    }
    return _allArray;
}
- (NSMutableArray *)photoArray {
    if (!_photoArray) {
        _photoArray = [NSMutableArray array];
    }
    return _photoArray;
}
- (NSMutableArray *)videoArray {
    if (!_videoArray) {
        _videoArray = [NSMutableArray array];
    }
    return _videoArray;
}
- (NSMutableArray *)previewArray {
    if (!_previewArray) {
        _previewArray = [NSMutableArray array];
    }
    return _previewArray;
}
- (NSMutableArray *)dateArray {
    if (!_dateArray) {
        _dateArray = [NSMutableArray array];
    }
    return _dateArray;
}
@end
@interface HXPhotoCameraViewCell ()<AVCaptureVideoDataOutputSampleBufferDelegate>
@property (strong, nonatomic) UIButton *cameraBtn;
@property (nonatomic, strong) AVCaptureVideoPreviewLayer *previewLayer;
@property (strong, nonatomic) UIVisualEffectView *effectView;
@property (strong, nonatomic) UIView *previewView;
@property (strong, nonatomic) UIImageView *tempCameraView;
@property (strong, nonatomic) AVCaptureVideoDataOutput *captureDataOutput;
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
                self.cameraBtn.selected = self.session.isRunning;
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
    if (self.session) {
        return;
    }
    self.startSession = YES;
    HXWeakSelf
    [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(BOOL granted) {
        if (granted) {
            dispatch_async(dispatch_get_main_queue(), ^{
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                    weakSelf.session = [[AVCaptureSession alloc] init];
                    weakSelf.previewLayer = [AVCaptureVideoPreviewLayer layerWithSession:weakSelf.session];
                    [weakSelf setupSeestion:weakSelf.session startSessionCompletion:^(BOOL success) {
                        if (success) {
                            dispatch_async(dispatch_get_main_queue(), ^{
                                HXStrongSelf
                                weakSelf.previewLayer.frame = weakSelf.bounds;
                                [weakSelf.previewView.layer insertSublayer:weakSelf.previewLayer atIndex:0];
                                weakSelf.cameraBtn.selected = YES;
                                if (weakSelf.tempCameraView.image) {
                                    if (strongSelf->_effectView) {
                                        [UIView animateWithDuration:0.2 animations:^{
                                            weakSelf.tempCameraView.alpha = 0;
                                            weakSelf.effectView.effect = nil;
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
            });
        }
    }];
}
- (void)setupSeestion:(AVCaptureSession *)session startSessionCompletion:(void (^)(BOOL success))completion {
    session.sessionPreset = AVCaptureSessionPresetMedium;
    AVCaptureDevice *videoDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    AVCaptureDeviceInput *videoInput = [AVCaptureDeviceInput deviceInputWithDevice:videoDevice error:nil];
    if (videoInput) {
        if ([session canAddInput:videoInput]) {
            [session addInput:videoInput];
        }
        if (HXGetCameraContentInRealTime) {
            if ([session canAddOutput:self.captureDataOutput]) {
                [session addOutput:self.captureDataOutput];
            }
        }
    }else {
        if (completion) {
            completion(NO);
        }
        return;
    }
    self.previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    [session startRunning];
    if (completion) {
        completion(YES);
    }
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
    if (!self.session) {
        return;
    }
    AVCaptureSession *session = self.session;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        if (session.isRunning) {
            [session stopRunning];
        }
        for (AVCaptureInput *input in session.inputs) {
            [session removeInput:input];
        }
        for (AVCaptureOutput *output in session.outputs) {
            [session removeOutput:output];
        }
    });
    if (HXGetCameraContentInRealTime) {
        [self.captureDataOutput setSampleBufferDelegate:nil queue:NULL];
        self.captureDataOutput = nil;
    }
    
    self.session = nil;
    self.cameraBtn.selected = NO;
}
- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {

    UIImage *image = [self imageFromSampleBuffer:sampleBuffer];
    image = [image hx_rotationImage:UIImageOrientationRight];
    [HXPhotoCommon photoCommon].cameraImage = image;
}
- (UIImage *) imageFromSampleBuffer:(CMSampleBufferRef) sampleBuffer {
    // Get a CMSampleBuffer's Core Video image buffer for the media data
    CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    // Lock the base address of the pixel buffer
    CVPixelBufferLockBaseAddress(imageBuffer, 0);

    // Get the number of bytes per row for the pixel buffer
    void *baseAddress = CVPixelBufferGetBaseAddress(imageBuffer);

    // Get the number of bytes per row for the pixel buffer
    size_t bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer);
    // Get the pixel buffer width and height
    size_t width = CVPixelBufferGetWidth(imageBuffer);
    size_t height = CVPixelBufferGetHeight(imageBuffer);

    // Create a device-dependent RGB color space
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();

    // Create a bitmap graphics context with the sample buffer data
    CGContextRef context = CGBitmapContextCreate(baseAddress, width, height, 8,
                                             bytesPerRow, colorSpace, kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst);
    // Create a Quartz image from the pixel data in the bitmap graphics context
    CGImageRef quartzImage = CGBitmapContextCreateImage(context);
    // Unlock the pixel buffer
    CVPixelBufferUnlockBaseAddress(imageBuffer,0);

    // Free up the context and color space
    CGContextRelease(context);
    CGColorSpaceRelease(colorSpace);

    // Create an image object from the Quartz image
    UIImage *image = [UIImage imageWithCGImage:quartzImage];

    // Release the Quartz image
    CGImageRelease(quartzImage);

    return (image);
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
    self.previewLayer.frame = self.bounds;
    self.effectView.frame = self.bounds;
    self.tempCameraView.frame = self.bounds;
}
- (void)removeOutputDelegate {
    if (!self.session) {
        return;
    }
    if (self.captureDataOutput.sampleBufferDelegate) {
        [self.captureDataOutput setSampleBufferDelegate:nil queue:NULL];
    }
}
- (void)addOutputDelegate {
    if (!self.session) {
        return;
    }
    if (!self.captureDataOutput.sampleBufferDelegate) {
        dispatch_queue_t queue = dispatch_queue_create("cameraQueue", NULL);
        [self.captureDataOutput setSampleBufferDelegate:self queue:queue];
    }
}
- (void)willRemoveSubview:(UIView *)subview {
    [super willRemoveSubview:subview];
    [subview.layer removeAllAnimations];
}
- (void)dealloc {
    [self stopRunning];
    if (HXShowLog) NSSLog(@"camera - dealloc");
}
- (AVCaptureVideoDataOutput *)captureDataOutput {
    if (!_captureDataOutput) {
        _captureDataOutput = [[AVCaptureVideoDataOutput alloc] init];
        _captureDataOutput.alwaysDiscardsLateVideoFrames = YES;
        NSString* formatKey = (NSString*)kCVPixelBufferPixelFormatTypeKey;
        NSNumber* value = [NSNumber numberWithUnsignedInt:kCVPixelFormatType_32BGRA];
        NSDictionary* videoSettings = [NSDictionary dictionaryWithObject:value forKey:formatKey];
        [_captureDataOutput setVideoSettings:videoSettings];
    }
    return _captureDataOutput;
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
- (UIImageView *)tempCameraView {
    if (!_tempCameraView) {
        _tempCameraView = [[UIImageView alloc] init];
        _tempCameraView.contentMode = UIViewContentModeScaleAspectFill;
        _tempCameraView.clipsToBounds = YES;
    }
    return _tempCameraView;
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
@property (strong, nonatomic) HXDownloadProgressView *downloadView;
@property (strong, nonatomic) HXCircleProgressView *progressView;
@property (strong, nonatomic) CALayer *videoMaskLayer;
@property (strong, nonatomic) UIView *highlightMaskView;
@end

@implementation HXPhotoViewCell
- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
    [super traitCollectionDidChange:previousTraitCollection];

#ifdef __IPHONE_13_0
    if (@available(iOS 13.0, *)) {
        if ([self.traitCollection hasDifferentColorAppearanceComparedToTraitCollection:previousTraitCollection]) {
            if ([HXPhotoCommon photoCommon].isDark) {
                self.selectMaskLayer.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.2].CGColor;
            }else {
                self.selectMaskLayer.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:0.2].CGColor;
            }
            self.imageView.backgroundColor = [HXPhotoCommon photoCommon].isDark ? [UIColor colorWithRed:0.1 green:0.1 blue:0.1 alpha:1] : [UIColor colorWithRed:0.95 green:0.95 blue:0.95 alpha:1];

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
    [self.contentView addSubview:self.downloadView];
    [self.contentView addSubview:self.progressView];
    [self.contentView addSubview:self.highlightMaskView];
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
        [self.selectBtn removeFromSuperview];
    }
}
- (void)resetNetworkImage {
    if (self.model.networkPhotoUrl &&
        self.model.type == HXPhotoModelMediaTypeCameraPhoto) {
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
- (void)setModel:(HXPhotoModel *)model {
    _model = model;
    self.progressView.hidden = YES;
    self.progressView.progress = 0;
    self.maskView.hidden = !self.imageView.image;
    HXWeakSelf
    if (model.type == HXPhotoModelMediaTypeCamera ||
        model.type == HXPhotoModelMediaTypeCameraPhoto ||
        model.type == HXPhotoModelMediaTypeCameraVideo) {
        self.imageView.image = model.thumbPhoto;
        if (model.networkPhotoUrl) {
            self.progressView.hidden = model.downloadComplete;
            CGFloat progress = (CGFloat)model.receivedSize / model.expectedSize;
            self.progressView.progress = progress;
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
            }]; 
        }else {
            self.maskView.hidden = NO;
        }
    }else {
        self.requestID = [self.model highQualityRequestThumbImageWithSize:CGSizeMake(10, 10) completion:^(UIImage * _Nullable image, HXPhotoModel * _Nullable model, NSDictionary * _Nullable info) {
            if (weakSelf.model == model) {
                weakSelf.maskView.hidden = NO;
                weakSelf.imageView.image = image;
                weakSelf.requestID = [weakSelf.model requestThumbImageCompletion:^(UIImage *image, HXPhotoModel *model, NSDictionary *info) {
                    if (weakSelf.model == model) {
                        weakSelf.imageView.image = image;
                    }
                }];
            }
        }];
    }
    if (model.type == HXPhotoModelMediaTypePhotoGif) {
        self.stateLb.text = @"GIF";
        self.stateLb.hidden = NO;
        self.bottomMaskLayer.hidden = NO;
    }else if (model.type == HXPhotoModelMediaTypeLivePhoto) {
        self.stateLb.text = @"Live";
        self.stateLb.hidden = NO;
        self.bottomMaskLayer.hidden = NO;
    }else {
        if (model.subType == HXPhotoModelMediaSubTypeVideo) {
            self.stateLb.text = model.videoTime;
            self.stateLb.hidden = NO;
            self.bottomMaskLayer.hidden = NO;
        }else {
            if (model.cameraPhotoType == HXPhotoModelMediaTypeCameraPhotoTypeNetWorkGif) {
                self.stateLb.text = @"GIF";
                self.stateLb.hidden = NO;
                self.bottomMaskLayer.hidden = NO;
            }else if (model.cameraPhotoType == HXPhotoModelMediaTypeCameraPhotoTypeLocalLivePhoto) {
                self.stateLb.text = @"Live";
                self.stateLb.hidden = NO;
                self.bottomMaskLayer.hidden = NO;
            }else {
                self.stateLb.hidden = YES;
                self.bottomMaskLayer.hidden = YES;
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
        self.userInteractionEnabled = YES;
    }else {
        // 当前是否需要隐藏选择按钮
        if (model.needHideSelectBtn) {
            // 当前视频是否不可选
            self.videoMaskLayer.hidden = !model.videoUnableSelect;
        }else {
            self.videoMaskLayer.hidden = YES;
            self.userInteractionEnabled = YES;
        }
    }
    
    if (model.iCloudDownloading) {
        if (model.isICloud) {
            self.downloadView.progress = model.iCloudProgress;
            [self startRequestICloudAsset];
        }else {
            model.iCloudDownloading = NO;
            self.downloadView.hidden = YES;
        }
    }else {
        self.downloadView.hidden = YES;
    }
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
    self.downloadView.hidden = NO;
    [self.downloadView startAnima];
    self.iCloudIcon.hidden = YES;
    self.iCloudMaskLayer.hidden = YES;
    HXWeakSelf
    if (self.model.type == HXPhotoModelMediaTypeVideo) {
        self.iCloudRequestID = [self.model requestAVAssetStartRequestICloud:^(PHImageRequestID iCloudRequestId, HXPhotoModel *model) {
            if (weakSelf.model == model) {
                weakSelf.downloadView.hidden = NO;
                weakSelf.iCloudRequestID = iCloudRequestId;
            }
        } progressHandler:^(double progress, HXPhotoModel *model) {
            if (weakSelf.model == model) {
                weakSelf.downloadView.hidden = NO;
                weakSelf.downloadView.progress = progress;
            }
        } success:^(AVAsset *avAsset, AVAudioMix *audioMix, HXPhotoModel *model, NSDictionary *info) {
            if (weakSelf.model == model) {
                weakSelf.model.isICloud = NO;
                weakSelf.downloadView.progress = 1;
                if ([weakSelf.delegate respondsToSelector:@selector(photoViewCellRequestICloudAssetComplete:)]) {
                    [weakSelf.delegate photoViewCellRequestICloudAssetComplete:weakSelf];
                }
            }
        } failed:^(NSDictionary *info, HXPhotoModel *model) {
            if (weakSelf.model == model) {
                [weakSelf downloadError:info];
            }
        }];
    }else if (self.model.type == HXPhotoModelMediaTypeLivePhoto){
        self.iCloudRequestID = [self.model requestLivePhotoWithSize:CGSizeMake(self.model.previewViewSize.width * 1.5, self.model.previewViewSize.height * 1.5) startRequestICloud:^(PHImageRequestID iCloudRequestId, HXPhotoModel *model) {
            if (weakSelf.model == model) {
                weakSelf.downloadView.hidden = NO;
                weakSelf.iCloudRequestID = iCloudRequestId;
            }
        } progressHandler:^(double progress, HXPhotoModel *model) {
            if (weakSelf.model == model) {
                weakSelf.downloadView.hidden = NO;
                weakSelf.downloadView.progress = progress;
            }
        } success:^(PHLivePhoto *livePhoto, HXPhotoModel *model, NSDictionary *info) {
            if (weakSelf.model == model) {
                weakSelf.model.isICloud = NO;
                weakSelf.downloadView.progress = 1;
                if ([weakSelf.delegate respondsToSelector:@selector(photoViewCellRequestICloudAssetComplete:)]) {
                    [weakSelf.delegate photoViewCellRequestICloudAssetComplete:weakSelf];
                }
            }
        } failed:^(NSDictionary *info, HXPhotoModel *model) {
            if (weakSelf.model == model) {
                [weakSelf downloadError:info];
            }
        }];
    }else {
        self.iCloudRequestID = [self.model requestImageDataStartRequestICloud:^(PHImageRequestID iCloudRequestId, HXPhotoModel *model) {
            if (weakSelf.model == model) {
                weakSelf.downloadView.hidden = NO;
                weakSelf.iCloudRequestID = iCloudRequestId;
            }
        } progressHandler:^(double progress, HXPhotoModel *model) {
            if (weakSelf.model == model) {
                weakSelf.downloadView.hidden = NO;
                weakSelf.downloadView.progress = progress;
            }
        } success:^(NSData *imageData, UIImageOrientation orientation, HXPhotoModel *model, NSDictionary *info) {
            if (weakSelf.model == model) {
                weakSelf.model.isICloud = NO;
                weakSelf.downloadView.progress = 1;
                if ([weakSelf.delegate respondsToSelector:@selector(photoViewCellRequestICloudAssetComplete:)]) {
                    [weakSelf.delegate photoViewCellRequestICloudAssetComplete:weakSelf];
                }
            }
        } failed:^(NSDictionary *info, HXPhotoModel *model) {
            if (weakSelf.model == model) {
                [weakSelf downloadError:info];
            }
        }];
    }
}
- (void)downloadError:(NSDictionary *)info {
    if (![[info objectForKey:PHImageCancelledKey] boolValue]) {
        [[self hx_viewController].view hx_showImageHUDText:[NSBundle hx_localizedStringForKey:@"下载失败，请重试！"]];
    }
    self.downloadView.hidden = YES;
    [self.downloadView resetState];
    self.iCloudIcon.hidden = !self.model.isICloud;
    self.iCloudMaskLayer.hidden = !self.model.isICloud;
}
- (void)cancelRequest {
#if HasYYWebImage
//    [self.imageView yy_cancelCurrentImageRequest];
#elif HasYYKit
//    [self.imageView cancelCurrentImageRequest];
#elif HasSDWebImage
//    [self.imageView sd_cancelCurrentAnimationImagesLoad];
#endif
    if (self.requestID) {
        [[PHImageManager defaultManager] cancelImageRequest:self.requestID];
        self.requestID = -1;
    }
    if (self.iCloudRequestID) {
        [[PHImageManager defaultManager] cancelImageRequest:self.iCloudRequestID];
        self.iCloudRequestID = -1;
    }
}
- (void)didSelectClick:(UIButton *)button {
    if (self.model.type == HXPhotoModelMediaTypeCamera) {
        return;
    }
    if (self.model.isICloud) {
        return;
    }
    if ([self.delegate respondsToSelector:@selector(photoViewCell:didSelectBtn:)]) {
        [self.delegate photoViewCell:self didSelectBtn:button];
    }
}
- (void)setHighlighted:(BOOL)highlighted {
    [super setHighlighted:highlighted];
    self.highlightMaskView.hidden = !highlighted;
}
- (void)layoutSubviews {
    [super layoutSubviews];
    self.imageView.frame = self.bounds;
    self.maskView.frame = self.bounds;
    self.stateLb.frame = CGRectMake(0, self.hx_h - 18, self.hx_w - 4, 18);
    self.bottomMaskLayer.frame = CGRectMake(0, self.hx_h - 25, self.hx_w, 25);
    self.selectBtn.hx_size = CGSizeMake(30, 30);
    self.selectBtn.hx_x = self.hx_w - self.selectBtn.hx_w;
    self.selectBtn.hx_y = 0;
    self.selectMaskLayer.frame = self.bounds;
    self.iCloudMaskLayer.frame = self.bounds;
    self.iCloudIcon.hx_x = self.hx_w - 3 - self.iCloudIcon.hx_w;
    self.iCloudIcon.hx_y = 3;
    self.downloadView.frame = self.bounds;
    self.progressView.center = CGPointMake(self.hx_w / 2, self.hx_h / 2);
    self.videoMaskLayer.frame = self.bounds;
    self.highlightMaskView.frame = self.bounds;
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
- (HXDownloadProgressView *)downloadView {
    if (!_downloadView) {
        _downloadView = [[HXDownloadProgressView alloc] initWithFrame:self.bounds];
    }
    return _downloadView;
}
- (HXCircleProgressView *)progressView {
    if (!_progressView) {
        _progressView = [[HXCircleProgressView alloc] init];
        _progressView.hidden = YES;
    }
    return _progressView;
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
        [_maskView.layer addSublayer:self.videoMaskLayer];
        [_maskView addSubview:self.iCloudIcon];
        [_maskView addSubview:self.stateLb];
        [_maskView addSubview:self.selectBtn];
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
        if ([HXPhotoCommon photoCommon].isDark) {
            _selectMaskLayer.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.2].CGColor;
        }else {
            _selectMaskLayer.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:0.3].CGColor;
        }
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
        _videoMaskLayer.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.5].CGColor;
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
        [_selectBtn setBackgroundImage:bgImage forState:UIControlStateSelected];
        [_selectBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateSelected];
        _selectBtn.titleLabel.font = [UIFont systemFontOfSize:15];
        _selectBtn.titleLabel.adjustsFontSizeToFitWidth = YES;
        [_selectBtn addTarget:self action:@selector(didSelectClick:) forControlEvents:UIControlEventTouchUpInside];
        [_selectBtn hx_setEnlargeEdgeWithTop:0 right:0 bottom:15 left:15];
    }
    return _selectBtn;
}
@end

@interface HXPhotoViewSectionHeaderView ()
@property (strong, nonatomic) UILabel *dateLb;
@property (strong, nonatomic) UILabel *subTitleLb;
@property (strong, nonatomic) UIToolbar *bgView;
@end

@implementation HXPhotoViewSectionHeaderView
- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
    [super traitCollectionDidChange:previousTraitCollection];
#ifdef __IPHONE_13_0
    if (@available(iOS 13.0, *)) {
        if ([self.traitCollection hasDifferentColorAppearanceComparedToTraitCollection:previousTraitCollection]) {
            [self setChangeState:self.changeState];
        }
    }
#endif
}
- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setupUI];
        [self setChangeState:self.changeState];
    }
    return self;
}
- (void)setupUI {
    [self addSubview:self.bgView];
    [self addSubview:self.dateLb];
    [self addSubview:self.subTitleLb];
}
- (void)setChangeState:(BOOL)changeState {
    _changeState = changeState;
    if (self.translucent) {
        self.bgView.translucent = changeState;
    }
    if (self.suspensionBgColor) {
        self.translucent = NO;
    }
    if (changeState) {
//        if (self.translucent) {
            self.bgView.alpha = 1;
//        }
        if (self.suspensionTitleColor) {
            self.dateLb.textColor = self.suspensionTitleColor;
            self.subTitleLb.textColor = self.suspensionTitleColor;
        }
        if (self.suspensionBgColor) {
            self.bgView.barTintColor = self.suspensionBgColor;
        }else {
            self.bgView.barTintColor = nil;
        }
    }else {
        if (!self.translucent) {
            self.bgView.barTintColor = [HXPhotoCommon photoCommon].isDark ? [UIColor blackColor] : [UIColor whiteColor];
        }
//        if (self.translucent) {
            self.bgView.alpha = 0;
//        }
        self.dateLb.textColor = [HXPhotoCommon photoCommon].isDark ? [UIColor whiteColor] : [UIColor blackColor];
        if ([HXPhotoCommon photoCommon].isDark) {
            self.subTitleLb.textColor = [UIColor whiteColor];
        }else {
            self.subTitleLb.textColor = [UIColor colorWithRed:140.f / 255.f green:140.f / 255.f blue:140.f / 255.f alpha:1];
        }
    }
}
- (void)setTranslucent:(BOOL)translucent {
    _translucent = translucent;
    if (!translucent) {
        self.bgView.translucent = YES;
        self.bgView.barTintColor = [HXPhotoCommon photoCommon].isDark ? [UIColor blackColor] : [UIColor whiteColor];
    }
}
- (void)setModel:(HXPhotoDateModel *)model {
    _model = model;
    if (model.location) {
        if (model.hasLocationTitles) {
            [self updateDateData];
        }else {
            self.dateLb.frame = CGRectMake(8, 0, self.hx_w - 16, 50);
            self.dateLb.text = model.dateString;
            self.subTitleLb.hidden = YES;
            HXWeakSelf
            [HXPhotoTools getDateLocationDetailInformationWithModel:model completion:^(CLPlacemark * _Nullable placemark, HXPhotoDateModel *model, NSError * _Nullable error) {
                if (!error) {
                    if (placemark.locality) {
                        NSString *province = placemark.administrativeArea;
                        NSString *city = placemark.locality;
                        NSString *area = placemark.subLocality;
                        NSString *street = placemark.thoroughfare;
                        NSString *subStreet = placemark.subThoroughfare;
                        if (area) {
                            model.locationTitle = [NSString stringWithFormat:@"%@ ﹣ %@",city,area];
                        }else {
                            model.locationTitle = [NSString stringWithFormat:@"%@",city];
                        }
                        if (street) {
                            if (subStreet) {
                                model.locationSubTitle = [NSString stringWithFormat:@"%@・%@%@",model.dateString,street,subStreet];
                            }else {
                                model.locationSubTitle = [NSString stringWithFormat:@"%@・%@",model.dateString,street];
                            }
                        }else if (province) {
                            model.locationSubTitle = [NSString stringWithFormat:@"%@・%@",model.dateString,province];
                        }else {
                            model.locationSubTitle = [NSString stringWithFormat:@"%@・%@",model.dateString,city];
                        }
                    }else {
                        NSString *province = placemark.administrativeArea;
                        model.locationSubTitle = [NSString stringWithFormat:@"%@・%@",model.dateString,province];
                        model.locationTitle = province;
                    }
                    model.locationError = NO;
                }else {
                    model.locationError = YES;
                }
                if (weakSelf.model == model) {
                    weakSelf.model.hasLocationTitles = YES;
                    [weakSelf updateDateData];
                }
            }];
        }
    }else {
        self.dateLb.frame = CGRectMake(8, 0, self.hx_w - 16, 50);
        self.dateLb.text = model.dateString;
        self.subTitleLb.hidden = YES;
    }
}
- (void)updateDateData {
    if (self.model.locationError) {
        self.dateLb.frame = CGRectMake(8, 0, self.hx_w - 16, 50);
        self.subTitleLb.hidden = YES;
        self.dateLb.text = self.model.dateString;
    }else {
        if (self.model.locationSubTitle) {
            self.dateLb.frame = CGRectMake(8, 4, self.hx_w - 16, 30);
            self.subTitleLb.frame = CGRectMake(8, 28, self.hx_w - 16, 20);
            self.subTitleLb.hidden = NO;
            self.subTitleLb.text = self.model.locationSubTitle;
        }else {
            self.dateLb.frame = CGRectMake(8, 0, self.hx_w - 16, 50);
            self.subTitleLb.hidden = YES;
        }
        self.dateLb.text = self.model.locationTitle;
    }
}
- (void)layoutSubviews {
    [super layoutSubviews];
    self.bgView.frame = self.bounds;
}
- (UILabel *)dateLb {
    if (!_dateLb) {
        _dateLb = [[UILabel alloc] init];
        _dateLb.font = [UIFont hx_boldPingFangOfSize:16];
    }
    return _dateLb;
}
- (UIToolbar *)bgView {
    if (!_bgView) {
        _bgView = [[UIToolbar alloc] init];
        _bgView.translucent = NO;
        _bgView.clipsToBounds = YES;
    }
    return _bgView;
}
- (UILabel *)subTitleLb {
    if (!_subTitleLb) {
        _subTitleLb = [[UILabel alloc] init];
        _subTitleLb.font = [UIFont hx_regularPingFangOfSize:12];
    }
    return _subTitleLb;
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
                self.backgroundColor = [UIColor whiteColor];
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
        self.backgroundColor = [UIColor whiteColor];
    }
    [self addSubview:self.titleLb];
}
- (void)setVideoCount:(NSInteger)videoCount {
    _videoCount = videoCount;
    UIColor *textColor = [HXPhotoCommon photoCommon].isDark ? [UIColor whiteColor] : [UIColor colorWithRed:51.f / 255.f green:51.f / 255.f blue:51.f / 255.f alpha:1];
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
    if ([HXPhotoCommon photoCommon].isDark) {
        themeColor = [UIColor whiteColor];
        selectedTitleColor = [UIColor whiteColor];
        self.bgView.barTintColor = [UIColor blackColor];
    }else {
        self.bgView.barTintColor = self.barTintColor;
        themeColor = self.manager.configuration.themeColor;
        selectedTitleColor = self.manager.configuration.selectedTitleColor;
    }
    
    [self.previewBtn setTitleColor:themeColor forState:UIControlStateNormal];
    [self.previewBtn setTitleColor:[themeColor colorWithAlphaComponent:0.5] forState:UIControlStateDisabled];
    
    [self.originalBtn setTitleColor:themeColor forState:UIControlStateNormal];
    [self.originalBtn setTitleColor:[themeColor colorWithAlphaComponent:0.5] forState:UIControlStateDisabled];
    
    UIImage *originalNormalImage = [[UIImage hx_imageNamed:self.manager.configuration.originalNormalImageName] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    UIImage *originalSelectedImage = [[UIImage hx_imageNamed:self.manager.configuration.originalSelectedImageName] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    [self.originalBtn setImage:originalNormalImage forState:UIControlStateNormal];
    [self.originalBtn setImage:originalSelectedImage forState:UIControlStateSelected];
    self.originalBtn.imageView.tintColor = themeColor;
    
    [self.editBtn setTitleColor:themeColor forState:UIControlStateNormal];
    [self.editBtn setTitleColor:[themeColor colorWithAlphaComponent:0.5] forState:UIControlStateDisabled];
    if ([themeColor isEqual:[UIColor whiteColor]]) {
        [self.doneBtn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        [self.doneBtn setTitleColor:[[UIColor blackColor] colorWithAlphaComponent:0.5] forState:UIControlStateDisabled];
    }
    if (selectedTitleColor) {
        [self.doneBtn setTitleColor:selectedTitleColor forState:UIControlStateNormal];
        [self.doneBtn setTitleColor:[selectedTitleColor colorWithAlphaComponent:0.5] forState:UIControlStateDisabled];
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
    UIColor *themeColor = [HXPhotoCommon photoCommon].isDark ? [UIColor colorWithRed:0.2 green:0.2 blue:0.2 alpha:1] : self.manager.configuration.themeColor;
    self.doneBtn.backgroundColor = self.doneBtn.enabled ? themeColor : [themeColor colorWithAlphaComponent:0.5];
    
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
    if (self.doneBtn.hx_w < 50) {
        self.doneBtn.hx_w = 50;
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
    
    self.doneBtn.frame = CGRectMake(0, 0, 50, 30);
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
        _doneBtn.titleLabel.font = [UIFont systemFontOfSize:14];
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
