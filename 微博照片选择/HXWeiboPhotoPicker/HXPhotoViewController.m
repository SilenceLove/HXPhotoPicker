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
#import "HXFullScreenCameraViewController.h"
#import "HXPhotoEditViewController.h"
#import <MobileCoreServices/MobileCoreServices.h>
#import <MediaPlayer/MediaPlayer.h>

#define iOS9Later ([UIDevice currentDevice].systemVersion.floatValue >= 9.1f)

static NSString *PhotoViewCellId = @"PhotoViewCellId";
@interface HXPhotoViewController ()<UICollectionViewDataSource,UICollectionViewDelegate,CAAnimationDelegate,UIViewControllerPreviewingDelegate,HXAlbumListViewDelegate,HXPhotoPreviewViewControllerDelegate,HXPhotoBottomViewDelegate,HXVideoPreviewViewControllerDelegate,HXCameraViewControllerDelegate,HXPhotoViewCellDelegate,UIAlertViewDelegate,HXFullScreenCameraViewControllerDelegate,HXPhotoEditViewControllerDelegate,UICollectionViewDataSourcePrefetching,UIImagePickerControllerDelegate>
{
    CGRect _originalFrame;
}

@property (copy, nonatomic) NSArray *albums;
@property (weak, nonatomic) HXAlbumListView *albumView;
@property (weak, nonatomic) HXAlbumTitleButton *titleBtn;
@property (strong, nonatomic) UIButton *rightBtn;
@property (strong, nonatomic) UIView *albumsBgView;
@property (weak, nonatomic) HXPhotoBottomView *bottomView;
@property (strong, nonatomic) UIActivityIndicatorView *indica;
@property (assign, nonatomic) BOOL isSelectedChange;
@property (strong, nonatomic) HXAlbumModel *albumModel;
@property (assign, nonatomic) NSInteger currentSelectCount;
@property (strong, nonatomic) NSIndexPath *currentIndexPath;
@property (strong, nonatomic) UIImageView *previewImg;
@property (strong, nonatomic) NSTimer *timer;
@property (strong, nonatomic) UILabel *authorizationLb;
@property (weak, nonatomic) id<UIViewControllerPreviewing> previewingContext;
@property (assign, nonatomic) BOOL responseTraitCollection;
@property (assign, nonatomic) BOOL responseForceTouchCapability;
@property (assign, nonatomic) BOOL isCapabilityAvailable;
@property (assign, nonatomic) BOOL selectOtherAlbum;
@property (strong, nonatomic) UINavigationBar *navBar;
@property (strong, nonatomic) UINavigationItem *navItem;
@property (strong, nonatomic) UIImagePickerController* imagePickerController;
@end

