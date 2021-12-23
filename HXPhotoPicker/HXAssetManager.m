//
//  HXAssetManager.m
//  HXPhotoPickerExample
//
//  Created by Silence on 2020/11/5.
//  Copyright © 2020 Silence. All rights reserved.
//

#import "HXAssetManager.h"
#import "HXAlbumModel.h"
#import "NSString+HXExtension.h"
#import "PHAsset+HXExtension.h"
#import "HXPhotoTools.h"

@implementation HXAssetManager

+ (PHFetchResult<PHAssetCollection *> *)fetchSmartAlbumsWithOptions:(PHFetchOptions * _Nullable)options {
    return [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeSmartAlbum subtype:PHAssetCollectionSubtypeAny options:options];
}

+ (PHFetchResult<PHAssetCollection *> *)fetchUserAlbumsWithOptions:(PHFetchOptions * _Nullable)options {
    return [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeAlbum subtype:PHAssetCollectionSubtypeAny options:options];
}
+ (void)enumerateAllAlbumsWithOptions:(PHFetchOptions * _Nullable)options
                           usingBlock:(void (^)(PHAssetCollection *collection))enumerationBlock {
    PHFetchResult *smartAlbums = [self fetchSmartAlbumsWithOptions:options];
    PHFetchResult *userAlbums = [self fetchUserAlbumsWithOptions:options];
    NSArray *allAlbum = [NSArray arrayWithObjects:smartAlbums, userAlbums, nil];
    for (PHFetchResult *result in allAlbum) {
        for (PHAssetCollection *collection in result) {
            if (![collection isKindOfClass:[PHAssetCollection class]]) continue;
            if (collection.estimatedAssetCount <= 0) continue;
            if (collection.assetCollectionSubtype == PHAssetCollectionSubtypeSmartAlbumAllHidden) continue;
            if (collection.assetCollectionSubtype == 215) continue;
            if (collection.assetCollectionSubtype == 212) continue;
            if (collection.assetCollectionSubtype == 204) continue;
            if (collection.assetCollectionSubtype == 1000000201) continue;
            if (enumerationBlock) {
                enumerationBlock(collection);
            }
        }
    }
}
+ (void)enumerateAllAlbumModelsWithOptions:(PHFetchOptions * _Nullable)options
                                usingBlock:(void (^)(HXAlbumModel *albumModel))enumerationBlock {
    [self enumerateAllAlbumsWithOptions:nil usingBlock:^(PHAssetCollection *collection) {
        HXAlbumModel *albumModel = [[HXAlbumModel alloc] initWithCollection:collection options:options];
        if (enumerationBlock) {
            enumerationBlock(albumModel);
        }
    }];
}
/// 获取相机胶卷
+ (PHAssetCollection *)fetchCameraRollAlbumWithOptions:(PHFetchOptions * _Nullable)options {
    PHFetchResult *smartAlbums = [self fetchSmartAlbumsWithOptions:options];
    for (PHAssetCollection *collection in smartAlbums) {
        if (![collection isKindOfClass:[PHAssetCollection class]]) continue;
        if (collection.estimatedAssetCount <= 0) continue;
        if ([self isCameraRollAlbum:collection]) {
            return collection;
        }
    }
    return nil;
}
+ (BOOL)isCameraRollAlbum:(PHAssetCollection *)assetCollection {
    NSString *versionStr = [[UIDevice currentDevice].systemVersion stringByReplacingOccurrencesOfString:@"." withString:@""];
    if (versionStr.length <= 1) {
        versionStr = [versionStr stringByAppendingString:@"00"];
    } else if (versionStr.length <= 2) {
        versionStr = [versionStr stringByAppendingString:@"0"];
    }
    CGFloat version = versionStr.floatValue;
    
    if (version >= 800 && version <= 802) {
        return assetCollection.assetCollectionSubtype == PHAssetCollectionSubtypeSmartAlbumRecentlyAdded;
    } else {
        return assetCollection.assetCollectionSubtype == PHAssetCollectionSubtypeSmartAlbumUserLibrary;
    }
}
+ (PHAssetCollection *)fetchAssetCollectionWithIndentifier:(NSString *)localIdentifier {
    return [[PHAssetCollection fetchAssetCollectionsWithLocalIdentifiers:@[localIdentifier] options:nil] firstObject];
}

