//
//  HXPhotoTools.m
//  微博照片选择
//
//  Created by 洪欣 on 17/2/8.
//  Copyright © 2017年 洪欣. All rights reserved.
//

#import "HXPhotoTools.h"
#import "HXPhotoModel.h"
#import "UIImage+HXExtension.h"
#import "HXPhotoManager.h"
#import <sys/utsname.h>
@implementation HXPhotoTools

+ (UIImage *)hx_imageNamed:(NSString *)imageName {
    NSString *path = [NSString stringWithFormat:@"HXWeiboPhotoPicker.bundle/%@",imageName];
    UIImage *image = [UIImage imageNamed:path];
    if (image) {
        return image;
    } else {
        NSString *path = [NSString stringWithFormat:@"Frameworks/HXWeiboPhotoPicker.framework/HXWeiboPhotoPicker.bundle/%@",imageName];
        image = [UIImage imageNamed:path];
        if (!image) {
            image = [UIImage imageNamed:imageName];
        }
        return image;
    }
} 

+ (PHImageRequestID)getPhotoForPHAsset:(PHAsset *)asset size:(CGSize)size completion:(void(^)(UIImage *image,NSDictionary *info))completion {
    static PHImageRequestID requestID = -1;
    
    CGFloat scale = [UIScreen mainScreen].scale;
    CGFloat width = MIN([UIScreen mainScreen].bounds.size.width, 500);
    if (requestID >= 1 && size.width / width == scale) {
        [[PHCachingImageManager defaultManager] cancelImageRequest:requestID];
    }
    
    PHImageRequestOptions *option = [[PHImageRequestOptions alloc] init];
    option.resizeMode = PHImageRequestOptionsResizeModeFast;
    
    requestID = [[PHImageManager defaultManager] requestImageForAsset:asset targetSize:size contentMode:PHImageContentModeAspectFill options:option resultHandler:^(UIImage * _Nullable result, NSDictionary * _Nullable info) {
        
        BOOL downloadFinined = (![[info objectForKey:PHImageCancelledKey] boolValue] && ![info objectForKey:PHImageErrorKey]);
        
        if (downloadFinined && completion && result) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(result,info);
            });
        }
    }];
    return requestID;
}

+ (PHImageRequestID)getHighQualityFormatPhotoForPHAsset:(PHAsset *)asset size:(CGSize)size completion:(void(^)(UIImage *image,NSDictionary *info))completion error:(void(^)(NSDictionary *info))error {
    PHImageRequestOptions *option = [[PHImageRequestOptions alloc] init];
    option.deliveryMode = PHImageRequestOptionsDeliveryModeHighQualityFormat; 
    option.resizeMode = PHImageRequestOptionsResizeModeFast;
//    option.synchronous = YES;
    
    PHImageRequestID requestID = [[PHImageManager defaultManager] requestImageForAsset:asset targetSize:size contentMode:PHImageContentModeAspectFill options:option resultHandler:^(UIImage * _Nullable result, NSDictionary * _Nullable info) {
        
        BOOL downloadFinined = (![[info objectForKey:PHImageCancelledKey] boolValue] && ![info objectForKey:PHImageErrorKey] && ![[info objectForKey:PHImageResultIsDegradedKey] boolValue]);
        if (downloadFinined && result) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (completion) {
                    completion(result,info);
                }
            });
        }else {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (error) {
                    error(info);
                }
            });
        }
    }];
    return requestID;
}

+ (int32_t)fetchPhotoWithAsset:(id)asset photoSize:(CGSize)photoSize completion:(void (^)(UIImage *photo,NSDictionary *info,BOOL isDegraded))completion {
    PHImageRequestOptions *option = [[PHImageRequestOptions alloc] init];
    option.resizeMode = PHImageRequestOptionsResizeModeFast; 
    int32_t imageRequestID = [[PHImageManager defaultManager] requestImageForAsset:asset targetSize:photoSize contentMode:PHImageContentModeAspectFill options:option resultHandler:^(UIImage * _Nullable result, NSDictionary * _Nullable info) {
        BOOL downloadFinined = (![[info objectForKey:PHImageCancelledKey] boolValue] && ![info objectForKey:PHImageErrorKey]);
        if (downloadFinined && result) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (completion) completion(result,info,[[info objectForKey:PHImageResultIsDegradedKey] boolValue]);
            });
        }
    }];
    return imageRequestID;
}

