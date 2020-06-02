//
//  HXPhotoCommon.h
//  照片选择器
//
//  Created by 洪欣 on 2019/1/8.
//  Copyright © 2019年 洪欣. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HXPhotoConfiguration.h"
#import "HXPhotoDefine.h"
#import "HXPhotoModel.h"
#import "HXAlbumModel.h"
#if __has_include(<AFNetworking/AFNetworking.h>)
#import <AFNetworking/AFNetworking.h>
#elif __has_include("AFNetworking.h")
#import "AFNetworking.h"
#endif

NS_ASSUME_NONNULL_BEGIN

typedef void (^ HXPhotoCommonGetUrlFileLengthSuccess)(NSUInteger length);
typedef void (^ HXPhotoCommonGetUrlFileLengthFailure)(void);

@interface HXPhotoCommon : NSObject
@property (strong, nonatomic, nullable) NSBundle *languageBundle;
/// 相册风格
@property (assign, nonatomic) HXPhotoStyle photoStyle;
@property (assign, nonatomic) HXPhotoLanguageType languageType;
@property (strong, nonatomic) UIImage *cameraImage;

/// 预览视频时是否自动播放
@property (assign, nonatomic) HXVideoAutoPlayType videoAutoPlayType;

/// 预览视频时是否先下载视频再播放
@property (assign, nonatomic) BOOL downloadNetworkVideo;

@property (assign, nonatomic) BOOL isVCBasedStatusBarAppearance;

@property (assign, nonatomic) BOOL isHapticTouch;

@property (assign, nonatomic) BOOL requestNetworkAfter;

#if HasAFNetworking
@property (assign, nonatomic) AFNetworkReachabilityStatus netStatus;
@property (copy, nonatomic) void (^ reachabilityStatusChangeBlock)(AFNetworkReachabilityStatus netStatus);
#endif

@property (strong, nonatomic) HXAlbumModel * _Nullable cameraRollAlbumModel;
@property (assign, nonatomic) NSInteger selectedType;

- (void)getURLFileLengthWithURL:(NSURL *)url
                        success:(HXPhotoCommonGetUrlFileLengthSuccess)success
                        failure:(HXPhotoCommonGetUrlFileLengthFailure)failure;

- (NSURLSessionDownloadTask * _Nullable)downloadVideoWithURL:(NSURL *)videoURL
                                          progress:(void (^ _Nullable)(float progress, long long downloadLength, long long totleLength, NSURL * _Nullable videoURL))progress
                                   downloadSuccess:(void (^ _Nullable)(NSURL * _Nullable filePath, NSURL * _Nullable videoURL))success
                                   downloadFailure:(void (^ _Nullable)(NSError * _Nullable error, NSURL * _Nullable videoURL))failure;

+ (instancetype)photoCommon;
+ (void)deallocPhotoCommon;
- (void)saveCamerImage;
- (BOOL)isDark;
@end

NS_ASSUME_NONNULL_END