#pragma mark - < PHAsset >

+ (PHAsset *)fetchAssetWithLocalIdentifier:(NSString *)localIdentifier {
    return [[PHAsset fetchAssetsWithLocalIdentifiers:@[localIdentifier] options:nil] firstObject];
}
+ (PHFetchResult<PHAsset *> *)fetchAssetsInAssetCollection:(PHAssetCollection *)assetCollection
                                                   options:(PHFetchOptions *)options {
    return [PHAsset fetchAssetsInAssetCollection:assetCollection options:options];
}
+ (UIImage *)originImageForAsset:(PHAsset *)asset {
    __block UIImage *resultImage = nil;
    PHImageRequestOptions *phImageRequestOptions = [[PHImageRequestOptions alloc] init];
    phImageRequestOptions.deliveryMode = PHImageRequestOptionsDeliveryModeHighQualityFormat;
    phImageRequestOptions.networkAccessAllowed = YES;
    phImageRequestOptions.synchronous = YES;
    [[PHImageManager defaultManager] requestImageDataForAsset:asset options:phImageRequestOptions resultHandler:^(NSData * _Nullable imageData, NSString * _Nullable dataUTI, UIImageOrientation orientation, NSDictionary * _Nullable info) {
        resultImage = [UIImage imageWithData:imageData];
    }];
    return resultImage;
}
+ (void)requestVideoURL:(PHAsset *)asset completion:(void (^)(NSURL * _Nullable))completion {
    [self requestAVAssetForAsset:asset networkAccessAllowed:YES progressHandler:nil completion:^(AVAsset * _Nonnull avAsset, AVAudioMix * _Nonnull audioMix, NSDictionary * _Nonnull info) {
        [asset hx_checkForModificationsWithAssetPathMethodCompletion:^(BOOL isAdjusted) {
            NSString *fileName = [[NSString hx_fileName] stringByAppendingString:@".mp4"];
            NSString *fullPathToFile = [NSTemporaryDirectory() stringByAppendingPathComponent:fileName];
            NSURL *videoURL = [NSURL fileURLWithPath:fullPathToFile];
            if (isAdjusted) {
                if ([avAsset isKindOfClass:AVURLAsset.class]) {
                    NSFileManager *fileManager = [NSFileManager defaultManager];
                    NSError *error;
                    [fileManager copyItemAtURL:[(AVURLAsset *)avAsset URL] toURL:videoURL error:&error];
                    if (error == nil) {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            if (completion) {
                                completion(videoURL);
                            }
                        });
                        return;
                    }
                }
                NSArray *presets = [AVAssetExportSession exportPresetsCompatibleWithAsset:avAsset];
                NSString *presetName;
                if ([presets containsObject:AVAssetExportPresetHighestQuality]) {
                    presetName = AVAssetExportPresetHighestQuality;
                }else {
                    presetName = AVAssetExportPresetMediumQuality;
                }
                AVAssetExportSession *session = [[AVAssetExportSession alloc] initWithAsset:avAsset presetName:presetName];
                session.outputURL = videoURL;
                session.shouldOptimizeForNetworkUse = YES;
                
                NSArray *supportedTypeArray = session.supportedFileTypes;
                if ([supportedTypeArray containsObject:AVFileTypeMPEG4]) {
                    session.outputFileType = AVFileTypeMPEG4;
                } else if (supportedTypeArray.count == 0) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        if (completion) {
                            completion(nil);
                        }
                    });
                    return;
                }else {
                    session.outputFileType = [supportedTypeArray objectAtIndex:0];
                }
                
                [session exportAsynchronouslyWithCompletionHandler:^{
                    dispatch_async(dispatch_get_main_queue(), ^{
                        if ([session status] == AVAssetExportSessionStatusCompleted) {
                            if (completion) {
                                completion(videoURL);
                            }
                        }else if ([session status] == AVAssetExportSessionStatusFailed ||
                                  [session status] == AVAssetExportSessionStatusCancelled) {
                            if (completion) {
                                completion(nil);
                            }
                        }
                    });
                }];
            }else {
                PHAssetResource *videoResource = [PHAssetResource assetResourcesForAsset:asset].firstObject;
                PHAssetResourceRequestOptions *options = [[PHAssetResourceRequestOptions alloc] init];
                options.networkAccessAllowed = YES;
                [[PHAssetResourceManager defaultManager] writeDataForAssetResource:videoResource toFile:videoURL options:options completionHandler:^(NSError * _Nullable error) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        if (!error) {
                            if (completion) {
                                completion(videoURL);
                            }
                        }else {
                            completion(nil);
                        }
                    });
                }];
            }
        }];
    }];
}
+ (CGSize)getAssetTargetSizeWithAsset:(PHAsset *)asset width:(CGFloat)width {
    if (!asset) {
        return CGSizeMake(width, width);
    }
    CGFloat scale = 0.8f;
    CGFloat aspectRatio = asset.pixelWidth / (CGFloat)asset.pixelHeight;
    CGFloat initialWidth = width;
    CGFloat height;
    if (asset.pixelWidth < width) {
        width = width * 0.5f;
    }
    height = width / aspectRatio;
    CGFloat maxHeight = [UIScreen mainScreen].bounds.size.height;
    if (height > maxHeight) {
        width = maxHeight / height * width * scale;
        height = maxHeight * scale;
    }
    if (height < initialWidth && width >= initialWidth) {
        width = initialWidth / height * width * scale;
        height = initialWidth * scale;
    }
    CGSize size = CGSizeMake(width, height);
    return size;
}
+ (PHImageRequestID)requestImageForAsset:(PHAsset *)asset
                              targetSize:(CGSize)targetSize
                             contentMode:(PHImageContentMode)contentMode
                                 options:(PHImageRequestOptions *)options
                              completion:(void (^)(UIImage *result, NSDictionary<NSString *, id> *info))completion {
    if (!asset) {
        completion(nil, nil);
        return -1;
    }
    return [[PHImageManager defaultManager] requestImageForAsset:asset targetSize:targetSize contentMode:contentMode options:options resultHandler:^(UIImage * _Nullable result, NSDictionary * _Nullable info) {
        if (completion) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(result, info);
            });
        }
    }];
}

