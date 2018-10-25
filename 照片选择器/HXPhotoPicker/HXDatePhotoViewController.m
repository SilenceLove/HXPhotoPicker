//
//  HXDatePhotoViewController.m
//  照片选择器
//
//  Created by 洪欣 on 2017/10/14.
//  Copyright © 2017年 洪欣. All rights reserved.
//

#import "HXDatePhotoViewController.h"
#import "UIImage+HXExtension.h"
#import "HXPhoto3DTouchViewController.h"
#import "HXDatePhotoPreviewViewController.h"
#import "UIButton+HXExtension.h" 
#import "HXCustomCameraViewController.h"
#import "HXCustomNavigationController.h"
#import "HXCustomCameraController.h"
#import "HXCustomPreviewView.h"
#import "HXDatePhotoEditViewController.h"
#import "HXDatePhotoViewFlowLayout.h"
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
#import "HXDatePhotoToolManager.h"

@interface HXDatePhotoViewController ()
<
UICollectionViewDataSource,
UICollectionViewDelegate,
UICollectionViewDelegateFlowLayout,
UIViewControllerPreviewingDelegate,
HXDatePhotoViewCellDelegate,
HXDatePhotoBottomViewDelegate,
HXDatePhotoPreviewViewControllerDelegate,
HXCustomCameraViewControllerDelegate,
HXDatePhotoEditViewControllerDelegate
>
@property (strong, nonatomic) UICollectionViewFlowLayout *flowLayout;
@property (strong, nonatomic) UICollectionView *collectionView;
@property (strong, nonatomic) HXDatePhotoViewFlowLayout *customLayout;

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

@property (weak, nonatomic) HXDatePhotoViewSectionFooterView *footerView;
@property (assign, nonatomic) BOOL showBottomPhotoCount;

@property (strong, nonatomic) HXAlbumTitleView *albumTitleView;
@property (strong, nonatomic) HXAlbumlistView *albumView;
@property (strong, nonatomic) UIView *albumBgView;
@property (strong, nonatomic) UILabel *authorizationLb;
@property (strong, nonatomic) HXDatePhotoToolManager *toolManager;
@end

