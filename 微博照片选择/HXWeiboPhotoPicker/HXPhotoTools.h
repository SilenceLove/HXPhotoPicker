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
#import "HXAlbumModel.h"
#import "UIView+HXExtension.h"
#import "NSBundle+HXWeiboPhotoPicker.h"
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
+ (void)saveVideoToCustomAlbumWithName:(NSString *)albumName videoURL:(NSURL *)videoURL;

/**
 保存图片到系统相册和自定义相册

 @param albumName 自定义相册名称
 @param photo uiimage
 */
+ (void)savePhotoToCustomAlbumWithName:(NSString *)albumName photo:(UIImage *)photo;

+ (CLGeocoder *)getDateLocationDetailInformationWithModel:(HXPhotoDateModel *)model completion:(void (^)(CLPlacemark *placemark,HXPhotoDateModel *model))completion;

/**
 根据PHAsset对象获取照片信息   此方法会回调多次
 */
+ (PHImageRequestID)getPhotoForPHAsset:(PHAsset *)asset size:(CGSize)size completion:(void(^)(UIImage *image,NSDictionary *info))completion;
/**
 根据PHAsset对象获取照片信息   此方法只会回调一次
 */
+ (PHImageRequestID)getHighQualityFormatPhotoForPHAsset:(PHAsset *)asset size:(CGSize)size completion:(void(^)(UIImage *image,NSDictionary *info))completion error:(void(^)(NSDictionary *info))error;

+ (PHImageRequestID)getImageWithModel:(HXPhotoModel *)model completion:(void (^)(UIImage *image, HXPhotoModel *model))completion;

+ (PHImageRequestID)getImageWithAlbumModel:(HXAlbumModel *)model size:(CGSize)size completion:(void (^)(UIImage *image, HXAlbumModel *model))completion;

+ (PHImageRequestID)getImageWithAlbumModel:(HXAlbumModel *)model asset:(PHAsset *)asset size:(CGSize)size completion:(void (^)(UIImage *image, HXAlbumModel *model))completion;

+ (PHImageRequestID)getPlayerItemWithPHAsset:(PHAsset *)asset startRequestIcloud:(void (^)(PHImageRequestID cloudRequestId))startRequestIcloud progressHandler:(void (^)(double progress))progressHandler completion:(void(^)(AVPlayerItem *playerItem))completion failed:(void(^)(NSDictionary *info))failed;

+ (PHImageRequestID)getAVAssetWithPHAsset:(PHAsset *)phAsset startRequestIcloud:(void (^)(PHImageRequestID cloudRequestId))startRequestIcloud progressHandler:(void (^)(double progress))progressHandler completion:(void(^)(AVAsset *asset))completion failed:(void(^)(NSDictionary *info))failed;

+ (PHImageRequestID)getHighQualityFormatPhoto:(PHAsset *)asset size:(CGSize)size succeed:(void (^)(UIImage *image))succeed failed:(void(^)())failed;

+ (PHImageRequestID)getHighQualityFormatPhoto:(PHAsset *)asset size:(CGSize)size startRequestIcloud:(void (^)(PHImageRequestID cloudRequestId))startRequestIcloud progressHandler:(void (^)(double progress))progressHandler completion:(void(^)(UIImage *image))completion failed:(void(^)(NSDictionary *info))failed;

+ (PHImageRequestID)getLivePhotoForAsset:(PHAsset *)asset size:(CGSize)size startRequestICloud:(void (^)(PHImageRequestID iCloudRequestId))startRequestICloud progressHandler:(void (^)(double progress))progressHandler completion:(void(^)(PHLivePhoto *livePhoto))completion failed:(void(^)())failed;

+ (PHImageRequestID)getImageData:(PHAsset *)asset startRequestIcloud:(void (^)(PHImageRequestID cloudRequestId))startRequestIcloud progressHandler:(void (^)(double progress))progressHandler completion:(void(^)(NSData *imageData, UIImageOrientation orientation))completion failed:(void(^)(NSDictionary *info))failed;

/**  通过模型去获取  */
+ (PHImageRequestID)getAVAssetWithModel:(HXPhotoModel *)model startRequestIcloud:(void (^)(HXPhotoModel *model, PHImageRequestID cloudRequestId))startRequestIcloud progressHandler:(void (^)(HXPhotoModel *model, double progress))progressHandler completion:(void(^)(HXPhotoModel *model, AVAsset *asset))completion failed:(void(^)(HXPhotoModel *model, NSDictionary *info))failed;

+ (PHImageRequestID)getLivePhotoWithModel:(HXPhotoModel *)model size:(CGSize)size startRequestICloud:(void (^)(HXPhotoModel *model, PHImageRequestID iCloudRequestId))startRequestICloud progressHandler:(void (^)(HXPhotoModel *model, double progress))progressHandler completion:(void(^)(HXPhotoModel *model, PHLivePhoto *livePhoto))completion failed:(void(^)(HXPhotoModel *model, NSDictionary *info))failed;

+ (PHImageRequestID)getImageDataWithModel:(HXPhotoModel *)model startRequestIcloud:(void (^)(HXPhotoModel *model, PHImageRequestID cloudRequestId))startRequestIcloud progressHandler:(void (^)(HXPhotoModel *model, double progress))progressHandler completion:(void(^)(HXPhotoModel *model, NSData *imageData, UIImageOrientation orientation))completion failed:(void(^)(HXPhotoModel *model, NSDictionary *info))failed;
/**  -------  */

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

+ (BOOL)platform;
+ (BOOL)isIphone6;

/**********************************/

+ (void)selectListWriteToTempPath:(NSArray *)selectList requestList:(void (^)(NSArray *imageRequestIds, NSArray *videoSessions))requestList completion:(void (^)(NSArray<NSURL *> *allUrl, NSArray<NSURL *> *imageUrls, NSArray<NSURL *> *videoUrls))completion error:(void (^)())error;
@end