+ (PHImageRequestID)requestThumbnailImageForAsset:(PHAsset *)asset
                                      targetWidth:(CGFloat)targetWidth
                                       completion:(void (^)(UIImage *result, NSDictionary<NSString *, id> *info))completion {
    return [self requestThumbnailImageForAsset:asset targetWidth:targetWidth deliveryMode:PHImageRequestOptionsDeliveryModeOpportunistic completion:^(UIImage * _Nonnull result, NSDictionary<NSString *,id> * _Nonnull info) {
        if (completion) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(result, info);
            });
        }
    }];
}

+ (PHImageRequestID)requestThumbnailImageForAsset:(PHAsset *)asset
                                      targetWidth:(CGFloat)targetWidth
                                     deliveryMode:(PHImageRequestOptionsDeliveryMode)deliveryMode
                                       completion:(void (^)(UIImage *result, NSDictionary<NSString *, id> *info))completion {
    PHImageRequestOptions *options = [[PHImageRequestOptions alloc] init];
    options.resizeMode = PHImageRequestOptionsResizeModeFast;
    options.deliveryMode = deliveryMode;
    return [self requestImageForAsset:asset targetSize:[self getAssetTargetSizeWithAsset:asset width:targetWidth] contentMode:PHImageContentModeAspectFill options:options completion:^(UIImage * _Nonnull result, NSDictionary<NSString *,id> * _Nonnull info) {
        if (completion) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(result, info);
            });
        }
    }];
}

