//
//  HXCustomAssetModel.h
//  HXPhotoPickerExample
//
//  Created by Silence on 2018/7/25.
//  Copyright © 2018年 Silence. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "HXPhotoTypes.h"

@interface HXCustomAssetModel : NSObject

/// 资源类型
@property (assign, nonatomic) HXCustomAssetModelType type;

/// 图片/视频尺寸
@property (assign, nonatomic) CGSize imageSize;

/// 网络图片地址 or 网络视频封面
@property (strong, nonatomic) NSURL * _Nullable networkImageURL;

/// 网络图片缩略图地址 or 网络视频封面
@property (strong, nonatomic) NSURL * _Nullable networkThumbURL;

/// 本地图片UIImage
@property (strong, nonatomic) UIImage * _Nullable localImage;

/// 本地视频地址
@property (strong, nonatomic) NSURL * _Nullable localVideoURL;

/// 本地图片地址
@property (strong, nonatomic) NSURL * _Nullable localImagePath;

/// 网络视频地址
@property (strong, nonatomic) NSURL * _Nullable networkVideoURL;

/// 视频时长
@property (assign, nonatomic) NSTimeInterval videoDuration;

/// 是否选中
@property (assign, nonatomic) BOOL selected;

/// 根据本地图片名初始化
/// @param imageName 本地图片名
/// @param selected 是否选中
+ (instancetype _Nullable)assetWithLocaImageName:(NSString * _Nonnull)imageName
                                        selected:(BOOL)selected;

/// 根据本地UIImage初始化
/// @param image 本地图片
/// @param selected 是否选中
+ (instancetype _Nullable)assetWithLocalImage:(UIImage * _Nonnull)image
                                     selected:(BOOL)selected;

/// 根据本地图片路径生成图片，本地GIF图片可根据此方法导入
/// @param imagePath 图片路径
/// @param selected 是否选中
+ (instancetype _Nullable)assetWithImagePath:(NSURL * _Nonnull)imagePath
                                    selected:(BOOL)selected;

/// 根据网络图片地址初始化
/// @param imageURL 网络图片地址
/// @param selected 是否选中
+ (instancetype _Nullable)assetWithNetworkImageURL:(NSURL * _Nonnull)imageURL
                                          selected:(BOOL)selected;

/// 根据网络图片地址初始化
/// @param imageURL 网络图片地址
/// @param thumbURL 网络图片缩略图地址
/// @param selected 是否选中
+ (instancetype _Nullable)assetWithNetworkImageURL:(NSURL * _Nonnull)imageURL
                                   networkThumbURL:(NSURL * _Nullable)thumbURL
                                          selected:(BOOL)selected;

/// 根据本地视频地址初始化
/// @param videoURL 本地视频地址
/// @param selected 是否选中
+ (instancetype _Nullable)assetWithLocalVideoURL:(NSURL * _Nonnull)videoURL
                                        selected:(BOOL)selected;

/// 根据网络视频地址、视频封面初始化
/// @param videoURL 视频地址
/// @param videoCoverURL 视频封面地址
/// @param videoDuration 视频时长
/// @param selected 是否选中
+ (instancetype _Nullable)assetWithNetworkVideoURL:(NSURL * _Nonnull)videoURL
                                     videoCoverURL:(NSURL * _Nullable)videoCoverURL
                                     videoDuration:(NSTimeInterval)videoDuration
                                          selected:(BOOL)selected;

/// 根据本地图片和本地视频生成LivePhoto
/// @param imagePath 本地图片地址 LivePhoto封面
/// @param videoURL 本地视频地址
/// @param selected 是否选中
+ (instancetype _Nullable)livePhotoAssetWithLocalImagePath:(NSURL * _Nonnull)imagePath
                                             localVideoURL:(NSURL * _Nonnull)videoURL
                                                  selected:(BOOL)selected;

/// 根据本地图片和本地视频生成LivePhoto
+ (instancetype _Nullable)livePhotoAssetWithImage:(UIImage * _Nonnull)image
                                    localVideoURL:(NSURL * _Nonnull)videoURL
                                         selected:(BOOL)selected;

/// 根据网络图片和网络视频生成LivePhoto
/// 网络视频需要使用AFNetWorking框架下载
/// 使用pod的 'HXPhotoPicker/SDWebImage_AF' 或者 'HXPhotoPicker/YYWebImage_AF'
+ (instancetype _Nullable)livePhotoAssetWithNetworkImageURL:(NSURL * _Nonnull)imageURL
                                            networkVideoURL:(NSURL * _Nonnull)videoURL
                                                   selected:(BOOL)selected;
@end
