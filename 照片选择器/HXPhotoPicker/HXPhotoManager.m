//
//  HX_PhotoManager.m
//  照片选择器
//
//  Created by 洪欣 on 17/2/8.
//  Copyright © 2017年 洪欣. All rights reserved.
//

#import "HXPhotoManager.h"
#import <mach/mach_time.h>
#import "HXDatePhotoToolManager.h"


@interface HXPhotoManager ()<PHPhotoLibraryChangeObserver>
@property (strong, nonatomic) NSMutableArray *allPhotos;
@property (strong, nonatomic) NSMutableArray *allVideos;
@property (strong, nonatomic) NSMutableArray *allObjs;
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
@property (strong, nonatomic) NSMutableArray *albums;
@property (assign, nonatomic) BOOL firstHasCameraAsset;
@property (assign, nonatomic) BOOL supportLivePhoto;

@property (assign, nonatomic) BOOL hasAuthorization;
@end

@implementation HXPhotoManager
#pragma mark - < 初始化 >
+ (instancetype)managerWithType:(HXPhotoManagerSelectedType)type {
    return [[self alloc] initWithType:type];
}
- (instancetype)initWithType:(HXPhotoManagerSelectedType)type {
    if (self = [super init]) {
        self.type = type;
        [self setup];
    }
    return self;
}
- (instancetype)init {
    return [self initWithType:HXPhotoManagerSelectedTypePhoto];
}
- (void)setType:(HXPhotoManagerSelectedType)type {
    if (_type != type) {
        self.cameraRollAlbumModel = nil;
    }
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
//    self.albums = [NSMutableArray array];
    self.loadAssetQueue = dispatch_queue_create("com.hxphotopicker.LoadAssetQueue", NULL);
    
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
    if ([PHPhotoLibrary authorizationStatus] == PHAuthorizationStatusAuthorized) {
        self.hasAuthorization = YES;
        [[PHPhotoLibrary sharedPhotoLibrary] registerChangeObserver:self];
    }else {
        self.hasAuthorization = NO;
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(requestAuthorizationCompletion) name:@"HXPhotoRequestAuthorizationCompletion" object:nil];
    }
