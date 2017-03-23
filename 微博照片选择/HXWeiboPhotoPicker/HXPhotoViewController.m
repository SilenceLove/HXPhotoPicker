//
//  HXPhotoViewController.m
//  微博照片选择
//
//  Created by 洪欣 on 17/2/8.
//  Copyright © 2017年 洪欣. All rights reserved.
//

#import "HXPhotoViewController.h"
#import "HXPhotoViewCell.h"
#import "HXAlbumListView.h"
#import "HXAlbumTitleButton.h"
#import "HXPhotoPreviewViewController.h"
#import "HXVideoPreviewViewController.h"
#import "HXCameraViewController.h"
#import "UIView+HXExtension.h"

static NSString *PhotoViewCellId = @"PhotoViewCellId";
@interface HXPhotoViewController ()<UICollectionViewDataSource,UICollectionViewDelegate,UIViewControllerPreviewingDelegate,HXAlbumListViewDelegate,HXPhotoPreviewViewControllerDelegate,HXPhotoBottomViewDelegate,HXVideoPreviewViewControllerDelegate,HXCameraViewControllerDelegate,HXPhotoViewCellDelegate,UIAlertViewDelegate>
{
    CGRect _originalFrame;
}

@property (strong, nonatomic) NSMutableArray *photos;
@property (copy, nonatomic) NSArray *albums;
@property (weak, nonatomic) HXAlbumListView *albumView;
@property (weak, nonatomic) HXAlbumTitleButton *titleBtn;
@property (strong, nonatomic) UIButton *rightBtn;
@property (strong, nonatomic) UIView *albumsBgView;
@property (weak, nonatomic) HXPhotoBottomView *bottomView;
@property (strong, nonatomic) NSMutableArray *videos;
@property (strong, nonatomic) NSMutableArray *objs;
@property (strong, nonatomic) UIActivityIndicatorView *indica;
@property (assign, nonatomic) BOOL isSelectedChange;
@property (strong, nonatomic) HXAlbumModel *albumModel;
@property (assign, nonatomic) NSInteger currentSelectCount;
@property (strong, nonatomic) NSIndexPath *currentIndexPath;
@property (strong, nonatomic) UIImageView *previewImg;
@property (strong, nonatomic) NSTimer *timer;
@property (strong, nonatomic) UILabel *authorizationLb;
@end

@implementation HXPhotoViewController

- (UILabel *)authorizationLb
{
    if (!_authorizationLb) {
        _authorizationLb = [[UILabel alloc] initWithFrame:CGRectMake(0, 200, self.view.frame.size.width, 100)];
        _authorizationLb.text = @"无法访问照片\n请点击这里前往设置中允许访问照片";
        _authorizationLb.textAlignment = NSTextAlignmentCenter;
        _authorizationLb.numberOfLines = 0;
        _authorizationLb.textColor = [UIColor blackColor];
        _authorizationLb.font = [UIFont systemFontOfSize:15];
        _authorizationLb.userInteractionEnabled = YES;
        [_authorizationLb addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(goSetup)]];
    }
    return _authorizationLb;
}

- (void)goSetup
{
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setup];
    [self getObjs];
    
    // 获取当前应用对照片的访问授权状态
    if ([PHPhotoLibrary authorizationStatus] != PHAuthorizationStatusAuthorized) {
        [self.view addSubview:self.authorizationLb];
        self.timer = [NSTimer scheduledTimerWithTimeInterval:0.2 target:self selector:@selector(observeAuthrizationStatusChange:) userInfo:nil repeats:YES];
    }else{
        [self goCameraVC];
    }
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (void)observeAuthrizationStatusChange:(NSTimer *)timer
{
    if ([PHPhotoLibrary authorizationStatus] == PHAuthorizationStatusAuthorized) {
        [timer invalidate];
        self.timer = nil;
        [self.authorizationLb removeFromSuperview];
        [self goCameraVC];
        [self getObjs];
    }
}

- (void)goCameraVC
{
    if (self.manager.goCamera) {
        self.manager.goCamera = NO;
        if (!self.manager.openCamera) {
            return;
        }
        if(![UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
            [self.view showImageHUDText:@"此设备不支持相机!"];
            return;
        }
        AVAuthorizationStatus authStatus = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
        if (authStatus == AVAuthorizationStatusRestricted || authStatus == AVAuthorizationStatusDenied) {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"无法使用相机" message:@"请在设置-隐私-相机中允许访问相机" delegate:self cancelButtonTitle:@"取消" otherButtonTitles:@"设置", nil];
            [alert show];
            return;
        }
        HXCameraViewController *vc = [[HXCameraViewController alloc] init];
        vc.delegate = self;
        if (self.manager.type == HXPhotoManagerSelectedTypePhotoAndVideo) {
            vc.type = HXCameraTypePhotoAndVideo;
        }else if (self.manager.type == HXPhotoManagerSelectedTypePhoto) {
            vc.type = HXCameraTypePhoto;
        }else if (self.manager.type == HXPhotoManagerSelectedTypeVideo) {
            vc.type = HXCameraTypeVideo;
        }
        [self presentViewController:vc animated:YES completion:nil];
    }
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 1) {
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]];
    }
}

/**
 获取所有相册 图片
 */
- (void)getObjs
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        __weak typeof(self) weakSelf = self;
        BOOL isShow = self.manager.selectedList.count;
        [self.manager FetchAllAlbum:^(NSArray *albums) {
            weakSelf.albums = albums;
            HXAlbumModel *model = weakSelf.albums.firstObject;
            weakSelf.currentSelectCount = model.selectedCount;
            weakSelf.albumModel = model;
            [weakSelf.manager FetchAllPhotoForPHFetchResult:model.result Index:model.index FetchResult:^(NSArray *photos, NSArray *videos, NSArray *Objs) {
                weakSelf.photos = [NSMutableArray arrayWithArray:photos];
                weakSelf.videos = [NSMutableArray arrayWithArray:videos];
                weakSelf.objs = [NSMutableArray arrayWithArray:Objs];
                dispatch_async(dispatch_get_main_queue(), ^{
                    weakSelf.albumView.list = albums;
                    if (model.albumName.length == 0) {
                        model.albumName = @"相机胶卷";
                    }
                    [weakSelf.titleBtn setTitle:model.albumName forState:UIControlStateNormal];
                    weakSelf.title = model.albumName;
                    CATransition *transition = [CATransition animation];
                    transition.type = kCATransitionPush;
                    transition.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
                    transition.fillMode = kCAFillModeForwards;
                    transition.duration = 0.25;
                    transition.subtype = kCATransitionFade;
                    [[weakSelf.collectionView layer] addAnimation:transition forKey:@""];
                    [weakSelf.collectionView reloadData];
                });
            }];
        } IsShowSelectTag:isShow];
    });
}

/**
 展开/收起 相册列表
 
 @param button 按钮
 */