+ (PHImageRequestID)requestPreviewImageForAsset:(PHAsset *)asset
                                     targetSize:(CGSize)targetSize
                           networkAccessAllowed:(BOOL)networkAccessAllowed
                                progressHandler:(PHAssetImageProgressHandler _Nullable)progressHandler
                                     completion:(void (^ _Nullable)(UIImage *result, NSDictionary<NSString *, id> *info))completion; {
    PHImageRequestOptions *options = [[PHImageRequestOptions alloc] init];
    options.resizeMode = PHImageRequestOptionsResizeModeFast;
    options.deliveryMode = PHImageRequestOptionsDeliveryModeHighQualityFormat;
    options.networkAccessAllowed = networkAccessAllowed;
    options.progressHandler = progressHandler;
    return [self requestImageForAsset:asset targetSize:targetSize contentMode:PHImageContentModeAspectFill options:options completion:^(UIImage * _Nonnull result, NSDictionary<NSString *,id> * _Nonnull info) {
        if (completion) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(result, info);
            });
        }
    }];
}

+ (void)requestVideoURLForAsset:(PHAsset *)asset
                         toFile:(NSURL * _Nullable)fileURL
                   exportPreset:(HXVideoExportPreset)exportPreset
                   videoQuality:(NSInteger)videoQuality
                  resultHandler:(void (^ _Nullable)(NSURL * _Nullable))resultHandler {
    [self requestAVAssetForAsset:asset networkAccessAllowed:YES progressHandler:nil completion:^(AVAsset * _Nonnull asset, AVAudioMix * _Nonnull audioMix, NSDictionary * _Nonnull info) {
        if (asset == nil) {
            if (resultHandler) {
                resultHandler(nil);
            }
            return;
        }
        NSString *fileName = [[NSString hx_fileName] stringByAppendingString:@".mp4"];
        NSString *fullPathToFile = [NSTemporaryDirectory() stringByAppendingPathComponent:fileName];
        NSURL *videoURL = fileURL ?:  [NSURL fileURLWithPath:fullPathToFile];
        NSString *presetName = [self presetName:exportPreset];
        NSArray *presets = [AVAssetExportSession exportPresetsCompatibleWithAsset:asset];
        if (![presets containsObject:presetName]) {
            if (resultHandler) {
                resultHandler(nil);
            }
            return;
        }
        AVAssetExportSession *session = [AVAssetExportSession exportSessionWithAsset:asset presetName:presetName];
        session.outputURL = videoURL;
        session.shouldOptimizeForNetworkUse = YES;
        NSArray *supportedTypeArray = session.supportedFileTypes;
        if ([supportedTypeArray containsObject:AVFileTypeMPEG4]) {
            session.outputFileType = AVFileTypeMPEG4;
        }else if (supportedTypeArray.count == 0) {
            if (resultHandler) {
                resultHandler(nil);
            }
            return;
        }else {
            session.outputFileType = [supportedTypeArray objectAtIndex:0];
        }
        if (videoQuality > 0) {
            session.fileLengthLimit = [self exportSessionFileLengthLimitWithSeconds:CMTimeGetSeconds(asset.duration) exportPreset:exportPreset videoQuality:videoQuality];
        }
        [session exportAsynchronouslyWithCompletionHandler:^{
            dispatch_async(dispatch_get_main_queue(), ^{
                if (session.status == AVAssetExportSessionStatusCompleted) {
                    if (resultHandler) {
                        resultHandler(videoURL);
                    }
                }else {
                    if (resultHandler) {
                        resultHandler(nil);
                    }
                }
            });
        }];
    }];
}
+ (NSString *)presetName:(HXVideoExportPreset)exportPreset {
    switch (exportPreset) {
        case HXVideoEditorExportPresetLowQuality:
            return AVAssetExportPresetLowQuality;
        case HXVideoEditorExportPresetMediumQuality:
            return AVAssetExportPresetMediumQuality;
        case HXVideoEditorExportPresetHighQuality:
            return AVAssetExportPresetHighestQuality;
        case HXVideoEditorExportPresetRatio_640x480:
            return AVAssetExportPreset640x480;
        case HXVideoEditorExportPresetRatio_960x540:
            return AVAssetExportPreset960x540;
        case HXVideoEditorExportPresetRatio_1280x720:
            return AVAssetExportPreset1280x720;
        default:
            return AVAssetExportPresetMediumQuality;
    }
}
+ (NSInteger)exportSessionFileLengthLimitWithSeconds:(CGFloat)seconds
                                        exportPreset:(HXVideoExportPreset)exportPreset
                                        videoQuality:(NSInteger)videoQuality {
    if (videoQuality > 0) {
        CGFloat ratioParam = 0;
        if (exportPreset == HXVideoEditorExportPresetRatio_640x480) {
            ratioParam = 0.02;
        }else if (exportPreset == HXVideoEditorExportPresetRatio_960x540) {
            ratioParam = 0.04;
        }else if (exportPreset == HXVideoEditorExportPresetRatio_1280x720) {
            ratioParam = 0.08;
        }
        NSInteger quality = MIN(videoQuality, 10);
        return seconds * ratioParam * quality * 1000 * 1000;
    }
    return 0;
}
+ (UIImageOrientation)imageOrientationWithCGImageOrientation:(CGImagePropertyOrientation)orientation {
    UIImageOrientation sureOrientation;
    if (orientation == kCGImagePropertyOrientationUp) {
        sureOrientation = UIImageOrientationUp;
    } else if (orientation == kCGImagePropertyOrientationUpMirrored) {
        sureOrientation = UIImageOrientationUpMirrored;
    } else if (orientation == kCGImagePropertyOrientationDown) {
        sureOrientation = UIImageOrientationDown;
    } else if (orientation == kCGImagePropertyOrientationDownMirrored) {
        sureOrientation = UIImageOrientationDownMirrored;
    } else if (orientation == kCGImagePropertyOrientationLeftMirrored) {
        sureOrientation = UIImageOrientationLeftMirrored;
    } else if (orientation == kCGImagePropertyOrientationRight) {
        sureOrientation = UIImageOrientationRight;
    } else if (orientation == kCGImagePropertyOrientationRightMirrored) {
        sureOrientation = UIImageOrientationRightMirrored;
    } else if (orientation == kCGImagePropertyOrientationLeft) {
        sureOrientation = UIImageOrientationLeft;
    } else {
        sureOrientation = UIImageOrientationUp;
    }
    return sureOrientation;
}
+ (PHImageRequestID)requestImageDataForAsset:(PHAsset *)asset
                                     options:(PHImageRequestOptions *)options
                                  completion:(void (^)(NSData *imageData,  UIImageOrientation orientation, NSDictionary<NSString *, id> *info))completion {
    PHImageRequestID requestID;
    if (@available(iOS 13.0, *)) {
        requestID = [[PHImageManager defaultManager] requestImageDataAndOrientationForAsset:asset options:options resultHandler:^(NSData * _Nullable imageData, NSString * _Nullable dataUTI, CGImagePropertyOrientation orientation, NSDictionary * _Nullable info) {
            if (completion) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    completion(imageData, [self imageOrientationWithCGImageOrientation:orientation], info);
                });
            }
        }];
    }else {
        requestID = [[PHImageManager defaultManager] requestImageDataForAsset:asset options:options resultHandler:^(NSData * _Nullable imageData, NSString * _Nullable dataUTI, UIImageOrientation orientation, NSDictionary * _Nullable info) {
            if (completion) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    completion(imageData, orientation, info);
                });
            }
        }];
    }
    return requestID;
}

