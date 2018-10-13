//
//  HXPhotoTools.m
//  照片选择器
//
//  Created by 洪欣 on 17/2/8.
//  Copyright © 2017年 洪欣. All rights reserved.
//

#import "HXPhotoTools.h"
#import "HXPhotoModel.h"
#import "UIImage+HXExtension.h"
#import "HXPhotoManager.h"
#import <sys/utsname.h>
#import "HXDatePhotoToolManager.h"
#import <MobileCoreServices/MobileCoreServices.h>
@implementation HXPhotoTools

+ (UIImage *)hx_imageNamed:(NSString *)imageName {
    UIImage *image = [UIImage imageNamed:imageName];
    if (image) {
        return image;
    }
    NSString *path = [NSString stringWithFormat:@"HXPhotoPicker.bundle/%@",imageName];
    image = [UIImage imageNamed:path];
    if (image) {
        return image;
    } else {
        NSString *path = [NSString stringWithFormat:@"Frameworks/HXPhotoPicker.framework/HXPhotoPicker.bundle/%@",imageName];
        image = [UIImage imageNamed:path];
        if (!image) {
            image = [UIImage imageNamed:imageName];
        }
        return image;
    }
}

+ (UIImage *)thumbnailImageForVideo:(NSURL *)videoURL atTime:(NSTimeInterval)time {
    AVURLAsset *asset = [[AVURLAsset alloc] initWithURL:videoURL options:nil];
    if (!asset) {
        return nil;
    }
    AVAssetImageGenerator *assetImageGenerator =[[AVAssetImageGenerator alloc] initWithAsset:asset];
    assetImageGenerator.appliesPreferredTrackTransform = YES;
    assetImageGenerator.apertureMode = AVAssetImageGeneratorApertureModeEncodedPixels;
    CGImageRef thumbnailImageRef = NULL;
    CFTimeInterval thumbnailImageTime = time;
    NSError *thumbnailImageGenerationError = nil;
    thumbnailImageRef = [assetImageGenerator copyCGImageAtTime:CMTimeMake(thumbnailImageTime, 60)actualTime:NULL error:&thumbnailImageGenerationError];
    UIImage*thumbnailImage = thumbnailImageRef ? [[UIImage alloc]initWithCGImage: thumbnailImageRef] : nil;
    return thumbnailImage;
}

+ (CLGeocoder *)getDateLocationDetailInformationWithModel:(HXPhotoDateModel *)model completion:(void (^)(CLPlacemark *placemark,HXPhotoDateModel *model))completion {
    CLGeocoder *geoCoder = [[CLGeocoder alloc] init]; 
    [geoCoder reverseGeocodeLocation:model.location completionHandler:^(NSArray<CLPlacemark *> * _Nullable placemarks, NSError * _Nullable error) {
        if (placemarks.count > 0 && !error) {
            CLPlacemark *placemark = placemarks.firstObject;
            if (completion) {
                completion(placemark,model);
            }
        }
    }];
    return geoCoder;
//    __block NSMutableArray *placemarkArray = [NSMutableArray array];
//    NSInteger locationCount = 0;
//    for (HXPhotoModel *subModel in model.photoModelArray) {
//        if (subModel.asset.location) {
//            [geoCoder reverseGeocodeLocation:subModel.asset.location completionHandler:^(NSArray<CLPlacemark *> * _Nullable placemarks, NSError * _Nullable error) {
//                if (placemarks.count > 0 && !error) {
//                    CLPlacemark *placemark = placemarks.firstObject;
//                    [placemarkArray addObject:placemark];
//                    if (placemark) {
//                        <#statements#>
//                    }
//                }
//            }];
//            locationCount++;
//        }
//    }
}
+ (PHImageRequestID)getAVAssetWithModel:(HXPhotoModel *)model startRequestIcloud:(void (^)(HXPhotoModel *model, PHImageRequestID cloudRequestId))startRequestIcloud progressHandler:(void (^)(HXPhotoModel *model, double progress))progressHandler completion:(void(^)(HXPhotoModel *model, AVAsset *asset))completion failed:(void(^)(HXPhotoModel *model, NSDictionary *info))failed {
    PHVideoRequestOptions *options = [[PHVideoRequestOptions alloc] init];
    options.deliveryMode = PHVideoRequestOptionsDeliveryModeFastFormat;
    options.networkAccessAllowed = NO;
    PHImageRequestID requestId = 0;
    model.iCloudDownloading = YES;
    requestId = [[PHImageManager defaultManager] requestAVAssetForVideo:model.asset options:options resultHandler:^(AVAsset * _Nullable asset, AVAudioMix * _Nullable audioMix, NSDictionary * _Nullable info) {
        BOOL downloadFinined = (![[info objectForKey:PHImageCancelledKey] boolValue] && ![info objectForKey:PHImageErrorKey] && ![[info objectForKey:PHImageResultIsDegradedKey] boolValue]);
        if (downloadFinined && asset) {
            dispatch_async(dispatch_get_main_queue(), ^{
                model.iCloudDownloading = NO;
                model.isICloud = NO;
                if (completion) {
                    completion(model,asset);
                }
            });
        }else {
            if ([[info objectForKey:PHImageResultIsInCloudKey] boolValue] && ![[info objectForKey:PHImageCancelledKey] boolValue] && ![info objectForKey:PHImageErrorKey]) {
                PHImageRequestID cloudRequestId = 0;
                PHVideoRequestOptions *cloudOptions = [[PHVideoRequestOptions alloc] init];
                cloudOptions.deliveryMode = PHVideoRequestOptionsDeliveryModeMediumQualityFormat;
                cloudOptions.networkAccessAllowed = YES;
                cloudOptions.progressHandler = ^(double progress, NSError * _Nullable error, BOOL * _Nonnull stop, NSDictionary * _Nullable info) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        model.iCloudProgress = progress;
                        if (progressHandler) {
                            progressHandler(model,progress);
                        }
                    });
                };
                cloudRequestId = [[PHImageManager defaultManager] requestAVAssetForVideo:model.asset options:cloudOptions resultHandler:^(AVAsset * _Nullable asset, AVAudioMix * _Nullable audioMix, NSDictionary * _Nullable info) {
                    BOOL downloadFinined = (![[info objectForKey:PHImageCancelledKey] boolValue] && ![info objectForKey:PHImageErrorKey] && ![[info objectForKey:PHImageResultIsDegradedKey] boolValue]);
                    if (downloadFinined && asset) {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            model.iCloudDownloading = NO;
                            model.isICloud = NO;
                            if (completion) {
                                completion(model,asset);
                            }
                        });
                    }else {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            if (![[info objectForKey:PHImageCancelledKey] boolValue]) {
                                model.iCloudDownloading = NO;
                            }
                            if (failed) {
                                failed(model,info);
                            }
                        });
                    }
                }];
                dispatch_async(dispatch_get_main_queue(), ^{
                    model.iCloudRequestID = cloudRequestId;
                    if (startRequestIcloud) {
                        startRequestIcloud(model,cloudRequestId);
                    }
                });
            }else {
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (![[info objectForKey:PHImageCancelledKey] boolValue]) {
                        model.iCloudDownloading = NO;
                    }
                    if (failed) {
                        failed(model,info);
                    }
                });
            }
        }
    }];
    model.iCloudRequestID = requestId;
    return requestId;
}
+ (PHImageRequestID)getLivePhotoWithModel:(HXPhotoModel *)model size:(CGSize)size startRequestICloud:(void (^)(HXPhotoModel *model, PHImageRequestID iCloudRequestId))startRequestICloud progressHandler:(void (^)(HXPhotoModel *model, double progress))progressHandler completion:(void(^)(HXPhotoModel *model, PHLivePhoto *livePhoto))completion failed:(void(^)(HXPhotoModel *model, NSDictionary *info))failed {
    PHLivePhotoRequestOptions *option = [[PHLivePhotoRequestOptions alloc] init];
    option.deliveryMode = PHImageRequestOptionsDeliveryModeHighQualityFormat;
    option.networkAccessAllowed = NO;
    PHImageRequestID requestId = 0;
    model.iCloudDownloading = YES;
    requestId = [[PHImageManager defaultManager] requestLivePhotoForAsset:model.asset targetSize:size contentMode:PHImageContentModeAspectFill options:option resultHandler:^(PHLivePhoto * _Nullable livePhoto, NSDictionary * _Nullable info) {
        BOOL downloadFinined = (![[info objectForKey:PHImageCancelledKey] boolValue] && ![info objectForKey:PHImageErrorKey] && ![[info objectForKey:PHImageResultIsDegradedKey] boolValue]);
        if (downloadFinined && completion && livePhoto) {
            dispatch_async(dispatch_get_main_queue(), ^{
                model.isICloud = NO;
                model.iCloudDownloading = NO;
                completion(model,livePhoto);
            });
        }else {
            if ([[info objectForKey:PHImageResultIsInCloudKey] boolValue] && ![[info objectForKey:PHImageCancelledKey] boolValue] && ![info objectForKey:PHImageErrorKey]) {
                PHImageRequestID iCloudRequestId = 0;
                PHLivePhotoRequestOptions *iCloudOption = [[PHLivePhotoRequestOptions alloc] init];
                iCloudOption.deliveryMode = PHImageRequestOptionsDeliveryModeHighQualityFormat;
                iCloudOption.networkAccessAllowed = YES;
                iCloudOption.progressHandler = ^(double progress, NSError * _Nullable error, BOOL * _Nonnull stop, NSDictionary * _Nullable info) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        model.iCloudProgress = progress;
                        if (progressHandler) {
                            progressHandler(model,progress);
                        }
                    });
                };
                iCloudRequestId = [[PHImageManager defaultManager] requestLivePhotoForAsset:model.asset targetSize:size contentMode:PHImageContentModeAspectFill options:iCloudOption resultHandler:^(PHLivePhoto * _Nullable livePhoto, NSDictionary * _Nullable info) {
                    BOOL downloadFinined = (![[info objectForKey:PHImageCancelledKey] boolValue] && ![info objectForKey:PHImageErrorKey] && ![[info objectForKey:PHImageResultIsDegradedKey] boolValue]);
                    if (downloadFinined && livePhoto) {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            model.isICloud = NO;
                            model.iCloudDownloading = NO;
                            if (completion) {
                                completion(model,livePhoto);
                            }
                        });
                    }else {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            if (![[info objectForKey:PHImageCancelledKey] boolValue]) {
                                model.iCloudDownloading = NO;
                            }
                            if (failed) {
                                failed(model,info);
                            }
                        });
                    }
                }];
                dispatch_async(dispatch_get_main_queue(), ^{
                    model.iCloudRequestID = requestId;
                    if (startRequestICloud) {
                        startRequestICloud(model,iCloudRequestId);
                    }
                });
            }else {
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (![[info objectForKey:PHImageCancelledKey] boolValue]) {
                        model.iCloudDownloading = NO;
                    }
                    if (failed) {
                        failed(model,info);
                    }
                });
            }
        }
    }];
    model.iCloudRequestID = requestId;
    return requestId;
}
+ (PHImageRequestID)getImageDataWithModel:(HXPhotoModel *)model startRequestIcloud:(void (^)(HXPhotoModel *model, PHImageRequestID cloudRequestId))startRequestIcloud progressHandler:(void (^)(HXPhotoModel *model, double progress))progressHandler completion:(void(^)(HXPhotoModel *model, NSData *imageData, UIImageOrientation orientation))completion failed:(void(^)(HXPhotoModel *model, NSDictionary *info))failed {
    PHImageRequestOptions *option = [[PHImageRequestOptions alloc] init];
    option.deliveryMode = PHImageRequestOptionsDeliveryModeHighQualityFormat;
    option.resizeMode = PHImageRequestOptionsResizeModeFast;
    option.networkAccessAllowed = NO;
    option.synchronous = NO;
    if (model.type == HXPhotoModelMediaTypePhotoGif) { 
        option.version = PHImageRequestOptionsVersionOriginal;
    }
    model.iCloudDownloading = YES;
    PHImageRequestID requestID = [[PHImageManager defaultManager] requestImageDataForAsset:model.asset options:option resultHandler:^(NSData * _Nullable imageData, NSString * _Nullable dataUTI, UIImageOrientation orientation, NSDictionary * _Nullable info) {
        BOOL downloadFinined = (![[info objectForKey:PHImageCancelledKey] boolValue] && ![info objectForKey:PHImageErrorKey] && ![[info objectForKey:PHImageResultIsDegradedKey] boolValue]);
        if (downloadFinined && imageData) {
            dispatch_async(dispatch_get_main_queue(), ^{
                model.iCloudDownloading = NO;
                model.isICloud = NO;
                if (completion) {
                    completion(model,imageData, orientation);
                }
            });
        }else {
            if ([[info objectForKey:PHImageResultIsInCloudKey] boolValue] && ![[info objectForKey:PHImageCancelledKey] boolValue] && ![info objectForKey:PHImageErrorKey]) {
                PHImageRequestID cloudRequestId = 0;
                PHImageRequestOptions *option = [[PHImageRequestOptions alloc] init];
                option.deliveryMode = PHImageRequestOptionsDeliveryModeHighQualityFormat;
                option.resizeMode = PHImageRequestOptionsResizeModeFast;
                option.networkAccessAllowed = YES;
                option.version = PHImageRequestOptionsVersionOriginal;
                option.progressHandler = ^(double progress, NSError * _Nullable error, BOOL * _Nonnull stop, NSDictionary * _Nullable info) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        model.iCloudProgress = progress;
                        if (progressHandler) {
                            progressHandler(model,progress);
                        }
                    });
                };
                cloudRequestId = [[PHImageManager defaultManager] requestImageDataForAsset:model.asset options:option resultHandler:^(NSData * _Nullable imageData, NSString * _Nullable dataUTI, UIImageOrientation orientation, NSDictionary * _Nullable info) {
                    BOOL downloadFinined = (![[info objectForKey:PHImageCancelledKey] boolValue] && ![info objectForKey:PHImageErrorKey] && ![[info objectForKey:PHImageResultIsDegradedKey] boolValue]);
                    if (downloadFinined && imageData) {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            model.iCloudDownloading = NO;
                            model.isICloud = NO;
                            if (completion) {
                                completion(model,imageData, orientation);
                            }
                        });
                    }else {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            if (![[info objectForKey:PHImageCancelledKey] boolValue]) {
                                model.iCloudDownloading = NO;
                            }
                            if (failed) {
                                failed(model,info);
                            }
                        });
                    }
                }];
                dispatch_async(dispatch_get_main_queue(), ^{
                    model.iCloudRequestID = cloudRequestId;
                    if (startRequestIcloud) {
                        startRequestIcloud(model,cloudRequestId);
                    }
                });
            }else {
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (![[info objectForKey:PHImageCancelledKey] boolValue]) {
                        model.iCloudDownloading = NO;
                    }
                    if (failed) {
                        failed(model,info);
                    }
                });
            }
        }
    }];
    model.iCloudRequestID = requestID;
    return requestID;
}

