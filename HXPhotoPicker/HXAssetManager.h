//
//  HXAssetManager.h
//  HXPhotoPickerExample
//
//  Created by Silence on 2020/11/5.
//  Copyright © 2020 Silence. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Photos/Photos.h>
#import "HXPhotoTypes.h"

NS_ASSUME_NONNULL_BEGIN
@class HXAlbumModel;
@interface HXAssetManager : NSObject

/// 获取智能相册
+ (PHFetchResult<PHAssetCollection *> *)fetchSmartAlbumsWithOptions:(PHFetchOptions * _Nullable)options;

/// 获取用户创建的相册
+ (PHFetchResult<PHAssetCollection *> *)fetchUserAlbumsWithOptions:(PHFetchOptions * _Nullable)options;

/// 获取相机胶卷
+ (PHAssetCollection *)fetchCameraRollAlbumWithOptions:(PHFetchOptions * _Nullable)options;

/// 获取所有相册
+ (void)enumerateAllAlbumsWithOptions:(PHFetchOptions * _Nullable)options
                           usingBlock:(void (^)(PHAssetCollection *collection))enumerationBlock;

/// 获取所有相册模型
+ (void)enumerateAllAlbumModelsWithOptions:(PHFetchOptions * _Nullable)options
                                usingBlock:(void (^)(HXAlbumModel *albumModel))enumerationBlock;

/// 是否相机胶卷
+ (BOOL)isCameraRollAlbum:(PHAssetCollection *)assetCollection;

/// 获取PHAssetCollection
/// @param localIdentifier 本地标识符
+ (PHAssetCollection *)fetchAssetCollectionWithIndentifier:(NSString *)localIdentifier;

/// 获取PHAsset
/// @param localIdentifier 本地标识符
+ (PHAsset *)fetchAssetWithLocalIdentifier:(NSString *)localIdentifier;

/// 获取PHAsset
/// @param assetCollection 相册
/// @param options 选项
+ (PHFetchResult<PHAsset *> *)fetchAssetsInAssetCollection:(PHAssetCollection *)assetCollection
                                                   options:(PHFetchOptions *)options;

/// Asset的原图
+ (UIImage *)originImageForAsset:(PHAsset *)asset;

/// 请求视频地址
+ (void)requestVideoURL:(PHAsset *)asset
             completion:(void (^ _Nullable)(NSURL * _Nullable videoURL))completion;

/// 请求获取image
/// @param asset 需要获取的资源
/// @param targetSize 指定返回的大小
/// @param contentMode 内容模式
/// @param options 选项
/// @param completion 完成请求后调用的 block
+ (PHImageRequestID)requestImageForAsset:(PHAsset *)asset
                              targetSize:(CGSize)targetSize
                             contentMode:(PHImageContentMode)contentMode
                                 options:(PHImageRequestOptions * _Nullable)options
                              completion:(void (^ _Nullable)(UIImage *result, NSDictionary<NSString *, id> *info))completion;

/// 异步请求 Asset 的缩略图，不会产生网络请求
/// @param asset 需要获取的资源
/// @param targetWidth 指定返回的缩略图的宽度
/// @param completion 完成请求后调用的 block 会被多次调用
+ (PHImageRequestID)requestThumbnailImageForAsset:(PHAsset *)asset
                                      targetWidth:(CGFloat)targetWidth
                                       completion:(void (^ _Nullable)(UIImage *result, NSDictionary<NSString *, id> *info))completion;

/// 异步请求 Asset 的缩略图，不会产生网络请求
/// @param targetWidth 指定返回的缩略图的宽度
/// @param deliveryMode 交付模式
/// @param completion 完成请求后调用的 block
+ (PHImageRequestID)requestThumbnailImageForAsset:(PHAsset *)asset
                                      targetWidth:(CGFloat)targetWidth
                                     deliveryMode:(PHImageRequestOptionsDeliveryMode)deliveryMode
                                       completion:(void (^ _Nullable)(UIImage *result, NSDictionary<NSString *, id> *info))completion;

