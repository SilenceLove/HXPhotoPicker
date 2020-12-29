//
//  HXAlbumModel.m
//  HXPhotoPickerExample
//
//  Created by Silence on 17/2/8.
//  Copyright © 2017年 Silence. All rights reserved.
//

#import "HXAlbumModel.h"
#import "HXPhotoTools.h"
#import "HXAssetManager.h"

@interface HXAlbumModel ()
@property (strong, nonatomic) PHFetchOptions *options;
@property (strong, nonatomic) PHAssetCollection *collection;
@end

@implementation HXAlbumModel

- (instancetype)initWithCollection:(PHAssetCollection *)collection options:(PHFetchOptions *)options {
    self = [super init];
    if (self) {
        self.collection = collection;
        self.albumName = [self transFormAlbumNameWithCollection:collection];
        self.options = options;
    }
    return self;
}
- (NSString *)localIdentifier {
    return self.collection.localIdentifier;
}
- (void)fetchAssetResult {
    if ([self.localIdentifier isEqualToString:[HXPhotoCommon photoCommon].cameraRollLocalIdentifier]) {
        if ([HXPhotoCommon photoCommon].cameraRollResult) {
            if ([HXPhotoCommon photoCommon].selectType == self.selectType) {
                self.assetResult = [HXPhotoCommon photoCommon].cameraRollResult;
                self.count = [HXPhotoCommon photoCommon].cameraRollResult.count;
                return;
            }else if ([HXPhotoCommon photoCommon].selectType == 2) {
                if (self.selectType == 0) {
                    self.assetResult = [HXPhotoCommon photoCommon].cameraRollResult;
                    self.count = [[HXPhotoCommon photoCommon].cameraRollResult countOfAssetsWithMediaType:PHAssetMediaTypeImage];
                    return;
                }else if (self.selectType == 1) {
                    self.assetResult = [HXPhotoCommon photoCommon].cameraRollResult;
                    self.count = [[HXPhotoCommon photoCommon].cameraRollResult countOfAssetsWithMediaType:PHAssetMediaTypeVideo];
                    return;
                }
            }
            [HXPhotoCommon photoCommon].cameraRollResult = nil;
        }
        PHFetchResult *result = [HXAssetManager fetchAssetsInAssetCollection:self.collection options:self.options];
        self.assetResult = result;
        self.count = result.count;
        [HXPhotoCommon photoCommon].cameraRollResult = result;
        [HXPhotoCommon photoCommon].selectType = self.selectType;
    }else {
        PHFetchResult *result = [HXAssetManager fetchAssetsInAssetCollection:self.collection options:self.options];
        self.assetResult = result;
        self.count = result.count;
    }
}

- (void)getResultWithCompletion:(void (^)(HXAlbumModel *albumModel))completion {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [self fetchAssetResult];
        if (completion) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(self);
            });
        }
    });
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
        if ([collection.localizedTitle isEqualToString:@"最近项目"] ||
            [collection.localizedTitle isEqualToString:@"最近添加"]) {
            return [NSBundle hx_localizedStringForKey:HXAlbumRecents];
        }else if ([collection.localizedTitle isEqualToString:@"Camera Roll"] ||
                  [collection.localizedTitle isEqualToString:@"相机胶卷"]) {
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
@end
