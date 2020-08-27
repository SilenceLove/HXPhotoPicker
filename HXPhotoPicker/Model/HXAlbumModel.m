//
//  HXAlbumModel.m
//  HXPhotoPicker-Demo
//
//  Created by 洪欣 on 17/2/8.
//  Copyright © 2017年 洪欣. All rights reserved.
//

#import "HXAlbumModel.h"
#import "HXPhotoTools.h"
@implementation HXAlbumModel

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
        PHFetchResult *result = [PHAsset fetchAssetsInAssetCollection:self.assetCollection options:self.option];
        self.assetResult = result;
        self.count = result.count;
        [HXPhotoCommon photoCommon].cameraRollResult = result;
        [HXPhotoCommon photoCommon].selectType = self.selectType;
    }else {
        PHFetchResult *result = [PHAsset fetchAssetsInAssetCollection:self.assetCollection options:self.option];
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
- (PHAssetCollection *)assetCollection {
    if (!_assetCollection) {
        _assetCollection = [[PHAssetCollection fetchAssetCollectionsWithLocalIdentifiers:@[self.localIdentifier] options:nil] firstObject];
    }
    return _assetCollection;
}
- (PHFetchOptions *)option {
    if (!_option) {
        _option = [[PHFetchOptions alloc] init];
        if (self.creationDateSort) {
            _option.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"creationDate" ascending:YES]];
        }
        if (self.selectType == 0) {
            _option.predicate = [NSPredicate predicateWithFormat:@"mediaType == %ld", PHAssetMediaTypeImage];
        }else if (self.selectType == 1) {
            _option.predicate = [NSPredicate predicateWithFormat:@"mediaType == %ld", PHAssetMediaTypeVideo];
        }
    }
    return _option;
}
@end
