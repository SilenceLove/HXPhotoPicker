//
//  HX_PhotoManager.m
//  HXPhotoPickerExample
//
//  Created by Silence on 17/2/8.
//  Copyright © 2017年 Silence. All rights reserved.
//

#import "HXPhotoManager.h"
#import <mach/mach_time.h>
#import "HXAssetManager.h"
#import "PHAsset+HXExtension.h"

@interface HXPhotoManager ()
//@property (assign, nonatomic) BOOL hasLivePhoto;
//------// 当要删除的已选中的图片或者视频的时候需要在对应的end数组里面删除
// 例如: 如果删除的是通过相机拍的照片需要在 endCameraList 和 endCameraPhotos 数组删除对应的图片模型
@property (strong, nonatomic) NSMutableArray *selectedList;
@property (strong, nonatomic) NSMutableArray *selectedPhotos;
@property (strong, nonatomic) NSMutableArray *selectedVideos;
@property (strong, nonatomic) NSMutableArray *cameraList;
@property (strong, nonatomic) NSMutableArray *cameraPhotos;
@property (strong, nonatomic) NSMutableArray *cameraVideos;
@property (strong, nonatomic) NSMutableArray *endCameraList;
@property (strong, nonatomic) NSMutableArray *endCameraPhotos;
@property (strong, nonatomic) NSMutableArray *endCameraVideos;
@property (strong, nonatomic) NSMutableArray *selectedCameraList;
@property (strong, nonatomic) NSMutableArray *selectedCameraPhotos;
@property (strong, nonatomic) NSMutableArray *selectedCameraVideos;
@property (strong, nonatomic) NSMutableArray *endSelectedCameraList;
@property (strong, nonatomic) NSMutableArray *endSelectedCameraPhotos;
@property (strong, nonatomic) NSMutableArray *endSelectedCameraVideos;
@property (strong, nonatomic) NSMutableArray *endSelectedList;
@property (strong, nonatomic) NSMutableArray *endSelectedPhotos;
@property (strong, nonatomic) NSMutableArray *endSelectedVideos;


@property (strong, nonatomic) NSMutableArray *selectedAssetList;
@property (strong, nonatomic) NSMutableArray *tempSelectedModelList;

//------//
@property (assign, nonatomic) BOOL isOriginal;
@property (assign, nonatomic) BOOL endIsOriginal;
@property (copy, nonatomic) NSString *photosTotalBtyes;
@property (copy, nonatomic) NSString *endPhotosTotalBtyes;
@property (strong, nonatomic) NSMutableArray *iCloudUploadArray;
@property (strong, nonatomic) NSMutableArray *iCloudAssetArray;

@property (assign, nonatomic) BOOL firstHasCameraAsset;
@property (assign, nonatomic) BOOL supportLivePhoto;

@property (assign, nonatomic) BOOL hasAuthorization;
@property (strong, nonatomic) PHFetchOptions *fetchAlbumOptions;
/// 相机拍照临时具有的model(PHAsset不为nil)
@property (strong, nonatomic) NSMutableArray *tempCameraAssetModels;
@end