+ (PHImageRequestID)FetchLivePhotoForPHAsset:(PHAsset *)asset Size:(CGSize)size Completion:(void (^)(PHLivePhoto *, NSDictionary *))completion
{
    PHLivePhotoRequestOptions *option = [[PHLivePhotoRequestOptions alloc] init];
    option.deliveryMode = PHImageRequestOptionsDeliveryModeHighQualityFormat;
    option.networkAccessAllowed = YES;
    
    return [[PHCachingImageManager defaultManager] requestLivePhotoForAsset:asset targetSize:size contentMode:PHImageContentModeAspectFill options:option resultHandler:^(PHLivePhoto * _Nullable livePhoto, NSDictionary * _Nullable info) {
        BOOL downloadFinined = (![[info objectForKey:PHLivePhotoInfoCancelledKey] boolValue] && ![info objectForKey:PHLivePhotoInfoErrorKey]);
        if (downloadFinined && completion && livePhoto) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(livePhoto,info);
            });
        }
    }];
}

+ (void)getFullSizeImageUrlFor:(HXPhotoModel *)model complete:(void (^)(NSURL *))complete {
    if (model.asset) {
        PHContentEditingInputRequestOptions *options = [[PHContentEditingInputRequestOptions alloc] init];
        options.networkAccessAllowed = YES;
//        options.canHandleAdjustmentData = ^BOOL(PHAdjustmentData * _Nonnull adjustmentData) {
//            
//            return YES;
//        };
        
        [model.asset requestContentEditingInputWithOptions:options completionHandler:^(PHContentEditingInput * _Nullable contentEditingInput, NSDictionary * _Nonnull info) {
            BOOL error = [info objectForKey:PHContentEditingInputErrorKey];
//            BOOL cloud = [[info objectForKey:PHContentEditingInputResultIsInCloudKey] boolValue];
            BOOL cancel = [[info objectForKey:PHContentEditingInputCancelledKey] boolValue];
            
            if (!error && !cancel && contentEditingInput) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (complete) {
                        complete(contentEditingInput.fullSizeImageURL);
                    }
                });
            }
        }];
    }else {
        NSData *imageData;
        NSString *suffix;
        if (UIImagePNGRepresentation(model.previewPhoto)) {
            //返回为png图像。
            imageData = UIImagePNGRepresentation(model.previewPhoto);
            suffix = @"png";
        }else {
            //返回为JPEG图像。
            imageData = UIImageJPEGRepresentation(model.previewPhoto, 1.0);
            suffix = @"jpeg";
        }
        NSString *fileName = [[self uploadFileName] stringByAppendingString:[NSString stringWithFormat:@".%@",suffix]];
        NSString *fullPathToFile = [NSTemporaryDirectory() stringByAppendingPathComponent:fileName];
        [imageData writeToFile:fullPathToFile atomically:YES];
        if (complete) {
            complete([NSURL fileURLWithPath:fullPathToFile]);
        }
    }
}

