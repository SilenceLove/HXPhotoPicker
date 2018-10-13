//
//  HXPhotoTools.h
//  照片选择器
//
//  Created by 洪欣 on 17/2/8.
//  Copyright © 2017年 洪欣. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Photos/Photos.h>
#import "HXPhotoModel.h"
#import "HXAlbumModel.h"
#import "UIView+HXExtension.h"
#import "NSBundle+HXPhotoPicker.h"
#import "NSDate+HXExtension.h"
#import "UIFont+HXExtension.h"
#import <CoreLocation/CoreLocation.h>
#import "HXPhotoDefine.h"


@class HXPhotoManager;
@interface HXPhotoTools : NSObject

+ (UIImage *)hx_imageNamed:(NSString *)imageName;
 

/**
 保存本地视频到系统相册和自定义相册

 @param albumName 自定义相册名称
 @param videoURL 本地视频地址
 */
+ (void)saveVideoToCustomAlbumWithName:(NSString *)albumName
                              videoURL:(NSURL *)videoURL;

/**
 保存图片到系统相册和自定义相册

 @param albumName 自定义相册名称
 @param photo uiimage
 */
+ (void)savePhotoToCustomAlbumWithName:(NSString *)albumName
                                 photo:(UIImage *)photo;

+ (UIImage *)thumbnailImageForVideo:(NSURL *)videoURL
                             atTime:(NSTimeInterval)time;

+ (CLGeocoder *)getDateLocationDetailInformationWithModel:(HXPhotoDateModel *)model
                                               completion:(void (^)(CLPlacemark *placemark,HXPhotoDateModel *model))completion;

/**
 根据PHAsset对象获取照片信息   此方法会回调多次
 */
+ (PHImageRequestID)getPhotoForPHAsset:(PHAsset *)asset
                                  size:(CGSize)size
                            completion:(void(^)(UIImage *image,NSDictionary *info))completion;
/**
 根据PHAsset对象获取照片信息   此方法只会回调一次
 */
+ (PHImageRequestID)getHighQualityFormatPhotoForPHAsset:(PHAsset *)asset
                                                   size:(CGSize)size
                                             completion:(void (^)(UIImage *image,NSDictionary *info))completion
                                                  error:(void (^)(NSDictionary *info))error;

/**
 根据模型获取image

 @param model 模型
 @param completion 完成后的block
 @return 请求id
 */
+ (PHImageRequestID)getImageWithModel:(HXPhotoModel *)model
                           completion:(void (^)(UIImage *image, HXPhotoModel *model))completion;

/**
 根据模型获取指定大小的image
 成功回调可能会执行多次

 @param model 模型
 @param size 大小
 @param completion 完成后的block
 @return 请求id
 */
+ (PHImageRequestID)getImageWithAlbumModel:(HXAlbumModel *)model
                                      size:(CGSize)size
                                completion:(void (^)(UIImage *image, HXAlbumModel *model))completion;

/**
 根据相册模型、PHAsset获取指定大小的iamge

 @param model 相册模型
 @param asset 照片对象
 @param size 大小
 @param completion 完成后的block
 @return 请求id
 */
+ (PHImageRequestID)getImageWithAlbumModel:(HXAlbumModel *)model
                                     asset:(PHAsset *)asset
                                      size:(CGSize)size
                                completion:(void (^)(UIImage *image, HXAlbumModel *model))completion;

/**
 根据PHAsset对象获取 AVPlayerItem
 如果为iCloud上的会自动下载

 @param asset PHAsset
 @param startRequestIcloud 开始请求iCloud上的资源
 @param progressHandler iCloud下载进度
 @param completion 完成后的block
 @param failed 失败后的block
 @return 请求id
 */
+ (PHImageRequestID)getPlayerItemWithPHAsset:(PHAsset *)asset
                          startRequestIcloud:(void (^)(PHImageRequestID cloudRequestId))startRequestIcloud
                             progressHandler:(void (^)(double progress))progressHandler
                                  completion:(void (^)(AVPlayerItem *playerItem))completion
                                      failed:(void (^)(NSDictionary *info))failed;

