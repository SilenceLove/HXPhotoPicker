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
 获取写入临时目录的URL, 已处理gif图片和网络图片
 网络图片根据URL http || https 来判断

 @param original 是否原图
 @param presetName 导出视频时的质量
        AVAssetExportPresetHighestQuality / AVAssetExportPresetMediumQuality
        if (presetName == nil)
        original = yes  AVAssetExportPresetHighestQuality
        original = no   AVAssetExportPresetMediumQuality
 @param completion URLArray 获取成功的URL数组, errorArray 获取失败的model数组
 */
//- (void)hx_requestURLWithOriginal:(BOOL)original presetName:(NSString *)presetName completion:(void (^)(NSArray<NSURL *> * _Nullable URLArray, NSArray<HXPhotoModel *> * _Nullable errorArray))completion;

/**
 获取image
 如果model是视频的话,获取的则是视频封面

 @param original 是否原图
 @param completion imageArray 获取成功的image数组, errorArray 获取失败的model数组
 */
- (void)hx_requestImageWithOriginal:(BOOL)original completion:(void (^)(NSArray<UIImage *> * _Nullable imageArray, NSArray<HXPhotoModel *> * _Nullable errorArray))completion;

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