@implementation HXDatePhotoViewController
- (UIStatusBarStyle)preferredStatusBarStyle {
    return self.manager.configuration.statusBarStyle;
}
- (void)viewDidLoad {
    [super viewDidLoad];
    if (self.manager.configuration.showBottomPhotoDetail) {
        self.showBottomPhotoCount = YES;
        self.manager.configuration.showBottomPhotoDetail = NO;
    }
    if (self.manager.configuration.albumShowMode == HXPhotoAlbumShowModeDefault) {
        [self setupUI]; // 这里因为懒 😝😝
        [self changeSubviewFrame]; // 这里因为懒 😝😝
        [self.view showLoadingHUDText:nil];
        [self getPhotoList];
    }else if (self.manager.configuration.albumShowMode == HXPhotoAlbumShowModePopup) {
        [self.manager selectedListTransformBefore];
        [self setupUI]; // 这里因为懒 😝😝
        [self changeSubviewFrame]; // 这里因为懒 😝😝
        // 获取当前应用对照片的访问授权状态
        HXWeakSelf
        [self.view showLoadingHUDText:nil];
        [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if ([PHPhotoLibrary authorizationStatus] != PHAuthorizationStatusAuthorized) {
                    [weakSelf.view handleLoading];
                    [weakSelf.view addSubview:weakSelf.authorizationLb];
                    UIAlertController *alert = [UIAlertController alertControllerWithTitle:[NSBundle hx_localizedStringForKey:@"无法访问相册"] message:[NSBundle hx_localizedStringForKey:@"请在设置-隐私-相册中允许访问相册"] preferredStyle:UIAlertControllerStyleAlert];
                    [alert addAction:[UIAlertAction actionWithTitle:[NSBundle hx_localizedStringForKey:@"取消"] style:UIAlertActionStyleDefault handler:nil]];
                    [alert addAction:[UIAlertAction actionWithTitle:[NSBundle hx_localizedStringForKey:@"设置"] style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]];
                    }]];
                    [weakSelf presentViewController:alert animated:YES completion:nil];
                }else {
                    [weakSelf getAlbumList];
                }
            });
        }];
        [UINavigationBar appearance].translucent = YES; 
    }
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(deviceOrientationChanged:) name:UIApplicationDidChangeStatusBarOrientationNotification object:nil];
}
- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [[UIApplication sharedApplication] setStatusBarStyle:self.manager.configuration.statusBarStyle];
    if (self.needChangeViewFrame) {
        self.needChangeViewFrame = NO;
    }
}
- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    if (self.orientationDidChange) {
        [self changeSubviewFrame];
        self.orientationDidChange = NO;
    }
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
    if (orientation == UIInterfaceOrientationPortrait || UIInterfaceOrientationPortrait == UIInterfaceOrientationPortraitUpsideDown) {
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
    if (HX_IS_IPhoneX_All && (orientation == UIInterfaceOrientationLandscapeLeft || orientation == UIInterfaceOrientationLandscapeRight)) {
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
    
//    self.collectionView.contentInset = UIEdgeInsetsMake(navBarHeight, leftMargin, bottomMargin, rightMargin);
    if (!self.manager.configuration.singleSelected) {
        self.collectionView.contentInset = UIEdgeInsetsMake(navBarHeight, leftMargin, 50 + bottomMargin, rightMargin);
    } else {
        self.collectionView.contentInset = UIEdgeInsetsMake(navBarHeight, leftMargin, bottomMargin, rightMargin);
    }
    self.collectionView.scrollIndicatorInsets = _collectionView.contentInset;
    
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
    
    if (self.manager.configuration.photoListCollectionView) {
        self.manager.configuration.photoListCollectionView(self.collectionView);
    }
}
- (void)setupUI {
    
    self.currentSectionIndex = 0;
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:[NSBundle hx_localizedStringForKey:@"取消"] style:UIBarButtonItemStyleDone target:self action:@selector(didCancelClick)];
    self.view.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:self.collectionView];
    if (!self.manager.configuration.singleSelected) {
        [self.view addSubview:self.bottomView];
        self.bottomView.selectCount = self.manager.selectedArray.count;
        if (self.manager.configuration.photoListBottomView) {
            self.manager.configuration.photoListBottomView(self.bottomView);
        }
    }
    if (self.manager.configuration.albumShowMode == HXPhotoAlbumShowModePopup) {
        [self.albumTitleView layoutSubviews];
        self.navigationItem.titleView = self.albumTitleView;
        [self.view addSubview:self.albumBgView];
        [self.view addSubview:self.albumView];
        
        [self.navigationController.navigationBar setTintColor:self.manager.configuration.themeColor];
        if (self.manager.configuration.navBarBackgroudColor) {
            [self.navigationController.navigationBar setBackgroundColor:nil];
            [self.navigationController.navigationBar setBackgroundImage:nil forBarMetrics:UIBarMetricsDefault];
            self.navigationController.navigationBar.barTintColor = self.manager.configuration.navBarBackgroudColor;
        }
        if (self.manager.configuration.navigationBar) {
            self.manager.configuration.navigationBar(self.navigationController.navigationBar, self);
        }
    }
}
- (void)didCancelClick {
    if (self.manager.configuration.albumShowMode == HXPhotoAlbumShowModePopup) {
        [self.manager cancelBeforeSelectedList];
    }
    if ([self.delegate respondsToSelector:@selector(datePhotoViewControllerDidCancel:)]) {
        [self.delegate datePhotoViewControllerDidCancel:self];
    }
    [self dismissViewControllerAnimated:YES completion:nil];
}
- (HXDatePhotoViewCell *)currentPreviewCell:(HXPhotoModel *)model {
    if (!model || ![self.allArray containsObject:model]) {
        return nil;
    }
    
    NSIndexPath *indexPath = [NSIndexPath indexPathForItem:[self dateItem:model] inSection:model.dateSection];
    return (HXDatePhotoViewCell *)[self.collectionView cellForItemAtIndexPath:indexPath];
}
- (BOOL)scrollToModel:(HXPhotoModel *)model {
    if ([self.allArray containsObject:model]) {
        [self.collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForItem:[self dateItem:model] inSection:model.dateSection] atScrollPosition:UICollectionViewScrollPositionNone animated:NO];
        [self.collectionView reloadItemsAtIndexPaths:@[[NSIndexPath indexPathForItem:[self dateItem:model] inSection:model.dateSection]]];
    }
    return [self.allArray containsObject:model];
}
- (NSInteger)dateItem:(HXPhotoModel *)model {
    NSInteger dateItem = model.dateItem;
    if (self.manager.configuration.showDateSectionHeader && self.manager.configuration.reverseDate && model.dateSection != 0) {
        dateItem = model.dateItem;
    }else if (self.manager.configuration.showDateSectionHeader && !self.manager.configuration.reverseDate && model.dateSection != self.dateArray.count - 1) {
        dateItem = model.dateItem;
    }else {
        if (model.type == HXPhotoModelMediaTypeCameraPhoto || model.type == HXPhotoModelMediaTypeCameraVideo) {
            if (self.manager.configuration.showDateSectionHeader) {
                if (self.manager.configuration.reverseDate) {
                    HXPhotoDateModel *dateModel = self.dateArray.firstObject;
                    dateItem = [dateModel.photoModelArray indexOfObject:model];
                    //                    dateItem = cameraIndex + [self.manager.cameraList indexOfObject:model];
                    //                    model.dateItem = dateItem;
                }else {
                    HXPhotoDateModel *dateModel = self.dateArray.lastObject;
                    dateItem = [dateModel.photoModelArray indexOfObject:model];
                }
            }else {
                dateItem = [self.allArray indexOfObject:model];
            }
        }else {
            if (self.manager.configuration.showDateSectionHeader) {
                if (self.manager.configuration.reverseDate) {
                    HXPhotoDateModel *dateModel = self.dateArray.firstObject;
                    dateItem = [dateModel.photoModelArray indexOfObject:model];
                    //                    dateItem = model.dateItem + cameraIndex + cameraCount;
                }else {
                    //                    dateItem = model.dateItem;
                    HXPhotoDateModel *dateModel = self.dateArray.lastObject;
                    dateItem = [dateModel.photoModelArray indexOfObject:model];
                }
            }else {
                dateItem = [self.allArray indexOfObject:model];
            }
        }
    }
    return dateItem;
}
- (void)scrollToPoint:(HXDatePhotoViewCell *)cell rect:(CGRect)rect {
    UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
    CGFloat navBarHeight = hxNavigationBarHeight;
    if (orientation == UIInterfaceOrientationPortrait || UIInterfaceOrientationPortrait == UIInterfaceOrientationPortraitUpsideDown) {
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
- (void)getAlbumList {
    if (self.manager.albums.count > 0 &&
        self.manager.configuration.saveSystemAblum &&
        !self.manager.configuration.singleSelected) {
        [self.albumTitleView setupAlpha:NO];
        self.albumView.albumModelArray = self.manager.albums.mutableCopy;
        self.albumModel = self.albumView.albumModelArray.firstObject;
        self.albumTitleView.model = self.albumModel;
        [self getPhotoList];
        return;
    }
    HXWeakSelf
    [self.manager fetchAlbums:^(HXAlbumModel *selectedModel) {
        weakSelf.albumModel = selectedModel;
        weakSelf.albumTitleView.model = selectedModel;
        [weakSelf.albumTitleView setupAlpha:YES];
        [weakSelf getPhotoList];
    } albums:^(NSArray *albums) {
        weakSelf.albumView.albumModelArray = albums.mutableCopy;
    }];
}
- (void)getPhotoList {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        __weak typeof(self) weakSelf = self;
        [self.manager getPhotoListWithAlbumModel:self.albumModel complete:^(NSArray *allList, NSArray *previewList, NSArray *photoList, NSArray *videoList, NSArray *dateList, HXPhotoModel *firstSelectModel) {
            weakSelf.dateArray = [NSMutableArray arrayWithArray:dateList];
            weakSelf.photoArray = [NSMutableArray arrayWithArray:photoList];
            weakSelf.videoArray = [NSMutableArray arrayWithArray:videoList];
            weakSelf.allArray = [NSMutableArray arrayWithArray:allList];
            if (weakSelf.allArray.count && weakSelf.showBottomPhotoCount) {
                weakSelf.manager.configuration.showBottomPhotoDetail = YES;
            }
            weakSelf.previewArray = [NSMutableArray arrayWithArray:previewList];
            dispatch_async(dispatch_get_main_queue(), ^{
                [weakSelf.view handleLoading];
                CATransition *transition = [CATransition animation];
                transition.type = kCATransitionPush;
                transition.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
                transition.fillMode = kCAFillModeForwards;
                transition.duration = 0.1;
                transition.subtype = kCATransitionFade;
                [[weakSelf.collectionView layer] addAnimation:transition forKey:@""];
                [weakSelf.collectionView reloadData];
                if (!weakSelf.manager.configuration.reverseDate) {
                    if (weakSelf.manager.configuration.showDateSectionHeader && weakSelf.dateArray.count > 0) {
                        HXPhotoDateModel *dateModel = weakSelf.dateArray.lastObject;
                        if (dateModel.photoModelArray.count > 0) {
                            if (firstSelectModel) {
                                [weakSelf.collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForItem:[weakSelf dateItem:firstSelectModel] inSection:firstSelectModel.dateSection] atScrollPosition:UICollectionViewScrollPositionCenteredVertically animated:NO];
                            }else {
                                NSInteger forItem = (dateModel.photoModelArray.count - 1) <= 0 ? 0 : dateModel.photoModelArray.count - 1;
                                NSInteger inSection = (weakSelf.dateArray.count - 1) <= 0 ? 0 : weakSelf.dateArray.count - 1;
                                [weakSelf.collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForItem:forItem inSection:inSection] atScrollPosition:UICollectionViewScrollPositionBottom animated:NO];
                            }
                        }
                    }else {
                        if (weakSelf.allArray.count > 0) {
                            if (firstSelectModel) {
                                [weakSelf.collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForItem:[weakSelf.allArray indexOfObject:firstSelectModel] inSection:0] atScrollPosition:UICollectionViewScrollPositionCenteredVertically animated:NO];
                            }else {
                                NSInteger forItem = (weakSelf.allArray.count - 1) <= 0 ? 0 : weakSelf.allArray.count - 1;
                                [weakSelf.collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForItem:forItem inSection:0] atScrollPosition:UICollectionViewScrollPositionBottom animated:NO];
                            }
                        }
                    }
                }else {
                    if (firstSelectModel) {
                        if (weakSelf.manager.configuration.showDateSectionHeader) {
                            [weakSelf.collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForItem:[weakSelf dateItem:firstSelectModel] inSection:firstSelectModel.dateSection] atScrollPosition:UICollectionViewScrollPositionCenteredVertically animated:NO];
                        }else {
                            [weakSelf.collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForItem:[weakSelf.allArray indexOfObject:firstSelectModel] inSection:0] atScrollPosition:UICollectionViewScrollPositionCenteredVertically animated:NO];
                        }
                    }
                }
            });
        }];
    });
}
#pragma mark - < HXCustomCameraViewControllerDelegate >
- (void)customCameraViewController:(HXCustomCameraViewController *)viewController didDone:(HXPhotoModel *)model {
    if (self.manager.configuration.singleSelected) {
        if (model.type == HXPhotoModelMediaTypeCameraPhoto) {
            HXDatePhotoEditViewController *vc = [[HXDatePhotoEditViewController alloc] init];
            vc.delegate = self;
            vc.manager = self.manager;
            vc.model = model;
            [self.navigationController pushViewController:vc animated:NO];
        }else {
            HXDatePhotoPreviewViewController *previewVC = [[HXDatePhotoPreviewViewController alloc] init];
            previewVC.delegate = self;
            previewVC.modelArray = [NSMutableArray arrayWithObjects:model, nil];
            previewVC.manager = self.manager;
            previewVC.currentModelIndex = 0;
            self.navigationController.delegate = previewVC;
            [self.navigationController pushViewController:previewVC animated:YES];
        }
        return;
    }
    model.currentAlbumIndex = self.albumModel.index;
    [self.manager beforeListAddCameraTakePicturesModel:model];
    
    // 判断类型
    if (model.type == HXPhotoModelMediaTypeCameraPhoto) {
        if (self.manager.configuration.reverseDate) {
            [self.photoArray insertObject:model atIndex:0];
        }else {
            [self.photoArray addObject:model];
        }
    }else if (model.type == HXPhotoModelMediaTypeCameraVideo) {
        if (self.manager.configuration.reverseDate) {
            [self.videoArray insertObject:model atIndex:0];
        }else {
            [self.videoArray addObject:model];
        }
    }
    NSInteger cameraIndex = self.manager.configuration.openCamera ? 1 : 0;
    if (self.manager.configuration.reverseDate) {
        [self.allArray insertObject:model atIndex:cameraIndex];
        [self.previewArray insertObject:model atIndex:0];
    }else {
        NSInteger count = self.allArray.count - cameraIndex;
        [self.allArray insertObject:model atIndex:count];
        [self.previewArray addObject:model];
    }
    if (self.manager.configuration.showDateSectionHeader) {
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
    }else {
        if (self.manager.configuration.reverseDate) {
            [self.collectionView insertItemsAtIndexPaths:@[[NSIndexPath indexPathForItem:cameraIndex inSection:0]]];
        }else {
            NSInteger count = self.allArray.count - 1;
            [self.collectionView insertItemsAtIndexPaths:@[[NSIndexPath indexPathForItem:count - cameraIndex inSection:0]]];
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
        model = dateModel.photoModelArray[indexPath.item];
    }else {
        model = self.allArray[indexPath.item];
    }
    model.rowCount = self.manager.configuration.rowCount;
    //    model.dateSection = indexPath.section;
    //    model.dateItem = indexPath.item;
    model.dateCellIsVisible = YES;
    if (model.type == HXPhotoModelMediaTypeCamera) {
        HXDatePhotoCameraViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"DateCameraCellId" forIndexPath:indexPath];
        cell.model = model;
        if (self.manager.configuration.cameraCellShowPreview) {
            if (!cell.model.photoManager) {
                cell.model.photoManager = self.manager;
            }
            [cell starRunning];
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
        HXDatePhotoViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"DateCellId" forIndexPath:indexPath];
        cell.delegate = self;
        if (self.manager.configuration.cellSelectedTitleColor) {
            cell.selectedTitleColor = self.manager.configuration.cellSelectedTitleColor;
        }else if (self.manager.configuration.selectedTitleColor) {
            cell.selectedTitleColor = self.manager.configuration.selectedTitleColor;
        }
        if (self.manager.configuration.cellSelectedBgColor) {
            cell.selectBgColor = self.manager.configuration.cellSelectedBgColor;
        }else {
            cell.selectBgColor = self.manager.configuration.themeColor;
        }
        //        cell.section = indexPath.section;
        //        cell.item = indexPath.item;
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
            [self.view showImageHUDText:[NSBundle hx_localizedStringForKey:@"无法使用相机!"]];
            return;
        }
        __weak typeof(self) weakSelf = self;
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
                                    cameraType = HXPhotoConfigurationCameraTypeTypePhotoAndVideo;
                                }
                            }else {
                                cameraType = HXPhotoConfigurationCameraTypeTypePhotoAndVideo;
                            }
                        }
                        if (weakSelf.manager.configuration.shouldUseCamera) {
                            weakSelf.manager.configuration.shouldUseCamera(weakSelf, cameraType, weakSelf.manager);
                        }
                        weakSelf.manager.configuration.useCameraComplete = ^(HXPhotoModel *model) {
                            if (model.videoDuration > weakSelf.manager.configuration.videoMaxDuration) {
                                [weakSelf.view showImageHUDText:[NSBundle hx_localizedStringForKey:@"视频过大,无法选择"]];
                            }
                            [weakSelf customCameraViewController:nil didDone:model];
                        };
                        return;
                    }
                    HXDatePhotoCameraViewCell *cameraCell = (HXDatePhotoCameraViewCell *)[collectionView cellForItemAtIndexPath:indexPath];
                    if (cameraCell.cameraController.captureSession &&
                        !weakSelf.manager.tempCameraView) {
                        weakSelf.manager.tempCameraView = [cameraCell.previewView snapshotViewAfterScreenUpdates:YES];
                    }
                    HXCustomCameraViewController *vc = [[HXCustomCameraViewController alloc] init];
                    vc.delegate = weakSelf;
                    vc.manager = weakSelf.manager;
                    HXCustomNavigationController *nav = [[HXCustomNavigationController alloc] initWithRootViewController:vc];
                    nav.isCamera = YES;
                    nav.supportRotation = weakSelf.manager.configuration.supportRotation;
                    [weakSelf presentViewController:nav animated:YES completion:nil];
                }else {
                    UIAlertController *alert = [UIAlertController alertControllerWithTitle:[NSBundle hx_localizedStringForKey:@"无法使用相机"] message:[NSBundle hx_localizedStringForKey:@"请在设置-隐私-相机中允许访问相机"] preferredStyle:UIAlertControllerStyleAlert];
                    [alert addAction:[UIAlertAction actionWithTitle:[NSBundle hx_localizedStringForKey:@"取消"] style:UIAlertActionStyleDefault handler:nil]];
                    [alert addAction:[UIAlertAction actionWithTitle:[NSBundle hx_localizedStringForKey:@"设置"] style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]];
                    }]];
                    [weakSelf presentViewController:alert animated:YES completion:nil];
                }
            });
        }];
    }else {
        HXDatePhotoViewCell *cell = (HXDatePhotoViewCell *)[self.collectionView cellForItemAtIndexPath:indexPath];
        if (cell.model.videoUnableSelect) {
            [self.view showImageHUDText:[NSBundle hx_localizedStringForKey:@"视频不能和图片同时选择"]]; 
            return;
        }
        if (cell.model.isICloud) {
            if (self.manager.configuration.downloadICloudAsset) {
                if (!cell.model.iCloudDownloading) {
                    [cell startRequestICloudAsset];
                }
            }else {
                [self.view showImageHUDText:[NSBundle hx_localizedStringForKey:@"尚未从iCloud上下载，请至系统相册下载完毕后选择"]];
            }
            return;
        }
        if (!self.manager.configuration.singleSelected) {
            HXDatePhotoPreviewViewController *previewVC = [[HXDatePhotoPreviewViewController alloc] init];
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
                HXDatePhotoPreviewViewController *previewVC = [[HXDatePhotoPreviewViewController alloc] init];
                previewVC.delegate = self;
                previewVC.modelArray = self.previewArray;
                previewVC.manager = self.manager;
                previewVC.currentModelIndex = currentIndex;
                self.navigationController.delegate = previewVC;
                [self.navigationController pushViewController:previewVC animated:YES];
            }else {
                if (cell.model.subType == HXPhotoModelMediaSubTypePhoto) {
                    HXDatePhotoEditViewController *vc = [[HXDatePhotoEditViewController alloc] init];
                    vc.model = cell.model;
                    vc.delegate = self;
                    vc.manager = self.manager;
                    [self.navigationController pushViewController:vc animated:NO];
                }else {
                    HXDatePhotoPreviewViewController *previewVC = [[HXDatePhotoPreviewViewController alloc] init];
                    previewVC.delegate = self;
                    previewVC.modelArray = [NSMutableArray arrayWithObjects:cell.model, nil];
                    previewVC.manager = self.manager;
                    previewVC.currentModelIndex = 0;
                    self.navigationController.delegate = previewVC;
                    [self.navigationController pushViewController:previewVC animated:YES];
                }
            }
        }
    }
}
- (void)collectionView:(UICollectionView *)collectionView didEndDisplayingCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath {
    if ([cell isKindOfClass:[HXDatePhotoViewCell class]]) {
        [(HXDatePhotoViewCell *)cell cancelRequest];
    }
}
- (void)collectionView:(UICollectionView *)collectionView didEndDisplayingSupplementaryView:(UICollectionReusableView *)view forElementOfKind:(NSString *)elementKind atIndexPath:(NSIndexPath *)indexPath {
    if ([elementKind isEqualToString:UICollectionElementKindSectionHeader]) {
        //        NSSLog(@"headerSection消失");
    }
}
- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath {
    if ([kind isEqualToString:UICollectionElementKindSectionHeader] && self.manager.configuration.showDateSectionHeader) {
        HXDatePhotoViewSectionHeaderView *headerView = [collectionView dequeueReusableSupplementaryViewOfKind:kind withReuseIdentifier:@"sectionHeaderId" forIndexPath:indexPath];
        headerView.translucent = self.manager.configuration.sectionHeaderTranslucent;
        headerView.suspensionBgColor = self.manager.configuration.sectionHeaderSuspensionBgColor;
        headerView.suspensionTitleColor = self.manager.configuration.sectionHeaderSuspensionTitleColor;
        headerView.model = self.dateArray[indexPath.section];
        return headerView;
    }else if ([kind isEqualToString:UICollectionElementKindSectionFooter]) {
        if (self.manager.configuration.showBottomPhotoDetail) {
            HXDatePhotoViewSectionFooterView *footerView = [collectionView dequeueReusableSupplementaryViewOfKind:kind withReuseIdentifier:@"sectionFooterId" forIndexPath:indexPath];
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

- (UIViewController *)previewingContext:(id<UIViewControllerPreviewing>)previewingContext viewControllerForLocation:(CGPoint)location {
    NSIndexPath *indexPath = [self.collectionView indexPathForItemAtPoint:location];
    if (!indexPath) {
        return nil;
    }
    if (![[self.collectionView cellForItemAtIndexPath:indexPath] isKindOfClass:[HXDatePhotoViewCell class]]) {
        return nil;
    }
    HXDatePhotoViewCell *cell = (HXDatePhotoViewCell *)[self.collectionView cellForItemAtIndexPath:indexPath];
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
    HXPhotoModel *_model = cell.model;
    HXPhoto3DTouchViewController *vc = [[HXPhoto3DTouchViewController alloc] init];
    vc.model = _model;
    vc.indexPath = indexPath;
    vc.image = cell.imageView.image;
    HXWeakSelf
    vc.downloadImageComplete = ^(HXPhoto3DTouchViewController *vc, HXPhotoModel *model) {
        if (!model.loadOriginalImage) {
            HXDatePhotoViewCell *myCell = (HXDatePhotoViewCell *)[weakSelf.collectionView cellForItemAtIndexPath:vc.indexPath];
            if (myCell) {
                [myCell resetNetworkImage];
            }
        }
    };
    vc.preferredContentSize = _model.previewViewSize;
    return vc;
}
- (void)previewingContext:(id<UIViewControllerPreviewing>)previewingContext commitViewController:(UIViewController *)viewControllerToCommit {
    HXPhoto3DTouchViewController *vc = (HXPhoto3DTouchViewController *)viewControllerToCommit;
    HXDatePhotoViewCell *cell = (HXDatePhotoViewCell *)[self.collectionView cellForItemAtIndexPath:vc.indexPath];
    if (!self.manager.configuration.singleSelected) {
        HXDatePhotoPreviewViewController *previewVC = [[HXDatePhotoPreviewViewController alloc] init];
        previewVC.delegate = self;
        previewVC.modelArray = self.previewArray;
        previewVC.manager = self.manager;
#if __has_include(<YYWebImage/YYWebImage.h>) || __has_include("YYWebImage.h")
        cell.model.tempImage = vc.animatedImageView.image;
#else
        cell.model.tempImage = vc.imageView.image;
#endif
        NSInteger currentIndex = [self.previewArray indexOfObject:cell.model];
        previewVC.currentModelIndex = currentIndex;
        self.navigationController.delegate = previewVC;
        [self.navigationController pushViewController:previewVC animated:YES];
    }else {
        if (vc.model.subType == HXPhotoModelMediaSubTypePhoto) {
            HXDatePhotoEditViewController *vc = [[HXDatePhotoEditViewController alloc] init];
            vc.model = cell.model;
            vc.delegate = self;
            vc.manager = self.manager;
            [self.navigationController pushViewController:vc animated:NO];
        }else {
            HXDatePhotoPreviewViewController *previewVC = [[HXDatePhotoPreviewViewController alloc] init];
            previewVC.delegate = self;
            previewVC.modelArray = [NSMutableArray arrayWithObjects:cell.model, nil];
            previewVC.manager = self.manager;
#if __has_include(<YYWebImage/YYWebImage.h>) || __has_include("YYWebImage.h")
            cell.model.tempImage = vc.animatedImageView.image;
#else
            cell.model.tempImage = vc.imageView.image;
#endif
            previewVC.currentModelIndex = 0;
            self.navigationController.delegate = previewVC;
            [self.navigationController pushViewController:previewVC animated:YES];
        }
    }
}
#pragma mark - < HXDatePhotoViewCellDelegate >
- (void)datePhotoViewCellRequestICloudAssetComplete:(HXDatePhotoViewCell *)cell {
    if (cell.model.dateCellIsVisible) {
        NSIndexPath *indexPath = [NSIndexPath indexPathForItem:[self dateItem:cell.model] inSection:cell.model.dateSection];
        if (indexPath) {
            [self.collectionView reloadItemsAtIndexPaths:@[indexPath]];
        }
        [self.manager addICloudModel:cell.model];
    }
}
- (void)datePhotoViewCell:(HXDatePhotoViewCell *)cell didSelectBtn:(UIButton *)selectBtn {
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
            [self.view showImageHUDText:str];
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
    UIColor *bgColor;
    if (self.manager.configuration.cellSelectedBgColor) {
        bgColor = self.manager.configuration.cellSelectedBgColor;
    }else {
        bgColor = self.manager.configuration.themeColor;
    }
    selectBtn.backgroundColor = selectBtn.selected ? bgColor : nil;
    
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
            if ([tempCell isKindOfClass:[HXDatePhotoViewCell class]]) {
                if ([(HXDatePhotoViewCell *)tempCell model].subType == HXPhotoModelMediaSubTypeVideo) {
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
    if ([self.delegate respondsToSelector:@selector(datePhotoViewControllerDidChangeSelect:selected:)]) {
        [self.delegate datePhotoViewControllerDidChangeSelect:cell.model selected:selectBtn.selected];
    }
}
#pragma mark - < HXDatePhotoPreviewViewControllerDelegate >
- (void)datePhotoPreviewCellDownloadImageComplete:(HXDatePhotoPreviewViewController *)previewController model:(HXPhotoModel *)model {
    if (model.dateCellIsVisible && !model.loadOriginalImage) {
        NSIndexPath *indexPath = [NSIndexPath indexPathForItem:[self dateItem:model] inSection:model.dateSection];
        HXDatePhotoViewCell *cell = (HXDatePhotoViewCell *)[self.collectionView cellForItemAtIndexPath:indexPath];
        if (cell) {
            [cell resetNetworkImage];
        }
    }
}
- (void)datePhotoPreviewDownLoadICloudAssetComplete:(HXDatePhotoPreviewViewController *)previewController model:(HXPhotoModel *)model {
    if (model.iCloudRequestID) {
        [[PHImageManager defaultManager] cancelImageRequest:model.iCloudRequestID];
    }
    if (model.dateCellIsVisible) {
        NSIndexPath *indexPath = [NSIndexPath indexPathForItem:[self dateItem:model] inSection:model.dateSection];
        [self.collectionView reloadItemsAtIndexPaths:@[indexPath]];
        [self.manager addICloudModel:model]; 
    }
}
- (void)datePhotoPreviewControllerDidSelect:(HXDatePhotoPreviewViewController *)previewController model:(HXPhotoModel *)model {
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
            if ([tempCell isKindOfClass:[HXDatePhotoViewCell class]]) {
                if ([(HXDatePhotoViewCell *)tempCell model].subType == HXPhotoModelMediaSubTypeVideo) {
                    [indexPathList addObject:[self.collectionView indexPathForCell:tempCell]];
                }
            }
        }
    }
    if (indexPathList.count) {
        [self.collectionView reloadItemsAtIndexPaths:indexPathList];
    }
    
    self.bottomView.selectCount = [self.manager selectedCount];
    if ([self.delegate respondsToSelector:@selector(datePhotoViewControllerDidChangeSelect:selected:)]) {
        [self.delegate datePhotoViewControllerDidChangeSelect:model selected:model.selected];
    }
}
- (void)datePhotoPreviewControllerDidDone:(HXDatePhotoPreviewViewController *)previewController {
    [self datePhotoBottomViewDidDoneBtn];
}
- (void)datePhotoPreviewDidEditClick:(HXDatePhotoPreviewViewController *)previewController {
    [self datePhotoBottomViewDidDoneBtn];
}
- (void)datePhotoPreviewSingleSelectedClick:(HXDatePhotoPreviewViewController *)previewController model:(HXPhotoModel *)model {
    [self.manager beforeSelectedListAddPhotoModel:model];
    [self datePhotoBottomViewDidDoneBtn];
}
#pragma mark - < HXDatePhotoEditViewControllerDelegate >
- (void)datePhotoEditViewControllerDidClipClick:(HXDatePhotoEditViewController *)datePhotoEditViewController beforeModel:(HXPhotoModel *)beforeModel afterModel:(HXPhotoModel *)afterModel {
    if (self.manager.configuration.singleSelected) {
        [self.manager beforeSelectedListAddPhotoModel:afterModel];
        [self datePhotoBottomViewDidDoneBtn];
        return;
    }
    [self.manager beforeSelectedListdeletePhotoModel:beforeModel];
    
    [self datePhotoPreviewControllerDidSelect:nil model:beforeModel];
    [self customCameraViewController:nil didDone:afterModel];
}
#pragma mark - < HXDatePhotoBottomViewDelegate >
- (void)datePhotoBottomViewDidPreviewBtn {
    if (self.navigationController.topViewController != self || [self.manager selectedCount] == 0) {
        return;
    }
    HXDatePhotoPreviewViewController *previewVC = [[HXDatePhotoPreviewViewController alloc] init];
    previewVC.delegate = self;
    previewVC.modelArray = [NSMutableArray arrayWithArray:[self.manager selectedArray]];
    previewVC.manager = self.manager;
    previewVC.currentModelIndex = 0;
    previewVC.selectPreview = YES;
    self.navigationController.delegate = previewVC;
    [self.navigationController pushViewController:previewVC animated:YES];
}
- (void)datePhotoBottomViewDidDoneBtn {
    [self cleanSelectedList];
    if (!self.manager.configuration.requestImageAfterFinishingSelection) {
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}
- (void)datePhotoBottomViewDidEditBtn {
    HXPhotoModel *model = self.manager.selectedArray.firstObject;
    if (model.subType == HXPhotoModelMediaSubTypePhoto) {
        if (self.manager.configuration.replacePhotoEditViewController) {
#pragma mark - < 替换图片编辑 >
            if (self.manager.configuration.shouldUseEditAsset) {
                self.manager.configuration.shouldUseEditAsset(self, NO,self.manager, model);
            }
            HXWeakSelf
            self.manager.configuration.usePhotoEditComplete = ^(HXPhotoModel *beforeModel, HXPhotoModel *afterModel) {
                [weakSelf datePhotoEditViewControllerDidClipClick:nil beforeModel:beforeModel afterModel:afterModel];
            };
        }else {
            HXDatePhotoEditViewController *vc = [[HXDatePhotoEditViewController alloc] init];
            vc.model = self.manager.selectedPhotoArray.firstObject;
            vc.delegate = self;
            vc.manager = self.manager;
            [self.navigationController pushViewController:vc animated:NO];
        }
    }else if (model.subType == HXPhotoModelMediaSubTypeVideo) {
        if (self.manager.configuration.replaceVideoEditViewController) {
#pragma mark - < 替换视频编辑 >
            if (self.manager.configuration.shouldUseEditAsset) {
                self.manager.configuration.shouldUseEditAsset(self, NO, self.manager, model);
            }
            HXWeakSelf
            self.manager.configuration.useVideoEditComplete = ^(HXPhotoModel *beforeModel, HXPhotoModel *afterModel) {
                [weakSelf datePhotoEditViewControllerDidClipClick:nil beforeModel:beforeModel afterModel:afterModel];
            };
        }else {
//            [self.view showImageHUDText:[NSBundle hx_localizedStringForKey:@"功能还在开发中^_^"]];
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"要使用视频编辑功能，请先替换视频编辑界面" message:nil delegate:nil cancelButtonTitle:nil otherButtonTitles:@"好的", nil];
            [alert show];
        }
    }
}

- (void)cleanSelectedList {
    [self.manager selectedListTransformAfter];
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
    if ([self.delegate respondsToSelector:@selector(datePhotoViewController:didDoneAllList:photos:videos:original:)]) {
        [self.delegate datePhotoViewController:self
                                didDoneAllList:allList
                                        photos:photoList
                                        videos:videoList
                                      original:isOriginal];
    }
    if (self.doneBlock) {
        self.doneBlock(allList, photoList, videoList, isOriginal, self, self.manager);
    }
    NSMutableArray *allAsset = [NSMutableArray array];
    NSMutableArray *photoAssets = [NSMutableArray array];
    NSMutableArray *videoAssets = [NSMutableArray array];
    for (HXPhotoModel *phMd in allList) {
        if (phMd.asset) {
            if (phMd.subType == HXPhotoModelMediaSubTypePhoto) {
                [photoAssets addObject:phMd.asset];
            }else {
                [videoAssets addObject:phMd.asset];
            }
            [allAsset addObject:phMd.asset];
        }
    }
    if (self.allAssetBlock) {
        self.allAssetBlock(allList, photoList, videoList, isOriginal, self, self.manager);
    }
    if ([self.delegate respondsToSelector:@selector(datePhotoViewController:allAssetList:photoAssets:videoAssets:original:)]) {
        [self.delegate datePhotoViewController:self
                                  allAssetList:allList
                                   photoAssets:photoList
                                   videoAssets:videoList
                                      original:isOriginal];
    }
    if (self.manager.configuration.requestImageAfterFinishingSelection) {
        [self.navigationController.viewControllers.lastObject.view showLoadingHUDText:nil];
        HXWeakSelf
        HXDatePhotoToolManagerRequestType requestType;
        if (isOriginal) {
            requestType = HXDatePhotoToolManagerRequestTypeOriginal;
        }else {
            requestType = HXDatePhotoToolManagerRequestTypeHD;
        }
        [self.toolManager getSelectedImageList:allList requestType:requestType success:^(NSArray<UIImage *> *imageList) {
            __strong typeof(weakSelf) strongSelf = weakSelf;
            BOOL tempOriginal;
            NSArray *tempArray;
            if (!strongSelf.manager.configuration.singleSelected) {
                tempArray = strongSelf.manager.afterSelectedArray.copy;
                tempOriginal = strongSelf.manager.afterOriginal;
            }else {
                tempArray = strongSelf.manager.selectedArray.copy;
                tempOriginal = strongSelf.manager.original;
            }
            int i = 0;
            for (HXPhotoModel *subModel in tempArray) {
                if (i < imageList.count) {
                    subModel.thumbPhoto = imageList[i];
                    subModel.previewPhoto = imageList[i];
                }
                i++;
            }
            if ([strongSelf.delegate respondsToSelector:@selector(datePhotoViewController:didDoneAllImage:original:)]) {
                [strongSelf.delegate datePhotoViewController:strongSelf didDoneAllImage:imageList original:tempOriginal];
            }
            if (strongSelf.allImageBlock) {
                strongSelf.allImageBlock(imageList, tempOriginal, strongSelf, strongSelf.manager);
            }
            [strongSelf dismissViewControllerAnimated:YES completion:nil];
        } failed:^{
            __strong typeof(weakSelf) strongSelf = weakSelf;
            [strongSelf.navigationController.viewControllers.lastObject.view handleLoading];
            [strongSelf dismissViewControllerAnimated:YES completion:nil];
        }];
    }
}
#pragma mark - < 懒加载 >
- (HXDatePhotoToolManager *)toolManager {
    if (!_toolManager) {
        _toolManager = [[HXDatePhotoToolManager alloc] init];
    }
    return _toolManager;
}
- (UILabel *)authorizationLb {
    if (!_authorizationLb) {
        _authorizationLb = [[UILabel alloc] initWithFrame:CGRectMake(0, 200, self.view.hx_w, 100)];
        _authorizationLb.text = [NSBundle hx_localizedStringForKey:@"无法访问照片\n请点击这里前往设置中允许访问照片"];
        _authorizationLb.textAlignment = NSTextAlignmentCenter;
        _authorizationLb.numberOfLines = 0;
        _authorizationLb.textColor = [UIColor blackColor];
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
            weakSelf.albumModel = model;
            weakSelf.albumTitleView.model = model;
            [weakSelf.view showLoadingHUDText:nil];
            [weakSelf getPhotoList];
        };
    }
    return _albumView;
}
- (HXAlbumTitleView *)albumTitleView {
    if (!_albumTitleView) {
        _albumTitleView = [[HXAlbumTitleView alloc] initWithManager:self.manager];
        HXWeakSelf
        _albumTitleView.didTitleViewBlock = ^(BOOL selected) {
            if (selected) {
                weakSelf.albumBgView.hidden = NO;
                weakSelf.albumBgView.alpha = 0;
                UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
                CGFloat navBarHeight = hxNavigationBarHeight;
                if (orientation == UIInterfaceOrientationPortrait || UIInterfaceOrientationPortrait == UIInterfaceOrientationPortraitUpsideDown) {
                    navBarHeight = hxNavigationBarHeight;
                }else if (orientation == UIInterfaceOrientationLandscapeRight || orientation == UIInterfaceOrientationLandscapeLeft){
                    if ([UIApplication sharedApplication].statusBarHidden) {
                        navBarHeight = weakSelf.navigationController.navigationBar.hx_h;
                    }else {
                        navBarHeight = weakSelf.navigationController.navigationBar.hx_h + 20;
                    }
                }
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
- (HXDatePhotoBottomView *)bottomView {
    if (!_bottomView) {
        _bottomView = [[HXDatePhotoBottomView alloc] initWithFrame:CGRectMake(0, self.view.hx_h - 50 - hxBottomMargin, self.view.hx_w, 50 + hxBottomMargin)];
        _bottomView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        _bottomView.manager = self.manager;
        _bottomView.delegate = self;
    }
    return _bottomView;
}
- (HXDatePhotoViewFlowLayout *)customLayout {
    if (!_customLayout) {
        _customLayout = [[HXDatePhotoViewFlowLayout alloc] init];
        _customLayout.minimumLineSpacing = 1;
        _customLayout.minimumInteritemSpacing = 1;
        _customLayout.sectionInset = UIEdgeInsetsMake(0.5, 0, 0.5, 0);
        //        if (iOS9_Later) {
        //            _customLayout.sectionHeadersPinToVisibleBounds = YES;
        //        }
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
        _collectionView.backgroundColor = [UIColor whiteColor];
        _collectionView.dataSource = self;
        _collectionView.delegate = self;
        _collectionView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        _collectionView.alwaysBounceVertical = YES;
        [_collectionView registerClass:[HXDatePhotoViewCell class] forCellWithReuseIdentifier:@"DateCellId"];
        [_collectionView registerClass:[HXDatePhotoCameraViewCell class] forCellWithReuseIdentifier:@"DateCameraCellId"];
        [_collectionView registerClass:[HXDatePhotoViewSectionHeaderView class] forSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:@"sectionHeaderId"];
        [_collectionView registerClass:[HXDatePhotoViewSectionFooterView class] forSupplementaryViewOfKind:UICollectionElementKindSectionFooter withReuseIdentifier:@"sectionFooterId"];
        
#ifdef __IPHONE_11_0
        if (@available(iOS 11.0, *)) {
            if ([self navigationBarWhetherSetupBackground]) {
                self.navigationController.navigationBar.translucent = YES;
            }
            _collectionView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
#else
        if ((NO)) {
#endif
        } else {
            if ([self navigationBarWhetherSetupBackground]) {
                self.navigationController.navigationBar.translucent = YES;
            }
            self.automaticallyAdjustsScrollViewInsets = NO;
        }
        if (self.manager.configuration.open3DTouchPreview) {
            if ([self respondsToSelector:@selector(traitCollection)]) {
                if ([self.traitCollection respondsToSelector:@selector(forceTouchCapability)]) {
                    if (self.traitCollection.forceTouchCapability == UIForceTouchCapabilityAvailable) {
                        self.previewingContext = [self registerForPreviewingWithDelegate:self sourceView:_collectionView];
                    }
                }
            }
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
        //        if (iOS9_Later) {
        //            _flowLayout.sectionHeadersPinToVisibleBounds = YES;
        //        }
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
- (void)dealloc {
    if (HXShowLog) NSSLog(@"dealloc");
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
@end
@interface HXDatePhotoCameraViewCell ()
@property (strong, nonatomic) UIButton *cameraBtn;
@property (strong, nonatomic) HXCustomCameraController *cameraController;
@property (strong, nonatomic) HXCustomPreviewView *previewView;
@property (strong, nonatomic) UIVisualEffectView *effectView;
@end

@implementation HXDatePhotoCameraViewCell
- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setupUI];
    }
    return self;
}
- (void)setupUI  {
    [self.contentView addSubview:self.previewView];
    [self.contentView addSubview:self.cameraBtn];
}
- (void)starRunning {
    if (![UIImagePickerController isSourceTypeAvailable:
          UIImagePickerControllerSourceTypeCamera]) {
        return;
    }
    if (self.cameraController.captureSession) {
        return;
    }
    __weak typeof(self) weakSelf = self;
    [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(BOOL granted) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (granted) {
                if ([weakSelf.cameraController setupSession:nil]) {
                    if (weakSelf.model.photoManager.tempCameraPreviewView) {
                        weakSelf.cameraBtn.selected = YES;
                        [weakSelf.previewView addSubview:weakSelf.model.photoManager.tempCameraPreviewView];
                        [weakSelf.previewView addSubview:weakSelf.effectView];
                    }
                    [weakSelf.previewView setSession:weakSelf.cameraController.captureSession];
                    [weakSelf.cameraController startSessionComplete:^{
                        dispatch_async(dispatch_get_main_queue(), ^{
                            weakSelf.cameraBtn.selected = YES;
                            if (weakSelf.model.photoManager.tempCameraPreviewView) {
                                [UIView animateWithDuration:0.3 animations:^{
                                    weakSelf.model.photoManager.tempCameraPreviewView.alpha = 0;
                                    weakSelf.effectView.effect = nil;
                                } completion:^(BOOL finished) {
                                    [weakSelf.model.photoManager.tempCameraPreviewView removeFromSuperview];
                                    [weakSelf.effectView removeFromSuperview];
                                }];
                            }
                        });
                    }];
                }
            }
        });
    }];
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
    if (!self.cameraController.captureSession) {
        return;
    }

    self.model.photoManager.tempCameraPreviewView = [self.previewView snapshotViewAfterScreenUpdates:YES];
    [self.cameraController stopSession];
    self.cameraBtn.selected = NO;
}
- (void)setModel:(HXPhotoModel *)model {
    _model = model;
    [self.cameraBtn setImage:model.thumbPhoto forState:UIControlStateNormal];
    [self.cameraBtn setImage:model.previewPhoto forState:UIControlStateSelected];
}
- (void)layoutSubviews {
    [super layoutSubviews];
    self.cameraBtn.frame = self.bounds;
    self.previewView.frame = self.bounds;
    self.effectView.frame = self.bounds;
    self.model.photoManager.tempCameraPreviewView.frame = self.bounds;
}
- (void)dealloc {
    [self stopRunning];
    if (HXShowLog) NSSLog(@"camera - dealloc");
}
- (UIButton *)cameraBtn {
    if (!_cameraBtn) {
        _cameraBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        _cameraBtn.userInteractionEnabled = NO;
    }
    return _cameraBtn;
}
- (HXCustomCameraController *)cameraController {
    if (!_cameraController) {
        _cameraController = [[HXCustomCameraController alloc] init];
    }
    return _cameraController;
}
- (HXCustomPreviewView *)previewView {
    if (!_previewView) {
        _previewView = [[HXCustomPreviewView alloc] init];
        _previewView.pinchToZoomEnabled = NO;
        _previewView.tapToFocusEnabled = NO;
        _previewView.tapToExposeEnabled = NO;
    }
    return _previewView;
}
- (UIVisualEffectView *)effectView {
    if (!_effectView) {
        UIBlurEffect *effect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleLight];
        _effectView = [[UIVisualEffectView alloc] initWithEffect:effect];
    }
    return _effectView;
}
@end
@interface HXDatePhotoViewCell ()
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

@implementation HXDatePhotoViewCell

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
        self.model.loadOriginalImage = YES;
        HXWeakSelf
        [self.imageView hx_setImageWithModel:self.model original:YES progress:nil completed:^(UIImage *image, NSError *error, HXPhotoModel *model) {
            if (weakSelf.model == model) {
                weakSelf.imageView.image = image;
            }
        }];
    }
}
- (void)setModel:(HXPhotoModel *)model {
    _model = model;
    self.progressView.hidden = YES;
    self.progressView.progress = 0;
    HXWeakSelf
    if (model.type == HXPhotoModelMediaTypeCamera ||
        model.type == HXPhotoModelMediaTypeCameraPhoto ||
        model.type == HXPhotoModelMediaTypeCameraVideo) {
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
                            weakSelf.progressView.progress = 1;
                            weakSelf.progressView.hidden = YES;
                            weakSelf.imageView.image = image;
                        }
                    }
                }
            }]; 
        }else {
            self.imageView.image = model.thumbPhoto;
        }
    }else {
        if (!self.imageView.image) {
            self.imageView.hidden = YES;
            self.imageView.alpha = 0;
            self.maskView.hidden = YES;
            self.maskView.alpha = 0;
        }
        self.imageView.image = nil;
        PHImageRequestID requestID = [HXPhotoTools getImageWithModel:model completion:^(UIImage *image, HXPhotoModel *model) {
            if (weakSelf.model == model) {
                weakSelf.imageView.image = image;
                if (weakSelf.maskView.hidden) {
                    weakSelf.imageView.hidden = NO;
                    weakSelf.maskView.hidden = NO;
                    [UIView animateWithDuration:0.2 animations:^{
                        weakSelf.maskView.alpha = 1;
                        weakSelf.imageView.alpha = 1;
                    }];
                }
            }
        }];
        self.requestID = requestID;
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
            if (model.networkPhotoUrl) {
                if ([[model.networkPhotoUrl.absoluteString substringFromIndex:model.networkPhotoUrl.absoluteString.length - 3] isEqualToString:@"gif"]) {
                    self.stateLb.text = @"GIF";
                    self.stateLb.hidden = NO;
                    self.bottomMaskLayer.hidden = NO;
                }else {
                    self.stateLb.hidden = YES;
                    self.bottomMaskLayer.hidden = YES;
                }
            }else {
                self.stateLb.hidden = YES;
                self.bottomMaskLayer.hidden = YES;
            }
        }
    }
    self.selectMaskLayer.hidden = !model.selected;
    self.selectBtn.selected = model.selected;
    [self.selectBtn setTitle:model.selectIndexStr forState:UIControlStateSelected];
    self.selectBtn.backgroundColor = model.selected ? self.selectBgColor :nil;
    
    //    if (model.isICloud) {
    //        self.selectBtn.userInteractionEnabled = NO;
    //    }else {
    //        self.selectBtn.userInteractionEnabled = YES;
    //    }
    
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
//            self.userInteractionEnabled = !model.videoUnableSelect;
        }else {
            self.videoMaskLayer.hidden = YES;
            self.userInteractionEnabled = YES;
        }
    }
    