@implementation HXPhotoManager
#pragma mark - < 初始化 >
+ (instancetype)managerWithType:(HXPhotoManagerSelectedType)type {
    return [[self alloc] initWithType:type];
}
- (instancetype)initWithType:(HXPhotoManagerSelectedType)type {
    if (self = [super init]) {
        _type = type;
        [self setup];
    }
    return self;
}
- (instancetype)init {
    return [self initWithType:HXPhotoManagerSelectedTypePhoto];
}
- (void)setType:(HXPhotoManagerSelectedType)type {
    if ([HXPhotoCommon photoCommon].selectType != 2) {
        if (type != [HXPhotoCommon photoCommon].selectType) {
            [HXPhotoCommon photoCommon].cameraRollResult = nil;
        }
        [HXPhotoCommon photoCommon].selectType = type;
    }
    _fetchAlbumOptions = nil;
    _type = type;
}
- (NSOperationQueue *)dataOperationQueue {
    if (!_dataOperationQueue) {
        _dataOperationQueue = [[NSOperationQueue alloc] init];
        _dataOperationQueue.maxConcurrentOperationCount = 1;
    }
    return _dataOperationQueue;
}
- (void)setup {
    self.selectPhotoFinishDismissAnimated = YES;
    self.selectPhotoCancelDismissAnimated = YES;
    self.cameraFinishDismissAnimated = YES;
    self.cameraCancelDismissAnimated = YES;
    
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
    self.iCloudUploadArray = [NSMutableArray array];
    
    if (HX_IOS91Later) {
        self.supportLivePhoto = YES;
    }
    
//    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appBecomeActive) name:UIApplicationDidBecomeActiveNotification object:nil];
}
- (HXPhotoConfiguration *)configuration {
    if (!_configuration) {
        _configuration = [[HXPhotoConfiguration alloc] init];
    }
    return _configuration;
}
- (void)addCustomAssetModel:(NSArray<HXCustomAssetModel *> *)assetArray {
    if (!assetArray.count) return;
    if (![assetArray.firstObject isKindOfClass:[HXCustomAssetModel class]]) {
        if (HXShowLog) NSSLog(@"请传入装着HXCustomAssetModel对象的数组");
        return;
    }
    self.configuration.deleteTemporaryPhoto = NO;
    NSInteger photoMaxCount = self.configuration.photoMaxNum;
    NSInteger videoMaxCount = self.configuration.videoMaxNum;
    NSInteger maxCount = self.configuration.maxNum;
    NSInteger photoCount = self.endSelectedPhotos.count;
    NSInteger videoCount = self.endSelectedVideos.count;
    BOOL canAddPhoto;
    BOOL canAddVideo;
    BOOL selectTogether = self.configuration.selectTogether;
    HXPhotoModel *firstModel;
    for (HXCustomAssetModel *model in assetArray) {
        if (photoMaxCount > 0) {
            canAddPhoto = !(photoCount >= photoMaxCount);
        }else {
            canAddPhoto = !(photoCount + videoCount >= maxCount);
        }
        if (videoMaxCount > 0) {
            canAddVideo = !(videoCount >= videoMaxCount);
        }else {
            canAddVideo = !(videoCount + photoCount >= maxCount);
        }
        if (!selectTogether && firstModel) {
            if (firstModel.subType == HXPhotoModelMediaSubTypePhoto) {
                canAddVideo = NO;
            }else if (firstModel.subType == HXPhotoModelMediaSubTypeVideo) {
                canAddPhoto = NO;
            }
        }
        if (model.type == HXCustomAssetModelTypeLocalImage && (model.localImage || model.localImagePath)) {
            if (self.type == HXPhotoManagerSelectedTypeVideo) {
                continue;
            }
            HXPhotoModel *photoModel = [HXPhotoModel photoModelWithImage:model.localImage];
            if ([[[model.localImagePath pathExtension] lowercaseString] isEqualToString:@"gif"]) {
                photoModel.cameraPhotoType = HXPhotoModelMediaTypeCameraPhotoTypeLocalGif;
            }
            photoModel.imageSize = model.imageSize;
            photoModel.imageURL = model.localImagePath;
            photoModel.selected = canAddPhoto ? model.selected : NO;
            if (model.selected && canAddPhoto) {
                [self.endCameraPhotos addObject:photoModel];
                [self.endSelectedCameraPhotos addObject:photoModel];
                [self.endCameraList addObject:photoModel];
                [self.endSelectedCameraList addObject:photoModel];
                [self.endSelectedPhotos addObject:photoModel];
                [self.endSelectedList addObject:photoModel];
                firstModel = photoModel;
                photoCount++;
            }else {
                [self.endCameraPhotos addObject:photoModel];
                [self.endCameraList addObject:photoModel];
            }
        }else if (model.type == HXCustomAssetModelTypeNetWorkImage && model.networkImageURL) {
            if (self.type == HXPhotoManagerSelectedTypeVideo) {
                continue;
            }
            HXPhotoModel *photoModel = [HXPhotoModel photoModelWithImageURL:model.networkImageURL thumbURL:model.networkThumbURL];
            photoModel.imageSize = model.imageSize;
            photoModel.selected = canAddPhoto ? model.selected : NO;
            if (model.selected && canAddPhoto) {
                [self.endCameraPhotos addObject:photoModel];
                [self.endSelectedCameraPhotos addObject:photoModel];
                [self.endCameraList addObject:photoModel];
                [self.endSelectedCameraList addObject:photoModel];
                [self.endSelectedPhotos addObject:photoModel];
                [self.endSelectedList addObject:photoModel];
                firstModel = photoModel;
                photoCount++;
            }else {
                [self.endCameraPhotos addObject:photoModel];
                [self.endCameraList addObject:photoModel];
            }
        }else if (model.type == HXCustomAssetModelTypeLocalVideo) {
            if (self.type == HXPhotoManagerSelectedTypePhoto) {
                continue;
            }
            // 本地视频
            HXPhotoModel *photoModel = [HXPhotoModel photoModelWithVideoURL:model.localVideoURL];
            photoModel.imageSize = model.imageSize;
            if (photoModel.videoDuration >= self.configuration.videoMaximumSelectDuration + 1) {
                canAddVideo = NO;
            }else if (photoModel.videoDuration < self.configuration.videoMinimumSelectDuration) {
                canAddVideo = NO;
            }
            photoModel.selected = canAddVideo ? model.selected : NO;
            if (model.selected && canAddVideo) {
                [self.endCameraVideos addObject:photoModel];
                [self.endSelectedCameraVideos addObject:photoModel];
                [self.endCameraList addObject:photoModel];
                [self.endSelectedCameraList addObject:photoModel];
                [self.endSelectedVideos addObject:photoModel];
                [self.endSelectedList addObject:photoModel];
                firstModel = photoModel;
                videoCount++;
            }else {
                [self.endCameraVideos addObject:photoModel];
                [self.endCameraList addObject:photoModel];
            }
        }else if (model.type == HXCustomAssetModelTypeNetWorkVideo) {
            if (self.type == HXPhotoManagerSelectedTypePhoto) {
                continue;
            }
            // 网络视频
            HXPhotoModel *photoModel = [HXPhotoModel photoModelWithNetworkVideoURL:model.networkVideoURL videoCoverURL:model.networkImageURL videoDuration:model.videoDuration];
            photoModel.imageSize = model.imageSize;
            if (photoModel.videoDuration >= self.configuration.videoMaximumSelectDuration + 1) {
                canAddVideo = NO;
            }else if (photoModel.videoDuration < self.configuration.videoMinimumSelectDuration) {
                canAddVideo = NO;
            }
            photoModel.selected = canAddVideo ? model.selected : NO;
            if (model.selected && canAddVideo) {
                [self.endCameraVideos addObject:photoModel];
                [self.endSelectedCameraVideos addObject:photoModel];
                [self.endCameraList addObject:photoModel];
                [self.endSelectedCameraList addObject:photoModel];
                [self.endSelectedVideos addObject:photoModel];
                [self.endSelectedList addObject:photoModel];
                firstModel = photoModel;
                videoCount++;
            }else {
                [self.endCameraVideos addObject:photoModel];
                [self.endCameraList addObject:photoModel];
            }
        }else if (model.type == HXCustomAssetModelTypeLocalLivePhoto ||
                  model.type == HXCustomAssetModelTypeNetWorkLivePhoto) {
            if (self.type == HXPhotoManagerSelectedTypeVideo) {
                continue;
            }
            HXPhotoModel *photoModel;
            if (model.type == HXCustomAssetModelTypeLocalLivePhoto) {
                photoModel = [HXPhotoModel photoModelWithLivePhotoImage:model.localImage videoURL:model.localVideoURL];
                photoModel.imageURL = model.localImagePath;
            }else {
                photoModel = [HXPhotoModel photoModelWithLivePhotoNetWorkImage:model.networkImageURL netWorkVideoURL:model.networkVideoURL];
            }
            photoModel.imageSize = model.imageSize;
            photoModel.selected = canAddPhoto ? model.selected : NO;
            if (model.selected && canAddPhoto) {
                [self.endCameraPhotos addObject:photoModel];
                [self.endSelectedCameraPhotos addObject:photoModel];
                [self.endCameraList addObject:photoModel];
                [self.endSelectedCameraList addObject:photoModel];
                [self.endSelectedPhotos addObject:photoModel];
                [self.endSelectedList addObject:photoModel];
                firstModel = photoModel;
                photoCount++;
            }else {
                [self.endCameraPhotos addObject:photoModel];
                [self.endCameraList addObject:photoModel];
            }
        }
    }
    
    NSInteger i = 0;
    for (HXPhotoModel *model in self.afterSelectedArray) {
        model.selectedIndex = i;
        model.selectIndexStr = [NSString stringWithFormat:@"%ld",i + 1];
        i++;
    }
}
- (void)requestPhotosBytesWithCompletion:(void (^)(NSString *, NSUInteger))completion {
    [self.dataOperationQueue cancelAllOperations];
    self.selectPhotoTotalDataLengths = 0;
    if (!self.selectedPhotos.count) {
        if (completion) completion(nil, 0);
        return;
    }
    __block NSUInteger dataLength = 0;
    __block NSUInteger assetCount = 0;
    HXWeakSelf
    NSBlockOperation *operation = [NSBlockOperation blockOperationWithBlock:^{
        for (int i = 0 ; i < weakSelf.selectedPhotos.count ; i++) {
            HXPhotoModel *model = weakSelf.selectedPhotos[i];
            if (model.subType != HXPhotoModelMediaSubTypePhoto) {
                continue;
            }
            if (model.asset != nil && model.photoEdit == nil) {
                [model.asset hx_checkForModificationsWithAssetPathMethodCompletion:^(BOOL hasAdj) {
                    if (hasAdj) {
                        [model requestImageDataStartRequestICloud:nil progressHandler:nil success:^(NSData *imageData, UIImageOrientation orientation, HXPhotoModel *model, NSDictionary *info) {
                            model.assetByte = imageData.length;
                            dataLength += model.assetByte;
                            assetCount ++;
                            if (assetCount >= weakSelf.selectedPhotos.count) {
                                weakSelf.selectPhotoTotalDataLengths = &(dataLength);
                                NSString *bytes = [HXPhotoTools getBytesFromDataLength:dataLength];
                                dispatch_async(dispatch_get_main_queue(), ^{
                                    if (completion) completion(bytes, dataLength);
                                });
                            }
                        } failed:^(NSDictionary *info, HXPhotoModel *model) {
                            assetCount ++;
                            if (assetCount >= weakSelf.selectedPhotos.count) {
                                weakSelf.selectPhotoTotalDataLengths = &(dataLength);
                                NSString *bytes = [HXPhotoTools getBytesFromDataLength:dataLength];
                                dispatch_async(dispatch_get_main_queue(), ^{
                                    if (completion) completion(bytes, dataLength);
                                });
                            }
                        }];
                    }else {
                        [self requestPhotosBytesWithModel:model completion:^(NSUInteger byte) {
                            dataLength += byte;
                            assetCount ++;
                            if (assetCount >= weakSelf.selectedPhotos.count) {
                                weakSelf.selectPhotoTotalDataLengths = &(dataLength);
                                NSString *bytes = [HXPhotoTools getBytesFromDataLength:dataLength];
                                dispatch_async(dispatch_get_main_queue(), ^{
                                    if (completion) completion(bytes, dataLength);
                                });
                            }
                        }];
                    }
                }];
            }else {
                [self requestPhotosBytesWithModel:model completion:^(NSUInteger byte) {
                    dataLength += byte;
                    assetCount ++;
                    if (assetCount >= weakSelf.selectedPhotos.count) {
                        weakSelf.selectPhotoTotalDataLengths = &(dataLength);
                        NSString *bytes = [HXPhotoTools getBytesFromDataLength:dataLength];
                        dispatch_async(dispatch_get_main_queue(), ^{
                            if (completion) completion(bytes, dataLength);
                        });
                    }
                }];
            }
        }
    }];
    [self.dataOperationQueue addOperation:operation];
}
- (void)requestPhotosBytesWithModel:(HXPhotoModel *)model completion:(void (^)(NSUInteger))completion {
    if (model.assetByte == 0 && model.type != HXPhotoModelMediaTypeCameraPhoto) {
        [model requestImageDataStartRequestICloud:nil progressHandler:nil success:^(NSData *imageData, UIImageOrientation orientation, HXPhotoModel *model, NSDictionary *info) {
            model.assetByte = imageData.length;
            if (completion) {
                completion(imageData.length);
            }
        } failed:^(NSDictionary *info, HXPhotoModel *model) {
            if (completion) completion(0);
        }];
    }else {
        if (completion) {
            completion(model.assetByte);
        }
    }
}
- (PHFetchOptions *)fetchAlbumOptions {
    if (!_fetchAlbumOptions) {
        PHFetchOptions *options = [[PHFetchOptions alloc] init];
        if (self.configuration.creationDateSort) {
            options.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"creationDate" ascending:YES]];
        }
        if (!self.fetchOptionsPredicate) {
            if (self.type == HXPhotoManagerSelectedTypePhoto) {
                options.predicate = [NSPredicate predicateWithFormat:@"mediaType == %ld", PHAssetMediaTypeImage];
            }else if (self.type == HXPhotoManagerSelectedTypeVideo) {
                options.predicate = [NSPredicate predicateWithFormat:@"mediaType == %ld", PHAssetMediaTypeVideo];
            }
        }else {
            options.predicate = [NSPredicate predicateWithFormat:self.fetchOptionsPredicate];
        }
        _fetchAlbumOptions = options;
    }
    return _fetchAlbumOptions;
}
- (HXAlbumModel *)getCommonAlbumModel {
    NSString *cameraRollLocalIdentifier = [HXPhotoCommon photoCommon].cameraRollLocalIdentifier;
    PHAssetCollection *collection = [HXAssetManager fetchAssetCollectionWithIndentifier:cameraRollLocalIdentifier];
    HXAlbumModel *model = [self albumModelWithCollection:collection fetchAssets:YES];
    model.cameraCount = self.cameraList.count;
    model.index = 0;
    if (!model.count) {
        [HXPhotoCommon photoCommon].cameraRollLocalIdentifier = nil;
        [HXPhotoCommon photoCommon].cameraRollResult = nil;
        return nil;
    }
    return model;
}
- (void)getCameraRollAlbumCompletion:(void (^)(HXAlbumModel *albumModel))completion {
    if ([HXPhotoCommon photoCommon].cameraRollLocalIdentifier) {
        HXAlbumModel *albumModel = [self getCommonAlbumModel];
        if (completion && albumModel) {
            completion(albumModel);
            return;
        }
    }
    PHAssetCollection *cameraRollCollection = [HXAssetManager fetchCameraRollAlbumWithOptions:nil];
    if (cameraRollCollection) {
        [HXPhotoCommon photoCommon].cameraRollLocalIdentifier = cameraRollCollection.localIdentifier;
        HXAlbumModel *model = [self albumModelWithCollection:cameraRollCollection fetchAssets:YES];
        model.cameraCount = self.cameraList.count;
        model.index = 0;
        if (completion) completion(model);
    }
    if (![HXPhotoCommon photoCommon].cameraRollLocalIdentifier) {
        PHFetchOptions *option = [self fetchAlbumOptions];
        HXPhotoModel *photoMd = self.cameraList.firstObject;
        HXAlbumModel *albumModel = [[HXAlbumModel alloc] init];
        albumModel.cameraCount = self.cameraList.count;
        albumModel.albumName = [NSBundle hx_localizedStringForKey:@"所有照片"];
        albumModel.index = 0;
        albumModel.selectType = self.type;
        albumModel.tempImage = photoMd.thumbPhoto;
        albumModel.assetResult = [PHAsset fetchAssetsWithOptions:option];
        albumModel.count = albumModel.assetResult.count;
        if (completion) completion(albumModel);
    }
}
- (HXAlbumModel *)albumModelWithCollection:(PHAssetCollection *)collection
                               fetchAssets:(BOOL)fetchAssets {
    HXAlbumModel *albumModel = [[HXAlbumModel alloc] initWithCollection:collection options:self.fetchAlbumOptions];
    albumModel.selectType = self.type;
    if (fetchAssets) {
        [albumModel fetchAssetResult];
    }
    return albumModel;
}