+ (PHContentEditingInputRequestID)getImagePathWithModel:(HXPhotoModel *)model startRequestIcloud:(void (^)(HXPhotoModel *, PHContentEditingInputRequestID))startRequestIcloud progressHandler:(void (^)(HXPhotoModel *, double))progressHandler completion:(void (^)(HXPhotoModel *, NSString *))completion failed:(void (^)(HXPhotoModel *, NSDictionary *))failed {
    
    PHContentEditingInputRequestOptions *options = [[PHContentEditingInputRequestOptions alloc] init];
    options.networkAccessAllowed = NO;
    return [model.asset requestContentEditingInputWithOptions:options completionHandler:^(PHContentEditingInput * _Nullable contentEditingInput, NSDictionary * _Nonnull info) {
        BOOL downloadFinined = (![[info objectForKey:PHContentEditingInputCancelledKey] boolValue] && ![info objectForKey:PHContentEditingInputErrorKey]);
        
        if (downloadFinined && contentEditingInput.fullSizeImageURL.relativePath) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (completion) {
                    completion(model, contentEditingInput.fullSizeImageURL.relativePath);
                }
            });
        }else {
            
            if ([[info objectForKey:PHContentEditingInputResultIsInCloudKey] boolValue] && ![[info objectForKey:PHContentEditingInputCancelledKey] boolValue] && ![info objectForKey:PHContentEditingInputErrorKey]) {
                PHContentEditingInputRequestOptions *iCloudOptions = [[PHContentEditingInputRequestOptions alloc] init];
                iCloudOptions.networkAccessAllowed = YES;
                iCloudOptions.progressHandler = ^(double progress, BOOL * _Nonnull stop) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        if (progressHandler) {
                            progressHandler(model,progress);
                        }
                    });
                };
                
                PHContentEditingInputRequestID iCloudRequestID = [model.asset requestContentEditingInputWithOptions:iCloudOptions completionHandler:^(PHContentEditingInput * _Nullable contentEditingInput, NSDictionary * _Nonnull info) {
                    BOOL downloadFinined = (![[info objectForKey:PHContentEditingInputCancelledKey] boolValue] && ![info objectForKey:PHContentEditingInputErrorKey]);
                    
                    if (downloadFinined && contentEditingInput.fullSizeImageURL.relativePath) {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            if (completion) {
                                completion(model, contentEditingInput.fullSizeImageURL.relativePath);
                            }
                        });
                    }else {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            if (failed) {
                                failed(model,info);
                            }
                        });
                    }
                }];
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (startRequestIcloud) {
                        startRequestIcloud(model,iCloudRequestID);
                    }
                });
            }else {
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (failed) {
                        failed(model,info);
                    }
                });
            }
        }
    }];
}