//    self.iCloudIcon.hidden = !model.isICloud;
//    self.selectBtn.hidden = model.isICloud;
//    self.iCloudMaskLayer.hidden = !model.isICloud;
    
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
    if ([selectBgColor isEqual:[UIColor whiteColor]] && !self.selectedTitleColor) {
        [self.selectBtn setTitleColor:[UIColor blackColor] forState:UIControlStateSelected];
    }
}
- (void)setSelectedTitleColor:(UIColor *)selectedTitleColor {
    _selectedTitleColor = selectedTitleColor;
    [self.selectBtn setTitleColor:selectedTitleColor forState:UIControlStateSelected];
}
- (void)startRequestICloudAsset {
    self.downloadView.hidden = NO;
    [self.downloadView startAnima];
    self.iCloudIcon.hidden = YES;
    self.iCloudMaskLayer.hidden = YES;
    __weak typeof(self) weakSelf = self;
    if (self.model.type == HXPhotoModelMediaTypeVideo) {
        self.iCloudRequestID = [HXPhotoTools getAVAssetWithModel:self.model startRequestIcloud:^(HXPhotoModel *model, PHImageRequestID cloudRequestId) {
            if (weakSelf.model == model) {
                weakSelf.downloadView.hidden = NO;
                weakSelf.iCloudRequestID = cloudRequestId;
            }
        } progressHandler:^(HXPhotoModel *model, double progress) {
            if (weakSelf.model == model) {
                weakSelf.downloadView.hidden = NO;
                weakSelf.downloadView.progress = progress;
            }
        } completion:^(HXPhotoModel *model, AVAsset *asset) {
            if (weakSelf.model == model) {
                weakSelf.downloadView.progress = 1;
                if ([weakSelf.delegate respondsToSelector:@selector(datePhotoViewCellRequestICloudAssetComplete:)]) {
                    [weakSelf.delegate datePhotoViewCellRequestICloudAssetComplete:weakSelf];
                }
            }
        } failed:^(HXPhotoModel *model, NSDictionary *info) {
            if (weakSelf.model == model) {
                [weakSelf downloadError:info];
            }
        }];
    }else if (self.model.type == HXPhotoModelMediaTypeLivePhoto){
        self.iCloudRequestID = [HXPhotoTools getLivePhotoWithModel:self.model size:CGSizeMake(self.model.previewViewSize.width * 1.5, self.model.previewViewSize.height * 1.5) startRequestICloud:^(HXPhotoModel *model, PHImageRequestID iCloudRequestId) {
            if (weakSelf.model == model) {
                weakSelf.downloadView.hidden = NO;
                weakSelf.iCloudRequestID = iCloudRequestId;
            }
        } progressHandler:^(HXPhotoModel *model, double progress) {
            if (weakSelf.model == model) {
                weakSelf.downloadView.hidden = NO;
                weakSelf.downloadView.progress = progress;
            }
        } completion:^(HXPhotoModel *model, PHLivePhoto *livePhoto) {
            if (weakSelf.model == model) {
                weakSelf.downloadView.progress = 1;
                if ([weakSelf.delegate respondsToSelector:@selector(datePhotoViewCellRequestICloudAssetComplete:)]) {
                    [weakSelf.delegate datePhotoViewCellRequestICloudAssetComplete:weakSelf];
                }
            }
        } failed:^(HXPhotoModel *model, NSDictionary *info) {
            if (weakSelf.model == model) {
                [weakSelf downloadError:info];
            }
        }];
    }else {
        self.iCloudRequestID = [HXPhotoTools getImageDataWithModel:self.model startRequestIcloud:^(HXPhotoModel *model, PHImageRequestID cloudRequestId) {
            if (weakSelf.model == model) {
                weakSelf.downloadView.hidden = NO;
                weakSelf.iCloudRequestID = cloudRequestId;
            }
        } progressHandler:^(HXPhotoModel *model, double progress) {
            if (weakSelf.model == model) {
                weakSelf.downloadView.hidden = NO;
                weakSelf.downloadView.progress = progress;
            }
        } completion:^(HXPhotoModel *model, NSData *imageData, UIImageOrientation orientation) {
            if (weakSelf.model == model) {
                weakSelf.downloadView.progress = 1;
                if ([weakSelf.delegate respondsToSelector:@selector(datePhotoViewCellRequestICloudAssetComplete:)]) {
                    [weakSelf.delegate datePhotoViewCellRequestICloudAssetComplete:weakSelf];
                }
            }
        } failed:^(HXPhotoModel *model, NSDictionary *info) {
            if (weakSelf.model == model) {
                [weakSelf downloadError:info];
            }
        }];
    }
}
- (void)downloadError:(NSDictionary *)info {
    if (![[info objectForKey:PHImageCancelledKey] boolValue]) {
        [[self hx_viewController].view showImageHUDText:[NSBundle hx_localizedStringForKey:@"下载失败，请重试！"]];
    }
    self.downloadView.hidden = YES;
    [self.downloadView resetState];
    self.iCloudIcon.hidden = !self.model.isICloud;
    self.iCloudMaskLayer.hidden = !self.model.isICloud;
}
- (void)cancelRequest {
#if __has_include(<YYWebImage/YYWebImage.h>) || __has_include("YYWebImage.h")
    [self.imageView yy_cancelCurrentImageRequest];
#elif __has_include(<SDWebImage/UIImageView+WebCache.h>) || __has_include("UIImageView+WebCache.h")
    [self.imageView sd_cancelCurrentAnimationImagesLoad];
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
    if ([self.delegate respondsToSelector:@selector(datePhotoViewCell:didSelectBtn:)]) {
        [self.delegate datePhotoViewCell:self didSelectBtn:button];
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
    self.selectBtn.frame = CGRectMake(self.hx_w - 27, 2, 25, 25);
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
        _imageView.backgroundColor = [UIColor colorWithRed:0.95 green:0.95 blue:0.95 alpha:1];
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
        _iCloudIcon = [[UIImageView alloc] initWithImage:[HXPhotoTools hx_imageNamed:@"hx_yunxiazai@2x.png"]];
        _iCloudIcon.hx_size = _iCloudIcon.image.size;
    }
    return _iCloudIcon;
}
- (CALayer *)selectMaskLayer {
    if (!_selectMaskLayer) {
        _selectMaskLayer = [CALayer layer];
        _selectMaskLayer.hidden = YES;
        _selectMaskLayer.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:0.3].CGColor;
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
        _stateLb.font = [UIFont systemFontOfSize:12];
    }
    return _stateLb;
}
- (CAGradientLayer *)bottomMaskLayer {
    if (!_bottomMaskLayer) {
        _bottomMaskLayer = [CAGradientLayer layer];
        _bottomMaskLayer.colors = @[
                                    (id)[[UIColor blackColor] colorWithAlphaComponent:0].CGColor,
                                    (id)[[UIColor blackColor] colorWithAlphaComponent:0.35].CGColor
                                    ];
        _bottomMaskLayer.startPoint = CGPointMake(0, 0);
        _bottomMaskLayer.endPoint = CGPointMake(0, 1);
        _bottomMaskLayer.locations = @[@(0.15f),@(0.9f)];
        _bottomMaskLayer.borderWidth  = 0.0;
    }
    return _bottomMaskLayer;
}
- (UIButton *)selectBtn {
    if (!_selectBtn) {
        _selectBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [_selectBtn setBackgroundImage:[HXPhotoTools hx_imageNamed:@"hx_compose_guide_check_box_default@2x.png"] forState:UIControlStateNormal];
        [_selectBtn setBackgroundImage:[[UIImage alloc] init] forState:UIControlStateSelected];
        [_selectBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateSelected];
        _selectBtn.titleLabel.font = [UIFont systemFontOfSize:14];
        _selectBtn.titleLabel.adjustsFontSizeToFitWidth = YES;
        [_selectBtn addTarget:self action:@selector(didSelectClick:) forControlEvents:UIControlEventTouchUpInside];
        [_selectBtn setEnlargeEdgeWithTop:0 right:0 bottom:15 left:15];
        _selectBtn.layer.cornerRadius = 25 / 2;
    }
    return _selectBtn;
}
@end