@implementation HXPhotoViewController

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
- (void)goSetup {
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]];
}
- (void)dealloc {
    self.manager.selectPhoto = NO; 
    NSSLog(@"dealloc");
}
- (void)viewDidLoad {
    [super viewDidLoad];
    [self.manager getImage];
    self.view.backgroundColor = [UIColor whiteColor];
    self.manager.selectPhoto = YES;
    [self setup];
    if (self.manager.albums.count > 0) {
        if (self.manager.cacheAlbum) {
            self.albums = self.manager.albums.mutableCopy;
            [self getAlbumPhotos];
        }else {
            [self getObjs];
        }
    }else {
        [self getObjs];
    }
    // 获取当前应用对照片的访问授权状态
    if ([PHPhotoLibrary authorizationStatus] != PHAuthorizationStatusAuthorized) {
        [self.view addSubview:self.authorizationLb];
        self.timer = [NSTimer scheduledTimerWithTimeInterval:0.2 target:self selector:@selector(observeAuthrizationStatusChange:) userInfo:nil repeats:YES];
    }else{
        [self goCameraVC];
    }
    __weak typeof(self) weakSelf = self;
    [self.manager setPhotoLibraryDidChangeWithPhotoViewController:^(NSArray *collectionChanges){
        [weakSelf photoLibraryDidChange:collectionChanges];
    }];
}
- (void)getAlbumPhotos {
    HXAlbumModel *model = self.albums.firstObject;
    self.currentSelectCount = model.selectedCount;
    self.albumModel = model;
    __weak typeof(self) weakSelf = self;
    [self.manager FetchAllPhotoForPHFetchResult:model.result Index:model.index FetchResult:^(NSArray *photos, NSArray *videos, NSArray *Objs) {
        weakSelf.photos = [NSMutableArray arrayWithArray:photos];
        weakSelf.videos = [NSMutableArray arrayWithArray:videos];
        weakSelf.objs = [NSMutableArray arrayWithArray:Objs];
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf.view handleLoading];
            weakSelf.albumView.list = weakSelf.albums;
            if (model.albumName.length == 0) {
                model.albumName = @"相机胶卷";
            }
            [weakSelf.titleBtn setTitle:model.albumName forState:UIControlStateNormal];
            weakSelf.title = model.albumName;
            CATransition *transition = [CATransition animation];
            transition.type = kCATransitionPush;
            transition.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
            transition.fillMode = kCAFillModeForwards;
            transition.duration = 0.05;
            transition.subtype = kCATransitionFade;
            [[weakSelf.collectionView layer] addAnimation:transition forKey:@""];
            [weakSelf.collectionView reloadData];
        });
    }];

}
- (void)photoLibraryDidChange:(NSArray *)list {
    for (int i = 0; i < list.count ; i++) {
        NSDictionary *dic = list[i];
        PHFetchResultChangeDetails *collectionChanges = dic[@"collectionChanges"];
        HXAlbumModel *albumModel = dic[@"model"];
        if (collectionChanges) {
            if ([collectionChanges hasIncrementalChanges]) {
                PHFetchResult *result = collectionChanges.fetchResultAfterChanges;
                
                if (collectionChanges.insertedObjects.count > 0) {
                    albumModel.asset = nil;
                    albumModel.result = result;
                    albumModel.count = result.count;
                    if (self.albumModel.index == albumModel.index) {
                        [self collectionChangeWithInseterData:collectionChanges.insertedObjects];
                    }
                }
                if (collectionChanges.removedObjects.count > 0) {
                    albumModel.asset = nil;
                    albumModel.result = result;
                    albumModel.count = result.count;
                    
                    BOOL select = NO;
                    NSMutableArray *indexPathList = [NSMutableArray array];
                    for (PHAsset *asset in collectionChanges.removedObjects) {
                        NSString *property = @"asset";
                        NSPredicate *pred = [NSPredicate predicateWithFormat:@"%K = %@", property, asset];
                        if (i == 0) {
                            NSArray *newArray = [self.manager.selectedList filteredArrayUsingPredicate:pred];
                            if (newArray.count > 0) {
                                select = YES;
                                HXPhotoModel *photoModel = newArray.firstObject;
                                photoModel.selected = NO;
                                if ((photoModel.type == HXPhotoModelMediaTypePhoto || photoModel.type == HXPhotoModelMediaTypePhotoGif) || photoModel.type == HXPhotoModelMediaTypeLivePhoto) {
                                    [self.manager.selectedPhotos removeObject:photoModel];
                                }else {
                                    [self.manager.selectedVideos removeObject:photoModel];
                                }
                                [self.manager.selectedList removeObject:photoModel];
                            }
                        }
                        if (self.albumModel.index == albumModel.index) {
                            HXPhotoModel *photoModel;
                            if (asset.mediaType == PHAssetMediaTypeImage) {
                                NSArray *photoArray = [self.photos filteredArrayUsingPredicate:pred];
                                photoModel = photoArray.firstObject;
                                [self.photos removeObject:photoModel];
                            }else if (asset.mediaType == PHAssetMediaTypeVideo) {
                                NSArray *videoArray = [self.videos filteredArrayUsingPredicate:pred];
                                photoModel = videoArray.firstObject;
                                [self.videos removeObject:photoModel];
                            }
                            [indexPathList addObject:[NSIndexPath indexPathForItem:[self.objs indexOfObject:photoModel] inSection:0]];
                            [self.objs removeObject:photoModel];
                        }
                    }
                    if (select) {
                        [self changeButtonClick:self.manager.selectedList.lastObject];
                    }
                    if (indexPathList.count > 0) {
                        [self.collectionView deleteItemsAtIndexPaths:indexPathList];
                    }
                    
                }
                if (collectionChanges.changedObjects.count > 0) {
                    
                }
                if ([collectionChanges hasMoves]) {
                    
                }
            }
        }
    }
    self.albumView.list = self.albums;
}
- (void)collectionChangeWithInseterData:(NSArray *)array {
    NSInteger insertedCount = array.count;
    NSInteger cameraIndex = self.manager.openCamera ? 1 : 0;
    NSMutableArray *indexPathList = [NSMutableArray array];
    for (int i = 0; i < insertedCount; i++) {
        PHAsset *asset = array[i];
        HXPhotoModel *photoModel = [[HXPhotoModel alloc] init];
        photoModel.asset = asset;
        if (asset.mediaType == PHAssetMediaTypeImage) {
            photoModel.subType = HXPhotoModelMediaSubTypePhoto;
            if ([[asset valueForKey:@"filename"] hasSuffix:@"GIF"]) {
                if (self.manager.singleSelected && self.manager.singleSelecteClip) {
                    photoModel.type = HXPhotoModelMediaTypePhoto;
                }else {
                    photoModel.type = self.manager.lookGifPhoto ? HXPhotoModelMediaTypePhotoGif : HXPhotoModelMediaTypePhoto;
                }
            }else {
                if (iOS9Later) {
                    if (asset.mediaSubtypes == PHAssetMediaSubtypePhotoLive) {
                        if (!self.manager.singleSelected) {
                            photoModel.type = self.manager.lookLivePhoto ? HXPhotoModelMediaTypeLivePhoto : HXPhotoModelMediaTypePhoto;
                        }else {
                            photoModel.type = HXPhotoModelMediaTypePhoto;
                        }
                    }else {
                        photoModel.type = HXPhotoModelMediaTypePhoto;
                    }
                }else {
                    photoModel.type = HXPhotoModelMediaTypePhoto;
                }
            }
            [self.photos insertObject:photoModel atIndex:0];
        }else if (asset.mediaType == PHAssetMediaTypeVideo) {
            photoModel.subType = HXPhotoModelMediaSubTypeVideo;
            photoModel.type = HXPhotoModelMediaTypeVideo;
            [[PHImageManager defaultManager] requestAVAssetForVideo:asset options:nil resultHandler:^(AVAsset * _Nullable asset, AVAudioMix * _Nullable audioMix, NSDictionary * _Nullable info) {
                photoModel.avAsset = asset;
            }];
            NSString *timeLength = [NSString stringWithFormat:@"%0.0f",asset.duration];
            photoModel.videoTime = [HXPhotoTools getNewTimeFromDurationSecond:timeLength.integerValue];
            [self.videos insertObject:photoModel atIndex:0];
        }
        photoModel.currentAlbumIndex = self.albumModel.index;
        [self.objs insertObject:photoModel atIndex:cameraIndex];
        [indexPathList addObject:[NSIndexPath indexPathForItem:i + cameraIndex inSection:0]];
    }
    [self.collectionView insertItemsAtIndexPaths:indexPathList];
}
- (void)observeAuthrizationStatusChange:(NSTimer *)timer {
    if ([PHPhotoLibrary authorizationStatus] == PHAuthorizationStatusAuthorized) {
        [timer invalidate];
        [self.timer invalidate];
        self.timer = nil;
        [self.authorizationLb removeFromSuperview];
        [self goCameraVC];
        if (self.manager.albums.count > 0) {
            if (self.manager.cacheAlbum) {
                self.albums = self.manager.albums.mutableCopy;
                [self getAlbumPhotos];
            }else {
                [self getObjs];
            }
        }else {
            [self getObjs];
        }
    }
}
- (void)goCameraVC {
    if (self.manager.goCamera) {
        self.manager.goCamera = NO;
        if (!self.manager.openCamera) {
            return;
        }
        if(![UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
            [self.view showImageHUDText:[NSBundle hx_localizedStringForKey:@"无法使用相机!"]];
            return;
        }
        AVAuthorizationStatus authStatus = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
        if (authStatus == AVAuthorizationStatusRestricted || authStatus == AVAuthorizationStatusDenied) {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:[NSBundle hx_localizedStringForKey:@"无法使用相机"] message:[NSBundle hx_localizedStringForKey:@"请在设置-隐私-相机中允许访问相机"] delegate:self cancelButtonTitle:[NSBundle hx_localizedStringForKey:@"取消"] otherButtonTitles:[NSBundle hx_localizedStringForKey:@"设置"], nil];
            [alert show];
            return;
        }
        if (self.manager.cameraType == HXPhotoManagerCameraTypeFullScreen) {
            HXFullScreenCameraViewController *vc = [[HXFullScreenCameraViewController alloc] init];
            vc.delegate = self;
            if (self.manager.type == HXPhotoManagerSelectedTypePhotoAndVideo) {
                vc.type = HXCameraTypePhotoAndVideo;
            }else if (self.manager.type == HXPhotoManagerSelectedTypePhoto) {
                vc.type = HXCameraTypePhoto;
            }else if (self.manager.type == HXPhotoManagerSelectedTypeVideo) {
                vc.type = HXCameraTypeVideo;
            }
            
            vc.photoManager = self.manager;
            
            if (self.manager.singleSelected) {
                [self presentViewController:[[UINavigationController alloc] initWithRootViewController:vc] animated:YES completion:nil];
            }else {
                [self presentViewController:vc animated:YES completion:nil];
            }
        }else if (self.manager.cameraType == HXPhotoManagerCameraTypeHalfScreen) {
            HXCameraViewController *vc = [[HXCameraViewController alloc] init];
            vc.delegate = self;
            vc.photoManager = self.manager;
            if (self.manager.type == HXPhotoManagerSelectedTypePhotoAndVideo) {
                vc.type = HXCameraTypePhotoAndVideo;
            }else if (self.manager.type == HXPhotoManagerSelectedTypePhoto) {
                vc.type = HXCameraTypePhoto;
            }else if (self.manager.type == HXPhotoManagerSelectedTypeVideo) {
                vc.type = HXCameraTypeVideo;
            }
            
            if (self.manager.singleSelected) {
                [self presentViewController:[[UINavigationController alloc] initWithRootViewController:vc] animated:YES completion:nil];
            }else {
                [self presentViewController:vc animated:YES completion:nil];
            }
        }else {
            // 跳转到相机或相册页面
            NSString *requiredMediaTypeImage = ( NSString *)kUTTypeImage;
            NSString *requiredMediaTypeMovie = ( NSString *)kUTTypeMovie;
            NSArray *arrMediaTypes;
            if (self.manager.type == HXPhotoManagerSelectedTypePhoto) {
                arrMediaTypes=[NSArray arrayWithObjects:requiredMediaTypeImage,nil];
            }else if (self.manager.type == HXPhotoManagerSelectedTypePhotoAndVideo) {
                arrMediaTypes=[NSArray arrayWithObjects:requiredMediaTypeImage, requiredMediaTypeMovie,nil];
            }else if (self.manager.type == HXPhotoManagerSelectedTypeVideo) {
                arrMediaTypes=[NSArray arrayWithObjects:requiredMediaTypeMovie,nil];
            }
            [self.imagePickerController setMediaTypes:arrMediaTypes];
            [self presentViewController:self.imagePickerController animated:YES completion:nil];
        }
    }
}
- (UIImagePickerController *)imagePickerController {
    if (!_imagePickerController) {
        _imagePickerController = [[UIImagePickerController alloc] init];
        _imagePickerController.delegate = (id)self;
        _imagePickerController.allowsEditing = NO;
        // 设置录制视频的质量
        [_imagePickerController setVideoQuality:UIImagePickerControllerQualityTypeHigh];
        //设置最长摄像时间
        [_imagePickerController setVideoMaximumDuration:60.f];
        _imagePickerController.sourceType = UIImagePickerControllerSourceTypeCamera;
        _imagePickerController.navigationController.navigationBar.tintColor = [UIColor whiteColor];
        _imagePickerController.modalPresentationStyle = UIModalPresentationOverCurrentContext;
    }
    return _imagePickerController;
}
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 1) {
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]];
    }
}
/**
 获取所有相册 图片
 */
- (void)getObjs {
    [self.view showLoadingHUDText:[NSBundle hx_localizedStringForKey:@"加载中"]];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        __weak typeof(self) weakSelf = self;
        BOOL isShow = self.manager.selectedList.count;
        [self.manager FetchAllAlbum:^(NSArray *albums) {
            weakSelf.albums = albums;
            [weakSelf getAlbumPhotos];
        } IsShowSelectTag:isShow];
    });
}
/**
 展开/收起 相册列表
 
 @param button 按钮
 */