+ (PHImageRequestID)getPhotoForPHAsset:(PHAsset *)asset size:(CGSize)size completion:(void(^)(UIImage *image,NSDictionary *info))completion {
    PHImageRequestOptions *option = [[PHImageRequestOptions alloc] init];
    option.resizeMode = PHImageRequestOptionsResizeModeFast;
    
    return [[PHImageManager defaultManager] requestImageForAsset:asset targetSize:size contentMode:PHImageContentModeAspectFill options:option resultHandler:^(UIImage * _Nullable result, NSDictionary * _Nullable info) {
        
        BOOL downloadFinined = (![[info objectForKey:PHImageCancelledKey] boolValue] && ![info objectForKey:PHImageErrorKey]);
        
        if (downloadFinined && completion && result) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(result,info);
            });
        }
    }];
}

+ (PHImageRequestID)getHighQualityFormatPhotoForPHAsset:(PHAsset *)asset size:(CGSize)size completion:(void(^)(UIImage *image,NSDictionary *info))completion error:(void(^)(NSDictionary *info))error {
    PHImageRequestOptions *option = [[PHImageRequestOptions alloc] init];
    option.deliveryMode = PHImageRequestOptionsDeliveryModeHighQualityFormat; 
    option.resizeMode = PHImageRequestOptionsResizeModeFast;
    option.networkAccessAllowed = NO;
    
    PHImageRequestID requestID = [[PHImageManager defaultManager] requestImageForAsset:asset targetSize:size contentMode:PHImageContentModeAspectFill options:option resultHandler:^(UIImage * _Nullable result, NSDictionary * _Nullable info) {
        
        BOOL downloadFinined = (![[info objectForKey:PHImageCancelledKey] boolValue] && ![info objectForKey:PHImageErrorKey] && ![[info objectForKey:PHImageResultIsDegradedKey] boolValue]);
        if (downloadFinined && result) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (completion) {
                    completion(result,info);
                }
            });
        }else {
//            if ([[info objectForKey:PHImageResultIsInCloudKey] boolValue]) {
//                PHImageRequestOptions *option = [[PHImageRequestOptions alloc] init];
//                option.deliveryMode = PHImageRequestOptionsDeliveryModeHighQualityFormat;
//                option.resizeMode = PHImageRequestOptionsResizeModeFast;
//                option.networkAccessAllowed = YES;
//                option.progressHandler = ^(double progress, NSError * _Nullable error, BOOL * _Nonnull stop, NSDictionary * _Nullable info) {
//                    NSSLog(@"%f",progress);
//                };
//                [[PHImageManager defaultManager] requestImageForAsset:asset targetSize:size contentMode:PHImageContentModeAspectFill options:option resultHandler:^(UIImage * _Nullable result, NSDictionary * _Nullable info) {
//                    BOOL downloadFinined = (![[info objectForKey:PHImageCancelledKey] boolValue] && ![info objectForKey:PHImageErrorKey] && ![[info objectForKey:PHImageResultIsDegradedKey] boolValue]);
//                    if (downloadFinined && result) {
//                        dispatch_async(dispatch_get_main_queue(), ^{
//                            if (completion) {
//                                completion(result,info);
//                            }
//                        });
//                    }else {
//                        
//                    }
//                }];
//            }else {
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (error) {
                        error(info);
                    }
                });
//            }
        }
    }];
    return requestID;
}

+ (PHImageRequestID)getImageWithAlbumModel:(HXAlbumModel *)model size:(CGSize)size completion:(void (^)(UIImage *image, HXAlbumModel *model))completion {
    PHImageRequestOptions *option = [[PHImageRequestOptions alloc] init];
    option.resizeMode = PHImageRequestOptionsResizeModeFast;
    return [[PHImageManager defaultManager] requestImageForAsset:model.asset targetSize:size contentMode:PHImageContentModeAspectFill options:option resultHandler:^(UIImage * _Nullable result, NSDictionary * _Nullable info) {
        BOOL downloadFinined = (![[info objectForKey:PHImageCancelledKey] boolValue] && ![info objectForKey:PHImageErrorKey]);
        if (downloadFinined && result) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (completion) completion(result,model);
            });
        }
    }];
}
+ (PHImageRequestID)getImageWithAlbumModel:(HXAlbumModel *)model asset:(PHAsset *)asset size:(CGSize)size completion:(void (^)(UIImage *image, HXAlbumModel *model))completion {
    PHImageRequestOptions *option = [[PHImageRequestOptions alloc] init];
    option.resizeMode = PHImageRequestOptionsResizeModeFast;
    return [[PHImageManager defaultManager] requestImageForAsset:asset targetSize:size contentMode:PHImageContentModeAspectFill options:option resultHandler:^(UIImage * _Nullable result, NSDictionary * _Nullable info) {
        BOOL downloadFinined = (![[info objectForKey:PHImageCancelledKey] boolValue] && ![info objectForKey:PHImageErrorKey]);
        if (downloadFinined && result) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (completion) completion(result,model);
            });
        }
    }];
}
+ (PHImageRequestID)getImageWithModel:(HXPhotoModel *)model completion:(void (^)(UIImage *image, HXPhotoModel *model))completion {
    PHImageRequestOptions *option = [[PHImageRequestOptions alloc] init];
    option.resizeMode = PHImageRequestOptionsResizeModeFast;
    return [[PHImageManager defaultManager] requestImageForAsset:model.asset targetSize:model.requestSize contentMode:PHImageContentModeAspectFill options:option resultHandler:^(UIImage * _Nullable result, NSDictionary * _Nullable info) {
        BOOL downloadFinined = (![[info objectForKey:PHImageCancelledKey] boolValue] && ![info objectForKey:PHImageErrorKey]);
//        if ([[info objectForKey:PHImageResultIsInCloudKey] boolValue]) {
//            NSSLog(@"icloud上的资源!!!");
//        }
        if (downloadFinined && result) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (completion) completion(result,model);
            });
        }
    }];
}

+ (PHImageRequestID)FetchLivePhotoForPHAsset:(PHAsset *)asset Size:(CGSize)size Completion:(void (^)(PHLivePhoto *, NSDictionary *))completion
{
    PHLivePhotoRequestOptions *option = [[PHLivePhotoRequestOptions alloc] init];
    option.deliveryMode = PHImageRequestOptionsDeliveryModeHighQualityFormat;
    option.networkAccessAllowed = NO;
    
    return [[PHCachingImageManager defaultManager] requestLivePhotoForAsset:asset targetSize:size contentMode:PHImageContentModeAspectFill options:option resultHandler:^(PHLivePhoto * _Nullable livePhoto, NSDictionary * _Nullable info) {
        BOOL downloadFinined = (![[info objectForKey:PHLivePhotoInfoCancelledKey] boolValue] && ![info objectForKey:PHLivePhotoInfoErrorKey]);
        if (downloadFinined && completion && livePhoto) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(livePhoto,info);
            });
        }
    }];
}

/**
 获取视频的时长
 */
+ (NSString *)getNewTimeFromDurationSecond:(NSInteger)duration {
    NSString *newTime;
    if (duration < 10) {
        newTime = [NSString stringWithFormat:@"00:0%zd",duration];
    } else if (duration < 60) {
        newTime = [NSString stringWithFormat:@"00:%zd",duration];
    } else {
        NSInteger min = duration / 60;
        NSInteger sec = duration - (min * 60);
        if (sec < 10) {
            newTime = [NSString stringWithFormat:@"%zd:0%zd",min,sec];
        } else {
            newTime = [NSString stringWithFormat:@"%zd:%zd",min,sec];
        }
    }
    return newTime;
}

/**
 相册名称转换
 */