- (void)pushAlbumList:(UIButton *)button
{
    button.selected = !button.selected;
    if (button.selected) {
        if (self.isSelectedChange) {
            self.isSelectedChange = NO;
            if (self.currentSelectCount != self.albumModel.selectedCount) {
                __weak typeof(self) weakSelf = self;
                [self.manager FetchAllAlbum:^(NSArray *albums) {
                    weakSelf.albumView.list = albums;
                    weakSelf.albums = albums;
                } IsShowSelectTag:YES];
                self.currentSelectCount = self.albumModel.selectedCount;
            }
        }
        self.albumsBgView.hidden = NO;
        [UIView animateWithDuration:0.25 animations:^{
            self.albumView.frame = CGRectMake(0, 64, self.view.frame.size.width, 340);
            self.albumsBgView.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.6];
            button.imageView.transform = CGAffineTransformMakeRotation(M_PI);
        }];
    }else {
        [UIView animateWithDuration:0.25 animations:^{
            self.albumView.frame = CGRectMake(0, 64-340, self.view.frame.size.width, 340);
            self.albumsBgView.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0];
            button.imageView.transform = CGAffineTransformMakeRotation(M_PI * 2);
        } completion:^(BOOL finished) {
            self.albumsBgView.hidden = YES;
        }];
    }
}

- (void)setup
{
    if (self.manager.type == HXPhotoManagerSelectedTypePhoto) {
        self.manager.maxNum = self.manager.photoMaxNum;
        if (self.manager.endCameraVideos.count > 0) {
            [self.manager.endCameraList removeObjectsInArray:self.manager.endCameraVideos];
            [self.manager.endCameraVideos removeAllObjects];
        }
    }else if (self.manager.type == HXPhotoManagerSelectedTypeVideo) {
        self.manager.maxNum = self.manager.videoMaxNum;
        if (self.manager.endCameraPhotos.count > 0) {
            [self.manager.endCameraList removeObjectsInArray:self.manager.endCameraPhotos];
            [self.manager.endCameraPhotos removeAllObjects];
        }
    }else {
        // 防错
        if (self.manager.videoMaxNum + self.manager.photoMaxNum != self.manager.maxNum) {
            self.manager.maxNum = self.manager.videoMaxNum + self.manager.photoMaxNum;
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
    
    self.view.backgroundColor = [UIColor whiteColor];
    self.automaticallyAdjustsScrollViewInsets = NO;
    self.navigationController.navigationBar.tintColor = [UIColor blackColor];
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"取消" style:UIBarButtonItemStylePlain target:self action:@selector(cancelClick)];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:self.rightBtn];
    if (self.manager.selectedList.count > 0) {
        self.navigationItem.rightBarButtonItem.enabled = YES;
        [self.rightBtn setTitle:[NSString stringWithFormat:@"下一步(%ld)",self.manager.selectedList.count] forState:UIControlStateNormal];
        [self.rightBtn setBackgroundColor:[UIColor colorWithRed:253/255.0 green:142/255.0 blue:36/255.0 alpha:1]];
        self.rightBtn.layer.borderWidth = 0;
        CGFloat rightBtnH = self.rightBtn.frame.size.height;
        CGFloat rightBtnW = [HXPhotoTools getTextWidth:self.rightBtn.currentTitle withHeight:rightBtnH fontSize:14];
        self.rightBtn.frame = CGRectMake(0, 0, rightBtnW + 20, rightBtnH);
    }else {
        self.navigationItem.rightBarButtonItem.enabled = NO;
        [self.rightBtn setTitle:@"下一步" forState:UIControlStateNormal];
        [self.rightBtn setBackgroundColor:[UIColor whiteColor]];
        self.rightBtn.frame = CGRectMake(0, 0, 60, 25);
        self.rightBtn.layer.borderWidth = 0.5;
    }
    
    HXAlbumTitleButton *titleBtn = [HXAlbumTitleButton buttonWithType:UIButtonTypeCustom];
    [titleBtn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [titleBtn setImage:[UIImage imageNamed:@"headlines_icon_arrow"] forState:UIControlStateNormal];
    titleBtn.frame = CGRectMake(0, 0, 150, 30);
    [titleBtn setTitle:@"相机胶卷" forState:UIControlStateNormal];
    [titleBtn addTarget:self action:@selector(pushAlbumList:) forControlEvents:UIControlEventTouchUpInside];
    self.navigationItem.titleView = titleBtn;
    self.title = @"相机胶卷";
    self.titleBtn = titleBtn;
    
    CGFloat width = self.view.frame.size.width;
    CGFloat heght = self.view.frame.size.height;
    CGFloat spacing = 1;
    CGFloat CVwidth = (width - spacing * self.manager.rowCount - 1 ) / self.manager.rowCount;
    UICollectionViewFlowLayout *flowLayout = [[UICollectionViewFlowLayout alloc] init];
    flowLayout.itemSize = CGSizeMake(CVwidth, CVwidth);
    flowLayout.minimumInteritemSpacing = spacing;
    flowLayout.minimumLineSpacing = spacing;
    
    self.collectionView = [[UICollectionView alloc] initWithFrame:CGRectMake(0, 0, width, heght) collectionViewLayout:flowLayout];
    self.collectionView.contentInset = UIEdgeInsetsMake(spacing + 64, 0, 50 + spacing, 0);
    self.collectionView.scrollIndicatorInsets = self.collectionView.contentInset;
    self.collectionView.dataSource = self;
    self.collectionView.delegate = self;
    self.collectionView.alwaysBounceVertical = YES;
    self.collectionView.backgroundColor = [UIColor whiteColor];
    [self.collectionView registerClass:[HXPhotoViewCell class] forCellWithReuseIdentifier:PhotoViewCellId];
    [self.view addSubview:self.collectionView];
    
    HXPhotoBottomView *bottomView = [[HXPhotoBottomView alloc] initWithFrame:CGRectMake(0, heght - 50, width, 50)];
    bottomView.delegate = self;
    if (self.manager.selectedList.count > 0) {
        bottomView.originalBtn.enabled = self.manager.selectedPhotos.count;
        bottomView.previewBtn.enabled = YES;
    }else {
        bottomView.previewBtn.enabled = NO;
        bottomView.originalBtn.enabled = NO;
    }
    bottomView.originalBtn.selected = self.manager.isOriginal;
    if (self.manager.type == HXPhotoManagerSelectedTypeVideo) {
        bottomView.hidden = YES;
        self.collectionView.contentInset = UIEdgeInsetsMake(spacing + 64, 0,  spacing, 0);
        self.collectionView.scrollIndicatorInsets = self.collectionView.contentInset;
    }
    [self.view addSubview:bottomView];
    self.bottomView = bottomView;
    _originalFrame = bottomView.originalBtn.frame;
    if (self.manager.selectedPhotos.count > 0 && self.manager.isOriginal) {
        CGFloat originalBtnX = self.bottomView.originalBtn.frame.origin.x;
        CGFloat originalBtnY = self.bottomView.originalBtn.frame.origin.y;
        CGFloat originalBtnW = self.bottomView.originalBtn.frame.size.width;
        CGFloat originalBtnH = self.bottomView.originalBtn.frame.size.height;
        CGFloat totalW = [HXPhotoTools getTextWidth:[NSString stringWithFormat:@"(%@)",self.manager.photosTotalBtyes] withHeight:originalBtnH fontSize:14];
        [bottomView.originalBtn setTitle:[NSString stringWithFormat:@"原图(%@)",self.manager.photosTotalBtyes] forState:UIControlStateNormal];
        
        bottomView.originalBtn.frame = CGRectMake(originalBtnX, originalBtnY, originalBtnW+totalW  , originalBtnH);
    }
    
    [self.view addSubview:self.albumsBgView];
    HXAlbumListView *albumView = [[HXAlbumListView alloc] initWithFrame:CGRectMake(0, 64 - 340, width, 340)];
    albumView.delegate = self;
    [self.view addSubview:albumView];
    self.albumView = albumView;
}

/**
 点击取消按钮 清空所有操作
 */
- (void)cancelClick
{
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
    if ([self.delegate respondsToSelector:@selector(photoViewControllerDidCancel)]) {
        [self.delegate photoViewControllerDidCancel];
    }
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return self.objs.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    HXPhotoViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:PhotoViewCellId forIndexPath:indexPath];
    HXPhotoModel *model = self.objs[indexPath.item];
    cell.delegate = self;
    cell.model = model;
    if (!cell.firstRegisterPreview) {
        if (model.type != HXPhotoModelMediaTypeCamera) {
            if ([self respondsToSelector:@selector(traitCollection)]) {
                if ([self.traitCollection respondsToSelector:@selector(forceTouchCapability)]) {
                    if (self.traitCollection.forceTouchCapability == UIForceTouchCapabilityAvailable) {
                        [self registerForPreviewingWithDelegate:self sourceView:cell];
                        cell.firstRegisterPreview = YES;
                    }
                }
            }
        }
    }
    return cell;
}

