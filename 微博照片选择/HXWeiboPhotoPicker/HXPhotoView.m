//
//  HXPhotoView.m
//  微博照片选择
//
//  Created by 洪欣 on 17/2/17.
//  Copyright © 2017年 洪欣. All rights reserved.
//

#import "HXPhotoView.h"
#import "HXPhotoSubViewCell.h"
#import "HXPhotoViewController.h"
#import "HXPhotoPreviewViewController.h"
#import "HXVideoPreviewViewController.h"
#import "HXCameraViewController.h"
#import "UIView+HXExtension.h"
#import "HXFullScreenCameraViewController.h"
#import <MobileCoreServices/MobileCoreServices.h>
#import <MediaPlayer/MediaPlayer.h>
#import "UIImage+HXExtension.h"
#import "HXAlbumListViewController.h"
#import "HXDatePhotoPreviewViewController.h"
#import "HXCustomNavigationController.h"
#import "HXCustomCameraViewController.h"

#define iOS9Later ([UIDevice currentDevice].systemVersion.floatValue >= 9.1f)

#define Spacing 3 // 每个item的间距  !! 这个宏已经没用了, 请用HXPhotoView 的 spacing 这个属性来控制

#define LineNum 3 // 每行个数  !! 这个宏已经没用了, 请用HXPhotoView 的 lineCount 这个属性来控制

static NSString *HXPhotoSubViewCellId = @"photoSubViewCellId";
@interface HXPhotoView ()<HXCollectionViewDataSource,HXCollectionViewDelegate,HXPhotoViewControllerDelegate,HXPhotoSubViewCellDelegate,UIActionSheetDelegate,HXCameraViewControllerDelegate,UIAlertViewDelegate,HXFullScreenCameraViewControllerDelegate,UIImagePickerControllerDelegate,HXAlbumListViewControllerDelegate,HXCustomCameraViewControllerDelegate>
@property (strong, nonatomic) NSMutableArray *dataList;
@property (strong, nonatomic) NSMutableArray *photos;
@property (strong, nonatomic) NSMutableArray *videos;
@property (strong, nonatomic) HXPhotoModel *addModel;
@property (assign, nonatomic) BOOL isAddModel;
@property (assign, nonatomic) BOOL original;
@property (strong, nonatomic) UICollectionViewFlowLayout *flowLayout;
@property (assign, nonatomic) NSInteger numOfLinesOld;
@property (strong, nonatomic) NSMutableArray *networkPhotos;
@property (assign, nonatomic) BOOL downLoadComplete;
@property (strong, nonatomic) UIImage *tempCameraImage;
@property (strong, nonatomic) UIImagePickerController* imagePickerController;
@property (assign, nonatomic) BOOL isDeleteAddModel;
@end

@implementation HXPhotoView
- (UICollectionViewFlowLayout *)flowLayout {
    if (!_flowLayout) {
        _flowLayout = [[UICollectionViewFlowLayout alloc] init];
    }
    return _flowLayout;
}

- (NSMutableArray *)dataList {
    if (!_dataList) {
        _dataList = [NSMutableArray array];
    }
    return _dataList;
}

- (HXPhotoModel *)addModel {
    if (!_addModel) {
        _addModel = [[HXPhotoModel alloc] init];
        _addModel.type = HXPhotoModelMediaTypeCamera;
        if (self.manager.UIManager.photoViewAddImageName) {
            _addModel.thumbPhoto = [HXPhotoTools hx_imageNamed:self.manager.UIManager.photoViewAddImageName];
        }else {
            _addModel.thumbPhoto = [HXPhotoTools hx_imageNamed:@"compose_pic_add@2x.png"];
        }
    }
    return _addModel;
}

- (NSMutableArray *)networkPhotos {
    if (!_networkPhotos) {
        _networkPhotos = [NSMutableArray array];
    }
    return _networkPhotos;
}

+ (instancetype)photoManager:(HXPhotoManager *)manager {
    return [[self alloc] initWithManager:manager];
}
- (instancetype)initWithFrame:(CGRect)frame manager:(HXPhotoManager *)manager {
    self = [super initWithFrame:frame];
    if (self) {
        self.spacing = 3;
        self.lineCount = 3;
        self.numOfLinesOld = 0;
        self.manager = manager;
        [self.manager getImage];
        [self setup];
    }
    return self;
}
- (instancetype)initWithFrame:(CGRect)frame WithManager:(HXPhotoManager *)manager {
    self = [super initWithFrame:frame];
    if (self) {
        self.spacing = 3;
        self.lineCount = 3;
        self.numOfLinesOld = 0;
        self.manager = manager;
        [self.manager getImage];
        [self setup];
    }
    return self;
}

- (instancetype)initWithManager:(HXPhotoManager *)manager {
    self = [super init];
    if (self) {
        self.spacing = 3;
        self.lineCount = 3;
        self.numOfLinesOld = 0;
        self.manager = manager;
        [self.manager getImage];
        [self setup];
    }
    return self;
}

/**  不要使用 "initWithFrame" 这个方法初始化  */
//- (instancetype)initWithFrame:(CGRect)frame {
//    self = [super initWithFrame:frame];
//    if (self) {
//        [self setup];
//    }
//    return self;
//}

- (void)deleteAddBtn {
    [self.dataList removeObject:self.addModel];
    self.isDeleteAddModel = YES;
}