- (void)getAllAlbumModelWithCompletion:(getAllAlbumListBlock)completion {
    NSMutableArray *albums = [NSMutableArray array];
    [HXAssetManager enumerateAllAlbumModelsWithOptions:self.fetchAlbumOptions usingBlock:^(HXAlbumModel * _Nonnull albumModel) {
        if (self.assetCollectionFilter &&
            self.assetCollectionFilter(albumModel.collection)) {
            return;
        }
        albumModel.selectType = self.type;
        [albumModel fetchAssetResult];
        if ([HXAssetManager isCameraRollAlbum:albumModel.collection]) {
            albumModel.cameraCount = [self cameraCount];
            albumModel.tempImage = [self firstCameraModel].thumbPhoto;
            albumModel.index = 0;
            [albums insertObject:albumModel atIndex:0];
        } else {
            if (albumModel.count > 0) {
                albumModel.cameraCount = [self cameraCount];
                [albums addObject:albumModel];
                albumModel.index = [albums indexOfObject:albumModel];
            }
        }
    }];
    if (!albums.count) {
        BOOL created = NO;
        PHAuthorizationStatus status = [HXPhotoTools authorizationStatus];
        if (status == PHAuthorizationStatusAuthorized) {
            created = YES;
        }
#ifdef __IPHONE_14_0
        else if (@available(iOS 14, *)) {
            if (status == PHAuthorizationStatusLimited) {
                created = YES;
            }
        }
#endif
        if (created) {
            HXPhotoModel *photoMd = self.cameraList.firstObject;
            HXAlbumModel *albumModel;
            if ([HXPhotoCommon photoCommon].cameraRollLocalIdentifier) {
                albumModel = [self getCommonAlbumModel];
            }else {
                albumModel = [[HXAlbumModel alloc] init];
                albumModel.assetResult = [PHAsset fetchAssetsWithOptions:self.fetchAlbumOptions];
                albumModel.count = albumModel.assetResult.count;
            }
            albumModel.cameraCount = self.cameraList.count;
            albumModel.albumName = [NSBundle hx_localizedStringForKey:@"所有照片"];
            albumModel.index = 0;
            albumModel.selectType = self.type;
            albumModel.tempImage = photoMd.thumbPhoto;
            if (self.firstHasCameraAsset &&
                self.configuration.saveSystemAblum) {
                // 防止直接打开相机并没有打开相册,导致相册列表为空,拍的照片没有保存到相册列表
                if (self.cameraList.count) {
                    [albums addObject:albumModel];
                    self.firstHasCameraAsset = NO;
                }
            }else {
                [albums addObject:albumModel];
            }
        }
    }
    
    if (completion) {
        completion(albums);
    };
}
- (HXPhotoModel *)photoModelWithAsset:(PHAsset *)asset {
    HXPhotoModel *photoModel = [[HXPhotoModel alloc] init];
    photoModel.asset = asset;
    // ios13之后可能不准，但是无关紧要。
    // 因为在获取的时候已经做了iCloud判断了。这里只是在展示的时候方便辨别
    BOOL isICloud = [[asset valueForKey:@"isCloudPlaceholder"] boolValue];
    if (isICloud) {
        if (_iCloudAssetArray.count) {
            if (![_iCloudAssetArray containsObject:asset]) {
                photoModel.isICloud = YES;
            }
        }else {
            photoModel.isICloud = YES;
        }
    }
    if (_selectedAssetList) {
        if ([_selectedAssetList containsObject:asset]) {
            HXPhotoModel *selectModel = [self.tempSelectedModelList objectAtIndex:[_selectedAssetList indexOfObject:asset]];
            photoModel.photoEdit = selectModel.photoEdit;
            photoModel.thumbPhoto = selectModel.thumbPhoto;
            photoModel.previewPhoto = selectModel.previewPhoto;
            photoModel.videoURL = selectModel.videoURL;
            if (selectModel.subType == HXPhotoModelMediaSubTypePhoto) {
                if (selectModel.type == HXPhotoModelMediaTypeCameraPhoto) {
                    [self.selectedCameraPhotos replaceObjectAtIndex:[self.selectedCameraPhotos indexOfObject:selectModel] withObject:photoModel];
                }else {
                    [self.selectedPhotos replaceObjectAtIndex:[self.selectedPhotos indexOfObject:selectModel] withObject:photoModel];
                }
            }else if (selectModel.subType == HXPhotoModelMediaSubTypeVideo) {
                if (selectModel.type == HXPhotoModelMediaTypeCameraVideo) {
                    [self.selectedCameraVideos replaceObjectAtIndex:[self.selectedCameraVideos indexOfObject:selectModel] withObject:photoModel];
                }else {
                    [self.selectedVideos replaceObjectAtIndex:[self.selectedVideos indexOfObject:selectModel] withObject:photoModel];
                }
            }
            [self.selectedList replaceObjectAtIndex:[self.selectedList indexOfObject:selectModel] withObject:photoModel];
            photoModel.selected = YES;
            photoModel.selectedIndex = selectModel.selectedIndex;
            photoModel.selectIndexStr = selectModel.selectIndexStr;
            
            [self.tempSelectedModelList removeObjectAtIndex:[_selectedAssetList indexOfObject:asset]];
            [_selectedAssetList removeObject:asset];
        }
    }
    if (asset.mediaType == PHAssetMediaTypeImage) {
        photoModel.subType = HXPhotoModelMediaSubTypePhoto;
        if ([[asset valueForKey:@"filename"] hasSuffix:@"GIF"] &&
            self.configuration.lookGifPhoto) {
            
            photoModel.type = HXPhotoModelMediaTypePhotoGif;
            
        }else if (self.supportLivePhoto &&
                  self.configuration.lookLivePhoto &&
                  asset.mediaSubtypes == PHAssetMediaSubtypePhotoLive ){
            photoModel.type =  HXPhotoModelMediaTypeLivePhoto;
        }else {
            photoModel.type = HXPhotoModelMediaTypePhoto;
        }
    }else if (asset.mediaType == PHAssetMediaTypeVideo) {
        photoModel.subType = HXPhotoModelMediaSubTypeVideo;
        photoModel.type = HXPhotoModelMediaTypeVideo;
        // 默认视频都是可选的
        [self changeModelVideoState:photoModel];
    }
    return photoModel;
}
- (void)getPhotoListWithAlbumModel:(HXAlbumModel *)albumModel
                          complete:(getPhotoListBlock)complete {
    
    if (self.selectedList.count) {
        self.selectedAssetList = [NSMutableArray arrayWithCapacity:self.selectedList.count];
        self.tempSelectedModelList = [NSMutableArray arrayWithCapacity:self.selectedList.count];
        NSInteger index = 0;
        for (HXPhotoModel *model in _selectedList) {
            model.selectedIndex = index;
            model.selectIndexStr = @(index + 1).stringValue;
            if (model.asset) {
                [self.selectedAssetList addObject:model.asset];
                [self.tempSelectedModelList addObject:model];
            }
            index++;
        }
    }
    if (self.iCloudUploadArray.count) {
        self.iCloudAssetArray = [NSMutableArray arrayWithCapacity:self.iCloudUploadArray.count];
        for (HXPhotoModel *model in self.iCloudUploadArray) {
            if (model.asset) {
                [self.iCloudAssetArray addObject:model.asset];
            }
        }
    }
    __block HXPhotoModel *firstSelectModel;
    if (!albumModel.assetResult) {
        [albumModel fetchAssetResult];
    }
    PHFetchResult *result = albumModel.assetResult;
    NSInteger allCount;
    if (self.type == HXPhotoManagerSelectedTypePhoto) {
        allCount = [result countOfAssetsWithMediaType:PHAssetMediaTypeImage];
    }else if (self.type == HXPhotoManagerSelectedTypeVideo) {
        allCount = [result countOfAssetsWithMediaType:PHAssetMediaTypeVideo];
    }else {
        allCount = result.count;
    }
    NSMutableArray *allArray = [NSMutableArray arrayWithCapacity:allCount + self.cameraList.count + 1];
    __block NSUInteger photoCount = 0;
    __block NSUInteger videoCount = 0;
    if (self.configuration.reverseDate) {
        [result enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(PHAsset *asset, NSUInteger idx, BOOL * _Nonnull stop) {
            if (self.type == HXPhotoManagerSelectedTypePhoto && asset.mediaType != PHAssetMediaTypeImage) {
                return;
            }else if (self.type == HXPhotoManagerSelectedTypeVideo && asset.mediaType != PHAssetMediaTypeVideo) {
                return;
            }
            BOOL filter = NO;
            if (self.assetFilter) {
                filter = self.assetFilter(albumModel, asset);
            }
            if (!filter) {
                HXPhotoModel *photoModel = [self photoModelWithAsset:asset];
                if (!firstSelectModel && photoModel.selectIndexStr) {
                    firstSelectModel = photoModel;
                }
                photoModel.currentAlbumIndex = albumModel.index;
                if (photoModel.subType == HXPhotoModelMediaSubTypePhoto) {
                    photoCount++;
                }else if (photoModel.subType == HXPhotoModelMediaSubTypeVideo) {
                    videoCount++;
                }
                [allArray addObject:photoModel];
            }
        }];
    }else {
        [result enumerateObjectsUsingBlock:^(PHAsset *asset, NSUInteger idx, BOOL * _Nonnull stop) {
            if (self.type == HXPhotoManagerSelectedTypePhoto && asset.mediaType != PHAssetMediaTypeImage) {
                return;
            }else if (self.type == HXPhotoManagerSelectedTypeVideo && asset.mediaType != PHAssetMediaTypeVideo) {
                return;
            }
            BOOL filter = NO;
            if (self.assetFilter) {
                filter = self.assetFilter(albumModel, asset);
            }
            if (!filter) {
                HXPhotoModel *photoModel = [self photoModelWithAsset:asset];
                if (!firstSelectModel && photoModel.selectIndexStr) {
                    firstSelectModel = photoModel;
                }
                photoModel.currentAlbumIndex = albumModel.index;
                if (photoModel.subType == HXPhotoModelMediaSubTypePhoto) {
                    photoCount++;
                }else if (photoModel.subType == HXPhotoModelMediaSubTypeVideo) {
                    videoCount++;
                }
                [allArray addObject:photoModel];
            }
        }];
    }
    
    [self.selectedAssetList removeAllObjects];
    self.selectedAssetList = nil;
    [self.tempSelectedModelList removeAllObjects];
    self.tempSelectedModelList = nil;
    [self.iCloudAssetArray removeAllObjects];
    self.iCloudAssetArray = nil;
    
    NSInteger cameraIndex = self.configuration.openCamera ? 1 : 0;
    NSMutableArray *previewArray;
    if (self.configuration.openCamera) {
        previewArray = allArray.mutableCopy;
        HXPhotoModel *model = [[HXPhotoModel alloc] init];
        model.type = HXPhotoModelMediaTypeCamera;
        if (self.configuration.photoListTakePhotoNormalImageNamed) {
            model.cameraNormalImageNamed = self.configuration.photoListTakePhotoNormalImageNamed;
            if (self.configuration.photoListTakePhotoSelectImageNamed) {
                model.cameraPreviewImageNamed = self.configuration.photoListTakePhotoSelectImageNamed;
            }else {
                model.cameraPreviewImageNamed = self.configuration.photoListTakePhotoNormalImageNamed;
            }
        }else {
            if (self.configuration.type == HXConfigurationTypeWXChat ||
                self.configuration.type == HXConfigurationTypeWXMoment) {
                    model.cameraNormalImageNamed = @"hx_takePhoto";
                    model.cameraPreviewImageNamed = @"hx_takePhoto";
            }else {
                model.cameraNormalImageNamed = @"hx_compose_photo_photograph";
                model.cameraPreviewImageNamed = @"hx_takePhoto";
            }
        }
        if (!self.configuration.reverseDate) {
            [allArray addObject:model];
        }else {
            [allArray insertObject:model atIndex:0];
        }
    }
    if ([HXPhotoTools authorizationStatusIsLimited]) {
        if (!self.configuration.openCamera) {
            previewArray = allArray.mutableCopy;
        }
        HXPhotoModel *model = [[HXPhotoModel alloc] init];
        model.type = HXPhotoModelMediaTypeLimit;
        if (!self.configuration.reverseDate) {
            if (self.configuration.openCamera) {
                [allArray insertObject:model atIndex:allArray.count - 1];
            }else {
                [allArray addObject:model];
            }
        }else {
            [allArray insertObject:model atIndex:cameraIndex];
        }
        cameraIndex++;
    }
    if (_tempCameraAssetModels && !self.configuration.singleSelected) {
        NSInteger index = 0;
        for (HXPhotoModel *model in _tempCameraAssetModels) {
            if (self.configuration.reverseDate) {
                [allArray insertObject:model atIndex:cameraIndex + index];
                if (previewArray) {
                    [previewArray insertObject:model atIndex:index];
                }
            }else {
                NSInteger count = allArray.count;
                NSInteger atIndex = (count - cameraIndex) < 0 ? 0 : count - cameraIndex;
                [allArray insertObject:model atIndex:atIndex];
                if (previewArray) {
                    [previewArray addObject:model];
                }
            }
            index++;
        }
    }
    if (self.cameraList.count) {
        NSInteger index = 0;
        for (HXPhotoModel *model in self.cameraList) {
            if ([self.selectedCameraList containsObject:model]) {
                model.selected = YES;
                model.selectedIndex = [self.selectedList indexOfObject:model];
                model.selectIndexStr = [NSString stringWithFormat:@"%ld",model.selectedIndex + 1];
            }else {
                model.selected = NO;
                model.selectIndexStr = @"";
                model.selectedIndex = 0;
            }
            model.currentAlbumIndex = albumModel.index;
            if (self.configuration.reverseDate) {
                [allArray insertObject:model atIndex:cameraIndex + index];
                if (previewArray) {
                    [previewArray insertObject:model atIndex:index];
                }
            }else {
                NSInteger count = allArray.count;
                NSInteger atIndex = (count - cameraIndex) < 0 ? 0 : count - cameraIndex;
                [allArray insertObject:model atIndex:atIndex];
                if (previewArray) {
                    [previewArray addObject:model];
                }
            }
            index++;
        }
    }
    if (complete) {
        complete(allArray, previewArray ?: allArray, photoCount, videoCount, firstSelectModel, albumModel);
    }
}
- (void)addICloudModel:(HXPhotoModel *)model {
    if (![self.iCloudUploadArray containsObject:model]) {
        [self.iCloudUploadArray addObject:model];
    }
}
- (NSString *)maximumOfJudgment:(HXPhotoModel *)model {
    if (model.subType == HXPhotoModelMediaSubTypePhoto &&
        !model.networkPhotoUrl) {
        if (self.configuration.selectPhotoLimitSize && self.configuration.limitPhotoSize > 0) {
            if (model.assetByte == 0 && !model.requestAssetByte && model.type != HXPhotoModelMediaTypeCameraPhoto) {
                model.requestAssetByte = YES;
                [model requestImageDataStartRequestICloud:nil progressHandler:nil success:^(NSData * _Nullable imageData, UIImageOrientation orientation, HXPhotoModel * _Nullable model, NSDictionary * _Nullable info) {
                    model.assetByte = imageData.length;
                    model.requestAssetByte = NO;
                } failed:^(NSDictionary * _Nullable info, HXPhotoModel * _Nullable model) {
                    model.requestAssetByte = NO;
                }];
            }
            if (model.requestAssetByte) {
                return [NSBundle hx_localizedStringForKey:@"正在获取照片大小，请稍等"];
            }
            if (model.assetByte > self.configuration.limitPhotoSize) {
                return [NSString stringWithFormat:[NSBundle hx_localizedStringForKey:@"照片大小超过最大限制%@"], [HXPhotoTools getBytesFromDataLength:self.configuration.limitPhotoSize]];
            }
        }
    }else if (model.subType == HXPhotoModelMediaSubTypeVideo &&
              model.cameraVideoType != HXPhotoModelMediaTypeCameraVideoTypeNetWork) {
        if (self.configuration.selectVideoLimitSize && self.configuration.limitVideoSize > 0) {
            if (model.assetByte > self.configuration.limitVideoSize) {
                return [NSString stringWithFormat:[NSBundle hx_localizedStringForKey:@"视频大小超过最大限制%@"], [HXPhotoTools getBytesFromDataLength:self.configuration.limitVideoSize]];
            }
        }
    }
    if (self.shouldSelectModel) {
        if (self.shouldSelectModel(model)) {
            return self.shouldSelectModel(model);
        }
    }
    if ([self beforeSelectCountIsMaximum]) {
        // 已经达到最大选择数 [NSString stringWithFormat:@"最多只能选择%ld个",manager.maxNum]
        return [NSString stringWithFormat:[NSBundle hx_localizedStringForKey:@"最多只能选择%ld个"],self.configuration.maxNum];
    }
    if (self.type == HXPhotoManagerSelectedTypePhotoAndVideo) {
        if (model.subType == HXPhotoModelMediaSubTypePhoto) {
            if (!self.configuration.selectTogether) { // 是否支持图片视频同时选择
                if (self.selectedVideos.count > 0 ) {
                    // 已经选择了视频,不能再选图片
                    return [NSBundle hx_localizedStringForKey:@"图片不能和视频同时选择"];
                }
            }
            
            if ([self beforeSelectPhotoCountIsMaximum]) {
                // 已经达到图片最大选择数
                NSUInteger maxSelectCount;
                if (self.configuration.photoMaxNum > 0) {
                    maxSelectCount = self.configuration.photoMaxNum;
                }else {
                    maxSelectCount = self.configuration.maxNum - self.selectedVideos.count;
                }
                return [NSString stringWithFormat:[NSBundle hx_localizedStringForKey:@"最多只能选择%ld张图片"],maxSelectCount];
            }
        }else if (model.subType == HXPhotoModelMediaSubTypeVideo) {
            if (!self.configuration.selectTogether) { // 是否支持图片视频同时选择
                if (self.selectedPhotos.count > 0 ) {
                    // 已经选择了图片,不能再选视频
                    return [NSBundle hx_localizedStringForKey:@"视频不能和图片同时选择"];
                }
            }
            if ([self beforeSelectVideoCountIsMaximum]) {
                // 已经达到视频最大选择数
                NSUInteger maxSelectCount;
                if (self.configuration.videoMaxNum > 0) {
                    maxSelectCount = self.configuration.videoMaxNum;
                }else {
                    maxSelectCount = self.configuration.maxNum - self.selectedPhotos.count;
                }
                return [NSString stringWithFormat:[NSBundle hx_localizedStringForKey:@"最多只能选择%ld个视频"],maxSelectCount];
            }
        }
    }else if (self.type == HXPhotoManagerSelectedTypePhoto) {
        if (model.subType == HXPhotoModelMediaSubTypeVideo) {
            // 已经选择了图片,不能再选视频
            return [NSBundle hx_localizedStringForKey:@"视频不能和图片同时选择"];
        }
        if ([self beforeSelectPhotoCountIsMaximum]) {
            NSUInteger maxSelectCount;
            if (self.configuration.photoMaxNum > 0) {
                maxSelectCount = self.configuration.photoMaxNum;
            }else {
                maxSelectCount = self.configuration.maxNum;
            }
            // 已经达到图片最大选择数
            return [NSString stringWithFormat:[NSBundle hx_localizedStringForKey:@"最多只能选择%ld张图片"],maxSelectCount];
        }
    }else if (self.type == HXPhotoManagerSelectedTypeVideo) {
        if (model.subType == HXPhotoModelMediaSubTypePhoto) {
            // 已经选择了图片,不能再选视频
            return [NSBundle hx_localizedStringForKey:@"图片不能和视频同时选择"];
        }
        if ([self beforeSelectVideoCountIsMaximum]) {
            NSUInteger maxSelectCount;
            if (self.configuration.videoMaxNum > 0) {
                maxSelectCount = self.configuration.videoMaxNum;
            }else {
                maxSelectCount = self.configuration.maxNum;
            }
            // 已经达到视频最大选择数
            return [NSString stringWithFormat:[NSBundle hx_localizedStringForKey:@"最多只能选择%ld个视频"],maxSelectCount];
        }
    }
    if (model.subType == HXPhotoModelMediaSubTypeVideo) {
        if (round(model.videoDuration) < self.configuration.videoMinimumSelectDuration) { 
            return [NSString stringWithFormat:[NSBundle hx_localizedStringForKey:@"视频少于%ld秒，无法选择"], self.configuration.videoMinimumSelectDuration];
        }else if (round(model.videoDuration) >= self.configuration.videoMaximumSelectDuration + 1) {
            if (self.configuration.selectVideoBeyondTheLimitTimeAutoEdit &&
                self.configuration.videoCanEdit) {
                if (model.cameraVideoType == HXPhotoModelMediaTypeCameraVideoTypeNetWork) {
                    if (self.configuration.selectNetworkVideoCanEdit) {
                        return @"selectVideoBeyondTheLimitTimeAutoEdit";
                    }
                }else {
                    return @"selectVideoBeyondTheLimitTimeAutoEdit";
                }
            }else {
                return [NSString stringWithFormat:[NSBundle hx_localizedStringForKey:@"视频大于%ld秒，无法选择"], self.configuration.videoMaximumSelectDuration];
            }
        }
    } 
    return nil;
}
#pragma mark - < 改变模型的视频状态 >
- (void)changeModelVideoState:(HXPhotoModel *)model {
    if (self.configuration.specialModeNeedHideVideoSelectBtn) {
        if (self.videoSelectedType == HXPhotoManagerVideoSelectedTypeSingle &&
            model.subType == HXPhotoModelMediaSubTypeVideo) {
            model.needHideSelectBtn = YES;
        }
    }
    if (model.subType == HXPhotoModelMediaSubTypeVideo) {
        if (model.videoDuration < self.configuration.videoMinimumSelectDuration) {
            model.videoState = HXPhotoModelVideoStateUndersize;
        }else if (model.videoDuration >= self.configuration.videoMaximumSelectDuration + 1) {
            model.videoState = HXPhotoModelVideoStateOversize;
        }
    }
}
- (HXPhotoManagerVideoSelectedType)videoSelectedType {
    if (self.type == HXPhotoManagerSelectedTypePhotoAndVideo && self.configuration.videoMaxNum == 1 && !self.configuration.selectTogether) {
        return HXPhotoManagerVideoSelectedTypeSingle;
    }
    return HXPhotoManagerVideoSelectedTypeNormal;
}
- (BOOL)videoCanSelected {
    if (self.videoSelectedType == HXPhotoManagerVideoSelectedTypeSingle) {
        if (self.selectedPhotos.count) {
            return NO;
        }
    }
    return YES;
}
- (NSInteger)cameraCount {
    return self.cameraList.count;
}
- (NSInteger)cameraPhotoCount {
    return self.cameraPhotos.count;
}
- (NSInteger)cameraVideoCount {
    return self.cameraVideos.count;
}
- (HXPhotoModel *)firstCameraModel {
    return self.cameraList.firstObject;
}
#pragma mark - < 关于选择完成之前的一些方法 > 
- (NSInteger)selectedCount {
    return self.selectedList.count;
}
- (NSInteger)selectedPhotoCount {
    return self.selectedPhotos.count;
}
- (NSInteger)selectedVideoCount {
    return self.selectedVideos.count;
}
- (NSArray *)selectedArray {
    return self.selectedList;
}
- (NSArray *)selectedPhotoArray {
    return self.selectedPhotos;
}
- (NSArray *)selectedVideoArray {
    return self.selectedVideos;
}
- (BOOL)original {
    return self.isOriginal;
}
- (void)setOriginal:(BOOL)original {
    self.isOriginal = original;
}
- (BOOL)beforeSelectCountIsMaximum {
    if (self.selectedList.count >= self.configuration.maxNum) {
        return YES;
    }
    return NO;
}
- (BOOL)beforeSelectPhotoCountIsMaximum {
    if (self.configuration.photoMaxNum > 0) {
        if (self.selectedPhotos.count >= self.configuration.photoMaxNum) {
            return YES;
        }
    }else {
        if (self.selectedPhotos.count + self.selectedVideos.count >= self.configuration.maxNum) {
            return YES;
        }
    }
    return NO;
}
- (BOOL)beforeSelectVideoCountIsMaximum {
    if (self.configuration.videoMaxNum > 0) {
        if (self.selectedVideos.count >= self.configuration.videoMaxNum) {
            return YES;
        }
    }else {
        if (self.selectedVideos.count + self.selectedPhotos.count >= self.configuration.maxNum) {
            return YES;
        }
    }
    return NO;
}
- (void)beforeSelectedListdeletePhotoModel:(HXPhotoModel *)model {
    if (![self.selectedList containsObject:model]) {
        return;
    }
    model.selected = NO;
    model.selectIndexStr = @"";
    model.selectedIndex = 0;
    if (model.subType == HXPhotoModelMediaSubTypePhoto) {
        [self.selectedPhotos removeObject:model];
        if (model.type == HXPhotoModelMediaTypeCameraPhoto) {
            // 为相机拍的照片时
            [self.selectedCameraPhotos removeObject:model];
            [self.selectedCameraList removeObject:model];
        }else {
            model.thumbPhoto = nil;
            model.previewPhoto = nil;
        }
    }else if (model.subType == HXPhotoModelMediaSubTypeVideo) {
        [self.selectedVideos removeObject:model];
        if (model.type == HXPhotoModelMediaTypeCameraVideo) {
            // 为相机录的视频时
            [self.selectedCameraVideos removeObject:model];
            [self.selectedCameraList removeObject:model];
        }else {
            model.thumbPhoto = nil;
            model.previewPhoto = nil;
        }
    }
    [self.selectedList removeObject:model];
    
    int i = 0;
    for (HXPhotoModel *model in self.selectedList) {
        model.selectIndexStr = [NSString stringWithFormat:@"%d",i + 1];
        i++;
    }
}
- (void)beforeSelectedListAddPhotoModel:(HXPhotoModel *)model {
    if (model.subType == HXPhotoModelMediaSubTypePhoto) {
        [self.selectedPhotos addObject:model];
        if (model.type == HXPhotoModelMediaTypeCameraPhoto) {
            // 为相机拍的照片时
            [self.selectedCameraPhotos addObject:model];
            [self.selectedCameraList addObject:model];
        }
    }else if (model.subType == HXPhotoModelMediaSubTypeVideo) { 
        [self.selectedVideos addObject:model];
        if (model.type == HXPhotoModelMediaTypeCameraVideo) {
            // 为相机录的视频时
            [self.selectedCameraVideos addObject:model];
            [self.selectedCameraList addObject:model];
        }
    }
    [self.selectedList addObject:model];
    model.selected = YES;
    model.selectedIndex = [self.selectedList indexOfObject:model];
    model.selectIndexStr = [NSString stringWithFormat:@"%ld",model.selectedIndex  + 1];
} 
- (void)beforeListAddCameraPhotoModel:(HXPhotoModel *)model {
    // 默认视频都是可选的
    [self changeModelVideoState:model];
    
    model.dateCellIsVisible = YES;
    //    NSInteger cameraIndex = self.configuration.openCamera ? 1 : 0;
    if (model.type == HXPhotoModelMediaTypeCameraPhoto ||
        model.type == HXPhotoModelMediaTypeCameraVideo) {
        if (self.configuration.reverseDate) {
            [self.cameraList insertObject:model atIndex:0];
        }else {
            [self.cameraList addObject:model];
        }
        if (model.type == HXPhotoModelMediaTypeCameraPhoto) {
            [self.cameraPhotos addObject:model];
        }else if (model.type == HXPhotoModelMediaTypeCameraVideo) {
            [self.cameraVideos addObject:model];
        }
    }
}
- (void)beforeListAddCameraTakePicturesModel:(HXPhotoModel *)model {
    [self beforeListAddCameraPhotoModel:model];
    if (self.shouldSelectModel) {
        if (self.shouldSelectModel(model)) {
            return;
        }
    }
    if (model.subType == HXPhotoModelMediaSubTypePhoto) {
        if (self.type == HXPhotoManagerSelectedTypeVideo) {
            return;
        }
        if (![self beforeSelectPhotoCountIsMaximum]) {
            if (!self.configuration.selectTogether) {
                if (self.selectedList.count > 0) {
                    HXPhotoModel *phMd = self.selectedList.firstObject;
                    if (phMd.subType == HXPhotoModelMediaSubTypePhoto) {
                        if (model.type == HXPhotoModelMediaTypeCameraPhoto) {
                            [self.selectedCameraPhotos insertObject:model atIndex:0];
                            [self.selectedCameraList addObject:model];
                        }
                        [self.selectedPhotos addObject:model];
                        [self.selectedList addObject:model];
                        model.selected = YES;
                        model.selectIndexStr = [NSString stringWithFormat:@"%ld",[self.selectedList indexOfObject:model] + 1];
                    }
                }else {
                    if (model.type == HXPhotoModelMediaTypeCameraPhoto) {
                        [self.selectedCameraPhotos insertObject:model atIndex:0];
                        [self.selectedCameraList addObject:model];
                    }
                    [self.selectedPhotos addObject:model];
                    [self.selectedList addObject:model];
                    model.selected = YES;
                    model.selectIndexStr = [NSString stringWithFormat:@"%ld",[self.selectedList indexOfObject:model] + 1];
                }
            }else {
                if (model.type == HXPhotoModelMediaTypeCameraPhoto) {
                    [self.selectedCameraPhotos insertObject:model atIndex:0];
                    [self.selectedCameraList addObject:model];
                }
                [self.selectedPhotos addObject:model];
                [self.selectedList addObject:model];
                model.selected = YES;
                model.selectIndexStr = [NSString stringWithFormat:@"%ld",[self.selectedList indexOfObject:model] + 1];
            }
        }
    }else if (model.subType == HXPhotoModelMediaSubTypeVideo) {
        if (self.type == HXPhotoManagerSelectedTypePhoto) {
            return;
        }
        // 当选中视频个数没有达到最大个数时就添加到选中数组中
        if (![self beforeSelectVideoCountIsMaximum] && model.videoDuration <= self.configuration.videoMaximumSelectDuration) {
            if (!self.configuration.selectTogether) {
                if (self.selectedList.count > 0) {
                    HXPhotoModel *phMd = self.selectedList.firstObject;
                    if (phMd.subType == HXPhotoModelMediaSubTypeVideo) {
                        if (model.type == HXPhotoModelMediaTypeCameraVideo) {
                            [self.selectedCameraVideos insertObject:model atIndex:0];
                            [self.selectedCameraList addObject:model];
                        }
                        [self.selectedVideos addObject:model];
                        [self.selectedList addObject:model];
                        model.selected = YES;
                        model.selectIndexStr = [NSString stringWithFormat:@"%ld",[self.selectedList indexOfObject:model] + 1];
                    }
                }else {
                    if (!model.needHideSelectBtn) {
                        if (model.type == HXPhotoModelMediaTypeCameraVideo) {
                            [self.selectedCameraVideos insertObject:model atIndex:0];
                            [self.selectedCameraList addObject:model];
                        }
                        [self.selectedVideos addObject:model];
                        [self.selectedList addObject:model];
                        model.selected = YES;
                        model.selectIndexStr = [NSString stringWithFormat:@"%ld",[self.selectedList indexOfObject:model] + 1];
                    }
                }
            }else {
                if (model.type == HXPhotoModelMediaTypeCameraVideo) {
                    [self.selectedCameraVideos insertObject:model atIndex:0];
                    [self.selectedCameraList addObject:model];
                }
                [self.selectedVideos addObject:model];
                [self.selectedList addObject:model];
                model.selected = YES;
                model.selectIndexStr = [NSString stringWithFormat:@"%ld",[self.selectedList indexOfObject:model] + 1];
            }
        }
    }
}