+ (PHImageRequestID)FetchPhotoForPHAsset:(PHAsset *)asset Size:(CGSize)size deliveryMode:(PHImageRequestOptionsDeliveryMode)deliveryMode completion:(void (^)(UIImage *, NSDictionary *))completion progressHandler:(void (^)(double, NSError *, BOOL *, NSDictionary *))progressHandler  {
    PHImageRequestOptions *option = [[PHImageRequestOptions alloc] init];
    option.deliveryMode = deliveryMode;
    option.resizeMode = PHImageRequestOptionsResizeModeFast;
    
    return [[PHCachingImageManager defaultManager] requestImageForAsset:asset targetSize:size contentMode:PHImageContentModeAspectFill options:option resultHandler:^(UIImage * _Nullable result, NSDictionary * _Nullable info) {
        BOOL downloadFinined = ![info objectForKey:PHImageErrorKey];
        if (downloadFinined && completion && result) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(result,info);
            });
        }
        if ([[info objectForKey:PHImageResultIsInCloudKey] boolValue] && !result) {
            PHImageRequestOptions *options = [[PHImageRequestOptions alloc] init];
            options.progressHandler = ^(double progress, NSError *error, BOOL *stop, NSDictionary *info) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (progressHandler) {
                        progressHandler(progress, error, stop, info);
                    }
                });
            };
            options.networkAccessAllowed = YES;
            options.resizeMode = PHImageRequestOptionsResizeModeFast;
            [[PHImageManager defaultManager] requestImageDataForAsset:asset options:options resultHandler:^(NSData * _Nullable imageData, NSString * _Nullable dataUTI, UIImageOrientation orientation, NSDictionary * _Nullable info) {
                UIImage *resultImage = [UIImage imageWithData:imageData scale:0.1];
                if (resultImage) {
                    completion(resultImage,info);
                }
            }];
        }
    }]; 
}

