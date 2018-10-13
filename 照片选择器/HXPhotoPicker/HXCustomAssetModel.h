//
//  HXCustomAssetModel.h
//  照片选择器
//
//  Created by 洪欣 on 2018/7/25.
//  Copyright © 2018年 洪欣. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, HXCustomAssetModelType) {
    HXCustomAssetModelTypeLocalImage = 1,   //!< 本地图片
    HXCustomAssetModelTypeLocalVideo = 2,   //!< 本地视频
    HXCustomAssetModelTypeNetWorkImage = 3  //!< 网络图片
};

@interface HXCustomAssetModel : NSObject

/**
 资源类型
 */
@property (assign, nonatomic) HXCustomAssetModelType type;

/**
 网络图片地址
 */
@property (strong, nonatomic) NSURL *networkImageURL;

/**
 网络图片缩略图地址
 */
@property (strong, nonatomic) NSURL *networkThumbURL;

/**
 本地图片UIImage
 */
@property (strong, nonatomic) UIImage *localImage;

/**
 本地视频地址
 */
@property (strong, nonatomic) NSURL *localVideoURL;

/**
 是否选中
 */
@property (assign, nonatomic) BOOL selected;

/**
 根据本地图片名初始化

 @param imageName 本地图片名
 @param selected 是否选中
 @return HXCustomAssetModel
 */
+ (instancetype)assetWithLocaImageName:(NSString *)imageName selected:(BOOL)selected;

/**
 根据本地UIImage初始化

 @param image 本地图片
 @param selected 是否选中
 @return HXCustomAssetModel
 */
+ (instancetype)assetWithLocalImage:(UIImage *)image selected:(BOOL)selected;

/**
 根据网络图片地址初始化

 @param imageURL 网络图片地址
 @param selected 是否选中
 @return HXCustomAssetModel
 */
+ (instancetype)assetWithNetworkImageURL:(NSURL *)imageURL selected:(BOOL)selected;

/**
 根据网络图片地址初始化

 @param imageURL 网络图片地址
 @param thumbURL 网络图片缩略图地址
 @param selected 是否选中
 @return HXCustomAssetModel
 */
+ (instancetype)assetWithNetworkImageURL:(NSURL *)imageURL networkThumbURL:(NSURL *)thumbURL selected:(BOOL)selected;

/**
 根据本地视频地址初始化

 @param videoURL 本地视频地址
 @param selected 是否选中
 @return HXCustomAssetModel
 */
+ (instancetype)assetWithLocalVideoURL:(NSURL *)videoURL selected:(BOOL)selected;
@end
