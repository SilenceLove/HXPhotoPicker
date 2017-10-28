//
//  HX_PhotoManager.m
//  微博照片选择
//
//  Created by 洪欣 on 17/2/8.
//  Copyright © 2017年 洪欣. All rights reserved.
//

#import "HXPhotoManager.h"
#import <mach/mach_time.h>

#define iOS9Later ([UIDevice currentDevice].systemVersion.floatValue >= 9.1f)
@interface HXPhotoManager ()<PHPhotoLibraryChangeObserver>
@property (strong, nonatomic) NSMutableArray *allPhotos;
@property (strong, nonatomic) NSMutableArray *allVideos;
@property (strong, nonatomic) NSMutableArray *allObjs;
@end

@implementation HXPhotoManager

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
    self.open3DTouchPreview = YES;
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
    self.monitorSystemAlbum = YES; // NO
    self.cacheAlbum = YES; // NO
    self.videoMaxDuration = 300.f;
    self.videoMaximumDuration = 60.f;
    self.saveSystemAblum = NO;
    self.deleteTemporaryPhoto = YES;
    self.style = HXPhotoAlbumStylesWeibo;
    self.showDateHeaderSection = YES;
    self.reverseDate = NO;
//    self.horizontalHideStatusBar = NO;
    self.horizontalRowCount = 6;
    self.UIManager = [[HXPhotoUIManager alloc] init];
    [[PHPhotoLibrary sharedPhotoLibrary] registerChangeObserver:self];
}

- (void)setSaveSystemAblum:(BOOL)saveSystemAblum {
    _saveSystemAblum = saveSystemAblum;
    if (saveSystemAblum) {
        [self getMaxAlbum];
    }
}

- (void)setMonitorSystemAlbum:(BOOL)monitorSystemAlbum {
    _monitorSystemAlbum = monitorSystemAlbum;
    if (!monitorSystemAlbum) {
        [[PHPhotoLibrary sharedPhotoLibrary] unregisterChangeObserver:self];
    }else {
        [[PHPhotoLibrary sharedPhotoLibrary] registerChangeObserver:self];
    }
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

- (void)addLocalImage:(NSArray *)images selected:(BOOL)selected {
    if (![images.firstObject isKindOfClass:[UIImage class]]) {
        NSSLog(@"请传入装着UIImage对象的数组");
        return;
    }
    self.deleteTemporaryPhoto = NO;
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
    self.deleteTemporaryPhoto = NO;
    for (UIImage *image in images) {
        HXPhotoModel *photoModel = [HXPhotoModel photoModelWithImage:image];
        [self.endCameraPhotos addObject:photoModel];
        [self.endCameraList addObject:photoModel];
    }
}

- (void)getImage {
    if (!self.singleSelected && !self.photoViewCellIconDic) {
//        uint64_t start = mach_absolute_time();
        self.photoViewCellIconDic = @{
                                      @"videoIcon" : [HXPhotoTools hx_imageNamed:@"VideoSendIcon@2x.png"] ,
                                      
                                      @"gifIcon" : [HXPhotoTools hx_imageNamed:self.UIManager.cellGitIconImageName] ,
                                      
                                      @"liveIcon" : [HXPhotoTools hx_imageNamed:@"compose_live_photo_open_only_icon@2x.png"] ,
                                      
                                      @"liveBtnImageNormal" : [HXPhotoTools hx_imageNamed:@"compose_live_photo_open_icon@2x.png"] ,
                                      
                                      @"liveBtnImageSelected" : [HXPhotoTools hx_imageNamed:@"compose_live_photo_close_icon@2x.png"] ,
                                      
                                      @"liveBtnBackgroundImage" : [HXPhotoTools hx_imageNamed:@"compose_live_photo_background@2x.png"] ,
                                      
                                      @"selectBtnNormal" : [HXPhotoTools hx_imageNamed:self.UIManager.cellSelectBtnNormalImageName] ,
                                      
                                      @"selectBtnSelected" : [HXPhotoTools hx_imageNamed:self.UIManager.cellSelectBtnSelectedImageName] ,
                                      
                                      @"icloudIcon" : [HXPhotoTools hx_imageNamed:self.UIManager.cellICloudIconImageName]
                                      };
//        uint64_t stop = mach_absolute_time();
//        NSSLog(@"%f",subtractTimes(stop, start));
    }
}

/**
 获取系统所有相册
 
 @param albums 相册集合
 */

- (void)getAllPhotoAlbums:(void(^)(HXAlbumModel *firstAlbumModel))firstModel albums:(void(^)(NSArray *albums))albums isFirst:(BOOL)isFirst {
    if (self.albums.count > 0) [self.albums removeAllObjects];
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
        NSPredicate *pred = [NSPredicate predicateWithFormat:@"currentAlbumIndex = %d", i];
        NSArray *newArray = [self.selectedList filteredArrayUsingPredicate:pred];
        model.selectedCount = newArray.count;
    }
    if (albums) {
        albums(self.albums);
    }
}

