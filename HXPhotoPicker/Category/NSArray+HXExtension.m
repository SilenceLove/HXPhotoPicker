//
//  NSArray+HXExtension.m
//  HXPhotoPickerExample
//
//  Created by Silence on 2019/1/7.
//  Copyright © 2019年 Silence. All rights reserved.
//

#import "NSArray+HXExtension.h"
#import "HXPhotoModel.h"
#import "HXPhotoEdit.h"
#import "HXPhotoManager.h"

@implementation NSArray (HXExtension)

- (BOOL)hx_detection {
    if (!self.count) {
        return NO;
    }
    for (id obj in self) {
        if (![obj respondsToSelector:@selector(isKindOfClass:)]) {
            return NO;
        }
        if (![obj isKindOfClass:[HXPhotoModel class]]) {
            return NO;
        }
    }
    return YES;
}
+ (NSArray *)hx_dictHandler:(NSDictionary *)dict {
    NSMutableArray *dataArray = [NSMutableArray array];
    NSArray *keys = [dict.allKeys sortedArrayUsingComparator:^NSComparisonResult(NSString * obj1, NSString * obj2) {
        if (obj1.integerValue > obj2.integerValue) {
            return NSOrderedDescending;
        }else if (obj1.integerValue < obj2.integerValue) {
            return NSOrderedAscending;
        }else {
            return NSOrderedSame;
        }
    }];
    for (NSString *key in keys) {
        if ([dict[key] isKindOfClass:[NSError class]]) {
            continue;
        }
        if ([dict[key] isKindOfClass:[NSString class]]) {
            NSString *path = dict[key];
            UIImage *image = [self hx_disposeHEICWithPath:path];
            if (image) {
                if (image.imageOrientation != UIImageOrientationUp) {
                    image = [image hx_normalizedImage];
                }
                [dataArray addObject:image];
            }
        }else {
            [dataArray addObject:dict[key]];
        }
    }
    return dataArray.copy;
}
+ (UIImage *)hx_disposeHEICWithPath:(NSString *)path {
    if ([path.pathExtension isEqualToString:@"HEIC"]) {
        // 处理一下 HEIC 格式图片
        CIImage *ciImage = [CIImage imageWithContentsOfURL:[NSURL fileURLWithPath:path]];
        CIContext *context = [CIContext context];
        NSString *key = (__bridge NSString *)kCGImageDestinationLossyCompressionQuality;
        NSData *jpgData = [context JPEGRepresentationOfImage:ciImage colorSpace:ciImage.colorSpace options:@{key : @1}];
        UIImage *image = [UIImage imageWithData:jpgData];
        if (image.imageOrientation != UIImageOrientationUp) {
            image = [image hx_normalizedImage];
        }
        return image;
    }else {
        NSData *imageData = [NSData dataWithContentsOfFile:path];
        UIImage *image = [UIImage imageWithData:imageData];
        if (!image) {
            if (image.imageOrientation != UIImageOrientationUp) {
                image = [image hx_normalizedImage];
            }
            image = [UIImage imageWithContentsOfFile:path];
        }
        return image;
    }
}
- (void)hx_requestImageWithOriginal:(BOOL)original completion:(nonnull void (^)(NSArray<UIImage *> * _Nullable, NSArray<HXPhotoModel *> * _Nullable))completion {
    if (![self hx_detection] || !self.count) {
        if (completion) {
            completion(nil, self);
        }
        if (HXShowLog) NSSLog(@"数组里装的不是HXPhotoModel对象或者为空");
        return;
    }
    NSInteger count = self.count;
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    for (int i = 0 ; i < self.count; i++) {
        HXPhotoModel *model = self[i];
        [dict setValue:[NSError errorWithDomain:@"获取失败" code:99999 userInfo:nil] forKey:model.selectIndexStr];
    }
    __block NSInteger index = 0;
    NSMutableArray *errorArray = [NSMutableArray array];
    for (HXPhotoModel *model in self) {
        [self requestImageWithOriginal:original photoModel:model successful:^(UIImage * _Nullable image, NSURL * _Nullable imagePath, HXPhotoModel *photoModel) {
            if (image) {
                // 如果photoModel 为nil可能是数组里的模型被移除了
                [dict setObject:image forKey:photoModel.selectIndexStr];
            }else if (imagePath) {
                UIImage *hImage = [NSArray hx_disposeHEICWithPath:imagePath.relativePath];
                if (hImage) {
                    photoModel.thumbPhoto = hImage;
                    photoModel.previewPhoto = hImage;
                    [dict setObject:hImage forKey:photoModel.selectIndexStr];
                }else {
                    [errorArray addObject:photoModel];
                }
            }else {
                [errorArray addObject:photoModel];
            }
            index++;
            if (index == count) {
                if (completion) {
                    completion([NSArray hx_dictHandler:dict], errorArray);
                }
            }
        } failure:^(HXPhotoModel *photoModel) {
            [errorArray addObject:photoModel];
            index++;
            if (index == count) {
                if (completion) {
                    completion([NSArray hx_dictHandler:dict], errorArray);
                }
            }
        }];
    }
}
- (void)hx_requestImageSeparatelyWithOriginal:(BOOL)original completion:(void (^)(NSArray<UIImage *> * _Nullable, NSArray<HXPhotoModel *> * _Nullable))completion {
    if (![self hx_detection] || !self.count) {
        if (completion) {
            completion(nil, self);
        }
        if (HXShowLog) NSSLog(@"数组里装的不是HXPhotoModel对象或者为空");
        return;
    }
    [self requestImageSeparatelyWithOriginal:original imageList:@[].mutableCopy photoModels:self.mutableCopy errorPhotoModels:@[].mutableCopy completion:completion];
}
- (void)requestImageSeparatelyWithOriginal:(BOOL)original
                                 imageList:(NSMutableArray *)imageList
                               photoModels:(NSMutableArray *)photoModels
                          errorPhotoModels:(NSMutableArray *)errorPhotoModels
                                completion:(void (^)(NSArray<UIImage *> * _Nullable imageArray, NSArray<HXPhotoModel *> * _Nullable errorArray))completion {
    if (!photoModels.count) {
        if (completion) {
            completion(imageList, errorPhotoModels);
        }
        return;
    }
    if (!imageList) imageList = [NSMutableArray array];
    if (!errorPhotoModels) errorPhotoModels = [NSMutableArray array];
    HXPhotoModel *model = photoModels.firstObject;
    HXWeakSelf
    [self requestImageWithOriginal:original photoModel:model successful:^(UIImage * _Nullable image, NSURL * _Nullable imagePath, HXPhotoModel *photoModel) {
        if (image) {
            photoModel.thumbPhoto = image;
            photoModel.previewPhoto = image;
            [imageList addObject:image];
        }else if (imagePath) {
            UIImage *hImage = [NSArray hx_disposeHEICWithPath:imagePath.relativePath];
            if (hImage) {
                photoModel.thumbPhoto = hImage;
                photoModel.previewPhoto = hImage;
                [imageList addObject:hImage];
            }else {
                //已知在iPhone 8，iOS 10.0.2系统上，通过requestImageDataStartRequestICloud能获取到图片的URL，但通过此URL并不能获取到image。故调用requestPreviewImageWithSize方法获取image，并存到沙盒tmp下
                [model requestPreviewImageWithSize:PHImageManagerMaximumSize startRequestICloud:^(PHImageRequestID iCloudRequestId, HXPhotoModel * _Nullable model) {
                } progressHandler:^(double progress, HXPhotoModel * _Nullable model) {
                } success:^(UIImage * _Nullable imageValue, HXPhotoModel * _Nullable model, NSDictionary * _Nullable info) {
                    NSString *photoPathStr = [NSTemporaryDirectory() stringByAppendingString:@"HXPhotoPickerSave/"];
                    BOOL isDir;
                    BOOL isDirExit = [[NSFileManager defaultManager] fileExistsAtPath:photoPathStr isDirectory:&isDir];
                    NSError *error;
                    if (isDirExit == NO) {
                        [[NSFileManager defaultManager] createDirectoryAtPath:photoPathStr withIntermediateDirectories:YES attributes:nil error:&error];
                    }
                    if (error) {
                        [errorPhotoModels addObject:photoModel];
                    }
                    else {
                        NSInteger timeStamp = [[NSDate new] timeIntervalSince1970];
                        NSString *imgPath = [NSString stringWithFormat:@"%@%zd_%zd.jpg",photoPathStr, timeStamp, photoModels.count];
                        [UIImageJPEGRepresentation(imageValue, 1.0) writeToFile:imgPath atomically:YES];
                        photoModel.imageURL = [NSURL fileURLWithPath:imgPath];
                        photoModel.thumbPhoto = imageValue;
                        photoModel.previewPhoto = imageValue;
                        [imageList addObject:imageValue];
                    }
                    
                    [photoModels removeObjectAtIndex:0];
                    if (!photoModels.count) {
                        [weakSelf requestImageSeparatelyWithOriginal:original imageList:imageList.copy photoModels:photoModels errorPhotoModels:errorPhotoModels.copy completion:completion];
                    }else {
                        [weakSelf requestImageSeparatelyWithOriginal:original imageList:imageList photoModels:photoModels errorPhotoModels:errorPhotoModels completion:completion];
                    }
                } failed:^(NSDictionary * _Nullable info, HXPhotoModel * _Nullable model) {
                    [errorPhotoModels addObject:photoModel];
                    [photoModels removeObjectAtIndex:0];
                    if (!photoModels.count) {
                        [weakSelf requestImageSeparatelyWithOriginal:original imageList:imageList.copy photoModels:photoModels errorPhotoModels:errorPhotoModels.copy completion:completion];
                    }else {
                        [weakSelf requestImageSeparatelyWithOriginal:original imageList:imageList photoModels:photoModels errorPhotoModels:errorPhotoModels completion:completion];
                    }
                }];
                
                return;
            }
        }else {
            [errorPhotoModels addObject:photoModel];
        }
        [photoModels removeObjectAtIndex:0];
        if (!photoModels.count) {
            [weakSelf requestImageSeparatelyWithOriginal:original imageList:imageList.copy photoModels:photoModels errorPhotoModels:errorPhotoModels.copy completion:completion];
        }else {
            [weakSelf requestImageSeparatelyWithOriginal:original imageList:imageList photoModels:photoModels errorPhotoModels:errorPhotoModels completion:completion];
        }
    } failure:^(HXPhotoModel *photoModel) {
        [errorPhotoModels addObject:photoModel];
        [photoModels removeObjectAtIndex:0];
        if (!photoModels.count) {
            [weakSelf requestImageSeparatelyWithOriginal:original imageList:imageList.copy photoModels:photoModels errorPhotoModels:errorPhotoModels.copy completion:completion];
        }else {
            [weakSelf requestImageSeparatelyWithOriginal:original imageList:imageList photoModels:photoModels errorPhotoModels:errorPhotoModels completion:completion];
        }
    }];
}
- (void)requestImageWithOriginal:(BOOL)original photoModel:(HXPhotoModel *)photoModel successful:(void (^)(UIImage * _Nullable image, NSURL * _Nullable imagePath, HXPhotoModel *photoModel))successful failure:(void (^)(HXPhotoModel *photoModel))failure {
    if (photoModel.photoEdit) {
        UIImage *image = photoModel.photoEdit.editPreviewImage;
        if (successful) {
            successful(image, nil, photoModel);
        }
        return;
    }
    if (photoModel.type == HXPhotoModelMediaTypeCameraPhoto) {
        if (photoModel.networkPhotoUrl) {
            if ([HXPhotoCommon photoCommon].requestNetworkAfter) {
                // 需要下载网络图片就将 [HXPhotoCommon photoCommon].requestNetworkAfter = YES
                [HXPhotoModel requestImageWithURL:photoModel.networkPhotoUrl progress:nil completion:^(UIImage * _Nullable image, NSURL * _Nullable url, NSError * _Nullable error) {
                    if (image) {
                        photoModel.thumbPhoto = image;
                        photoModel.previewPhoto = image;
                        if (successful) {
                            successful(image, nil, photoModel);
                        }
                    }else {
                        if (failure) {
                            failure(photoModel);
                        }
                        if (HXShowLog) NSSLog(@"网络图片获取失败!");
                    }
                }];
            }else {
                if (successful) {
                    successful(photoModel.thumbPhoto, nil, photoModel);
                }
            }
        }else {
            // 本地图片
            if (successful) {
                successful(photoModel.thumbPhoto, nil, photoModel);
            }
        }
        return;
    }else {
        if (!photoModel.asset) {
            if (photoModel.thumbPhoto) {
                if (successful) {
                    successful(photoModel.thumbPhoto, nil, photoModel);
                }
            }else {
                if (failure) {
                    failure(photoModel);
                }
            }
            return;
        }
    }
    if ((original && photoModel.type != HXPhotoModelMediaTypeVideo) ||
        photoModel.type == HXPhotoModelMediaTypePhotoGif) {
        // 如果选择了原图，就换一种获取方式
        [photoModel getAssetURLWithSuccess:^(NSURL * _Nullable imageURL, HXPhotoModelMediaSubType mediaType, BOOL isNetwork, HXPhotoModel * _Nullable model) {
            if (successful) {
                successful(nil, imageURL, model);
            }
        } failed:^(NSDictionary * _Nullable info, HXPhotoModel * _Nullable model) {
            if (failure) {
                failure(model);
            }
        }];
    }else {
        [photoModel requestImageDataStartRequestICloud:nil progressHandler:nil success:^(NSData * _Nullable imageData, UIImageOrientation orientation, HXPhotoModel * _Nullable model, NSDictionary * _Nullable info) {
            UIImage *image = [UIImage imageWithData:imageData];
            if (image.imageOrientation != UIImageOrientationUp) {
                image = [image hx_normalizedImage];
            }
            // 不是原图那就压缩
            if (!original) {
                image = [image hx_scaleImagetoScale:0.5f];
            }
            if (successful) {
                successful(image, nil, model);
            }
        } failed:^(NSDictionary * _Nullable info, HXPhotoModel * _Nullable model) {
            if (model.previewPhoto) {
                if (successful) {
                    successful(model.previewPhoto, nil, model);
                }
            }else {
                if (failure) {
                    failure(model);
                }
            }
        }];
    }
}

