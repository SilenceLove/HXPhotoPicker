//
//  NSArray+HXExtension.h
//  照片选择器
//
//  Created by 洪欣 on 2019/1/7.
//  Copyright © 2019年 洪欣. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class AVAsset, HXPhotoModel;

@interface NSArray (HXExtension)
/**
 获取image，同时获取
 如果model是视频的话,获取的则是视频封面
 如果图片或者视频选择了获取时内存峰值过大。建议一个一个的获取,当前面一个获取完了再去获取第二个
 
 @param original 是否原图
 @param completion imageArray 获取成功的image数组, errorArray 获取失败的model数组
 */
- (void)hx_requestImageWithOriginal:(BOOL)original completion:(void (^)(NSArray<UIImage *> * _Nullable imageArray, NSArray<HXPhotoModel *> * _Nullable errorArray))completion;

/// 分别获取image，前面一个获取完了再去获取第二个
/// @param original 是否原图
/// @param completion imageArray 获取成功的image数组, errorArray 获取失败的model数组
- (void)hx_requestImageSeparatelyWithOriginal:(BOOL)original completion:(void (^)(NSArray<UIImage *> * _Nullable imageArray, NSArray<HXPhotoModel *> * _Nullable errorArray))completion;

/**
 获取imageData
 会过滤掉视频
 @param completion 完成回调，获取失败的不会添加到数组中
 */
- (void)hx_requestImageDataWithCompletion:(void (^)(NSArray<NSData *> * _Nullable imageDataArray))completion;

/**
 获取AVAsset

 @param completion 完成回调，获取失败的不会添加到数组中
 */
- (void)hx_requestAVAssetWithCompletion:(void (^)(NSArray<AVAsset *> * _Nullable assetArray))completion;

/**
 获取视频地址

 @param presetName AVAssetExportPresetHighestQuality / AVAssetExportPresetMediumQuality
 @param completion 完成回调，获取失败的不会添加到数组中
 */
- (void)hx_requestVideoURLWithPresetName:(NSString *)presetName completion:(void (^)(NSArray<NSURL *> * _Nullable videoURLArray))completion;
@end

NS_ASSUME_NONNULL_END