+ (PHImageRequestID)requestImageDataForAsset:(PHAsset *)asset
                                     version:(PHImageRequestOptionsVersion)version
                                  resizeMode:(PHImageRequestOptionsResizeMode)resizeMode
                        networkAccessAllowed:(BOOL)networkAccessAllowed
                             progressHandler:(PHAssetImageProgressHandler)progressHandler
                                  completion:(void (^)(NSData *imageData,  UIImageOrientation orientation, NSDictionary<NSString *, id> *info))completion {
    PHImageRequestOptions *options = [[PHImageRequestOptions alloc] init];
    options.version = version;
    options.deliveryMode = PHImageRequestOptionsDeliveryModeHighQualityFormat;
    options.resizeMode = resizeMode;
    options.networkAccessAllowed = networkAccessAllowed;
    options.progressHandler = progressHandler;
    return [self requestImageDataForAsset:asset options:options completion:^(NSData * _Nonnull imageData, UIImageOrientation orientation, NSDictionary<NSString *,id> * _Nonnull info) {
        if (completion) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(imageData, orientation, info);
            });
        }
    }];
}

+ (PHLivePhotoRequestID)requestLivePhotoForAsset:(PHAsset *)asset
                                      targetSize:(CGSize)targetSize
                                     contentMode:(PHImageContentMode)contentMode
                                         options:(PHLivePhotoRequestOptions *)options
                                      completion:(void (^)(PHLivePhoto *livePhoto, NSDictionary<NSString *,id> * _Nonnull info))completion {
    return [[PHImageManager defaultManager] requestLivePhotoForAsset:asset targetSize:targetSize contentMode:contentMode options:options resultHandler:^(PHLivePhoto * _Nullable livePhoto, NSDictionary * _Nullable info) {
        if (completion) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(livePhoto, info);
            });
        }
    }];
}
+ (PHLivePhotoRequestID)requestPreviewLivePhotoForAsset:(PHAsset *)asset
                                             targetSize:(CGSize)targetSize
                                   networkAccessAllowed:(BOOL)networkAccessAllowed
                                        progressHandler:(PHAssetImageProgressHandler)progressHandler
                                             completion:(void (^)(PHLivePhoto *livePhoto, NSDictionary<NSString *,id> * _Nonnull info))completion {
    PHLivePhotoRequestOptions *options = [[PHLivePhotoRequestOptions alloc] init];
    options.deliveryMode = PHImageRequestOptionsDeliveryModeHighQualityFormat;
    options.networkAccessAllowed = networkAccessAllowed;
    options.progressHandler = progressHandler;
    return [self requestLivePhotoForAsset:asset targetSize:targetSize contentMode:PHImageContentModeAspectFill options:options completion:^(PHLivePhoto * _Nonnull livePhoto, NSDictionary<NSString *,id> * _Nonnull info) {
        if (completion) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(livePhoto, info);
            });
        }
    }];
}
+ (PHImageRequestID)requestAVAssetForAsset:(PHAsset *)asset
                                   options:(PHVideoRequestOptions *)options
                                completion:(void (^)(AVAsset *asset, AVAudioMix *audioMix, NSDictionary *info))completion {
    return [[PHImageManager defaultManager] requestAVAssetForVideo:asset options:options resultHandler:^(AVAsset * _Nullable asset, AVAudioMix * _Nullable audioMix, NSDictionary * _Nullable info) {
        if (completion) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(asset, audioMix, info);
            });
        }
    }];
}
+ (PHImageRequestID)requestAVAssetForAsset:(PHAsset *)asset
                      networkAccessAllowed:(BOOL)networkAccessAllowed
                           progressHandler:(PHAssetImageProgressHandler)progressHandler
                                completion:(void (^)(AVAsset *asset, AVAudioMix *audioMix, NSDictionary *info))completion {
    PHVideoRequestOptions *options = [[PHVideoRequestOptions alloc] init];
    options.deliveryMode = PHVideoRequestOptionsDeliveryModeHighQualityFormat;
    options.networkAccessAllowed = networkAccessAllowed;
    options.progressHandler = progressHandler;
    return [self requestAVAssetForAsset:asset options:options completion:^(AVAsset * _Nonnull asset, AVAudioMix * _Nonnull audioMix, NSDictionary * _Nonnull info) {
        if (completion) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(asset, audioMix, info);
            });
        }
    }];
}
+ (PHImageRequestID)requestPlayerItemForAsset:(PHAsset *)asset
                                      options:(PHVideoRequestOptions * _Nullable)options
                                   completion:(void (^ _Nullable)(AVPlayerItem * _Nullable playerItem, NSDictionary * _Nullable info))completion {
    return [[PHImageManager defaultManager] requestPlayerItemForVideo:asset options:options resultHandler:^(AVPlayerItem * _Nullable playerItem, NSDictionary * _Nullable info) {
        if (completion) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(playerItem, info);
            });
        }
    }];
}