- (void)setup {
    self.tag = 9999;
    [self.dataList addObject:self.addModel];
    
    self.flowLayout.minimumLineSpacing = self.spacing;
    self.flowLayout.minimumInteritemSpacing = self.spacing;
    self.collectionView = [[HXCollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:self.flowLayout];
    self.collectionView.tag = 8888;
    self.collectionView.scrollEnabled = NO;
    self.collectionView.dataSource = self;
    self.collectionView.delegate = self;
    self.collectionView.backgroundColor = self.backgroundColor;
    [self.collectionView registerClass:[HXPhotoSubViewCell class] forCellWithReuseIdentifier:HXPhotoSubViewCellId];
    [self addSubview:self.collectionView];
    if (self.manager.networkPhotoUrls.count) {
        self.collectionView.editEnabled = NO;
        [self.networkPhotos removeAllObjects];
        for (int i = 0; i < self.manager.networkPhotoUrls.count ; i++) {
            HXPhotoModel *model = [[HXPhotoModel alloc] init];
            model.type = HXPhotoModelMediaTypeCameraPhoto;
            model.networkPhotoUrl = self.manager.networkPhotoUrls[i];
            model.cameraIdentifier = [self videoOutFutFileName];
            model.imageSize = CGSizeMake([UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.width);
            model.selected = YES;
            model.thumbPhoto = [HXPhotoTools hx_imageNamed:self.manager.UIManager.placeholderImageName];
            model.previewPhoto = model.thumbPhoto;
            [self.networkPhotos addObject:model];
        }
    }
    if (self.manager.endSelectedList.count > 0 || self.networkPhotos.count > 0) {
        [self photoViewControllerDidNext:self.manager.endSelectedList.mutableCopy Photos:self.manager.endSelectedPhotos.mutableCopy Videos:self.manager.endSelectedVideos.mutableCopy Original:self.manager.endIsOriginal];
    }
    
    __weak typeof(self) weakSelf = self;
    [self.manager setPhotoLibraryDidChangeWithPhotoView:^(NSArray *collectionChanges, BOOL selectPhoto){
        [weakSelf photoLibraryDidChange:collectionChanges selectPhoto:selectPhoto];
    }];
}

/**
 系统相册发生变化

 @param list 发生改变的相册数组
 @param selectPhoto 是否正在选择照片
 */
- (void)photoLibraryDidChange:(NSArray *)list selectPhoto:(BOOL)selectPhoto {
    for (int i = 0; i < list.count ; i++) {
        NSDictionary *dic = list[i];
        PHFetchResultChangeDetails *collectionChanges = dic[@"collectionChanges"];
        HXAlbumModel *albumModel = dic[@"model"];
        if (collectionChanges) {
            if ([collectionChanges hasIncrementalChanges]) {
                PHFetchResult *result = collectionChanges.fetchResultAfterChanges;
                
                if (collectionChanges.insertedObjects.count > 0) {
                    if (!selectPhoto) {
                        albumModel.asset = nil;
                        albumModel.result = result;
                        albumModel.count = result.count;
                    }
                    if (i == 0) {
                        if (self.manager.cameraPhoto) {
                            PHAsset *asset = collectionChanges.insertedObjects.firstObject;
                            HXPhotoModel *photoModel = [[HXPhotoModel alloc] init];
                            photoModel.albumName = albumModel.albumName;
                            photoModel.asset = asset;
                            photoModel.thumbPhoto = self.tempCameraImage;
                            photoModel.previewPhoto = self.tempCameraImage;
                            if (asset.mediaType == PHAssetMediaTypeImage) {
                                photoModel.subType = HXPhotoModelMediaSubTypePhoto;
                                if ([[asset valueForKey:@"filename"] hasSuffix:@"GIF"]) {
                                    if (self.manager.singleSelected && self.manager.singleSelecteClip) {
                                        photoModel.type = HXPhotoModelMediaTypePhoto;
                                    }else {
                                        photoModel.type = self.manager.lookGifPhoto ? HXPhotoModelMediaTypePhotoGif : HXPhotoModelMediaTypePhoto;
                                    }
                                }else {
                                    if (iOS9Later && [HXPhotoTools platform]) {
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
                                [self.manager.endSelectedPhotos addObject:photoModel];
                            }else if (asset.mediaType == PHAssetMediaTypeVideo) {
                                photoModel.subType = HXPhotoModelMediaSubTypeVideo;
                                photoModel.type = HXPhotoModelMediaTypeVideo;
                                [[PHImageManager defaultManager] requestAVAssetForVideo:asset options:nil resultHandler:^(AVAsset * _Nullable asset, AVAudioMix * _Nullable audioMix, NSDictionary * _Nullable info) {
                                    photoModel.avAsset = asset;
                                }];
                                NSString *timeLength = [NSString stringWithFormat:@"%0.0f",asset.duration];
                                photoModel.videoTime = [HXPhotoTools getNewTimeFromDurationSecond:timeLength.integerValue];
                                [self.manager.endSelectedVideos addObject:photoModel];
                            }
                            photoModel.currentAlbumIndex = albumModel.index;
                            [self.manager.endSelectedList addObject:photoModel];
                            [self photoViewControllerDidNext:self.manager.endSelectedList.mutableCopy Photos:self.manager.endSelectedPhotos.mutableCopy Videos:self.manager.endSelectedVideos.mutableCopy Original:self.manager.endIsOriginal];
                            self.manager.cameraPhoto = NO;
                        }
                    }
                }
                if (collectionChanges.removedObjects.count > 0) {
                    if (!selectPhoto) {
                        albumModel.asset = nil;
                        albumModel.result = result;
                        albumModel.count = result.count;
                    }
                    if (i == 0) {
                        for (PHAsset *asset in collectionChanges.removedObjects) {
                            NSString *property = @"asset";
                            NSPredicate *pred = [NSPredicate predicateWithFormat:@"%K = %@", property, asset];
                            NSArray *newArray = [self.manager.endSelectedList filteredArrayUsingPredicate:pred];
                            if (newArray.count > 0) {
                                HXPhotoModel *photoModel = newArray.firstObject;
                                if ((photoModel.type == HXPhotoModelMediaTypePhoto || photoModel.type == HXPhotoModelMediaTypePhotoGif) || photoModel.type == HXPhotoModelMediaTypeLivePhoto) {
                                    [self.manager.endSelectedPhotos removeObject:photoModel];
                                }else {
                                    [self.manager.endSelectedVideos removeObject:photoModel];
                                }
                                [self.manager.endSelectedList removeObject:photoModel];
                            }
                        }
                        if (self.manager.endSelectedList.count == 0) {
                            self.manager.endIsOriginal = NO;
                        }
                        [self photoViewControllerDidNext:self.manager.endSelectedList.mutableCopy Photos:self.manager.endSelectedPhotos.mutableCopy Videos:self.manager.endSelectedVideos.mutableCopy Original:self.manager.endIsOriginal];
                    }
                }
                if (collectionChanges.changedObjects.count > 0) {
                    
                }
                if ([collectionChanges hasMoves]) {
                    
                }
            }
        }
    }
}
- (void)setManager:(HXPhotoManager *)manager {
    _manager = manager;
    [manager getImage];
    [self.networkPhotos removeAllObjects];
    if (self.manager.networkPhotoUrls.count) {
        self.collectionView.editEnabled = NO;
        for (int i = 0; i < self.manager.networkPhotoUrls.count ; i++) {
            HXPhotoModel *model = [[HXPhotoModel alloc] init];
            model.type = HXPhotoModelMediaTypeCameraPhoto;
            model.networkPhotoUrl = self.manager.networkPhotoUrls[i];
            model.cameraIdentifier = [self videoOutFutFileName];
            model.imageSize = CGSizeMake([UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.width);
            model.selected = YES;
            model.thumbPhoto = [HXPhotoTools hx_imageNamed:self.manager.UIManager.placeholderImageName];
            model.previewPhoto = model.thumbPhoto;
            [self.networkPhotos addObject:model];
        }
    }
    if (self.manager.endSelectedList.count > 0 || self.networkPhotos.count > 0) {
        [self photoViewControllerDidNext:self.manager.endSelectedList.mutableCopy Photos:self.manager.endSelectedPhotos.mutableCopy Videos:self.manager.endSelectedVideos.mutableCopy Original:self.manager.endIsOriginal];
    }
}

/**
 刷新视图
 */
- (void)refreshView {
    [self photoViewControllerDidNext:self.manager.endSelectedList.mutableCopy Photos:self.manager.endSelectedPhotos.mutableCopy Videos:self.manager.endSelectedVideos.mutableCopy Original:self.manager.endIsOriginal];
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
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.dataList.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    HXPhotoSubViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:HXPhotoSubViewCellId forIndexPath:indexPath];
    cell.delegate = self;
    cell.dic = self.manager.photoViewCellIconDic;
    cell.model = self.dataList[indexPath.item];
    cell.showDeleteNetworkPhotoAlert = self.manager.showDeleteNetworkPhotoAlert;
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    self.currentIndexPath = indexPath;
    HXPhotoModel *model = self.dataList[indexPath.item];
    if (model.networkPhotoUrl.length > 0) {
        if (!model.downloadComplete) {
            [[self viewController].view showImageHUDText:[NSBundle hx_localizedStringForKey:@"照片正在下载"]];
            return;
        }else if (model.downloadError) {
            HXPhotoSubViewCell *cell = (HXPhotoSubViewCell *)[self.collectionView cellForItemAtIndexPath:indexPath];
            [cell againDownload];
            return;
        }
    }
    if (self.manager.style == HXPhotoAlbumStylesSystem) {
        if (model.type == HXPhotoModelMediaTypeCamera) {
            [self goPhotoViewController];
        }else {
            HXDatePhotoPreviewViewController *vc = [[HXDatePhotoPreviewViewController alloc] init];
            vc.outside = YES;
            vc.manager = self.manager;
            vc.modelArray = self.manager.endSelectedList;
            vc.currentModelIndex = [self.manager.endSelectedList indexOfObject:model];
            vc.photoView = self;
            
//            UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
//            nav.transitioningDelegate = vc;
//            nav.modalPresentationStyle = UIModalPresentationCustom;
            [[self viewController] presentViewController:vc animated:YES completion:nil];
        }
        return;
    }
    if (model.type == HXPhotoModelMediaTypeCamera) {
        [self goPhotoViewController];
    }else if ((model.type == HXPhotoModelMediaTypePhoto || model.type == HXPhotoModelMediaTypePhotoGif) || (model.type == HXPhotoModelMediaTypeCameraPhoto || model.type == HXPhotoModelMediaTypeLivePhoto)) {
        HXPhotoPreviewViewController *vc = [[HXPhotoPreviewViewController alloc] init];
        vc.selectedComplete = YES;
        vc.modelList = self.photos;
        vc.index = model.endIndex;
        vc.manager = self.manager;
        vc.photoView = self;
        [[self viewController] presentViewController:vc animated:YES completion:nil];
    }else if (model.type == HXPhotoModelMediaTypeVideo){
        HXVideoPreviewViewController *vc = [[HXVideoPreviewViewController alloc] init];
        vc.manager = self.manager;
        vc.model = model;
        vc.selectedComplete = YES;
        vc.photoView = self;
        [[self viewController] presentViewController:vc animated:YES completion:nil];
    }else if (model.type == HXPhotoModelMediaTypeCameraVideo) {
        HXVideoPreviewViewController *vc = [[HXVideoPreviewViewController alloc] init];
        vc.manager = self.manager;
        vc.model = model;
        vc.isCamera = YES;
        vc.selectedComplete = YES;
        vc.photoView = self;
        [[self viewController] presentViewController:vc animated:YES completion:nil];
    }
}

/**
 先进入相册再进入相机
 */
- (void)goCamera {
    self.manager.goCamera = YES;
    [self goPhotoViewController];
}

/**
 添加按钮点击事件
 */
- (void)goPhotoViewController {
    if (self.manager.outerCamera) {
        self.manager.openCamera = NO;
        if (self.manager.networkPhotoUrls.count == 0) {
            if (self.manager.type == HXPhotoManagerSelectedTypePhoto) {
                self.manager.maxNum = self.manager.photoMaxNum;
            }else if (self.manager.type == HXPhotoManagerSelectedTypeVideo) {
                self.manager.maxNum = self.manager.videoMaxNum;
            }else {
                // 防错
                if (self.manager.videoMaxNum + self.manager.photoMaxNum != self.manager.maxNum) {
                    self.manager.maxNum = self.manager.videoMaxNum + self.manager.photoMaxNum;
                }
            }
        }
        UIActionSheet *sheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:[NSBundle hx_localizedStringForKey:@"取消"] destructiveButtonTitle:nil otherButtonTitles:[NSBundle hx_localizedStringForKey:@"相机"],[NSBundle hx_localizedStringForKey:@"相册"], nil];
        
        [sheet showInView:self];
        return;
    }
    [self directGoPhotoViewController];
}

- (void)directGoPhotoViewController {
    if (self.manager.style == HXPhotoAlbumStylesWeibo) {
        HXPhotoViewController *vc = [[HXPhotoViewController alloc] init];
        vc.manager = self.manager;
        vc.delegate = self;
        [[self viewController] presentViewController:[[UINavigationController alloc] initWithRootViewController:vc] animated:YES completion:nil];
    }else {
        HXAlbumListViewController *vc = [[HXAlbumListViewController alloc] init];
        vc.manager = self.manager;
        vc.delegate = self;
        HXCustomNavigationController *nav = [[HXCustomNavigationController alloc] initWithRootViewController:vc];
        [[self viewController] presentViewController:nav animated:YES completion:nil];
    }
}

/**
 前往相机
 */
- (void)goCameraViewContoller {
    if(![UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
        [[self viewController].view showImageHUDText:[NSBundle hx_localizedStringForKey:@"无法使用相机!"]];
        return;
    }
    if (self.manager.style == HXPhotoAlbumStylesSystem) {
        [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(BOOL granted) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (granted) {
                    HXCustomCameraViewController *vc = [[HXCustomCameraViewController alloc] init];
                    vc.delegate = self;
                    vc.manager = self.manager;
                    vc.isOutside = YES;
                    HXCustomNavigationController *nav = [[HXCustomNavigationController alloc] initWithRootViewController:vc];
                    nav.isCamera = YES;
                    [[self viewController] presentViewController:nav animated:YES completion:nil];
                }else {
                    UIAlertController *alert = [UIAlertController alertControllerWithTitle:[NSBundle hx_localizedStringForKey:@"无法使用相机"] message:[NSBundle hx_localizedStringForKey:@"请在设置-隐私-相机中允许访问相机"] preferredStyle:UIAlertControllerStyleAlert];
                    [alert addAction:[UIAlertAction actionWithTitle:[NSBundle hx_localizedStringForKey:@"取消"] style:UIAlertActionStyleDefault handler:nil]];
                    [alert addAction:[UIAlertAction actionWithTitle:[NSBundle hx_localizedStringForKey:@"设置"] style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]];
                    }]];
                    [[self viewController] presentViewController:alert animated:YES completion:nil];
                }
            });
        }];
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
        if (self.videos.count >= self.manager.videoMaxNum && self.photos.count < self.manager.photoMaxNum + self.networkPhotos.count) {
            type = HXCameraTypePhoto;
        }else if (self.photos.count >= self.manager.photoMaxNum + self.networkPhotos.count && self.videos.count < self.manager.videoMaxNum) {
            type = HXCameraTypeVideo;
        }else if (self.photos.count + self.videos.count >= self.manager.maxNum + self.networkPhotos.count) {
            [[self viewController].view showImageHUDText:[NSBundle hx_localizedStringForKey:@"已达最大数!"]];
            return;
        }else {
            if (!self.manager.selectTogether) {
                if (self.photos.count > 0) {
                    type = HXCameraTypePhoto;
                }else if (self.videos.count > 0) {
                    type = HXCameraTypeVideo;
                }else {
                    type = HXCameraTypePhotoAndVideo;
                }
            }else {
                type = HXCameraTypePhotoAndVideo;
            }
        }
    }else if (self.manager.type == HXPhotoManagerSelectedTypePhoto) {
        if (self.photos.count >= self.manager.photoMaxNum + self.networkPhotos.count) {
            [[self viewController].view showImageHUDText:[NSBundle hx_localizedStringForKey:@"照片已达最大数!"]];
            return;
        }
        type = HXCameraTypePhoto;
    }else if (self.manager.type == HXPhotoManagerSelectedTypeVideo) {
        if (self.videos.count >= self.manager.videoMaxNum) {
            [[self viewController].view showImageHUDText:[NSBundle hx_localizedStringForKey:@"视频已达最大数!"]];
            return;
        }
        type = HXCameraTypeVideo;
    }
    if (self.manager.cameraType == HXPhotoManagerCameraTypeFullScreen) {
        HXFullScreenCameraViewController *vc1 = [[HXFullScreenCameraViewController alloc] init];
        vc1.delegate = self;
        vc1.type = type;
        vc1.photoManager = self.manager;
        if (self.manager.singleSelected) {
            [[self viewController] presentViewController:[[UINavigationController alloc] initWithRootViewController:vc1] animated:YES completion:nil];
        }else {
            [[self viewController] presentViewController:vc1 animated:YES completion:nil];
        }
    }else if (self.manager.cameraType == HXPhotoManagerCameraTypeHalfScreen) {
        HXCameraViewController *vc = [[HXCameraViewController alloc] init];
        vc.delegate = self;
        vc.type = type;
        vc.photoManager = self.manager;
        if (self.manager.singleSelected) {
            [[self viewController] presentViewController:[[UINavigationController alloc] initWithRootViewController:vc] animated:YES completion:nil];
        }else {
            [[self viewController] presentViewController:vc animated:YES completion:nil];
        }
    }else {
        // 跳转到相机或相册页面
        self.imagePickerController = [[UIImagePickerController alloc] init];
        self.imagePickerController.delegate = (id)self;
        self.imagePickerController.allowsEditing = NO;
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
        // 设置录制视频的质量
        [self.imagePickerController setVideoQuality:UIImagePickerControllerQualityTypeHigh];
        //设置最长摄像时间
        [self.imagePickerController setVideoMaximumDuration:self.manager.videoMaximumDuration];
        self.imagePickerController.sourceType = UIImagePickerControllerSourceTypeCamera;
        self.imagePickerController.navigationController.navigationBar.tintColor = [UIColor whiteColor];
        self.imagePickerController.modalPresentationStyle=UIModalPresentationOverCurrentContext;
        [[self viewController] presentViewController:self.imagePickerController animated:YES completion:nil];
    }
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 0) {
        [self goCameraViewContoller];
    }else if (buttonIndex == 1){
        [self directGoPhotoViewController];
    }
}

