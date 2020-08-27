//
//  HXPhotoCommon.h
//  HXPhotoPicker-Demo
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

@interface HXPhotoCommon : NSObject
@property (strong, nonatomic, nullable) NSBundle *languageBundle;
@property (strong, nonatomic, nullable) NSBundle *photoPickerBundle;

@property (assign, nonatomic) CGSize requestSize;

/// 相册风格
@property (assign, nonatomic) HXPhotoStyle photoStyle;
@property (assign, nonatomic) HXPhotoLanguageType languageType;
@property (strong, nonatomic) UIImage * _Nullable cameraImage;
@property (strong, nonatomic) NSURL * _Nullable cameraImageURL;

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

@property (copy, nonatomic) NSString * _Nullable cameraRollLocalIdentifier;
@property (copy, nonatomic) PHFetchResult * _Nullable cameraRollResult;
@property (assign, nonatomic) NSInteger selectType;
@property (assign, nonatomic) BOOL creationDateSort;

@property (copy, nonatomic) NSString *UUIDString;

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
