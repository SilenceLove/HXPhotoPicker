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
 

+ (CLGeocoder *)getDateLocationDetailInformationWithModel:(HXPhotoDateModel *)model
                                               completion:(void (^)(CLPlacemark * _Nullable placemark, HXPhotoDateModel *model, NSError * _Nullable error))completion;

+ (void)requestAuthorization:(UIViewController *)viewController
                     handler:(void (^)(PHAuthorizationStatus status))handler;

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
 获取数组里面图片的大小
 */
+ (void)FetchPhotosBytes:(NSArray *)photos
              completion:(void (^)(NSString *totalBytes))completion;

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