/**
 前往设置开启权限
 */
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 1) {
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]];
    }
}
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString *,id> *)info {
    [picker dismissViewControllerAnimated:YES completion:nil];

    NSString *mediaType = [info objectForKey:UIImagePickerControllerMediaType];
    HXPhotoModel *model = [[HXPhotoModel alloc] init];
    if ([mediaType isEqualToString:(NSString *)kUTTypeImage]) {
        UIImage *image = [info objectForKey:UIImagePickerControllerOriginalImage];
        if (image.imageOrientation != UIImageOrientationUp) {
            image = [image normalizedImage];
        }
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
- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [picker dismissViewControllerAnimated:YES completion:nil];
}
- (void)fullScreenCameraDidNextClick:(HXPhotoModel *)model {
    [self cameraDidNextClick:model];
}
- (void)customCameraViewController:(HXCustomCameraViewController *)viewController didDone:(HXPhotoModel *)model {
    [self cameraDidNextClick:model];
}
/**
 相机拍完之后的代理

 @param model 照片模型
 */
- (void)cameraDidNextClick:(HXPhotoModel *)model {
    if (self.manager.saveSystemAblum && self.manager.style != HXPhotoAlbumStylesSystem) {
        if ([PHPhotoLibrary authorizationStatus] != PHAuthorizationStatusAuthorized) {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.4 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [[self viewController].view showImageHUDText:[NSBundle hx_localizedStringForKey:@"保存失败，无法访问照片\n请前往设置中允许访问照片"]];
            });
            return;
        }
        self.tempCameraImage = model.thumbPhoto;
        self.manager.cameraPhoto = YES;
        __weak typeof(self) weakSelf = self;
        if (model.type == HXPhotoModelMediaTypeCameraPhoto) {
            [HXPhotoTools saveImageToAlbum:model.previewPhoto completion:^{
                NSSLog(@"保存成功");
            } error:^{
                weakSelf.manager.cameraPhoto = YES;
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.4 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    [[weakSelf viewController].view showImageHUDText:[NSBundle hx_localizedStringForKey:@"照片保存失败!"]];
                });
            }];
        }else {
            [HXPhotoTools saveVideoToAlbum:model.videoURL completion:^{
                NSSLog(@"保存成功");
            } error:^{
                weakSelf.manager.cameraPhoto = YES;
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.4 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    [[weakSelf viewController].view showImageHUDText:[NSBundle hx_localizedStringForKey:@"视频保存失败!"]];
                });
            }];
        }
        return;
    } 
    // 判断类型
    if (model.type == HXPhotoModelMediaTypeCameraPhoto) {
        [self.manager.endCameraPhotos addObject:model];
        // 当选择图片个数没有达到最大个数时就添加到选中数组中
        if (self.manager.endSelectedPhotos.count != self.manager.photoMaxNum) {
            if (!self.manager.selectTogether) {
                if (self.manager.endSelectedList.count > 0) {
                    HXPhotoModel *phMd = self.manager.endSelectedList.firstObject;
                    if ((phMd.type == HXPhotoModelMediaTypePhoto || phMd.type == HXPhotoModelMediaTypeLivePhoto) || (phMd.type == HXPhotoModelMediaTypePhotoGif || phMd.type == HXPhotoModelMediaTypeCameraPhoto)) {
                        [self.manager.endSelectedCameraPhotos insertObject:model atIndex:0];
                        [self.manager.endSelectedPhotos addObject:model];
                        [self.manager.endSelectedList addObject:model];
                        [self.manager.endSelectedCameraList addObject:model];
                        model.selected = YES;
                        model.selectIndexStr = [NSString stringWithFormat:@"%ld",[self.manager.endSelectedList indexOfObject:model] + 1];
                    }
                }else {
                    [self.manager.endSelectedCameraPhotos insertObject:model atIndex:0];
                    [self.manager.endSelectedPhotos addObject:model];
                    [self.manager.endSelectedList addObject:model];
                    [self.manager.endSelectedCameraList addObject:model];
                    model.selected = YES;
                    model.selectIndexStr = [NSString stringWithFormat:@"%ld",[self.manager.endSelectedList indexOfObject:model] + 1];
                }
            }else {
                [self.manager.endSelectedCameraPhotos insertObject:model atIndex:0];
                [self.manager.endSelectedPhotos addObject:model];
                [self.manager.endSelectedList addObject:model];
                [self.manager.endSelectedCameraList addObject:model];
                model.selected = YES;
                model.selectIndexStr = [NSString stringWithFormat:@"%ld",[self.manager.endSelectedList indexOfObject:model] + 1];
            }
        }else {
            [[self viewController].view showImageHUDText:[NSString stringWithFormat:[NSBundle hx_localizedStringForKey:@"最多只能选择%ld张图片"],self.manager.photoMaxNum]];
        }
    }else if (model.type == HXPhotoModelMediaTypeCameraVideo) {
        [self.manager.endCameraVideos addObject:model];
        // 当选中视频个数没有达到最大个数时就添加到选中数组中
        if (self.manager.endSelectedVideos.count != self.manager.videoMaxNum) {
            if (!self.manager.selectTogether) {
                if (self.manager.endSelectedList.count > 0) {
                    HXPhotoModel *phMd = self.manager.endSelectedList.firstObject;
                    if (phMd.type == HXPhotoModelMediaTypeVideo || phMd.type == HXPhotoModelMediaTypeCameraVideo) {
                        [self.manager.endSelectedCameraVideos insertObject:model atIndex:0];
                        [self.manager.endSelectedVideos addObject:model];
                        [self.manager.endSelectedList addObject:model];
                        [self.manager.endSelectedCameraList addObject:model];
                        model.selected = YES;
                        model.selectIndexStr = [NSString stringWithFormat:@"%ld",[self.manager.endSelectedList indexOfObject:model] + 1];
                    }
                }else {
                    
                    [self.manager.endSelectedCameraVideos insertObject:model atIndex:0];
                    [self.manager.endSelectedVideos addObject:model];
                    [self.manager.endSelectedList addObject:model];
                    [self.manager.endSelectedCameraList addObject:model];
                    model.selected = YES;
                    model.selectIndexStr = [NSString stringWithFormat:@"%ld",[self.manager.endSelectedList indexOfObject:model] + 1];
                }
            }else {
                [self.manager.endSelectedCameraVideos insertObject:model atIndex:0];
                [self.manager.endSelectedVideos addObject:model];
                [self.manager.endSelectedList addObject:model];
                [self.manager.endSelectedCameraList addObject:model];
                model.selected = YES;
                model.selectIndexStr = [NSString stringWithFormat:@"%ld",[self.manager.endSelectedList indexOfObject:model] + 1];
            }
        }else {
            [[self viewController].view showImageHUDText:[NSString stringWithFormat:[NSBundle hx_localizedStringForKey:@"最多只能选择%ld个视频"],self.manager.videoMaxNum]];
        }
    }
    [self.manager.endCameraList addObject:model];
    [self photoViewControllerDidNext:self.manager.endSelectedList.mutableCopy Photos:self.manager.endSelectedPhotos.mutableCopy Videos:self.manager.endSelectedVideos.mutableCopy Original:self.manager.endIsOriginal];
}

