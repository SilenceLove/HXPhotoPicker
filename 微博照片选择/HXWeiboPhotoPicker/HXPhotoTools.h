//
//  HXPhotoTools.h
//  微博照片选择
//
//  Created by 洪欣 on 17/2/8.
//  Copyright © 2017年 洪欣. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Photos/Photos.h>

/*
 *  工具类
 */

@interface HXPhotoTools : NSObject

/**
 根据已选照片数组返回原图数组

 @param photos 选中照片数组
 @return 原图数组
 */
//+ (NSArray<UIImage *> *)fetchOriginalForSelectedPhoto:(NSArray *)photos;

/**
 根据已选照片数组返回imageData数组
 
 @param photos 选中照片数组
 @return imageData数组
 */
//+ (NSArray<NSData *> *)fetchImageDataForSelectedPhoto:(NSArray *)photos;


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
+ (void)FetchPhotoForPHAsset:(PHAsset *)asset Size:(CGSize)size resizeMode:(PHImageRequestOptionsResizeMode)resizeMode completion:(void(^)(UIImage *image,NSDictionary *info))completion;

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
+ (void)FetchPhotoForPHAsset:(PHAsset *)asset Size:(CGSize)size deliveryMode:(PHImageRequestOptionsDeliveryMode)deliveryMode completion:(void(^)(UIImage *image,NSDictionary *info))completion error:(void(^)(NSDictionary *info))error;

@end