@interface HXDatePhotoViewSectionHeaderView ()
@property (strong, nonatomic) UILabel *dateLb;
@property (strong, nonatomic) UILabel *subTitleLb;
@property (strong, nonatomic) UIToolbar *bgView;
@end

@implementation HXDatePhotoViewSectionHeaderView
- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setupUI];
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
        if (self.translucent) {
            self.bgView.alpha = 1;
        }
        if (self.suspensionTitleColor) {
            self.dateLb.textColor = self.suspensionTitleColor;
            self.subTitleLb.textColor = self.suspensionTitleColor;
        }
        if (self.suspensionBgColor) {
            self.bgView.barTintColor = self.suspensionBgColor;
        }
    }else {
        if (!self.translucent) {
            self.bgView.barTintColor = [UIColor whiteColor];
        }
        if (self.translucent) {
            self.bgView.alpha = 0;
        }
        self.dateLb.textColor = [UIColor blackColor];
        self.subTitleLb.textColor = [UIColor blackColor];
    }
}
- (void)setTranslucent:(BOOL)translucent {
    _translucent = translucent;
    if (!translucent) {
        self.bgView.translucent = YES;
        self.bgView.barTintColor = [UIColor whiteColor];
    }
}
- (void)setModel:(HXPhotoDateModel *)model {
    _model = model;
    if (model.location) {
        if (model.hasLocationTitles) {
            self.dateLb.frame = CGRectMake(8, 4, self.hx_w - 16, 30);
            self.subTitleLb.hidden = NO;
            self.subTitleLb.text = model.locationSubTitle;
            self.dateLb.text = model.locationTitle;
        }else {
            self.dateLb.frame = CGRectMake(8, 0, self.hx_w - 16, 50);
            self.dateLb.text = model.dateString;
            self.subTitleLb.hidden = YES;
            __weak typeof(self) weakSelf = self;
            [HXPhotoTools getDateLocationDetailInformationWithModel:model completion:^(CLPlacemark *placemark, HXPhotoDateModel *model) {
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
                model.hasLocationTitles = YES;
                if (weakSelf.model == model) {
                    weakSelf.subTitleLb.text = model.locationSubTitle;
                    weakSelf.dateLb.text = model.locationTitle;
                    weakSelf.dateLb.frame = CGRectMake(8, 4, weakSelf.hx_w - 16, 30);
                    weakSelf.subTitleLb.hidden = NO;
                }
            }];
        }
    }else {
        self.dateLb.frame = CGRectMake(8, 0, self.hx_w - 16, 50);
        self.dateLb.text = model.dateString;
        self.subTitleLb.hidden = YES;
    }
}
- (void)layoutSubviews {
    [super layoutSubviews];
    if (self.model.location) {
        self.dateLb.frame = CGRectMake(8, 4, self.hx_w - 16, 30);
        self.subTitleLb.frame = CGRectMake(8, 26, self.hx_w - 16, 20);
    }else {
    }
    self.bgView.frame = self.bounds;
}
- (UILabel *)dateLb {
    if (!_dateLb) {
        _dateLb = [[UILabel alloc] init];
        _dateLb.textColor = [UIColor blackColor];
        _dateLb.font = [UIFont hx_helveticaNeueOfSize:16];
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
        _subTitleLb.textColor = [UIColor blackColor];
        _subTitleLb.font = [UIFont hx_pingFangFontOfSize:11];
    }
    return _subTitleLb;
}
@end