+ (NSString *)transFormPhotoTitle:(NSString *)englishName {
    NSString *photoName; 
    if ([englishName isEqualToString:@"Bursts"]) {
        photoName = @"连拍快照";
    }else if([englishName isEqualToString:@"Recently Added"] ||
             [englishName isEqualToString:@"最後に追加した項目"] ||
             [englishName isEqualToString:@"최근 추가된 항목"] ){
        photoName = @"最近添加";
    }else if([englishName isEqualToString:@"Screenshots"] ||
             [englishName isEqualToString:@"スクリーンショット"] ||
             [englishName isEqualToString:@"스크린샷"] ){
        photoName = @"屏幕快照";
    }else if([englishName isEqualToString:@"Camera Roll"] ||
             [englishName isEqualToString:@"カメラロール"] ||
             [englishName isEqualToString:@"카메라 롤"] ){
        photoName = @"相机胶卷";
    }else if([englishName isEqualToString:@"Selfies"] ||
             [englishName isEqualToString:@"셀카"] ){
        photoName = @"自拍";
    }else if([englishName isEqualToString:@"My Photo Stream"]){
        photoName = @"我的照片流";
    }else if([englishName isEqualToString:@"Videos"] ||
             [englishName isEqualToString:@"ビデオ"] ){
        photoName = @"视频";
    }else if([englishName isEqualToString:@"All Photos"] ||
             [englishName isEqualToString:@"すべての写真"] ||
             [englishName isEqualToString:@"비디오"] ){
        photoName = @"所有照片";
    }else if([englishName isEqualToString:@"Slo-mo"] ||
             [englishName isEqualToString:@"スローモーション"] ){
        photoName = @"慢动作";
    }else if([englishName isEqualToString:@"Recently Deleted"] ||
             [englishName isEqualToString:@"最近削除した項目"] ){
        photoName = @"最近删除";
    }else if([englishName isEqualToString:@"Favorites"] ||
             [englishName isEqualToString:@"お気に入り"] ||
             [englishName isEqualToString:@"최근 삭제된 항목"] ){
        photoName = @"个人收藏";
    }else if([englishName isEqualToString:@"Panoramas"] ||
             [englishName isEqualToString:@"パノラマ"] ||
             [englishName isEqualToString:@"파노라마"] ){
        photoName = @"全景照片";
    }else {
        photoName = englishName;
    }
    return photoName;
}

+ (void)FetchPhotosBytes:(NSArray *)photos completion:(void (^)(NSString *))completion
{
    __block NSInteger dataLength = 0;
    __block NSInteger assetCount = 0;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        for (int i = 0 ; i < photos.count ; i++) {
            HXPhotoModel *model = photos[i];
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
                if (assetCount >= photos.count) {
                    NSString *bytes = [self getBytesFromDataLength:dataLength];
                    dispatch_async(dispatch_get_main_queue(), ^{
                        if (completion) completion(bytes);
                    });
                }
            }else {
                [[PHImageManager defaultManager] requestImageDataForAsset:model.asset options:nil resultHandler:^(NSData * _Nullable imageData, NSString * _Nullable dataUTI, UIImageOrientation orientation, NSDictionary * _Nullable info) {
                    dataLength += imageData.length;
                    assetCount ++;
                    if (assetCount >= photos.count) {
                        NSString *bytes = [self getBytesFromDataLength:dataLength];
                        dispatch_async(dispatch_get_main_queue(), ^{
                            if (completion) completion(bytes);
                        });
                    }
                }];
            }
        }
    });
}

+ (void)getVideoEachFrameWithAsset:(AVAsset *)asset total:(NSInteger)total size:(CGSize)size complete:(void (^)(AVAsset *, NSArray<UIImage *> *))complete {
    long duration = round(asset.duration.value) / asset.duration.timescale;
    
    NSTimeInterval average = (CGFloat)duration / (CGFloat)total;
    
    AVAssetImageGenerator *generator = [[AVAssetImageGenerator alloc] initWithAsset:asset];
    generator.maximumSize = size;
    generator.appliesPreferredTrackTransform = YES;
    generator.requestedTimeToleranceBefore = kCMTimeZero;
    generator.requestedTimeToleranceAfter = kCMTimeZero;
    
    NSMutableArray *arr = [NSMutableArray array];
    for (int i = 1; i <= total; i++) {
        CMTime time = CMTimeMake((i * average) * asset.duration.timescale, asset.duration.timescale);
        NSValue *value = [NSValue valueWithCMTime:time];
        [arr addObject:value];
    }
    NSMutableArray *arrImages = [NSMutableArray array];
    __block long count = 0;
    [generator generateCGImagesAsynchronouslyForTimes:arr completionHandler:^(CMTime requestedTime, CGImageRef  _Nullable image, CMTime actualTime, AVAssetImageGeneratorResult result, NSError * _Nullable error) {
        switch (result) {
            case AVAssetImageGeneratorSucceeded:
                [arrImages addObject:[UIImage imageWithCGImage:image]];
                break;
            case AVAssetImageGeneratorFailed:
                
                break;
            case AVAssetImageGeneratorCancelled:
                
                break;
        }
        count++;
        if (count == arr.count && complete) {
            dispatch_async(dispatch_get_main_queue(), ^{
                complete(asset, arrImages);
            });
        }
    }];
}
+ (NSString *)getBytesFromDataLength:(NSInteger)dataLength {
    NSString *bytes;
    if (dataLength >= 0.1 * (1024 * 1024)) {
        bytes = [NSString stringWithFormat:@"%0.1fM",dataLength/1024/1024.0];
    } else if (dataLength >= 1024) {
        bytes = [NSString stringWithFormat:@"%0.0fK",dataLength/1024.0];
    } else {
        bytes = [NSString stringWithFormat:@"%zdB",dataLength];
    }
    return bytes;
}

+ (void)saveVideoToCustomAlbumWithName:(NSString *)albumName videoURL:(NSURL *)videoURL {
    if (!videoURL) {
        return;
    }
    // 判断授权状态
    [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
        if (status != PHAuthorizationStatusAuthorized) return;
        dispatch_async(dispatch_get_main_queue(), ^{
            if (!iOS9_Later) {
                if (UIVideoAtPathIsCompatibleWithSavedPhotosAlbum([videoURL path])) {
                    //保存相册核心代码
                    UISaveVideoAtPathToSavedPhotosAlbum([videoURL path], nil, nil, nil);
                }
                return;
            }
            NSError *error = nil;
            // 保存相片到相机胶卷
            __block PHObjectPlaceholder *createdAsset = nil;
            [[PHPhotoLibrary sharedPhotoLibrary] performChangesAndWait:^{
                createdAsset = [PHAssetCreationRequest creationRequestForAssetFromVideoAtFileURL:videoURL].placeholderForCreatedAsset;
            } error:&error];
            
            if (error) {
                if (HXShowLog) NSSLog(@"保存失败");
                return;
            }
            
            // 拿到自定义的相册对象
            PHAssetCollection *collection = [self createCollection:albumName];
            if (collection == nil) {
                if (HXShowLog) NSSLog(@"保存自定义相册失败");
                return;
            }
            
            [[PHPhotoLibrary sharedPhotoLibrary] performChangesAndWait:^{
                [[PHAssetCollectionChangeRequest changeRequestForAssetCollection:collection] insertAssets:@[createdAsset] atIndexes:[NSIndexSet indexSetWithIndex:0]];
            } error:&error];
            
            if (error) {
                if (HXShowLog) NSSLog(@"保存自定义相册失败");
            } else {
               if (HXShowLog)  NSSLog(@"保存成功");
            }
        });
    }];
}
+ (void)savePhotoToCustomAlbumWithName:(NSString *)albumName photo:(UIImage *)photo {
    if (!photo) {
        return;
    }
    // 判断授权状态
    [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
        if (status != PHAuthorizationStatusAuthorized) return;
        dispatch_async(dispatch_get_main_queue(), ^{
            if (!iOS9_Later) {
                UIImageWriteToSavedPhotosAlbum(photo, nil, nil, nil);
                return;
            }
            NSError *error = nil;
            // 保存相片到相机胶卷
            __block PHObjectPlaceholder *createdAsset = nil;
            [[PHPhotoLibrary sharedPhotoLibrary] performChangesAndWait:^{
                createdAsset = [PHAssetCreationRequest creationRequestForAssetFromImage:photo].placeholderForCreatedAsset;
            } error:&error];
            
            if (error) {
                if (HXShowLog) NSSLog(@"保存失败");
                return;
            }
            
            // 拿到自定义的相册对象
            PHAssetCollection *collection = [self createCollection:albumName];
            if (collection == nil) {
                if (HXShowLog) NSSLog(@"保存自定义相册失败");
                return;
            }
            
            [[PHPhotoLibrary sharedPhotoLibrary] performChangesAndWait:^{
                [[PHAssetCollectionChangeRequest changeRequestForAssetCollection:collection] insertAssets:@[createdAsset] atIndexes:[NSIndexSet indexSetWithIndex:0]];
            } error:&error];
            
            if (error) {
                if (HXShowLog) NSSLog(@"保存自定义相册失败");
            } else {
                if (HXShowLog) NSSLog(@"保存成功");
            }
        });
    }];
}
// 创建自己要创建的自定义相册
+ (PHAssetCollection * )createCollection:(NSString *)albumName {
    NSString * title = [NSBundle mainBundle].infoDictionary[(NSString *)kCFBundleNameKey];
    PHFetchResult<PHAssetCollection *> *collections =  [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeAlbum subtype:PHAssetCollectionSubtypeAlbumRegular options:nil];
    
    PHAssetCollection * createCollection = nil;
    for (PHAssetCollection * collection in collections) {
        if ([collection.localizedTitle isEqualToString:title]) {
            createCollection = collection;
            break;
        }
    }
    if (createCollection == nil) {
        
        NSError * error1 = nil;
        __block NSString * createCollectionID = nil;
        [[PHPhotoLibrary sharedPhotoLibrary] performChangesAndWait:^{
            NSString * title = [NSBundle mainBundle].infoDictionary[(NSString *)kCFBundleNameKey];
            createCollectionID = [PHAssetCollectionChangeRequest creationRequestForAssetCollectionWithTitle:title].placeholderForCreatedAssetCollection.localIdentifier;
        } error:&error1];
        
        if (error1) {
            if (HXShowLog) NSSLog(@"创建相册失败...");
            return nil;
        }
        // 创建相册之后我们还要获取此相册  因为我们要往进存储相片
        createCollection = [PHAssetCollection fetchAssetCollectionsWithLocalIdentifiers:@[createCollectionID] options:nil].firstObject;
    }
    
    return createCollection;
}
+ (CGFloat)getTextWidth:(NSString *)text height:(CGFloat)height fontSize:(CGFloat)fontSize { 
    
    return [self getTextWidth:text height:height font:[UIFont systemFontOfSize:fontSize]];
}
+ (CGFloat)getTextWidth:(NSString *)text height:(CGFloat)height font:(UIFont *)font {
    CGSize newSize = [text boundingRectWithSize:CGSizeMake(MAXFLOAT, height) options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName:font} context:nil].size;
    
    return newSize.width;
}
+ (CGFloat)getTextHeight:(NSString *)text width:(CGFloat)width fontSize:(CGFloat)fontSize {
    return [self getTextHeight:text width:width font:[UIFont systemFontOfSize:fontSize]];
}
+ (CGFloat)getTextHeight:(NSString *)text
                   width:(CGFloat)width
                    font:(UIFont *)font {
    CGSize newSize = [text boundingRectWithSize:CGSizeMake(width, MAXFLOAT) options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName : font} context:nil].size;
    
    return newSize.height;
}
+ (BOOL)isIphone6 {
    struct utsname systemInfo;
    uname(&systemInfo);
    
    NSString *platform = [NSString stringWithCString:systemInfo.machine encoding:NSASCIIStringEncoding];
    if([platform isEqualToString:@"iPhone7,2"]){//6
        return YES;
    }
    if ([platform isEqualToString:@"iPhone8,1"]) {//6s
        return YES;
    }
    if([platform isEqualToString:@"iPhone9,1"] || [platform isEqualToString:@"iPhone9,3"]) {//7
        return YES;
    }
    if([platform isEqualToString:@"iPhone10,1"] || [platform isEqualToString:@"iPhone10,4"]) {//8
        return YES;
    }
    return NO;
}

