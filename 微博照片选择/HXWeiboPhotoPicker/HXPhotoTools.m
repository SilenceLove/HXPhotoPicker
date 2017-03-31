//
//  HXPhotoTools.m
//  微博照片选择
//
//  Created by 洪欣 on 17/2/8.
//  Copyright © 2017年 洪欣. All rights reserved.
//

#import "HXPhotoTools.h"
#import "HXPhotoModel.h"
@implementation HXPhotoTools

/**
 根据PHAsset对象获取照片信息
 */
+ (PHImageRequestID)FetchPhotoForPHAsset:(PHAsset *)asset Size:(CGSize)size resizeMode:(PHImageRequestOptionsResizeMode)resizeMode completion:(void(^)(UIImage *image,NSDictionary *info))completion
{
    static PHImageRequestID requestID = -1;
    
    CGFloat scale = [UIScreen mainScreen].scale;
    CGFloat width = MIN([UIScreen mainScreen].bounds.size.width, 500);
    if (requestID >= 1 && size.width / width == scale) {
        [[PHCachingImageManager defaultManager] cancelImageRequest:requestID];
    }
    
    PHImageRequestOptions *option = [[PHImageRequestOptions alloc] init];
    option.networkAccessAllowed = YES;
    //option.deliveryMode = PHImageRequestOptionsDeliveryModeHighQualityFormat;
    option.resizeMode = resizeMode;
    
    requestID = [[PHCachingImageManager defaultManager] requestImageForAsset:asset targetSize:size contentMode:PHImageContentModeAspectFill options:option resultHandler:^(UIImage * _Nullable result, NSDictionary * _Nullable info) {
        
        BOOL downloadFinined = (![[info objectForKey:PHImageCancelledKey] boolValue] && ![info objectForKey:PHImageErrorKey]);
        
        if (downloadFinined && completion && result) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(result,info);
            });
        }
    }];
    return requestID;
}

+ (void)FetchLivePhotoForPHAsset:(PHAsset *)asset Size:(CGSize)size Completion:(void (^)(PHLivePhoto *, NSDictionary *))completion
{
    PHLivePhotoRequestOptions *option = [[PHLivePhotoRequestOptions alloc] init];
    option.version = PHImageRequestOptionsVersionCurrent;
    option.deliveryMode = PHImageRequestOptionsDeliveryModeHighQualityFormat;
    option.networkAccessAllowed = YES;
    
    [[PHCachingImageManager defaultManager] requestLivePhotoForAsset:asset targetSize:size contentMode:PHImageContentModeAspectFill options:option resultHandler:^(PHLivePhoto * _Nullable livePhoto, NSDictionary * _Nullable info) {
        BOOL downloadFinined = (![[info objectForKey:PHLivePhotoInfoCancelledKey] boolValue] && ![info objectForKey:PHLivePhotoInfoErrorKey]);
        if (downloadFinined && completion && livePhoto) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(livePhoto,info);
            });
        }
    }];
}