/// 完成之前是否可以选择照片
- (BOOL)beforeCanSelectPhoto {
    if (!self.configuration.selectTogether) {
        if (!self.selectedVideoCount && !self.beforeSelectPhotoCountIsMaximum) {
            return YES;
        }
    }else {
        if (!self.beforeSelectPhotoCountIsMaximum) {
            return YES;
        }
    }
    return NO;
}

/// 完成之前是否可以选择视频
- (BOOL)beforeCanSelectVideoWithModel:(HXPhotoModel *)model {
    if (model.videoDuration < self.configuration.videoMinimumSelectDuration) {
        return NO;
    }else if (model.videoDuration >= self.configuration.videoMaximumSelectDuration + 1) {
        if (!self.configuration.videoCanEdit) {
            return NO;
        }
    }
    if (!self.configuration.selectTogether) {
        if (!self.selectedPhotoCount && !self.beforeSelectVideoCountIsMaximum) {
            return YES;
        }
    }else {
        if (!self.beforeSelectVideoCountIsMaximum) {
            return YES;
        }
    }
    return NO;
}

#pragma mark - < 关于选择完成之后的一些方法 >
- (BOOL)afterSelectCountIsMaximum {
    if (self.endSelectedList.count >= self.configuration.maxNum) {
        return YES;
    }
    return NO;
}