- (UIViewController *)previewingContext:(id<UIViewControllerPreviewing>)previewingContext viewControllerForLocation:(CGPoint)location
{
    NSIndexPath *index = [self.collectionView indexPathForCell:(UICollectionViewCell *)[previewingContext sourceView]];
    HXPhotoModel *model = self.objs[index.item];
    self.previewImg = [[UIImageView alloc] init];
    self.previewImg.frame = CGRectMake(0, 0, model.endImageSize.width, model.endImageSize.height);
    if (model.previewPhoto) {
        self.previewImg.image = model.previewPhoto;
    }else {
        __weak typeof(self) weakSelf = self;
        [HXPhotoTools FetchPhotoForPHAsset:model.asset Size:CGSizeMake(model.endImageSize.width * 2, model.endImageSize.height * 2) deliveryMode:0 completion:^(UIImage *image, NSDictionary *info) {
            weakSelf.previewImg.image = image;
        } error:^(NSDictionary *info) {
            weakSelf.previewImg.image = model.thumbPhoto;
        }];
    }
    CGRect rect = CGRectMake(0, 0, previewingContext.sourceView.frame.size.width, previewingContext.sourceView.frame.size.height);
    previewingContext.sourceRect = rect;
    if ((model.type == HXPhotoModelMediaTypePhoto || model.type == HXPhotoModelMediaTypePhotoGif) || (model.type == HXPhotoModelMediaTypeCameraPhoto || model.type == HXPhotoModelMediaTypeLivePhoto)) {
        HXPhotoPreviewViewController *showVC = [[HXPhotoPreviewViewController alloc] init];
        showVC.preferredContentSize = model.endImageSize;
        showVC.modelList = self.photos;
        NSInteger index = 0;
        if (model.type != HXPhotoModelMediaTypeCameraPhoto) {
            if (self.albumModel.index == 0) {
                if (self.manager.cameraPhotos.count > 0) {
                    index = model.photoIndex + self.manager.cameraPhotos.count;
                }else {
                    index = model.photoIndex;
                }
            }else {
                index = model.photoIndex;
            }
        }else {
            index = model.photoIndex;
        }
        
        showVC.index = index;
        showVC.delegate = self;
        showVC.manager = self.manager;
        showVC.collectionView.hidden = YES;
        self.navigationController.delegate = showVC;
        [showVC.view addSubview:self.previewImg];
        return showVC;
    }else if (model.type == HXPhotoModelMediaTypeVideo || model.type == HXPhotoModelMediaTypeCameraVideo){
        HXVideoPreviewViewController *showVC = [[HXVideoPreviewViewController alloc] init];
        showVC.preferredContentSize = model.endImageSize;
        showVC.manager = self.manager;
        showVC.delegate = self;
        showVC.model = model;
        showVC.isTouch = YES;
        if (model.type == HXPhotoModelMediaTypeCameraVideo) {
            showVC.isCamera = YES;
        }
        self.navigationController.delegate = showVC;
        [showVC.view addSubview:self.previewImg];
        return showVC;
    }else {
        return nil;
    }
}

