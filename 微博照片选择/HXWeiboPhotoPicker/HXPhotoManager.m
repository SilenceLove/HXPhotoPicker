//
//  HX_PhotoManager.m
//  微博照片选择
//
//  Created by 洪欣 on 17/2/8.
//  Copyright © 2017年 洪欣. All rights reserved.
//

#import "HXPhotoManager.h"

#define iOS9Later ([UIDevice currentDevice].systemVersion.floatValue >= 9.1f)
@interface HXPhotoManager ()<PHPhotoLibraryChangeObserver>
@property (strong, nonatomic) NSMutableArray *allPhotos;
@property (strong, nonatomic) NSMutableArray *allVideos;
@property (strong, nonatomic) NSMutableArray *allObjs;
@end

@implementation HXPhotoManager

- (instancetype)initWithType:(HXPhotoManagerSelectedType)type
{
    if (self = [super init]) {
        self.type = type;
        [self setup];
    }
    return self;
}

- (instancetype)init
{
    if ([super init]) {
        self.type = HXPhotoManagerSelectedTypePhoto;
        [self setup];
    }
    return self;
}

- (void)setup
{
    self.open3DTouchPreview = NO;
    self.cameraType = HXPhotoManagerCameraTypeHalfScreen;
    self.outerCamera = NO;
    self.openCamera = YES;
    self.lookLivePhoto = NO;
    self.lookGifPhoto = YES;
    self.selectTogether = YES;
    self.maxNum = 10;
    self.photoMaxNum = 9;
    self.videoMaxNum = 1;
    if ([UIScreen mainScreen].bounds.size.width == 320) {
        self.rowCount = 3;
    }else {
        self.rowCount = 4;
    }
    self.albums = [NSMutableArray array];
    self.selectedList = [NSMutableArray array];
    self.selectedPhotos = [NSMutableArray array];
    self.selectedVideos = [NSMutableArray array];
    self.endSelectedList = [NSMutableArray array];
    self.endSelectedPhotos = [NSMutableArray array];
    self.endSelectedVideos = [NSMutableArray array];
    self.cameraList = [NSMutableArray array];
    self.cameraPhotos = [NSMutableArray array];
    self.cameraVideos = [NSMutableArray array];
    self.endCameraList = [NSMutableArray array];
    self.endCameraPhotos = [NSMutableArray array];
    self.endCameraVideos = [NSMutableArray array];
    self.selectedCameraList = [NSMutableArray array];
    self.selectedCameraPhotos = [NSMutableArray array];
    self.selectedCameraVideos = [NSMutableArray array];
    self.endSelectedCameraList = [NSMutableArray array];
    self.endSelectedCameraPhotos = [NSMutableArray array];
    self.endSelectedCameraVideos = [NSMutableArray array];
    self.networkPhotoUrls = [NSMutableArray array];
    self.showDeleteNetworkPhotoAlert = NO;
    self.singleSelecteClip = YES;
    self.monitorSystemAlbum = YES;
    self.cacheAlbum = YES;
    self.videoMaxDuration = 300.f;
    self.saveSystemAblum = NO;
    self.UIManager = [[HXPhotoUIManager alloc] init];
    self.UIManager.photoViewAddImageName = @"compose_pic_add@2x.png";
    self.UIManager.placeholderImageName = @"qz_photolist_picture_fail@2x.png";
    self.UIManager.navLeftBtnTitleColor = [UIColor blackColor]; 
    self.UIManager.navTitleColor = [UIColor blackColor];
    self.UIManager.navTitleImageName = @"headlines_icon_arrow@2x.png";
    self.UIManager.navRightBtnNormalBgColor = [UIColor colorWithRed:253/255.0 green:142/255.0 blue:36/255.0 alpha:1];
    self.UIManager.navRightBtnDisabledBgColor = [UIColor whiteColor];
    self.UIManager.navRightBtnBorderColor = [UIColor lightGrayColor];
    self.UIManager.navRightBtnNormalTitleColor = [UIColor whiteColor];
    self.UIManager.navRightBtnDisabledTitleColor = [UIColor lightGrayColor];
    self.UIManager.bottomViewBgColor = [UIColor whiteColor];
    self.UIManager.blurEffect = NO;
    self.UIManager.previewBtnNormalTitleColor = [UIColor blackColor];
    self.UIManager.previewBtnDisabledTitleColor = [UIColor lightGrayColor];
    self.UIManager.previewBtnNormalBgImageName = @"compose_photo_preview_seleted@2x.png";
    self.UIManager.previewBtnDisabledBgImageName = @"compose_photo_preview_disable@2x.png";
    self.UIManager.originalBtnBgColor = [UIColor whiteColor];
    self.UIManager.originalBtnNormalTitleColor = [UIColor blackColor];
    self.UIManager.originalBtnDisabledTitleColor = [UIColor lightGrayColor];
    self.UIManager.originalBtnBorderColor = [UIColor colorWithRed:200/255.0 green:200/255.0 blue:200/255.0 alpha:0.7];
    self.UIManager.originalBtnNormalImageName = @"椭圆-1@2x.png";
    self.UIManager.originalBtnSelectedImageName = @"椭圆-1-拷贝@2x.png";
    self.UIManager.albumViewBgColor = [UIColor colorWithRed:240/255.0 green:240/255.0 blue:240/255.0 alpha:1];
    self.UIManager.albumViewSelectImageName = @"compose_photo_filter_checkbox_checked@2x.png";
    self.UIManager.albumNameTitleColor = [UIColor blackColor];
    self.UIManager.photosNumberTitleColor = [UIColor darkGrayColor];
    self.UIManager.cellCameraPhotoImageName = @"compose_photo_photograph@2x.png";
    self.UIManager.cellCameraVideoImageName = @"compose_photo_video@2x.png";
    self.UIManager.cellGitIconImageName = @"timeline_image_gif@2x.png";
    self.UIManager.cellSelectBtnNormalImageName = @"compose_guide_check_box_default@2x.png";
    self.UIManager.cellSelectBtnSelectedImageName = @"compose_guide_check_box_right@2x.png";
    self.UIManager.cameraCloseNormalImageName = @"camera_close@2x.png";
    self.UIManager.cameraCloseHighlightedImageName = @"camera_close_highlighted@2x.png";
    self.UIManager.cameraReverseNormalImageName = @"camera_overturn@2x.png";
    self.UIManager.cameraReverseHighlightedImageName = @"camera_overturn_highlighted@2x.png";
    self.UIManager.flashAutoImageName = @"camera_flashlight_auto_disable@2x.png";
    self.UIManager.flashOnImageName = @"camera_flashlight_open_disable@2x.png";
    self.UIManager.flashOffImageName = @"camera_flashlight_disable@2x.png";
    self.UIManager.takePicturesBtnNormalImageName = @"camera_camera_background@2x.png";
    self.UIManager.takePicturesBtnHighlightedImageName = @"camera_camera_background_highlighted@2x.png";
    self.UIManager.recordedBtnNormalImageName = @"camera_video_background@2x.png";
    self.UIManager.recordedBtnHighlightedImageName = @"camera_video_background_highlighted@2x.png";
    self.UIManager.cameraDeleteBtnImageName = @"video_delete_dustbin@2x.png";
    self.UIManager.cameraNextBtnNormalImageName = @"video_next_button@2x.png";
    self.UIManager.cameraNextBtnHighlightedImageName = @"video_next_button_highlighted@2x.png";
    self.UIManager.cameraCenterDotImageName = @"camera_drop_highlighted@2x.png";
    self.UIManager.cameraFocusImageName = @"camera_ Focusing@2x.png";
    self.UIManager.fullScreenCameraNextBtnTitleColor = [UIColor whiteColor];
    self.UIManager.fullScreenCameraNextBtnBgColor = [UIColor colorWithRed:253/255.0 green:142/255.0 blue:36/255.0 alpha:1];
    self.UIManager.cameraPhotoVideoNormalTitleColor = [UIColor lightGrayColor];
    self.UIManager.cameraPhotoVideoSelectedTitleColor = [UIColor colorWithRed:253/255.0 green:142/255.0 blue:36/255.0 alpha:1];
    
    [[PHPhotoLibrary sharedPhotoLibrary] registerChangeObserver:self];
}

