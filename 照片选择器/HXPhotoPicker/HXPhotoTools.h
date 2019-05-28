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
+ (void)saveVideoToCustomAlbumWithName:(NSString * _Nullable)albumName
                              videoURL:(NSURL * _Nullable)videoURL;
+ (void)saveVideoToCustomAlbumWithName:(NSString * _Nullable)albumName
                              videoURL:(NSURL * _Nullable)videoURL
                              location:(CLLocation * _Nullable)location
                              complete:(void (^ _Nullable)(HXPhotoModel * _Nullable model, BOOL success))complete;

/**
 保存图片到系统相册和自定义相册

 @param albumName 自定义相册名称
 @param photo uiimage
 */
+ (void)savePhotoToCustomAlbumWithName:(NSString * _Nullable)albumName
                                 photo:(UIImage * _Nullable)photo;
+ (void)savePhotoToCustomAlbumWithName:(NSString * _Nullable)albumName
                                 photo:(UIImage * _Nullable)photo
                              location:(CLLocation * _Nullable)location
                              complete:(void (^ _Nullable)(HXPhotoModel * _Nullable model, BOOL success))complete;

/**
 获取定位信息 
 */
+ (CLGeocoder * _Nullable)getDateLocationDetailInformationWithModel:(HXPhotoDateModel * _Nullable)model
                                               completion:(void (^ _Nullable)(CLPlacemark * _Nullable placemark, HXPhotoDateModel * _Nullable model, NSError * _Nullable error))completion;

/**
 请求相册权限
 */
+ (void)requestAuthorization:(UIViewController * _Nullable)viewController
                     handler:(void (^ _Nullable)(PHAuthorizationStatus status))handler;

/**
 判断是否是HEIF格式的图片
 */
+ (BOOL)assetIsHEIF:(PHAsset * _Nullable)asset;

/**
 导出裁剪的视频

 @param asset 视频AVAsset
 @param timeRange 裁剪时间区域
 @param presetName 导出的视频质量
 @param success 成功
 @param failed 失败
 */
+ (void)exportEditVideoForAVAsset:(AVAsset * _Nullable)asset
                        timeRange:(CMTimeRange)timeRange
                       presetName:(NSString * _Nullable)presetName
                          success:(void (^ _Nullable)(NSURL * _Nullable videoURL))success
                           failed:(void (^ _Nullable)(NSError * _Nullable error))failed;

/**
 获取视频的时长
 */
+ (NSString * _Nullable)transformVideoTimeToString:(NSTimeInterval)duration;

/**
 获取数组里面图片的大小
 */
+ (void)FetchPhotosBytes:(NSArray * _Nullable)photos
              completion:(void (^ _Nullable)(NSString * _Nullable totalBytes))completion;
+ (NSString * _Nullable)getBytesFromDataLength:(NSInteger)dataLength;

+ (BOOL)platform;
/**  iphone6, 6s, 7, 8  */
+ (BOOL)isIphone6;

+ (void)selectListWriteToTempPath:(NSArray * _Nullable)selectList
                      requestList:(void (^ _Nullable)(NSArray * _Nullable imageRequestIds, NSArray * _Nullable videoSessions))requestList
                       completion:(void (^ _Nullable)(NSArray<NSURL *> * _Nullable allUrl, NSArray<NSURL *> * _Nullable imageUrls, NSArray<NSURL *> * _Nullable videoUrls))completion
                            error:(void (^ _Nullable)(void))error DEPRECATED_MSG_ATTRIBUTE("该无效已无效' instead");
@end
