//
//  HXDateAlbumViewController.m
//  HXPhotoPickerExample
//
//  Created by Silence on 2017/10/14.
//  Copyright © 2017年 Silence. All rights reserved.
//

#import "HXAlbumListViewController.h" 
#import "HXPhotoViewController.h"
#import "UIViewController+HXExtension.h"
#import "HXAssetManager.h"

@interface HXAlbumListViewController ()
<
HXPhotoViewControllerDelegate,
UITableViewDataSource,
UITableViewDelegate
>
@property (strong, nonatomic) UITableView *tableView;
@property (strong, nonatomic) NSMutableArray *albumModelArray;
@property (strong, nonatomic) UILabel *authorizationLb;
@property (assign, nonatomic) BOOL orientationDidChange;
@property (strong, nonatomic) NSIndexPath *beforeOrientationIndexPath;
@end

@implementation HXAlbumListViewController
- (instancetype)initWithManager:(HXPhotoManager *)manager {
    self = [super init];
    if (self) {
        self.manager = manager;
    }
    return self;
}
- (void)requestData {
    // 获取当前应用对照片的访问授权状态
    HXWeakSelf
    self.hx_customNavigationController.reloadAsset = ^(BOOL initialAuthorization){
        if (initialAuthorization) {
            [weakSelf authorizationHandler];
        }
    };
    [self authorizationHandler];
}