- (void)setSaveSystemAblum:(BOOL)saveSystemAblum {
    _saveSystemAblum = saveSystemAblum;
    [self getMaxAlbum];
}

- (void)setMonitorSystemAlbum:(BOOL)monitorSystemAlbum {
    _monitorSystemAlbum = monitorSystemAlbum;
    if (!monitorSystemAlbum) {
        [[PHPhotoLibrary sharedPhotoLibrary] unregisterChangeObserver:self];
    }
}

- (void)getImage {
    
    if (!self.singleSelected && !self.photoViewCellIconDic) {
        self.photoViewCellIconDic = @{@"videoIcon" : [HXPhotoTools hx_imageNamed:@"VideoSendIcon@2x.png"] ,
                                              @"gifIcon" : [HXPhotoTools hx_imageNamed:self.UIManager.cellGitIconImageName] ,
                                              @"liveIcon" : [HXPhotoTools hx_imageNamed:@"compose_live_photo_open_only_icon@2x.png"] ,
                                              @"liveBtnImageNormal" : [HXPhotoTools hx_imageNamed:@"compose_live_photo_open_icon@2x.png"] ,
                                              @"liveBtnImageSelected" : [HXPhotoTools hx_imageNamed:@"compose_live_photo_close_icon@2x.png"] ,
                                              @"liveBtnBackgroundImage" : [HXPhotoTools hx_imageNamed:@"compose_live_photo_background@2x.png"] ,
                                              @"selectBtnNormal" : [HXPhotoTools hx_imageNamed:self.UIManager.cellSelectBtnNormalImageName] ,
                                              @"selectBtnSelected" : [HXPhotoTools hx_imageNamed:self.UIManager.cellSelectBtnSelectedImageName]};
    }
}