+ (PHImageRequestID)FetchPhotoDataForPHAsset:(PHAsset *)asset completion:(void (^)(NSData *, NSDictionary *))completion {
    PHImageRequestOptions *option = [[PHImageRequestOptions alloc]init];
    option.networkAccessAllowed = YES;
    return [[PHImageManager defaultManager] requestImageDataForAsset:asset options:option resultHandler:^(NSData * _Nullable imageData, NSString * _Nullable dataUTI, UIImageOrientation orientation, NSDictionary * _Nullable info) {
        if (imageData) {
            if (completion) completion(imageData,info);
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
    }else if([englishName isEqualToString:@"Recently Added"]){
        photoName = @"最近添加";
    }else if([englishName isEqualToString:@"Screenshots"]){
        photoName = @"屏幕快照";
    }else if([englishName isEqualToString:@"Camera Roll"]){
        photoName = @"相机胶卷";
    }else if([englishName isEqualToString:@"Selfies"]){
        photoName = @"自拍";
    }else if([englishName isEqualToString:@"My Photo Stream"]){
        photoName = @"我的照片流";
    }else if([englishName isEqualToString:@"Videos"]){
        photoName = @"视频";
    }else if([englishName isEqualToString:@"All Photos"]){
        photoName = @"所有照片";
    }else if([englishName isEqualToString:@"Slo-mo"]){
        photoName = @"慢动作";
    }else if([englishName isEqualToString:@"Recently Deleted"]){
        photoName = @"最近删除";
    }else if([englishName isEqualToString:@"Favorites"]){
        photoName = @"个人收藏";
    }else if([englishName isEqualToString:@"Panoramas"]){
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

+ (NSString *)maximumOfJudgment:(HXPhotoModel *)model manager:(HXPhotoManager *)manager {
    if (manager.selectedList.count == manager.maxNum) {
        // 已经达到最大选择数 [NSString stringWithFormat:@"最多只能选择%ld个",manager.maxNum]
        return [NSString stringWithFormat:[NSBundle hx_localizedStringForKey:@"最多只能选择%ld个"],manager.maxNum];
    }
    if (manager.type == HXPhotoManagerSelectedTypePhotoAndVideo) {
        if ((model.type == HXPhotoModelMediaTypePhoto || model.type == HXPhotoModelMediaTypePhotoGif) || (model.type == HXPhotoModelMediaTypeCameraPhoto || model.type == HXPhotoModelMediaTypeLivePhoto)) {
            if (manager.videoMaxNum > 0) {
                if (!manager.selectTogether) { // 是否支持图片视频同时选择
                    if (manager.selectedVideos.count > 0 ) {
                        // 已经选择了视频,不能再选图片
                        return [NSBundle hx_localizedStringForKey:@"图片不能和视频同时选择"];
                    }
                }
            }
            if (manager.selectedPhotos.count == manager.photoMaxNum) {
                // 已经达到图片最大选择数
                
                return [NSString stringWithFormat:[NSBundle hx_localizedStringForKey:@"最多只能选择%ld张图片"],manager.photoMaxNum];
            }
        }else if (model.type == HXPhotoModelMediaTypeVideo || model.type == HXPhotoModelMediaTypeCameraVideo) {
            if (manager.photoMaxNum > 0) {
                if (!manager.selectTogether) { // 是否支持图片视频同时选择
                    if (manager.selectedPhotos.count > 0 ) {
                        // 已经选择了图片,不能再选视频
                        
                        return [NSBundle hx_localizedStringForKey:@"视频不能和图片同时选择"];
                    }
                }
            }
            if (manager.selectedVideos.count == manager.videoMaxNum) {
                // 已经达到视频最大选择数
                
                return [NSString stringWithFormat:[NSBundle hx_localizedStringForKey:@"最多只能选择%ld个视频"],manager.videoMaxNum];
            }
        }
    }else if (manager.type == HXPhotoManagerSelectedTypePhoto) {
        if (manager.selectedPhotos.count == manager.photoMaxNum) {
            // 已经达到图片最大选择数
            return [NSString stringWithFormat:[NSBundle hx_localizedStringForKey:@"最多只能选择%ld张图片"],manager.photoMaxNum];
        }
    }else if (manager.type == HXPhotoManagerSelectedTypeVideo) {
        if (manager.selectedVideos.count == manager.videoMaxNum) {
            // 已经达到视频最大选择数
            return [NSString stringWithFormat:[NSBundle hx_localizedStringForKey:@"最多只能选择%ld个视频"],manager.videoMaxNum];
        }
    }
    if (model.type == HXPhotoModelMediaTypeVideo) {
        if (model.asset.duration < 3) {
            return [NSBundle hx_localizedStringForKey:@"视频少于3秒,无法选择"];
        }else if (model.asset.duration > manager.videoMaxDuration) {
            return [NSBundle hx_localizedStringForKey:@"视频过大,无法选择"];
        }
    }
    return nil;
}

+ (void)saveImageToAlbum:(UIImage *)image completion:(void(^)())completion error:(void (^)())error {
    NSError *saveError = nil;
    
    // 保存相片到相机胶卷
    __block PHObjectPlaceholder *createdAsset = nil;
    [[PHPhotoLibrary sharedPhotoLibrary] performChangesAndWait:^{
        createdAsset = [PHAssetCreationRequest creationRequestForAssetFromImage:image].placeholderForCreatedAsset;
    } error:&saveError];
    
    if (saveError) {
        if (error) {
            error();
        }
        return;
    }
    if (completion) {
        completion();
    }
}

+ (void)saveVideoToAlbum:(NSURL *)videoUrl completion:(void(^)())completion error:(void (^)())error {
    NSError *saveError = nil;
    
    // 保存相片到相机胶卷
    __block PHObjectPlaceholder *createdAsset = nil;
    [[PHPhotoLibrary sharedPhotoLibrary] performChangesAndWait:^{
        createdAsset = [PHAssetCreationRequest creationRequestForAssetFromVideoAtFileURL:videoUrl].placeholderForCreatedAsset;
    } error:&saveError];
    
    if (saveError) {
        if (error) {
            error();
        }
        return;
    }
    if (completion) {
        completion();
    }
}

+ (CGFloat)getTextWidth:(NSString *)text height:(CGFloat)height fontSize:(CGFloat)fontSize
{
    CGSize newSize = [text boundingRectWithSize:CGSizeMake(MAXFLOAT, height) options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName:[UIFont systemFontOfSize:fontSize]} context:nil].size;
    
    return newSize.width;
}
+ (CGFloat)getTextHeight:(NSString *)text width:(CGFloat)width fontSize:(CGFloat)fontSize {
    CGSize newSize = [text boundingRectWithSize:CGSizeMake(width, MAXFLOAT) options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName:[UIFont systemFontOfSize:fontSize]} context:nil].size;
    
    return newSize.height;
}
+ (void)getImageForSelectedPhoto:(NSArray<HXPhotoModel *> *)photos type:(HXPhotoToolsFetchType)type completion:(void (^)(NSArray<UIImage *> *))completion {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSMutableArray *HDImages = [NSMutableArray array];
        __weak typeof(self) weakSelf = self;
        for (HXPhotoModel *model in photos) {
            if (model.type == HXPhotoModelMediaTypeCameraPhoto) {
                [self sortImageForModel:model total:photos.count images:HDImages completion:^(NSArray *array) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        if (completion) {
                            completion(array);
                        }
                    });
                }];
            } else if (model.type == HXPhotoModelMediaTypePhotoGif) {
                [self FetchPhotoDataForPHAsset:model.asset completion:^(NSData *imageData, NSDictionary *info) {
                    UIImage *image = [UIImage animatedGIFWithData:imageData];
                    model.previewPhoto = image;
                    [weakSelf sortImageForModel:model total:photos.count images:HDImages completion:^(NSArray *array) {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            if (completion) {
                                completion(array);
                            }
                        });
                    }];
                }];
            }/*else if (model.type == HXPhotoModelMediaTypeLivePhoto) {
             // 关于livephoto 我也不知道怎么上传
            } */else {
                if (model.previewPhoto) {
                    [self sortImageForModel:model total:photos.count images:HDImages completion:^(NSArray *array) {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            if (completion) {
                                completion(array);
                            }
                        });
                    }];
                }else {
                    CGSize size;
                    if (type == HXPhotoToolsFetchHDImageType) {
                        size = CGSizeMake(model.asset.pixelWidth * 0.6, model.asset.pixelHeight * 0.6);
                    }else {
                        size = PHImageManagerMaximumSize;
                    }
                    
                    [self getHighQualityFormatPhotoForPHAsset:model.asset size:size completion:^(UIImage *image, NSDictionary *info) {
                        model.previewPhoto = image;
                        [weakSelf sortImageForModel:model total:photos.count images:HDImages completion:^(NSArray *array) {
                            dispatch_async(dispatch_get_main_queue(), ^{
                                if (completion) {
                                    completion(array);
                                }
                            });
                        }];
                    } error:^(NSDictionary *info) {
                        model.previewPhoto = model.thumbPhoto;
                        [weakSelf sortImageForModel:model total:photos.count images:HDImages completion:^(NSArray *array) {
                            dispatch_async(dispatch_get_main_queue(), ^{
                                if (completion) {
                                    completion(array);
                                }
                            });
                        }];
                    }];
                }
            }
        }
    });
}
+ (void)sortImageForModel:(HXPhotoModel *)model total:(NSInteger)total images:(NSMutableArray *)images completion:(void(^)(NSArray *array))completion {
    [images addObject:model];
    if (images.count == total) {
        [images sortUsingComparator:^NSComparisonResult(HXPhotoModel *temp, HXPhotoModel *other) {
            NSInteger length1 = temp.endIndex;
            NSInteger length2 = other.endIndex;
            
            NSNumber *number1 = [NSNumber numberWithInteger:length1];
            NSNumber *number2 = [NSNumber numberWithInteger:length2];
            
            NSComparisonResult result = [number1 compare:number2];
            return result == NSOrderedDescending;
        }];
        NSMutableArray *array = [NSMutableArray array];
        for (HXPhotoModel *md in images) {
            if (!md.previewPhoto) {
                [array addObject:md.thumbPhoto];
            }else {
                [array addObject:md.previewPhoto];
            }
        }
        [images removeAllObjects];
        if (completion) {
            completion(array);
        }
    }
}