+ (PHImageRequestID)FetchPhotoForPHAsset:(PHAsset *)asset Size:(CGSize)size deliveryMode:(PHImageRequestOptionsDeliveryMode)deliveryMode completion:(void(^)(UIImage *image,NSDictionary *info))completion error:(void(^)(NSDictionary *info))error
{
    static PHImageRequestID requestID = -1;
    
    CGFloat scale = [UIScreen mainScreen].scale;
    CGFloat width = MIN([UIScreen mainScreen].bounds.size.width, 500);
    if (requestID >= 1 && size.width / width == scale) {
        [[PHCachingImageManager defaultManager] cancelImageRequest:requestID];
    }
    
    PHImageRequestOptions *option = [[PHImageRequestOptions alloc] init];
    option.networkAccessAllowed = YES;
    option.deliveryMode = deliveryMode;
    option.synchronous = NO;
    option.resizeMode = PHImageRequestOptionsResizeModeFast;
 
    option.progressHandler = ^(double progress, NSError *__nullable error, BOOL *stop, NSDictionary *__nullable info) {
        
    };
    
    requestID = [[PHCachingImageManager defaultManager] requestImageForAsset:asset targetSize:size contentMode:PHImageContentModeAspectFill options:option resultHandler:^(UIImage * _Nullable result, NSDictionary * _Nullable info) {
        BOOL downloadFinined = ![info objectForKey:PHImageErrorKey];
        if (downloadFinined && completion && result) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(result,info);
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

+ (PHImageRequestID)FetchPhotoDataForPHAsset:(PHAsset *)asset completion:(void (^)(NSData *, NSDictionary *))completion
{
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
                if (UIImagePNGRepresentation(model.previewPhoto)) {
                    //返回为png图像。
                    imageData = UIImagePNGRepresentation(model.previewPhoto);
                }else {
                    //返回为JPEG图像。
                    imageData = UIImageJPEGRepresentation(model.previewPhoto, 1.0);
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

+ (CGFloat)getTextWidth:(NSString *)text withHeight:(CGFloat)height fontSize:(CGFloat)fontSize
{
    CGSize newSize = [text boundingRectWithSize:CGSizeMake(MAXFLOAT, height) options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName:[UIFont systemFontOfSize:fontSize]} context:nil].size;
    
    return newSize.width;
}

+ (void)fetchOriginalForSelectedPhoto:(NSArray<HXPhotoModel *> *)photos completion:(void (^)(NSArray<UIImage *> *))completion
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        __block NSMutableArray *images = [NSMutableArray array];
        __weak typeof(self) weakSelf = self;
        [photos.copy enumerateObjectsUsingBlock:^(HXPhotoModel * _Nonnull model, NSUInteger idx, BOOL * _Nonnull stop) {
            __strong typeof(weakSelf) strongSelf = weakSelf;
            model.fetchOriginalIndex = idx;
            if (model.type == HXPhotoModelMediaTypeCameraPhoto) {
                [strongSelf sortImageForModel:model total:photos.count images:images completion:^(NSArray *array) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        if (completion) {
                            completion(array);
                        }
                    });
                }];
            }else if (model.type == HXPhotoModelMediaTypePhotoGif || model.type == HXPhotoModelMediaTypeLivePhoto) {
                [strongSelf FetchPhotoDataForPHAsset:model.asset completion:^(NSData *imageData, NSDictionary *info) {
                    model.previewPhoto = [UIImage imageWithData:imageData];
                    [strongSelf sortImageForModel:model total:photos.count images:images completion:^(NSArray *array) {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            if (completion) {
                                completion(array);
                            }
                        });
                    }];
                }];
            }else {
                [strongSelf FetchPhotoForPHAsset:model.asset Size:PHImageManagerMaximumSize deliveryMode:PHImageRequestOptionsDeliveryModeHighQualityFormat completion:^(UIImage *image, NSDictionary *info) {
                    if (![[info objectForKey:PHImageCancelledKey] boolValue]) {
                        if (!image) {
                            image = model.thumbPhoto;
                        }
                        model.previewPhoto = image;
                        [strongSelf sortImageForModel:model total:photos.count images:images completion:^(NSArray *array) {
                            dispatch_async(dispatch_get_main_queue(), ^{
                                if (completion) {
                                    completion(array);
                                }
                            });
                        }];
                    }
                } error:^(NSDictionary *info) {
                    model.previewPhoto = model.thumbPhoto;
                    [strongSelf sortImageForModel:model total:photos.count images:images completion:^(NSArray *array) {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            if (completion) {
                                completion(array);
                            }
                        });
                    }];
                }];
            }
        }];
    });
}

+ (void)fetchHDImageForSelectedPhoto:(NSArray<HXPhotoModel *> *)photos completion:(void (^)(NSArray<UIImage *> *))completion
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        __block NSMutableArray *images = [NSMutableArray array];
        __weak typeof(self) weakSelf = self;
        [photos.copy enumerateObjectsUsingBlock:^(HXPhotoModel * _Nonnull model, NSUInteger idx, BOOL * _Nonnull stop) {
            __strong typeof(weakSelf) strongSelf = weakSelf;
            model.fetchOriginalIndex = idx;
            if (model.type == HXPhotoModelMediaTypeCameraPhoto) {
                [strongSelf sortImageForModel:model total:photos.count images:images completion:^(NSArray *array) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        if (completion) {
                            completion(array);
                        }
                    });
                }];
            }else if (model.type == HXPhotoModelMediaTypePhotoGif || model.type == HXPhotoModelMediaTypeLivePhoto) {
                [strongSelf FetchPhotoDataForPHAsset:model.asset completion:^(NSData *imageData, NSDictionary *info) {
                    model.previewPhoto = [UIImage imageWithData:imageData];
                    [strongSelf sortImageForModel:model total:photos.count images:images completion:^(NSArray *array) {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            if (completion) {
                                completion(array);
                            }
                        });
                    }];
                }];
            }else {
                // 这里的size 是普通图片的时候  想要更高质量的图片 可以把 1.5 换成 2 或者 3  如果觉得内存消耗过大可以 调小一点
                CGSize size = CGSizeMake(model.endImageSize.width * 1.5, model.endImageSize.height * 1.5);
                
                // 这里是判断图片是否过长 因为图片如果长了 上面的size就显的有点小了获取出来的图片就变模糊了,所以这里把宽度 换成了屏幕的宽度,这个可以保证即不影响内存也不影响质量 如果觉得质量达不到你的要求,可以乘上 1.5 或者 2 . 当然你也可以不按我这样给size,自己测试怎么给都可以
                if (model.endImageSize.height > model.endImageSize.width / 9 * 20) {
                    size = CGSizeMake([UIScreen mainScreen].bounds.size.width, model.endImageSize.height);
                }
                [strongSelf FetchPhotoForPHAsset:model.asset Size:size deliveryMode:PHImageRequestOptionsDeliveryModeHighQualityFormat completion:^(UIImage *image, NSDictionary *info) {
                    if (![[info objectForKey:PHImageCancelledKey] boolValue]) {
                        if (!image) {
                            image = model.thumbPhoto;
                        }
                        model.previewPhoto = image;
                        [strongSelf sortImageForModel:model total:photos.count images:images completion:^(NSArray *array) {
                            dispatch_async(dispatch_get_main_queue(), ^{
                                if (completion) {
                                    completion(array);
                                }
                            });
                        }];
                    }
                } error:^(NSDictionary *info) {
                    model.previewPhoto = model.thumbPhoto;
                    [strongSelf sortImageForModel:model total:photos.count images:images completion:^(NSArray *array) {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            if (completion) {
                                completion(array);
                            }
                        });
                    }];
                }];
            }
        }];
    });
}