- (void)previewingContext:(id<UIViewControllerPreviewing>)previewingContext commitViewController:(UIViewController *)viewControllerToCommit
{
    NSIndexPath *index = [self.collectionView indexPathForCell:(UICollectionViewCell *)[previewingContext sourceView]];
    self.currentIndexPath = index;
    [self.previewImg removeFromSuperview];
    HXPhotoModel *model = self.objs[index.item];
    if (model.type == HXPhotoModelMediaTypeVideo) {
        HXVideoPreviewViewController *vc = (HXVideoPreviewViewController *)viewControllerToCommit;
        [vc.playVideo play];
        vc.playBtn.selected = YES;
        [vc selectClick];
    }else if (model.type == HXPhotoModelMediaTypePhoto || (model.type == HXPhotoModelMediaTypePhotoGif || model.type == HXPhotoModelMediaTypeLivePhoto)) {
        HXPhotoPreviewViewController *vc = (HXPhotoPreviewViewController *)viewControllerToCommit;
        [vc selectClick];
    }
    [self showViewController:viewControllerToCommit sender:self];
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    self.currentIndexPath = indexPath;
    HXPhotoModel *model = self.objs[indexPath.item];
    if (model.type == HXPhotoModelMediaTypePhoto || (model.type == HXPhotoModelMediaTypePhotoGif || model.type == HXPhotoModelMediaTypeLivePhoto)) {
        HXPhotoPreviewViewController *vc = [[HXPhotoPreviewViewController alloc] init];
        vc.modelList = self.photos;
        NSInteger index = 0;
        if (self.albumModel.index == 0) {
            if (self.manager.cameraPhotos.count > 0) {
                index = model.photoIndex + self.manager.cameraPhotos.count;
            }else {
                index = model.photoIndex;
            }
        }else {
            index = model.photoIndex;
        }
        vc.index = index;
        vc.delegate = self;
        vc.manager = self.manager;
        self.navigationController.delegate = vc;
        [self.navigationController pushViewController:vc animated:YES];
    }else if (model.type == HXPhotoModelMediaTypeVideo){
        HXVideoPreviewViewController *vc = [[HXVideoPreviewViewController alloc] init];
        vc.manager = self.manager;
        vc.delegate = self;
        vc.model = model;
        self.navigationController.delegate = vc;
        [self.navigationController pushViewController:vc animated:YES];
    }else if (model.type == HXPhotoModelMediaTypeCameraPhoto){
        HXPhotoPreviewViewController *vc = [[HXPhotoPreviewViewController alloc] init];
        vc.modelList = self.photos;
        vc.index = model.photoIndex;
        vc.delegate = self;
        vc.manager = self.manager;
        self.navigationController.delegate = vc;
        [self.navigationController pushViewController:vc animated:YES];
    }else if (model.type == HXPhotoModelMediaTypeCameraVideo) {
        HXVideoPreviewViewController *vc = [[HXVideoPreviewViewController alloc] init];
        vc.manager = self.manager;
        vc.delegate = self;
        vc.model = model;
        vc.isCamera = YES;
        self.navigationController.delegate = vc;
        [self.navigationController pushViewController:vc animated:YES];
    }else if (model.type == HXPhotoModelMediaTypeCamera) {
        if(![UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
            [self.view showImageHUDText:@"此设备不支持相机!"];
            return;
        }
        AVAuthorizationStatus authStatus = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
        if (authStatus == AVAuthorizationStatusRestricted || authStatus == AVAuthorizationStatusDenied) {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"无法使用相机" message:@"请在设置-隐私-相机中允许访问相机" delegate:self cancelButtonTitle:@"取消" otherButtonTitles:@"设置", nil];
            [alert show];
            return;
        }
        HXCameraViewController *vc = [[HXCameraViewController alloc] init];
        vc.delegate = self;
        if (self.manager.type == HXPhotoManagerSelectedTypePhotoAndVideo) {
            if (self.photos.count > 0 && self.videos.count > 0) {
                vc.type = HXCameraTypePhotoAndVideo;
            }else if (self.videos.count > 0) {
                vc.type = HXCameraTypeVideo;
            }else {
                vc.type = HXCameraTypePhotoAndVideo;
            }
        }else if (self.manager.type == HXPhotoManagerSelectedTypePhoto) {
            vc.type = HXCameraTypePhoto;
        }else if (self.manager.type == HXPhotoManagerSelectedTypeVideo) {
            vc.type = HXCameraTypeVideo;
        }
        [self presentViewController:vc animated:YES completion:nil];
    }
}

/**
 通过相机拍照的图片或视频
 
 @param model 图片/视频 模型
 */
- (void)cameraDidNextClick:(HXPhotoModel *)model
{
    if (self.albumModel.index != 0) {
        [self didTableViewCellClick:self.albums.firstObject animate:NO];
    }
    // 判断类型
    if (model.type == HXPhotoModelMediaTypeCameraPhoto) {
        [self.manager.cameraPhotos addObject:model];
        [self.photos insertObject:model atIndex:0];
        // 当选择图片个数没有达到最大个数时就添加到选中数组中
        if (self.manager.selectedPhotos.count != self.manager.photoMaxNum) {
            if (!self.manager.selectTogether) {
                if (self.manager.selectedList.count > 0) {
                    HXPhotoModel *phMd = self.manager.selectedList.firstObject;
                    if ((phMd.type == HXPhotoModelMediaTypePhoto || phMd.type == HXPhotoModelMediaTypeLivePhoto) || (phMd.type == HXPhotoModelMediaTypePhotoGif || phMd.type == HXPhotoModelMediaTypeCameraPhoto)) {
                        [self.manager.selectedCameraPhotos insertObject:model atIndex:0];
                        [self.manager.selectedPhotos addObject:model];
                        [self.manager.selectedList addObject:model];
                        [self.manager.selectedCameraList addObject:model];
                        self.isSelectedChange = YES;
                        model.selected = YES;
                        self.albumModel.selectedCount++;
                    }
                }else {
                    [self.manager.selectedCameraPhotos insertObject:model atIndex:0];
                    [self.manager.selectedPhotos addObject:model];
                    [self.manager.selectedList addObject:model];
                    [self.manager.selectedCameraList addObject:model];
                    self.isSelectedChange = YES;
                    model.selected = YES;
                    self.albumModel.selectedCount++;
                }
            }else {
                [self.manager.selectedCameraPhotos insertObject:model atIndex:0];
                [self.manager.selectedPhotos addObject:model];
                [self.manager.selectedList addObject:model];
                [self.manager.selectedCameraList addObject:model];
                self.isSelectedChange = YES;
                model.selected = YES;
                self.albumModel.selectedCount++;
            }
        }
    }else if (model.type == HXPhotoModelMediaTypeCameraVideo) {
        [self.manager.cameraVideos addObject:model];
        [self.videos insertObject:model atIndex:0];
        // 当选中视频个数没有达到最大个数时就添加到选中数组中
        if (self.manager.selectedVideos.count != self.manager.videoMaxNum) {
            if (!self.manager.selectTogether) {
                if (self.manager.selectedList.count > 0) {
                    HXPhotoModel *phMd = self.manager.selectedList.firstObject;
                    if (phMd.type == HXPhotoModelMediaTypeVideo || phMd.type == HXPhotoModelMediaTypeCameraVideo) {
                        [self.manager.selectedCameraVideos insertObject:model atIndex:0];
                        [self.manager.selectedVideos addObject:model];
                        [self.manager.selectedList addObject:model];
                        [self.manager.selectedCameraList addObject:model];
                        self.isSelectedChange = YES;
                        model.selected = YES;
                        self.albumModel.selectedCount++;
                    }
                }else {
                    
                    [self.manager.selectedCameraVideos insertObject:model atIndex:0];
                    [self.manager.selectedVideos addObject:model];
                    [self.manager.selectedList addObject:model];
                    [self.manager.selectedCameraList addObject:model];
                    self.isSelectedChange = YES;
                    model.selected = YES;
                    self.albumModel.selectedCount++;
                }
            }else {
                [self.manager.selectedCameraVideos insertObject:model atIndex:0];
                [self.manager.selectedVideos addObject:model];
                [self.manager.selectedList addObject:model];
                [self.manager.selectedCameraList addObject:model];
                self.isSelectedChange = YES;
                model.selected = YES;
                self.albumModel.selectedCount++;
            }
        }
    }
    [self.manager.cameraList addObject:model];
    NSInteger cameraIndex = self.manager.openCamera ? 1 : 0;
    [self.objs insertObject:model atIndex:cameraIndex];
    
    int index = 0;
    for (NSInteger i = self.manager.cameraPhotos.count - 1; i >= 0; i--) {
        HXPhotoModel *photoMD = self.manager.cameraPhotos[i];
        photoMD.photoIndex = index;
        photoMD.albumListIndex = index + cameraIndex;
        index++;
    }
    index = 0;
    for (NSInteger i = self.manager.cameraVideos.count - 1; i >= 0; i--) {
        HXPhotoModel *photoMD = self.manager.cameraVideos[i];
        photoMD.videoIndex = index;
        index++;
    }
    index = 0;
    for (NSInteger i = self.manager.cameraList.count - 1; i>= 0; i--) {
        HXPhotoModel *photoMD = self.manager.cameraList[i];
        photoMD.albumListIndex = index + cameraIndex;
        index++;
    }
    [self.collectionView reloadData];
    [self changeButtonClick:model];
}