+ (BOOL)platform {
    struct utsname systemInfo;
    uname(&systemInfo);
    
    NSString *platform = [NSString stringWithCString:systemInfo.machine encoding:NSASCIIStringEncoding];
    BOOL have = NO;
    if ([platform isEqualToString:@"iPhone8,1"]) { // iphone6s
        have = YES;
    }else if ([platform isEqualToString:@"iPhone8,2"]) { // iphone6s plus
        have = YES;
    }else if ([platform isEqualToString:@"iPhone9,1"]) { // iphone7
        have = YES;
    }else if ([platform isEqualToString:@"iPhone9,2"]) { // iphone7 plus
        have = YES;
    }else if ([platform isEqualToString:@"iPhone10,1"]) { // iphone7 plus
        have = YES;
    }else if ([platform isEqualToString:@"iPhone10,2"]) { // iphone7 plus
        have = YES;
    }else if ([platform isEqualToString:@"iPhone10,3"]) { // iphone7 plus
        have = YES;
    }else if ([platform isEqualToString:@"iPhone10,4"]) { // iphone7 plus
        have = YES;
    }else if ([platform isEqualToString:@"iPhone10,5"]) { // iphone7 plus
        have = YES;
    }else if ([platform isEqualToString:@"iPhone10,6"]) { // iphone7 plus
        have = YES;
    } 
    return have;
}

+ (PHImageRequestID)getHighQualityFormatPhoto:(PHAsset *)asset size:(CGSize)size succeed:(void (^)(UIImage *image))succeed failed:(void(^)(void))failed {
    PHImageRequestOptions *option = [[PHImageRequestOptions alloc] init];
    option.deliveryMode = PHImageRequestOptionsDeliveryModeHighQualityFormat;
    option.resizeMode = PHImageRequestOptionsResizeModeFast;
    option.networkAccessAllowed = NO;
    PHImageRequestID requestID = [[PHImageManager defaultManager] requestImageForAsset:asset targetSize:size contentMode:PHImageContentModeAspectFill options:option resultHandler:^(UIImage * _Nullable result, NSDictionary * _Nullable info) {
        BOOL downloadFinined = (![[info objectForKey:PHImageCancelledKey] boolValue] && ![info objectForKey:PHImageErrorKey] && ![[info objectForKey:PHImageResultIsDegradedKey] boolValue]);
        if (downloadFinined && result) {
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                if (succeed) {
                    succeed(result);
                }
            });
        }else {
            if (failed) {
                failed();
            }
        }
    }];
    return requestID;
}

+ (PHImageRequestID)getPlayerItemWithPHAsset:(PHAsset *)asset startRequestIcloud:(void (^)(PHImageRequestID cloudRequestId))startRequestIcloud progressHandler:(void (^)(double progress))progressHandler completion:(void(^)(AVPlayerItem *playerItem))completion failed:(void(^)(NSDictionary *info))failed {
    PHVideoRequestOptions *options = [[PHVideoRequestOptions alloc] init];
    options.deliveryMode = PHVideoRequestOptionsDeliveryModeFastFormat;
    options.networkAccessAllowed = NO;
    return [[PHImageManager defaultManager] requestPlayerItemForVideo:asset options:options resultHandler:^(AVPlayerItem * _Nullable playerItem, NSDictionary * _Nullable info) {
        BOOL downloadFinined = (![[info objectForKey:PHImageCancelledKey] boolValue] && ![info objectForKey:PHImageErrorKey] && ![[info objectForKey:PHImageResultIsDegradedKey] boolValue]);
        if (downloadFinined && playerItem) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (completion) {
                    completion(playerItem);
                }
            });
        }else {
            if ([[info objectForKey:PHImageResultIsInCloudKey] boolValue]) {
                PHImageRequestID cloudRequestId = 0;
                PHVideoRequestOptions *cloudOptions = [[PHVideoRequestOptions alloc] init];
                cloudOptions.deliveryMode = PHVideoRequestOptionsDeliveryModeMediumQualityFormat;
                cloudOptions.networkAccessAllowed = YES;
                cloudOptions.progressHandler = ^(double progress, NSError * _Nullable error, BOOL * _Nonnull stop, NSDictionary * _Nullable info) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        if (progressHandler) {
                            progressHandler(progress);
                        }
                    });
                };
                cloudRequestId = [[PHImageManager defaultManager] requestPlayerItemForVideo:asset options:cloudOptions resultHandler:^(AVPlayerItem * _Nullable playerItem, NSDictionary * _Nullable info) {
                    BOOL downloadFinined = (![[info objectForKey:PHImageCancelledKey] boolValue] && ![info objectForKey:PHImageErrorKey] && ![[info objectForKey:PHImageResultIsDegradedKey] boolValue]);
                    if (downloadFinined && playerItem) {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            if (completion) {
                                completion(playerItem);
                            }
                        });
                    }else {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            if (failed) {
                                failed(info);
                            }
                        });
                    }
                }];
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (startRequestIcloud) {
                        startRequestIcloud(cloudRequestId);
                    }
                });
            }else {
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (failed) {
                        failed(info);
                    }
                });
            }
        }
    }];
}

