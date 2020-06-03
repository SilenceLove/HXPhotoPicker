//
//  NSArray+HXExtension.m
//  照片选择器
//
//  Created by 洪欣 on 2019/1/7.
//  Copyright © 2019年 洪欣. All rights reserved.
//

#import "NSArray+HXExtension.h"
#import "HXPhotoModel.h"
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
    NSArray *keys = [dict.allKeys sortedArrayUsingSelector:@selector(compare:)];
    for (NSString *key in keys) {
        if ([dict[key] isKindOfClass:[NSError class]]) {
            continue;
        }
        if ([dict[key] isKindOfClass:[NSString class]]) {
            NSString *path = dict[key];
            UIImage *image = [self hx_disposeHEICWithPath:path];
            if (image) {
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
        return image;
    }else {
        NSData *imageData = [NSData dataWithContentsOfFile:path];
        UIImage *image = [UIImage imageWithData:imageData];
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
    __block NSMutableArray *errorArray;
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
                    if (!errorArray) errorArray = [NSMutableArray array];
                    [errorArray addObject:photoModel];
                }
            }else {
                if (!errorArray) errorArray = [NSMutableArray array];
                [errorArray addObject:photoModel];
            }
            index++;
            if (index == count) {
                if (completion) {
                    completion([NSArray hx_dictHandler:dict], errorArray);
                }
            }
        } failure:^(HXPhotoModel *photoModel) {
            if (!errorArray) errorArray = [NSMutableArray array];
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
            [imageList addObject:image];
        }else if (imagePath) {
            UIImage *hImage = [NSArray hx_disposeHEICWithPath:imagePath.relativePath];
            if (hImage) {
                photoModel.thumbPhoto = hImage;
                photoModel.previewPhoto = hImage;
                [imageList addObject:hImage];
            }else {
                [errorPhotoModels addObject:photoModel];
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
    if (photoModel.type == HXPhotoModelMediaTypeCameraPhoto) {
        if (photoModel.networkPhotoUrl) {
            if ([HXPhotoCommon photoCommon].requestNetworkAfter) {
                // 网络图片
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
//        [photoModel requestPreviewImageWithSize:PHImageManagerMaximumSize startRequestICloud:nil progressHandler:nil success:^(UIImage * _Nullable image, HXPhotoModel * _Nullable model, NSDictionary * _Nullable info) {
//            if (successful) {
//                successful(image, nil, model);
//            }
//        } failed:^(NSDictionary * _Nullable info, HXPhotoModel * _Nullable model) {
//            if (failure) {
//                failure(model);
//            }
//        }];
        [photoModel requestImageURLStartRequestICloud:nil progressHandler:nil success:^(NSURL *imageURL, HXPhotoModel *model, NSDictionary *info) {
            if (successful) {
                successful(nil, imageURL, model);
            }
        } failed:^(NSDictionary *info, HXPhotoModel *model) {
            if (failure) {
                failure(model);
            }
        }];
    }else {
        CGSize size;
        CGFloat width = [UIScreen mainScreen].bounds.size.width;
        CGFloat height = [UIScreen mainScreen].bounds.size.height;
        CGFloat imgWidth = photoModel.imageSize.width;
        CGFloat imgHeight = photoModel.imageSize.height;
        if (imgHeight > imgWidth / 9 * 20 ||
            imgWidth > imgHeight / 9 * 20) {
            // 处理一下长图
            size = CGSizeMake(width, height);
        }else {
            size = CGSizeMake(photoModel.endImageSize.width * 1.5, photoModel.endImageSize.height * 1.5);
        }
        [photoModel requestPreviewImageWithSize:size startRequestICloud:nil progressHandler:nil success:^(UIImage *image, HXPhotoModel *model, NSDictionary *info) {
            if (successful) {
                successful(image, nil, model);
            }
        } failed:^(NSDictionary *info, HXPhotoModel *model) {
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

- (void)hx_requestAVAssetWithCompletion:(void (^)(NSArray<AVAsset *> * _Nullable assetArray))completion {
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
        [model requestAVAssetStartRequestICloud:nil progressHandler:nil success:^(AVAsset *avAsset, AVAudioMix *audioMix, HXPhotoModel *model, NSDictionary *info) {
            [dict setObject:avAsset forKey:model.selectIndexStr];
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

- (void)hx_requestVideoURLWithPresetName:(NSString *)presetName completion:(void (^)(NSArray<NSURL *> * _Nullable videoURLArray))completion {
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
        // AVAssetExportPresetHighestQuality
        [model exportVideoWithPresetName:presetName startRequestICloud:nil iCloudProgressHandler:nil exportProgressHandler:nil success:^(NSURL *videoURL, HXPhotoModel *model) {
            [dict setObject:videoURL forKey:model.selectIndexStr];
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