- (void)pushAlbumList:(UIButton *)button {
    button.selected = !button.selected;
    button.userInteractionEnabled = NO;
    if (button.selected) {
        if (self.manager.selectedList.count > 0) {
            for (HXAlbumModel *albumMd in self.albums) {
                albumMd.selectedCount = 0;
            }
            for (HXPhotoModel *photoModel in self.manager.selectedList) {
                for (HXAlbumModel *albumMd in self.albums) {
                    if ([albumMd.result containsObject:photoModel.asset]) {
                        albumMd.selectedCount++;
                    }
                }
            }
            if (self.manager.selectedCameraList.count > 0) {
                HXAlbumModel *albumMd = self.albums.firstObject;
                albumMd.selectedCount = self.manager.selectedCameraList.count;
            }
        }else {
            for (HXAlbumModel *albumMd in self.albums) {
                albumMd.selectedCount = 0;
            }
        }
        self.albumView.list = self.albums;
        self.currentSelectCount = self.albumModel.selectedCount;
        
        self.albumsBgView.hidden = NO;
        [UIView animateWithDuration:0.2 animations:^{
            self.albumView.frame = CGRectMake(0, 64, self.view.frame.size.width, 340);
            self.albumView.tableView.frame = CGRectMake(0, 15, self.view.frame.size.width, 340);
            button.imageView.transform = CGAffineTransformMakeRotation(M_PI);
        } completion:^(BOOL finished) {
            [UIView animateWithDuration:0.25 animations:^{
                self.albumView.tableView.frame = CGRectMake(0, 0, self.view.frame.size.width, 340);
            } completion:^(BOOL finished) {
                button.userInteractionEnabled = YES;
            }];
        }];
        [UIView animateWithDuration:0.45 animations:^{
            self.albumsBgView.alpha = 1;
        }];
    }else {
        
        [UIView animateWithDuration:0.45 animations:^{
            self.albumsBgView.alpha = 0;
        } completion:^(BOOL finished) {
            self.albumsBgView.hidden = YES;
            button.userInteractionEnabled = YES;
        }];
        [UIView animateWithDuration:0.25 animations:^{
            self.albumView.tableView.frame = CGRectMake(0, 15, self.view.frame.size.width, 340);
            button.imageView.transform = CGAffineTransformMakeRotation(M_PI * 2);
        } completion:^(BOOL finished) {
            [UIView animateWithDuration:0.2 animations:^{
                self.albumView.tableView.frame = CGRectMake(0, 0, self.view.frame.size.width, 340);
                self.albumView.frame = CGRectMake(0, -340, self.view.frame.size.width, 340);
            }];
        }];
    }
}
- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:YES animated:NO];
}
- (UINavigationBar *)navBar {
    if (!_navBar) {
        _navBar = [[UINavigationBar alloc] initWithFrame:CGRectMake(0, 0, self.view.hx_w, 64)];
        [_navBar pushNavigationItem:self.navItem animated:NO];
        
        _navBar.tintColor = self.manager.UIManager.navLeftBtnTitleColor;
        if (self.manager.UIManager.navBackgroundImageName) {
            [_navBar setBackgroundImage:[HXPhotoTools hx_imageNamed:self.manager.UIManager.navBackgroundImageName] forBarMetrics:UIBarMetricsDefault];
        }else if (self.manager.UIManager.navBackgroundColor) {
            [_navBar setBackgroundColor:self.manager.UIManager.navBackgroundColor];
        }
    }
    return _navBar;
}
- (UINavigationItem *)navItem {
    if (!_navItem) {
        _navItem = [[UINavigationItem alloc] init];
        _navItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:[NSBundle hx_localizedStringForKey:@"取消"] style:UIBarButtonItemStylePlain target:self action:@selector(cancelClick)];
        
        HXAlbumTitleButton *titleBtn = [HXAlbumTitleButton buttonWithType:UIButtonTypeCustom];
        [titleBtn setTitleColor:self.manager.UIManager.navTitleColor forState:UIControlStateNormal];
        [titleBtn setImage:[HXPhotoTools hx_imageNamed:self.manager.UIManager.navTitleImageName] forState:UIControlStateNormal];
        titleBtn.frame = CGRectMake(0, 0, 150, 30);
        [titleBtn setTitle:@"相机胶卷" forState:UIControlStateNormal];
        [titleBtn addTarget:self action:@selector(pushAlbumList:) forControlEvents:UIControlEventTouchUpInside];
        self.titleBtn = titleBtn;
        _navItem.title = @"相机胶卷";
        _navItem.titleView = self.titleBtn;
    }
    return _navItem;
}
- (void)setup {
    self.responseTraitCollection = [self respondsToSelector:@selector(traitCollection)];
    self.responseForceTouchCapability = [self.traitCollection respondsToSelector:@selector(forceTouchCapability)];
    self.isCapabilityAvailable = self.traitCollection.forceTouchCapability == UIForceTouchCapabilityAvailable;
    
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
    
    self.view.backgroundColor = [UIColor whiteColor];
    
    CGFloat width = self.view.frame.size.width;
    CGFloat height = self.view.frame.size.height;
    
    if (!self.manager.singleSelected) {
        self.navItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:self.rightBtn];
        if (self.manager.selectedList.count > 0) {
            self.navItem.rightBarButtonItem.enabled = YES;
            [self.rightBtn setTitle:[NSString stringWithFormat:@"%@(%ld)",[NSBundle hx_localizedStringForKey:@"下一步"],self.manager.selectedList.count] forState:UIControlStateNormal];
            [self.rightBtn setBackgroundColor:self.manager.UIManager.navRightBtnNormalBgColor];
            self.rightBtn.layer.borderWidth = 0;
            CGFloat rightBtnH = self.rightBtn.frame.size.height;
            CGFloat rightBtnW = [HXPhotoTools getTextWidth:self.rightBtn.currentTitle height:rightBtnH fontSize:14];
            self.rightBtn.frame = CGRectMake(0, 0, rightBtnW + 20, rightBtnH);
        }else {
            self.navItem.rightBarButtonItem.enabled = NO;
            [self.rightBtn setTitle:[NSBundle hx_localizedStringForKey:@"下一步"] forState:UIControlStateNormal];
            [self.rightBtn setBackgroundColor:self.manager.UIManager.navRightBtnDisabledBgColor];
            self.rightBtn.frame = CGRectMake(0, 0, 60, 25);
            self.rightBtn.layer.borderWidth = 0.5;
        }
    }
    
    CGFloat spacing = 0.5;
    CGFloat CVwidth = (width - spacing * self.manager.rowCount - 1 ) / self.manager.rowCount;
    UICollectionViewFlowLayout *flowLayout = [[UICollectionViewFlowLayout alloc] init];
    flowLayout.itemSize = CGSizeMake(CVwidth, CVwidth);
    flowLayout.minimumInteritemSpacing = spacing;
    flowLayout.minimumLineSpacing = spacing;
    self.automaticallyAdjustsScrollViewInsets = NO;
    
    self.collectionView = [[UICollectionView alloc] initWithFrame:CGRectMake(0, 0, width, height) collectionViewLayout:flowLayout];
    self.collectionView.scrollIndicatorInsets = self.collectionView.contentInset;
    self.collectionView.dataSource = self;
    self.collectionView.delegate = self;
    if (([UIDevice currentDevice].systemVersion.floatValue >= 10.0f)) {
        self.collectionView.prefetchDataSource = self;
        self.collectionView.prefetchingEnabled = YES;
    }
    self.collectionView.alwaysBounceVertical = YES;
    self.collectionView.backgroundColor = [UIColor whiteColor];
    [self.collectionView registerClass:[HXPhotoViewCell class] forCellWithReuseIdentifier:PhotoViewCellId];
    [self.view addSubview:self.collectionView];
    if (!self.manager.singleSelected) {
        self.collectionView.contentInset = UIEdgeInsetsMake(spacing + 64, 0, spacing + 50, 0);
        HXPhotoBottomView *bottomView = [[HXPhotoBottomView alloc] initWithFrame:CGRectMake(0, height - 50, width, 50) manager:self.manager];
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
            CGFloat totalW = [HXPhotoTools getTextWidth:[NSString stringWithFormat:@"(%@)",self.manager.photosTotalBtyes] height:originalBtnH fontSize:14];
            [bottomView.originalBtn setTitle:[NSString stringWithFormat:@"%@(%@)",[NSBundle hx_localizedStringForKey:@"原图"],self.manager.photosTotalBtyes] forState:UIControlStateNormal];
            
            bottomView.originalBtn.frame = CGRectMake(originalBtnX, originalBtnY, originalBtnW+totalW  , originalBtnH);
        }
    }else {
        self.collectionView.contentInset = UIEdgeInsetsMake(spacing + 64, 0,  spacing, 0);
    }
    self.collectionView.scrollIndicatorInsets = self.collectionView.contentInset;
    
    [self.view addSubview:self.albumsBgView];
    HXAlbumListView *albumView = [[HXAlbumListView alloc] initWithFrame:CGRectMake(0, -340, width, 340) manager:self.manager];
    albumView.delegate = self;
    [self.view addSubview:albumView];
    self.albumView = albumView;
    
    [self.view addSubview:self.navBar];
}
/**
 点击取消按钮 清空所有操作
 */