+ (PHImageRequestID)getExportSessionWithPHAsset:(PHAsset *)phAsset deliveryMode:(PHVideoRequestOptionsDeliveryMode)deliveryMode presetName:(NSString *)presetName startRequestIcloud:(void (^)(PHImageRequestID cloudRequestId))startRequestIcloud progressHandler:(void (^)(double progress))progressHandler completion:(void(^)(AVAssetExportSession * exportSession, NSDictionary *info))completion failed:(void(^)(NSDictionary *info))failed {
//    AVAssetExportPresetHighestQuality
    PHVideoRequestOptions *options = [[PHVideoRequestOptions alloc] init];
    options.deliveryMode = deliveryMode;
    options.networkAccessAllowed = NO;
    
    return [[PHImageManager defaultManager] requestExportSessionForVideo:phAsset options:options exportPreset:presetName resultHandler:^(AVAssetExportSession * _Nullable exportSession, NSDictionary * _Nullable info) {
        // 是否成功
        BOOL downloadFinined = (![[info objectForKey:PHImageCancelledKey] boolValue] && ![info objectForKey:PHImageErrorKey] && ![[info objectForKey:PHImageResultIsDegradedKey] boolValue]);
        if (downloadFinined && exportSession) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (completion) {
                    completion(exportSession, info);
                }
            });
        }else {
            if ([[info objectForKey:PHImageResultIsInCloudKey] boolValue]) {
                PHImageRequestID iRequestId = 0;
                PHVideoRequestOptions *iOption = [[PHVideoRequestOptions alloc] init];
                iOption.deliveryMode = deliveryMode;
                iOption.networkAccessAllowed = YES;
                iOption.progressHandler = ^(double progress, NSError * _Nullable error, BOOL * _Nonnull stop, NSDictionary * _Nullable info) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        if (progressHandler) {
                            progressHandler(progress);
                        }
                    });
                };
                iRequestId = [[PHImageManager defaultManager] requestExportSessionForVideo:phAsset options:iOption exportPreset:presetName resultHandler:^(AVAssetExportSession * _Nullable exportSession, NSDictionary * _Nullable info) {
                    BOOL downloadFinined = (![[info objectForKey:PHImageCancelledKey] boolValue] && ![info objectForKey:PHImageErrorKey] && ![[info objectForKey:PHImageResultIsDegradedKey] boolValue]);
                    if (downloadFinined && exportSession) {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            if (completion) {
                                completion(exportSession, info);
                            }
                        });
                    }else {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            if (failed) {
                                failed(info);
                            }
                        });
                    }
                }];
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (startRequestIcloud) {
                        startRequestIcloud(iRequestId);
                    }
                });
            }else {
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (failed) {
                        failed(info);
                    }
                });
            }
        } 
    }];
}

+ (PHImageRequestID)getAVAssetWithPHAsset:(PHAsset *)phAsset startRequestIcloud:(void (^)(PHImageRequestID cloudRequestId))startRequestIcloud progressHandler:(void (^)(double progress))progressHandler completion:(void(^)(AVAsset *asset))completion failed:(void(^)(NSDictionary *info))failed {
    PHVideoRequestOptions *options = [[PHVideoRequestOptions alloc] init];
    options.deliveryMode = PHVideoRequestOptionsDeliveryModeFastFormat;
    options.networkAccessAllowed = NO;
    return [[PHImageManager defaultManager] requestAVAssetForVideo:phAsset options:options resultHandler:^(AVAsset * _Nullable asset, AVAudioMix * _Nullable audioMix, NSDictionary * _Nullable info) {
        BOOL downloadFinined = (![[info objectForKey:PHImageCancelledKey] boolValue] && ![info objectForKey:PHImageErrorKey] && ![[info objectForKey:PHImageResultIsDegradedKey] boolValue]);
        if (downloadFinined && asset) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (completion) {
                    completion(asset);
                }
            });
        }else {
            if ([[info objectForKey:PHImageResultIsInCloudKey] boolValue]) {
                PHImageRequestID cloudRequestId = 0;
                PHVideoRequestOptions *cloudOptions = [[PHVideoRequestOptions alloc] init];
                cloudOptions.deliveryMode = PHVideoRequestOptionsDeliveryModeMediumQualityFormat;
                cloudOptions.networkAccessAllowed = YES;
                cloudOptions.progressHandler = ^(double progress, NSError * _Nullable error, BOOL * _Nonnull stop, NSDictionary * _Nullable info) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        if (progressHandler) {
                            progressHandler(progress);
                        }
                    });
                };
                cloudRequestId = [[PHImageManager defaultManager] requestAVAssetForVideo:phAsset options:cloudOptions resultHandler:^(AVAsset * _Nullable asset, AVAudioMix * _Nullable audioMix, NSDictionary * _Nullable info) {
                    BOOL downloadFinined = (![[info objectForKey:PHImageCancelledKey] boolValue] && ![info objectForKey:PHImageErrorKey] && ![[info objectForKey:PHImageResultIsDegradedKey] boolValue]);
                    if (downloadFinined && asset) {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            if (completion) {
                                completion(asset);
                            }
                        });
                    }else {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            if (failed) {
                                failed(info);
                            }
                        });
                    }
                }];
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (startRequestIcloud) {
                        startRequestIcloud(cloudRequestId);
                    }
                });
            }else {
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (failed) {
                        failed(info);
                    }
                });
            }
        }
    }];
} 

+ (PHImageRequestID)getHighQualityFormatPhoto:(PHAsset *)asset size:(CGSize)size startRequestIcloud:(void (^)(PHImageRequestID cloudRequestId))startRequestIcloud progressHandler:(void (^)(double progress))progressHandler completion:(void(^)(UIImage *image))completion failed:(void(^)(NSDictionary *info))failed {
    PHImageRequestOptions *option = [[PHImageRequestOptions alloc] init];
    option.deliveryMode = PHImageRequestOptionsDeliveryModeHighQualityFormat;
    option.resizeMode = PHImageRequestOptionsResizeModeFast;
    option.networkAccessAllowed = NO;
    
    PHImageRequestID requestID = [[PHImageManager defaultManager] requestImageForAsset:asset targetSize:size contentMode:PHImageContentModeAspectFill options:option resultHandler:^(UIImage * _Nullable result, NSDictionary * _Nullable info) {
        
        BOOL downloadFinined = (![[info objectForKey:PHImageCancelledKey] boolValue] && ![info objectForKey:PHImageErrorKey] && ![[info objectForKey:PHImageResultIsDegradedKey] boolValue]);
        if (downloadFinined && result) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (completion) {
                    completion(result);
                }
            });
        }else { 
            if ([[info objectForKey:PHImageResultIsInCloudKey] boolValue] && ![[info objectForKey:PHImageCancelledKey] boolValue]) {
                PHImageRequestID cloudRequestId = 0;
                PHImageRequestOptions *option = [[PHImageRequestOptions alloc] init];
                option.deliveryMode = PHImageRequestOptionsDeliveryModeHighQualityFormat;
                option.resizeMode = PHImageRequestOptionsResizeModeFast;
                option.networkAccessAllowed = YES;
                option.progressHandler = ^(double progress, NSError * _Nullable error, BOOL * _Nonnull stop, NSDictionary * _Nullable info) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        if (progressHandler) {
                            progressHandler(progress);
                        }
                    });
                };
                cloudRequestId = [[PHImageManager defaultManager] requestImageForAsset:asset targetSize:size contentMode:PHImageContentModeAspectFill options:option resultHandler:^(UIImage * _Nullable result, NSDictionary * _Nullable info) {
                    BOOL downloadFinined = (![[info objectForKey:PHImageCancelledKey] boolValue] && ![info objectForKey:PHImageErrorKey] && ![[info objectForKey:PHImageResultIsDegradedKey] boolValue]);
                    if (downloadFinined && result) {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            if (completion) {
                                completion(result);
                            }
                        });
                    }else {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            if (failed) {
                                failed(info);
                            }
                        });
                    }
                }];
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (startRequestIcloud) {
                        startRequestIcloud(cloudRequestId);
                    }
                });
            }else {
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (failed) {
                        failed(info);
                    }
                }); 
            }
        }
    }];
    return requestID;
}