- (void)cellNetworkingPhotoDownLoadComplete {
    if ([self networkingPhotoDownloadComplete] && !self.downLoadComplete) {
        self.downLoadComplete = YES;
        NSMutableArray *tempAllArray = [NSMutableArray array];
        NSMutableArray *tempPhotoArray = [NSMutableArray array];
        for (HXPhotoModel *model in self.networkPhotos) {
            [tempAllArray addObject:model];
            [tempPhotoArray addObject:model];
        }
        [tempAllArray addObjectsFromArray:self.manager.endSelectedList];
        [tempPhotoArray addObjectsFromArray:self.manager.endSelectedPhotos];
        if ([self.delegate respondsToSelector:@selector(photoView:changeComplete:photos:videos:original:)]) {
            [self.delegate photoView:self changeComplete:tempAllArray.mutableCopy photos:tempPhotoArray.mutableCopy videos:self.manager.endSelectedVideos.mutableCopy original:self.manager.endIsOriginal];
        }
        if ([self.delegate respondsToSelector:@selector(photoViewAllNetworkingPhotoDownloadComplete:)]) {
            [self.delegate photoViewAllNetworkingPhotoDownloadComplete:self];
        }
    }
}
- (void)deleteModelWithIndex:(NSInteger)index {
    if (index < 0) {
        index = 0;
    }
    if (index > self.manager.endSelectedList.count - 1) {
        index = self.manager.endSelectedList.count - 1;
    }
    UICollectionViewCell *cell = [self.collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForItem:index inSection:0]];
    if (cell) {
        [self cellDidDeleteClcik:cell];
    }else {
        NSSLog(@"删除失败 - cell为空");
    }
}
/**
 cell删除按钮的代理

 @param cell 被删的cell
 */