- (void)FetchAllAlbum:(void(^)(NSArray *albums))albums IsShowSelectTag:(BOOL)isShow {
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
    
    if (self.reverseDate) {
        [albumModel.result enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(PHAsset *asset, NSUInteger idx, BOOL * _Nonnull stop) {
            HXPhotoModel *photoModel = [[HXPhotoModel alloc] init];
            photoModel.asset = asset;
            if ([[asset valueForKey:@"isCloudPlaceholder"] boolValue]) {
                photoModel.isIcloud = YES;
            }
            if (self.selectedList.count > 0) {
                NSMutableArray *selectedList = [NSMutableArray arrayWithArray:self.selectedList];
                NSString *property = @"asset";
                NSPredicate *pred = [NSPredicate predicateWithFormat:@"%K = %@", property, asset];
                NSArray *newArray = [selectedList filteredArrayUsingPredicate:pred];
                if (newArray.count > 0) {
                    HXPhotoModel *model = newArray.firstObject;
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
                    photoModel.isCloseLivePhoto = model.isCloseLivePhoto;
                    photoModel.selectIndexStr = model.selectIndexStr;
                    if (!firstSelectModel) {
                        firstSelectModel = photoModel;
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
                    if (iOS9Later && [HXPhotoTools platform]) {
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
                if (!photoModel.isIcloud) {
                    [photoArray addObject:photoModel];
                }
            }else if (asset.mediaType == PHAssetMediaTypeVideo) {
                photoModel.subType = HXPhotoModelMediaSubTypeVideo;
                photoModel.type = HXPhotoModelMediaTypeVideo;
                [[PHImageManager defaultManager] requestAVAssetForVideo:asset options:nil resultHandler:^(AVAsset * _Nullable asset, AVAudioMix * _Nullable audioMix, NSDictionary * _Nullable info) {
                    photoModel.avAsset = asset;
                }];
                NSString *timeLength = [NSString stringWithFormat:@"%0.0f",asset.duration];
                photoModel.videoTime = [HXPhotoTools getNewTimeFromDurationSecond:timeLength.integerValue];
                if (!photoModel.isIcloud) {
                    [videoArray addObject:photoModel];
                }
            }
            photoModel.currentAlbumIndex = albumModel.index;
            [allArray addObject:photoModel];
            if (!photoModel.isIcloud) {
                [previewArray addObject:photoModel];
            }
            if (self.showDateHeaderSection) {
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
                if (idx == 0) {
                    dateModel.photoModelArray = sameDayArray;
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
            if ([[asset valueForKey:@"isCloudPlaceholder"] boolValue]) {
                photoModel.isIcloud = YES;
            }
            if (self.selectedList.count > 0) {
                NSMutableArray *selectedList = [NSMutableArray arrayWithArray:self.selectedList];
                NSString *property = @"asset";
                NSPredicate *pred = [NSPredicate predicateWithFormat:@"%K = %@", property, asset];
                NSArray *newArray = [selectedList filteredArrayUsingPredicate:pred];
                if (newArray.count > 0) {
                    HXPhotoModel *model = newArray.firstObject;
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
                    photoModel.isCloseLivePhoto = model.isCloseLivePhoto;
                    photoModel.selectIndexStr = model.selectIndexStr;
                    if (!firstSelectModel) {
                        firstSelectModel = photoModel;
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
                    if (iOS9Later && [HXPhotoTools platform]) {
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
                if (!photoModel.isIcloud) {
                    [photoArray addObject:photoModel];
                }
            }else if (asset.mediaType == PHAssetMediaTypeVideo) {
                photoModel.subType = HXPhotoModelMediaSubTypeVideo;
                photoModel.type = HXPhotoModelMediaTypeVideo;
//                [[PHImageManager defaultManager] requestAVAssetForVideo:asset options:nil resultHandler:^(AVAsset * _Nullable asset, AVAudioMix * _Nullable audioMix, NSDictionary * _Nullable info) {
//                    photoModel.avAsset = asset;
//                }];
                NSString *timeLength = [NSString stringWithFormat:@"%0.0f",asset.duration];
                photoModel.videoTime = [HXPhotoTools getNewTimeFromDurationSecond:timeLength.integerValue];
                if (!photoModel.isIcloud) {
                    [videoArray addObject:photoModel];
                }
            }
            photoModel.currentAlbumIndex = albumModel.index;
            [allArray addObject:photoModel];
            
            if (!photoModel.isIcloud) {
                [previewArray addObject:photoModel];
            }
            if (self.showDateHeaderSection) {
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
                currentIndexDate = photoDate;
            }else {
                photoModel.dateItem = allArray.count - 1;
                photoModel.dateSection = 0;
            }
            index++;
        }
    }
    if (complete) {
        complete(allArray,previewArray,photoArray,videoArray,dateArray,firstSelectModel);
    }
}

/**
 根据PHFetchResult获取某个相册里面的所有图片和视频
 
 @param result PHFetchResult对象
 @param index 相册下标
 @param list 照片和视频的集合
 */
- (void)FetchAllPhotoForPHFetchResult:(PHFetchResult *)result Index:(NSInteger)index FetchResult:(void(^)(NSArray *photos, NSArray *videos, NSArray *Objs))list {
    NSMutableArray *photoAy = [NSMutableArray array];
    NSMutableArray *videoAy = [NSMutableArray array];
    NSMutableArray *objAy = [NSMutableArray array]; 
    __block NSInteger cameraIndex = self.openCamera ? 1 : 0;
//    uint64_t start = mach_absolute_time();
    [result enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(PHAsset *asset, NSUInteger idx, BOOL * _Nonnull stop) {
        HXPhotoModel *photoModel = [[HXPhotoModel alloc] init];
        photoModel.asset = asset;
//        if ([[asset valueForKey:@"localResourcesState"] longLongValue] == 18446744073709551615) {
//            photoModel.isIcloud = YES;
//            NSSLog(@"%@",[asset valueForKey:@"cloudPlaceholderKind"]);
//        }
        
        if ([[asset valueForKey:@"isCloudPlaceholder"] boolValue]) {
            photoModel.isIcloud = YES;
        }
//        if ([[asset valueForKey:@"fileURLForFullsizeRenderImage"] boolValue]) {
//            NSSLog(@"%@",[asset valueForKey:@"mainFileURL"]);
//        }
//        if ([[asset valueForKey:@"cloudIsDeletable"] boolValue]) {
//            photoModel.isIcloud = YES;
//            photoModel.cloudIsDeletable = YES;
//        }
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
                if (iOS9Later && [HXPhotoTools platform]) {
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
            if (!photoModel.isIcloud) {
                [photoAy addObject:photoModel];
            }
        }else if (asset.mediaType == PHAssetMediaTypeVideo) {
            photoModel.subType = HXPhotoModelMediaSubTypeVideo;
            photoModel.type = HXPhotoModelMediaTypeVideo;
            [[PHImageManager defaultManager] requestAVAssetForVideo:asset options:nil resultHandler:^(AVAsset * _Nullable asset, AVAudioMix * _Nullable audioMix, NSDictionary * _Nullable info) {
                photoModel.avAsset = asset;
            }];
            NSString *timeLength = [NSString stringWithFormat:@"%0.0f",asset.duration];
            photoModel.videoTime = [HXPhotoTools getNewTimeFromDurationSecond:timeLength.integerValue];
            if (!photoModel.isIcloud) {
                [videoAy addObject:photoModel];
            }
        }
//        if (!photoModel.cloudIsDeletable) {
            photoModel.currentAlbumIndex = index;
            [objAy addObject:photoModel];
//        }
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
            for (int i = 0; i < self.cameraList.count; i++) {
                HXPhotoModel *phMD = self.cameraList[i];
                [objAy insertObject:phMD atIndex:cameraIndex];
            }
            for (int i = 0; i < self.cameraPhotos.count; i++) {
                HXPhotoModel *phMD = self.cameraPhotos[i];
                [photoAy insertObject:phMD atIndex:0];
            }
            for (int i = 0; i < self.cameraVideos.count; i++) {
                HXPhotoModel *phMD = self.cameraVideos[i];
                [videoAy insertObject:phMD atIndex:0];
            }
        }
    }
    uint64_t stop = mach_absolute_time();
//    NSSLog(@"%f",subtractTimes(stop, start));
    if (list) {
        list(photoAy,videoAy,objAy);
    }
}
double subtractTimes( uint64_t endTime, uint64_t startTime ) {
    uint64_t difference = endTime - startTime;
    static double conversion = 0.0;
    if( conversion == 0.0 )
    {
        mach_timebase_info_data_t info;
        kern_return_t err =mach_timebase_info( &info );
        //Convert the timebase into seconds
        if( err == 0  )
            conversion= 1e-9 * (double) info.numer / (double) info.denom;
    }
    return conversion * (double)difference;
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
- (void)deleteSpecifiedModel:(HXPhotoModel *)model {
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

- (void)addSpecifiedArrayToSelectedArray:(NSArray *)list {
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
