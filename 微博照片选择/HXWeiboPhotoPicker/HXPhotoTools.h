//
//  HXPhotoTools.h
//  微博照片选择
//
//  Created by 洪欣 on 17/2/8.
//  Copyright © 2017年 洪欣. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Photos/Photos.h>
@interface HXPhotoTools : NSObject
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
 获取图片NSData

 @param asset 图片对象
 @param completion 返回结果
 */
+ (void)FetchPhotoDataForPHAsset:(PHAsset *)asset completion:(void(^)(NSData *imageData, NSDictionary *info))completion;

/**
 获取数组里面图片的大小
 */
+ (void)FetchPhotosBytes:(NSArray *)photos completion:(void (^)(NSString *totalBytes))completion;

+ (CGFloat)getTextWidth:(NSString *)text withHeight:(CGFloat)height fontSize:(CGFloat)fontSize;

/**
 根据PHAsset对象获取照片信息 带返回错误的block
 
 @param asset <#asset description#>
 @param size <#size description#>
 @param resizeMode <#resizeMode description#>
 @param completion <#completion description#>
 @param error <#error description#>
 */
+ (void)FetchPhotoForPHAsset:(PHAsset *)asset Size:(CGSize)size resizeMode:(PHImageRequestOptionsResizeMode)resizeMode completion:(void(^)(UIImage *image,NSDictionary *info))completion error:(void(^)(NSDictionary *info))error;

@end