- (void)cellDidDeleteClcik:(UICollectionViewCell *)cell {
    NSIndexPath *indexPath = [self.collectionView indexPathForCell:cell];
    HXPhotoModel *model = self.dataList[indexPath.item];
    [self.manager deleteSpecifiedModel:model];
    if (model.networkPhotoUrl.length > 0) {
        for (HXPhotoModel *netModel in self.networkPhotos) {
            if ([netModel.networkPhotoUrl isEqualToString:model.networkPhotoUrl]) {
                if ([self.delegate respondsToSelector:@selector(photoView:deleteNetworkPhoto:)]) {
                    [self.delegate photoView:self deleteNetworkPhoto:model.networkPhotoUrl];
                }
                self.manager.photoMaxNum += 1;
                [self.networkPhotos removeObject:netModel];
                break;
            }
        }
    }
    if ((model.type == HXPhotoModelMediaTypePhoto || model.type == HXPhotoModelMediaTypePhotoGif) || (model.type == HXPhotoModelMediaTypeCameraPhoto || model.type == HXPhotoModelMediaTypeLivePhoto)) {
        [self.photos removeObject:model];
    }else if (model.type == HXPhotoModelMediaTypeVideo || model.type == HXPhotoModelMediaTypeCameraVideo) {
        [self.videos removeObject:model];
    }
    model.thumbPhoto = nil;
    model.previewPhoto = nil; 
    model = nil;
    
    UIView *mirrorView = [cell snapshotViewAfterScreenUpdates:NO];
    mirrorView.frame = cell.frame;
    [self.collectionView insertSubview:mirrorView atIndex:0];
    cell.hidden = YES;
    [UIView animateWithDuration:0.25 animations:^{
        mirrorView.transform = CGAffineTransformMakeScale(0.0001, 0.0001);
    } completion:^(BOOL finished) {
        cell.hidden = NO;
        HXPhotoSubViewCell *myCell = (HXPhotoSubViewCell *)cell;
        myCell.imageView.image = nil;
        [mirrorView removeFromSuperview];
    }];
    [self.dataList removeObjectAtIndex:indexPath.item];
    [self.collectionView deleteItemsAtIndexPaths:@[indexPath]];
    [self changeSelectedListModelIndex];
    if (self.isAddModel) {
        if ([self.delegate respondsToSelector:@selector(photoView:changeComplete:photos:videos:original:)]) {
            [self.delegate photoView:self changeComplete:self.dataList photos:self.photos videos:self.videos original:self.original];
        }
        self.isAddModel = NO;
        [self.dataList addObject:self.addModel];
        [self.collectionView reloadData];
    }else {
        NSMutableArray *array = [NSMutableArray arrayWithArray:self.dataList.mutableCopy];
        [array removeLastObject];
        if ([self.delegate respondsToSelector:@selector(photoView:changeComplete:photos:videos:original:)]) {
            [self.delegate photoView:self changeComplete:array photos:self.photos.mutableCopy videos:self.videos.mutableCopy original:self.original];
        }
    }
    [self setupNewFrame];
}