- (void)authorizationHandler {
    PHAuthorizationStatus status = [HXPhotoTools authorizationStatus];
    if (status == PHAuthorizationStatusAuthorized) {
        [self getAlbumModelList:YES];
    }
#ifdef __IPHONE_14_0
    else if (@available(iOS 14, *)) {
        if (status == PHAuthorizationStatusLimited) {
            [self getAlbumModelList:YES];
            return;
        }
#endif
    else if (status == PHAuthorizationStatusDenied ||
             status == PHAuthorizationStatusRestricted){
        [self.hx_customNavigationController.view hx_handleLoading];
        [self.view addSubview:self.authorizationLb];
        [HXPhotoTools showNoAuthorizedAlertWithViewController:self status:status];
    }
#ifdef __IPHONE_14_0
    }else if (status == PHAuthorizationStatusDenied ||
              status == PHAuthorizationStatusRestricted){
         [self.hx_customNavigationController.view hx_handleLoading];
         [self.view addSubview:self.authorizationLb];
         [HXPhotoTools showNoAuthorizedAlertWithViewController:self status:status];
     }
#endif
}
- (UIStatusBarStyle)preferredStatusBarStyle {
    if ([HXPhotoCommon photoCommon].isDark) {
        return UIStatusBarStyleLightContent;
    }
    return self.manager.configuration.statusBarStyle;
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
- (void)viewDidLoad {
    [super viewDidLoad];
    self.extendedLayoutIncludesOpaqueBars = YES;
    self.edgesForExtendedLayout = UIRectEdgeAll;
    self.navigationController.popoverPresentationController.delegate = (id)self;
    [self requestData];
    [self setupUI];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(deviceOrientationChanged:) name:UIApplicationDidChangeStatusBarOrientationNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(customCameraViewControllerDidDoneClick) name:@"CustomCameraViewControllerDidDoneNotification" object:nil];
}
- (void)customCameraViewControllerDidDoneClick {
    NSInteger i = 0;
    for (HXAlbumModel *albumMd in self.albumModelArray) {
        albumMd.cameraCount = [self.manager cameraCount];
        if (i == 0 && !albumMd.localIdentifier) {
            albumMd.tempImage = [self.manager firstCameraModel].thumbPhoto;
        }
        i++;
    }
    [self.tableView reloadData];
}
- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    if (self.orientationDidChange) {
        [self changeSubviewFrame];
        self.orientationDidChange = NO;
    }
}
- (void)deviceOrientationChanged:(NSNotification *)notify {
    self.orientationDidChange = YES;
}
- (void)changeSubviewFrame {
    UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
    CGFloat navBarHeight = hxNavigationBarHeight;
#pragma clang diagnostic push
#pragma clang diagnostic ignored"-Wdeprecated-declarations"
    if (orientation == UIInterfaceOrientationPortrait || orientation == UIInterfaceOrientationPortraitUpsideDown) {
        navBarHeight = hxNavigationBarHeight;
        [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationFade];
    }else if (orientation == UIInterfaceOrientationLandscapeRight || orientation == UIInterfaceOrientationLandscapeLeft){
        [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationFade];
        if ([UIApplication sharedApplication].statusBarHidden) {
            navBarHeight = self.navigationController.navigationBar.hx_h;
        }else {
            navBarHeight = self.navigationController.navigationBar.hx_h + 20;
        }
    }
#pragma clang diagnostic pop
    CGFloat leftMargin = 0;
    CGFloat rightMargin = 0;
    CGFloat bottomMargin = hxBottomMargin;
    if (HX_IS_IPhoneX_All && (orientation == UIInterfaceOrientationLandscapeLeft || orientation == UIInterfaceOrientationLandscapeRight)) {
        leftMargin = 35;
        rightMargin = 35;
        bottomMargin = 0;
    }
    
        self.tableView.contentInset = UIEdgeInsetsMake(navBarHeight, leftMargin, bottomMargin, rightMargin);
    
#ifdef __IPHONE_13_0
        if (@available(iOS 13.0, *)) {
        }else {
            self.tableView.scrollIndicatorInsets = UIEdgeInsetsMake(navBarHeight, leftMargin, bottomMargin, rightMargin);
        }
#else
        self.tableView.scrollIndicatorInsets = UIEdgeInsetsMake(navBarHeight, leftMargin, bottomMargin, rightMargin);
#endif
        self.tableView.frame = self.view.bounds;
        if (self.manager.configuration.albumListTableView) {
            self.manager.configuration.albumListTableView(self.tableView);
        }
        
    self.navigationController.navigationBar.translucent = self.manager.configuration.navBarTranslucent;
    if (self.manager.configuration.navigationBar) {
        self.manager.configuration.navigationBar(self.navigationController.navigationBar, self);
    }
}
- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self changeStatusBarStyle];
    if (self.manager.viewWillAppear) {
        self.manager.viewWillAppear(self);
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
- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if (!self.albumModelArray.count) {
        PHAuthorizationStatus status = [HXPhotoTools authorizationStatus];
        if (status == PHAuthorizationStatusAuthorized) {
            [self getAlbumModelList:NO];
        }
#ifdef __IPHONE_14_0
        else if (@available(iOS 14, *)) {
            if (status == PHAuthorizationStatusLimited) {
                [self getAlbumModelList:NO];
            }
        }
#endif
    }
    if (self.manager.viewDidAppear) {
        self.manager.viewDidAppear(self);
    }
}
- (void)setupUI {
    self.title = [NSBundle hx_localizedStringForKey:@"相册"];
    [self changeColor];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:[NSBundle hx_localizedStringForKey:@"取消"] style:UIBarButtonItemStyleDone target:self action:@selector(cancelClick)];
    if (self.manager.configuration.navigationBar) {
        self.manager.configuration.navigationBar(self.navigationController.navigationBar, self);
    }
}
- (void)changeColor {
    UIColor *backgroudColor;
    UIColor *themeColor;
    UIColor *navBarBackgroudColor;
    UIColor *navigationTitleColor;
    if ([HXPhotoCommon photoCommon].isDark) {
        backgroudColor = [UIColor colorWithRed:0.075 green:0.075 blue:0.075 alpha:1];
        themeColor = [UIColor whiteColor];
        navBarBackgroudColor = [UIColor blackColor];
        navigationTitleColor = [UIColor whiteColor];
    }else {
        backgroudColor = self.manager.configuration.albumListViewBgColor;
        themeColor = self.manager.configuration.themeColor;
        navBarBackgroudColor = self.manager.configuration.navBarBackgroudColor;
        navigationTitleColor = self.manager.configuration.navigationTitleColor;
    }
    self.view.backgroundColor = backgroudColor;
    self.tableView.backgroundColor = backgroudColor;
    [self.navigationController.navigationBar setTintColor:themeColor];
    self.navigationController.navigationBar.barTintColor = navBarBackgroudColor;
    self.navigationController.navigationBar.barStyle = self.manager.configuration.navBarStyle;
    
    if (self.manager.configuration.navBarBackgroundImage) {
        [self.navigationController.navigationBar setBackgroundImage:self.manager.configuration.navBarBackgroundImage forBarMetrics:UIBarMetricsDefault];
    }
//    if (navBarBackgroudColor) {
//        [self.navigationController.navigationBar setBackgroundColor:navBarBackgroudColor];
//        [self.navigationController.navigationBar setBackgroundImage:nil forBarMetrics:UIBarMetricsDefault];
//    }
    
    if (self.manager.configuration.navigationTitleSynchColor) {
        self.navigationController.navigationBar.titleTextAttributes = @{NSForegroundColorAttributeName : themeColor};
    }else {
        if (navigationTitleColor) {
            self.navigationController.navigationBar.titleTextAttributes = @{NSForegroundColorAttributeName : navigationTitleColor};
        }else {
            self.navigationController.navigationBar.titleTextAttributes = @{NSForegroundColorAttributeName : [UIColor blackColor]};
        }
    }
}
- (void)configTableView {
    [self.view addSubview:self.tableView];
        
    [self changeSubviewFrame];
}
- (void)cancelClick {
    [self.manager cancelBeforeSelectedList]; 
    if ([self.delegate respondsToSelector:@selector(albumListViewControllerDidCancel:)]) {
        [self.delegate albumListViewControllerDidCancel:self];
    }
    if (self.cancelBlock) {
        self.cancelBlock(self, self.manager);
    }
    self.manager.selectPhotoing = NO;
    
    BOOL selectPhotoCancelDismissAnimated = self.manager.selectPhotoCancelDismissAnimated;
    [self dismissViewControllerAnimated:selectPhotoCancelDismissAnimated completion:^{
        if ([self.delegate respondsToSelector:@selector(albumListViewControllerCancelDismissCompletion:)]) {
            [self.delegate albumListViewControllerCancelDismissCompletion:self];
        }
    }];
}
#pragma mark - < HXPhotoViewControllerDelegate >
- (void)photoViewController:(HXPhotoViewController *)photoViewController didDoneAllList:(NSArray<HXPhotoModel *> *)allList photos:(NSArray<HXPhotoModel *> *)photoList videos:(NSArray<HXPhotoModel *> *)videoList original:(BOOL)original {
    if ([self.delegate respondsToSelector:@selector(albumListViewController:didDoneAllList:photos:videos:original:)]) {
        [self.delegate albumListViewController:self didDoneAllList:allList photos:photoList videos:videoList original:original];
    }
    if (self.doneBlock) {
        self.doneBlock(allList, photoList, videoList, original, self, self.manager);
    }
}
- (void)photoViewControllerDidCancel:(HXPhotoViewController *)photoViewController {
    [self cancelClick];
}
- (void)photoViewControllerDidChangeSelect:(HXPhotoModel *)model selected:(BOOL)selected {
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
- (void)pushPhotoListViewControllerWithAlbumModel:(HXAlbumModel *)albumModel animated:(BOOL) animated {
    if (self.navigationController.topViewController != self) {
        [self.navigationController popToViewController:self animated:NO];
    }
    HXPhotoViewController *vc = [[HXPhotoViewController alloc] init];
    vc.manager = self.manager;
    vc.title = albumModel.albumName;
    vc.albumModel = albumModel;
    vc.delegate = self;
    [self.navigationController pushViewController:vc animated:animated];
}
- (void)getAlbumModelList:(BOOL)isFirst {
    HXWeakSelf
    if (isFirst) {
        if (self.hx_customNavigationController.cameraRollAlbumModel) {
            [self.view hx_handleLoading];
            [self pushPhotoListViewControllerWithAlbumModel:self.hx_customNavigationController.cameraRollAlbumModel animated:NO];
        }else {
            self.hx_customNavigationController.requestCameraRollCompletion = ^{
                [weakSelf.view hx_handleLoading];
                [weakSelf pushPhotoListViewControllerWithAlbumModel:weakSelf.hx_customNavigationController.cameraRollAlbumModel animated:NO];
            };
        }
    }else {
        [self configTableView];
        [self.view hx_showLoadingHUDText:nil];
        if (self.hx_customNavigationController.albums) {
            self.albumModelArray = self.hx_customNavigationController.albums;
            [self.tableView reloadData];
            [self.view hx_handleLoading:YES];
        }else {
            self.hx_customNavigationController.requestAllAlbumCompletion = ^{
                weakSelf.albumModelArray = weakSelf.hx_customNavigationController.albums;
                [weakSelf.tableView reloadData];
                [weakSelf.view hx_handleLoading:YES];
            };
        }
    }
}

#pragma mark - < UITableViewDataSource >
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.albumModelArray.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    HXAlbumListSingleViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"tableViewCellId"];
    cell.bgColor = self.manager.configuration.albumListViewCellBgColor;
    cell.textColor = self.manager.configuration.albumListViewCellTextColor;
    cell.selectedBgColor = self.manager.configuration.albumListViewCellSelectBgColor;
    cell.lineViewColor = self.manager.configuration.albumListViewCellLineColor;
    cell.model = self.albumModelArray[indexPath.row];
    
    HXWeakSelf
    cell.getResultCompleteBlock = ^(NSInteger count, HXAlbumListSingleViewCell *myCell) {
        if (count <= 0) {
            if ([weakSelf.albumModelArray containsObject:myCell.model]) {
                NSIndexPath *myIndexPath = [weakSelf.tableView indexPathForCell:myCell];
                if (myIndexPath) {
                    [weakSelf.albumModelArray removeObject:myCell.model];
                    [weakSelf.tableView deleteRowsAtIndexPaths:@[myIndexPath] withRowAnimation:UITableViewRowAnimationFade];
                }
            }
        }
    };
    return cell;
}