+ (PHImageRequestID)requestPlayerItemForAsset:(PHAsset *)asset
                         networkAccessAllowed:(BOOL)networkAccessAllowed
                              progressHandler:(PHAssetImageProgressHandler _Nullable)progressHandler
                                   completion:(void (^ _Nullable)(AVPlayerItem * _Nullable playerItem, NSDictionary * _Nullable info))completion {
    PHVideoRequestOptions *options = [[PHVideoRequestOptions alloc] init];
    options.deliveryMode = PHVideoRequestOptionsDeliveryModeHighQualityFormat;
    options.networkAccessAllowed = networkAccessAllowed;
    options.progressHandler = progressHandler;
    return [self requestPlayerItemForAsset:asset options:options completion:^(AVPlayerItem * _Nullable playerItem, NSDictionary * _Nullable info) {
        if (completion) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(playerItem, info);
            });
        }
    }];
}
+ (PHImageRequestID)requestExportSessionForAsset:(PHAsset *)asset
                                         options:(PHVideoRequestOptions * _Nullable)options
                                    exportPreset:(NSString *)exportPreset
                                      completion:(void (^ _Nullable)(AVAssetExportSession * _Nullable exportSession, NSDictionary * _Nullable info))completion {
    return [[PHImageManager defaultManager] requestExportSessionForVideo:asset options:options exportPreset:exportPreset resultHandler:^(AVAssetExportSession * _Nullable exportSession, NSDictionary * _Nullable info) {
        if (completion) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(exportSession, info);
            });
        }
    }];
}
+ (PHImageRequestID)requestExportSessionForAsset:(PHAsset *)asset
                                    exportPreset:(NSString *)exportPreset
                            networkAccessAllowed:(BOOL)networkAccessAllowed
                                 progressHandler:(PHAssetImageProgressHandler _Nullable)progressHandler
                                      completion:(void (^ _Nullable)(AVAssetExportSession * _Nullable exportSession, NSDictionary * _Nullable info))completion {
    PHVideoRequestOptions *options = [[PHVideoRequestOptions alloc] init];
    options.deliveryMode = PHVideoRequestOptionsDeliveryModeHighQualityFormat;
    options.networkAccessAllowed = networkAccessAllowed;
    options.progressHandler = progressHandler;
    return [self requestExportSessionForAsset:asset options:options exportPreset:exportPreset completion:^(AVAssetExportSession * _Nullable exportSession, NSDictionary * _Nullable info) {
        if (completion) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(exportSession, info);
            });
        }
    }];
}
+ (BOOL)downloadFininedForInfo:(NSDictionary *)info {
    BOOL downloadFinined = (![[info objectForKey:PHImageCancelledKey] boolValue] && ![info objectForKey:PHImageErrorKey] && ![[info objectForKey:PHImageResultIsDegradedKey] boolValue]);
    return downloadFinined;
}
+ (BOOL)isInCloudForInfo:(NSDictionary *)info {
    return [[info objectForKey:PHImageResultIsInCloudKey] boolValue];
}
@end
