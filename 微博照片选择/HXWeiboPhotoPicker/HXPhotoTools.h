//
//  HXPhotoTools.h
//  微博照片选择
//
//  Created by 洪欣 on 17/2/8.
//  Copyright © 2017年 洪欣. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Photos/Photos.h>
#import "HXPhotoModel.h"
/*
 *  工具类
 */

@interface HXPhotoTools : NSObject

/**
 根据已选照片数组返回原图数组

 @param photos 选中照片数组
 */
+ (void)fetchOriginalForSelectedPhoto:(NSArray<HXPhotoModel *> *)photos completion:(void(^)(NSArray<UIImage *> *images))completion;

/**
 根据已选照片数组返回高清图片数组 (质量略小于原图)

 @param photos 选中照片数组
 @param completion 高清图片数组
 */
+ (void)fetchHDImageForSelectedPhoto:(NSArray<HXPhotoModel *> *)photos completion:(void(^)(NSArray<UIImage *> *images))completion;

/**
 根据已选照片数组返回imageData数组
 
 @param photos 选中照片数组
 */
+ (void)fetchImageDataForSelectedPhoto:(NSArray<HXPhotoModel *> *)photos completion:(void(^)(NSArray<NSData *> *imageDatas))completion;


/**
 获取视频的时长
 */
+ (NSString *)getNewTimeFromDurationSecond:(NSInteger)duration;

/**
 相册名称转换
 */
+ (NSString *)transFormPhotoTitle:(NSString *)englishName;

/**
 根据PHAsset对象获取照片信息
 */
+ (PHImageRequestID)FetchPhotoForPHAsset:(PHAsset *)asset Size:(CGSize)size resizeMode:(PHImageRequestOptionsResizeMode)resizeMode completion:(void(^)(UIImage *image,NSDictionary *info))completion;

/**
 根据PHAsset对象获取LivePhoto
 */
+ (void)FetchLivePhotoForPHAsset:(PHAsset *)asset Size:(CGSize)size Completion:(void(^)(PHLivePhoto *livePhoto, NSDictionary *info))completion;

/**
 获取图片NSData

 @param asset 图片对象
 @param completion 返回结果
 */
+ (PHImageRequestID)FetchPhotoDataForPHAsset:(PHAsset *)asset completion:(void(^)(NSData *imageData, NSDictionary *info))completion;

/**
 获取数组里面图片的大小
 */
+ (void)FetchPhotosBytes:(NSArray *)photos completion:(void (^)(NSString *totalBytes))completion;

/**
 获取指定字符串的宽度

 @param text 需要计算的字符串
 @param height 高度大小
 @param fontSize 字体大小
 @return 宽度大小
 */
+ (CGFloat)getTextWidth:(NSString *)text withHeight:(CGFloat)height fontSize:(CGFloat)fontSize;

/**
 根据PHAsset对象获取照片信息 带返回错误的block
 
 @param asset 照片的PHAsset对象
 @param size 指定请求的大小
 @param deliveryMode 请求模式
 @param completion 完成后的block
 @param error 失败后的block
 */
+ (PHImageRequestID)FetchPhotoForPHAsset:(PHAsset *)asset Size:(CGSize)size deliveryMode:(PHImageRequestOptionsDeliveryMode)deliveryMode completion:(void(^)(UIImage *image,NSDictionary *info))completion error:(void(^)(NSDictionary *info))error;

@end