#pragma mark - < UITableViewDelegate >
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if (self.navigationController.topViewController != self) {
        return;
    }
    [self.hx_customNavigationController clearAssetCache];
    HXAlbumModel *model = self.albumModelArray[indexPath.row];
    [self pushPhotoListViewControllerWithAlbumModel:model animated:YES]; 
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 100;
}

- (void)tableView:(UITableView *)tableView didEndDisplayingCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    [(HXAlbumListSingleViewCell *)cell cancelRequest];
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
        _tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        _tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        [_tableView registerClass:[HXAlbumListSingleViewCell class] forCellReuseIdentifier:@"tableViewCellId"];
#ifdef __IPHONE_11_0
        if (@available(iOS 11.0, *)) {
//            if ([self hx_navigationBarWhetherSetupBackground]) {
//                self.navigationController.navigationBar.translucent = NO;
//            }else {
                _tableView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
//            }
#else
            if ((NO)) {
#endif
            } else {
//                if ([self hx_navigationBarWhetherSetupBackground]) {
//                    self.navigationController.navigationBar.translucent = NO;
//                }else {
                    self.automaticallyAdjustsScrollViewInsets = NO;
//                }
            }
    }
    return _tableView;
}
- (UILabel *)authorizationLb {
    if (!_authorizationLb) {
        _authorizationLb = [[UILabel alloc] initWithFrame:CGRectMake(0, 200, self.view.frame.size.width, 100)];
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
- (void)dealloc {
    self.manager.selectPhotoing = NO;
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"CustomCameraViewControllerDidDoneNotification" object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidChangeStatusBarOrientationNotification object:nil];
}
- (void)goSetup {
    NSURL *url = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
    if (@available(iOS 10.0, *)) {
        [[UIApplication sharedApplication] openURL:url options:@{} completionHandler:nil];
    }else {
        [[UIApplication sharedApplication] openURL:url];
    }
}
@end
     
@interface HXAlbumListSingleViewCell ()
@property (strong, nonatomic) UIImageView *coverView1;
@property (strong, nonatomic) UILabel *albumNameLb;
@property (strong, nonatomic) UILabel *photoNumberLb;
@property (assign, nonatomic) PHImageRequestID requestId1;
@property (assign, nonatomic) PHImageRequestID requestId2;
@property (assign, nonatomic) PHImageRequestID requestId3;
@property (strong, nonatomic) UIView *lineView;
@property (strong, nonatomic) UIView *selectBgView;
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
    [self.contentView addSubview:self.coverView1];
    [self.contentView addSubview:self.albumNameLb];
    [self.contentView addSubview:self.photoNumberLb];
    [self.contentView addSubview:self.lineView];
}
- (void)cancelRequest {
    if (self.requestId1) {
        [[PHImageManager defaultManager] cancelImageRequest:self.requestId1];
        self.requestId1 = -1;
    }
}
- (void)setModel:(HXAlbumModel *)model {
    _model = model;
    [self changeColor];
    self.albumNameLb.text = self.model.albumName;
    if (!model.assetResult && model.localIdentifier) {
        HXWeakSelf
        [model getResultWithCompletion:^(HXAlbumModel *albumModel) {
            if (albumModel == weakSelf.model) {
                [weakSelf setAlbumImage];
            }
        }];
    }else {
        [self setAlbumImage];
    }
    if (!model.assetResult || !model.count) {
        self.coverView1.image = model.tempImage ?: [UIImage hx_imageNamed:@"hx_yundian_tupian"];
    }
}
- (void)setAlbumImage {
    NSInteger photoCount = self.model.count;
    HXWeakSelf
    PHAsset *asset = self.model.assetResult.lastObject;
    if (asset) {
        self.requestId1 = [HXAssetManager requestThumbnailImageForAsset:asset targetWidth:300 completion:^(UIImage * _Nonnull result, NSDictionary<NSString *,id> * _Nonnull info) {
            if (weakSelf.model.assetResult.lastObject == asset && result) {
                weakSelf.coverView1.image = result;
            }
        }];
    }
    
    self.photoNumberLb.text = [@(photoCount + self.model.cameraCount).stringValue hx_countStrBecomeComma];
    if (self.getResultCompleteBlock) {
        self.getResultCompleteBlock(photoCount + self.model.cameraCount, self);
    }
}
- (void)setHighlighted:(BOOL)highlighted animated:(BOOL)animated {
    [super setHighlighted:highlighted animated:animated];
}
- (void)layoutSubviews {
    [super layoutSubviews];
    self.coverView1.frame = CGRectMake(10, 5, self.hx_h - 10, self.hx_h - 10);
    CGFloat albumNameLbX = CGRectGetMaxX(self.coverView1.frame) + 12;
    CGFloat albumNameLbY = self.hx_h / 2  - 16;
    self.albumNameLb.frame = CGRectMake(albumNameLbX, albumNameLbY, self.hx_w - albumNameLbX - 40, 14);
    self.photoNumberLb.frame = CGRectMake(albumNameLbX, self.hx_h / 2 + 4, self.hx_w, 13);
    self.lineView.frame = CGRectMake(10, self.hx_h - 0.5f, self.hx_w - 22, 0.5f);
    
    self.selectBgView.frame = self.bounds;
}
- (void)dealloc {
//    [self cancelRequest];
}
#pragma mark - < cell懒加载 >
- (UIView *)lineView {
    if (!_lineView) {
        _lineView = [[UIView alloc] init];
    }
    return _lineView;
}
- (UIImageView *)coverView1 {
    if (!_coverView1) {
        _coverView1 = [[UIImageView alloc] init];
        _coverView1.contentMode = UIViewContentModeScaleAspectFill;
        _coverView1.clipsToBounds = YES;
        _coverView1.layer.borderColor = [UIColor whiteColor].CGColor;
        _coverView1.layer.borderWidth = 0.5f;
    }
    return _coverView1;
}
- (UILabel *)albumNameLb {
    if (!_albumNameLb) {
        _albumNameLb = [[UILabel alloc] init];
        _albumNameLb.font = [UIFont hx_mediumSFUITextOfSize:13];
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
- (UIView *)selectBgView {
    if (!_selectBgView) {
        _selectBgView = [[UIView alloc] init];
        _selectBgView.backgroundColor = [UIColor colorWithRed:0.125 green:0.125 blue:0.125 alpha:1];
    }
    return _selectBgView;
}
- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
    [super traitCollectionDidChange:previousTraitCollection];
#ifdef __IPHONE_13_0
    if (@available(iOS 13.0, *)) {
        if ([self.traitCollection hasDifferentColorAppearanceComparedToTraitCollection:previousTraitCollection]) {
            [self changeColor];
        }
    }
#endif
}
- (void)changeAlbumNameTextColor {
    if ([HXPhotoCommon photoCommon].isDark) {
        self.albumNameLb.textColor = [UIColor whiteColor];
    }else {
        self.albumNameLb.textColor = self.textColor;
    }
}
- (void)changeColor {
    self.backgroundColor = [HXPhotoCommon photoCommon].isDark ? [UIColor colorWithRed:0.075 green:0.075 blue:0.075 alpha:1] : self.bgColor;
    if (self.selectedBgColor) {
        self.selectBgView.backgroundColor = self.selectedBgColor;
        self.selectedBackgroundView = self.selectBgView;
    }else {
        self.selectedBackgroundView = [HXPhotoCommon photoCommon].isDark ? self.selectBgView : nil;
    }
    self.lineView.backgroundColor = [HXPhotoCommon photoCommon].isDark ? [[UIColor colorWithRed:0.1 green:0.1 blue:0.1 alpha:1] colorWithAlphaComponent:1] : self.lineViewColor;
    [self changeAlbumNameTextColor];
}
    
@end