/**
 获取系统所有相册
 
 @param albums 相册集合
 */
- (void)FetchAllAlbum:(void(^)(NSArray *albums))albums IsShowSelectTag:(BOOL)isShow
{
    if (self.albums.count > 0) [self.albums removeAllObjects];
    // 获取系统智能相册
    PHFetchResult *smartAlbums = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeSmartAlbum subtype:PHAssetCollectionSubtypeAlbumRegular options:nil];
    [smartAlbums enumerateObjectsWithOptions:NSEnumerationConcurrent usingBlock:^(PHAssetCollection *collection, NSUInteger idx, BOOL * _Nonnull stop) {
        // 是否按创建时间排序
        PHFetchOptions *option = [[PHFetchOptions alloc] init];
        option.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"creationDate" ascending:YES]];
        if (self.type == HXPhotoManagerSelectedTypePhoto) {
            option.predicate = [NSPredicate predicateWithFormat:@"mediaType == %ld", PHAssetMediaTypeImage];
        }else if (self.type == HXPhotoManagerSelectedTypeVideo) {
            option.predicate = [NSPredicate predicateWithFormat:@"mediaType == %ld", PHAssetMediaTypeVideo];
        }
        // 获取照片集合
        PHFetchResult *result = [PHAsset fetchAssetsInAssetCollection:collection options:option];
        // 过滤掉空相册
        if (result.count > 0 && ![[HXPhotoTools transFormPhotoTitle:collection.localizedTitle] isEqualToString:@"最近删除"]) {
            HXAlbumModel *albumModel = [[HXAlbumModel alloc] init];
            albumModel.count = result.count;
            albumModel.albumName = collection.localizedTitle;
//            albumModel.asset = result.lastObject;
            albumModel.result = result;
            if ([[HXPhotoTools transFormPhotoTitle:collection.localizedTitle] isEqualToString:@"相机胶卷"] || [[HXPhotoTools transFormPhotoTitle:collection.localizedTitle] isEqualToString:@"所有照片"]) {
                [self.albums insertObject:albumModel atIndex:0];
            }else {
                [self.albums addObject:albumModel];
            }
            
            if (isShow) {
                if (self.selectedList.count > 0) {
                    HXPhotoModel *photoModel = self.selectedList.firstObject;
                    for (PHAsset *asset in result) {
                        if ([asset.localIdentifier isEqualToString:photoModel.asset.localIdentifier]) {
                            albumModel.selectedCount++;
                            break;
                        }
                    }
                }
            }
        }
    }];
    
    // 获取用户相册
    PHFetchResult *userAlbums = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeAlbum subtype:PHAssetCollectionSubtypeSmartAlbumUserLibrary options:nil];
    [userAlbums enumerateObjectsWithOptions:NSEnumerationConcurrent usingBlock:^(PHAssetCollection *collection, NSUInteger idx, BOOL * _Nonnull stop) {
        // 是否按创建时间排序
        PHFetchOptions *option = [[PHFetchOptions alloc] init];
        option.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"creationDate" ascending:YES]];
        if (self.type == HXPhotoManagerSelectedTypePhoto) {
            option.predicate = [NSPredicate predicateWithFormat:@"mediaType == %ld", PHAssetMediaTypeImage];
        }else if (self.type == HXPhotoManagerSelectedTypeVideo) {
            option.predicate = [NSPredicate predicateWithFormat:@"mediaType == %ld", PHAssetMediaTypeVideo];
        }
        // 获取照片集合
        PHFetchResult *result = [PHAsset fetchAssetsInAssetCollection:collection options:option];
        
        // 过滤掉空相册
        if (result.count > 0) {
            HXAlbumModel *albumModel = [[HXAlbumModel alloc] init];
            albumModel.count = result.count;
            albumModel.albumName = [HXPhotoTools transFormPhotoTitle:collection.localizedTitle];
//            albumModel.asset = result.lastObject;
            albumModel.result = result;
            [self.albums addObject:albumModel];
            if (isShow) {
                if (self.selectedList.count > 0) {
                    HXPhotoModel *photoModel = self.selectedList.firstObject;
                    for (PHAsset *asset in result) {
                        if ([asset.localIdentifier isEqualToString:photoModel.asset.localIdentifier]) {
                            albumModel.selectedCount++;
                            break;
                        }
                    }
                }
            }
        }
    }];
    
    for (int i = 0 ; i < self.albums.count; i++) {
        HXAlbumModel *model = self.albums[i];
        model.index = i;
        if (isShow) {
            if (i == 0) {
                model.selectedCount += self.selectedCameraList.count;
            }
        }
    }
    if (albums) {
        albums(self.albums);
    }
}

