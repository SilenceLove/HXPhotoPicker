//
//  HXDateAlbumViewController.m
//  照片选择器
//
//  Created by 洪欣 on 2017/10/14.
//  Copyright © 2017年 洪欣. All rights reserved.
//

#import "HXAlbumListViewController.h" 
#import "HXDatePhotoViewController.h"
#import "UIViewController+HXExtension.h"
@interface HXAlbumListViewController ()
<
UICollectionViewDataSource,
UICollectionViewDelegate,
UIViewControllerPreviewingDelegate,
HXDatePhotoViewControllerDelegate,
UITableViewDataSource,
UITableViewDelegate
>
@property (strong, nonatomic) UICollectionViewFlowLayout *flowLayout;
@property (strong, nonatomic) UICollectionView *collectionView;

@property (strong, nonatomic) UITableView *tableView;

@property (strong, nonatomic) NSMutableArray *albumModelArray;

@property (strong, nonatomic) UILabel *authorizationLb;
@property (weak, nonatomic) id<UIViewControllerPreviewing> previewingContext;

@property (assign, nonatomic) BOOL orientationDidChange;
@property (strong, nonatomic) NSIndexPath *beforeOrientationIndexPath;
@end

@implementation HXAlbumListViewController

- (UIStatusBarStyle)preferredStatusBarStyle {
    return self.manager.configuration.statusBarStyle;
}
- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self setPhotoManager];
    self.navigationController.popoverPresentationController.delegate = (id)self;
    [self setupUI];
    // 获取当前应用对照片的访问授权状态
    __weak typeof(self) weakSelf = self;
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
                [weakSelf getAlbumModelList:YES];
            }
        });
    }];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(deviceOrientationChanged:) name:UIApplicationDidChangeStatusBarOrientationNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(customCameraViewControllerDidDoneClick) name:@"CustomCameraViewControllerDidDoneNotification" object:nil];
    
    
    [UINavigationBar appearance].translucent = YES;
}
- (void)customCameraViewControllerDidDoneClick {
    NSInteger i = 0;
    for (HXAlbumModel *albumMd in self.albumModelArray) {
        albumMd.cameraCount = [self.manager cameraCount];
        if (i == 0 && !albumMd.result) {
            albumMd.tempImage = [self.manager firstCameraModel].thumbPhoto;
        }
        i++;
    }
    if (self.manager.configuration.singleSelected) {
        [self.tableView reloadData];
    }else {
        [self.collectionView reloadData];
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
    if (!self.manager.configuration.singleSelected) {
        self.beforeOrientationIndexPath = [self.collectionView indexPathsForVisibleItems].firstObject;
    }
    self.orientationDidChange = YES;
}
- (void)changeSubviewFrame {
    UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
    CGFloat navBarHeight = hxNavigationBarHeight;
    NSInteger lineCount = 2;
    if (orientation == UIInterfaceOrientationPortrait || UIInterfaceOrientationPortrait == UIInterfaceOrientationPortraitUpsideDown) {
        navBarHeight = hxNavigationBarHeight;
        lineCount = 2;
        [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationFade];
    }else if (orientation == UIInterfaceOrientationLandscapeRight || orientation == UIInterfaceOrientationLandscapeLeft){
        [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationFade];
        if ([UIApplication sharedApplication].statusBarHidden) {
            navBarHeight = self.navigationController.navigationBar.hx_h;
        }else {
            navBarHeight = self.navigationController.navigationBar.hx_h + 20;
        }
        lineCount = 3;
    }
    CGFloat leftMargin = 0;
    CGFloat rightMargin = 0;
    CGFloat width = self.view.hx_w;
    if (HX_IS_IPhoneX_All && (orientation == UIInterfaceOrientationLandscapeLeft || orientation == UIInterfaceOrientationLandscapeRight)) {
        leftMargin = 35;
        rightMargin = 35;
        width = self.view.hx_w - 70;
    }
    if (self.manager.configuration.singleSelected) {
        self.tableView.contentInset = UIEdgeInsetsMake(navBarHeight, leftMargin, 0, rightMargin);
        self.tableView.scrollIndicatorInsets = UIEdgeInsetsMake(navBarHeight, leftMargin, 0, rightMargin);
        if (self.manager.configuration.albumListTableView) {
            self.manager.configuration.albumListTableView(self.tableView);
        }
    }else {
        CGFloat itemWidth = (width - (lineCount + 1) * 15) / lineCount;
        CGFloat itemHeight = itemWidth + 6 + 14 + 4 + 14;
        self.flowLayout.itemSize = CGSizeMake(itemWidth, itemHeight);
        
        self.collectionView.contentInset = UIEdgeInsetsMake(navBarHeight, leftMargin, 0, rightMargin);
        self.collectionView.scrollIndicatorInsets = UIEdgeInsetsMake(navBarHeight, leftMargin, 0, rightMargin);
        if (self.orientationDidChange) {
            [self.collectionView scrollToItemAtIndexPath:self.beforeOrientationIndexPath atScrollPosition:UICollectionViewScrollPositionTop animated:NO];
        }
        if (self.manager.configuration.albumListCollectionView) {
            self.manager.configuration.albumListCollectionView(self.collectionView);
        }
    }
}
- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [[UIApplication sharedApplication] setStatusBarStyle:self.manager.configuration.statusBarStyle];
}
- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if (self.albumModelArray.count == 0) {
        [self getAlbumModelList:NO];
    }
}
- (void)setupUI {
    [self.navigationController.navigationBar setTintColor:self.manager.configuration.themeColor];
    if (self.manager.configuration.navBarBackgroudColor) {
        [self.navigationController.navigationBar setBackgroundColor:nil];
        [self.navigationController.navigationBar setBackgroundImage:nil forBarMetrics:UIBarMetricsDefault];
        self.navigationController.navigationBar.barTintColor = self.manager.configuration.navBarBackgroudColor;
    }
    if (self.manager.configuration.navigationBar) {
        self.manager.configuration.navigationBar(self.navigationController.navigationBar, self);
    }
    if (self.manager.configuration.navigationTitleSynchColor) {
        self.navigationController.navigationBar.titleTextAttributes = @{NSForegroundColorAttributeName : self.manager.configuration.themeColor};
    }else {
        if (self.manager.configuration.navigationTitleColor) {
            self.navigationController.navigationBar.titleTextAttributes = @{NSForegroundColorAttributeName : self.manager.configuration.navigationTitleColor};
        }
    }
    
    self.title = [NSBundle hx_localizedStringForKey:@"相册"];
    self.view.backgroundColor = [UIColor whiteColor];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:[NSBundle hx_localizedStringForKey:@"取消"] style:UIBarButtonItemStyleDone target:self action:@selector(cancelClick)];
    if (self.manager.configuration.singleSelected) {
        [self.view addSubview:self.tableView];
    }else {
        [self.view addSubview:self.collectionView];
    }
    [self changeSubviewFrame];
}
- (void)setPhotoManager {
    [self.manager selectedListTransformBefore];
}
- (void)cancelClick {
    [self.manager cancelBeforeSelectedList]; 
    if ([self.delegate respondsToSelector:@selector(albumListViewControllerDidCancel:)]) {
        [self.delegate albumListViewControllerDidCancel:self];
    }
    if (self.cancelBlock) {
        self.cancelBlock(self, self.manager);
    }
    [self dismissViewControllerAnimated:YES completion:nil];
}
#pragma mark - < HXDatePhotoViewControllerDelegate >
- (void)datePhotoViewController:(HXDatePhotoViewController *)datePhotoViewController allAssetList:(NSArray<PHAsset *> *)allAssetList photoAssets:(NSArray<PHAsset *> *)photoAssetList videoAssets:(NSArray<PHAsset *> *)videoAssetList original:(BOOL)original {
    if ([self.delegate respondsToSelector:@selector(albumListViewControllerDidDone:allAssetList:photoAssets:videoAssets:original:)]) {
        [self.delegate albumListViewControllerDidDone:self allAssetList:allAssetList photoAssets:photoAssetList videoAssets:videoAssetList original:original];
    }
}
- (void)datePhotoViewController:(HXDatePhotoViewController *)datePhotoViewController didDoneAllImage:(NSArray<UIImage *> *)imageList original:(BOOL)original  {
    if ([self.delegate respondsToSelector:@selector(albumListViewController:didDoneAllImage:)]) {
        [self.delegate albumListViewController:self didDoneAllImage:imageList];
    }
    if (self.allImageBlock) {
        self.allImageBlock(imageList, original, self, self.manager);
    }
}
- (void)datePhotoViewController:(HXDatePhotoViewController *)datePhotoViewController didDoneAllList:(NSArray<HXPhotoModel *> *)allList photos:(NSArray<HXPhotoModel *> *)photoList videos:(NSArray<HXPhotoModel *> *)videoList original:(BOOL)original {
    if ([self.delegate respondsToSelector:@selector(albumListViewController:didDoneAllList:photos:videos:original:)]) {
        [self.delegate albumListViewController:self didDoneAllList:allList photos:photoList videos:videoList original:original];
    }
    if (self.doneBlock) {
        self.doneBlock(allList, photoList, videoList, original, self, self.manager);
    }
}
- (void)datePhotoViewControllerDidCancel:(HXDatePhotoViewController *)datePhotoViewController {
    [self cancelClick];
}
- (void)datePhotoViewControllerDidChangeSelect:(HXPhotoModel *)model selected:(BOOL)selected {
    if (self.albumModelArray.count > 0) {
//        HXAlbumModel *albumModel = self.albumModelArray[model.currentAlbumIndex];
//        if (selected) {
//            albumModel.selectedCount++;
//        }else {
//            albumModel.selectedCount--;
//        }
//        [self.collectionView reloadItemsAtIndexPaths:@[[NSIndexPath indexPathForItem:model.currentAlbumIndex inSection:0]]];
    }
}
- (void)getAlbumModelList:(BOOL)isFirst {
    if (self.manager.albums.count > 0 &&
        self.manager.configuration.saveSystemAblum &&
        !self.manager.configuration.singleSelected) {
        [self.view handleLoading];
        self.albumModelArray = [NSMutableArray arrayWithArray:self.manager.albums];
        HXAlbumModel *model = self.albumModelArray.firstObject;
        HXDatePhotoViewController *vc = [[HXDatePhotoViewController alloc] init];
        vc.manager = self.manager;
        vc.title = model.albumName;
        vc.albumModel = model;
        vc.delegate = self;
        [self.navigationController pushViewController:vc animated:NO];
        NSInteger i = 0;
        for (HXAlbumModel *albumMd in self.albumModelArray) {
            albumMd.cameraCount = [self.manager cameraCount];
            if (i == 0 && !albumMd.result) {
                albumMd.tempImage = [self.manager firstCameraModel].thumbPhoto;
            }
            i++;
        }
        if (self.manager.configuration.singleSelected) {
            [self.tableView reloadData];
        }else {
            [self.collectionView reloadData];
        }
        return;
    }
    if (!isFirst) {
        [self.view showLoadingHUDText:nil];
    }
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        __weak typeof(self) weakSelf = self;
        [self.manager getAllPhotoAlbums:^(HXAlbumModel *firstAlbumModel) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [weakSelf.view handleLoading];
                HXAlbumModel *model = firstAlbumModel;
                HXDatePhotoViewController *vc = [[HXDatePhotoViewController alloc] init];
                vc.manager = weakSelf.manager;
                vc.title = model.albumName;
                vc.albumModel = model;
                vc.delegate = weakSelf;
                [weakSelf.navigationController pushViewController:vc animated:NO];
                if (weakSelf.manager.configuration.saveSystemAblum && !weakSelf.manager.configuration.singleSelected) {
                    if (weakSelf.albumModelArray.count == 0) {
                        [weakSelf getAlbumModelList:NO];
                    }
                }
            });
        } albums:^(NSArray *albums) {
            weakSelf.albumModelArray = [NSMutableArray arrayWithArray:albums];
            for (HXAlbumModel *albumMd in weakSelf.albumModelArray) {
                albumMd.cameraCount = [weakSelf.manager cameraCount];
            }
            dispatch_async(dispatch_get_main_queue(), ^{
                if (weakSelf.manager.configuration.singleSelected) {
                    [weakSelf.tableView reloadData];
                }else {
                    [weakSelf.collectionView reloadData];
                }
                [weakSelf.view handleLoading];
            });
        } isFirst:isFirst];
    });
}
#pragma mark - < UICollectionViewDataSource >
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.albumModelArray.count;
}
- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    HXAlbumListQuadrateViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"cellId" forIndexPath:indexPath];
    cell.model = self.albumModelArray[indexPath.item];
    return cell;
}
#pragma mark - < UICollectionViewDelegate >
- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    if (self.navigationController.topViewController != self) {
        return;
    }
    HXAlbumModel *model = self.albumModelArray[indexPath.item];
    HXDatePhotoViewController *vc = [[HXDatePhotoViewController alloc] init];
    vc.manager = self.manager;
    vc.title = model.albumName;
    vc.albumModel = model;
    vc.delegate = self;
    [self.navigationController pushViewController:vc animated:YES];
}
- (void)collectionView:(UICollectionView *)collectionView didEndDisplayingCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath {
    [(HXAlbumListQuadrateViewCell *)cell cancelRequest];
}
#pragma mark - < UITableViewDataSource >
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.albumModelArray.count;
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    HXAlbumListSingleViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"tableViewCellId"];
    cell.model = self.albumModelArray[indexPath.row];
    return cell;
}
#pragma mark - < UITableViewDelegate >
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if (self.navigationController.topViewController != self) {
        return;
    }
    HXAlbumModel *model = self.albumModelArray[indexPath.row];
    HXDatePhotoViewController *vc = [[HXDatePhotoViewController alloc] init];
    vc.manager = self.manager;
    vc.title = model.albumName;
    vc.albumModel = model;
    vc.delegate = self;
    [self.navigationController pushViewController:vc animated:YES];
}
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 100;
}
- (void)tableView:(UITableView *)tableView didEndDisplayingCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    [(HXAlbumListSingleViewCell *)cell cancelRequest];
}