- (void)cancelClick {
    self.manager.selectPhoto = NO;
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
#pragma mark - < UICollectionViewDataSource >
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.objs.count;
}
- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath { 
    HXPhotoViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:PhotoViewCellId forIndexPath:indexPath];
    if (!self.manager.singleSelected) {
        cell.iconDic = self.manager.photoViewCellIconDic;
    }
    HXPhotoModel *model = self.objs[indexPath.item];
    model.rowCount = self.manager.rowCount;
    cell.delegate = self;
    cell.model = model;
    cell.singleSelected = self.manager.singleSelected;
    
    return cell;
}
- (void)collectionView:(UICollectionView *)collectionView prefetchItemsAtIndexPaths:(NSArray<NSIndexPath *> *)indexPaths {
//    NSMutableArray *assets = [NSMutableArray array];
//    HXPhotoModel *model;
//    for (NSIndexPath *indexPath in indexPaths) {
//        model = self.objs[indexPath.item];
//        model.rowCount = self.manager.rowCount;
//        if (model.type != HXPhotoModelMediaTypeCamera && model.type != HXPhotoModelMediaTypeCameraPhoto && model.type != HXPhotoModelMediaTypeCameraVideo) {
//            [model prefetchThumbImage];
//            [assets addObject:model.asset];
//        }
//    }
//    [self.cachingManager startCachingImagesForAssets:assets targetSize:model.requestSize contentMode:PHImageContentModeAspectFill options:self.option];
}
- (void)collectionView:(UICollectionView *)collectionView cancelPrefetchingForItemsAtIndexPaths:(NSArray<NSIndexPath *> *)indexPaths {
//    if (self.selectOtherAlbum) {
//        self.selectOtherAlbum = NO;
//        return;
//    }
//    NSMutableArray *assets = [NSMutableArray array];
//    HXPhotoModel *model;
//    for (NSIndexPath *indexPath in indexPaths) {
//        model = self.objs[indexPath.item];
////        [model cancelImageRequest];
//        if (!model.selected && model.type != HXPhotoModelMediaTypeCamera && model.thumbPhoto) {
//            model.thumbPhoto = nil;
//        }
//    }
//    [self.cachingManager stopCachingImagesForAssets:assets targetSize:model.requestSize contentMode:PHImageContentModeAspectFill options:self.option];
}
- (void)collectionView:(UICollectionView *)collectionView willDisplayCell:(nonnull UICollectionViewCell *)cell forItemAtIndexPath:(nonnull NSIndexPath *)indexPath {
    if (self.manager.open3DTouchPreview) {
        if (self.responseTraitCollection) {
            if (self.responseForceTouchCapability) {
                if (self.isCapabilityAvailable) {
                    HXPhotoViewCell *myCell = (HXPhotoViewCell *)cell;
                    HXPhotoModel *model = self.objs[indexPath.item];
                    if (model.type != HXPhotoModelMediaTypeCamera) {
                        myCell.previewingContext = [self registerForPreviewingWithDelegate:self sourceView:myCell];
                        myCell.firstRegisterPreview = YES;
                    }
                }
            }
        }
    }
}
- (void)collectionView:(UICollectionView *)collectionView didEndDisplayingCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath {
    HXPhotoViewCell *myCell = (HXPhotoViewCell *)cell;
//    if (myCell.requestID) {
//        [[PHImageManager defaultManager] cancelImageRequest:myCell.requestID];
//        myCell.requestID = -1;
//    }
//    [myCell.model cancelImageRequest];
    if (!myCell.model.selected && myCell.model.type != HXPhotoModelMediaTypeCamera && myCell.model.thumbPhoto) {
        myCell.model.thumbPhoto = nil;
    }
    if (self.manager.open3DTouchPreview) {
        if (myCell.firstRegisterPreview) {
            if (myCell.previewingContext) {
                [self unregisterForPreviewingWithContext:myCell.previewingContext];
                myCell.previewingContext = nil;
                myCell.firstRegisterPreview = NO;
            }
        }
    }
}
- (UIViewController *)previewingContext:(id<UIViewControllerPreviewing>)previewingContext viewControllerForLocation:(CGPoint)location {
    HXPhotoViewCell *cell = (HXPhotoViewCell *)previewingContext.sourceView;
    NSIndexPath *index = [self.collectionView indexPathForCell:cell]; 
    if (!cell || cell.model.type == HXPhotoModelMediaTypeCamera) {
        return nil;
    }
    HXPhotoModel *model = self.objs[index.item];
    self.previewImg = [[UIImageView alloc] init];
    self.previewImg.frame = CGRectMake(0, 0, model.endImageSize.width, model.endImageSize.height);
    
    if (model.type == HXPhotoModelMediaTypeCameraPhoto || model.type == HXPhotoModelMediaTypeCameraVideo) {
        HXPhotoViewCell *cell = (HXPhotoViewCell *)[previewingContext sourceView];
        self.previewImg.image = cell.imageView.image;
    }
    __weak typeof(self) weakSelf = self;
    [HXPhotoTools getPhotoForPHAsset:model.asset size:CGSizeMake(model.endImageSize.width * 1.5, model.endImageSize.height * 1.5) completion:^(UIImage *image, NSDictionary *info) {
        weakSelf.previewImg.image = image;
    }];
    [NSThread sleepForTimeInterval:0.2];
    CGRect rect = CGRectMake(0, 0, previewingContext.sourceView.frame.size.width, previewingContext.sourceView.frame.size.height);
    previewingContext.sourceRect = rect;
    if (self.manager.singleSelected) {
        if (model.type == HXPhotoModelMediaTypeCameraVideo || model.type == HXPhotoModelMediaTypeVideo) {
            HXVideoPreviewViewController *showVC = [[HXVideoPreviewViewController alloc] init];
            showVC.preferredContentSize = model.endImageSize;
            showVC.isTouch = YES;
            [showVC.view addSubview:self.previewImg];
            return showVC;
        }else {
            HXPhotoEditViewController *vc = [[HXPhotoEditViewController alloc] init];
            vc.preferredContentSize = model.endImageSize;
            vc.model = model; 
            vc.coverImage = self.previewImg.image;
            vc.photoManager = self.manager;
            [vc.view addSubview:self.previewImg];
            return vc;
        }
    }
    
    if ((model.type == HXPhotoModelMediaTypePhoto || model.type == HXPhotoModelMediaTypePhotoGif) || (model.type == HXPhotoModelMediaTypeCameraPhoto || model.type == HXPhotoModelMediaTypeLivePhoto)) {
        HXPhotoPreviewViewController *showVC = [[HXPhotoPreviewViewController alloc] init];
        showVC.preferredContentSize = model.endImageSize;
        showVC.isTouch = YES;
        [showVC.view addSubview:self.previewImg];
        return showVC;
    }else if (model.type == HXPhotoModelMediaTypeVideo || model.type == HXPhotoModelMediaTypeCameraVideo){
        HXVideoPreviewViewController *showVC = [[HXVideoPreviewViewController alloc] init];
        showVC.preferredContentSize = model.endImageSize; 
        showVC.isTouch = YES;
        [showVC.view addSubview:self.previewImg];
        return showVC;
    }else {
        return nil;
    }
}
- (void)previewingContext:(id<UIViewControllerPreviewing>)previewingContext commitViewController:(UIViewController *)viewControllerToCommit {
    NSIndexPath *index = [self.collectionView indexPathForCell:(UICollectionViewCell *)[previewingContext sourceView]];
    self.currentIndexPath = index;
    [self.previewImg removeFromSuperview];
    HXPhotoModel *model = self.objs[index.item];
    if (!self.manager.singleSelected) {
        if (model.type == HXPhotoModelMediaTypeVideo || model.type == HXPhotoModelMediaTypeCameraVideo) {
            HXVideoPreviewViewController *vc = (HXVideoPreviewViewController *)viewControllerToCommit;
            vc.manager = self.manager;
            vc.model = model;
            if (model.type == HXPhotoModelMediaTypeCameraVideo) {
                vc.isCamera = YES;
            }
            [vc setup];
            if (self.previewImg.image) {
                vc.coverImage = self.previewImg.image;
            }else {
                HXPhotoViewCell *cell = (HXPhotoViewCell *)[previewingContext sourceView];
                vc.coverImage = cell.imageView.image;
            }
            vc.delegate = self;
            vc.playBtn.selected = YES;
            [vc selectClick];
            self.navigationController.delegate = vc;
        }else if ((model.type == HXPhotoModelMediaTypePhoto || model.type == HXPhotoModelMediaTypePhotoGif) || (model.type == HXPhotoModelMediaTypeCameraPhoto || model.type == HXPhotoModelMediaTypeLivePhoto)) {
            HXPhotoPreviewViewController *vc = (HXPhotoPreviewViewController *)viewControllerToCommit;
            vc.modelList = self.photos;
            vc.index = [self.photos indexOfObject:model];
            vc.manager = self.manager;
            if (self.previewImg.image) {
                vc.gifCoverImage = self.previewImg.image;
            }else {
                HXPhotoViewCell *cell = (HXPhotoViewCell *)[previewingContext sourceView];
                vc.gifCoverImage = cell.imageView.image;
            }
            [vc setup];
            vc.delegate = self;
            [vc selectClick];
            self.navigationController.delegate = vc;
        }
    }else {
        if (model.type == HXPhotoModelMediaTypeVideo || model.type == HXPhotoModelMediaTypeCameraVideo) {
            HXVideoPreviewViewController *vc = (HXVideoPreviewViewController *)viewControllerToCommit;
            vc.manager = self.manager;
            vc.model = model;
            if (model.type == HXPhotoModelMediaTypeCameraVideo) {
                vc.isCamera = YES;
            }
            [vc setup];
            vc.delegate = self;
            if (self.previewImg.image) {
                vc.coverImage = self.previewImg.image;
            }else {
                HXPhotoViewCell *cell = (HXPhotoViewCell *)[previewingContext sourceView];
                vc.coverImage = cell.imageView.image;
            }
            vc.playBtn.selected = YES;
            self.navigationController.delegate = vc;
        }else {
            HXPhotoEditViewController *vc = (HXPhotoEditViewController *)viewControllerToCommit;
            vc.delegate = self;
        }
    }
    [self showViewController:viewControllerToCommit sender:self];
} 
- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    HXPhotoViewCell *cell = (HXPhotoViewCell *)[self.collectionView cellForItemAtIndexPath:indexPath];
    self.currentIndexPath = indexPath;
    HXPhotoModel *model = self.objs[indexPath.item];
    if (self.manager.singleSelected) {
        if (model.type == HXPhotoModelMediaTypeCamera) {
            [self goCameraViewController]; 
        }else if (model.type == HXPhotoModelMediaTypeVideo) {
            HXVideoPreviewViewController *vc = [[HXVideoPreviewViewController alloc] init];
            vc.coverImage = cell.imageView.image;
            vc.manager = self.manager;
            vc.delegate = self;
            vc.model = model;
            self.navigationController.delegate = vc;
            [self.navigationController pushViewController:vc animated:YES];
        }else if (model.type == HXPhotoModelMediaTypeCameraVideo) {
            HXVideoPreviewViewController *vc = [[HXVideoPreviewViewController alloc] init];
            vc.coverImage = cell.imageView.image;
            vc.manager = self.manager;
            vc.delegate = self;
            vc.model = model;
            vc.isCamera = YES;
            self.navigationController.delegate = vc;
            [self.navigationController pushViewController:vc animated:YES];
        }else {
            HXPhotoEditViewController *vc = [[HXPhotoEditViewController alloc] init];
            vc.model = model;
            vc.delegate = self;
            vc.coverImage = cell.imageView.image;
            vc.photoManager = self.manager;
            [self.navigationController pushViewController:vc animated:YES];
        }
        return;
    }
    if (model.type == HXPhotoModelMediaTypePhoto || (model.type == HXPhotoModelMediaTypePhotoGif || model.type == HXPhotoModelMediaTypeLivePhoto)) {
        HXPhotoPreviewViewController *vc = [[HXPhotoPreviewViewController alloc] init];
        vc.modelList = self.photos;
        vc.index = [self.photos indexOfObject:model];
        vc.delegate = self;
        vc.manager = self.manager;
        self.navigationController.delegate = vc;
        [self.navigationController pushViewController:vc animated:YES];
    }else if (model.type == HXPhotoModelMediaTypeVideo){
        HXVideoPreviewViewController *vc = [[HXVideoPreviewViewController alloc] init];
        vc.coverImage = cell.imageView.image;
        vc.manager = self.manager;
        vc.delegate = self;
        vc.model = model;
        self.navigationController.delegate = vc;
        [self.navigationController pushViewController:vc animated:YES];
    }else if (model.type == HXPhotoModelMediaTypeCameraPhoto){
        HXPhotoPreviewViewController *vc = [[HXPhotoPreviewViewController alloc] init];
        vc.modelList = self.photos;
        vc.index = [self.photos indexOfObject:model];
        vc.delegate = self;
        vc.manager = self.manager;
        self.navigationController.delegate = vc;
        [self.navigationController pushViewController:vc animated:YES];
    }else if (model.type == HXPhotoModelMediaTypeCameraVideo) {
        HXVideoPreviewViewController *vc = [[HXVideoPreviewViewController alloc] init];
        vc.coverImage = cell.imageView.image;
        vc.manager = self.manager;
        vc.delegate = self;
        vc.model = model;
        vc.isCamera = YES;
        self.navigationController.delegate = vc;
        [self.navigationController pushViewController:vc animated:YES];
    }else if (model.type == HXPhotoModelMediaTypeCamera) {
        [self goCameraViewController];
    }
}
- (void)goCameraViewController {
    if(![UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
        [self.view showImageHUDText:[NSBundle hx_localizedStringForKey:@"无法使用相机!"]];
        return;
    }
    AVAuthorizationStatus authStatus = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
    if (authStatus == AVAuthorizationStatusRestricted || authStatus == AVAuthorizationStatusDenied) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:[NSBundle hx_localizedStringForKey:@"无法使用相机"] message:[NSBundle hx_localizedStringForKey:@"请在设置-隐私-相机中允许访问相机"] delegate:self cancelButtonTitle:[NSBundle hx_localizedStringForKey:@"取消"] otherButtonTitles:[NSBundle hx_localizedStringForKey:@"设置"], nil];
        [alert show];
        return;
    }
    HXCameraType type = 0;
    if (self.manager.type == HXPhotoManagerSelectedTypePhotoAndVideo) {
        if (self.photos.count > 0 && self.videos.count > 0) {
            type = HXCameraTypePhotoAndVideo;
        }else if (self.videos.count > 0) {
            type = HXCameraTypeVideo;
        }else {
            type = HXCameraTypePhotoAndVideo;
        }
    }else if (self.manager.type == HXPhotoManagerSelectedTypePhoto) {
        type = HXCameraTypePhoto;
    }else if (self.manager.type == HXPhotoManagerSelectedTypeVideo) {
        type = HXCameraTypeVideo;
    }
    if (self.manager.cameraType == HXPhotoManagerCameraTypeFullScreen) {
        HXFullScreenCameraViewController *vc = [[HXFullScreenCameraViewController alloc] init];
        vc.delegate = self;
        vc.type = type;
        vc.photoManager = self.manager;
        if (self.manager.singleSelected) {
            [self presentViewController:[[UINavigationController alloc] initWithRootViewController:vc] animated:YES completion:nil];
        }else {
            [self presentViewController:vc animated:YES completion:nil];
        }
    }else if (self.manager.cameraType == HXPhotoManagerCameraTypeHalfScreen) {
        HXCameraViewController *vc = [[HXCameraViewController alloc] init];
        vc.delegate = self;
        vc.type = type;
        vc.photoManager = self.manager;
        
        if (self.manager.singleSelected) {
            [self presentViewController:[[UINavigationController alloc] initWithRootViewController:vc] animated:YES completion:nil];
        }else {
            [self presentViewController:vc animated:YES completion:nil];
        }
    }else {
        // 跳转到相机或相册页面
        NSString *requiredMediaTypeImage = ( NSString *)kUTTypeImage;
        NSString *requiredMediaTypeMovie = ( NSString *)kUTTypeMovie;
        NSArray *arrMediaTypes;
        if (type == HXCameraTypePhoto) {
            arrMediaTypes=[NSArray arrayWithObjects:requiredMediaTypeImage,nil];
        }else if (type == HXCameraTypePhotoAndVideo) {
            arrMediaTypes=[NSArray arrayWithObjects:requiredMediaTypeImage, requiredMediaTypeMovie,nil];
        }else if (type == HXCameraTypeVideo) {
            arrMediaTypes=[NSArray arrayWithObjects:requiredMediaTypeMovie,nil];
        }
        
        [self.imagePickerController setMediaTypes:arrMediaTypes];
        [self presentViewController:self.imagePickerController animated:YES completion:nil];
    }
}
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString *,id> *)info {
    [picker dismissViewControllerAnimated:YES completion:nil];
    
    NSString *mediaType = [info objectForKey:UIImagePickerControllerMediaType];
    HXPhotoModel *model = [[HXPhotoModel alloc] init];
    if ([mediaType isEqualToString:(NSString *)kUTTypeImage]) {
        UIImage *image = [info objectForKey:UIImagePickerControllerOriginalImage];
        model.type = HXPhotoModelMediaTypeCameraPhoto;
        model.subType = HXPhotoModelMediaSubTypePhoto;
        model.thumbPhoto = image;
        model.imageSize = image.size;
        model.previewPhoto = image;
        model.cameraIdentifier = [self videoOutFutFileName];
    }else  if ([mediaType isEqualToString:(NSString *)kUTTypeMovie]) {
        NSURL *url = info[UIImagePickerControllerMediaURL];
        model.type = HXPhotoModelMediaTypeCameraVideo;
        model.subType = HXPhotoModelMediaSubTypeVideo;
        MPMoviePlayerController *player = [[MPMoviePlayerController alloc]initWithContentURL:url] ;
        player.shouldAutoplay = NO;
        UIImage  *image = [player thumbnailImageAtTime:1.0 timeOption:MPMovieTimeOptionNearestKeyFrame];
        NSDictionary *opts = [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:NO]
                                                         forKey:AVURLAssetPreferPreciseDurationAndTimingKey];
        AVURLAsset *urlAsset = [AVURLAsset URLAssetWithURL:url options:opts];
        float second = 0;
        second = urlAsset.duration.value/urlAsset.duration.timescale;
        NSString *videoTime = [HXPhotoTools getNewTimeFromDurationSecond:second];
        model.videoURL = url;
        model.videoTime = videoTime;
        model.thumbPhoto = image;
        model.imageSize = image.size;
        model.previewPhoto = image;
        model.cameraIdentifier = [self videoOutFutFileName];
        //        if (second < 3) {
        //            [[self viewController:self].view showImageHUDText:[NSBundle hx_localizedStringForKey:@"录制时间少于3秒"]];
        //            return;
        //        }
    }
    [self cameraDidNextClick:model];
}
- (NSString *)videoOutFutFileName {
    NSString *fileName = @"";
    NSDate *nowDate = [NSDate date];
    NSString *dateStr = [NSString stringWithFormat:@"%ld", (long)[nowDate timeIntervalSince1970]];
    NSString *numStr = [NSString stringWithFormat:@"%d",arc4random()%10000];
    fileName = [fileName stringByAppendingString:dateStr];
    fileName = [fileName stringByAppendingString:numStr];
    return fileName;
}
- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [picker dismissViewControllerAnimated:YES completion:nil];
}
/**
 通过相机拍照的图片或视频
 
 @param model 图片/视频 模型
 */