- (BOOL)afterSelectPhotoCountIsMaximum {
    if (self.configuration.photoMaxNum > 0) {
        if (self.endSelectedPhotos.count >= self.configuration.photoMaxNum) {
            return YES;
        }
    }else {
        if (self.endSelectedPhotos.count + self.endSelectedVideos.count >= self.configuration.maxNum) {
            return YES;
        }
    }
    return NO;
}

- (BOOL)afterSelectVideoCountIsMaximum {
    if (self.configuration.videoMaxNum > 0) {
        if (self.endSelectedVideos.count >= self.configuration.videoMaxNum) {
            return YES;
        }
    }else {
        if (self.endSelectedPhotos.count + self.endSelectedVideos.count >= self.configuration.maxNum) {
            return YES;
        }
    }
    return NO;
}
- (NSInteger)afterSelectedCount {
    return self.endSelectedList.count;
}
- (NSArray *)afterSelectedArray {
    return self.endSelectedList;
}
- (NSArray *)afterSelectedPhotoArray {
    return self.endSelectedPhotos;
}
- (NSArray *)afterSelectedVideoArray {
    return self.endSelectedVideos;
}
- (void)setAfterSelectedPhotoArray:(NSArray *)array {
    self.endSelectedPhotos = [NSMutableArray arrayWithArray:array];
}
- (void)setAfterSelectedVideoArray:(NSArray *)array {
    self.endSelectedVideos = [NSMutableArray arrayWithArray:array];
}
- (BOOL)afterOriginal {
    return self.endIsOriginal;
}
- (void)afterSelectedArraySwapPlacesWithFromModel:(HXPhotoModel *)fromModel fromIndex:(NSInteger)fromIndex toModel:(HXPhotoModel *)toModel toIndex:(NSInteger)toIndex {
    [self.endSelectedList removeObject:toModel];
    [self.endSelectedList insertObject:toModel atIndex:toIndex];
    [self.endSelectedList removeObject:fromModel];
    [self.endSelectedList insertObject:fromModel atIndex:fromIndex];
}
- (void)afterSelectedArrayReplaceModelAtModel:(HXPhotoModel *)atModel withModel:(HXPhotoModel *)model {
    atModel.selected = NO;
    model.selected = YES;
    
    // 默认视频都是可选的
    [self changeModelVideoState:model];
    
    [self.endSelectedList replaceObjectAtIndex:[self.endSelectedList indexOfObject:atModel] withObject:model];
    if (atModel.type == HXPhotoModelMediaTypeCameraPhoto) {
        [self.endSelectedCameraPhotos removeObject:atModel];
        [self.endSelectedCameraList removeObject:atModel];
        [self.endCameraList removeObject:atModel];
        [self.endCameraPhotos removeObject:atModel];
    }else if (atModel.type == HXPhotoModelMediaTypeCameraVideo) {
        [self.endSelectedCameraVideos removeObject:atModel];
        [self.endSelectedCameraList removeObject:atModel];
        [self.endCameraList removeObject:atModel];
        [self.endCameraVideos removeObject:atModel];
    }
}
- (void)afterSelectedListAddEditPhotoModel:(HXPhotoModel *)model {
    // 默认视频都是可选的
    [self changeModelVideoState:model];
    
    if (model.subType == HXPhotoModelMediaSubTypePhoto) {
        if (model.type == HXPhotoModelMediaTypeCameraPhoto) {
            [self.endCameraPhotos addObject:model];
            [self.endCameraList addObject:model];
            [self.endSelectedCameraList addObject:model];
            [self.endSelectedCameraPhotos addObject:model];
        }
    }else {
        if (model.type == HXPhotoModelMediaTypeCameraVideo) {
            [self.endCameraVideos addObject:model];
            [self.endCameraList addObject:model];
            [self.endSelectedCameraList addObject:model];
            [self.endSelectedCameraVideos addObject:model];
        }
    }
}
- (void)afterListAddCameraTakePicturesModel:(HXPhotoModel *)model {
    // 默认视频都是可选的
    [self changeModelVideoState:model];
    
    if (model.subType == HXPhotoModelMediaSubTypePhoto) {
        if (self.type == HXPhotoManagerSelectedTypeVideo) {
            return;
        }
        if (model.type == HXPhotoModelMediaTypeCameraPhoto) {
            [self.endCameraPhotos addObject:model];
            [self.endCameraList addObject:model];
        }
        // 当选择图片个数没有达到最大个数时就添加到选中数组中
        if (![self afterSelectPhotoCountIsMaximum]) {
            if (!self.configuration.selectTogether) {
                if (self.endSelectedList.count > 0) {
                    HXPhotoModel *phMd = self.endSelectedList.firstObject;
                    if (phMd.subType == HXPhotoModelMediaSubTypePhoto) {
                        if (model.type == HXPhotoModelMediaTypeCameraPhoto) {
                            [self.endSelectedCameraPhotos insertObject:model atIndex:0];
                            [self.endSelectedCameraList addObject:model];
                        }
                        [self.endSelectedPhotos addObject:model];
                        [self.endSelectedList addObject:model];
                        model.selected = YES;
                        model.selectIndexStr = [NSString stringWithFormat:@"%ld",[self.endSelectedList indexOfObject:model] + 1];
                    }
                }else {
                    if (model.type == HXPhotoModelMediaTypeCameraPhoto) {
                        [self.endSelectedCameraPhotos insertObject:model atIndex:0];
                        [self.endSelectedCameraList addObject:model];
                    }
                    [self.endSelectedPhotos addObject:model];
                    [self.endSelectedList addObject:model];
                    model.selected = YES;
                    model.selectIndexStr = [NSString stringWithFormat:@"%ld",[self.endSelectedList indexOfObject:model] + 1];
                }
            }else {
                if (model.type == HXPhotoModelMediaTypeCameraPhoto) {
                    [self.endSelectedCameraPhotos insertObject:model atIndex:0];
                    [self.endSelectedCameraList addObject:model];
                }
                [self.endSelectedPhotos addObject:model];
                [self.endSelectedList addObject:model];
                model.selected = YES;
                model.selectIndexStr = [NSString stringWithFormat:@"%ld",[self.endSelectedList indexOfObject:model] + 1];
            }
        }
    }else if (model.subType == HXPhotoModelMediaSubTypeVideo) {
        if (self.type == HXPhotoManagerSelectedTypePhoto) {
            return;
        }
        if (model.type == HXPhotoModelMediaTypeCameraVideo) {
            [self.endCameraVideos addObject:model];
            [self.endCameraList addObject:model];
        }
        // 当选中视频个数没有达到最大个数时就添加到选中数组中
        if (![self afterSelectVideoCountIsMaximum] && model.videoDuration < self.configuration.videoMaximumSelectDuration + 1) {
            if (!self.configuration.selectTogether) {
                if (self.endSelectedList.count > 0) {
                    HXPhotoModel *phMd = self.endSelectedList.firstObject;
                    if (phMd.subType == HXPhotoModelMediaSubTypeVideo) {
                        if (model.type == HXPhotoModelMediaTypeCameraVideo) {
                            [self.endSelectedCameraVideos insertObject:model atIndex:0];
                            [self.endSelectedCameraList addObject:model];
                        }
                        [self.endSelectedVideos addObject:model];
                        [self.endSelectedList addObject:model];
                        model.selected = YES;
                        model.selectIndexStr = [NSString stringWithFormat:@"%ld",[self.endSelectedList indexOfObject:model] + 1];
                    }
                }else {
                    if (model.type == HXPhotoModelMediaTypeCameraVideo) {
                        [self.endSelectedCameraVideos insertObject:model atIndex:0];
                        [self.endSelectedCameraList addObject:model];
                    }
                    [self.endSelectedVideos addObject:model];
                    [self.endSelectedList addObject:model];
                    model.selected = YES;
                    model.selectIndexStr = [NSString stringWithFormat:@"%ld",[self.endSelectedList indexOfObject:model] + 1];
                }
            }else {
                if (model.type == HXPhotoModelMediaTypeCameraVideo) {
                    [self.endSelectedCameraVideos insertObject:model atIndex:0];
                    [self.endSelectedCameraList addObject:model];
                }
                [self.endSelectedVideos addObject:model];
                [self.endSelectedList addObject:model];
                model.selected = YES;
                model.selectIndexStr = [NSString stringWithFormat:@"%ld",[self.endSelectedList indexOfObject:model] + 1];
            }
        }
    }
    self.firstHasCameraAsset = YES;
}
- (void)afterSelectedListdeletePhotoModel:(HXPhotoModel *)model {
    if ([self.tempCameraAssetModels containsObject:model]) {
        [self.tempCameraAssetModels removeObject:model];
    }
    if (![self.endSelectedList containsObject:model]) {
        return;
    }
    if (model.subType == HXPhotoModelMediaSubTypePhoto) {
        if (model.type == HXPhotoModelMediaTypeCameraPhoto) {
            if (self.configuration.deleteTemporaryPhoto) {
                [self.endCameraPhotos removeObject:model];
                [self.endCameraList removeObject:model];
            }
            [self.endSelectedCameraPhotos removeObject:model];
            [self.endSelectedCameraList removeObject:model];
        }
        [self.endSelectedPhotos removeObject:model];
    }else if (model.subType == HXPhotoModelMediaSubTypeVideo) {
        if (model.type == HXPhotoModelMediaTypeCameraVideo) {
            if (self.configuration.deleteTemporaryPhoto) {
                [self.endCameraVideos removeObject:model];
                [self.endCameraList removeObject:model];
            }
            [self.endSelectedCameraVideos removeObject:model];
            [self.endSelectedCameraList removeObject:model];
        }
        [self.endSelectedVideos removeObject:model];
    }
    [self.endSelectedList removeObject:model];
    
    int i = 0;
    for (HXPhotoModel *model in self.endSelectedList) {
        model.selectIndexStr = [NSString stringWithFormat:@"%d",i + 1];
        i++;
    }
}
- (void)afterSelectedListAddPhotoModel:(HXPhotoModel *)model {
    // 默认视频都是可选的
    [self changeModelVideoState:model];
    
    if (model.subType == HXPhotoModelMediaSubTypePhoto) {
        if (model.type == HXPhotoModelMediaTypeCameraPhoto) {
            [self.endCameraPhotos addObject:model];
            [self.endCameraList addObject:model];
            [self.endSelectedCameraList addObject:model];
            [self.endSelectedCameraPhotos addObject:model];
        }
        [self.endSelectedPhotos addObject:model];
    }else {
        if (model.type == HXPhotoModelMediaTypeCameraVideo) {
            [self.endCameraVideos addObject:model];
            [self.endCameraList addObject:model];
            [self.endSelectedCameraList addObject:model];
            [self.endSelectedCameraVideos addObject:model];
        }
        [self.endSelectedVideos addObject:model];
    }
    [self.endSelectedList addObject:model];
}
#pragma mark - < others >
- (void)selectedListTransformBefore {
    if (self.type == HXPhotoManagerSelectedTypePhoto) {
        if (self.configuration.photoMaxNum > 0) {
            self.configuration.maxNum = self.configuration.photoMaxNum;
        }
        if (self.endCameraVideos.count > 0) {
            [self.endCameraList removeObjectsInArray:self.endCameraVideos];
            [self.endCameraVideos removeAllObjects];
        }
    }else if (self.type == HXPhotoManagerSelectedTypeVideo) {
        if (self.configuration.videoMaxNum > 0) {
            self.configuration.maxNum = self.configuration.videoMaxNum;
        }
        if (self.endCameraPhotos.count > 0) {
            [self.endCameraList removeObjectsInArray:self.endCameraPhotos];
            [self.endCameraPhotos removeAllObjects];
        }
    }else {
        if (self.configuration.photoMaxNum > 0 &&
            self.configuration.videoMaxNum > 0) {
            self.configuration.maxNum = self.configuration.photoMaxNum + self.configuration.videoMaxNum;
        }
    }
    // 上次选择的所有记录
    self.selectedList = [NSMutableArray arrayWithArray:self.endSelectedList];
    self.selectedPhotos = [NSMutableArray arrayWithArray:self.endSelectedPhotos];
    self.selectedVideos = [NSMutableArray arrayWithArray:self.endSelectedVideos];
    self.cameraList = [NSMutableArray arrayWithArray:self.endCameraList];
    self.cameraPhotos = [NSMutableArray arrayWithArray:self.endCameraPhotos];
    self.cameraVideos = [NSMutableArray arrayWithArray:self.endCameraVideos];
    self.selectedCameraList = [NSMutableArray arrayWithArray:self.endSelectedCameraList];
    self.selectedCameraPhotos = [NSMutableArray arrayWithArray:self.endSelectedCameraPhotos];
    self.selectedCameraVideos = [NSMutableArray arrayWithArray:self.endSelectedCameraVideos];
    self.isOriginal = self.endIsOriginal;
    self.photosTotalBtyes = self.endPhotosTotalBtyes;
}
- (void)selectedListTransformAfter {
    // 如果通过相机拍的数组为空 则清空所有关于相机的数组
    if (self.configuration.deleteTemporaryPhoto) {
        if (self.selectedCameraList.count == 0) {
            [self.cameraList removeAllObjects];
            [self.cameraVideos removeAllObjects];
            [self.cameraPhotos removeAllObjects];
        }
    }
    if (!self.configuration.singleSelected) {
        // 记录这次操作的数据
        self.endSelectedList = [NSMutableArray arrayWithArray:self.selectedList];
        self.endSelectedPhotos = [NSMutableArray arrayWithArray:self.selectedPhotos];
        self.endSelectedVideos = [NSMutableArray arrayWithArray:self.selectedVideos];
        self.endCameraList = [NSMutableArray arrayWithArray:self.cameraList];
        self.endCameraPhotos = [NSMutableArray arrayWithArray:self.cameraPhotos];
        self.endCameraVideos = [NSMutableArray arrayWithArray:self.cameraVideos];
        self.endSelectedCameraList = [NSMutableArray arrayWithArray:self.selectedCameraList];
        self.endSelectedCameraPhotos = [NSMutableArray arrayWithArray:self.selectedCameraPhotos];
        self.endSelectedCameraVideos = [NSMutableArray arrayWithArray:self.selectedCameraVideos];
        self.endIsOriginal = self.isOriginal;
        self.endPhotosTotalBtyes = self.photosTotalBtyes;
        
        [self cancelBeforeSelectedList];
    }
}
- (void)addTempCameraAssetModel:(HXPhotoModel *)model {
    [self.tempCameraAssetModels addObject:model];
}
- (void)removeAllTempCameraAssetModel {
    self.tempCameraAssetModels = nil;
}
- (void)cancelBeforeSelectedList {
    [self.selectedList removeAllObjects];
    [self.selectedPhotos removeAllObjects];
    [self.selectedVideos removeAllObjects];
    self.isOriginal = NO;
    self.photosTotalBtyes = nil;
    [self.selectedCameraList removeAllObjects];
    [self.selectedCameraVideos removeAllObjects];
    [self.selectedCameraPhotos removeAllObjects];
    [self.cameraPhotos removeAllObjects];
    [self.cameraList removeAllObjects];
    [self.cameraVideos removeAllObjects];
    [self removeAllTempCameraAssetModel];
}
- (void)sortSelectedListIndex {
    NSInteger i = 0;
    for (HXPhotoModel *model in self.selectedList) {
        model.selectIndexStr = [NSString stringWithFormat:@"%ld",i + 1];
        i++;
    }
    for (HXPhotoModel *model in self.endSelectedList) {
        model.selectIndexStr = [NSString stringWithFormat:@"%ld",i + 1];
        i++;
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
    
    [self.selectedList removeAllObjects];
    [self.cameraPhotos removeAllObjects];
    [self.selectedCameraPhotos removeAllObjects];
    [self.cameraList removeAllObjects];
    [self.selectedCameraList removeAllObjects];
    [self.selectedPhotos removeAllObjects];
    [self.cameraVideos removeAllObjects];
    [self.selectedCameraVideos removeAllObjects];
    [self.cameraList removeAllObjects];
    [self.selectedCameraList removeAllObjects];
    [self.selectedVideos removeAllObjects];
    [self.selectedPhotos removeAllObjects];
    [self.selectedVideos removeAllObjects];
    self.isOriginal = NO;
    self.photosTotalBtyes = nil;
    
    [self.iCloudUploadArray removeAllObjects];
}

- (void)appBecomeActive {
    
}

- (void)changeAfterCameraArray:(NSArray *)array {
    self.endCameraList = array.mutableCopy;
}
- (void)changeAfterCameraPhotoArray:(NSArray *)array {
    self.endCameraPhotos = array.mutableCopy;
}
- (void)changeAfterCameraVideoArray:(NSArray *)array {
    self.endCameraVideos = array.mutableCopy;
}
- (void)changeAfterSelectedCameraArray:(NSArray *)array {
    self.endSelectedCameraList = array.mutableCopy;
}
- (void)changeAfterSelectedCameraPhotoArray:(NSArray *)array {
    self.endSelectedCameraPhotos = array.mutableCopy;
}
- (void)changeAfterSelectedCameraVideoArray:(NSArray *)array {
    self.endSelectedCameraVideos = array.mutableCopy;
}
- (void)changeAfterSelectedArray:(NSArray *)array {
    self.endSelectedList = array.mutableCopy;
}
- (void)changeAfterSelectedPhotoArray:(NSArray *)array {
    self.endSelectedPhotos = array.mutableCopy;
}
- (void)changeAfterSelectedVideoArray:(NSArray *)array {
    self.endSelectedVideos = array.mutableCopy;
}
- (void)changeICloudUploadArray:(NSArray *)array {
    self.iCloudUploadArray = array.mutableCopy;
}
- (NSArray *)afterCameraArray {
    return self.endCameraList;
}
- (NSArray *)afterCameraPhotoArray {
    return self.endCameraPhotos;
}
- (NSArray *)afterCameraVideoArray {
    return self.endCameraVideos;
}
- (NSArray *)afterSelectedCameraArray {
    return self.endSelectedCameraList;
}
- (NSArray *)afterSelectedCameraPhotoArray {
    return self.endSelectedCameraPhotos;
}
- (NSArray *)afterSelectedCameraVideoArray {
    return self.endSelectedCameraVideos;
}
- (NSArray *)afterICloudUploadArray {
    return self.iCloudUploadArray;
} 

#pragma mark - < 保存草稿功能 >
- (void)addLocalModels {
    [self addLocalModels:self.localModels];
}
- (void)addLocalModels:(NSArray<HXPhotoModel *> *)models {
    if (!models.count) return;
    if (![models.firstObject isKindOfClass:[HXPhotoModel class]]) {
        if (HXShowLog) NSSLog(@"请传入装着HXPhotoModel对象的数组");
        return;
    }
    for (HXPhotoModel *photoModel in models) {
        if (photoModel.subType == HXPhotoModelMediaSubTypePhoto) {
            [self.endSelectedPhotos addObject:photoModel];
        }else {
            [self.endSelectedVideos addObject:photoModel];
        }
        if (photoModel.type == HXPhotoModelMediaTypeCameraPhoto) {
            [self.endCameraPhotos addObject:photoModel];
            [self.endSelectedCameraPhotos addObject:photoModel];
            [self.endCameraList addObject:photoModel];
            [self.endSelectedCameraList addObject:photoModel];
        }else if (photoModel.type == HXPhotoModelMediaTypeCameraVideo) {
            [self.endCameraVideos addObject:photoModel];
            [self.endSelectedCameraVideos addObject:photoModel];
            [self.endCameraList addObject:photoModel];
            [self.endSelectedCameraList addObject:photoModel];
        }
        [self.endSelectedList addObject:photoModel];
    }
}
- (BOOL)saveLocalModelsToFile {
    self.localModels = self.afterSelectedArray.copy;
    NSMutableData *data = [[NSMutableData alloc] init];
    NSKeyedArchiver *archiver = [[NSKeyedArchiver alloc] initForWritingWithMutableData:data];
    [archiver encodeObject:self.afterSelectedArray forKey:HXEncodeKey];
    [archiver finishEncoding];
    NSString *toFileName = [HXPhotoPickerLocalModelsPath stringByAppendingPathComponent:HXDiskCacheFileNameForKey(self.configuration.localFileName, NO)];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if (![fileManager fileExistsAtPath:HXPhotoPickerLocalModelsPath]) {
        [fileManager createDirectoryAtPath:HXPhotoPickerLocalModelsPath withIntermediateDirectories:YES attributes:nil error:nil];
    }
    if([data writeToFile:toFileName atomically:YES]){
        if (HXShowLog) NSSLog(@"归档成功");
        return YES;
    }
    return NO;
}

- (NSArray<HXPhotoModel *> *)getLocalModelsInFile {
    return [self getLocalModelsInFileWithAddData:NO];
}
- (NSArray<HXPhotoModel *> *)getLocalModelsInFileWithAddData:(BOOL)addData {
    NSString *toFileName = [HXPhotoPickerLocalModelsPath stringByAppendingPathComponent:HXDiskCacheFileNameForKey(self.configuration.localFileName, NO)];
    NSData *undata = [[NSData alloc] initWithContentsOfFile:toFileName];
    NSKeyedUnarchiver *unarchiver = [[NSKeyedUnarchiver alloc] initForReadingWithData:undata];
    NSArray *tempArray = [unarchiver decodeObjectForKey:HXEncodeKey];
    [unarchiver finishDecoding];
    NSMutableArray *modelArray = @[].mutableCopy;
    for (HXPhotoModel *model in tempArray) {
        if (model.localIdentifier && !model.asset) {
            PHAsset *asset = [HXAssetManager fetchAssetWithLocalIdentifier:model.localIdentifier];
            if (asset) {
                model.asset = asset;
                [modelArray addObject:model];
            }
            // asset为空代表这张图片已经被删除了,这里过滤掉
            continue;
        }else {
            if (model.videoURL && ![[NSFileManager defaultManager] fileExistsAtPath:model.videoURL.path]) {
                // 如果本地视频，但是视频地址已不存在也过滤掉
                continue;
            }
        }
        [modelArray addObject:model];
    }
    if (modelArray.count) {
        if (addData) {
            [self addLocalModels:modelArray];
        }
        self.localModels = modelArray.copy;
    }else {
        self.localModels = nil;
    }
    return self.localModels;
}
- (BOOL)deleteLocalModelsInFile {
    self.localModels = nil;
    NSString *toFileName = [HXPhotoPickerLocalModelsPath stringByAppendingPathComponent:HXDiskCacheFileNameForKey(self.configuration.localFileName, NO)];
    if (![[NSFileManager defaultManager] fileExistsAtPath:toFileName]) {
        return YES;
    }
    NSError *error;
    [[NSFileManager defaultManager] removeItemAtPath:toFileName error:&error];
    if (error) {
        if (HXShowLog) NSSLog(@"删除失败%@", error);
        return NO;
    }
    return YES;
}
- (NSMutableArray *)tempCameraAssetModels {
    if (!_tempCameraAssetModels) {
        _tempCameraAssetModels = [NSMutableArray array];
    }
    return _tempCameraAssetModels;
}
- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidBecomeActiveNotification object:nil];
    [self.dataOperationQueue cancelAllOperations];
    
    self.selectedList = nil;
    self.selectedPhotos = nil;
    self.selectedVideos = nil;
    self.cameraList = nil;
    self.cameraPhotos = nil;
    self.cameraVideos = nil;
    self.endCameraList = nil;
    self.endCameraPhotos = nil;
    self.endCameraVideos = nil;
    self.selectedCameraList = nil;
    self.selectedCameraPhotos = nil;
    self.selectedCameraVideos = nil;
    self.endSelectedCameraList = nil;
    self.endSelectedCameraPhotos = nil;
    self.endSelectedCameraVideos = nil;
    self.endSelectedList = nil;
    self.endSelectedPhotos = nil;
    self.endSelectedVideos = nil;
    self.selectedAssetList = nil;
    self.tempSelectedModelList = nil;
    
    if (HXShowLog) NSSLog(@"dealloc");
}
@end