- (void)changeSelectedListModelIndex {
    int i = 0, j = 0, k = 0;
    NSMutableArray *array;
    if (self.isAddModel) {
        array = self.dataList;
    }else {
        array = self.dataList.mutableCopy;
        [array removeLastObject];
    }
    for (HXPhotoModel *model in array) {
        model.selectIndexStr = [NSString stringWithFormat:@"%d",k + 1];
        if ((model.type == HXPhotoModelMediaTypePhoto || model.type == HXPhotoModelMediaTypePhotoGif) || (model.type == HXPhotoModelMediaTypeCameraPhoto || model.type == HXPhotoModelMediaTypeLivePhoto)) {
            model.endIndex = i++;
        }else if (model.type == HXPhotoModelMediaTypeVideo || model.type == HXPhotoModelMediaTypeCameraVideo) {
            model.videoIndex = j++;
        }
        model.endCollectionIndex = k++;
    }
}
#pragma mark - < HXAlbumListViewControllerDelegate >
- (void)albumListViewController:(HXAlbumListViewController *)albumListViewController didDoneAllList:(NSArray<HXPhotoModel *> *)allList photos:(NSArray<HXPhotoModel *> *)photoList videos:(NSArray<HXPhotoModel *> *)videoList original:(BOOL)original {
    [self photoViewControllerDidNext:allList Photos:photoList Videos:videoList Original:original];
}
- (void)photoViewControllerDidNext:(NSArray<HXPhotoModel *> *)allList Photos:(NSArray<HXPhotoModel *> *)photos Videos:(NSArray<HXPhotoModel *> *)videos Original:(BOOL)original {
    self.original = original;
    NSMutableArray *tempAllArray = [NSMutableArray array];
    NSMutableArray *tempPhotoArray = [NSMutableArray array];
    for (HXPhotoModel *model in self.networkPhotos) {
        [tempAllArray addObject:model];
        [tempPhotoArray addObject:model];
    }
    [tempAllArray addObjectsFromArray:allList];
    [tempPhotoArray addObjectsFromArray:photos];
    allList = tempAllArray;
    photos = tempPhotoArray;
    
    self.photos = [NSMutableArray arrayWithArray:photos];
    self.videos = [NSMutableArray arrayWithArray:videos];
    [self.dataList removeAllObjects];
    [self.dataList addObjectsFromArray:allList];
    [self.dataList addObject:self.addModel];
    if (self.manager.selectTogether) {
        if (self.manager.maxNum == allList.count) {
            [self.dataList removeLastObject];
            self.isAddModel = YES;
        }
    }else {
        if (photos.count > 0) {
            if (photos.count == self.manager.photoMaxNum + self.networkPhotos.count) {
                if (self.manager.photoMaxNum > 0 || self.networkPhotos.count > 0) {
                    [self.dataList removeLastObject];
                    self.isAddModel = YES;
                }
            }
        }else if (videos.count > 0) {
            if (videos.count == self.manager.videoMaxNum) {
                if (self.manager.videoMaxNum > 0) {
                    [self.dataList removeLastObject];
                    self.isAddModel = YES;
                }
            }
        }
    }
    [self changeSelectedListModelIndex];
    [self.collectionView reloadData];
    
    if ([self.delegate respondsToSelector:@selector(photoView:changeComplete:photos:videos:original:)]) {
        [self.delegate photoView:self changeComplete:allList.copy photos:photos.copy videos:videos.copy original:original];
    }
    [self setupNewFrame];
}