+ (void)getSelectedPhotosFullSizeImageUrl:(NSArray<HXPhotoModel *> *)photos complete:(void (^)(NSArray<NSURL *> *))complete {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSMutableArray *urls = [NSMutableArray array];
        for (HXPhotoModel *model in photos) {
            __weak typeof(self) weakSelf = self;
            [self getFullSizeImageUrlFor:model complete:^(NSURL *url) {
                model.fullSizeImageURL = url;
                [weakSelf sortFullImageUrlForModel:model total:photos.count images:urls completion:^(NSArray *array) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        if (complete) {
                            complete(array);
                        }
                    });
                }];
            }];
        }
    });
}
+ (void)sortFullImageUrlForModel:(HXPhotoModel *)model total:(NSInteger)total images:(NSMutableArray *)images completion:(void(^)(NSArray *array))completion {
    [images addObject:model];
    if (images.count == total) {
        [images sortUsingComparator:^NSComparisonResult(HXPhotoModel *temp, HXPhotoModel *other) {
            NSInteger length1 = temp.endIndex;
            NSInteger length2 = other.endIndex;
            
            NSNumber *number1 = [NSNumber numberWithInteger:length1];
            NSNumber *number2 = [NSNumber numberWithInteger:length2];
            
            NSComparisonResult result = [number1 compare:number2];
            return result == NSOrderedDescending;
        }];
        NSMutableArray *array = [NSMutableArray array];
        for (HXPhotoModel *md in images) {
            [array addObject:md.fullSizeImageURL];
        }
        [images removeAllObjects];
        if (completion) {
            completion(array);
        }
    }
}
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
+ (void)sortResultModel:(HXPhotoResultModel *)model total:(NSInteger)total models:(NSMutableArray *)models photos:(NSMutableArray *)photos videos:(NSMutableArray *)videos completion:(void(^)(NSArray *all, NSArray *photos, NSArray *videos))completion {
    [models addObject:model];
    if (model.type == HXPhotoResultModelMediaTypePhoto) {
        [photos addObject:model];
    }else {
        [videos addObject:model];
    }
    if (models.count == total) {
        [models sortUsingComparator:^NSComparisonResult(HXPhotoResultModel *temp, HXPhotoResultModel *other) {
            NSInteger length1 = temp.index;
            NSInteger length2 = other.index;
            
            NSNumber *number1 = [NSNumber numberWithInteger:length1];
            NSNumber *number2 = [NSNumber numberWithInteger:length2];
            
            NSComparisonResult result = [number1 compare:number2];
            return result == NSOrderedDescending;
        }];
        [photos sortUsingComparator:^NSComparisonResult(HXPhotoResultModel *temp, HXPhotoResultModel *other) {
            NSInteger length1 = temp.photoIndex;
            NSInteger length2 = other.photoIndex;
            
            NSNumber *number1 = [NSNumber numberWithInteger:length1];
            NSNumber *number2 = [NSNumber numberWithInteger:length2];
            
            NSComparisonResult result = [number1 compare:number2];
            return result == NSOrderedDescending;
        }];
        [videos sortUsingComparator:^NSComparisonResult(HXPhotoResultModel *temp, HXPhotoResultModel *other) {
            NSInteger length1 = temp.videoIndex;
            NSInteger length2 = other.videoIndex;
            
            NSNumber *number1 = [NSNumber numberWithInteger:length1];
            NSNumber *number2 = [NSNumber numberWithInteger:length2];
            
            NSComparisonResult result = [number1 compare:number2];
            return result == NSOrderedDescending;
        }];
        if (completion) {
            completion(models,photos,videos);
        }
    }
}