- (void)fullScreenCameraDidNextClick:(HXPhotoModel *)model {
    [self cameraDidNextClick:model];
}
- (void)cameraDidNextClick:(HXPhotoModel *)model {
    if (self.manager.saveSystemAblum) {
        if ([PHPhotoLibrary authorizationStatus] != PHAuthorizationStatusAuthorized) {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.4 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [self.view showImageHUDText:[NSBundle hx_localizedStringForKey:@"保存失败，无法访问照片\n请前往设置中允许访问照片"]];
            });
            return;
        }
        if (self.albumModel.index != 0) {
            [self didTableViewCellClick:self.albums.firstObject animate:NO];
            self.albumView.currentIndex = 0;
            self.albumView.list = self.albums;
        }
        __weak typeof(self) weakSelf = self;
        if (model.type == HXPhotoModelMediaTypeCameraPhoto) {
            [HXPhotoTools saveImageToAlbum:model.previewPhoto completion:^{
                NSSLog(@"保存成功");
            } error:^{
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.4 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    [weakSelf.view showImageHUDText:[NSBundle hx_localizedStringForKey:@"照片保存失败!"]];
                });
            }];
        }else {
            [HXPhotoTools saveVideoToAlbum:model.videoURL completion:^{
                NSSLog(@"保存成功");
            } error:^{ 
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.4 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    [weakSelf.view showImageHUDText:[NSBundle hx_localizedStringForKey:@"视频保存失败!"]];
                });
            }];
        }
        return;
    }
    if (self.manager.singleSelected && model.type == HXPhotoModelMediaTypeCameraPhoto) {
        [self.manager.selectedCameraList addObject:model];
        [self.manager.selectedCameraPhotos addObject:model];
        [self.manager.selectedPhotos addObject:model];
        [self.manager.selectedList addObject:model];
        [self didNextClick:self.rightBtn];
        return;
    }
    if (self.albumModel.index != 0) {
        [self didTableViewCellClick:self.albums.firstObject animate:NO];
        self.albumView.currentIndex = 0;
        self.albumView.list = self.albums;
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
    [self.collectionView reloadData];
    [self changeButtonClick:model];
}