/// 异步请求 Asset 的展示图
/// @param targetSize 指定返回展示的大小
/// @param networkAccessAllowed 允许网络请求
/// @param progressHandler 存在iCloud上并且允许了网络请求才有回调，不在主线程上执行
/// @param completion 完成请求后调用的 block，只会回调一次
+ (PHImageRequestID)requestPreviewImageForAsset:(PHAsset *)asset
                                     targetSize:(CGSize)targetSize
                           networkAccessAllowed:(BOOL)networkAccessAllowed
                                progressHandler:(PHAssetImageProgressHandler _Nullable)progressHandler
                                     completion:(void (^ _Nullable)(UIImage *result, NSDictionary<NSString *, id> *info))completion;

/// 请求获取imageData
/// @param asset 需要获取的资源
/// @param options 选项
/// @param completion 完成请求后调用的 block
+ (PHImageRequestID)requestImageDataForAsset:(PHAsset *)asset
                                     options:(PHImageRequestOptions * _Nullable)options
                                  completion:(void (^ _Nullable)(NSData *imageData,  UIImageOrientation orientation, NSDictionary<NSString *, id> *info))completion;

/// 异步请求 Asset 的imageData
/// @param version 请求版本，如果是GIF建议设置PHImageRequestOptionsVersionOriginal
/// @param resizeMode 调整模式
/// @param networkAccessAllowed 允许网络请求
/// @param progressHandler 存在iCloud上并且允许了网络请求才有回调，不在主线程上执行
/// @param completion 完成请求后调用的 block，只回调一次
/// @return 返回请求图片的请求 id
+ (PHImageRequestID)requestImageDataForAsset:(PHAsset *)asset
                                     version:(PHImageRequestOptionsVersion)version
                                  resizeMode:(PHImageRequestOptionsResizeMode)resizeMode
                        networkAccessAllowed:(BOOL)networkAccessAllowed
                             progressHandler:(PHAssetImageProgressHandler _Nullable)progressHandler
                                  completion:(void (^ _Nullable)(NSData *imageData,  UIImageOrientation orientation, NSDictionary<NSString *, id> *info))completion;

/// 请求获取LivePhoto
/// @param targetSize 指定返回的大小
/// @param contentMode 内容模式
/// @param options 选项
/// @param completion 完成请求后调用的 block
+ (PHLivePhotoRequestID)requestLivePhotoForAsset:(PHAsset *)asset
                                      targetSize:(CGSize)targetSize
                                     contentMode:(PHImageContentMode)contentMode
                                         options:(PHLivePhotoRequestOptions * _Nullable)options
                                      completion:(void (^ _Nullable)(PHLivePhoto *livePhoto, NSDictionary<NSString *,id> * _Nonnull info))completion;

/// 异步请求 LivePhoto
/// @param targetSize 指定返回的大小
/// @param networkAccessAllowed 允许网络请求
/// @param progressHandler 存在iCloud上并且允许了网络请求才有回调，不在主线程上执行
/// @param completion 完成请求后调用的 block，只会回调一次
+ (PHLivePhotoRequestID)requestPreviewLivePhotoForAsset:(PHAsset *)asset
                                             targetSize:(CGSize)targetSize
                                   networkAccessAllowed:(BOOL)networkAccessAllowed
                                        progressHandler:(PHAssetImageProgressHandler _Nullable)progressHandler
                                             completion:(void (^ _Nullable)(PHLivePhoto *livePhoto, NSDictionary<NSString *,id> * _Nonnull info))completion;

/// 请求获取 AVAsset
/// @param options 选项
/// @param completion 完成请求后调用的 block，只会回调一次
+ (PHImageRequestID)requestAVAssetForAsset:(PHAsset *)asset
                                   options:(PHVideoRequestOptions * _Nullable)options
                                completion:(void (^ _Nullable)(AVAsset *asset, AVAudioMix *audioMix, NSDictionary *info))completion;

