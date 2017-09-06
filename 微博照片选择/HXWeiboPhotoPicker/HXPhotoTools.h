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
#import "UIView+HXExtension.h"
#import "HXPhotoResultModel.h"
#import "NSBundle+HXWeiboPhotoPicker.h"
#ifdef DEBUG
#define NSSLog(FORMAT, ...) fprintf(stderr,"%s:%d\t%s\n",[[[NSString stringWithUTF8String:__FILE__] lastPathComponent] UTF8String], __LINE__, [[NSString stringWithFormat:FORMAT, ##__VA_ARGS__] UTF8String]);

#else
#define NSSLog(...)
#endif
/*
 *  工具类
 */
typedef enum : NSUInteger {
    HXPhotoToolsFetchHDImageType = 0, // 高清
    HXPhotoToolsFetchOriginalImageTpe, // 原图
} HXPhotoToolsFetchType;

@class HXPhotoManager;
@interface HXPhotoTools : NSObject

+ (NSString *)maximumOfJudgment:(HXPhotoModel *)model manager:(HXPhotoManager *)manager;

+ (UIImage *)hx_imageNamed:(NSString *)imageName;

+ (void)saveImageToAlbum:(UIImage *)image completion:(void(^)())completion error:(void (^)())error;
+ (void)saveVideoToAlbum:(NSURL *)videoUrl completion:(void(^)())completion error:(void (^)())error;

/**
 根据PHAsset对象获取照片信息   此方法会回调多次
 */
+ (PHImageRequestID)getPhotoForPHAsset:(PHAsset *)asset size:(CGSize)size completion:(void(^)(UIImage *image,NSDictionary *info))completion;
/**
 根据PHAsset对象获取照片信息   此方法只会回调一次
 */
+ (PHImageRequestID)getHighQualityFormatPhotoForPHAsset:(PHAsset *)asset size:(CGSize)size completion:(void(^)(UIImage *image,NSDictionary *info))completion error:(void(^)(NSDictionary *info))error;


/**
 根据HXPhotoModel模型获取照片原图路径 
 
 @param model 照片模型
 @param complete 原图url
 */
+ (void)getFullSizeImageUrlFor:(HXPhotoModel *)model complete:(void (^)(NSURL *url))complete;

/**
 将HXPhotoModel模型数组转化成HXPhotoResultModel模型数组  - 已按选择顺序排序
 !!!!  必须是全部类型的那个数组  !!!!
 @param selectedList 已选的所有类型(photoAndVideo)数组
 @param complete 各个类型HXPhotoResultModel模型数组
 */
+ (void)getSelectedListResultModel:(NSArray<HXPhotoModel *> *)selectedList complete:(void (^)(NSArray<HXPhotoResultModel *> *alls, NSArray<HXPhotoResultModel *> *photos, NSArray<HXPhotoResultModel *> *videos))complete;

/**
 获取已选照片模型数组里照片原图路径  - 已按选择顺序排序

 @param photos 已选照片模型数组
 @param complete 原图路径数组
 */
+ (void)getSelectedPhotosFullSizeImageUrl:(NSArray<HXPhotoModel *> *)photos complete:(void (^)(NSArray<NSURL *> *imageUrls))complete;

/**
 根据已选照片数组返回 原图/高清(质量略小于原图) 图片数组   - 已按选择顺序排序
 
 注: 此方法只是一个简单的取image,有可能跟你的需求不一样.那么你就需要自己重新循环模型数组取数据了

 @param photos 选中照片数组
 @param completion image数组
 */
+ (void)getImageForSelectedPhoto:(NSArray<HXPhotoModel *> *)photos type:(HXPhotoToolsFetchType)type completion:(void(^)(NSArray<UIImage *> *images))completion;

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
+ (int32_t)fetchPhotoWithAsset:(id)asset photoSize:(CGSize)photoSize completion:(void (^)(UIImage *photo,NSDictionary *info,BOOL isDegraded))completion;

/**
 根据PHAsset对象获取LivePhoto
 */
+ (PHImageRequestID)FetchLivePhotoForPHAsset:(PHAsset *)asset Size:(CGSize)size Completion:(void(^)(PHLivePhoto *livePhoto, NSDictionary *info))completion;

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
+ (CGFloat)getTextWidth:(NSString *)text height:(CGFloat)height fontSize:(CGFloat)fontSize;
+ (CGFloat)getTextHeight:(NSString *)text width:(CGFloat)width fontSize:(CGFloat)fontSize;

/**
 根据PHAsset对象获取照片信息 带返回错误的block
 
 @param asset 照片的PHAsset对象
 @param size 指定请求的大小
 @param deliveryMode 请求模式
 @param completion 完成后的block
 */
+ (PHImageRequestID)FetchPhotoForPHAsset:(PHAsset *)asset Size:(CGSize)size deliveryMode:(PHImageRequestOptionsDeliveryMode)deliveryMode completion:(void(^)(UIImage *image,NSDictionary *info))completion progressHandler:(void (^)(double progress, NSError *error, BOOL *stop, NSDictionary *info))progressHandler;

+ (BOOL)platform;
@end
