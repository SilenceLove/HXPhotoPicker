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
    for (id obj in self) {
        if (![obj isKindOfClass:[HXPhotoModel class]]) {
            return NO;
        }
    }
    return YES;
}
- (void)hx_requestURLWithOriginal:(BOOL)original presetName:(NSString *)presetName completion:(void (^)(NSArray<NSURL *> * _Nullable, NSArray<HXPhotoModel *> * _Nullable))completion {
    if (![self hx_detection] || !self.count) {
        if (completion) {
            completion(nil, self);
        }
        if (HXShowLog) NSSLog(@"数组里装的不是HXPhotoModel对象或者为空");
        return;
    }
//    __block NSInteger index = 0;
//    NSInteger count = self.count;
//    __block NSMutableArray *errorArray;
    for (HXPhotoModel *model in self) {
        if (model.subType == HXPhotoModelMediaSubTypePhoto) {
            
        }else if (model.subType == HXPhotoModelMediaSubTypeVideo) {
            
//            [model exportVideoWithPresetName:presetName startRequestICloud:nil iCloudProgressHandler:nil exportProgressHandler:nil success:^(NSURL *videoURL, HXPhotoModel *model) {
//                [dict setObject:videoURL forKey:model.selectIndexStr];
//                index++;
//                if (index == count) {
//                    if (completion) {
//                        completion([NSArray hx_dictHandler:dict]);
//                    }
//                }
//            } failed:^(NSDictionary *info, HXPhotoModel *model) {
//                index++;
//                if (HXShowLog) NSSLog(@"一个获取失败!");
//                if (index == count) {
//                    if (completion) {
//                        completion([NSArray hx_dictHandler:dict]);
//                    }
//                }
//            }];
        }
    }
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
            if ([path.pathExtension isEqualToString:@"HEIC"]) {
                // 处理一下 HEIC 格式图片
                CIImage *ciImage = [CIImage imageWithContentsOfURL:[NSURL fileURLWithPath:path]];
                CIContext *context = [CIContext context];
                NSString *key = (__bridge NSString *)kCGImageDestinationLossyCompressionQuality;
                NSData *jpgData = [context JPEGRepresentationOfImage:ciImage colorSpace:ciImage.colorSpace options:@{key : @1}];
                UIImage *image = [UIImage imageWithData:jpgData];
                [dataArray addObject:image];
            }else {
                NSData *imageData = [NSData dataWithContentsOfFile:path];
                UIImage *image = [UIImage imageWithData:imageData];
//                UIImage *image = [UIImage imageWithContentsOfFile:path];
                if (image) {
                    [dataArray addObject:image];
                }
            }
        }else {
            [dataArray addObject:dict[key]];
        }
    }
    return dataArray.copy;
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
        if (model.type == HXPhotoModelMediaTypeCameraPhoto) {
            if (model.networkPhotoUrl) {
                // 网络图片
                [HXPhotoModel requestImageWithURL:model.networkPhotoUrl progress:nil completion:^(UIImage * _Nullable image, NSURL * _Nonnull url, NSError * _Nullable error) {
                    if (image) {
                        [dict setObject:image forKey:model.selectIndexStr];
                    }else {
                        if (!errorArray) errorArray = [NSMutableArray array];
                        [errorArray addObject:model];
                        if (HXShowLog) NSSLog(@"网络图片获取失败!");
                    }
                    index++;
                    if (index == count) {
                        if (completion) {
                            completion([NSArray hx_dictHandler:dict], errorArray);
                        }
                    }
                }];
            }else {
                // 本地图片
                [dict setObject:model.thumbPhoto forKey:model.selectIndexStr];
                index++;
                if (index == count) {
                    if (completion) {
                        completion([NSArray hx_dictHandler:dict], errorArray);
                    }
                }
            }
            continue;
        }else {
            if (!model.asset) {
                if (model.thumbPhoto) {
                    [dict setObject:model.thumbPhoto forKey:model.selectIndexStr];
                }else {
                    if (!errorArray) errorArray = [NSMutableArray array];
                    [errorArray addObject:model];
                }
                index++;
                if (index == count) {
                    if (completion) {
                        completion([NSArray hx_dictHandler:dict], errorArray);
                    }
                }
                continue;
            }
        }
        if (original && model.type != HXPhotoModelMediaTypeVideo) {
            // 如果选择了原图，就换一种获取方式
            [model requestImageURLStartRequestICloud:nil progressHandler:nil success:^(NSURL *imageURL, HXPhotoModel *model, NSDictionary *info) {
                [dict setObject:imageURL.relativePath forKey:model.selectIndexStr];
                index++;
                if (index == count) {
                    if (completion) {
                        completion([NSArray hx_dictHandler:dict], errorArray);
                    }
                }
            } failed:^(NSDictionary *info, HXPhotoModel *model) {
                if (!errorArray) errorArray = [NSMutableArray array];
                [errorArray addObject:model];
                index++;
                if (HXShowLog) NSSLog(@"一个获取失败!");
                if (index == count) {
                    if (completion) {
                        completion([NSArray hx_dictHandler:dict], errorArray);
                    }
                }
            }];
        }else {
            CGSize size;
            CGFloat width = [UIScreen mainScreen].bounds.size.width;
            CGFloat height = [UIScreen mainScreen].bounds.size.height;
            CGFloat imgWidth = model.imageSize.width;
            CGFloat imgHeight = model.imageSize.height;
            if (imgHeight > imgWidth / 9 * 20 ||
                imgWidth > imgHeight / 9 * 20) {
                // 处理一下长图
                size = CGSizeMake(width, height);
            }else {
                size = CGSizeMake(model.endImageSize.width * 1.5, model.endImageSize.height * 1.5);
            }
            [model requestPreviewImageWithSize:size startRequestICloud:nil progressHandler:nil success:^(UIImage *image, HXPhotoModel *model, NSDictionary *info) {
                [dict setObject:image forKey:model.selectIndexStr];
                index++;
                if (index == count) {
                    if (completion) {
                        completion([NSArray hx_dictHandler:dict], errorArray);
                    }
                }
            } failed:^(NSDictionary *info, HXPhotoModel *model) {
                if (model.previewPhoto) {
                    [dict setObject:model.previewPhoto forKey:model.selectIndexStr];
                }else {
                    if (HXShowLog) NSSLog(@"一个获取失败!");
                    if (!errorArray) errorArray = [NSMutableArray array];
                    [errorArray addObject:model];
                }
                index++;
                if (index == count) {
                    if (completion) {
                        completion([NSArray hx_dictHandler:dict], errorArray);
                    }
                }
            }];
        }
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