+ (PHImageRequestID)getImageData:(PHAsset *)asset startRequestIcloud:(void (^)(PHImageRequestID cloudRequestId))startRequestIcloud progressHandler:(void (^)(double progress))progressHandler completion:(void(^)(NSData *imageData, UIImageOrientation orientation))completion failed:(void(^)(NSDictionary *info))failed {
    
    PHImageRequestOptions *option = [[PHImageRequestOptions alloc] init];
    option.deliveryMode = PHImageRequestOptionsDeliveryModeHighQualityFormat;
    option.resizeMode = PHImageRequestOptionsResizeModeFast;
    option.networkAccessAllowed = NO;
    option.synchronous = NO;
    option.version = PHImageRequestOptionsVersionOriginal;
    
    PHImageRequestID requestID = [[PHImageManager defaultManager] requestImageDataForAsset:asset options:option resultHandler:^(NSData * _Nullable imageData, NSString * _Nullable dataUTI, UIImageOrientation orientation, NSDictionary * _Nullable info) {
        BOOL downloadFinined = (![[info objectForKey:PHImageCancelledKey] boolValue] && ![info objectForKey:PHImageErrorKey] && ![[info objectForKey:PHImageResultIsDegradedKey] boolValue]);
        if (downloadFinined && imageData) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (completion) {
                    completion(imageData, orientation);
                }
            });
        }else {
            if ([[info objectForKey:PHImageResultIsInCloudKey] boolValue] && ![[info objectForKey:PHImageCancelledKey] boolValue]) {
                PHImageRequestID cloudRequestId = 0;
                PHImageRequestOptions *option = [[PHImageRequestOptions alloc] init];
                option.deliveryMode = PHImageRequestOptionsDeliveryModeHighQualityFormat;
                option.resizeMode = PHImageRequestOptionsResizeModeFast;
                option.networkAccessAllowed = YES;
                option.version = PHImageRequestOptionsVersionOriginal;
                option.progressHandler = ^(double progress, NSError * _Nullable error, BOOL * _Nonnull stop, NSDictionary * _Nullable info) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        if (progressHandler) {
                            progressHandler(progress);
                        }
                    });
                };
                cloudRequestId = [[PHImageManager defaultManager] requestImageDataForAsset:asset options:option resultHandler:^(NSData * _Nullable imageData, NSString * _Nullable dataUTI, UIImageOrientation orientation, NSDictionary * _Nullable info) {
                    BOOL downloadFinined = (![[info objectForKey:PHImageCancelledKey] boolValue] && ![info objectForKey:PHImageErrorKey] && ![[info objectForKey:PHImageResultIsDegradedKey] boolValue]);
                    if (downloadFinined && imageData) {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            if (completion) {
                                completion(imageData, orientation);
                            }
                        });
                    }else {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            if (failed) {
                                failed(info);
                            }
                        });
                    }
                }];
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (startRequestIcloud) {
                        startRequestIcloud(cloudRequestId);
                    }
                });
            }else {
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (failed) {
                        failed(info);
                    }
                });
            }
        }
    }];
    return requestID;
}
+ (PHImageRequestID)getLivePhotoForAsset:(PHAsset *)asset size:(CGSize)size startRequestICloud:(void (^)(PHImageRequestID iCloudRequestId))startRequestICloud progressHandler:(void (^)(double progress))progressHandler completion:(void(^)(PHLivePhoto *livePhoto))completion failed:(void(^)(void))failed {
    PHLivePhotoRequestOptions *option = [[PHLivePhotoRequestOptions alloc] init];
    option.deliveryMode = PHImageRequestOptionsDeliveryModeHighQualityFormat;
    option.networkAccessAllowed = NO;
    
    return [[PHImageManager defaultManager] requestLivePhotoForAsset:asset targetSize:size contentMode:PHImageContentModeAspectFill options:option resultHandler:^(PHLivePhoto * _Nullable livePhoto, NSDictionary * _Nullable info) {
        BOOL downloadFinined = (![[info objectForKey:PHImageCancelledKey] boolValue] && ![info objectForKey:PHImageErrorKey] && ![[info objectForKey:PHImageResultIsDegradedKey] boolValue]);
        if (downloadFinined && completion && livePhoto) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(livePhoto);
            });
        }else {
            if ([[info objectForKey:PHImageResultIsInCloudKey] boolValue] && ![[info objectForKey:PHImageCancelledKey] boolValue] && ![info objectForKey:PHImageErrorKey]) {
                PHImageRequestID iCloudRequestId = 0;
                PHLivePhotoRequestOptions *iCloudOption = [[PHLivePhotoRequestOptions alloc] init];
                iCloudOption.deliveryMode = PHImageRequestOptionsDeliveryModeHighQualityFormat;
                iCloudOption.networkAccessAllowed = YES;
                iCloudOption.progressHandler = ^(double progress, NSError * _Nullable error, BOOL * _Nonnull stop, NSDictionary * _Nullable info) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        if (progressHandler) {
                            progressHandler(progress);
                        }
                    });
                };
                iCloudRequestId = [[PHImageManager defaultManager] requestLivePhotoForAsset:asset targetSize:size contentMode:PHImageContentModeAspectFill options:iCloudOption resultHandler:^(PHLivePhoto * _Nullable livePhoto, NSDictionary * _Nullable info) {
                    BOOL downloadFinined = (![[info objectForKey:PHImageCancelledKey] boolValue] && ![info objectForKey:PHImageErrorKey] && ![[info objectForKey:PHImageResultIsDegradedKey] boolValue]);
                    if (downloadFinined && livePhoto) {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            if (completion) {
                                completion(livePhoto);
                            }
                        });
                    }else {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            if (failed) {
                                failed();
                            }
                        });
                    }
                }];
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (startRequestICloud) {
                        startRequestICloud(iCloudRequestId);
                    }
                });
            }else {
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (failed) {
                        failed();
                    }
                });
            }
        }
    }];
}