- (UIViewController *)previewingContext:(id<UIViewControllerPreviewing>)previewingContext viewControllerForLocation:(CGPoint)location {
    NSIndexPath *indexPath = [self.collectionView indexPathForItemAtPoint:location];
    if (!indexPath) {
        return nil;
    }
    HXAlbumListQuadrateViewCell *cell = (HXAlbumListQuadrateViewCell *)[self.collectionView cellForItemAtIndexPath:indexPath];
    //设置突出区域
    CGRect frame = [self.collectionView cellForItemAtIndexPath:indexPath].frame;
    previewingContext.sourceRect = CGRectMake(frame.origin.x, frame.origin.y, frame.size.width, frame.size.width);
    HXDatePhotoViewController *vc = [[HXDatePhotoViewController alloc] init];
    vc.manager = self.manager;
    vc.title = cell.model.albumName;
    vc.albumModel = cell.model;
    vc.delegate = self;
    return vc;
}
- (void)previewingContext:(id<UIViewControllerPreviewing>)previewingContext commitViewController:(UIViewController *)viewControllerToCommit {
    [self.navigationController pushViewController:viewControllerToCommit animated:YES];
}
#pragma mark - < 懒加载 >
- (UITableView *)tableView {
    if (!_tableView) {
        _tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, self.view.hx_w, self.view.hx_h) style:UITableViewStylePlain];
        _tableView.dataSource = self;
        _tableView.delegate = self;
        _tableView.estimatedRowHeight = 0;
        _tableView.estimatedSectionFooterHeight = 0;
        _tableView.estimatedSectionHeaderHeight = 0;
        _tableView.backgroundColor = [UIColor whiteColor];
        _tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        _tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        [_tableView registerClass:[HXAlbumListSingleViewCell class] forCellReuseIdentifier:@"tableViewCellId"];