/**
 点击相册列表的代理
 
 @param model 点击的相册模型
 @param anim 是否需要展开动画
 */
- (void)didTableViewCellClick:(HXAlbumModel *)model animate:(BOOL)anim {
    if (anim) {
        [self pushAlbumList:self.titleBtn];
    }
    if ([self.albumModel.result isEqual:model.result]) {
        return;
    }
    // 当前相册选中的个数
    self.currentSelectCount = model.selectedCount;
    self.albumModel = model;
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
        transition.duration = 0.2;
        transition.delegate = weakSelf;
        transition.subtype = kCATransitionFade;
        [[weakSelf.collectionView layer] addAnimation:transition forKey:@""];
        weakSelf.selectOtherAlbum = YES;
        [weakSelf.collectionView reloadData];
        [weakSelf.collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:0] atScrollPosition:UICollectionViewScrollPositionTop animated:NO];
    }];
}
- (void)animationDidStop:(CAAnimation *)anim finished:(BOOL)flag {
    if (flag) {
        [self.collectionView.layer removeAllAnimations];
    }
}

/**
 查看图片时 选中或取消选中时的代理
 
 @param model 当前操作的模型
 @param state 状态
 */
- (void)didSelectedClick:(HXPhotoModel *)model AddOrDelete:(BOOL)state {
    if (state) { // 选中
        self.albumModel.selectedCount++;
    }else { // 取消选中
        self.albumModel.selectedCount--;
    }
    model.selected = state;
    [self.collectionView reloadItemsAtIndexPaths:@[[NSIndexPath indexPathForItem:[self.objs indexOfObject:model] inSection:0]]];
    // 改变 预览、原图 按钮的状态
    [self changeButtonClick:model];
}
/**
 cell选中代理
 */