/// 请求获取 AVAsset
/// @param networkAccessAllowed 允许网络请求
/// @param progressHandler 存在iCloud上并且允许了网络请求才有回调，不在主线程上执行
/// @param completion 完成请求后调用的 block，只会回调一次
+ (PHImageRequestID)requestAVAssetForAsset:(PHAsset *)asset
                      networkAccessAllowed:(BOOL)networkAccessAllowed
                           progressHandler:(PHAssetImageProgressHandler _Nullable)progressHandler
                                completion:(void (^ _Nullable)(AVAsset *asset, AVAudioMix *audioMix, NSDictionary *info))completion;

/// 请求获取 AVPlayerItem
/// @param options 选项
/// @param completion 完成请求后调用的 block，只会回调一次
+ (PHImageRequestID)requestPlayerItemForAsset:(PHAsset *)asset
                                      options:(PHVideoRequestOptions * _Nullable)options
                                   completion:(void (^ _Nullable)(AVPlayerItem * _Nullable playerItem, NSDictionary * _Nullable info))completion;

/// 请求获取 AVPlayerItem
/// @param networkAccessAllowed 允许网络请求
/// @param progressHandler 存在iCloud上并且允许了网络请求才有回调，不在主线程上执行
/// @param completion 完成请求后调用的 block，只会回调一次
+ (PHImageRequestID)requestPlayerItemForAsset:(PHAsset *)asset
                         networkAccessAllowed:(BOOL)networkAccessAllowed
                              progressHandler:(PHAssetImageProgressHandler _Nullable)progressHandler
                                   completion:(void (^ _Nullable)(AVPlayerItem * _Nullable playerItem, NSDictionary * _Nullable info))completion;

/// 请求获取 AVAssetExportSession
/// @param options 选项
/// @param exportPreset 导出质量
/// @param completion 完成请求后调用的 block，只会回调一次
+ (PHImageRequestID)requestExportSessionForAsset:(PHAsset *)asset
                                         options:(PHVideoRequestOptions * _Nullable)options
                                    exportPreset:(NSString *)exportPreset
                                      completion:(void (^ _Nullable)(AVAssetExportSession * _Nullable exportSession, NSDictionary * _Nullable info))completion;

/// 请求获取 AVAssetExportSession
/// @param exportPreset 导出质量
/// @param networkAccessAllowed 允许网络请求
/// @param progressHandler 存在iCloud上并且允许了网络请求才有回调，不在主线程上执行
/// @param completion 完成请求后调用的 block，只会回调一次
+ (PHImageRequestID)requestExportSessionForAsset:(PHAsset *)asset
                                    exportPreset:(NSString *)exportPreset
                            networkAccessAllowed:(BOOL)networkAccessAllowed
                                 progressHandler:(PHAssetImageProgressHandler _Nullable)progressHandler
                                      completion:(void (^ _Nullable)(AVAssetExportSession * _Nullable exportSession, NSDictionary * _Nullable info))completion;

/// 获取视频地址，可压缩
/// @param asset 对应的 PHAsset 对象
/// @param fileURL 指定导出地址
/// @param exportPreset 导出视频分辨率
/// @param videoQuality 导出视频质量[0-10]
/// @param resultHandler 导出结果
+ (void)requestVideoURLForAsset:(PHAsset *)asset
                         toFile:(NSURL * _Nullable)fileURL
                   exportPreset:(HXVideoExportPreset)exportPreset
                   videoQuality:(NSInteger)videoQuality
                  resultHandler:(void (^ _Nullable)(NSURL * _Nullable))resultHandler;
/// 获取是否成功完成
/// @param info 获取时返回的信息
+ (BOOL)downloadFininedForInfo:(NSDictionary *)info;

/// 资源是否在iCloud上
/// @param info 获取时返回的信息
+ (BOOL)isInCloudForInfo:(NSDictionary *)info;

@end

NS_ASSUME_NONNULL_END