#ifdef __IPHONE_11_0
        if (@available(iOS 11.0, *)) {
            if ([self navigationBarWhetherSetupBackground]) {
                self.navigationController.navigationBar.translucent = NO;
            }else {
                _tableView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
            }
#else
            if ((NO)) {
#endif
            } else {
                if ([self navigationBarWhetherSetupBackground]) {
                    self.navigationController.navigationBar.translucent = NO;
                }else {
                    self.automaticallyAdjustsScrollViewInsets = NO;
                }
            }
    }
    return _tableView;
}
- (UICollectionView *)collectionView {
    if (!_collectionView) {
        _collectionView = [[UICollectionView alloc] initWithFrame:CGRectMake(0, 0, self.view.hx_w, self.view.hx_h) collectionViewLayout:self.flowLayout];
        _collectionView.backgroundColor = [UIColor whiteColor];
        _collectionView.dataSource = self;
        _collectionView.delegate = self;
        _collectionView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        _collectionView.alwaysBounceVertical = YES;
        [_collectionView registerClass:[HXAlbumListQuadrateViewCell class] forCellWithReuseIdentifier:@"cellId"];
//        _collectionView.contentInset = UIEdgeInsetsMake(hxNavigationBarHeight, 0, 0, 0);
//        _collectionView.scrollIndicatorInsets = UIEdgeInsetsMake(hxNavigationBarHeight, 0, 0, 0);
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
//        CGFloat itemWidth = (self.view.hx_w - 45) / 2;
//        CGFloat itemHeight = itemWidth + 6 + 14 + 4 + 14;
//        _flowLayout.itemSize = CGSizeMake(itemWidth, itemHeight);
        _flowLayout.minimumLineSpacing = 15;
        _flowLayout.minimumInteritemSpacing = 15;
        _flowLayout.sectionInset = UIEdgeInsetsMake(15, 15, 15, 15);
    }
    return _flowLayout;
}
- (UILabel *)authorizationLb {
    if (!_authorizationLb) {
        _authorizationLb = [[UILabel alloc] initWithFrame:CGRectMake(0, 200, self.view.frame.size.width, 100)];
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
- (void)dealloc {
    if (HXShowLog) NSSLog(@"dealloc");
    if (self.manager.configuration.open3DTouchPreview) {
        if (self.previewingContext) {
            [self unregisterForPreviewingWithContext:self.previewingContext];
        }
    }
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"CustomCameraViewControllerDidDoneNotification" object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidChangeStatusBarOrientationNotification object:nil];
}
- (void)goSetup {
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]];
}
@end