/**
 点击相册列表的代理
 
 @param model 点击的相册模型
 @param anim 是否需要展开动画
 */
- (void)didTableViewCellClick:(HXAlbumModel *)model animate:(BOOL)anim
{
    // 当前相册选中的个数
    self.currentSelectCount = model.selectedCount;
    self.albumModel = model;
    if (anim) {
        [self pushAlbumList:self.titleBtn];
    }
    self.title = model.albumName;
    [self.titleBtn setTitle:model.albumName forState:UIControlStateNormal];
    __weak typeof(self) weakSelf = self;
    // 获取指定相册的所有图片
    [self.manager FetchAllPhotoForPHFetchResult:model.result Index:model.index FetchResult:^(NSArray *photos, NSArray *videos, NSArray *Objs) {
        weakSelf.photos = [NSMutableArray arrayWithArray:photos];
        weakSelf.videos = [NSMutableArray arrayWithArray:videos];
        weakSelf.objs = [NSMutableArray arrayWithArray:Objs];
        CATransition *transition = [CATransition animation];
        transition.type = kCATransitionPush;
        transition.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
        transition.fillMode = kCAFillModeForwards;
        transition.duration = 0.25;
        transition.subtype = kCATransitionFade;
        [[weakSelf.collectionView layer] addAnimation:transition forKey:@""];
        [weakSelf.collectionView reloadData];
        [weakSelf.collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:0] atScrollPosition:UICollectionViewScrollPositionTop animated:NO];
    }];
}

/**
 查看图片时 选中或取消选中时的代理
 
 @param model 当前操作的模型
 @param state 状态
 */
- (void)didSelectedClick:(HXPhotoModel *)model AddOrDelete:(BOOL)state
{
    if (state) { // 选中
        self.albumModel.selectedCount++;
    }else { // 取消选中
        self.albumModel.selectedCount--;
    }
    NSInteger index = 0;
    if (self.albumModel.index == 0) {
        if (self.manager.cameraList.count > 0) {
            if (model.type != HXPhotoModelMediaTypeCameraPhoto && model.type != HXPhotoModelMediaTypeCameraVideo) {
                index = model.albumListIndex + self.manager.cameraList.count;
            }else {
                index = model.albumListIndex;
            }
        }else {
            index = model.albumListIndex;
        }
    }else {
        index = model.albumListIndex;
    }

    [self.collectionView reloadItemsAtIndexPaths:@[[NSIndexPath indexPathForItem:index inSection:0]]];
    // 改变 预览、原图 按钮的状态
    [self changeButtonClick:model];
}


/**
 cell选中代理
 */
- (void)cellDidSelectedBtnClick:(HXPhotoViewCell *)cell Model:(HXPhotoModel *)model
{
    if (!cell.selectBtn.selected) { // 弹簧果冻动画效果
        if (self.manager.selectedList.count == self.manager.maxNum) {
            [self.view showImageHUDText:[NSString stringWithFormat:@"最多只能选择%ld个",self.manager.maxNum]];
            // 已经达到最大选择数
            return;
        }
        if (self.manager.type == HXPhotoManagerSelectedTypePhotoAndVideo) {
            if ((model.type == HXPhotoModelMediaTypePhoto || model.type == HXPhotoModelMediaTypePhotoGif) || (model.type == HXPhotoModelMediaTypeCameraPhoto || model.type == HXPhotoModelMediaTypeLivePhoto)) {
                if (self.manager.videoMaxNum > 0) {
                    if (!self.manager.selectTogether) { // 是否支持图片视频同时选择
                        if (self.manager.selectedVideos.count > 0 ) {
                            [self.view showImageHUDText:@"图片不能和视频同时选择"];
                            // 已经选择了视频,不能再选图片
                            return;
                        }
                    }
                }
                if (self.manager.selectedPhotos.count == self.manager.photoMaxNum) {
                    [self.view showImageHUDText:[NSString stringWithFormat:@"最多只能选择%ld张图片",self.manager.photoMaxNum]];
                    // 已经达到图片最大选择数
                    return;
                }
            }else if (model.type == HXPhotoModelMediaTypeVideo || model.type == HXPhotoModelMediaTypeCameraVideo) {
                if (self.manager.photoMaxNum > 0) {
                    if (!self.manager.selectTogether) { // 是否支持图片视频同时选择
                        if (self.manager.selectedPhotos.count > 0 ) {
                            // 已经选择了图片,不能再选视频
                            [self.view showImageHUDText:@"视频不能和图片同时选择"];
                            return;
                        }
                    }
                }
                if (self.manager.selectedVideos.count == self.manager.videoMaxNum) {
                    [self.view showImageHUDText:[NSString stringWithFormat:@"最多只能选择%ld个视频",self.manager.videoMaxNum]];
                    // 已经达到视频最大选择数
                    return;
                }
            }
        }else if (self.manager.type == HXPhotoManagerSelectedTypePhoto) {
            if (self.manager.selectedPhotos.count == self.manager.photoMaxNum) {
                [self.view showImageHUDText:[NSString stringWithFormat:@"最多只能选择%ld张图片",self.manager.photoMaxNum]];
                // 已经达到图片最大选择数
                return;
            }
        }else if (self.manager.type == HXPhotoManagerSelectedTypeVideo) {
            if (self.manager.selectedVideos.count == self.manager.videoMaxNum) {
                [self.view showImageHUDText:[NSString stringWithFormat:@"最多只能选择%ld个视频",self.manager.videoMaxNum]];
                // 已经达到视频最大选择数
                return;
            }
        }
        if (model.type == HXPhotoModelMediaTypeVideo) {
            if (model.asset.duration < 3) {
                [self.view showImageHUDText:@"视频少于3秒,暂不支持"];
                return;
            }
        }
//        if (!model.imageData) {
//            [HXPhotoTools FetchPhotoDataForPHAsset:model.asset completion:^(NSData *imageData, NSDictionary *info) {
//                model.imageData = imageData;
//            }];
//        }
//        if (!model.previewPhoto) {
//            [HXPhotoTools FetchPhotoForPHAsset:model.asset Size:PHImageManagerMaximumSize deliveryMode:PHImageRequestOptionsDeliveryModeHighQualityFormat completion:^(UIImage *image, NSDictionary *info) {
//                model.previewPhoto = image;
//            } error:^(NSDictionary *info) {
//                model.previewPhoto = model.thumbPhoto;
//            }];
//        }
//        // 这里加个延迟  防止可能照片过大导致获取时间过长  可以屏蔽这段代码 按自己的需求来
//        if (!model.imageData || !model.previewPhoto) {
//            [NSThread sleepForTimeInterval:0.25];
//        }
        cell.maskView.hidden = NO;
        CAKeyframeAnimation *anim = [CAKeyframeAnimation animationWithKeyPath:@"transform.scale"];
        anim.duration = 0.25;
        anim.values = @[@(1.2),@(0.8),@(1.1),@(0.9),@(1.0)];
        [cell.selectBtn.layer addAnimation:anim forKey:@""];
    }else {
        cell.maskView.hidden = YES;
    }
    cell.selectBtn.selected = !cell.selectBtn.selected;
    cell.model.selected = cell.selectBtn.selected;
    BOOL selected = cell.selectBtn.selected;
    
    if (selected) { // 选中之后需要做的
        if (model.type == HXPhotoModelMediaTypeLivePhoto) {
            [cell startLivePhoto];
        }
        if (model.type == HXPhotoModelMediaTypePhoto || (model.type == HXPhotoModelMediaTypePhotoGif || model.type == HXPhotoModelMediaTypeLivePhoto)) { // 为图片时
            [self.manager.selectedPhotos addObject:model];
        }else if (model.type == HXPhotoModelMediaTypeVideo) { // 为视频时
            [self.manager.selectedVideos addObject:model];
        }else if (model.type == HXPhotoModelMediaTypeCameraPhoto) {
            // 为相机拍的照片时
            [self.manager.selectedPhotos addObject:model];
            [self.manager.selectedCameraPhotos addObject:model];
            [self.manager.selectedCameraList addObject:model];
        }else if (model.type == HXPhotoModelMediaTypeCameraVideo) {
            // 为相机录的视频时
            [self.manager.selectedVideos addObject:model];
            [self.manager.selectedCameraVideos addObject:model];
            [self.manager.selectedCameraList addObject:model];
        }
        [self.manager.selectedList addObject:model];
        self.albumModel.selectedCount++;
    }else { // 取消选中之后的
        if (model.type == HXPhotoModelMediaTypeLivePhoto) {
            [cell stopLivePhoto];
        }
        int i = 0;
        for (HXPhotoModel *subModel in self.manager.selectedList) {
            if ((model.type == HXPhotoModelMediaTypePhoto || model.type == HXPhotoModelMediaTypePhotoGif) || (model.type == HXPhotoModelMediaTypeVideo || model.type == HXPhotoModelMediaTypeLivePhoto)) {
                if ([subModel.asset.localIdentifier isEqualToString:model.asset.localIdentifier]) {
                    if (model.type == HXPhotoModelMediaTypePhoto || model.type == HXPhotoModelMediaTypePhotoGif || model.type == HXPhotoModelMediaTypeLivePhoto) {
                        [self.manager.selectedPhotos removeObject:subModel];
                    }else if (model.type == HXPhotoModelMediaTypeVideo) {
                        [self.manager.selectedVideos removeObject:subModel];
                    }
                    self.albumModel.selectedCount--;
                    [self.manager.selectedList removeObjectAtIndex:i];
                    break;
                }
            }else if (model.type == HXPhotoModelMediaTypeCameraPhoto || model.type == HXPhotoModelMediaTypeCameraVideo){
                if ([subModel.cameraIdentifier isEqualToString:model.cameraIdentifier]) {
                    if (model.type == HXPhotoModelMediaTypeCameraPhoto) {
                        [self.manager.selectedPhotos removeObject:subModel];
                        [self.manager.selectedCameraPhotos removeObject:subModel];
                    }else if (model.type == HXPhotoModelMediaTypeCameraVideo) {
                        [self.manager.selectedVideos removeObject:subModel];
                        [self.manager.selectedCameraVideos removeObject:subModel];
                    }
                    self.albumModel.selectedCount--;
                    [self.manager.selectedList removeObjectAtIndex:i];
                    [self.manager.selectedCameraList removeObject:subModel];
                    break;
                }
            }
            i++;
        }
    }
    // 改变 预览、原图 按钮的状态
    [self changeButtonClick:model];
}