- (void)cellDidSelectedBtnClick:(HXPhotoViewCell *)cell Model:(HXPhotoModel *)model {
    if (!cell.selectBtn.selected) { // 弹簧果冻动画效果
        NSString *str = [HXPhotoTools maximumOfJudgment:model manager:self.manager];
        if (str) {
            [self.view showImageHUDText:str];
            return;
        }
        [cell.maskView.layer removeAllAnimations];
        cell.maskView.hidden = NO;
        cell.maskView.alpha = 0;
        [UIView animateWithDuration:0.15 animations:^{
            cell.maskView.alpha = 1;
        }];
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
        if (model.type != HXPhotoModelMediaTypeCameraVideo && model.type != HXPhotoModelMediaTypeCameraPhoto) {
            model.thumbPhoto = cell.imageView.image;
        }
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
        if (model.type != HXPhotoModelMediaTypeCameraVideo && model.type != HXPhotoModelMediaTypeCameraPhoto) {
            model.thumbPhoto = nil;
            model.previewPhoto = nil;
        }
        if (model.type == HXPhotoModelMediaTypeLivePhoto) {
            [cell stopLivePhoto];
        }
        if ((model.type == HXPhotoModelMediaTypePhoto || model.type == HXPhotoModelMediaTypePhotoGif) || (model.type == HXPhotoModelMediaTypeVideo || model.type == HXPhotoModelMediaTypeLivePhoto)) {
            if (model.type == HXPhotoModelMediaTypePhoto || model.type == HXPhotoModelMediaTypePhotoGif || model.type == HXPhotoModelMediaTypeLivePhoto) {
                [self.manager.selectedPhotos removeObject:model];
            }else if (model.type == HXPhotoModelMediaTypeVideo) {
                [self.manager.selectedVideos removeObject:model];
            }
        }else if (model.type == HXPhotoModelMediaTypeCameraPhoto || model.type == HXPhotoModelMediaTypeCameraVideo) {
            if (model.type == HXPhotoModelMediaTypeCameraPhoto) {
                [self.manager.selectedPhotos removeObject:model];
                [self.manager.selectedCameraPhotos removeObject:model];
            }else if (model.type == HXPhotoModelMediaTypeCameraVideo) {
                [self.manager.selectedVideos removeObject:model];
                [self.manager.selectedCameraVideos removeObject:model];
            }
            [self.manager.selectedCameraList removeObject:model];
        }
        self.albumModel.selectedCount--;
        [self.manager.selectedList removeObject:model];
     }
    // 改变 预览、原图 按钮的状态
    [self changeButtonClick:model];
}

/**
 cell改变livephoto的状态

 @param model 模型
 */
- (void)cellChangeLivePhotoState:(HXPhotoModel *)model {
    HXPhotoModel *PHModel = [self.manager.selectedList objectAtIndex:[self.manager.selectedList indexOfObject:model]];
    PHModel.isCloseLivePhoto = model.isCloseLivePhoto;
    
    HXPhotoModel *PHModel1 = [self.manager.selectedPhotos objectAtIndex:[self.manager.selectedPhotos indexOfObject:model]];
    PHModel1.isCloseLivePhoto = model.isCloseLivePhoto;
//    for (HXPhotoModel *PHModel in self.manager.selectedList) {
//        if ([model.asset.localIdentifier isEqualToString:PHModel.asset.localIdentifier]) {
//            PHModel.isCloseLivePhoto = model.isCloseLivePhoto;
//            break;
//        }
//    }
//    for (HXPhotoModel *PHModel in self.manager.selectedPhotos) {
//        if ([model.asset.localIdentifier isEqualToString:PHModel.asset.localIdentifier]) {
//            PHModel.isCloseLivePhoto = model.isCloseLivePhoto;
//            break;
//        }
//    }
}

/**
 改变 预览、原图 按钮的状态
 
 @param model 选中的模型
 */