/**
 根据PHFetchResult获取某个相册里面的所有图片和视频
 
 @param result PHFetchResult对象
 @param index 相册下标
 @param list 照片和视频的集合
 */
- (void)FetchAllPhotoForPHFetchResult:(PHFetchResult *)result Index:(NSInteger)index FetchResult:(void(^)(NSArray *photos, NSArray *videos, NSArray *Objs))list
{
    NSMutableArray *photoAy = [NSMutableArray array];
    NSMutableArray *videoAy = [NSMutableArray array];
    NSMutableArray *objAy = [NSMutableArray array]; 
    __block NSInteger cameraIndex = self.openCamera ? 1 : 0;
    [result enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(PHAsset *asset, NSUInteger idx, BOOL * _Nonnull stop) {
        HXPhotoModel *photoModel = [[HXPhotoModel alloc] init];
        photoModel.asset = asset;
        if (self.selectedList.count > 0) {
            NSMutableArray *selectedList = [NSMutableArray arrayWithArray:self.selectedList];
            for (HXPhotoModel *model in selectedList) {
                if ([model.asset.localIdentifier isEqualToString:photoModel.asset.localIdentifier]) {
                    photoModel.selected = YES;
//                    if (model.currentAlbumIndex == index) {
                        if ((model.type == HXPhotoModelMediaTypePhoto || model.type == HXPhotoModelMediaTypePhotoGif) || (model.type == HXPhotoModelMediaTypeLivePhoto || model.type == HXPhotoModelMediaTypeCameraPhoto)) {
                            if (model.type == HXPhotoModelMediaTypeCameraPhoto) {
                                [self.selectedCameraPhotos replaceObjectAtIndex:[self.selectedCameraPhotos indexOfObject:model] withObject:photoModel];
                            }else {
                                [self.selectedPhotos replaceObjectAtIndex:[self.selectedPhotos indexOfObject:model] withObject:photoModel];
                            }
                        }else {
                            if (model.type == HXPhotoModelMediaTypeCameraVideo) {
                                [self.selectedCameraVideos replaceObjectAtIndex:[self.selectedCameraVideos indexOfObject:model] withObject:photoModel];
                            }else {
                                [self.selectedVideos replaceObjectAtIndex:[self.selectedVideos indexOfObject:model] withObject:photoModel];
                            }
                        }
                        [self.selectedList replaceObjectAtIndex:[self.selectedList indexOfObject:model] withObject:photoModel];

//                    }
                    photoModel.thumbPhoto = model.thumbPhoto;
                    photoModel.previewPhoto = model.previewPhoto;
                    photoModel.isCloseLivePhoto = model.isCloseLivePhoto;
                }
            }
        }
        if (asset.mediaType == PHAssetMediaTypeImage) {
            photoModel.subType = HXPhotoModelMediaSubTypePhoto;
            if ([[asset valueForKey:@"filename"] hasSuffix:@"GIF"]) {
                if (self.singleSelected && self.singleSelecteClip) {
                    photoModel.type = HXPhotoModelMediaTypePhoto;
                }else {
                    photoModel.type = self.lookGifPhoto ? HXPhotoModelMediaTypePhotoGif : HXPhotoModelMediaTypePhoto;
                }
            }else {
                if (iOS9Later) {
                    if (asset.mediaSubtypes == PHAssetMediaSubtypePhotoLive) {
                        if (!self.singleSelected) {
                            photoModel.type = self.lookLivePhoto ? HXPhotoModelMediaTypeLivePhoto : HXPhotoModelMediaTypePhoto;
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
            [photoAy addObject:photoModel];
        }else if (asset.mediaType == PHAssetMediaTypeVideo) {
            photoModel.subType = HXPhotoModelMediaSubTypeVideo;
            photoModel.type = HXPhotoModelMediaTypeVideo;
            [[PHImageManager defaultManager] requestAVAssetForVideo:asset options:nil resultHandler:^(AVAsset * _Nullable asset, AVAudioMix * _Nullable audioMix, NSDictionary * _Nullable info) {
                photoModel.avAsset = asset;
            }];
            //            [[PHImageManager defaultManager] requestPlayerItemForVideo:asset options:nil resultHandler:^(AVPlayerItem * _Nullable playerItem, NSDictionary * _Nullable info) {
            //                photoModel.playerItem = playerItem;
            //            }];
            NSString *timeLength = [NSString stringWithFormat:@"%0.0f",asset.duration];
            photoModel.videoTime = [HXPhotoTools getNewTimeFromDurationSecond:timeLength.integerValue];
            [videoAy addObject:photoModel];
        }
        photoModel.currentAlbumIndex = index;
        [objAy addObject:photoModel];
    }];
    if (self.openCamera) {
        HXPhotoModel *model = [[HXPhotoModel alloc] init];
        model.type = HXPhotoModelMediaTypeCamera;
        if (photoAy.count == 0 && videoAy.count != 0) {
            model.thumbPhoto = [HXPhotoTools hx_imageNamed:self.UIManager.cellCameraVideoImageName];
        }else if (videoAy.count == 0) {
            model.thumbPhoto = [HXPhotoTools hx_imageNamed:self.UIManager.cellCameraPhotoImageName];
        }else {
            model.thumbPhoto = [HXPhotoTools hx_imageNamed:self.UIManager.cellCameraPhotoImageName];
        }
        [objAy insertObject:model atIndex:0];
    }
    if (index == 0) {
        if (self.cameraList.count > 0) {
//            NSInteger listCount = self.cameraList.count;
//            if (self.outerCamera) {
//                listCount = self.cameraList.count - 1;
//            }
            for (int i = 0; i < self.cameraList.count; i++) {
                HXPhotoModel *phMD = self.cameraList[i];
//                phMD.albumListIndex = listCount--;
                [objAy insertObject:phMD atIndex:cameraIndex];
            }
//            NSInteger photoCount = self.cameraPhotos.count - 1;
            for (int i = 0; i < self.cameraPhotos.count; i++) {
                HXPhotoModel *phMD = self.cameraPhotos[i];
//                phMD.photoIndex = photoCount--;
                [photoAy insertObject:phMD atIndex:0];
            }
//            NSInteger videoCount = self.cameraVideos.count - 1;
            for (int i = 0; i < self.cameraVideos.count; i++) {
                HXPhotoModel *phMD = self.cameraVideos[i];
//                phMD.videoIndex = videoCount--;
                [videoAy insertObject:phMD atIndex:0];
            }
        }
    }
    if (list) {
        list(photoAy,videoAy,objAy);
    }
}

- (void)deletePhotoModelFromLastSelectedListWhereNotInSystemAlbums {
//    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
//        __weak typeof(self) weakSelf = self;
//        [self FetchAllAlbum:^(NSArray *albums) {
//            HXAlbumModel *model = weakSelf.albums.firstObject;
//            [weakSelf FetchAllPhotoForPHFetchResult:model.result Index:model.index FetchResult:^(NSArray *photos, NSArray *videos, NSArray *Objs) {
//                NSPredicate *predicate = [NSPredicate predicateWithFormat:@"NOT (SELF IN %@)", weakSelf.lastSelectedList];
//                NSLog(@"%@", [Objs filteredArrayUsingPredicate:predicate]);
//                
//                [Objs enumerateObjectsUsingBlock:^(HXPhotoModel *photoMd, NSUInteger idx, BOOL * _Nonnull stop) {
//                    for (HXPhotoModel *subMd in weakSelf.lastSelectedList) {
//                        if ([photoMd.asset.localIdentifier isEqualToString:subMd.asset.localIdentifier]) {
//                            
//                        }
//                    }
//                }];
//                dispatch_async(dispatch_get_main_queue(), ^{
//                    
//                });
//            }];
//        } IsShowSelectTag:NO];
//    });
}
- (void)deleteSpecifiedModel:(HXPhotoModel *)model
{
    if (model.type == HXPhotoModelMediaTypeCameraPhoto) {
        
        [self.endCameraPhotos removeObject:model];
        [self.endSelectedCameraPhotos removeObject:model];
        [self.endCameraList removeObject:model];
        [self.endSelectedCameraList removeObject:model];
        [self.endSelectedPhotos removeObject:model];
        
    }else if (model.type == HXPhotoModelMediaTypeCameraVideo){
        
        [self.endCameraVideos removeObject:model];
        [self.endSelectedCameraVideos removeObject:model];
        [self.endCameraList removeObject:model];
        [self.endSelectedCameraList removeObject:model];
        [self.endSelectedVideos removeObject:model];
        
    }else if (model.type == HXPhotoModelMediaTypePhoto || (model.type == HXPhotoModelMediaTypePhotoGif || model.type == HXPhotoModelMediaTypeLivePhoto)) {
        
        [self.endSelectedPhotos removeObject:model];
        
    }else if (model.type == HXPhotoModelMediaTypeVideo) {
        
        [self.endSelectedVideos removeObject:model];
        
    }
    [self.endSelectedList removeObject:model];
}

- (void)addSpecifiedArrayToSelectedArray:(NSArray *)list
{
    for (HXPhotoModel *model in list) {
        if (model.type == HXPhotoModelMediaTypeCameraPhoto) {
            
            [self.endCameraPhotos addObject:model];
            [self.endSelectedCameraPhotos addObject:model];
            [self.endCameraList addObject:model];
            [self.endSelectedCameraList addObject:model];
            [self.endSelectedPhotos addObject:model];
            
        }else if (model.type == HXPhotoModelMediaTypeCameraVideo){
            
            [self.endCameraVideos addObject:model];
            [self.endSelectedCameraVideos addObject:model];
            [self.endCameraList addObject:model];
            [self.endSelectedCameraList addObject:model];
            [self.endSelectedVideos addObject:model];
            
        }else if (model.type == HXPhotoModelMediaTypePhoto || (model.type == HXPhotoModelMediaTypePhotoGif || model.type == HXPhotoModelMediaTypeLivePhoto)) {
            
            [self.endSelectedPhotos addObject:model];
            
        }else if (model.type == HXPhotoModelMediaTypeVideo) {
            
            [self.endSelectedVideos addObject:model];
            
        }
        [self.endSelectedList addObject:model];
    }
}

- (void)clearSelectedList {
    [self.endSelectedList removeAllObjects];
    [self.endCameraPhotos removeAllObjects];
    [self.endSelectedCameraPhotos removeAllObjects];
    [self.endCameraList removeAllObjects];
    [self.endSelectedCameraList removeAllObjects];
    [self.endSelectedPhotos removeAllObjects];
    [self.endCameraVideos removeAllObjects];
    [self.endSelectedCameraVideos removeAllObjects];
    [self.endCameraList removeAllObjects];
    [self.endSelectedCameraList removeAllObjects];
    [self.endSelectedVideos removeAllObjects];
    [self.endSelectedPhotos removeAllObjects];
    [self.endSelectedVideos removeAllObjects];
    self.endIsOriginal = NO;
    self.endPhotosTotalBtyes = nil;
}

- (void)getMaxAlbum {
    if ([PHPhotoLibrary authorizationStatus] != PHAuthorizationStatusAuthorized) {
        [[UIApplication sharedApplication].keyWindow showImageHUDText:[NSBundle hx_localizedStringForKey:@"无法访问照片，请前往设置中允许\n访问照片"]];
        return;
    }
    PHFetchResult *smartAlbums = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeSmartAlbum subtype:PHAssetCollectionSubtypeAlbumRegular options:nil];
    for (PHAssetCollection *collection in smartAlbums) {
        if ([[HXPhotoTools transFormPhotoTitle:collection.localizedTitle] isEqualToString:@"相机胶卷"] || [[HXPhotoTools transFormPhotoTitle:collection.localizedTitle] isEqualToString:@"所有照片"]) {
            PHFetchOptions *option = [[PHFetchOptions alloc] init];
            option.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"creationDate" ascending:YES]];
            if (self.type == HXPhotoManagerSelectedTypePhoto) {
                option.predicate = [NSPredicate predicateWithFormat:@"mediaType == %ld", PHAssetMediaTypeImage];
            }else if (self.type == HXPhotoManagerSelectedTypeVideo) {
                option.predicate = [NSPredicate predicateWithFormat:@"mediaType == %ld", PHAssetMediaTypeVideo];
            }
            PHFetchResult *result = [PHAsset fetchAssetsInAssetCollection:collection options:option];
            HXAlbumModel *albumModel = [[HXAlbumModel alloc] init];
            albumModel.count = result.count;
            albumModel.albumName = collection.localizedTitle;
            albumModel.result = result;
            self.tempAlbumMd = albumModel;
            break;
        }
    }
}

- (void)photoLibraryDidChange:(PHChange *)changeInstance {
    NSMutableArray *array = [NSMutableArray array];
    for (HXAlbumModel *albumModel in self.albums) {
        PHFetchResultChangeDetails *collectionChanges = [changeInstance changeDetailsForFetchResult:albumModel.result];
        if (collectionChanges) {
            [array addObject:@{@"collectionChanges" : collectionChanges ,@"model" : albumModel}];
        }
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.selectPhoto) {
            if (self.photoLibraryDidChangeWithPhotoViewController) {
                self.photoLibraryDidChangeWithPhotoViewController(array);
            }
        }
        if (self.photoLibraryDidChangeWithPhotoPreviewViewController) {
            self.photoLibraryDidChangeWithPhotoPreviewViewController(array);
        }
        if (self.photoLibraryDidChangeWithVideoViewController) {
            self.photoLibraryDidChangeWithVideoViewController(array);
        }
        if (array.count == 0 && self.saveSystemAblum) {
            PHFetchResultChangeDetails *collectionChanges = [changeInstance changeDetailsForFetchResult:self.tempAlbumMd.result];
            if (collectionChanges) {
                [array addObject:@{@"collectionChanges" : collectionChanges ,@"model" : self.tempAlbumMd}];
            }
        }
        if (array.count > 0) {
            if (self.photoLibraryDidChangeWithPhotoView) {
                self.photoLibraryDidChangeWithPhotoView(array,self.selectPhoto);
            }
        }
    });
}
- (void)dealloc {
    NSSLog(@"dealloc");
    [[PHPhotoLibrary sharedPhotoLibrary] unregisterChangeObserver:self];
}

@end
