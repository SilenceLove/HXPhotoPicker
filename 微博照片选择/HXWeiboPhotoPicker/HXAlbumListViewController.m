//
//  HXDateAlbumViewController.m
//  微博照片选择
//
//  Created by 洪欣 on 2017/10/14.
//  Copyright © 2017年 洪欣. All rights reserved.
//

#import "HXAlbumListViewController.h" 
#import "HXDatePhotoViewController.h"
@interface HXAlbumListViewController ()<UICollectionViewDataSource,UICollectionViewDelegate,UIViewControllerPreviewingDelegate,HXDatePhotoViewControllerDelegate>

@property (strong, nonatomic) UICollectionViewFlowLayout *flowLayout;
@property (strong, nonatomic) UICollectionView *collectionView;

@property (strong, nonatomic) NSMutableArray *albumModelArray;
@property (strong, nonatomic) NSTimer *timer;
@property (strong, nonatomic) UILabel *authorizationLb;
@property (weak, nonatomic) id<UIViewControllerPreviewing> previewingContext;

@property (assign, nonatomic) BOOL orientationDidChange;
@property (strong, nonatomic) NSIndexPath *beforeOrientationIndexPath;
@end

@implementation HXAlbumListViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setPhotoManager];
    self.navigationController.popoverPresentationController.delegate = (id)self;
    [self setupUI];
    [self getAlbumModelList:YES];
    // 获取当前应用对照片的访问授权状态
    if ([PHPhotoLibrary authorizationStatus] != PHAuthorizationStatusAuthorized) {
        [self.view addSubview:self.authorizationLb];
        self.timer = [NSTimer scheduledTimerWithTimeInterval:0.2 target:self selector:@selector(observeAuthrizationStatusChange:) userInfo:nil repeats:YES];
    }
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(deviceOrientationChanged:) name:UIApplicationDidChangeStatusBarOrientationNotification object:nil];
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
}
- (void)changeSubviewFrame {
    UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
    CGFloat navBarHeight = kNavigationBarHeight;
    NSInteger lineCount = 2;
    if (orientation == UIInterfaceOrientationPortrait || UIInterfaceOrientationPortrait == UIInterfaceOrientationPortraitUpsideDown) {
        navBarHeight = kNavigationBarHeight;
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
    if (kDevice_Is_iPhoneX && (orientation == UIInterfaceOrientationLandscapeLeft || orientation == UIInterfaceOrientationLandscapeRight)) {
        leftMargin = 35;
        rightMargin = 35;
        width = self.view.hx_w - 70;
    }
    
    CGFloat itemWidth = (width - (lineCount + 1) * 15) / lineCount;
    CGFloat itemHeight = itemWidth + 6 + 14 + 4 + 14;
    self.flowLayout.itemSize = CGSizeMake(itemWidth, itemHeight);
    
    self.collectionView.contentInset = UIEdgeInsetsMake(navBarHeight, leftMargin, 0, rightMargin);
    self.collectionView.scrollIndicatorInsets = UIEdgeInsetsMake(navBarHeight, leftMargin, 0, rightMargin);
    if (self.orientationDidChange) {
        [self.collectionView scrollToItemAtIndexPath:self.beforeOrientationIndexPath atScrollPosition:UICollectionViewScrollPositionTop animated:NO];
    }
}
- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if (self.albumModelArray.count == 0) {
        [self getAlbumModelList:NO];
    }
}
- (void)observeAuthrizationStatusChange:(NSTimer *)timer {
    if ([PHPhotoLibrary authorizationStatus] == PHAuthorizationStatusAuthorized) {
        [timer invalidate];
        [self.timer invalidate];
        self.timer = nil;
        [self.authorizationLb removeFromSuperview];
//        if (self.manager.albums.count > 0) {
//            if (self.manager.cacheAlbum) {
//                self.albums = self.manager.albums.mutableCopy;
//                [self getAlbumPhotos];
//            }else {
//                [self getObjs];
//            }
//        }else {
        [self getAlbumModelList:YES];
//        }
    }
}
- (void)setupUI {
    self.title = @"相册";
    self.view.backgroundColor = [UIColor whiteColor];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"取消" style:UIBarButtonItemStylePlain target:self action:@selector(cancelClick)];
    [self.view addSubview:self.collectionView];
    [self changeSubviewFrame];
}
- (void)setPhotoManager {
    if (self.manager.type == HXPhotoManagerSelectedTypePhoto) {
        if (self.manager.networkPhotoUrls.count == 0) {
            self.manager.maxNum = self.manager.photoMaxNum;
        }
        if (self.manager.endCameraVideos.count > 0) {
            [self.manager.endCameraList removeObjectsInArray:self.manager.endCameraVideos];
            [self.manager.endCameraVideos removeAllObjects];
        }
    }else if (self.manager.type == HXPhotoManagerSelectedTypeVideo) {
        if (self.manager.networkPhotoUrls.count == 0) {
            self.manager.maxNum = self.manager.videoMaxNum;
        }
        if (self.manager.endCameraPhotos.count > 0) {
            [self.manager.endCameraList removeObjectsInArray:self.manager.endCameraPhotos];
            [self.manager.endCameraPhotos removeAllObjects];
        }
    }else {
        // 防错  请在外面设置好!!!!
        if (self.manager.networkPhotoUrls.count == 0) {
            if (self.manager.videoMaxNum + self.manager.photoMaxNum != self.manager.maxNum) {
                self.manager.maxNum = self.manager.videoMaxNum + self.manager.photoMaxNum;
            }
        }
    }
    // 上次选择的所有记录
    self.manager.selectedList = [NSMutableArray arrayWithArray:self.manager.endSelectedList];
    self.manager.selectedPhotos = [NSMutableArray arrayWithArray:self.manager.endSelectedPhotos];
    self.manager.selectedVideos = [NSMutableArray arrayWithArray:self.manager.endSelectedVideos];
    self.manager.cameraList = [NSMutableArray arrayWithArray:self.manager.endCameraList];
    self.manager.cameraPhotos = [NSMutableArray arrayWithArray:self.manager.endCameraPhotos];
    self.manager.cameraVideos = [NSMutableArray arrayWithArray:self.manager.endCameraVideos];
    self.manager.selectedCameraList = [NSMutableArray arrayWithArray:self.manager.endSelectedCameraList];
    self.manager.selectedCameraPhotos = [NSMutableArray arrayWithArray:self.manager.endSelectedCameraPhotos];
    self.manager.selectedCameraVideos = [NSMutableArray arrayWithArray:self.manager.endSelectedCameraVideos];
    self.manager.isOriginal = self.manager.endIsOriginal;
    self.manager.photosTotalBtyes = self.manager.endPhotosTotalBtyes;
}
- (void)cancelClick {
    if (self.timer) {
        [self.timer invalidate];
        self.timer = nil;
    }
    [self.manager.selectedList removeAllObjects];
    [self.manager.selectedPhotos removeAllObjects];
    [self.manager.selectedVideos removeAllObjects];
    self.manager.isOriginal = NO;
    self.manager.photosTotalBtyes = nil;
    [self.manager.selectedCameraList removeAllObjects];
    [self.manager.selectedCameraVideos removeAllObjects];
    [self.manager.selectedCameraPhotos removeAllObjects];
    [self.manager.cameraPhotos removeAllObjects];
    [self.manager.cameraList removeAllObjects];
    [self.manager.cameraVideos removeAllObjects];
    if ([self.delegate respondsToSelector:@selector(albumListViewControllerDidCancel:)]) {
        [self.delegate albumListViewControllerDidCancel:self];
    }
    [self dismissViewControllerAnimated:YES completion:nil];
}
#pragma mark - < HXDatePhotoViewControllerDelegate >
- (void)datePhotoViewController:(HXDatePhotoViewController *)datePhotoViewController didDoneAllList:(NSArray<HXPhotoModel *> *)allList photos:(NSArray<HXPhotoModel *> *)photoList videos:(NSArray<HXPhotoModel *> *)videoList original:(BOOL)original {
    if ([self.delegate respondsToSelector:@selector(albumListViewController:didDoneAllList:photos:videos:original:)]) {
        [self.delegate albumListViewController:self didDoneAllList:allList photos:photoList videos:videoList original:original];

    }
}
- (void)datePhotoViewControllerDidCancel:(HXDatePhotoViewController *)datePhotoViewController {
    [self cancelClick];
    if ([self.delegate respondsToSelector:@selector(albumListViewControllerDidCancel:)]) {
        [self.delegate albumListViewControllerDidCancel:self];
    }
}
- (void)datePhotoViewControllerDidChangeSelect:(HXPhotoModel *)model selected:(BOOL)selected {
    if (self.albumModelArray.count > 0) {
        HXAlbumModel *albumModel = self.albumModelArray[model.currentAlbumIndex];
        if (selected) {
            albumModel.selectedCount++;
        }else {
            albumModel.selectedCount--;
        }
        [self.collectionView reloadItemsAtIndexPaths:@[[NSIndexPath indexPathForItem:model.currentAlbumIndex inSection:0]]];
    }
}
- (void)getAlbumModelList:(BOOL)isFirst {
    if (!isFirst) {
        [self.view showLoadingHUDText:[NSBundle hx_localizedStringForKey:@"加载中"]];
    }
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        __weak typeof(self) weakSelf = self;
        [self.manager getAllPhotoAlbums:^(HXAlbumModel *firstAlbumModel) {
            dispatch_async(dispatch_get_main_queue(), ^{
                HXAlbumModel *model = firstAlbumModel;
                HXDatePhotoViewController *vc = [[HXDatePhotoViewController alloc] init];
                vc.manager = weakSelf.manager;
                vc.title = model.albumName;
                vc.albumModel = model;
                vc.delegate = weakSelf;
                [weakSelf.navigationController pushViewController:vc animated:NO];
            });
        } albums:^(NSArray *albums) {
            weakSelf.albumModelArray = [NSMutableArray arrayWithArray:albums];
            dispatch_async(dispatch_get_main_queue(), ^{
                [weakSelf.collectionView reloadData];
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
- (UICollectionView *)collectionView {
    if (!_collectionView) {
        _collectionView = [[UICollectionView alloc] initWithFrame:CGRectMake(0, 0, self.view.hx_w, self.view.hx_h) collectionViewLayout:self.flowLayout];
        _collectionView.backgroundColor = [UIColor whiteColor];
        _collectionView.dataSource = self;
        _collectionView.delegate = self;
        _collectionView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        _collectionView.alwaysBounceVertical = YES;
        [_collectionView registerClass:[HXAlbumListQuadrateViewCell class] forCellWithReuseIdentifier:@"cellId"];
//        _collectionView.contentInset = UIEdgeInsetsMake(kNavigationBarHeight, 0, 0, 0);
//        _collectionView.scrollIndicatorInsets = UIEdgeInsetsMake(kNavigationBarHeight, 0, 0, 0);
#ifdef __IPHONE_11_0
        if (@available(iOS 11.0, *)) {
            _collectionView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
#else
            if ((NO)) {
#endif
            } else {
                self.automaticallyAdjustsScrollViewInsets = NO;
            }
            if (self.manager.open3DTouchPreview) {
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
    NSSLog(@"dealloc");
    [self unregisterForPreviewingWithContext:self.previewingContext];
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
@property (copy, nonatomic) NSString *localIdentifier;
@property (assign, nonatomic) int32_t requestID;
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
        model.albumImage = nil;
    }
    self.localIdentifier = model.asset.localIdentifier;
    __weak typeof(self) weakSelf = self;
    int32_t requestID = [HXPhotoTools fetchPhotoWithAsset:model.asset photoSize:CGSizeMake(self.hx_w * 1.5, self.hx_w * 1.5) completion:^(UIImage *photo, NSDictionary *info, BOOL isDegraded) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        strongSelf.coverView.image = photo;
//        if (strongSelf.requestID) {
//            [[PHImageManager defaultManager] cancelImageRequest:strongSelf.requestID];
//            strongSelf.requestID = -1;
//        }
    }];
    if (requestID && self.requestID && requestID != self.requestID) {
        [[PHImageManager defaultManager] cancelImageRequest:self.requestID];
    }
    self.requestID = requestID;
    
    self.albumNameLb.text = model.albumName;
    self.photoNumberLb.text = @(model.result.count).stringValue;
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
        [_selectNumberBtn setBackgroundColor:self.tintColor];
        _selectNumberBtn.layer.cornerRadius = 12.f / 2;
        _selectNumberBtn.titleLabel.adjustsFontSizeToFitWidth = YES;
    }
    return _selectNumberBtn;
}
@end
