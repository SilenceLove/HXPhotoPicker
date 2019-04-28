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
#import "UILabel+HXExtension.h"
#import "UIFont+HXExtension.h"
#import "UIImage+HXExtension.h"
#import "NSTimer+HXExtension.h"
#import "NSString+HXExtension.h"
#import <CoreLocation/CoreLocation.h>
#import "HXPhotoDefine.h"
#import "HXPhotoCommon.h"


@class HXPhotoManager;
@interface HXPhotoTools : NSObject 

/**
 保存本地视频到系统相册和自定义相册

 @param albumName 自定义相册名称
 @param videoURL 本地视频地址
 */
+ (void)saveVideoToCustomAlbumWithName:(NSString *)albumName
                              videoURL:(NSURL *)videoURL;
+ (void)saveVideoToCustomAlbumWithName:(NSString *)albumName
                              videoURL:(NSURL *)videoURL
                              location:(CLLocation *)location
                              complete:(void (^)(HXPhotoModel *model, BOOL success))complete;

/**
 保存图片到系统相册和自定义相册

 @param albumName 自定义相册名称
 @param photo uiimage
 */
+ (void)savePhotoToCustomAlbumWithName:(NSString *)albumName
                                 photo:(UIImage *)photo;
+ (void)savePhotoToCustomAlbumWithName:(NSString *)albumName
                                 photo:(UIImage *)photo
                              location:(CLLocation *)location
                              complete:(void (^)(HXPhotoModel *model, BOOL success))complete;

/**
 获取定位信息 
 */
+ (CLGeocoder *)getDateLocationDetailInformationWithModel:(HXPhotoDateModel *)model
                                               completion:(void (^)(CLPlacemark * _Nullable placemark, HXPhotoDateModel *model, NSError * _Nullable error))completion;

/**
 请求相册权限
 */
+ (void)requestAuthorization:(UIViewController *)viewController
                     handler:(void (^)(PHAuthorizationStatus status))handler;

/**
 判断是否是HEIF格式的图片
 */
+ (BOOL)assetIsHEIF:(PHAsset *)asset;

/**
 导出裁剪的视频

 @param asset 视频AVAsset
 @param timeRange 裁剪时间区域
 @param presetName 导出的视频质量
 @param success 成功
 @param failed 失败
 */
+ (void)exportEditVideoForAVAsset:(AVAsset *)asset
                        timeRange:(CMTimeRange)timeRange
                       presetName:(NSString *)presetName
                          success:(void (^)(NSURL *videoURL))success
                           failed:(void (^)(NSError *error))failed;

/**
 获取视频的时长
 */
+ (NSString *)transformVideoTimeToString:(NSTimeInterval)duration;

/**
 获取数组里面图片的大小
 */
+ (void)FetchPhotosBytes:(NSArray *)photos
              completion:(void (^)(NSString *totalBytes))completion;
+ (NSString *)getBytesFromDataLength:(NSInteger)dataLength;

+ (BOOL)platform;
/**  iphone6, 6s, 7, 8  */
+ (BOOL)isIphone6;

+ (void)selectListWriteToTempPath:(NSArray *)selectList
                      requestList:(void (^)(NSArray *imageRequestIds, NSArray *videoSessions))requestList
                       completion:(void (^)(NSArray<NSURL *> *allUrl, NSArray<NSURL *> *imageUrls, NSArray<NSURL *> *videoUrls))completion
                            error:(void (^)(void))error DEPRECATED_MSG_ATTRIBUTE("该无效已无效' instead");
@end
