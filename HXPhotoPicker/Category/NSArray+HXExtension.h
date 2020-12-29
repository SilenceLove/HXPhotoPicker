//
//  NSArray+HXExtension.h
//  HXPhotoPickerExample
//
//  Created by Silence on 2019/1/7.
//  Copyright © 2019年 Silence. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class AVAsset, HXPhotoModel;

@interface NSArray (HXExtension)

/// 获取image，同时获取
/// 如果model是视频的话,获取的则是视频封面
/// @param original 是否原图
/// @param completion imageArray 获取成功的image数组, errorArray 获取失败的model数组
- (void)hx_requestImageWithOriginal:(BOOL)original completion:(void (^)(NSArray<UIImage *> * _Nullable imageArray, NSArray<HXPhotoModel *> * _Nullable errorArray))completion;

/// 分别获取image，前面一个获取完了再去获取第二个
/// @param original 是否原图
/// @param completion imageArray 获取成功的image数组, errorArray 获取失败的model数组
- (void)hx_requestImageSeparatelyWithOriginal:(BOOL)original completion:(void (^)(NSArray<UIImage *> * _Nullable imageArray, NSArray<HXPhotoModel *> * _Nullable errorArray))completion;

/// 获取imageData
/// @param completion 获取失败的不会添加到数组中
- (void)hx_requestImageDataWithCompletion:(void (^)(NSArray<NSData *> * _Nullable imageDataArray))completion;

@end

NS_ASSUME_NONNULL_END