@interface HXDatePhotoViewSectionFooterView ()
@property (strong, nonatomic) UILabel *titleLb;
@end

@implementation HXDatePhotoViewSectionFooterView
- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setupUI];
    }
    return self;
}
- (void)setupUI {
    self.backgroundColor = [UIColor whiteColor];
    [self addSubview:self.titleLb];
}
- (void)setVideoCount:(NSInteger)videoCount {
    _videoCount = videoCount;
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
        self.titleLb.text = [NSString stringWithFormat:@"%ld %@、%ld %@",self.photoCount,[NSBundle hx_localizedStringForKey:photoStr],videoCount,[NSBundle hx_localizedStringForKey:videoStr]];
        
    }else if (self.photoCount > 0) {
        NSString *photoStr;
        if (self.photoCount > 1) {
            photoStr = @"Photos";
        }else {
            photoStr = @"Photo";
        }
        self.titleLb.text = [NSString stringWithFormat:@"%ld %@",self.photoCount,[NSBundle hx_localizedStringForKey:photoStr]];
    }else {
        NSString *videoStr;
        if (videoCount > 1) {
            videoStr = @"Videos";
        }else {
            videoStr = @"Video";
        }
        self.titleLb.text = [NSString stringWithFormat:@"%ld %@",videoCount,
                             [NSBundle hx_localizedStringForKey:videoStr]];
    }
}
- (void)layoutSubviews {
    [super layoutSubviews];
    self.titleLb.frame = CGRectMake(0, 0, self.hx_w, 50);
}
- (UILabel *)titleLb {
    if (!_titleLb) {
        _titleLb = [[UILabel alloc] init];
        _titleLb.textColor = [UIColor blackColor];
        _titleLb.textAlignment = NSTextAlignmentCenter;
        _titleLb.font = [UIFont systemFontOfSize:15];
    }
    return _titleLb;
}
@end

