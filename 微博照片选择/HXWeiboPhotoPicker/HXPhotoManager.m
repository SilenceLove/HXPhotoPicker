//
//  HX_PhotoManager.m
//  微博照片选择
//
//  Created by 洪欣 on 17/2/8.
//  Copyright © 2017年 洪欣. All rights reserved.
//

#import "HXPhotoManager.h"

#define iOS9Later ([UIDevice currentDevice].systemVersion.floatValue >= 9.0f)
@interface HXPhotoManager ()
@property (strong, nonatomic) NSMutableArray *albums;
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
    self.outerCamera = NO;
    self.openCamera = YES;
    self.lookLivePhoto = YES;
    self.lookGifPhoto = YES;
    self.selectTogether = YES;
    self.maxNum = 10;
    self.photoMaxNum = 9;
    self.videoMaxNum = 1;
    self.rowCount = 4;
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
    
    [smartAlbums enumerateObjectsUsingBlock:^(PHAssetCollection *collection, NSUInteger idx, BOOL * _Nonnull stop) {
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
            albumModel.albumName = [HXPhotoTools transFormPhotoTitle:collection.localizedTitle];
            albumModel.asset = result.lastObject;
            albumModel.result = result;
            [self.albums addObject:albumModel];
            
            if (isShow) {
                for (PHAsset *asset in result) {
                    for (HXPhotoModel *photoModel in self.selectedList) {
                        if ([asset.localIdentifier isEqualToString:photoModel.asset.localIdentifier]) {
                            albumModel.selectedCount++;
                            continue;
                        }
                    }
                }
            }
        }
    }];
    
    for (int i = 0; i<self.albums.count; i++) {
        HXAlbumModel *model = self.albums[i];
        if ([model.albumName isEqualToString:@"相机胶卷"]) {
            [self.albums removeObject:model];
            [self.albums insertObject:model atIndex:0];
            break;
        }
    }
    
    // 获取用户相册
    PHFetchResult *userAlbums = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeAlbum subtype:PHAssetCollectionSubtypeSmartAlbumUserLibrary options:nil];
    
    [userAlbums enumerateObjectsUsingBlock:^(PHAssetCollection *collection, NSUInteger idx, BOOL * _Nonnull stop) {
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
            albumModel.asset = result.lastObject;
            albumModel.result = result;
            [self.albums addObject:albumModel];
            if (isShow) {
                for (PHAsset *asset in result) {
                    for (HXPhotoModel *photoModel in self.selectedList) {
                        if ([asset.localIdentifier isEqualToString:photoModel.asset.localIdentifier]) {
                            albumModel.selectedCount++;
                            continue;
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
    NSInteger photoIndex = 0, videoIndex = 0, albumIndex = 0;
    NSInteger cameraIndex = self.openCamera ? 1 : 0;
    for (NSInteger i = result.count - 1 ; i >= 0 ; i--) {
        PHAsset *asset = result[i];
        HXPhotoModel *photoModel = [[HXPhotoModel alloc] init];
        photoModel.asset = asset;
        photoModel.albumListIndex = albumIndex + cameraIndex;
        if (self.selectedList.count > 0) {
            for (HXPhotoModel *model in self.selectedList) {
                if ([model.asset.localIdentifier isEqualToString:photoModel.asset.localIdentifier]) {
                    photoModel.selected = YES;
                }
                photoModel.isCloseLivePhoto = model.isCloseLivePhoto;
            }
        }
        if (asset.mediaType == PHAssetMediaTypeImage) {
            if ([[asset valueForKey:@"filename"] hasSuffix:@"GIF"]) {
                photoModel.type = self.lookGifPhoto ? HXPhotoModelMediaTypePhotoGif : HXPhotoModelMediaTypePhoto;
            }else {
                if (iOS9Later) {
                    if (asset.mediaSubtypes == PHAssetMediaSubtypePhotoLive) {
                        photoModel.type = self.lookLivePhoto ? HXPhotoModelMediaTypeLivePhoto : HXPhotoModelMediaTypePhoto;
                    }else {
                        photoModel.type = HXPhotoModelMediaTypePhoto;
                    }
                }else {
                    photoModel.type = HXPhotoModelMediaTypePhoto;
                }
            }
            photoModel.photoIndex = photoIndex;
            [photoAy addObject:photoModel];
            photoIndex++;
        }else if (asset.mediaType == PHAssetMediaTypeVideo) {
            photoModel.type = HXPhotoModelMediaTypeVideo;
            [[PHImageManager defaultManager] requestAVAssetForVideo:asset options:nil resultHandler:^(AVAsset * _Nullable asset, AVAudioMix * _Nullable audioMix, NSDictionary * _Nullable info) {
                photoModel.avAsset = asset;
            }];
            //            [[PHImageManager defaultManager] requestPlayerItemForVideo:asset options:nil resultHandler:^(AVPlayerItem * _Nullable playerItem, NSDictionary * _Nullable info) {
            //                photoModel.playerItem = playerItem;
            //            }];
            NSString *timeLength = [NSString stringWithFormat:@"%0.0f",asset.duration];
            photoModel.videoTime = [HXPhotoTools getNewTimeFromDurationSecond:timeLength.integerValue];
            photoModel.videoIndex = videoIndex;
            [videoAy addObject:photoModel];
            videoIndex++;
        }
        albumIndex++;
        photoModel.currentAlbumIndex = index;
        [objAy addObject:photoModel];
    }
    if (self.openCamera) {
        HXPhotoModel *model = [[HXPhotoModel alloc] init];
        model.type = HXPhotoModelMediaTypeCamera;
        if (photoAy.count == 0 && videoAy.count != 0) {
            model.thumbPhoto = [UIImage imageNamed:@"compose_photo_video@2x.png"];
        }else if (videoAy.count == 0) {
            model.thumbPhoto = [UIImage imageNamed:@"compose_photo_photograph@2x.png"];
        }else {
            model.thumbPhoto = [UIImage imageNamed:@"compose_photo_photograph@2x.png"];
        }
        [objAy insertObject:model atIndex:0];
    }
    if (index == 0) {
        if (self.cameraList.count > 0) {
            NSInteger listCount = self.cameraList.count;
            if (self.outerCamera) {
                listCount = self.cameraList.count - 1;
            }
            for (int i = 0; i < self.cameraList.count; i++) {
                HXPhotoModel *phMD = self.cameraList[i];
                phMD.albumListIndex = listCount--;
                [objAy insertObject:phMD atIndex:cameraIndex];
            }
            NSInteger photoCount = self.cameraPhotos.count - 1;
            for (int i = 0; i < self.cameraPhotos.count; i++) {
                HXPhotoModel *phMD = self.cameraPhotos[i];
                phMD.photoIndex = photoCount--;
                [photoAy insertObject:phMD atIndex:0];
            }
            NSInteger videoCount = self.cameraVideos.count - 1;
            for (int i = 0; i < self.cameraVideos.count; i++) {
                HXPhotoModel *phMD = self.cameraVideos[i];
                phMD.videoIndex = videoCount--;
                [videoAy insertObject:phMD atIndex:0];
            }
        }
    }
    if (list) {
        list(photoAy,videoAy,objAy);
    }
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

- (void)emptySelectedList
{
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

@end