+ (void)getSelectedListResultModel:(NSArray<HXPhotoModel *> *)selectedList complete:(void (^)(NSArray<HXPhotoResultModel *> *, NSArray<HXPhotoResultModel *> *, NSArray<HXPhotoResultModel *> *))complete {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSMutableArray *models = [NSMutableArray array];
        NSMutableArray *photos = [NSMutableArray array];
        NSMutableArray *videos = [NSMutableArray array];
        for (HXPhotoModel *photoModel in selectedList) {
            HXPhotoResultModel *resultModel = [[HXPhotoResultModel alloc] init];
            resultModel.index = photoModel.endCollectionIndex;
            if (photoModel.asset) {
                if (photoModel.subType == HXPhotoModelMediaSubTypeVideo) {
                    if ([photoModel.avAsset isKindOfClass:[AVURLAsset class]]) {
                        AVURLAsset *urlAsset = (AVURLAsset *)photoModel.avAsset;
                        resultModel.videoURL = urlAsset.URL;
                    }
                    resultModel.type = HXPhotoResultModelMediaTypeVideo;
                    resultModel.videoIndex = photoModel.videoIndex;
                }else {
                    resultModel.photoIndex = photoModel.endIndex;
                    resultModel.type = HXPhotoResultModelMediaTypePhoto;
                }
                resultModel.avAsset = photoModel.avAsset;
                PHContentEditingInputRequestOptions *options = [[PHContentEditingInputRequestOptions alloc] init];
                options.networkAccessAllowed = YES;
                __weak typeof(self) weakSelf = self;
                [photoModel.asset requestContentEditingInputWithOptions:options completionHandler:^(PHContentEditingInput * _Nullable contentEditingInput, NSDictionary * _Nonnull info) {
                    BOOL error = [info objectForKey:PHContentEditingInputErrorKey];
                    //            BOOL cloud = [[info objectForKey:PHContentEditingInputResultIsInCloudKey] boolValue];
                    BOOL cancel = [[info objectForKey:PHContentEditingInputCancelledKey] boolValue];
                    
                    if (!error && !cancel && contentEditingInput) {
                        resultModel.fullSizeImageURL = contentEditingInput.fullSizeImageURL;
                        if (resultModel.type == HXPhotoResultModelMediaTypePhoto) {
                            resultModel.displaySizeImage = contentEditingInput.displaySizeImage;
                        }else {
                            resultModel.displaySizeImage = photoModel.thumbPhoto;
                        }
                        resultModel.fullSizeImageOrientation = contentEditingInput.fullSizeImageOrientation;
                        resultModel.creationDate = contentEditingInput.creationDate;
                        resultModel.location = contentEditingInput.location;
                        if ([contentEditingInput.avAsset isKindOfClass:[AVURLAsset class]]) {
                            AVURLAsset *urlAsset = (AVURLAsset *)contentEditingInput.avAsset;
                            resultModel.videoURL = urlAsset.URL;
                            resultModel.avAsset = contentEditingInput.avAsset;
                        }
                        [weakSelf sortResultModel:resultModel total:selectedList.count models:models photos:photos videos:videos completion:^(NSArray *all, NSArray *photos, NSArray *videos) {
                            dispatch_async(dispatch_get_main_queue(), ^{
                                if (complete) {
                                    complete(all,photos,videos);
                                }
                            });
                        }];
                    }
                }];
            }else {
                resultModel.creationDate = [NSDate date];
                resultModel.displaySizeImage = photoModel.previewPhoto;
                if (photoModel.subType == HXPhotoModelMediaSubTypePhoto) {
                    resultModel.photoIndex = photoModel.endIndex;
                    resultModel.type = HXPhotoResultModelMediaTypePhoto;
                    resultModel.fullSizeImageOrientation = photoModel.previewPhoto.imageOrientation;
                    NSData *imageData;
                    NSString *suffix;
                    if (UIImagePNGRepresentation(photoModel.previewPhoto)) {
                        //返回为png图像。
                        imageData = UIImagePNGRepresentation(photoModel.previewPhoto);
                        suffix = @"png";
                    }else {
                        //返回为JPEG图像。
                        imageData = UIImageJPEGRepresentation(photoModel.previewPhoto, 1.0);
                        suffix = @"jpeg";
                    }
                    NSString *fileName = [[self uploadFileName] stringByAppendingString:[NSString stringWithFormat:@".%@",suffix]];
                    NSString *fullPathToFile = [NSTemporaryDirectory() stringByAppendingPathComponent:fileName];
                    [imageData writeToFile:fullPathToFile atomically:YES];
                    resultModel.fullSizeImageURL = [NSURL fileURLWithPath:fullPathToFile];
                }else {
                    resultModel.videoIndex = photoModel.videoIndex;
                    resultModel.type = HXPhotoResultModelMediaTypeVideo;
                    resultModel.videoURL = photoModel.videoURL;
                }
                [self sortResultModel:resultModel total:selectedList.count models:models photos:photos videos:videos completion:^(NSArray *all, NSArray *photos, NSArray *videos) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        if (complete) {
                            complete(all,photos,videos);
                        }
                    });
                }];
            }
            
        }
    });
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
    }
    return have;
}

@end