- (void)photoViewControllerDidCancel {
    
}

- (NSArray *)dataSourceArrayOfCollectionView:(HXCollectionView *)collectionView {
    return self.dataList;
}

- (void)dragCellCollectionView:(HXCollectionView *)collectionView newDataArrayAfterMove:(NSArray *)newDataArray {
    self.dataList = [NSMutableArray arrayWithArray:newDataArray];
}

- (void)dragCellCollectionView:(HXCollectionView *)collectionView moveCellFromIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
    HXPhotoModel *fromModel = self.dataList[fromIndexPath.item];
    HXPhotoModel *toModel = self.dataList[toIndexPath.item];
    [self.manager.endSelectedList removeObject:toModel];
    [self.manager.endSelectedList insertObject:toModel atIndex:toIndexPath.item];
    [self.manager.endSelectedList removeObject:fromModel];
    [self.manager.endSelectedList insertObject:fromModel atIndex:fromIndexPath.item];
    [self.photos removeAllObjects];
    [self.videos removeAllObjects];
    int i = 0, j = 0, k = 0;
    for (HXPhotoModel *model in self.manager.endSelectedList) {
        model.selectIndexStr = [NSString stringWithFormat:@"%d",k + 1];
        if ((model.type == HXPhotoModelMediaTypePhoto || model.type == HXPhotoModelMediaTypePhotoGif) || (model.type == HXPhotoModelMediaTypeCameraPhoto || model.type == HXPhotoModelMediaTypeLivePhoto)) {
            model.endIndex = i++;
            [self.photos addObject:model];
        }else if (model.type == HXPhotoModelMediaTypeVideo || model.type == HXPhotoModelMediaTypeCameraVideo) {
            model.endIndex = j++;
            [self.videos addObject:model];
        }
        model.endCollectionIndex = k++;
    }
    self.manager.endSelectedPhotos = [NSMutableArray arrayWithArray:self.photos];
    self.manager.endSelectedVideos = [NSMutableArray arrayWithArray:self.videos];
}