+ (void)sortImageForModel:(HXPhotoModel *)model total:(NSInteger)total images:(NSMutableArray *)images completion:(void(^)(NSArray *array))completion
{
    [images addObject:model];
    if (images.count == total) {
        [images sortUsingComparator:^NSComparisonResult(HXPhotoModel *temp, HXPhotoModel *other) {
            NSInteger length1 = temp.fetchOriginalIndex;
            NSInteger length2 = other.fetchOriginalIndex;
            
            NSNumber *number1 = [NSNumber numberWithInteger:length1];
            NSNumber *number2 = [NSNumber numberWithInteger:length2];
            
            NSComparisonResult result = [number1 compare:number2];
            return result == NSOrderedDescending;
        }];
        NSMutableArray *array = [NSMutableArray array];
        for (HXPhotoModel *md in images) {
            if (!md.previewPhoto) {
                continue;
            }
            [array addObject:md.previewPhoto];
        }
        [images removeAllObjects];
        if (completion) {
            completion(array);
        }
    }
}


+ (void)fetchImageDataForSelectedPhoto:(NSArray<HXPhotoModel *> *)photos completion:(void (^)(NSArray<NSData *> *))completion
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        __block NSMutableArray *imageDatas = [NSMutableArray array];
        __weak typeof(self) weakSelf= self;
        [photos.copy enumerateObjectsUsingBlock:^(HXPhotoModel * _Nonnull model, NSUInteger idx, BOOL * _Nonnull stop) {
            __strong typeof(weakSelf) strongSelf = weakSelf;
            model.fetchImageDataIndex = idx;
            if (model.type == HXPhotoModelMediaTypeCameraPhoto) {
                NSData *imageData;
                if (UIImagePNGRepresentation(model.thumbPhoto)) {
                    //返回为png图像。
                    imageData = UIImagePNGRepresentation(model.thumbPhoto);
                }else {
                    //返回为JPEG图像。
                    imageData = UIImageJPEGRepresentation(model.thumbPhoto, 1.0);
                }
                model.imageData = imageData;
                [strongSelf sortDataForModel:model total:photos.count images:imageDatas completion:^(NSArray *array) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        if (completion) {
                            completion(array);
                        }
                    });
                }];
            }else {
                [strongSelf FetchPhotoDataForPHAsset:model.asset completion:^(NSData *imageData, NSDictionary *info) {
                    model.imageData = imageData;
                    [strongSelf sortDataForModel:model total:photos.count images:imageDatas completion:^(NSArray *array) {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            if (completion) {
                                completion(array);
                            }
                        });
                    }];
                }];
            }
        }];
    });
}

+ (void)sortDataForModel:(HXPhotoModel *)model total:(NSInteger)total images:(NSMutableArray *)images completion:(void(^)(NSArray *array))completion
{
    [images addObject:model];
    if (images.count == total) {
        [images sortUsingComparator:^NSComparisonResult(HXPhotoModel *temp, HXPhotoModel *other) {
            NSInteger length1 = temp.fetchImageDataIndex;
            NSInteger length2 = other.fetchImageDataIndex;
            
            NSNumber *number1 = [NSNumber numberWithInteger:length1];
            NSNumber *number2 = [NSNumber numberWithInteger:length2];
            
            NSComparisonResult result = [number1 compare:number2];
            return result == NSOrderedDescending;
        }];
        NSMutableArray *array = [NSMutableArray array];
        for (HXPhotoModel *md in images) {
            if (!md.imageData) {
                continue;
            }
            [array addObject:md.imageData.copy];
            md.imageData = nil;
            md.previewPhoto = nil;
        }
        [images removeAllObjects];
        images = nil;
        if (completion) {
            completion(array);
        }
    }
}


@end
