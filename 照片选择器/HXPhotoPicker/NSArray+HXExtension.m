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

- (void)hx_requestImageWithOriginal:(BOOL)original completion:(void (^)(NSArray<UIImage *> * _Nullable imageArray))completion {
    if (![self hx_detection]) {
        if (completion) {
            completion(nil);
        }
        if (HXShowLog) NSSLog(@"数组里装的不是HXPhotoModel对象");
        return;
    }
    __block NSInteger index = 0;
    NSInteger count = self.count;
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    for (int i = 0 ; i < self.count; i++) {
        [dict setValue:@"" forKey:@(i + 1).stringValue];
    }
    
    for (HXPhotoModel *model in self) {
        CGSize size;
        if (original) {
            size = PHImageManagerMaximumSize;
        }else {
            CGFloat width = [UIScreen mainScreen].bounds.size.width;
            CGFloat height = [UIScreen mainScreen].bounds.size.height;
            CGFloat imgWidth = model.imageSize.width;
            CGFloat imgHeight = model.imageSize.height;
            if (imgHeight > imgWidth / 9 * 17) {
                size = CGSizeMake(width, height);
            }else {
                size = CGSizeMake(model.endImageSize.width * 1.5, model.endImageSize.height * 1.5);
            }
        }
        [model requestPreviewImageWithSize:size startRequestICloud:nil progressHandler:nil success:^(UIImage *image, HXPhotoModel *model, NSDictionary *info) {
            [dict setObject:image forKey:model.selectIndexStr];
            index++;
            if (index == count) {
                if (completion) {
                    NSMutableArray *imageArray = [NSMutableArray array];
                    NSArray *keys = [dict.allKeys sortedArrayUsingSelector:@selector(compare:)];
                    for (NSString *imageKey in keys) {
                        if ([dict[imageKey] isKindOfClass:[UIImage class]]) {
                            [imageArray addObject:dict[imageKey]];
                        }
                    }
                    completion(imageArray);
                }
            }
        } failed:^(NSDictionary *info, HXPhotoModel *model) {
            if (model.thumbPhoto) {
                [dict setObject:model.thumbPhoto forKey:model.selectIndexStr];
            }
            index++;
            if (HXShowLog) NSSLog(@"一个获取失败!");
            if (index == count) {
                if (completion) {
                    NSMutableArray *imageArray = [NSMutableArray array];
                    NSArray *keys = [dict.allKeys sortedArrayUsingSelector:@selector(compare:)];
                    for (NSString *imageKey in keys) {
                        if ([dict[imageKey] isKindOfClass:[UIImage class]]) {
                            [imageArray addObject:dict[imageKey]];
                        }
                    }
                    completion(imageArray);
                }
            }
        }];
    }
}
- (void)hx_requestImageDataWithCompletion:(void (^)(NSArray<NSData *> * _Nullable imageDataArray))completion {
    if (![self hx_detection]) {
        if (completion) {
            completion(nil);
        }
        if (HXShowLog) NSSLog(@"数组里装的不是HXPhotoModel对象");
        return;
    }
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    for (int i = 0 ; i < self.count; i++) {
        [dict setValue:@"" forKey:@(i + 1).stringValue];
    }
    __block NSInteger index = 0;
    NSInteger count = self.count;
    for (HXPhotoModel *model in self) {
        [model requestImageDataStartRequestICloud:nil progressHandler:nil success:^(NSData *imageData, UIImageOrientation orientation, HXPhotoModel *model, NSDictionary *info) {
            [dict setObject:imageData forKey:model.selectIndexStr];
            index++;
            if (index == count) {
                if (completion) {
                    NSMutableArray *imageDataArray = [NSMutableArray array];
                    NSArray *keys = [dict.allKeys sortedArrayUsingSelector:@selector(compare:)];
                    for (NSString *key in keys) {
                        if ([dict[key] isKindOfClass:[NSData class]]) {
                            [imageDataArray addObject:dict[key]];
                        }
                    }
                    completion(imageDataArray);
                }
            }
        } failed:^(NSDictionary *info, HXPhotoModel *model) {
            index++;
            if (HXShowLog) NSSLog(@"一个获取失败!");
            if (index == count) {
                if (completion) {
                    NSMutableArray *imageDataArray = [NSMutableArray array];
                    NSArray *keys = [dict.allKeys sortedArrayUsingSelector:@selector(compare:)];
                    for (NSString *key in keys) {
                        if ([dict[key] isKindOfClass:[NSData class]]) {
                            [imageDataArray addObject:dict[key]];
                        }
                    }
                    completion(imageDataArray);
                }
            }
        }];
    }
}