/**
 cell改变livephoto的状态

 @param model 模型
 */
- (void)cellChangeLivePhotoState:(HXPhotoModel *)model
{
    for (HXPhotoModel *PHModel in self.manager.selectedList) {
        if ([model.asset.localIdentifier isEqualToString:PHModel.asset.localIdentifier]) {
            PHModel.isCloseLivePhoto = model.isCloseLivePhoto;
            break;
        }
    }
    for (HXPhotoModel *PHModel in self.manager.selectedPhotos) {
        if ([model.asset.localIdentifier isEqualToString:PHModel.asset.localIdentifier]) {
            PHModel.isCloseLivePhoto = model.isCloseLivePhoto;
            break;
        }
    }
}


/**
 改变 预览、原图 按钮的状态
 
 @param model 选中的模型
 */
- (void)changeButtonClick:(HXPhotoModel *)model
{
    self.isSelectedChange = YES; // 记录在当前相册是否操作过
    if (self.manager.selectedList.count > 0) { // 选中数组已经有值时
        if (self.manager.type != HXPhotoManagerSelectedTypeVideo) {
            if (self.manager.type == HXPhotoManagerSelectedTypePhotoAndVideo) {
                BOOL isVideo = NO, isPhoto = NO;
                for (HXPhotoModel *model in self.manager.selectedList) {
                    // 循环判断选中的数组中有没有视频或者图片
                    if (model.type == HXPhotoModelMediaTypePhoto || (model.type == HXPhotoModelMediaTypePhotoGif || model.type == HXPhotoModelMediaTypeLivePhoto)) {
                        isPhoto = YES;
                    }else if (model.type == HXPhotoModelMediaTypeVideo) {
                        isVideo = YES;
                    }else if (model.type == HXPhotoModelMediaTypeCameraPhoto) {
                        isPhoto = YES;
                    }else if (model.type == HXPhotoModelMediaTypeCameraVideo) {
                        isVideo = YES;
                    }
                }
                if (self.manager.isOriginal) { // 原图按钮已经选中
                    // 改变原图按钮的状态和计算图片原图的大小
                    [self changeOriginalState:YES IsChange:YES];
                }
                // 当数组中有图片时 原图按钮变为可操作状态
                if ((isPhoto && isVideo) || isPhoto) {
                    self.bottomView.originalBtn.enabled = YES;
                }else { // 否则回复成初始状态
                    [self changeOriginalState:NO IsChange:NO];
                    self.bottomView.originalBtn.enabled = NO;
                    self.bottomView.originalBtn.selected = NO;
                    self.manager.isOriginal = NO;
                }
            }else {
                self.bottomView.originalBtn.enabled = YES;
            }
        }
        self.bottomView.previewBtn.enabled = YES;
        
        self.navigationItem.rightBarButtonItem.enabled = YES;
        [self.rightBtn setTitle:[NSString stringWithFormat:@"下一步(%ld)",self.manager.selectedList.count] forState:UIControlStateNormal];
        [self.rightBtn setBackgroundColor:[UIColor colorWithRed:253/255.0 green:142/255.0 blue:36/255.0 alpha:1]];
        self.rightBtn.layer.borderWidth = 0;
        CGFloat rightBtnH = self.rightBtn.frame.size.height;
        CGFloat rightBtnW = [HXPhotoTools getTextWidth:self.rightBtn.currentTitle withHeight:rightBtnH fontSize:14];
        self.rightBtn.frame = CGRectMake(0, 0, rightBtnW + 20, rightBtnH);
    }else { // 没有选中时 全部恢复成初始状态
        [self changeOriginalState:NO IsChange:NO];
        self.manager.isOriginal = NO;
        self.bottomView.originalBtn.selected = NO;
        self.bottomView.previewBtn.enabled = NO;
        self.bottomView.originalBtn.enabled = NO;
        self.navigationItem.rightBarButtonItem.enabled = NO;
        [self.rightBtn setTitle:@"下一步" forState:UIControlStateNormal];
        [self.rightBtn setBackgroundColor:[UIColor whiteColor]];
        self.rightBtn.frame = CGRectMake(0, 0, 60, 25);
        self.rightBtn.layer.borderWidth = 0.5;
    }
}