@interface HXAlbumListQuadrateViewCell ()
@property (strong, nonatomic) UIImageView *coverView;
@property (strong, nonatomic) UIButton *selectNumberBtn;
@property (strong, nonatomic) UILabel *albumNameLb;
@property (strong, nonatomic) UILabel *photoNumberLb;
@property (assign, nonatomic) PHImageRequestID requestID;
@end

@implementation HXAlbumListQuadrateViewCell

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setupUI];
    }
    return self;
}
- (void)setupUI {
    [self.contentView addSubview:self.coverView];
    [self.contentView addSubview:self.albumNameLb];
    [self.contentView addSubview:self.photoNumberLb];
//    [self.contentView addSubview:self.selectNumberBtn];
}
- (void)setModel:(HXAlbumModel *)model {
    _model = model;
    if (!model.asset) {
        model.asset = model.result.lastObject;
    }
    __weak typeof(self) weakSelf = self;
    self.requestID = [HXPhotoTools getImageWithAlbumModel:model size:CGSizeMake(self.hx_w * 1.5, self.hx_w * 1.5) completion:^(UIImage *image, HXAlbumModel *model) {
        if (weakSelf.model == model) {
            weakSelf.coverView.image = image;
        }
    }];
    
    self.albumNameLb.text = model.albumName;
    self.photoNumberLb.text = @(model.result.count + model.cameraCount).stringValue;
    if (!model.result) {
        self.coverView.image = model.tempImage ?: [HXPhotoTools hx_imageNamed:@"hx_yundian_tupian@3x.png"];
    }
//    if (model.selectedCount == 0) {
//        self.selectNumberBtn.hidden = YES;
//    }else {
//        self.selectNumberBtn.hidden = NO;
//    }
//    [self.selectNumberBtn setTitle:@(model.selectedCount).stringValue forState:UIControlStateNormal];
}
- (void)layoutSubviews {
    [super layoutSubviews];
    self.coverView.frame = CGRectMake(0, 0, self.hx_w, self.hx_w);
    self.albumNameLb.frame = CGRectMake(0, self.hx_w + 6, self.hx_w, 14);
    self.photoNumberLb.frame = CGRectMake(0, CGRectGetMaxY(self.albumNameLb.frame) + 4, self.hx_w, 14);
    self.selectNumberBtn.hx_size = CGSizeMake(12, 12);
    self.selectNumberBtn.hx_x = self.hx_w - 5 - self.selectNumberBtn.hx_w;
    CGFloat margin = (self.hx_h - self.hx_w) / 2 + 3;
    self.selectNumberBtn.center = CGPointMake(self.selectNumberBtn.center.x, self.hx_w + margin);
}
- (void)cancelRequest {
    if (self.requestID) {
        [[PHImageManager defaultManager] cancelImageRequest:self.requestID];
        self.requestID = -1;
    }
}
- (void)dealloc {
    [self cancelRequest];
}
#pragma mark - < cell懒加载 >
- (UIImageView *)coverView {
    if (!_coverView) {
        _coverView = [[UIImageView alloc] init];
        _coverView.layer.masksToBounds = YES;
        _coverView.layer.cornerRadius = 4;
        _coverView.contentMode = UIViewContentModeScaleAspectFill;
        _coverView.clipsToBounds = YES;
    }
    return _coverView;
}
- (UILabel *)albumNameLb {
    if (!_albumNameLb) {
        _albumNameLb = [[UILabel alloc] init];
        _albumNameLb.textColor = [UIColor blackColor];
        _albumNameLb.font = [UIFont systemFontOfSize:13];
    }
    return _albumNameLb;
}
- (UILabel *)photoNumberLb {
    if (!_photoNumberLb) {
        _photoNumberLb = [[UILabel alloc] init];
        _photoNumberLb.textColor = [UIColor lightGrayColor];
        _photoNumberLb.font = [UIFont systemFontOfSize:13];
    }
    return _photoNumberLb;
}
- (UIButton *)selectNumberBtn {
    if (!_selectNumberBtn) {
        _selectNumberBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        _selectNumberBtn.userInteractionEnabled = NO;
        [_selectNumberBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        _selectNumberBtn.titleLabel.font = [UIFont systemFontOfSize:14];
//        [_selectNumberBtn setBackgroundColor:self.manager.themeColor];
        _selectNumberBtn.layer.cornerRadius = 12.f / 2;
        _selectNumberBtn.titleLabel.adjustsFontSizeToFitWidth = YES;
    }
    return _selectNumberBtn;
}
@end

@interface HXAlbumListSingleViewCell ()
@property (strong, nonatomic) UIImageView *coverView1;
@property (strong, nonatomic) UIImageView *coverView2;
@property (strong, nonatomic) UIImageView *coverView3;
@property (strong, nonatomic) UILabel *albumNameLb;
@property (strong, nonatomic) UILabel *photoNumberLb;
@property (assign, nonatomic) PHImageRequestID requestId1;
@property (assign, nonatomic) PHImageRequestID requestId2;
@property (assign, nonatomic) PHImageRequestID requestId3;
@end

@implementation HXAlbumListSingleViewCell
- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        [self setupUI];
    }
    return self;
}
- (void)setupUI {
    [self.contentView addSubview:self.coverView3];
    [self.contentView addSubview:self.coverView2];
    [self.contentView addSubview:self.coverView1];
    [self.contentView addSubview:self.albumNameLb];
    [self.contentView addSubview:self.photoNumberLb];
}
- (void)cancelRequest {
    if (self.requestId1) {
        [[PHImageManager defaultManager] cancelImageRequest:self.requestId1];
        self.requestId1 = -1;
    }
    if (self.requestId2) {
        [[PHImageManager defaultManager] cancelImageRequest:self.requestId2];
        self.requestId2 = -1;
    }
    if (self.requestId3) {
        [[PHImageManager defaultManager] cancelImageRequest:self.requestId3];
        self.requestId3 = -1;
    }
}
- (void)setModel:(HXAlbumModel *)model {
    _model = model;
    NSInteger photoCount = model.result.count;
    if (!model.asset) {
        model.asset = model.result.lastObject;
    }
    __weak typeof(self) weakSelf = self;
    self.requestId1 = [HXPhotoTools getImageWithAlbumModel:model size:CGSizeMake(self.hx_h * 1.6, self.hx_h * 1.6) completion:^(UIImage *image, HXAlbumModel *model) {
        if (weakSelf.model == model) {
            weakSelf.coverView1.image = image;
        }
    }];
    if (photoCount == 1) {
        self.coverView2.hidden = YES;
        self.coverView3.hidden = YES;
    }else if (photoCount == 2) {
        if (!model.asset2) {
            model.asset2 = model.result[1];
        }
        self.requestId2 = [HXPhotoTools getImageWithAlbumModel:model asset:model.asset2 size:CGSizeMake(self.hx_h * 0.7, self.hx_h * 0.7) completion:^(UIImage *image, HXAlbumModel *model) {
            if (weakSelf.model == model) {
                weakSelf.coverView2.image = image;
            }
        }];
        self.coverView2.hidden = NO;
        self.coverView3.hidden = YES;
    }else {
        if (!model.asset2) {
            model.asset2 = model.result[1];
        }
        if (!model.asset3) {
            model.asset3 = model.result[2];
        }
        self.coverView2.hidden = NO;
        self.coverView3.hidden = NO;
        
        self.requestId2 = [HXPhotoTools getImageWithAlbumModel:model asset:model.asset2 size:CGSizeMake(self.hx_h * 0.7, self.hx_h * 0.7) completion:^(UIImage *image, HXAlbumModel *model) {
            if (weakSelf.model == model) {
                weakSelf.coverView2.image = image;
            }
        }];
        self.requestId3 = [HXPhotoTools getImageWithAlbumModel:model asset:model.asset3 size:CGSizeMake(self.hx_h * 0.5, self.hx_h * 0.5) completion:^(UIImage *image, HXAlbumModel *model) {
            if (weakSelf.model == model) {
                weakSelf.coverView3.image = image;
            }
        }];
    }
    
    self.albumNameLb.text = model.albumName;
    self.photoNumberLb.text = @(photoCount + model.cameraCount).stringValue;
    if (!model.result) {
        self.coverView1.image = model.tempImage ?: [HXPhotoTools hx_imageNamed:@"hx_yundian_tupian@3x.png"];
        self.coverView2.hidden = YES;
        self.coverView3.hidden = YES;
    }
}
- (void)layoutSubviews {
    [super layoutSubviews];
    self.coverView1.frame = CGRectMake(10, 5, self.hx_h - 10, self.hx_h - 10);
    if (self.model.count == 2) {
        self.coverView2.frame = CGRectMake(12.5, 3.5, self.hx_h - 15, self.hx_h - 15);
    }else {
        self.coverView2.frame = CGRectMake(12.5, 3.5, self.hx_h - 15, self.hx_h - 15);
        self.coverView3.frame = CGRectMake(15, 2, self.hx_h - 20, self.hx_h - 20);
    }
    CGFloat albumNameLbX = CGRectGetMaxX(self.coverView1.frame) + 12;
    CGFloat albumNameLbY = self.hx_h / 2  - 16;
    self.albumNameLb.frame = CGRectMake(albumNameLbX, albumNameLbY, self.hx_w - albumNameLbX - 40, 14);
    self.photoNumberLb.frame = CGRectMake(albumNameLbX, self.hx_h / 2 + 2, self.hx_w, 13);
}
- (void)dealloc {
    [self cancelRequest];
}
#pragma mark - < cell懒加载 >
- (UIImageView *)coverView1 {
    if (!_coverView1) {
        _coverView1 = [[UIImageView alloc] init];
        _coverView1.contentMode = UIViewContentModeScaleAspectFill;
        _coverView1.clipsToBounds = YES;
    }
    return _coverView1;
}
- (UIImageView *)coverView2 {
    if (!_coverView2) {
        _coverView2 = [[UIImageView alloc] init];
        _coverView2.contentMode = UIViewContentModeScaleAspectFill;
        _coverView2.clipsToBounds = YES;
    }
    return _coverView2;
}
- (UIImageView *)coverView3 {
    if (!_coverView3) {
        _coverView3 = [[UIImageView alloc] init];
        _coverView3.contentMode = UIViewContentModeScaleAspectFill;
        _coverView3.clipsToBounds = YES;
    }
    return _coverView3;
}
- (UILabel *)albumNameLb {
    if (!_albumNameLb) {
        _albumNameLb = [[UILabel alloc] init];
        _albumNameLb.textColor = [UIColor blackColor];
        _albumNameLb.font = [UIFont systemFontOfSize:13];
    }
    return _albumNameLb;
}
- (UILabel *)photoNumberLb {
    if (!_photoNumberLb) {
        _photoNumberLb = [[UILabel alloc] init];
        _photoNumberLb.textColor = [UIColor lightGrayColor];
        _photoNumberLb.font = [UIFont systemFontOfSize:12];
    }
    return _photoNumberLb;
}
@end