- (void)hx_requestImageDataWithCompletion:(void (^)(NSArray<NSData *> * _Nullable imageDataArray))completion {
    if (![self hx_detection] || !self.count) {
        if (completion) {
            completion(nil);
        }
        if (HXShowLog) NSSLog(@"数组里装的不是HXPhotoModel对象或者为空");
        return;
    }
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    for (int i = 0 ; i < self.count; i++) {
        HXPhotoModel *model = self[i];
        [dict setValue:[NSError errorWithDomain:@"获取失败" code:99999 userInfo:nil] forKey:model.selectIndexStr];
    }
    __block NSInteger index = 0;
    NSInteger count = self.count;
    for (HXPhotoModel *model in self) {
        if (model.subType != HXPhotoModelMediaSubTypePhoto) {
            continue;
        }
        [model requestImageDataStartRequestICloud:nil progressHandler:nil success:^(NSData *imageData, UIImageOrientation orientation, HXPhotoModel *model, NSDictionary *info) {
            if (model.asset && [HXPhotoTools assetIsHEIF:model.asset]) {
                CIImage *ciImage = [CIImage imageWithData:imageData];
                CIContext *context = [CIContext context];
                NSData *jpgData = [context JPEGRepresentationOfImage:ciImage colorSpace:ciImage.colorSpace options:@{}];
                [dict setObject:jpgData forKey:model.selectIndexStr];
            }else {
                [dict setObject:imageData forKey:model.selectIndexStr];
            }
            index++;
            if (index == count) {
                if (completion) {
                    completion([NSArray hx_dictHandler:dict]);
                }
            }
        } failed:^(NSDictionary *info, HXPhotoModel *model) {
            index++;
            if (HXShowLog) NSSLog(@"一个获取失败!");
            if (index == count) {
                if (completion) {
                    completion([NSArray hx_dictHandler:dict]);
                }
            }
        }];
    }
}

@end