/**
 点击 预览、原图 按钮的代理
 
 @param type 类型
 @param button button对象
 */
- (void)didPhotoBottomViewClick:(HXPhotoBottomType)type Button:(UIButton *)button
{
    if (type == HXPhotoBottomTyPepreview) { // 预览
        self.isPreview = YES; // 自定义转场动画时用到的属性
        // 判断选中数组中有没有图片 如果有图片则只预览选中的图片 反之 视频
        if (self.manager.selectedPhotos.count > 0) {
            HXPhotoPreviewViewController *vc = [[HXPhotoPreviewViewController alloc] init];
            vc.modelList = self.manager.selectedPhotos;
            vc.index = 0;
            vc.delegate = self;
            vc.manager = self.manager;
            self.navigationController.delegate = vc;
            [self.navigationController pushViewController:vc animated:YES];
        }else {
            HXVideoPreviewViewController *vc = [[HXVideoPreviewViewController alloc] init];
            vc.manager = self.manager;
            vc.delegate = self;
            vc.model = self.manager.selectedVideos.firstObject;
            if (vc.model.type == HXPhotoModelMediaTypeCameraVideo) {
                vc.isCamera = YES;
            }
            self.navigationController.delegate = vc;
            [self.navigationController pushViewController:vc animated:YES];
        }
    }else { // 原图
        // 记录是否原图
        self.manager.isOriginal = button.selected;
        // 改变原图按钮状态
        [self changeOriginalState:button.selected IsChange:NO];
    }
}

/**
 查看视频时点击下一步按钮的代理
 */
- (void)previewVideoDidNextClick
{
    [self didNextClick:self.rightBtn];
}

/**
 查看视频时 选中/取消选中 的代理
 
 @param model 模型
 */
- (void)previewVideoDidSelectedClick:(HXPhotoModel *)model
{
    [self.collectionView reloadData];
    // 改变 预览、原图 按钮的状态
    [self changeButtonClick:model];
}

/**
 改变原图按钮的状态信息
 
 @param selected 是否选中
 @param isChange 是否改变成初始状态
 */
- (void)changeOriginalState:(BOOL)selected IsChange:(BOOL)isChange
{
    if (selected) { // 选中时
        if (isChange) { // 改变成初始状态
            self.bottomView.originalBtn.frame = _originalFrame;
            [self.bottomView.originalBtn setTitle:@"原图" forState:UIControlStateNormal];
        }
        // 记录原图按钮的frame
        _originalFrame = self.bottomView.originalBtn.frame;
        [self.indica startAnimating];
        self.indica.hidden = NO;
        CGFloat indicaW = self.indica.frame.size.width;
        CGFloat originalBtnX = self.bottomView.originalBtn.frame.origin.x;
        CGFloat originalBtnY = self.bottomView.originalBtn.frame.origin.y;
        CGFloat originalBtnW = self.bottomView.originalBtn.frame.size.width;
        CGFloat originalBtnH = self.bottomView.originalBtn.frame.size.height;
        self.bottomView.originalBtn.frame = CGRectMake(originalBtnX, originalBtnY, originalBtnW + indicaW + 5, originalBtnH);
        __weak typeof(self) weakSelf = self;
        // 获取一组图片的大小
        [HXPhotoTools FetchPhotosBytes:self.manager.selectedPhotos completion:^(NSString *totalBytes) {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.25 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                if (!weakSelf.manager.isOriginal) {
                    return;
                }
                weakSelf.manager.photosTotalBtyes = totalBytes;
                CGFloat totalW = [HXPhotoTools getTextWidth:[NSString stringWithFormat:@"(%@)",totalBytes] withHeight:originalBtnH fontSize:14];
                [weakSelf.bottomView.originalBtn setTitle:[NSString stringWithFormat:@"原图(%@)",totalBytes] forState:UIControlStateNormal];
                [weakSelf.indica stopAnimating];
                weakSelf.indica.hidden = YES;
                weakSelf.bottomView.originalBtn.frame = CGRectMake(originalBtnX, originalBtnY, originalBtnW+totalW, originalBtnH);
            });
        }];
    }else {// 取消选中 恢复成初始状态
        [self.indica stopAnimating];
        self.indica.hidden = YES;
        self.manager.photosTotalBtyes = nil;
        [self.bottomView.originalBtn setTitle:@"原图" forState:UIControlStateNormal];
        self.bottomView.originalBtn.frame = _originalFrame;
    }
}

/**
 查看图片时点击下一步按钮的代理
 */
- (void)previewDidNextClick
{
    [self didNextClick:self.rightBtn];
}

/**
 点击下一步执行的方法
 
 @param button 下一步按钮
 */
- (void)didNextClick:(UIButton *)button
{
    // 如果通过相机拍的数组为空 则清空所有关于相机的数组
    if (self.manager.selectedCameraList.count == 0) {
        [self.manager.cameraList removeAllObjects];
        [self.manager.cameraVideos removeAllObjects];
        [self.manager.cameraPhotos removeAllObjects];
    }
    // 记录这次操作的数据
    self.manager.endSelectedList = [NSMutableArray arrayWithArray:self.manager.selectedList];
    self.manager.endSelectedPhotos = [NSMutableArray arrayWithArray:self.manager.selectedPhotos];
    self.manager.endSelectedVideos = [NSMutableArray arrayWithArray:self.manager.selectedVideos];
    self.manager.endCameraList = [NSMutableArray arrayWithArray:self.manager.cameraList];
    self.manager.endCameraPhotos = [NSMutableArray arrayWithArray:self.manager.cameraPhotos];
    self.manager.endCameraVideos = [NSMutableArray arrayWithArray:self.manager.cameraVideos];
    self.manager.endSelectedCameraList = [NSMutableArray arrayWithArray:self.manager.selectedCameraList];
    self.manager.endSelectedCameraPhotos = [NSMutableArray arrayWithArray:self.manager.selectedCameraPhotos];
    self.manager.endSelectedCameraVideos = [NSMutableArray arrayWithArray:self.manager.selectedCameraVideos];
    self.manager.endIsOriginal = self.manager.isOriginal;
    self.manager.endPhotosTotalBtyes = self.manager.photosTotalBtyes;
    
    if ([self.delegate respondsToSelector:@selector(photoViewControllerDidNext:Photos:Videos:Original:)]) {
        [self.delegate photoViewControllerDidNext:self.manager.endSelectedList.mutableCopy Photos:self.manager.endSelectedPhotos.mutableCopy Videos:self.manager.endSelectedVideos.mutableCopy Original:self.manager.endIsOriginal];
    }
    [self dismissViewControllerAnimated:YES completion:nil];
}