- (void)dragCellCollectionViewCellEndMoving:(HXCollectionView *)collectionView {
    if (self.isAddModel) {
        if ([self.delegate respondsToSelector:@selector(photoView:changeComplete:photos:videos:original:)]) {
            [self.delegate photoView:self changeComplete:self.dataList.mutableCopy photos:self.photos.mutableCopy videos:self.videos.mutableCopy original:self.original];
        }
    }else {
        NSMutableArray *array = [NSMutableArray arrayWithArray:self.dataList.mutableCopy];
        [array removeLastObject];
        if ([self.delegate respondsToSelector:@selector(photoView:changeComplete:photos:videos:original:)]) {
            [self.delegate photoView:self changeComplete:array photos:self.photos.mutableCopy videos:self.videos.mutableCopy original:self.original];
        }
    }
}

- (BOOL)networkingPhotoDownloadComplete {
    BOOL complete = YES;
    for (HXPhotoModel *model in self.networkPhotos) {
        if (!model.downloadComplete || model.downloadError) {
            complete = NO;
            break;
        }
    }
    return complete;
}

/**
 获取已下载完成的网络图片数量

 @return 个数
 */
- (NSInteger)downloadNumberForNetworkingPhoto {
    NSInteger number = 0;
    for (HXPhotoModel *model in self.networkPhotos) {
        if (model.downloadComplete && !model.downloadError) {
            number++;
        }
    }
    return number;
}

/**
 更新高度
 */
- (void)setupNewFrame {
    double x = self.frame.origin.x;
    double y = self.frame.origin.y;
    CGFloat width = self.frame.size.width;
    
    CGFloat itemW = (width - self.spacing * (self.lineCount - 1)) / self.lineCount;
    if (itemW > 0) {
        self.flowLayout.itemSize = CGSizeMake(itemW, itemW);
    }
    
    NSInteger dataCount = self.dataList.count;
    NSInteger numOfLinesNew = 0;
    if (self.lineCount != 0) {
        numOfLinesNew = (dataCount / self.lineCount) + 1;
    }
    
    if (dataCount % self.lineCount == 0) {
        numOfLinesNew -= 1;
    }
    self.flowLayout.minimumLineSpacing = self.spacing;
    
    if (numOfLinesNew != self.numOfLinesOld) {
        CGFloat newHeight = numOfLinesNew * itemW + self.spacing * (numOfLinesNew - 1);
        if (newHeight < 0) {
            newHeight = 0;
        }
        self.frame = CGRectMake(x, y, width, newHeight);
        self.numOfLinesOld = numOfLinesNew;
        if (newHeight <= 0) {
            self.numOfLinesOld = 0;
        }
        if ([self.delegate respondsToSelector:@selector(photoView:updateFrame:)]) {
            [self.delegate photoView:self updateFrame:self.frame]; 
        }
    }
}

- (void)layoutSubviews {
    [super layoutSubviews];
    NSInteger dataCount = self.dataList.count;
    NSInteger numOfLinesNew = (dataCount / self.lineCount) + 1;
    
    [self setupNewFrame];
    CGFloat x = self.frame.origin.x;
    CGFloat y = self.frame.origin.y;
    CGFloat width = self.frame.size.width;
    CGFloat height = self.frame.size.height;
    
    if (dataCount == 1) {
        CGFloat itemW = (width - self.spacing * (self.lineCount - 1)) / self.lineCount;
        if ((int)height != (int)itemW) {
            self.frame = CGRectMake(x, y, width, itemW);
        }
    }
    if (dataCount % self.lineCount == 0) {
        numOfLinesNew -= 1;
    }
    CGFloat cWidth = self.frame.size.width;
    CGFloat cHeight = self.frame.size.height;
    self.collectionView.frame = CGRectMake(0, 0, cWidth, cHeight);
    if (cHeight <= 0) {
        self.numOfLinesOld = 0;
        [self setupNewFrame];
        CGFloat cWidth = self.frame.size.width;
        CGFloat cHeight = self.frame.size.height;
        self.collectionView.frame = CGRectMake(0, 0, cWidth, cHeight);
    }
}
- (void)dealloc {
    NSSLog(@"dealloc");
}

@end