@interface HXDatePhotoBottomView ()
@property (strong, nonatomic) UIButton *previewBtn;
@property (strong, nonatomic) UIButton *doneBtn;
@property (strong, nonatomic) UIButton *editBtn;
@end

@implementation HXDatePhotoBottomView
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
    self.originalBtn.hidden = self.manager.configuration.hideOriginalBtn;
    if (manager.type == HXPhotoManagerSelectedTypePhoto) {
        self.editBtn.hidden = !manager.configuration.photoCanEdit;
    }else if (manager.type == HXPhotoManagerSelectedTypeVideo) {
        self.originalBtn.hidden = YES;
        self.editBtn.hidden = !manager.configuration.videoCanEdit;
    }else {
        if (!manager.configuration.videoCanEdit && !manager.configuration.photoCanEdit) {
            self.editBtn.hidden = YES;
        }
    }
    self.originalBtn.selected = self.manager.original;
    
    [self.previewBtn setTitleColor:self.manager.configuration.themeColor forState:UIControlStateNormal];
    [self.previewBtn setTitleColor:[self.manager.configuration.themeColor colorWithAlphaComponent:0.5] forState:UIControlStateDisabled];
    self.doneBtn.backgroundColor = [self.manager.configuration.themeColor colorWithAlphaComponent:0.5];
    [self.originalBtn setTitleColor:self.manager.configuration.themeColor forState:UIControlStateNormal];
    [self.originalBtn setTitleColor:[self.manager.configuration.themeColor colorWithAlphaComponent:0.5] forState:UIControlStateDisabled];
    [self.originalBtn setImage:[HXPhotoTools hx_imageNamed:self.manager.configuration.originalNormalImageName] forState:UIControlStateNormal];
    [self.originalBtn setImage:[HXPhotoTools hx_imageNamed:self.manager.configuration.originalSelectedImageName] forState:UIControlStateSelected];
    [self.editBtn setTitleColor:self.manager.configuration.themeColor forState:UIControlStateNormal];
    [self.editBtn setTitleColor:[self.manager.configuration.themeColor colorWithAlphaComponent:0.5] forState:UIControlStateDisabled];
    if ([self.manager.configuration.themeColor isEqual:[UIColor whiteColor]]) {
        [self.doneBtn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        [self.doneBtn setTitleColor:[[UIColor blackColor] colorWithAlphaComponent:0.5] forState:UIControlStateDisabled];
    }
    if (self.manager.configuration.selectedTitleColor) {
        [self.doneBtn setTitleColor:self.manager.configuration.selectedTitleColor forState:UIControlStateNormal];
        [self.doneBtn setTitleColor:[self.manager.configuration.selectedTitleColor colorWithAlphaComponent:0.5] forState:UIControlStateDisabled];
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
                    [self.doneBtn setTitle:[NSString stringWithFormat:@"%@(%ld/%ld)",[NSBundle hx_localizedStringForKey:@"完成"],selectCount,self.manager.configuration.photoMaxNum] forState:UIControlStateNormal];
                }else {
                    [self.doneBtn setTitle:[NSString stringWithFormat:@"%@(%ld/%ld)",[NSBundle hx_localizedStringForKey:@"完成"],selectCount,self.manager.configuration.videoMaxNum] forState:UIControlStateNormal];
                }
            }else {
                [self.doneBtn setTitle:[NSString stringWithFormat:@"%@(%ld/%ld)",[NSBundle hx_localizedStringForKey:@"完成"],selectCount,self.manager.configuration.maxNum] forState:UIControlStateNormal];
            }
        }else {
            [self.doneBtn setTitle:[NSString stringWithFormat:@"%@(%ld)",[NSBundle hx_localizedStringForKey:@"完成"],selectCount] forState:UIControlStateNormal];
        }
    }
    
    self.doneBtn.backgroundColor = self.doneBtn.enabled ? self.manager.configuration.themeColor : [self.manager.configuration.themeColor colorWithAlphaComponent:0.5];
    [self changeDoneBtnFrame];
    
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
    if (self.manager.selectedPhotoArray.count == 0) {
        self.originalBtn.enabled = NO;
        self.originalBtn.selected = NO;
        [self.manager setOriginal:NO] ;
    }else { 
        self.originalBtn.enabled = YES;
    }
}
- (void)changeDoneBtnFrame {
    CGFloat width = [HXPhotoTools getTextWidth:self.doneBtn.currentTitle height:30 fontSize:14];
    self.doneBtn.hx_w = width + 20;
    if (self.doneBtn.hx_w < 50) {
        self.doneBtn.hx_w = 50;
    }
    self.doneBtn.hx_x = self.hx_w - 12 - self.doneBtn.hx_w;
}
- (void)didDoneBtnClick {
    if ([self.delegate respondsToSelector:@selector(datePhotoBottomViewDidDoneBtn)]) {
        [self.delegate datePhotoBottomViewDidDoneBtn];
    }
}
- (void)didPreviewClick {
    if ([self.delegate respondsToSelector:@selector(datePhotoBottomViewDidPreviewBtn)]) {
        [self.delegate datePhotoBottomViewDidPreviewBtn];
    }
}
- (void)didEditBtnClick {
    if ([self.delegate respondsToSelector:@selector(datePhotoBottomViewDidEditBtn)]) {
        [self.delegate datePhotoBottomViewDidEditBtn];
    }
}
- (void)didOriginalClick:(UIButton *)button {
    button.selected = !button.selected;
    [self.manager setOriginal:button.selected]; 
}
- (void)layoutSubviews {
    [super layoutSubviews];
    
    self.bgView.frame = self.bounds;
    self.previewBtn.frame = CGRectMake(12, 0, [HXPhotoTools getTextWidth:self.previewBtn.currentTitle height:50 fontSize:16], 50);
    self.previewBtn.center = CGPointMake(self.previewBtn.center.x, 25);
    self.editBtn.frame = CGRectMake(CGRectGetMaxX(self.previewBtn.frame) + 10, 0, [HXPhotoTools getTextWidth:self.editBtn.currentTitle height:50 fontSize:16], 50);
    if (self.editBtn.hidden) {
        self.originalBtn.frame = CGRectMake(CGRectGetMaxX(self.previewBtn.frame) + 10, 0, [HXPhotoTools getTextWidth:self.originalBtn.currentTitle height:50 fontSize:16] + 20, 50);
        self.originalBtn.imageEdgeInsets = UIEdgeInsetsMake(0, [HXPhotoTools getTextWidth:self.originalBtn.currentTitle height:50 fontSize:16] , 0, 0);
    }else {
        self.originalBtn.frame = CGRectMake(CGRectGetMaxX(self.editBtn.frame) + 10, 0, [HXPhotoTools getTextWidth:self.originalBtn.currentTitle height:50 fontSize:16] + 20, 50);
        self.originalBtn.imageEdgeInsets = UIEdgeInsetsMake(0, [HXPhotoTools getTextWidth:self.originalBtn.currentTitle height:50 fontSize:16] , 0, 0);
//        self.originalBtn.titleEdgeInsets = UIEdgeInsetsMake(0, -15, 0, 0);
    }
    self.doneBtn.frame = CGRectMake(0, 0, 50, 30);
    self.doneBtn.center = CGPointMake(self.doneBtn.center.x, 25);
    [self changeDoneBtnFrame];
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
        [_doneBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [_doneBtn setTitleColor:[[UIColor whiteColor] colorWithAlphaComponent:0.5] forState:UIControlStateDisabled];
        //        _doneBtn.contentHorizontalAlignment = UIControlContentHorizontalAlignmentRight;
        _doneBtn.titleLabel.font = [UIFont hx_pingFangFontOfSize:14];
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
        _originalBtn.imageEdgeInsets = UIEdgeInsetsMake(0, 35, 0, 0);
        _originalBtn.titleEdgeInsets = UIEdgeInsetsMake(0, -15, 0, 0);
        _originalBtn.enabled = NO;
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
@end