- (void)changeButtonClick:(HXPhotoModel *)model {
    self.isSelectedChange = YES; // 记录在当前相册是否操作过
    if (self.manager.selectedList.count > 0) { // 选中数组已经有值时
        if (self.manager.type != HXPhotoManagerSelectedTypeVideo) {
//            if (self.manager.type == HXPhotoManagerSelectedTypePhotoAndVideo) {
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
//            }else {
//                self.bottomView.originalBtn.enabled = YES;
//            }
        }
        self.bottomView.previewBtn.enabled = YES;
        
        
        self.navItem.rightBarButtonItem.enabled = YES;
        [self.rightBtn setTitle:[NSString stringWithFormat:@"%@(%ld)",[NSBundle hx_localizedStringForKey:@"下一步"],self.manager.selectedList.count] forState:UIControlStateNormal];
        [self.rightBtn setBackgroundColor:[UIColor colorWithRed:253/255.0 green:142/255.0 blue:36/255.0 alpha:1]];
        self.rightBtn.layer.borderWidth = 0;
        CGFloat rightBtnH = self.rightBtn.frame.size.height;
        CGFloat rightBtnW = [HXPhotoTools getTextWidth:self.rightBtn.currentTitle height:rightBtnH fontSize:14];
        self.rightBtn.frame = CGRectMake(0, 0, rightBtnW + 20, rightBtnH);
    }else { // 没有选中时 全部恢复成初始状态
        [self changeOriginalState:NO IsChange:NO];
        self.manager.isOriginal = NO;
        self.bottomView.originalBtn.selected = NO;
        self.bottomView.previewBtn.enabled = NO;
        self.bottomView.originalBtn.enabled = NO;
        self.navItem.rightBarButtonItem.enabled = NO;
        [self.rightBtn setTitle:[NSBundle hx_localizedStringForKey:@"下一步"] forState:UIControlStateNormal];
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
- (void)didPhotoBottomViewClick:(HXPhotoBottomType)type Button:(UIButton *)button {
    if (type == HXPhotoBottomTyPepreview) { // 预览
        self.isPreview = YES; // 自定义转场动画时用到的属性
        // 判断选中数组中有没有图片 如果有图片则只预览选中的图片 反之 视频
        if (self.manager.selectedPhotos.count > 0) {
            HXPhotoPreviewViewController *vc = [[HXPhotoPreviewViewController alloc] init];
            vc.isPreview = self.isPreview;
            vc.modelList = self.manager.selectedPhotos.mutableCopy;
            vc.index = 0;
            vc.delegate = self;
            vc.manager = self.manager;
            self.navigationController.delegate = vc;
            [self.navigationController pushViewController:vc animated:YES];
        }else {
            HXVideoPreviewViewController *vc = [[HXVideoPreviewViewController alloc] init];
            HXPhotoModel *model = self.manager.selectedVideos.firstObject;
            HXPhotoViewCell *cell = (HXPhotoViewCell *)[self.collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForItem:[self.objs indexOfObject:model] inSection:0]];
            vc.coverImage = cell.imageView.image;
            vc.isPreview = self.isPreview;
            vc.manager = self.manager;
            vc.delegate = self;
            vc.model = model;
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
- (void)previewVideoDidNextClick {
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
            [self.bottomView.originalBtn setTitle:[NSBundle hx_localizedStringForKey:@"原图"] forState:UIControlStateNormal];
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
                CGFloat totalW = [HXPhotoTools getTextWidth:[NSString stringWithFormat:@"(%@)",totalBytes] height:originalBtnH fontSize:14];
                [weakSelf.bottomView.originalBtn setTitle:[NSString stringWithFormat:@"%@(%@)",[NSBundle hx_localizedStringForKey:@"原图"],totalBytes] forState:UIControlStateNormal];
                [weakSelf.indica stopAnimating];
                weakSelf.indica.hidden = YES;
                weakSelf.bottomView.originalBtn.frame = CGRectMake(originalBtnX, originalBtnY, originalBtnW+totalW, originalBtnH);
            });
        }];
    }else {// 取消选中 恢复成初始状态
        [self.indica stopAnimating];
        self.indica.hidden = YES;
        self.manager.photosTotalBtyes = nil;
        [self.bottomView.originalBtn setTitle:[NSBundle hx_localizedStringForKey:@"原图"] forState:UIControlStateNormal];
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
#pragma mark - < HXPhotoEditViewControllerDelegate >
- (void)editViewControllerDidNextClick:(HXPhotoModel *)model {
    [self.manager.selectedCameraList addObject:model];
    [self.manager.selectedCameraPhotos addObject:model];
    [self.manager.selectedPhotos addObject:model];
    [self.manager.selectedList addObject:model];
    [self didNextClick:self.rightBtn];
}

/**
 点击下一步执行的方法
 
 @param button 下一步按钮
 */
- (void)didNextClick:(UIButton *)button {
    [self cleanSelectedList];
    self.manager.selectPhoto = NO;
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)cleanSelectedList {
    // 如果通过相机拍的数组为空 则清空所有关于相机的数组
    if (self.manager.selectedCameraList.count == 0) {
        [self.manager.cameraList removeAllObjects];
        [self.manager.cameraVideos removeAllObjects];
        [self.manager.cameraPhotos removeAllObjects];
    }
    if (!self.manager.singleSelected) {
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
    }else {
        if ([self.delegate respondsToSelector:@selector(photoViewControllerDidNext:Photos:Videos:Original:)]) {
            [self.delegate photoViewControllerDidNext:self.manager.selectedList.mutableCopy Photos:self.manager.selectedPhotos.mutableCopy Videos:self.manager.selectedVideos.mutableCopy Original:self.manager.isOriginal];
        }
    }
}

/**
 小菊花
 
 @return 小菊花
 */
- (UIActivityIndicatorView *)indica {
    if (!_indica) {
        _indica = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
        CGFloat indicaX = self.bottomView.originalBtn.titleLabel.frame.origin.x + [HXPhotoTools getTextWidth:[NSBundle hx_localizedStringForKey:@"原图"] height:self.bottomView.originalBtn.frame.size.height / 2 fontSize:14] + 5;
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
- (UIButton *)rightBtn {
    if (!_rightBtn) {
        _rightBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [_rightBtn setTitle:[NSBundle hx_localizedStringForKey:@"下一步"] forState:UIControlStateNormal];
        [_rightBtn setTitleColor:self.manager.UIManager.navRightBtnNormalTitleColor forState:UIControlStateNormal];
        [_rightBtn setTitleColor:self.manager.UIManager.navRightBtnDisabledTitleColor forState:UIControlStateDisabled];
        [_rightBtn setTitleColor:[[UIColor lightGrayColor] colorWithAlphaComponent:0.5] forState:UIControlStateHighlighted];
        _rightBtn.layer.masksToBounds = YES;
        _rightBtn.layer.cornerRadius = 2;
        _rightBtn.layer.borderWidth = 0.5;
        _rightBtn.layer.borderColor = self.manager.UIManager.navRightBtnBorderColor.CGColor;
        [_rightBtn setBackgroundColor:self.manager.UIManager.navRightBtnDisabledBgColor];
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
- (UIView *)albumsBgView {
    if (!_albumsBgView) {
        _albumsBgView = [[UIView alloc] initWithFrame:CGRectMake(0, 64, self.view.frame.size.width, self.view.frame.size.height - 64)];
        _albumsBgView.hidden = YES;
        _albumsBgView.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.6];
        _albumsBgView.alpha = 0;
        [_albumsBgView addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(didAlbumsBgViewClick)]];
    }
    return _albumsBgView;
}

/**
 点击背景时
 */
- (void)didAlbumsBgViewClick {
    [self pushAlbumList:self.titleBtn];
}

@end

@interface HXPhotoBottomView ()
@property (strong, nonatomic) UIVisualEffectView *effectView;
@property (strong, nonatomic) HXPhotoManager *manager;
@end

@implementation HXPhotoBottomView

- (instancetype)initWithFrame:(CGRect)frame manager:(HXPhotoManager *)manager {
    self = [super initWithFrame:frame];
    if (self) {
        self.manager = manager;
        [self setup];
    }
    return self;
}
#pragma mark - < 懒加载 >
- (void)setup {
    if (self.manager.UIManager.blurEffect) {
        UIBlurEffect *effect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleExtraLight];
        self.effectView = [[UIVisualEffectView alloc] initWithEffect:effect];
        self.effectView.frame = self.bounds;
        [self addSubview:self.effectView];
    }else {
        self.backgroundColor = self.manager.UIManager.bottomViewBgColor;
    }
    
    UIButton *previewBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [previewBtn setTitle:[NSBundle hx_localizedStringForKey:@"预览"] forState:UIControlStateNormal];
    [previewBtn setTitleColor:self.manager.UIManager.previewBtnNormalTitleColor forState:UIControlStateNormal];
    [previewBtn setTitleColor:self.manager.UIManager.previewBtnDisabledTitleColor forState:UIControlStateDisabled];
    [previewBtn setBackgroundImage:[HXPhotoTools hx_imageNamed:self.manager.UIManager.previewBtnNormalBgImageName] forState:UIControlStateNormal];
    [previewBtn setBackgroundImage:[HXPhotoTools hx_imageNamed:self.manager.UIManager.previewBtnDisabledBgImageName] forState:UIControlStateDisabled];
    previewBtn.titleLabel.font = [UIFont systemFontOfSize:14];
    [previewBtn addTarget:self action:@selector(didPreviewClick:) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:previewBtn];
    CGFloat previewBtnX = 10;
    CGFloat previewBtnW = [HXPhotoTools getTextWidth:previewBtn.currentTitle height:15 fontSize:14] + 20;
    if (previewBtnW < previewBtn.currentBackgroundImage.size.width) {
        previewBtnW = previewBtn.currentBackgroundImage.size.width;
    }
    CGFloat previewBtnH = previewBtn.currentBackgroundImage.size.height;
    previewBtn.frame = CGRectMake(previewBtnX, 0, previewBtnW, previewBtnH);
    previewBtn.center = CGPointMake(previewBtn.center.x, self.frame.size.height / 2);
    self.previewBtn = previewBtn;
    
    UIButton *originalBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [originalBtn setBackgroundColor:self.manager.UIManager.originalBtnBgColor];
    [originalBtn setTitle:[NSBundle hx_localizedStringForKey:@"原图"] forState:UIControlStateNormal];
    [originalBtn setTitleColor:self.manager.UIManager.originalBtnNormalTitleColor forState:UIControlStateNormal];
    [originalBtn setTitleColor:self.manager.UIManager.originalBtnDisabledTitleColor forState:UIControlStateDisabled];
    originalBtn.layer.masksToBounds = YES;
    originalBtn.layer.cornerRadius = 2.2;
    originalBtn.layer.borderColor = self.manager.UIManager.originalBtnBorderColor.CGColor;
    originalBtn.layer.borderWidth = 0.7;
    [originalBtn setImage:[HXPhotoTools hx_imageNamed:self.manager.UIManager.originalBtnNormalImageName] forState:UIControlStateNormal];
    [originalBtn setImage:[HXPhotoTools hx_imageNamed:self.manager.UIManager.originalBtnSelectedImageName] forState:UIControlStateSelected];
    originalBtn.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
    originalBtn.titleEdgeInsets = UIEdgeInsetsMake(0, 8 + 8, 0, 0);
    originalBtn.imageEdgeInsets = UIEdgeInsetsMake(0, 8, 0, 0);
    originalBtn.titleLabel.font = [UIFont systemFontOfSize:14];
    [originalBtn addTarget:self action:@selector(didOriginalClick:) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:originalBtn];
    CGFloat originalBtnX = CGRectGetMaxX(previewBtn.frame)+10;
    CGFloat originalBtnH = previewBtnH;
    CGFloat originalBtnW = [HXPhotoTools getTextWidth:originalBtn.currentTitle height:15 fontSize:14] + 35;
    if (originalBtnW < 65) {
        originalBtnW = 65;
    }
    originalBtn.frame = CGRectMake(originalBtnX, 0, originalBtnW, originalBtnH);
    originalBtn.center = CGPointMake(originalBtn.center.x, self.frame.size.height / 2);
    self.originalBtn = originalBtn;
    
    UIView *lineView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.frame.size.width, 0.5)];
    lineView.backgroundColor = [[UIColor lightGrayColor] colorWithAlphaComponent:0.5];
    [self addSubview:lineView];
}
- (void)didPreviewClick:(UIButton *)button {
    if ([self.delegate respondsToSelector:@selector(didPhotoBottomViewClick:Button:)]) {
        [self.delegate didPhotoBottomViewClick:HXPhotoBottomTyPepreview Button:button];
    }
}
- (void)didOriginalClick:(UIButton *)button {
    button.selected = !button.selected;
    if ([self.delegate respondsToSelector:@selector(didPhotoBottomViewClick:Button:)]) {
        [self.delegate didPhotoBottomViewClick:HXPhotoBottomTyOriginalPhoto Button:button];
    }
}
@end
