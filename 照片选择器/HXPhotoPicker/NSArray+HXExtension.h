//
//  NSArray+HXExtension.h
//  照片选择器
//
//  Created by 洪欣 on 2019/1/7.
//  Copyright © 2019年 洪欣. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class AVAsset;

@interface NSArray (HXExtension)

/**
 获取image

 @param original 是否原图
 @param completion 完成回调，获取的失败不会添加到数组中
 */
- (void)hx_requestImageWithOriginal:(BOOL)original completion:(void (^)(NSArray<UIImage *> * _Nullable imageArray))completion;

/**
 获取imageData

 @param completion 完成回调，获取的失败不会添加到数组中
 */
- (void)hx_requestImageDataWithCompletion:(void (^)(NSArray<NSData *> * _Nullable imageDataArray))completion;

/**
 获取AVAsset

 @param completion 完成回调，获取的失败不会添加到数组中
 */
- (void)hx_requestAVAssetWithCompletion:(void (^)(NSArray<AVAsset *> * _Nullable assetArray))completion;

/**
 获取视频地址

 @param presetName AVAssetExportPresetHighestQuality / AVAssetExportPresetMediumQuality
 @param completion 完成回调，获取的失败不会添加到数组中
 */
- (void)hx_requestVideoURLWithPresetName:(NSString *)presetName completion:(void (^)(NSArray<NSURL *> * _Nullable videoURLArray))completion;
@end

NS_ASSUME_NONNULL_END