/**
 根据PHAsset对象获取 AVAsset
 如果为iCloud上的会自动下载

 @param phAsset PHAsset
 @param startRequestIcloud 开始请求iCloud上的资源
 @param progressHandler iCloud下载进度
 @param completion 完成后的block
 @param failed 失败后的block
 @return 请求id
 */
+ (PHImageRequestID)getAVAssetWithPHAsset:(PHAsset *)phAsset
                       startRequestIcloud:(void (^)(PHImageRequestID cloudRequestId))startRequestIcloud
                          progressHandler:(void (^)(double progress))progressHandler
                               completion:(void (^)(AVAsset *asset))completion
                                   failed:(void (^)(NSDictionary *info))failed;

/**
 获取 AVAssetExportSession

 @param phAsset PHAsset对象
 @param deliveryMode PHVideoRequestOptionsDeliveryMode
 @param presetName 质量
 @param startRequestIcloud 开始请求iCloud上的资源
 @param progressHandler iCloud下载进度
 @param completion 完成后的block
 @param failed 失败后的block
 @return 请求id
 */
+ (PHImageRequestID)getExportSessionWithPHAsset:(PHAsset *)phAsset
                                   deliveryMode:(PHVideoRequestOptionsDeliveryMode)deliveryMode
                                     presetName:(NSString *)presetName
                             startRequestIcloud:(void (^)(PHImageRequestID cloudRequestId))startRequestIcloud
                                progressHandler:(void (^)(double progress))progressHandler
                                     completion:(void (^)(AVAssetExportSession * exportSession, NSDictionary *info))completion
                                         failed:(void (^)(NSDictionary *info))failed;

/**
 根据PHAsset对象获取指定大小的图片
 成功回调只会执行一次

 @param asset PHAsset
 @param size 大小
 @param succeed 成功后的回调
 @param failed 失败后的回调
 @return 请求id
 */
+ (PHImageRequestID)getHighQualityFormatPhoto:(PHAsset *)asset
                                         size:(CGSize)size
                                      succeed:(void (^)(UIImage *image))succeed
                                       failed:(void (^)(void))failed;

/**
 根据PHAsset对象获取指定大小的图片
 成功回调只会执行一次
 
 @param asset PHAsset对象
 @param size 大小
 @param startRequestIcloud 开始请求iCloud上的资源
 @param progressHandler iCloud下载进度
 @param completion 完成后的block
 @param failed 失败后的block
 @return 请求id
 */
+ (PHImageRequestID)getHighQualityFormatPhoto:(PHAsset *)asset
                                         size:(CGSize)size
                           startRequestIcloud:(void (^)(PHImageRequestID cloudRequestId))startRequestIcloud
                              progressHandler:(void (^)(double progress))progressHandler
                                   completion:(void (^)(UIImage *image))completion
                                       failed:(void (^)(NSDictionary *info))failed;

/**
 根据PHAsset获取指定大小的LivePhoto图片

 @param asset PHAsset
 @param size 大小
 @param startRequestICloud 开始请求iCloud上的资源
 @param progressHandler iCloud下载进度
 @param completion 完成后的block
 @param failed 失败后的block
 @return 请求id
 */
+ (PHImageRequestID)getLivePhotoForAsset:(PHAsset *)asset
                                    size:(CGSize)size
                      startRequestICloud:(void (^)(PHImageRequestID iCloudRequestId))startRequestICloud
                         progressHandler:(void (^)(double progress))progressHandler
                              completion:(void (^)(PHLivePhoto *livePhoto))completion
                                  failed:(void (^)(void))failed;

/**
 根据PHAsset获取imageData

 @param asset PHAsset
 @param startRequestIcloud 开始请求iCloud上的资源
 @param progressHandler iCloud下载进度
 @param completion 完成后的block
 @param failed 失败后的block
 @return 请求id
 */
+ (PHImageRequestID)getImageData:(PHAsset *)asset
              startRequestIcloud:(void (^)(PHImageRequestID cloudRequestId))startRequestIcloud
                 progressHandler:(void (^)(double progress))progressHandler
                      completion:(void (^)(NSData *imageData, UIImageOrientation orientation))completion
                          failed:(void (^)(NSDictionary *info))failed;

