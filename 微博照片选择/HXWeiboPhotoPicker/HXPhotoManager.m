//
//  HX_PhotoManager.m
//  微博照片选择
//
//  Created by 洪欣 on 17/2/8.
//  Copyright © 2017年 洪欣. All rights reserved.
//

#import "HXPhotoManager.h"
#import <mach/mach_time.h>


@interface HXPhotoManager ()<PHPhotoLibraryChangeObserver>
@property (strong, nonatomic) NSMutableArray *allPhotos;
@property (strong, nonatomic) NSMutableArray *allVideos;
@property (strong, nonatomic) NSMutableArray *allObjs;
@property (assign, nonatomic) BOOL hasLivePhoto;
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
//------//
@property (assign, nonatomic) BOOL isOriginal;
@property (assign, nonatomic) BOOL endIsOriginal;
@property (copy, nonatomic) NSString *photosTotalBtyes;
@property (copy, nonatomic) NSString *endPhotosTotalBtyes;
@property (strong, nonatomic) NSMutableArray *iCloudUploadArray;
@property (strong, nonatomic) NSMutableArray *albums;
@end

@implementation HXPhotoManager
#pragma mark - < 初始化 >
- (instancetype)initWithType:(HXPhotoManagerSelectedType)type {
    if (self = [super init]) {
        self.type = type;
        [self setup];
    }
    return self;
}
- (instancetype)init {
    if ([super init]) {
        self.type = HXPhotoManagerSelectedTypePhoto;
        [self setup];
    }
    return self;
}
- (void)setup {
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
    self.iCloudUploadArray = [NSMutableArray array];
    [[PHPhotoLibrary sharedPhotoLibrary] registerChangeObserver:self];
}
- (HXPhotoConfiguration *)configuration {
    if (!_configuration) {
        _configuration = [[HXPhotoConfiguration alloc] init];
    }
    return _configuration;
}
- (void)setLocalImageList:(NSArray *)localImageList {
    _localImageList = localImageList;
    if (![localImageList.firstObject isKindOfClass:[UIImage class]]) {
        NSSLog(@"请传入装着UIImage对象的数组");
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
- (void)addNetworkingImageToAlbum:(NSArray<NSString *> *)imageUrls selected:(BOOL)selected {
    if (![imageUrls.firstObject isKindOfClass:[NSString class]]) {
        NSSLog(@"请传入装着NSString对象的数组");
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
    if (![networkPhotoUrls.firstObject isKindOfClass:[NSString class]]) {
        NSSLog(@"请传入装着NSString对象的数组");
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
- (void)addLocalImage:(NSArray *)images selected:(BOOL)selected {
    if (![images.firstObject isKindOfClass:[UIImage class]]) {
        NSSLog(@"请传入装着UIImage对象的数组");
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
    if (![images.firstObject isKindOfClass:[UIImage class]]) {
        NSSLog(@"请传入装着UIImage对象的数组");
        return;
    }
    self.configuration.deleteTemporaryPhoto = NO;
    for (UIImage *image in images) {
        HXPhotoModel *photoModel = [HXPhotoModel photoModelWithImage:image];
        [self.endCameraPhotos addObject:photoModel];
        [self.endCameraList addObject:photoModel];
    }
}
/**
 获取系统所有相册
 
 @param albums 相册集合
 */
- (void)getAllPhotoAlbums:(void(^)(HXAlbumModel *firstAlbumModel))firstModel albums:(void(^)(NSArray *albums))albums isFirst:(BOOL)isFirst {
    if (self.albums.count > 0) [self.albums removeAllObjects];
    [self.iCloudUploadArray removeAllObjects];
    // 获取系统智能相册
    PHFetchResult *smartAlbums = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeSmartAlbum subtype:PHAssetCollectionSubtypeAlbumRegular options:nil];
    [smartAlbums enumerateObjectsWithOptions:NSEnumerationConcurrent usingBlock:^(PHAssetCollection *collection, NSUInteger idx, BOOL * _Nonnull stop) {
        if (isFirst) {
            if ([[HXPhotoTools transFormPhotoTitle:collection.localizedTitle] isEqualToString:@"相机胶卷"] || [[HXPhotoTools transFormPhotoTitle:collection.localizedTitle] isEqualToString:@"所有照片"]) {
                
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
                
                HXAlbumModel *albumModel = [[HXAlbumModel alloc] init];
                albumModel.count = result.count;
                albumModel.albumName = collection.localizedTitle;
                albumModel.result = result;
                albumModel.index = 0;
                if (firstModel) {
                    firstModel(albumModel);
                }
                *stop = YES;
            }
        }else {
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
                albumModel.result = result;
                if ([[HXPhotoTools transFormPhotoTitle:collection.localizedTitle] isEqualToString:@"相机胶卷"] || [[HXPhotoTools transFormPhotoTitle:collection.localizedTitle] isEqualToString:@"所有照片"]) {
                    [self.albums insertObject:albumModel atIndex:0];
                }else {
                    [self.albums addObject:albumModel];
                }
            }
        }
    }];
    if (isFirst) {
        return;
    }
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
            albumModel.result = result;
            [self.albums addObject:albumModel];
        }
    }];
    for (int i = 0 ; i < self.albums.count; i++) {
        HXAlbumModel *model = self.albums[i];
        model.index = i;
//        NSPredicate *pred = [NSPredicate predicateWithFormat:@"currentAlbumIndex = %d", i];
//        NSArray *newArray = [self.selectedList filteredArrayUsingPredicate:pred];
//        model.selectedCount = newArray.count;
    }
    if (albums) {
        albums(self.albums);
    }
}

/**
 *  是否为同一天
 */
- (BOOL)isSameDay:(NSDate*)date1 date2:(NSDate*)date2 {
    NSCalendar* calendar = [NSCalendar currentCalendar];
    
    unsigned unitFlags = NSCalendarUnitYear | NSCalendarUnitMonth |  NSCalendarUnitDay;
    NSDateComponents* comp1 = [calendar components:unitFlags fromDate:date1];
    NSDateComponents* comp2 = [calendar components:unitFlags fromDate:date2];
    
    return [comp1 day]   == [comp2 day] &&
    [comp1 month] == [comp2 month] &&
    [comp1 year]  == [comp2 year];
}
- (void)getPhotoListWithAlbumModel:(HXAlbumModel *)albumModel complete:(void (^)(NSArray *allList , NSArray *previewList,NSArray *photoList ,NSArray *videoList ,NSArray *dateList , HXPhotoModel *firstSelectModel))complete {
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
    NSMutableArray *selectList = [NSMutableArray arrayWithArray:self.selectedList];
    if (self.configuration.reverseDate) {
        [albumModel.result enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(PHAsset *asset, NSUInteger idx, BOOL * _Nonnull stop) {
            HXPhotoModel *photoModel = [[HXPhotoModel alloc] init];
            photoModel.clarityScale = self.configuration.clarityScale;
            photoModel.asset = asset;
            if ([[asset valueForKey:@"isCloudPlaceholder"] boolValue]) {
                if (self.iCloudUploadArray.count) {
                    NSString *property = @"asset";
                    NSPredicate *pred = [NSPredicate predicateWithFormat:@"%K = %@", property, asset];
                    NSArray *newArray = [self.iCloudUploadArray filteredArrayUsingPredicate:pred];
                    if (!newArray.count) {
                        photoModel.isICloud = YES;
                    }
                }else {
                    photoModel.isICloud = YES;
                }
            }
            if (selectList.count > 0) {
                NSString *property = @"asset";
                NSPredicate *pred = [NSPredicate predicateWithFormat:@"%K = %@", property, asset];
                NSArray *newArray = [selectList filteredArrayUsingPredicate:pred];
                if (newArray.count > 0) {
                    HXPhotoModel *model = newArray.firstObject;
                    [selectList removeObject:model];
                    photoModel.selected = YES;
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
                    photoModel.thumbPhoto = model.thumbPhoto;
                    photoModel.previewPhoto = model.previewPhoto;
                    photoModel.selectIndexStr = model.selectIndexStr;
                    if (!firstSelectModel) {
                        firstSelectModel = photoModel;
                    }
                }
            }
            if (asset.mediaType == PHAssetMediaTypeImage) {
                photoModel.subType = HXPhotoModelMediaSubTypePhoto;
                if ([[asset valueForKey:@"filename"] hasSuffix:@"GIF"]) {
                    if (self.configuration.singleSelected) {
                        photoModel.type = HXPhotoModelMediaTypePhoto;
                    }else {
                        photoModel.type = self.configuration.lookGifPhoto ? HXPhotoModelMediaTypePhotoGif : HXPhotoModelMediaTypePhoto;
                    }
                }else {
                    if (iOS9Later && self.hasLivePhoto) {
                        if (asset.mediaSubtypes == PHAssetMediaSubtypePhotoLive) {
                            if (!self.configuration.singleSelected) {
                                photoModel.type = self.configuration.lookLivePhoto ? HXPhotoModelMediaTypeLivePhoto : HXPhotoModelMediaTypePhoto;
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
//                if (!photoModel.isICloud) {
                    [photoArray addObject:photoModel];
//                }
            }else if (asset.mediaType == PHAssetMediaTypeVideo) {
                photoModel.subType = HXPhotoModelMediaSubTypeVideo;
                photoModel.type = HXPhotoModelMediaTypeVideo;
//                if (!photoModel.isICloud) {
                    [videoArray addObject:photoModel];
//                }
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
                    photoModel.dateItem = sameDayArray.count - 1;
                    photoModel.dateSection = dateArray.count - 1;
                }else {
                    if ([self isSameDay:photoDate date2:currentIndexDate]) {
                        [sameDayArray addObject:photoModel];
                        photoModel.dateItem = sameDayArray.count - 1;
                        photoModel.dateSection = dateArray.count - 1;
                    }else {
                        dateModel.photoModelArray = sameDayArray;
                        sameDayArray = [NSMutableArray array];
                        dateModel = [[HXPhotoDateModel alloc] init];
                        dateModel.date = photoDate;
                        [sameDayArray addObject:photoModel];
                        [dateArray addObject:dateModel];
                        photoModel.dateItem = sameDayArray.count - 1;
                        photoModel.dateSection = dateArray.count - 1;
                    }
                }
                if (firstSelectModel && !already) {
                    firstSelectModel.dateSection = dateArray.count - 1;
                    firstSelectModel.dateItem = sameDayArray.count - 1;
                    already = YES;
                }
                if (idx == 0) {
                    dateModel.photoModelArray = sameDayArray;
                }
                if (!dateModel.location && self.configuration.sectionHeaderShowPhotoLocation) {
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
            HXPhotoModel *photoModel = [[HXPhotoModel alloc] init];
            photoModel.asset = asset;
            photoModel.clarityScale = self.configuration.clarityScale;
            if ([[asset valueForKey:@"isCloudPlaceholder"] boolValue]) {
                if (self.iCloudUploadArray.count) {
                    NSString *property = @"asset";
                    NSPredicate *pred = [NSPredicate predicateWithFormat:@"%K = %@", property, asset];
                    NSArray *newArray = [self.iCloudUploadArray filteredArrayUsingPredicate:pred];
                    if (!newArray.count) {
                        photoModel.isICloud = YES;
                    }
                }else {
                    photoModel.isICloud = YES;
                }
            }
            if (selectList.count > 0) {
                NSString *property = @"asset";
                NSPredicate *pred = [NSPredicate predicateWithFormat:@"%K = %@", property, asset];
                NSArray *newArray = [selectList filteredArrayUsingPredicate:pred];
                if (newArray.count > 0) {
                    HXPhotoModel *model = newArray.firstObject;
                    [selectList removeObject:model];
                    photoModel.selected = YES;
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
                    photoModel.thumbPhoto = model.thumbPhoto;
                    photoModel.previewPhoto = model.previewPhoto; 
                    photoModel.selectIndexStr = model.selectIndexStr;
                    if (!firstSelectModel) {
                        firstSelectModel = photoModel;
                    }
                }
            }
            if (asset.mediaType == PHAssetMediaTypeImage) {
                photoModel.subType = HXPhotoModelMediaSubTypePhoto;
                if ([[asset valueForKey:@"filename"] hasSuffix:@"GIF"]) {
                    if (self.configuration.singleSelected) {
                        photoModel.type = HXPhotoModelMediaTypePhoto;
                    }else {
                        photoModel.type = self.configuration.lookGifPhoto ? HXPhotoModelMediaTypePhotoGif : HXPhotoModelMediaTypePhoto;
                    }
                }else {
                    if (iOS9Later && self.hasLivePhoto) {
                        if (asset.mediaSubtypes == PHAssetMediaSubtypePhotoLive) {
                            if (!self.configuration.singleSelected) {
                                photoModel.type = self.configuration.lookLivePhoto ? HXPhotoModelMediaTypeLivePhoto : HXPhotoModelMediaTypePhoto;
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
//                if (!photoModel.isICloud) {
                    [photoArray addObject:photoModel];
//                }
            }else if (asset.mediaType == PHAssetMediaTypeVideo) {
                photoModel.subType = HXPhotoModelMediaSubTypeVideo;
                photoModel.type = HXPhotoModelMediaTypeVideo;
//                if (!photoModel.isICloud) {
                    [videoArray addObject:photoModel];
//                }
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
                    photoModel.dateItem = sameDayArray.count - 1;
                    photoModel.dateSection = dateArray.count - 1;
                }else {
                    if ([self isSameDay:photoDate date2:currentIndexDate]) {
                        [sameDayArray addObject:photoModel];
                        photoModel.dateItem = sameDayArray.count - 1;
                        photoModel.dateSection = dateArray.count - 1;
                    }else {
                        dateModel.photoModelArray = sameDayArray;
                        sameDayArray = [NSMutableArray array];
                        dateModel = [[HXPhotoDateModel alloc] init];
                        dateModel.date = photoDate;
                        [sameDayArray addObject:photoModel];
                        [dateArray addObject:dateModel];
                        photoModel.dateItem = sameDayArray.count - 1;
                        photoModel.dateSection = dateArray.count - 1;
                    }
                }
                if (firstSelectModel && !already) {
                    firstSelectModel.dateSection = dateArray.count - 1;
                    firstSelectModel.dateItem = sameDayArray.count - 1;
                    already = YES;
                }
                if (index == albumModel.result.count - 1) {
                    dateModel.photoModelArray = sameDayArray;
                }
                if (!dateModel.location && self.configuration.sectionHeaderShowPhotoLocation) {
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
    NSInteger cameraIndex = self.configuration.openCamera ? 1 : 0;
    if (self.configuration.openCamera) {
        HXPhotoModel *model = [[HXPhotoModel alloc] init];
        model.type = HXPhotoModelMediaTypeCamera;
        if (photoArray.count == 0 && videoArray.count != 0) {
            model.thumbPhoto = [HXPhotoTools hx_imageNamed:@"compose_photo_video@2x.png"];
            model.previewPhoto = [HXPhotoTools hx_imageNamed:@"takePhoto@2x.png"];
        }else if (photoArray.count == 0) {
            model.thumbPhoto = [HXPhotoTools hx_imageNamed:@"compose_photo_photograph@2x.png"];
            model.previewPhoto = [HXPhotoTools hx_imageNamed:@"takePhoto@2x.png"];
        }else {
            model.thumbPhoto = [HXPhotoTools hx_imageNamed:@"compose_photo_photograph@2x.png"];
            model.previewPhoto = [HXPhotoTools hx_imageNamed:@"takePhoto@2x.png"];
        }
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
                [allArray addObject:model];
            }
        }else {
            model.dateSection = 0;
            model.dateItem = 0;
            if (self.configuration.showDateSectionHeader) {
                HXPhotoDateModel *dateModel = dateArray.firstObject;
                NSMutableArray *array = [NSMutableArray arrayWithArray:dateModel.photoModelArray];
                [array insertObject:model atIndex:0];
                dateModel.photoModelArray = array;
            }else {
                [allArray insertObject:model atIndex:0];
            }
        }
    }
    if (self.cameraList.count > 0) {
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
                [allArray insertObject:model atIndex:count - cameraIndex];
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
                    model.dateSection = dateArray.count - 1;
                    HXPhotoDateModel *dateModel = dateArray.lastObject;
                    NSMutableArray *array = [NSMutableArray arrayWithArray:dateModel.photoModelArray];
                    NSInteger count = array.count;
                    [array insertObject:model atIndex:count - cameraIndex];
                    dateModel.photoModelArray = array;
                }
            }else {
                model.dateSection = 0;
            }
            index++;
        }
    }
    if (complete) {
        complete(allArray,previewArray,photoArray,videoArray,dateArray,firstSelectModel);
    }
}
- (void)addICloudModel:(HXPhotoModel *)model {
    if (![self.iCloudUploadArray containsObject:model]) {
        [self.iCloudUploadArray addObject:model];
    }
}
- (NSString *)maximumOfJudgment:(HXPhotoModel *)model {
    if ([self beforeSelectCountIsMaximum]) {
        // 已经达到最大选择数 [NSString stringWithFormat:@"最多只能选择%ld个",manager.maxNum]
        return [NSString stringWithFormat:[NSBundle hx_localizedStringForKey:@"最多只能选择%ld个"],self.configuration.maxNum];
    }
    if (self.type == HXPhotoManagerSelectedTypePhotoAndVideo) {
        if ((model.type == HXPhotoModelMediaTypePhoto || model.type == HXPhotoModelMediaTypePhotoGif) || (model.type == HXPhotoModelMediaTypeCameraPhoto || model.type == HXPhotoModelMediaTypeLivePhoto)) {
            if (self.configuration.videoMaxNum > 0) {
                if (!self.configuration.selectTogether) { // 是否支持图片视频同时选择
                    if (self.selectedVideos.count > 0 ) {
                        // 已经选择了视频,不能再选图片
                        return [NSBundle hx_localizedStringForKey:@"图片不能和视频同时选择"];
                    }
                }
            }
            if (self.selectedPhotos.count == self.configuration.photoMaxNum) {
                // 已经达到图片最大选择数
                
                return [NSString stringWithFormat:[NSBundle hx_localizedStringForKey:@"最多只能选择%ld张图片"],self.configuration.photoMaxNum];
            }
        }else if (model.type == HXPhotoModelMediaTypeVideo || model.type == HXPhotoModelMediaTypeCameraVideo) {
            if (self.configuration.photoMaxNum > 0) {
                if (!self.configuration.selectTogether) { // 是否支持图片视频同时选择
                    if (self.selectedPhotos.count > 0 ) {
                        // 已经选择了图片,不能再选视频
                        return [NSBundle hx_localizedStringForKey:@"视频不能和图片同时选择"];
                    }
                }
            }
            if ([self beforeSelectVideoCountIsMaximum]) {
                // 已经达到视频最大选择数
                
                return [NSString stringWithFormat:[NSBundle hx_localizedStringForKey:@"最多只能选择%ld个视频"],self.configuration.videoMaxNum];
            }
        }
    }else if (self.type == HXPhotoManagerSelectedTypePhoto) {
        if ([self beforeSelectPhotoCountIsMaximum]) {
            // 已经达到图片最大选择数
            return [NSString stringWithFormat:[NSBundle hx_localizedStringForKey:@"最多只能选择%ld张图片"],self.configuration.photoMaxNum];
        }
    }else if (self.type == HXPhotoManagerSelectedTypeVideo) {
        if ([self beforeSelectVideoCountIsMaximum]) {
            // 已经达到视频最大选择数
            return [NSString stringWithFormat:[NSBundle hx_localizedStringForKey:@"最多只能选择%ld个视频"],self.configuration.videoMaxNum];
        }
    }
    if (model.type == HXPhotoModelMediaTypeVideo) {
        if (model.asset.duration < 3) {
            return [NSBundle hx_localizedStringForKey:@"视频少于3秒,无法选择"];
        }else if (model.asset.duration > self.configuration.videoMaxDuration) {
            return [NSBundle hx_localizedStringForKey:@"视频过大,无法选择"];
        }
    }else if (model.type == HXPhotoModelMediaTypeCameraVideo) {
        if (model.videoDuration < 3) {
            return [NSBundle hx_localizedStringForKey:@"视频少于3秒,无法选择"];
        }else if (model.videoDuration > self.configuration.videoMaxDuration) {
            return [NSBundle hx_localizedStringForKey:@"视频过大,无法选择"];
        }
    }
    return nil;
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
    if (self.selectedPhotos.count >= self.configuration.photoMaxNum) {
        return YES;
    }
    return NO;
}
- (BOOL)beforeSelectVideoCountIsMaximum {
    if (self.selectedVideos.count >= self.configuration.videoMaxNum) {
        return YES;
    }
    return NO;
}
- (void)beforeSelectedListdeletePhotoModel:(HXPhotoModel *)model {
    model.selected = NO;
    model.selectIndexStr = @"";
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
    model.selectIndexStr = [NSString stringWithFormat:@"%ld",[self.selectedList indexOfObject:model] + 1];
}
- (void)beforeSelectedListAddEditPhotoModel:(HXPhotoModel *)model {
    [self beforeSelectedListAddPhotoModel:model];
    [self.cameraPhotos addObject:model];
    [self.cameraList addObject:model];
}
- (void)beforeListAddCameraTakePicturesModel:(HXPhotoModel *)model {
    model.dateCellIsVisible = YES;
    if (model.type == HXPhotoModelMediaTypeCameraPhoto) {
        [self.cameraPhotos addObject:model];
        if (![self beforeSelectPhotoCountIsMaximum]) {
            if (!self.configuration.selectTogether) {
                if (self.selectedList.count > 0) {
                    HXPhotoModel *phMd = self.selectedList.firstObject;
                    if (phMd.subType == HXPhotoModelMediaSubTypePhoto) {
                        [self.selectedCameraPhotos insertObject:model atIndex:0];
                        [self.selectedPhotos addObject:model];
                        [self.selectedList addObject:model];
                        [self.selectedCameraList addObject:model];
                        model.selected = YES;
                        model.selectIndexStr = [NSString stringWithFormat:@"%ld",[self.selectedList indexOfObject:model] + 1];
                    }
                }else {
                    [self.selectedCameraPhotos insertObject:model atIndex:0];
                    [self.selectedPhotos addObject:model];
                    [self.selectedList addObject:model];
                    [self.selectedCameraList addObject:model];
                    model.selected = YES;
                    model.selectIndexStr = [NSString stringWithFormat:@"%ld",[self.selectedList indexOfObject:model] + 1];
                }
            }else {
                [self.selectedCameraPhotos insertObject:model atIndex:0];
                [self.selectedPhotos addObject:model];
                [self.selectedList addObject:model];
                [self.selectedCameraList addObject:model];
                model.selected = YES;
                model.selectIndexStr = [NSString stringWithFormat:@"%ld",[self.selectedList indexOfObject:model] + 1];
            }
        }
    }else if (model.type == HXPhotoModelMediaTypeCameraVideo) {
        [self.cameraVideos addObject:model];
        // 当选中视频个数没有达到最大个数时就添加到选中数组中
        if (![self beforeSelectVideoCountIsMaximum] && model.videoDuration <= self.configuration.videoMaxDuration) {
            if (!self.configuration.selectTogether) {
                if (self.selectedList.count > 0) {
                    HXPhotoModel *phMd = self.selectedList.firstObject;
                    if (phMd.subType == HXPhotoModelMediaSubTypeVideo) {
                        [self.selectedCameraVideos insertObject:model atIndex:0];
                        [self.selectedVideos addObject:model];
                        [self.selectedList addObject:model];
                        [self.selectedCameraList addObject:model];
                        model.selected = YES;
                        model.selectIndexStr = [NSString stringWithFormat:@"%ld",[self.selectedList indexOfObject:model] + 1];
                    }
                }else {
                    [self.selectedCameraVideos insertObject:model atIndex:0];
                    [self.selectedVideos addObject:model];
                    [self.selectedList addObject:model];
                    [self.selectedCameraList addObject:model];
                    model.selected = YES;
                    model.selectIndexStr = [NSString stringWithFormat:@"%ld",[self.selectedList indexOfObject:model] + 1];
                }
            }else {
                [self.selectedCameraVideos insertObject:model atIndex:0];
                [self.selectedVideos addObject:model];
                [self.selectedList addObject:model];
                [self.selectedCameraList addObject:model];
                model.selected = YES;
                model.selectIndexStr = [NSString stringWithFormat:@"%ld",[self.selectedList indexOfObject:model] + 1];
            }
        }
    }
    //    NSInteger cameraIndex = self.configuration.openCamera ? 1 : 0;
    if (self.configuration.reverseDate) {
        [self.cameraList insertObject:model atIndex:0];
    }else {
        [self.cameraList addObject:model];
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
    if (self.endSelectedPhotos.count >= self.configuration.photoMaxNum) {
        return YES;
    }
    return NO;
}

- (BOOL)afterSelectVideoCountIsMaximum {
    if (self.endSelectedVideos.count >= self.configuration.videoMaxNum) {
        return YES;
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
    [self.endSelectedList replaceObjectAtIndex:[self.endSelectedList indexOfObject:atModel] withObject:model];
    if (atModel.type == HXPhotoModelMediaTypeCameraPhoto) {
        [self.endSelectedCameraPhotos removeObject:atModel];
        [self.endSelectedCameraList removeObject:atModel];
        [self.endCameraList removeObject:atModel];
        [self.endCameraPhotos removeObject:atModel];
    }
}
- (void)afterSelectedListAddEditPhotoModel:(HXPhotoModel *)model {
    [self.endCameraPhotos addObject:model];
    [self.endCameraList addObject:model];
    [self.endSelectedCameraList addObject:model];
    [self.endSelectedCameraPhotos addObject:model];
}
- (void)afterListAddCameraTakePicturesModel:(HXPhotoModel *)model {
    if (model.type == HXPhotoModelMediaTypeCameraPhoto) {
        [self.endCameraPhotos addObject:model];
        // 当选择图片个数没有达到最大个数时就添加到选中数组中
        if (![self afterSelectPhotoCountIsMaximum]) {
            if (!self.configuration.selectTogether) {
                if (self.endSelectedList.count > 0) {
                    HXPhotoModel *phMd = self.endSelectedList.firstObject;
                    if ((phMd.type == HXPhotoModelMediaTypePhoto || phMd.type == HXPhotoModelMediaTypeLivePhoto) || (phMd.type == HXPhotoModelMediaTypePhotoGif || phMd.type == HXPhotoModelMediaTypeCameraPhoto)) {
                        [self.endSelectedCameraPhotos insertObject:model atIndex:0];
                        [self.endSelectedPhotos addObject:model];
                        [self.endSelectedList addObject:model];
                        [self.endSelectedCameraList addObject:model];
                        model.selected = YES;
                        model.selectIndexStr = [NSString stringWithFormat:@"%ld",[self.endSelectedList indexOfObject:model] + 1];
                    }
                }else {
                    [self.endSelectedCameraPhotos insertObject:model atIndex:0];
                    [self.endSelectedPhotos addObject:model];
                    [self.endSelectedList addObject:model];
                    [self.endSelectedCameraList addObject:model];
                    model.selected = YES;
                    model.selectIndexStr = [NSString stringWithFormat:@"%ld",[self.endSelectedList indexOfObject:model] + 1];
                }
            }else {
                [self.endSelectedCameraPhotos insertObject:model atIndex:0];
                [self.endSelectedPhotos addObject:model];
                [self.endSelectedList addObject:model];
                [self.endSelectedCameraList addObject:model];
                model.selected = YES;
                model.selectIndexStr = [NSString stringWithFormat:@"%ld",[self.endSelectedList indexOfObject:model] + 1];
            }
        }
    }else if (model.type == HXPhotoModelMediaTypeCameraVideo) {
        [self.endCameraVideos addObject:model];
        // 当选中视频个数没有达到最大个数时就添加到选中数组中
        if (![self afterSelectVideoCountIsMaximum] && model.videoDuration <= self.configuration.videoMaxDuration) {
            if (!self.configuration.selectTogether) {
                if (self.endSelectedList.count > 0) {
                    HXPhotoModel *phMd = self.endSelectedList.firstObject;
                    if (phMd.type == HXPhotoModelMediaTypeVideo || phMd.type == HXPhotoModelMediaTypeCameraVideo) {
                        [self.endSelectedCameraVideos insertObject:model atIndex:0];
                        [self.endSelectedVideos addObject:model];
                        [self.endSelectedList addObject:model];
                        [self.endSelectedCameraList addObject:model];
                        model.selected = YES;
                        model.selectIndexStr = [NSString stringWithFormat:@"%ld",[self.endSelectedList indexOfObject:model] + 1];
                    }
                }else {
                    [self.endSelectedCameraVideos insertObject:model atIndex:0];
                    [self.endSelectedVideos addObject:model];
                    [self.endSelectedList addObject:model];
                    [self.endSelectedCameraList addObject:model];
                    model.selected = YES;
                    model.selectIndexStr = [NSString stringWithFormat:@"%ld",[self.endSelectedList indexOfObject:model] + 1];
                }
            }else {
                [self.endSelectedCameraVideos insertObject:model atIndex:0];
                [self.endSelectedVideos addObject:model];
                [self.endSelectedList addObject:model];
                [self.endSelectedCameraList addObject:model];
                model.selected = YES;
                model.selectIndexStr = [NSString stringWithFormat:@"%ld",[self.endSelectedList indexOfObject:model] + 1];
            }
        }
    }
    [self.endCameraList addObject:model];
}
- (void)afterSelectedListdeletePhotoModel:(HXPhotoModel *)model {
    if (model.subType == HXPhotoModelMediaSubTypePhoto) {
        if (model.type == HXPhotoModelMediaTypeCameraPhoto) {
            [self.endCameraPhotos removeObject:model];
            [self.endCameraList removeObject:model];
            [self.endSelectedCameraPhotos removeObject:model];
            [self.endSelectedCameraList removeObject:model];
        }
        [self.endSelectedPhotos removeObject:model];
    }else if (model.subType == HXPhotoModelMediaSubTypeVideo) {
        if (model.type == HXPhotoModelMediaTypeCameraVideo) {
            [self.endCameraVideos removeObject:model];
            [self.endCameraList removeObject:model];
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
    
}
#pragma mark - < others >
- (void)selectedListTransformBefore {
    if (self.type == HXPhotoManagerSelectedTypePhoto) {
        self.configuration.maxNum = self.configuration.photoMaxNum;
        if (self.endCameraVideos.count > 0) {
            [self.endCameraList removeObjectsInArray:self.endCameraVideos];
            [self.endCameraVideos removeAllObjects];
        }
    }else if (self.type == HXPhotoManagerSelectedTypeVideo) {
        self.configuration.maxNum = self.configuration.videoMaxNum;
        if (self.endCameraPhotos.count > 0) {
            [self.endCameraList removeObjectsInArray:self.endCameraPhotos];
            [self.endCameraPhotos removeAllObjects];
        }
    }else {
        if (self.configuration.videoMaxNum + self.configuration.photoMaxNum != self.configuration.maxNum) {
            self.configuration.maxNum = self.configuration.videoMaxNum + self.configuration.photoMaxNum;
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
    [self.iCloudUploadArray removeAllObjects];
}

#pragma mark - < PHPhotoLibraryChangeObserver >
- (void)photoLibraryDidChange:(PHChange *)changeInstance {
    NSMutableArray *array = [NSMutableArray arrayWithArray:self.albums];
    for (HXAlbumModel *albumModel in array) {
        PHFetchResultChangeDetails *collectionChanges = [changeInstance changeDetailsForFetchResult:albumModel.result];
        if ([collectionChanges hasIncrementalChanges]) {
            if (self.configuration.saveSystemAblum) {
//                if (!self.cameraList.count) {
//                    self.albums = nil;
//                }
            }
            return;
        }
    }
}
- (void)dealloc {
    [[PHPhotoLibrary sharedPhotoLibrary] unregisterChangeObserver:self];
    NSSLog(@"dealloc");
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

@end