/********************分割线*********************/
+ (NSString *)uploadFileName {
    NSString *fileName = @"";
    NSDate *nowDate = [NSDate date];
    NSString *dateStr = [NSString stringWithFormat:@"%ld", (long)[nowDate timeIntervalSince1970]];
    
    NSString *numStr = [NSString stringWithFormat:@"%d",arc4random()%10000];
    
    fileName = [fileName stringByAppendingString:@"hx"];
    fileName = [fileName stringByAppendingString:dateStr];
    fileName = [fileName stringByAppendingString:numStr];
    return fileName;
}
+ (void)selectListWriteToTempPath:(NSArray *)selectList requestList:(void (^)(NSArray *imageRequestIds, NSArray *videoSessions))requestList completion:(void (^)(NSArray<NSURL *> *allUrl, NSArray<NSURL *> *imageUrls, NSArray<NSURL *> *videoUrls))completion error:(void (^)(void))error {
    if (selectList.count == 0) {
        if (HXShowLog) NSSLog(@"请选择后再写入");
        if (error) {
            error();
        }
        return;
    }
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSMutableArray *allUrl = [NSMutableArray array];
        NSMutableArray *imageUrls = [NSMutableArray array];
        NSMutableArray *videoUrls = [NSMutableArray array];
        for (HXPhotoModel *photoModel in selectList) {
            if (photoModel.subType == HXPhotoModelMediaSubTypePhoto) {
                NSString *suffix;
                if (photoModel.asset) {
                    if (photoModel.type == HXPhotoModelMediaTypePhotoGif) {
                        suffix = @"gif";
                    }else if ([[photoModel.asset valueForKey:@"filename"] hasSuffix:@"JPG"]) {
                        suffix = @"jpeg";
                    }else {
                        suffix = @"png";
                    }
                }else {
                    if (!photoModel.previewPhoto) {
                        photoModel.previewPhoto = photoModel.thumbPhoto;
                    }
                    if (UIImagePNGRepresentation(photoModel.previewPhoto)) {
                        suffix = @"png";
                    }else {
                        suffix = @"jpeg";
                    }
                }
                NSString *fileName = [[self uploadFileName] stringByAppendingString:[NSString stringWithFormat:@".%@",suffix]];
                NSString *fullPathToFile = [NSTemporaryDirectory() stringByAppendingPathComponent:fileName];
                photoModel.fullPathToFile = fullPathToFile;
                [imageUrls addObject:[NSURL fileURLWithPath:fullPathToFile]];
                [allUrl addObject:[NSURL fileURLWithPath:fullPathToFile]];
            }else {
                NSString *fileName = [[self uploadFileName] stringByAppendingString:@".mp4"];
                NSString *fullPathToFile = [NSTemporaryDirectory() stringByAppendingPathComponent:fileName];
                photoModel.fullPathToFile = fullPathToFile;
                [videoUrls addObject:[NSURL fileURLWithPath:fullPathToFile]];
                [allUrl addObject:[NSURL fileURLWithPath:fullPathToFile]];
            }
        }
        __block NSInteger i = 0 ,k = 0 , j = 0;
        __block NSInteger imageCount = imageUrls.count , videoCount = videoUrls.count , count = selectList.count , requestIndex = 0;
        __block BOOL writeError = NO;
        __block NSMutableArray *requestIds = [NSMutableArray array];
        __block NSMutableArray *videoSessions = [NSMutableArray array];
        for (HXPhotoModel *photoModel in selectList) {
            if (writeError) {
                break;
            }
            if (photoModel.subType == HXPhotoModelMediaSubTypePhoto) {
                [self writeOriginalImageToTempWith:photoModel requestId:^(PHImageRequestID requestId) {
                    requestIndex++;
                    [requestIds addObject:@(requestId)];
                    if (requestIndex >= count) {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            if (requestList) {
                                requestList(requestIds,videoSessions);
                            }
                        });
                    }
                } iCloudRequestId:^(PHImageRequestID requestId) {
                    [requestIds addObject:@(requestId)];
                    if (requestIndex >= count) {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            if (requestList) {
                                requestList(requestIds,videoSessions);
                            }
                        });
                    }
                } success:^{
                    i++;
                    k++;
                    if (k == imageCount && !writeError) {
                        if (HXShowLog) NSSLog(@"图片写入成功");
                    }
                    if (i == count && !writeError) {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            if (completion) {
                                completion(allUrl,imageUrls,videoUrls);
                            }
                        });
                    }
                } failure:^{
                    if (!writeError) {
                        writeError = YES;
                        dispatch_async(dispatch_get_main_queue(), ^{
                            if (error) {
                                error();
                            }
                        });
                    }
                }];
            } else {
                __weak typeof(self) weakSelf = self;
                if (photoModel.asset) {
                    PHImageRequestID requestId = [self getAVAssetWithModel:photoModel startRequestIcloud:^(HXPhotoModel *model, PHImageRequestID cloudRequestId) {
                        [requestIds addObject:@(cloudRequestId)];
                        if (requestIndex >= count) {
                            dispatch_async(dispatch_get_main_queue(), ^{
                                if (requestList) {
                                    requestList(requestIds,videoSessions);
                                }
                            });
                        }
                    } progressHandler:^(HXPhotoModel *model, double progress) {
                        
                    } completion:^(HXPhotoModel *model, AVAsset *asset) {
                        AVAssetExportSession * session = [weakSelf compressedVideoWithMediumQualityWriteToTemp:asset pathFile:model.fullPathToFile progress:^(float progress) {
                            
                        } success:^{
                            i++;
                            j++;
                            if (j == videoCount && !writeError) {
                                if (HXShowLog) NSSLog(@"视频写入成功");
                            }
                            if (i == count && !writeError) {
                                dispatch_async(dispatch_get_main_queue(), ^{
                                    if (completion) {
                                        completion(allUrl,imageUrls,videoUrls);
                                    }
                                });
                            }
                        } failure:^{
                            if (!writeError) {
                                writeError = YES;
                                dispatch_async(dispatch_get_main_queue(), ^{
                                    if (error) {
                                        error();
                                    }
                                });
                            }
                        }];
                        requestIndex++;
                        if (session) {
                            [videoSessions addObject:session];
                        }
                        
                        if (requestIndex >= count) {
                            dispatch_async(dispatch_get_main_queue(), ^{
                                if (requestList) {
                                    requestList(requestIds,videoSessions);
                                }
                            });
                        }
                    } failed:^(HXPhotoModel *model, NSDictionary *info) {
                        if (!writeError) {
                            writeError = YES;
                            dispatch_async(dispatch_get_main_queue(), ^{
                                if (error) {
                                    error();
                                }
                            });
                        }
                    }];
                    requestIndex++;
                    [requestIds addObject:@(requestId)];
                    if (requestIndex >= count) {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            if (requestList) {
                                requestList(requestIds,videoSessions);
                            }
                        });
                    }
                }else {
                    AVAssetExportSession * session = [self compressedVideoWithMediumQualityWriteToTemp:photoModel.videoURL pathFile:photoModel.fullPathToFile progress:^(float progress) {
                        
                    } success:^{
                        i++;
                        j++;
                        if (j == videoCount && !writeError) {
                            if (HXShowLog) NSSLog(@"视频写入成功");
                        }
                        if (i == count && !writeError) {
                            dispatch_async(dispatch_get_main_queue(), ^{
                                if (completion) {
                                    completion(allUrl,imageUrls,videoUrls);
                                }
                            });
                        }
                    } failure:^{
                        if (!writeError) {
                            writeError = YES;
                            dispatch_async(dispatch_get_main_queue(), ^{
                                if (error) {
                                    error();
                                }
                            });
                        }
                    }];
                    requestIndex++;
                    if (session) {
                        [videoSessions addObject:session];
                    }
                    
                    if (requestIndex >= count) {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            if (requestList) {
                                requestList(requestIds,videoSessions);
                            }
                        });
                    }
                }
            }
        }
    });
}
+ (void)writeOriginalImageToTempWith:(HXPhotoModel *)model requestId:(void (^)(PHImageRequestID requestId))requestId iCloudRequestId:(void (^)(PHImageRequestID requestId))iCloudRequestId success:(void (^)(void))success failure:(void (^)(void))failure {
    if (model.asset) { // asset有值说明是系统相册里的照片
        if (model.type == HXPhotoModelMediaTypePhotoGif) {
            // 根据asset获取imageData
            PHImageRequestID request_Id = [self getImageData:model.asset startRequestIcloud:^(PHImageRequestID cloudRequestId) {
                if (HXShowLog) NSSLog(@"正在请求下载iCloud");
                if (iCloudRequestId) {
                    iCloudRequestId(cloudRequestId);
                }
            } progressHandler:^(double progress) {
                if (HXShowLog) NSSLog(@"iCloud下载进度 %f ",progress);
            } completion:^(NSData *imageData, UIImageOrientation orientation) {
                // 将imageData 写入临时目录
                if ([imageData writeToFile:model.fullPathToFile atomically:YES]) {
                    if (success) {
                        success();
                    }
                } else {
                    if (failure) {
                        failure();
                    }
                }
            } failed:^(NSDictionary *info) {
                if (failure) {
                    failure();
                }
            }];
            if (requestId) {
                requestId(request_Id);
            }
        }else {
            CGFloat width = [UIScreen mainScreen].bounds.size.width;
            CGFloat height = [UIScreen mainScreen].bounds.size.height;
            CGFloat imgWidth = model.imageSize.width;
            CGFloat imgHeight = model.imageSize.height;
            
            CGSize size;
            if (imgHeight > imgWidth / 9 * 17) {
                size = CGSizeMake(width, height);
            }else {
                size = CGSizeMake(model.endImageSize.width * 1.5, model.endImageSize.height * 1.5);
            }
            PHImageRequestID request_Id = [self getHighQualityFormatPhoto:model.asset size:size startRequestIcloud:^(PHImageRequestID cloudRequestId) {
                if (HXShowLog) NSSLog(@"正在请求下载iCloud");
                if (iCloudRequestId) {
                    iCloudRequestId(cloudRequestId);
                }
            } progressHandler:^(double progress) {
                if (HXShowLog) NSSLog(@"iCloud下载进度 %f ",progress);
            } completion:^(UIImage *image) {
                NSData *imageData;
                if (image.imageOrientation != UIImageOrientationUp) {
                    image = [image normalizedImage];
                }
                imageData = UIImageJPEGRepresentation(image, 1.0);
                if ([imageData writeToFile:model.fullPathToFile atomically:YES]) {
                    if (success) {
                        success();
                    }
                } else {
                    if (failure) {
                        failure();
                    }
                }
            } failed:^(NSDictionary *info) {
                if (failure) {
                    failure();
                }
            }];
            if (requestId) {
                requestId(request_Id);
            }
        }
    }else {
        NSData *imageData;
        imageData = UIImageJPEGRepresentation(model.previewPhoto, 0.8);
        if ([imageData writeToFile:model.fullPathToFile atomically:YES]) {
            if (success) {
                success();
            }
        }else {
            if (failure) {
                failure();
            }
        }
    }
}
+ (AVAssetExportSession *)compressedVideoWithMediumQualityWriteToTemp:(id)obj pathFile:(NSString *)pathFile progress:(void (^)(float progress))progress success:(void (^)(void))success failure:(void (^)(void))failure {
    AVAsset *avAsset;
    if ([obj isKindOfClass:[AVAsset class]]) {
        avAsset = (AVAsset *)obj;
    }else if ([obj isKindOfClass:[NSURL class]]){
        avAsset = [AVURLAsset URLAssetWithURL:(NSURL *)obj options:nil];
    }else {
        if (failure) {
            failure();
        }
        return nil;
    }
    NSArray *compatiblePresets = [AVAssetExportSession exportPresetsCompatibleWithAsset:avAsset];
    if ([compatiblePresets containsObject:AVAssetExportPresetHighestQuality]) {
        AVAssetExportSession *exportSession = [[AVAssetExportSession alloc] initWithAsset:avAsset presetName:AVAssetExportPresetMediumQuality];
        exportSession.outputURL = [NSURL fileURLWithPath:pathFile];
        exportSession.outputFileType = AVFileTypeMPEG4;
        exportSession.shouldOptimizeForNetworkUse = YES;
        
        [exportSession exportAsynchronouslyWithCompletionHandler:^{
            if ([exportSession status] == AVAssetExportSessionStatusCompleted) {
                if (success) {
                    success();
                }
            }else if ([exportSession status] == AVAssetExportSessionStatusFailed){
                if (failure) {
                    failure();
                }
            }else if ([exportSession status] == AVAssetExportSessionStatusCancelled) {
                if (failure) {
                    failure();
                }
            }
        }];
        return exportSession;
    }else {
        if (failure) {
            failure();
        }
        
        return nil;
    }
}
@end