/**  通过模型去获取AVAsset  */
+ (PHImageRequestID)getAVAssetWithModel:(HXPhotoModel *)model
                     startRequestIcloud:(void (^)(HXPhotoModel *model, PHImageRequestID cloudRequestId))startRequestIcloud
                        progressHandler:(void (^)(HXPhotoModel *model, double progress))progressHandler
                             completion:(void (^)(HXPhotoModel *model, AVAsset *asset))completion
                                 failed:(void (^)(HXPhotoModel *model, NSDictionary *info))failed;
/**  通过模型去获取PHLivePhoto  */
+ (PHImageRequestID)getLivePhotoWithModel:(HXPhotoModel *)model
                                     size:(CGSize)size
                       startRequestICloud:(void (^)(HXPhotoModel *model, PHImageRequestID iCloudRequestId))startRequestICloud
                          progressHandler:(void (^)(HXPhotoModel *model, double progress))progressHandler
                               completion:(void (^)(HXPhotoModel *model, PHLivePhoto *livePhoto))completion
                                   failed:(void (^)(HXPhotoModel *model, NSDictionary *info))failed;
/**  通过模型去获取imageData  */
+ (PHImageRequestID)getImageDataWithModel:(HXPhotoModel *)model
                       startRequestIcloud:(void (^)(HXPhotoModel *model, PHImageRequestID cloudRequestId))startRequestIcloud
                          progressHandler:(void (^)(HXPhotoModel *model, double progress))progressHandler
                               completion:(void (^)(HXPhotoModel *model, NSData *imageData, UIImageOrientation orientation))completion
                                   failed:(void (^)(HXPhotoModel *model, NSDictionary *info))failed;

+ (PHContentEditingInputRequestID)getImagePathWithModel:(HXPhotoModel *)model
                                     startRequestIcloud:(void (^)(HXPhotoModel *model, PHContentEditingInputRequestID cloudRequestId))startRequestIcloud
                                        progressHandler:(void (^)(HXPhotoModel *model, double progress))progressHandler
                                             completion:(void (^)(HXPhotoModel *model, NSString *path))completion
                                                 failed:(void (^)(HXPhotoModel *model, NSDictionary *info))failed;

/**  -------  */

/**
 根据AVAsset对象获取指定数量和大小的图片
 (会根据视频时长平分)

 @param asset AVAsset
 @param total 总数
 @param size 图片大小
 @param complete 完成后的block
 */
+ (void)getVideoEachFrameWithAsset:(AVAsset *)asset
                             total:(NSInteger)total
                              size:(CGSize)size
                          complete:(void (^)(AVAsset *asset, NSArray<UIImage *> *images))complete;

/**
 获取视频的时长
 */
+ (NSString *)getNewTimeFromDurationSecond:(NSInteger)duration;

/**
 相册名称转换
 */
+ (NSString *)transFormPhotoTitle:(NSString *)englishName;

/**
 获取数组里面图片的大小
 */
+ (void)FetchPhotosBytes:(NSArray *)photos
              completion:(void (^)(NSString *totalBytes))completion;

/**
 获取指定字符串的宽度

 @param text 需要计算的字符串
 @param height 高度大小
 @param fontSize 字体大小
 @return 宽度大小
 */
+ (CGFloat)getTextWidth:(NSString *)text
                 height:(CGFloat)height
               fontSize:(CGFloat)fontSize;
+ (CGFloat)getTextWidth:(NSString *)text
                 height:(CGFloat)height
                   font:(UIFont *)font;
+ (CGFloat)getTextHeight:(NSString *)text
                   width:(CGFloat)width
                fontSize:(CGFloat)fontSize;
+ (CGFloat)getTextHeight:(NSString *)text
                   width:(CGFloat)width
                    font:(UIFont *)font;

+ (BOOL)platform;
/**  iphone6, 6s, 7, 8  */
+ (BOOL)isIphone6;

/**********************************/
+ (NSString *)uploadFileName;
+ (void)selectListWriteToTempPath:(NSArray *)selectList
                      requestList:(void (^)(NSArray *imageRequestIds, NSArray *videoSessions))requestList
                       completion:(void (^)(NSArray<NSURL *> *allUrl, NSArray<NSURL *> *imageUrls, NSArray<NSURL *> *videoUrls))completion
                            error:(void (^)(void))error;
@end