//    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appBecomeActive) name:UIApplicationDidBecomeActiveNotification object:nil];
}
- (void)requestAuthorizationCompletion {
    if (!self.hasAuthorization && [PHPhotoLibrary authorizationStatus] == PHAuthorizationStatusAuthorized) {
        self.hasAuthorization = YES;
        [[PHPhotoLibrary sharedPhotoLibrary] registerChangeObserver:self];
    }
}
- (HXPhotoConfiguration *)configuration {
    if (!_configuration) {
        _configuration = [[HXPhotoConfiguration alloc] init];
    }
    return _configuration;
}
- (void)setLocalImageList:(NSArray *)localImageList {
    _localImageList = localImageList;
    if (!localImageList.count) return;
    if (![localImageList.firstObject isKindOfClass:[UIImage class]]) {
        if (HXShowLog) NSSLog(@"请传入装着UIImage对象的数组");
        return;
    }
    for (UIImage *image in localImageList) {
        HXPhotoModel *photoModel = [HXPhotoModel photoModelWithImage:image];
        photoModel.selected = YES;
        [self.endCameraPhotos addObject:photoModel];
        [self.endSelectedCameraPhotos addObject:photoModel];
        [self.endCameraList addObject:photoModel];
        [self.endSelectedCameraList addObject:photoModel];
        [self.endSelectedPhotos addObject:photoModel];
        [self.endSelectedList addObject:photoModel];
    }
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
        if (model.type == HXCustomAssetModelTypeLocalImage && model.localImage) {
            if (self.type == HXPhotoManagerSelectedTypeVideo) {
                continue;
            }
            HXPhotoModel *photoModel = [HXPhotoModel photoModelWithImage:model.localImage];
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
    if (!self.selectedPhotos.count) {
        return;
    }
    __block NSInteger dataLength = 0;
    __block NSInteger assetCount = 0;
    HXWeakSelf
    NSBlockOperation *operation = [NSBlockOperation blockOperationWithBlock:^{
        for (int i = 0 ; i < weakSelf.selectedPhotos.count ; i++) {
            HXPhotoModel *model = weakSelf.selectedPhotos[i];
            if (model.type == HXPhotoModelMediaTypeCameraPhoto) {
                NSData *imageData;
                if (UIImagePNGRepresentation(model.thumbPhoto)) {
                    //返回为png图像。
                    imageData = UIImagePNGRepresentation(model.thumbPhoto);
                }else {
                    //返回为JPEG图像。
                    imageData = UIImageJPEGRepresentation(model.thumbPhoto, 1.0);
                }
                dataLength += imageData.length;
                assetCount ++;
                if (assetCount >= weakSelf.selectedPhotos.count) {
                    NSString *bytes = [HXPhotoTools getBytesFromDataLength:dataLength];
                    dispatch_async(dispatch_get_main_queue(), ^{
                        if (completion) completion(bytes, dataLength);
                    });
                }
            }else {
                [model requestImageDataStartRequestICloud:nil progressHandler:nil success:^(NSData *imageData, UIImageOrientation orientation, HXPhotoModel *model, NSDictionary *info) {
                    dataLength += imageData.length;
                    assetCount ++;
                    if (assetCount >= weakSelf.selectedPhotos.count) {
                        NSString *bytes = [HXPhotoTools getBytesFromDataLength:dataLength];
                        dispatch_async(dispatch_get_main_queue(), ^{
                            if (completion) completion(bytes, dataLength);
                        });
                    }
                } failed:^(NSDictionary *info, HXPhotoModel *model) {
                    dataLength += 0;
                    assetCount ++;
                    if (assetCount >= weakSelf.selectedPhotos.count) {
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
- (void)addNetworkingImageToAlbum:(NSArray<NSString *> *)imageUrls selected:(BOOL)selected {
    if (!imageUrls.count) return;
    if (![imageUrls.firstObject isKindOfClass:[NSString class]]) {
        if (HXShowLog) NSSLog(@"请传入装着NSString对象的数组");
        return;
    }
    self.configuration.deleteTemporaryPhoto = NO;
    for (NSString *imageUrlStr in imageUrls) {
        HXPhotoModel *photoModel = [HXPhotoModel photoModelWithImageURL:[NSURL URLWithString:imageUrlStr]];
        photoModel.selected = selected;
        if (selected) {
            [self.endCameraPhotos addObject:photoModel];
            [self.endSelectedCameraPhotos addObject:photoModel];
            [self.endCameraList addObject:photoModel];
            [self.endSelectedCameraList addObject:photoModel];
            [self.endSelectedPhotos addObject:photoModel];
            [self.endSelectedList addObject:photoModel];
        }else {
            [self.endCameraPhotos addObject:photoModel];
            [self.endCameraList addObject:photoModel];
        }
    }
}
- (void)setNetworkPhotoUrls:(NSArray<NSString *> *)networkPhotoUrls {
    _networkPhotoUrls = networkPhotoUrls;
    if (!networkPhotoUrls.count) return;
    if (![networkPhotoUrls.firstObject isKindOfClass:[NSString class]]) {
        if (HXShowLog) NSSLog(@"请传入装着NSString对象的数组");
        return;
    }
    self.configuration.deleteTemporaryPhoto = NO;
    for (NSString *imageUrlStr in networkPhotoUrls) {
        HXPhotoModel *photoModel = [HXPhotoModel photoModelWithImageURL:[NSURL URLWithString:imageUrlStr]];
        photoModel.selected = NO;
        [self.endCameraPhotos addObject:photoModel];
        [self.endCameraList addObject:photoModel];
    }
}
- (void)addModelArray:(NSArray<HXPhotoModel *> *)modelArray {
    if (!modelArray.count) return;
    if (![modelArray.firstObject isKindOfClass:[HXPhotoModel class]]) {
        if (HXShowLog) NSSLog(@"请传入装着HXPhotoModel对象的数组");
        return;
    }
    for (HXPhotoModel *photoModel in modelArray) {
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
- (void)addLocalVideo:(NSArray<NSURL *> *)urlArray selected:(BOOL)selected {
    if (!urlArray.count) return;
    if (![urlArray.firstObject isKindOfClass:[NSURL class]]) {
        if (HXShowLog) NSSLog(@"请传入装着NSURL对象的数组");
        return;
    }
    self.configuration.deleteTemporaryPhoto = NO;
    for (NSURL *url in urlArray) {
        HXPhotoModel *model = [HXPhotoModel photoModelWithVideoURL:url];
        model.selected = selected;
        if (selected) {
            [self.endCameraVideos addObject:model];
            [self.endSelectedCameraVideos addObject:model];
            [self.endCameraList addObject:model];
            [self.endSelectedCameraList addObject:model];
            [self.endSelectedVideos addObject:model];
            [self.endSelectedList addObject:model];
        }else {
            [self.endCameraVideos addObject:model];
            [self.endCameraList addObject:model];
        }
    }
}
- (void)addLocalImage:(NSArray *)images selected:(BOOL)selected {
    if (!images.count) return;
    if (![images.firstObject isKindOfClass:[UIImage class]]) {
        if (HXShowLog) NSSLog(@"请传入装着UIImage对象的数组");
        return;
    }
    self.configuration.deleteTemporaryPhoto = NO;
    for (UIImage *image in images) {
        HXPhotoModel *photoModel = [HXPhotoModel photoModelWithImage:image];
        photoModel.selected = selected;
        if (selected) {
            [self.endCameraPhotos addObject:photoModel];
            [self.endSelectedCameraPhotos addObject:photoModel];
            [self.endCameraList addObject:photoModel];
            [self.endSelectedCameraList addObject:photoModel];
            [self.endSelectedPhotos addObject:photoModel];
            [self.endSelectedList addObject:photoModel];
        }else {
            [self.endCameraPhotos addObject:photoModel];
            [self.endCameraList addObject:photoModel];
        }
    }
}
- (void)addLocalImageToAlbumWithImages:(NSArray *)images {
    if (!images.count) return;
    if (![images.firstObject isKindOfClass:[UIImage class]]) {
        if (HXShowLog) NSSLog(@"请传入装着UIImage对象的数组");
        return;
    }
    self.configuration.deleteTemporaryPhoto = NO;
    for (UIImage *image in images) {
        HXPhotoModel *photoModel = [HXPhotoModel photoModelWithImage:image];
        [self.endCameraPhotos addObject:photoModel];
        [self.endCameraList addObject:photoModel];
    }
}

- (void)getCameraRollAlbumCompletion:(void (^)(HXAlbumModel *albumModel))completion {
    if (self.cameraRollAlbumModel && self.cameraRollAlbumModel.count) {
        if (self.getCameraRollAlbumModel) {
            self.getCameraRollAlbumModel(self.cameraRollAlbumModel);
        }
        if (completion) {
            completion(self.cameraRollAlbumModel);
        }
        return;
    }
    self.getCameraRoolAlbuming = YES;
    PHFetchOptions *option = [[PHFetchOptions alloc] init];
    if (self.configuration.creationDateSort) {
        option.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"creationDate" ascending:YES]];
    }
    if (self.type == HXPhotoManagerSelectedTypePhoto) {
        option.predicate = [NSPredicate predicateWithFormat:@"mediaType == %ld", PHAssetMediaTypeImage];
    }else if (self.type == HXPhotoManagerSelectedTypeVideo) {
        option.predicate = [NSPredicate predicateWithFormat:@"mediaType == %ld", PHAssetMediaTypeVideo];
    }
    BOOL addTempAlbum = YES;
    PHFetchResult *smartAlbums = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeSmartAlbum subtype:PHAssetCollectionSubtypeAny options:nil];
    for (PHAssetCollection *collection in smartAlbums) {
        if (![collection isKindOfClass:[PHAssetCollection class]]) continue;
        if (collection.estimatedAssetCount <= 0) continue;
        if ([self isCameraRollAlbum:collection]) {
            HXAlbumModel *model = [self albumModelWithCollection:collection option:option fetchAssets:YES];
            model.cameraCount = self.cameraList.count;
            model.index = 0;
            self.cameraRollAlbumModel = model;
            if (self.getCameraRollAlbumModel) {
                self.getCameraRollAlbumModel(model);
            }
            if (completion) completion(model);
            self.getCameraRoolAlbuming = NO;
            addTempAlbum = NO;
            break;
        }
    }
    if (addTempAlbum || !self.cameraRollAlbumModel) {
        HXPhotoModel *photoMd = self.cameraList.firstObject;
        HXAlbumModel *albumModel = [[HXAlbumModel alloc] init];
        albumModel.cameraCount = self.cameraList.count;
        albumModel.albumName = [NSBundle hx_localizedStringForKey:@"所有照片"];
        albumModel.index = 0;
        albumModel.tempImage = photoMd.thumbPhoto;
        albumModel.result = [PHAsset fetchAssetsWithOptions:option];
        albumModel.count = albumModel.result.count;
        if (albumModel.count) {
            self.cameraRollAlbumModel = albumModel;
        }
        if (self.getCameraRollAlbumModel) {
            self.getCameraRollAlbumModel(albumModel);
        }
        if (completion) completion(albumModel);
        self.getCameraRoolAlbuming = NO;
    }
}
- (BOOL)isCameraRollAlbum:(PHAssetCollection *)metadata {
    NSString *versionStr = [[UIDevice currentDevice].systemVersion stringByReplacingOccurrencesOfString:@"." withString:@""];
    if (versionStr.length <= 1) {
        versionStr = [versionStr stringByAppendingString:@"00"];
    } else if (versionStr.length <= 2) {
        versionStr = [versionStr stringByAppendingString:@"0"];
    }
    CGFloat version = versionStr.floatValue;
    
    if (version >= 800 && version <= 802) {
        return ((PHAssetCollection *)metadata).assetCollectionSubtype == PHAssetCollectionSubtypeSmartAlbumRecentlyAdded;
    } else {
        return ((PHAssetCollection *)metadata).assetCollectionSubtype == PHAssetCollectionSubtypeSmartAlbumUserLibrary;
    }
}
- (HXAlbumModel *)albumModelWithCollection:(PHAssetCollection *)collection option:(PHFetchOptions *)option fetchAssets:(BOOL)fetchAssets {
    HXAlbumModel *albumModel = [[HXAlbumModel alloc] init];
    albumModel.albumName = [self transFormAlbumNameWithCollection:collection];
//    albumModel.albumName = collection.localizedTitle;
    if (fetchAssets) {
        PHFetchResult *result = [PHAsset fetchAssetsInAssetCollection:collection options:option];
        albumModel.result = result;
        albumModel.count = result.count;
    }else {
        albumModel.collection = collection;
        albumModel.option = option;
    }
    return albumModel;
}
- (NSString *)transFormAlbumNameWithCollection:(PHAssetCollection *)collection {
    if (collection.assetCollectionType == PHAssetCollectionTypeAlbum) {
        return collection.localizedTitle;
    }
    NSString *albumName;
    HXPhotoLanguageType type = [HXPhotoCommon photoCommon].languageType;
    if (type == HXPhotoLanguageTypeSys) {
        albumName = collection.localizedTitle;
    }else {
        if ([collection.localizedTitle isEqualToString:@"相机胶卷"]) {
            return collection.localizedTitle;
        }else if ([collection.localizedTitle isEqualToString:@"Camera Roll"]) {
            return [NSBundle hx_localizedStringForKey:HXAlbumCameraRoll];
        }
        switch (collection.assetCollectionSubtype) {
            case PHAssetCollectionSubtypeSmartAlbumUserLibrary:
                albumName = [NSBundle hx_localizedStringForKey:HXAlbumCameraRoll]; 
                break;
            case PHAssetCollectionSubtypeSmartAlbumPanoramas:
                albumName = [NSBundle hx_localizedStringForKey:HXAlbumPanoramas];
                break;
            case PHAssetCollectionSubtypeSmartAlbumVideos:
                albumName = [NSBundle hx_localizedStringForKey:HXAlbumVideos];
                break;
            case PHAssetCollectionSubtypeSmartAlbumFavorites:
                albumName = [NSBundle hx_localizedStringForKey:HXAlbumFavorites];
                break;
            case PHAssetCollectionSubtypeSmartAlbumTimelapses:
                albumName = [NSBundle hx_localizedStringForKey:HXAlbumTimelapses];
                break;
            case PHAssetCollectionSubtypeSmartAlbumRecentlyAdded:
                albumName = [NSBundle hx_localizedStringForKey:HXAlbumRecentlyAdded];
                break;
            case PHAssetCollectionSubtypeSmartAlbumBursts:
                albumName = [NSBundle hx_localizedStringForKey:HXAlbumBursts];
                break;
            case PHAssetCollectionSubtypeSmartAlbumSlomoVideos:
                albumName = [NSBundle hx_localizedStringForKey:HXAlbumSlomoVideos];
                break;
            case PHAssetCollectionSubtypeSmartAlbumSelfPortraits:
                albumName = [NSBundle hx_localizedStringForKey:HXAlbumSelfPortraits];
                break;
            case PHAssetCollectionSubtypeSmartAlbumScreenshots:
                albumName = [NSBundle hx_localizedStringForKey:HXAlbumScreenshots];
                break;
            case PHAssetCollectionSubtypeSmartAlbumDepthEffect:
                albumName = [NSBundle hx_localizedStringForKey:HXAlbumDepthEffect];
                break;
            case PHAssetCollectionSubtypeSmartAlbumLivePhotos:
                albumName = [NSBundle hx_localizedStringForKey:HXAlbumLivePhotos];
                break;
            case PHAssetCollectionSubtypeSmartAlbumAnimated:
                albumName = [NSBundle hx_localizedStringForKey:HXAlbumAnimated];
                break;
            default:
                albumName = collection.localizedTitle;
                break;
        }
    }
    return albumName;
} 
- (void)preloadData {
    PHAuthorizationStatus status = [PHPhotoLibrary authorizationStatus];
    if (status != PHAuthorizationStatusAuthorized || self.getCameraRoolAlbuming || self.cameraRollAlbumModel) {
        return;
    }
    dispatch_async(self.loadAssetQueue, ^{
        HXWeakSelf
        [self getCameraRollAlbumCompletion:^(HXAlbumModel *albumModel) {
            if (!albumModel.result && albumModel.collection) {
                PHFetchResult *result = [PHAsset fetchAssetsInAssetCollection:albumModel.collection options:albumModel.option];
                albumModel.result = result;
                albumModel.count = result.count;
                if (!weakSelf.getPhotoListing) {
                    [weakSelf getPhotoListWithAlbumModel:albumModel complete:nil];
                }
            }else {
                if (!weakSelf.getPhotoListing) {
                    [weakSelf getPhotoListWithAlbumModel:albumModel complete:nil];
                }
            }
        }];
    });
}
- (void)removeAllAlbum {
    self.albums = nil;
    self.firstAlbumModel = nil; 
}
- (void)getAllAlbumModelFilter:(BOOL)filter select:(getSelectAlbumBlock)selectedModel completion:(getAllAlbumListBlock)completion {
    [self getAllAlbumModelFilter:filter needSelect:NO select:selectedModel completion:completion];
}
- (void)getAllAlbumModelFilter:(BOOL)filter needSelect:(BOOL)needSelect select:(getSelectAlbumBlock)selectedModel completion:(getAllAlbumListBlock)completion {
    
    if (self.albums) {
        if ((filter || needSelect)) {
            if (selectedModel) selectedModel(self.firstAlbumModel);
            if (self.selectAlbumBlock) {
                self.selectAlbumBlock(self.firstAlbumModel);
            }
            if (filter) return;
        }
        if (completion) {
            completion(self.albums);
        }
        if (self.allAlbumListBlock) {
            self.allAlbumListBlock(self.albums);
        }
        return;
    } 
    self.getAlbumListing = YES;
    
    PHFetchOptions *option = [[PHFetchOptions alloc] init];
    if (self.configuration.creationDateSort) {
        option.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"creationDate" ascending:YES]];
    }
    if (self.type == HXPhotoManagerSelectedTypePhoto) {
        option.predicate = [NSPredicate predicateWithFormat:@"mediaType == %ld", PHAssetMediaTypeImage];
    }else if (self.type == HXPhotoManagerSelectedTypeVideo) {
        option.predicate = [NSPredicate predicateWithFormat:@"mediaType == %ld", PHAssetMediaTypeVideo];
    }
    PHFetchResult *smartAlbums = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeSmartAlbum subtype:PHAssetCollectionSubtypeAny options:nil];
    PHFetchResult *userAlbums = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeAlbum subtype:PHAssetCollectionSubtypeAny options:nil];
    
    self.albums = [NSMutableArray array];
    if (self.firstHasCameraAsset &&
        self.configuration.saveSystemAblum &&
        !smartAlbums.count &&
        !userAlbums.count &&
        [PHPhotoLibrary authorizationStatus] == PHAuthorizationStatusAuthorized) {
        // 防止直接打开相机并没有打开相册,导致相册列表为空,拍的照片没有保存到相册列表
        if (!self.albums.count && self.cameraList.count) {
            if (!self.getAlbumListing) {
                return;
            }
            HXPhotoModel *photoMd = self.cameraList.firstObject;
            HXAlbumModel *albumModel = [[HXAlbumModel alloc] init];
            albumModel.cameraCount = self.cameraList.count;
            albumModel.albumName = [NSBundle hx_localizedStringForKey:@"所有照片"];
            albumModel.index = 0;
            albumModel.tempImage = photoMd.thumbPhoto;
            [self.albums addObject:albumModel];
            if (completion) {
                completion(self.albums);
            }
            if ((filter || needSelect)) {
                albumModel.index = 0;
                self.firstAlbumModel = albumModel;
                if (selectedModel) selectedModel(albumModel);
                if (self.selectAlbumBlock) {
                    self.selectAlbumBlock(albumModel);
                }
            }
            self.firstHasCameraAsset = NO;
            return;
        }
    }
    
    NSArray *allAlbums = @[smartAlbums,userAlbums];
    for (PHFetchResult *fetchResult in allAlbums) { 
        for (PHAssetCollection *collection in fetchResult) {
            // 有可能是PHCollectionList类的的对象，过滤掉
            if (![collection isKindOfClass:[PHAssetCollection class]]) continue;
            // 过滤空相册
            if (collection.estimatedAssetCount <= 0) continue;
            
            if (collection.assetCollectionSubtype == PHAssetCollectionSubtypeSmartAlbumAllHidden) continue;
            if (collection.assetCollectionSubtype == 215) continue;
            if (collection.assetCollectionSubtype == 212) continue;
            if (collection.assetCollectionSubtype == 204) continue;
            if (collection.assetCollectionSubtype == 1000000201) continue;
            
            @autoreleasepool {
                if ([self isCameraRollAlbum:collection]) {
                    HXAlbumModel *albumModel;
                    if (self.cameraRollAlbumModel) {
                        albumModel = self.cameraRollAlbumModel;
                    }else {
                        albumModel = [self albumModelWithCollection:collection option:option fetchAssets:YES];
                    }
                    if ((filter || needSelect)) {
                        albumModel.cameraCount = [self cameraCount];
                        albumModel.index = 0;
                        self.firstAlbumModel = albumModel;
                        if (selectedModel) selectedModel(albumModel);
                        if (self.selectAlbumBlock) {
                            self.selectAlbumBlock(albumModel);
                        }
                        if (filter) return;
                    }
                    [self.albums insertObject:albumModel atIndex:0];
                } else {
                    if (filter) continue;
                    HXAlbumModel *albumModel = [self albumModelWithCollection:collection option:option fetchAssets:YES];
                    if (albumModel.result && albumModel.count > 0) {
                        [self.albums addObject:albumModel];
                    }
                }
            }
        }
    }
    if (!self.albums.count &&
        [PHPhotoLibrary authorizationStatus] == PHAuthorizationStatusAuthorized) {
        HXAlbumModel *albumModel = [[HXAlbumModel alloc] init];
        albumModel.cameraCount = [self cameraCount];
        albumModel.albumName = [NSBundle hx_localizedStringForKey:@"所有照片"];
        albumModel.index = 0;
        albumModel.tempImage = [self firstCameraModel].thumbPhoto;
        [self.albums addObject:albumModel];
        if ((filter || needSelect)) { 
            self.firstAlbumModel = albumModel;
            if (selectedModel) selectedModel(albumModel);
            if (self.selectAlbumBlock) {
                self.selectAlbumBlock(albumModel);
            }
        }
    }
    for (int i = 0 ; i < self.albums.count; i++) {
        HXAlbumModel *model = self.albums[i];
        model.index = i;
        model.cameraCount = [self cameraCount];
        if (i == 0 && !model.result) {
            model.tempImage = [self firstCameraModel].thumbPhoto;
        }
    }
    if (completion) {
        completion(self.albums);
    }
    if (!self.getAlbumListing) return;
    if (self.allAlbumListBlock) {
        self.allAlbumListBlock(self.albums);
    }
    self.getAlbumListing = NO;
} 
- (HXPhotoModel *)photoModelWithAsset:(PHAsset *)asset {
    HXPhotoModel *photoModel = [[HXPhotoModel alloc] init];
    photoModel.clarityScale = self.configuration.clarityScale;
    photoModel.asset = asset;
    if ([[asset valueForKey:@"isCloudPlaceholder"] boolValue]) {
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
            
        }else if (asset.mediaSubtypes == PHAssetMediaSubtypePhotoLive &&
                  self.configuration.lookLivePhoto &&
                  self.supportLivePhoto ){
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
- (void)removeAllTempList {
    self.tempAllList = nil;
    self.tempPreviewList = nil;
    self.tempPhotoList = nil;
    self.tempVideoList = nil;
    self.tempDateList = nil;
    self.tempFirstSelectModel = nil;
    self.tempAlbumModel = nil;
}
- (void)getPhotoListWithAlbumModel:(HXAlbumModel *)albumModel complete:(getPhotoListBlock)complete {
    if (albumModel == self.tempAlbumModel &&
        !self.selectedList.count) {
        if (complete) {
            complete(self.tempAllList, self.tempPreviewList, self.tempPhotoList, self.tempVideoList, self.tempDateList, self.tempFirstSelectModel,  self.tempAlbumModel);
        }
        if (self.photoListBlock) {
            self.photoListBlock(self.tempAllList, self.tempPreviewList, self.tempPhotoList, self.tempVideoList, self.tempDateList, self.tempFirstSelectModel,  self.tempAlbumModel);
        }
        return;
    }
    self.getPhotoListing = YES; 
    [self removeAllTempList];
    if (_selectedList) {
        self.selectedAssetList = @[].mutableCopy;
        self.tempSelectedModelList = @[].mutableCopy;
        for (HXPhotoModel *model in _selectedList) {
            if (model.asset) {
                [self.selectedAssetList addObject:model.asset];
                [self.tempSelectedModelList addObject:model];
            }
        }
    }
    if (self.iCloudUploadArray) {
        self.iCloudAssetArray = @[].mutableCopy;
        for (HXPhotoModel *model in self.iCloudUploadArray) {
            if (model.asset) {
                [self.iCloudAssetArray addObject:model.asset];
            }
        }
    }
    
    NSMutableArray *allArray = [NSMutableArray array];
    NSMutableArray *previewArray = [NSMutableArray array];
    NSMutableArray *videoArray = [NSMutableArray array];
    NSMutableArray *photoArray = [NSMutableArray array];
    NSMutableArray *dateArray = [NSMutableArray array];
    
    __block NSDate *currentIndexDate;
    __block NSMutableArray *sameDayArray;
    __block HXPhotoDateModel *dateModel;
    __block HXPhotoModel *firstSelectModel;
    __block BOOL already = NO;
    
    if (self.configuration.reverseDate) {
        [albumModel.result enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(PHAsset *asset, NSUInteger idx, BOOL * _Nonnull stop) {
            if (!self.getPhotoListing) {
                return;
            }
            HXPhotoModel *photoModel = [self photoModelWithAsset:asset];
            if (!firstSelectModel && photoModel.selectIndexStr) {
                firstSelectModel = photoModel;
            }
            if (photoModel.subType == HXPhotoModelMediaSubTypePhoto) {
                [photoArray addObject:photoModel];
            }else if (photoModel.subType == HXPhotoModelMediaSubTypeVideo) {
                [videoArray addObject:photoModel];
            }
            photoModel.currentAlbumIndex = albumModel.index;
            
            BOOL canAddPhoto = YES;
            if (self.configuration.filtrationICloudAsset) {
                if (!photoModel.isICloud) {
                    [allArray addObject:photoModel];
                    [previewArray addObject:photoModel];
                }else {
                    canAddPhoto = NO;
                }
            }else {
                [allArray addObject:photoModel];
                if (photoModel.isICloud) {
                    if (self.configuration.downloadICloudAsset) {
                        [previewArray addObject:photoModel];
                    }
                }else {
                    [previewArray addObject:photoModel];
                }
            }

            if (self.configuration.showDateSectionHeader && canAddPhoto) {
                NSDate *photoDate = photoModel.creationDate;
                if (!currentIndexDate) {
                    dateModel = [[HXPhotoDateModel alloc] init];
                    dateModel.date = photoDate;
                    sameDayArray = [NSMutableArray array];
                    [sameDayArray addObject:photoModel];
                    [dateArray addObject:dateModel];
                }else {
                    if ([photoDate hx_isSameDay:currentIndexDate]) {
                        [sameDayArray addObject:photoModel];
                    }else {
                        dateModel.photoModelArray = sameDayArray;
                        sameDayArray = [NSMutableArray array];
                        dateModel = [[HXPhotoDateModel alloc] init];
                        dateModel.date = photoDate;
                        [sameDayArray addObject:photoModel];
                        [dateArray addObject:dateModel];
                    }
                }
                photoModel.dateItem = sameDayArray.count - 1;
                photoModel.dateSection = dateArray.count - 1;
                if (firstSelectModel && !already) {
                    firstSelectModel.dateSection = dateArray.count - 1;
                    firstSelectModel.dateItem = sameDayArray.count - 1;
                    already = YES;
                }
                if (idx == 0) {
                    dateModel.photoModelArray = sameDayArray;
                }
                if (self.configuration.sectionHeaderShowPhotoLocation && !dateModel.location) {
                    if (photoModel.asset.location) {
                        dateModel.location = photoModel.asset.location;
                    }
                }
                currentIndexDate = photoDate;
            }else {
                photoModel.dateItem = allArray.count - 1;
                photoModel.dateSection = 0;
            }
        }];
    }else {
        NSInteger index = 0;
        for (PHAsset *asset in albumModel.result) {
            if (!self.getPhotoListing) {
                return;
            }
            HXPhotoModel *photoModel = [self photoModelWithAsset:asset];
            if (!firstSelectModel && photoModel.selectIndexStr) {
                firstSelectModel = photoModel;
            }
            if (photoModel.subType == HXPhotoModelMediaSubTypePhoto) {
                [photoArray addObject:photoModel];
            }else if (photoModel.subType == HXPhotoModelMediaSubTypeVideo) {
                [videoArray addObject:photoModel];
            }
            
            photoModel.currentAlbumIndex = albumModel.index;
            BOOL canAddPhoto = YES;
            if (self.configuration.filtrationICloudAsset) {
                if (!photoModel.isICloud) {
                    [allArray addObject:photoModel];
                    [previewArray addObject:photoModel];
                }else {
                    canAddPhoto = NO;
                }
            }else {
                [allArray addObject:photoModel];
                if (photoModel.isICloud) {
                    if (self.configuration.downloadICloudAsset) {
                        [previewArray addObject:photoModel];
                    }
                }else {
                    [previewArray addObject:photoModel];
                }
            }
            if (self.configuration.showDateSectionHeader && canAddPhoto) {
                NSDate *photoDate = photoModel.creationDate;
                //        CLLocation *photoLocation = photoModel.location;
                if (!currentIndexDate) {
                    dateModel = [[HXPhotoDateModel alloc] init];
                    dateModel.date = photoDate;
                    sameDayArray = [NSMutableArray array];
                    [sameDayArray addObject:photoModel];
                    [dateArray addObject:dateModel];
                }else {
                    if ([photoDate hx_isSameDay:currentIndexDate]) {
                        [sameDayArray addObject:photoModel];
                    }else {
                        dateModel.photoModelArray = sameDayArray;
                        sameDayArray = [NSMutableArray array];
                        dateModel = [[HXPhotoDateModel alloc] init];
                        dateModel.date = photoDate;
                        [sameDayArray addObject:photoModel];
                        [dateArray addObject:dateModel];
                    }
                }
                photoModel.dateItem = sameDayArray.count - 1;
                photoModel.dateSection = dateArray.count - 1;
                if (firstSelectModel && !already) {
                    firstSelectModel.dateSection = dateArray.count - 1;
                    firstSelectModel.dateItem = sameDayArray.count - 1;
                    already = YES;
                }
                if (index == albumModel.result.count - 1) {
                    dateModel.photoModelArray = sameDayArray;
                }
                if (self.configuration.sectionHeaderShowPhotoLocation && !dateModel.location) {
                    if (photoModel.asset.location) {
                        dateModel.location = photoModel.asset.location;
                    }
                }
                currentIndexDate = photoDate;
            }else {
                photoModel.dateItem = allArray.count - 1;
                photoModel.dateSection = 0;
            }
            index++;
        }
    }
    
    self.selectedAssetList = nil;
    self.tempSelectedModelList = nil;
    self.iCloudAssetArray = nil;
    
    if (!dateArray.count &&
        self.configuration.showDateSectionHeader &&
        (self.configuration.openCamera || self.cameraList.count > 0)) {
        dateModel = [[HXPhotoDateModel alloc] init];
        dateModel.date = [NSDate date];
        [dateArray addObject:dateModel];
    }
    NSInteger cameraIndex = self.configuration.openCamera ? 1 : 0;
    if (self.configuration.openCamera) {
        HXPhotoModel *model = [[HXPhotoModel alloc] init];
        model.type = HXPhotoModelMediaTypeCamera;
//        if (photoArray.count == 0 && videoArray.count != 0) {
//            model.cameraNormalImageNamed = @"hx_compose_photo_video";
//            model.cameraPreviewImageNamed = @"hx_takePhoto";
//        }else if (photoArray.count == 0) {
//            model.cameraNormalImageNamed = @"hx_compose_photo_photograph";
//            model.cameraPreviewImageNamed = @"hx_takePhoto";
//        }else {
            model.cameraNormalImageNamed = @"hx_compose_photo_photograph";
            model.cameraPreviewImageNamed = @"hx_takePhoto";
//        }
        if (!self.configuration.reverseDate) {
            if (self.configuration.showDateSectionHeader) {
                model.dateSection = dateArray.count;
                HXPhotoDateModel *dateModel = dateArray.lastObject;
                model.dateItem = dateModel.photoModelArray.count;
                NSMutableArray *array = [NSMutableArray arrayWithArray:dateModel.photoModelArray];
                [array addObject:model];
                dateModel.photoModelArray = array;
            }else {
                model.dateSection = 0;
                model.dateItem = allArray.count;
            }
            [allArray addObject:model];
        }else {
            model.dateSection = 0;
            model.dateItem = 0;
            if (self.configuration.showDateSectionHeader) {
                HXPhotoDateModel *dateModel = dateArray.firstObject;
                NSMutableArray *array = [NSMutableArray arrayWithArray:dateModel.photoModelArray];
                [array insertObject:model atIndex:0];
                dateModel.photoModelArray = array;
            }
            [allArray insertObject:model atIndex:0];
        }
    }
    if (self.cameraList.count) {
        NSInteger index = 0;
        NSInteger photoIndex = 0;
        NSInteger videoIndex = 0;
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
                [previewArray insertObject:model atIndex:index];
                if (model.subType == HXPhotoModelMediaSubTypePhoto) {
                    [photoArray insertObject:model atIndex:photoIndex];
                    photoIndex++;
                }else {
                    [videoArray insertObject:model atIndex:videoIndex];
                    videoIndex++;
                }
            }else {
                NSInteger count = allArray.count;
                NSInteger atIndex = (count - cameraIndex) < 0 ? 0 : count - cameraIndex;
                [allArray insertObject:model atIndex:atIndex];
                [previewArray addObject:model];
                if (model.subType == HXPhotoModelMediaSubTypePhoto) {
                    [photoArray addObject:model];
                }else {
                    [videoArray addObject:model];
                }
            }
            if (self.configuration.showDateSectionHeader) {
                if (self.configuration.reverseDate) {
                    model.dateSection = 0;
                    HXPhotoDateModel *dateModel = dateArray.firstObject;
                    NSMutableArray *array = [NSMutableArray arrayWithArray:dateModel.photoModelArray];
                    [array insertObject:model atIndex:cameraIndex + index];
                    dateModel.photoModelArray = array;
                }else {
                    model.dateSection = (dateArray.count - 1) <= 0 ? 0 : dateArray.count - 1;
                    HXPhotoDateModel *dateModel = dateArray.lastObject;
                    
                    NSMutableArray *array = [NSMutableArray arrayWithArray:dateModel.photoModelArray];
                    NSInteger count = array.count;
                    NSInteger atIndex = (count - cameraIndex) < 0 ? 0 : count - cameraIndex;
                    [array insertObject:model atIndex:atIndex];
                    dateModel.photoModelArray = array;
                }
            }else {
                model.dateSection = 0;
            }
            index++;
        }
    }
    
    if (!self.getPhotoListing) {
        return;
    }
    self.tempAllList = allArray;
    self.tempPreviewList = previewArray;
    self.tempPhotoList = photoArray;
    self.tempVideoList = videoArray;
    self.tempDateList = dateArray;
    self.tempFirstSelectModel = firstSelectModel;
    self.tempAlbumModel = albumModel;
//    if (complete) {
//        complete(allArray, previewArray, photoArray, videoArray, dateArray, firstSelectModel,  albumModel);
//    }
//    if (self.photoListBlock) {
//        self.photoListBlock(allArray, previewArray, photoArray, videoArray, dateArray, firstSelectModel,  albumModel);
//     }
    if (complete) {
        complete(self.tempAllList, self.tempPreviewList, self.tempPhotoList, self.tempVideoList, self.tempDateList, self.tempFirstSelectModel,  self.tempAlbumModel);
    }
    if (self.photoListBlock) {
        self.photoListBlock(self.tempAllList, self.tempPreviewList, self.tempPhotoList, self.tempVideoList, self.tempDateList, self.tempFirstSelectModel,  self.tempAlbumModel);
    }
    self.getPhotoListing = NO;
}
- (void)addICloudModel:(HXPhotoModel *)model {
    if (![self.iCloudUploadArray containsObject:model]) {
        [self.iCloudUploadArray addObject:model];
    }
}
- (NSString *)maximumOfJudgment:(HXPhotoModel *)model {
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
        if (model.videoDuration < self.configuration.videoMinimumSelectDuration) { 
            return [NSString stringWithFormat:[NSBundle hx_localizedStringForKey:@"视频少于%ld秒，无法选择"], self.configuration.videoMinimumSelectDuration];
        }else if (model.videoDuration >= self.configuration.videoMaximumSelectDuration + 1) {
            return [NSString stringWithFormat:[NSBundle hx_localizedStringForKey:@"视频大于%ld秒，无法选择"], self.configuration.videoMaximumSelectDuration];
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
    for (HXPhotoModel *model in self.selectedList) {
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
    }
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
    
    [self.albums removeAllObjects];
    self.albums = nil;
    [self.iCloudUploadArray removeAllObjects];
}

#pragma mark - < PHPhotoLibraryChangeObserver >
- (void)photoLibraryDidChange:(PHChange *)changeInstance {
    PHFetchResultChangeDetails *collectionChanges = [changeInstance changeDetailsForFetchResult:self.cameraRollAlbumModel.result];
    if (collectionChanges) {
        if ([collectionChanges hasIncrementalChanges]) {
            PHFetchResult *result = collectionChanges.fetchResultAfterChanges;
            self.cameraRollAlbumModel.result = result;
            self.cameraRollAlbumModel.count = result.count;
            if (collectionChanges.insertedObjects.count > 0) {
                // 添加照片了
            }
            
            if (collectionChanges.removedObjects.count > 0) {
                // 删除照片了
                
            }
            if (collectionChanges.changedObjects.count > 0) {
                // 改变照片了
            }
            if ([collectionChanges hasMoves]) {
                // 移动照片了
            }
        }
    }
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
- (void)saveSelectModelArraySuccess:(void (^)(void))success failed:(void (^)(void))failed {
    if (!self.afterSelectedArray.count) {
        if (failed) failed();
        return;
    }
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        BOOL su = [self saveSelectModelArray];
        if (!su) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (failed) {
                    failed();
                }
                if (HXShowLog) NSSLog(@"保存草稿失败啦!");
            });
        }else {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (success) {
                    success();
                }
            });
        }
    });
}

