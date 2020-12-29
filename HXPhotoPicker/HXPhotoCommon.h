//
//  HXPhotoCommon.h
//  HXPhotoPickerExample
//
//  Created by Silence on 2019/1/8.
//  Copyright © 2019年 Silence. All rights reserved.
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
/// 小图请求大小
@property (assign, nonatomic) CGFloat requestWidth;
/// 相册风格
@property (assign, nonatomic) HXPhotoStyle photoStyle;
/// 相册语言
@property (assign, nonatomic) HXPhotoLanguageType languageType;
/// 相机预览图片
@property (strong, nonatomic) UIImage * _Nullable cameraImage;
/// 相机预览imageURL
@property (strong, nonatomic) NSURL * _Nullable cameraImageURL;
/// 查看LivePhoto是否自动播放，为NO时需要长按才可播放
@property (assign, nonatomic) BOOL livePhotoAutoPlay;
/// 预览视频时是否自动播放
@property (assign, nonatomic) HXVideoAutoPlayType videoAutoPlayType;
/// 预览视频时是否先下载视频再播放
@property (assign, nonatomic) BOOL downloadNetworkVideo;
/// 状态栏
@property (assign, nonatomic) BOOL isVCBasedStatusBarAppearance;
/// ios13之后的3DTouch
@property (assign, nonatomic) BOOL isHapticTouch;
/// 点击完成按钮时是否需要下载网络视频
@property (assign, nonatomic) BOOL requestNetworkAfter;

#if HasAFNetworking
@property (assign, nonatomic) AFNetworkReachabilityStatus netStatus;
@property (copy, nonatomic) void (^ reachabilityStatusChangeBlock)(AFNetworkReachabilityStatus netStatus);
#endif
/// 相机胶卷相册唯一标识符
@property (copy, nonatomic) NSString * _Nullable cameraRollLocalIdentifier;
/// 相机胶卷相册Result
@property (copy, nonatomic) PHFetchResult * _Nullable cameraRollResult;
/// 选择类型
@property (assign, nonatomic) NSInteger selectType;
/// 创建日期排序
@property (assign, nonatomic) BOOL creationDateSort;
/// 相册发生改变时，主要作用在选择部分可查看资源时
@property (copy, nonatomic) void (^photoLibraryDidChange)(void);
/// 设备id
@property (copy, nonatomic) NSString *UUIDString;

@property (assign, nonatomic) PHImageRequestID clearAssetRequestID;

/// 下载视频
/// @param videoURL 网络视频地址
/// @param progress 下载进度
/// @param success 下载成功
/// @param failure 下载失败
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