- (void)hx_requestAVAssetWithCompletion:(void (^)(NSArray<AVAsset *> * _Nullable assetArray))completion {
    if (![self hx_detection]) {
        if (completion) {
            completion(nil);
        }
        if (HXShowLog) NSSLog(@"数组里装的不是HXPhotoModel对象");
        return;
    }
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    for (int i = 0 ; i < self.count; i++) {
        [dict setValue:@"" forKey:@(i + 1).stringValue];
    }
    __block NSInteger index = 0;
    NSInteger count = self.count;
    for (HXPhotoModel *model in self) {
        [model requestAVAssetStartRequestICloud:nil progressHandler:nil success:^(AVAsset *avAsset, AVAudioMix *audioMix, HXPhotoModel *model, NSDictionary *info) {
            [dict setObject:avAsset forKey:model.selectIndexStr];
            index++;
            if (index == count) {
                if (completion) {
                    NSMutableArray *assetArray = [NSMutableArray array];
                    NSArray *keys = [dict.allKeys sortedArrayUsingSelector:@selector(compare:)];
                    for (NSString *key in keys) {
                        if ([dict[key] isKindOfClass:[AVAsset class]]) {
                            [assetArray addObject:dict[key]];
                        }
                    }
                    completion(assetArray);
                }
            }
        } failed:^(NSDictionary *info, HXPhotoModel *model) {
            index++;
            if (HXShowLog) NSSLog(@"一个获取失败!");
            if (index == count) {
                if (completion) {
                    NSMutableArray *assetArray = [NSMutableArray array];
                    NSArray *keys = [dict.allKeys sortedArrayUsingSelector:@selector(compare:)];
                    for (NSString *key in keys) {
                        if ([dict[key] isKindOfClass:[AVAsset class]]) {
                            [assetArray addObject:dict[key]];
                        }
                    }
                    completion(assetArray);
                }
            }
        }];
    }
}

- (void)hx_requestVideoURLWithPresetName:(NSString *)presetName completion:(void (^)(NSArray<NSURL *> * _Nullable videoURLArray))completion {
    if (![self hx_detection]) {
        if (completion) {
            completion(nil);
        }
        if (HXShowLog) NSSLog(@"数组里装的不是HXPhotoModel对象");
        return;
    }
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    for (int i = 0 ; i < self.count; i++) {
        [dict setValue:@"" forKey:@(i + 1).stringValue];
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
                    NSMutableArray *videoURLArray = [NSMutableArray array];
                    NSArray *keys = [dict.allKeys sortedArrayUsingSelector:@selector(compare:)];
                    for (NSString *key in keys) {
                        if ([dict[key] isKindOfClass:[NSURL class]]) {
                            [videoURLArray addObject:dict[key]];
                        }
                    }
                    completion(videoURLArray);
                }
            }
        } failed:^(NSDictionary *info, HXPhotoModel *model) {
            index++;
            if (HXShowLog) NSSLog(@"一个获取失败!");
            if (index == count) {
                if (completion) {
                    NSMutableArray *videoURLArray = [NSMutableArray array];
                    NSArray *keys = [dict.allKeys sortedArrayUsingSelector:@selector(compare:)];
                    for (NSString *key in keys) {
                        if ([dict[key] isKindOfClass:[NSURL class]]) {
                            [videoURLArray addObject:dict[key]];
                        }
                    }
                    completion(videoURLArray);
                }
            }
        }];
    }
}

@end