/**
 小菊花
 
 @return 小菊花
 */
- (UIActivityIndicatorView *)indica
{
    if (!_indica) {
        _indica = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
        CGFloat indicaX = self.bottomView.originalBtn.titleLabel.frame.origin.x + [HXPhotoTools getTextWidth:@"原图" withHeight:self.bottomView.originalBtn.frame.size.height / 2 fontSize:14] + 5;
        CGFloat indicaW = _indica.frame.size.width;
        CGFloat indicaH = _indica.frame.size.height;
        _indica.frame = CGRectMake(indicaX, 0, indicaW, indicaH);
        _indica.center = CGPointMake(_indica.center.x, self.bottomView.originalBtn.frame.size.height / 2);
        [self.bottomView.originalBtn addSubview:_indica];
    }
    return _indica;
}

/**
 下一步按钮
 
 @return 按钮
 */
- (UIButton *)rightBtn
{
    if (!_rightBtn) {
        _rightBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [_rightBtn setTitle:@"下一步" forState:UIControlStateNormal];
        [_rightBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [_rightBtn setTitleColor:[UIColor lightGrayColor] forState:UIControlStateDisabled];
        [_rightBtn setTitleColor:[[UIColor lightGrayColor] colorWithAlphaComponent:0.5] forState:UIControlStateHighlighted];
        _rightBtn.layer.masksToBounds = YES;
        _rightBtn.layer.cornerRadius = 2;
        _rightBtn.layer.borderWidth = 0.5;
        _rightBtn.layer.borderColor = [UIColor lightGrayColor].CGColor;
        [_rightBtn setBackgroundColor:[UIColor whiteColor]];
        [_rightBtn addTarget:self action:@selector(didNextClick:) forControlEvents:UIControlEventTouchUpInside];
        _rightBtn.titleLabel.font = [UIFont systemFontOfSize:14];
        _rightBtn.frame = CGRectMake(0, 0, 60, 25);
    }
    return _rightBtn;
}

/**
 展开相册列表时的黑色背景
 
 @return 视图
 */
- (UIView *)albumsBgView
{
    if (!_albumsBgView) {
        _albumsBgView = [[UIView alloc] initWithFrame:CGRectMake(0, 64, self.view.frame.size.width, self.view.frame.size.height - 64)];
        _albumsBgView.hidden = YES;
        _albumsBgView.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0];
        [_albumsBgView addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(didAlbumsBgViewClick)]];
    }
    return _albumsBgView;
}

/**
 点击背景时
 */
- (void)didAlbumsBgViewClick
{
    [self pushAlbumList:self.titleBtn];
}

@end

@interface HXPhotoBottomView ()
@end

@implementation HXPhotoBottomView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor whiteColor];
        [self setup];
    }
    return self;
}

- (void)setup
{
    UIButton *previewBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [previewBtn setTitle:@"预览" forState:UIControlStateNormal];
    [previewBtn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [previewBtn setTitleColor:[UIColor lightGrayColor] forState:UIControlStateDisabled];
    [previewBtn setBackgroundImage:[UIImage imageNamed:@"compose_photo_preview_seleted@2x.png"] forState:UIControlStateNormal];
    [previewBtn setBackgroundImage:[UIImage imageNamed:@"compose_photo_preview_disable@2x.png"] forState:UIControlStateDisabled];
    previewBtn.titleLabel.font = [UIFont systemFontOfSize:14];
    [previewBtn addTarget:self action:@selector(didPreviewClick:) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:previewBtn];
    CGFloat previewBtnX = 10;
    CGFloat previewBtnW = previewBtn.currentBackgroundImage.size.width;
    CGFloat previewBtnH = previewBtn.currentBackgroundImage.size.height;
    previewBtn.frame = CGRectMake(previewBtnX, 0, previewBtnW, previewBtnH);
    previewBtn.center = CGPointMake(previewBtn.center.x, self.frame.size.height / 2);
    self.previewBtn = previewBtn;
    
    UIButton *originalBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [originalBtn setTitle:@"原图" forState:UIControlStateNormal];
    [originalBtn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [originalBtn setTitleColor:[UIColor lightGrayColor] forState:UIControlStateDisabled];
    originalBtn.layer.masksToBounds = YES;
    originalBtn.layer.cornerRadius = 2;
    originalBtn.layer.borderColor = [UIColor colorWithRed:200/255.0 green:200/255.0 blue:200/255.0 alpha:1].CGColor;
    originalBtn.layer.borderWidth = 0.7;
    [originalBtn setImage:[UIImage imageNamed:@"椭圆-1@2x.png"] forState:UIControlStateNormal];
    [originalBtn setImage:[UIImage imageNamed:@"椭圆-1-拷贝@2x.png"] forState:UIControlStateSelected];
    originalBtn.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
    originalBtn.titleEdgeInsets = UIEdgeInsetsMake(0, 8 + 8, 0, 0);
    originalBtn.imageEdgeInsets = UIEdgeInsetsMake(0, 8, 0, 0);
    originalBtn.titleLabel.font = [UIFont systemFontOfSize:14];
    [originalBtn addTarget:self action:@selector(didOriginalClick:) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:originalBtn];
    CGFloat originalBtnX = CGRectGetMaxX(previewBtn.frame)+10;
    CGFloat originalBtnW = 65;
    CGFloat originalBtnH = previewBtnH;
    originalBtn.frame = CGRectMake(originalBtnX, 0, originalBtnW, originalBtnH);
    originalBtn.center = CGPointMake(originalBtn.center.x, self.frame.size.height / 2);
    self.originalBtn = originalBtn;
    
    UIView *lineView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.frame.size.width, 0.5)];
    lineView.backgroundColor = [[UIColor lightGrayColor] colorWithAlphaComponent:0.5];
    [self addSubview:lineView];
}

- (void)didPreviewClick:(UIButton *)button
{
    if ([self.delegate respondsToSelector:@selector(didPhotoBottomViewClick:Button:)]) {
        [self.delegate didPhotoBottomViewClick:HXPhotoBottomTyPepreview Button:button];
    }
}

- (void)didOriginalClick:(UIButton *)button
{
    button.selected = !button.selected;
    if ([self.delegate respondsToSelector:@selector(didPhotoBottomViewClick:Button:)]) {
        [self.delegate didPhotoBottomViewClick:HXPhotoBottomTyOriginalPhoto Button:button];
    }
}

@end