- (BOOL)deleteLocalSelectModelArray {
    return [self deleteSelectModelArray];
}

- (void)getSelectedModelArrayComplete:(void (^)(NSArray<HXPhotoModel *> *modelArray))complete  {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSArray *modelArray = [self getSelectedModelArray];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if (complete) {
                complete(modelArray);
            }
        });
    });
}

- (BOOL)saveSelectModelArray {
    NSMutableData *data = [[NSMutableData alloc] init];
    //创建归档辅助类
    NSKeyedArchiver *archiver = [[NSKeyedArchiver alloc] initForWritingWithMutableData:data];
    //编码
    [archiver encodeObject:self.afterSelectedArray forKey:HXEncodeKey];
    //结束编码
    [archiver finishEncoding];
    //写入到沙盒
    NSArray *array =  NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *toFileName = [array.firstObject stringByAppendingPathComponent:self.configuration.localFileName];
    
    if([data writeToFile:toFileName atomically:YES]){
        if (HXShowLog) NSSLog(@"归档成功");
        return YES;
    }
    return NO;
}

- (NSArray<HXPhotoModel *> *)getSelectedModelArray {
    NSArray *array =  NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *toFileName = [array.firstObject stringByAppendingPathComponent:self.configuration.localFileName];
    //解档
    NSData *undata = [[NSData alloc] initWithContentsOfFile:toFileName];
    //解档辅助类
    NSKeyedUnarchiver *unarchiver = [[NSKeyedUnarchiver alloc] initForReadingWithData:undata];
    //解码并解档出model
    NSArray *tempArray = [unarchiver decodeObjectForKey:HXEncodeKey];
    //关闭解档
    [unarchiver finishDecoding];
    NSMutableArray *modelArray = @[].mutableCopy;
    for (HXPhotoModel *model in tempArray) {
        if (model.localIdentifier && !model.asset) {
            PHAsset *asset = [[PHAsset fetchAssetsWithLocalIdentifiers:@[model.localIdentifier] options:nil] firstObject];
            if (asset) {
                model.asset = asset;
                [modelArray addObject:model];
            }
            // asset为空代表这张图片已经被删除了,这里过滤掉
        }else {
            [modelArray addObject:model];
        }
    }
    return modelArray.copy;
}

- (BOOL)deleteSelectModelArray {
    NSArray *array =  NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *toFileName = [array.firstObject stringByAppendingPathComponent:self.configuration.localFileName];
    NSError *error;
    [[NSFileManager defaultManager] removeItemAtPath:toFileName error:&error];
    if (error) {
        if (HXShowLog) NSSLog(@"删除失败");
        return NO;
    }
    return YES;
}

- (void)dealloc {
    [[PHPhotoLibrary sharedPhotoLibrary] unregisterChangeObserver:self];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidBecomeActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"HXPhotoRequestAuthorizationCompletion" object:nil];
    [self.dataOperationQueue cancelAllOperations];
    if (HXShowLog) NSSLog(@"dealloc");
}
@end
