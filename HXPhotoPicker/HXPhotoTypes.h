//
//  HXPhotoTypes.h
//  HXPhotoPickerExample
//
//  Created by Silence on 2020/8/3.
//  Copyright © 2020 Silence. All rights reserved.
//

#ifndef HXPhotoTypes_h
#define HXPhotoTypes_h

#import <UIKit/UIKit.h>
#import <Photos/Photos.h>

@class HXPhotoModel, HXAlbumModel, HXPhotoManager;

typedef void (^ viewControllerDidDoneBlock)(NSArray<HXPhotoModel *> * _Nullable allList, NSArray<HXPhotoModel *> * _Nullable photoList, NSArray<HXPhotoModel *> * _Nullable videoList, BOOL original, UIViewController * _Nullable viewController, HXPhotoManager * _Nullable manager);

typedef void (^ viewControllerDidCancelBlock)(UIViewController * _Nullable viewController, HXPhotoManager * _Nullable manager);

typedef void (^ getAllAlbumListBlock)(NSMutableArray<HXAlbumModel *> * _Nullable albums);

typedef void (^ getSelectAlbumBlock)(HXAlbumModel * _Nullable selectedModel);

typedef void (^ getPhotoListBlock)(NSMutableArray * _Nullable allList , NSMutableArray * _Nullable previewList, NSUInteger photoCount, NSUInteger videoCount , HXPhotoModel * _Nullable firstSelectModel, HXAlbumModel * _Nullable albumModel);

typedef NS_ENUM(NSUInteger, HXPhotoManagerSelectedType) {
    HXPhotoManagerSelectedTypePhoto = 0,        //!< 只显示图片
    HXPhotoManagerSelectedTypeVideo = 1,        //!< 只显示视频
    HXPhotoManagerSelectedTypePhotoAndVideo = 2 //!< 图片和视频一起显示
};

typedef NS_ENUM(NSUInteger, HXPhotoManagerVideoSelectedType) {
    HXPhotoManagerVideoSelectedTypeNormal = 0,  //!< 普通状态显示选择按钮
    HXPhotoManagerVideoSelectedTypeSingle       //!< 单选不显示选择按钮
};


/// 当使用了自定义相机类型时会过滤掉内部按 HXPhotoManagerSelectedType 来设置的逻辑，
/// 将会使用自定义类型的逻辑进行设置
typedef NS_ENUM(NSUInteger, HXPhotoCustomCameraType) {
    HXPhotoCustomCameraTypeUnused = 0,      //!< 不使用自定义相机类型，按默认逻辑设置
    HXPhotoCustomCameraTypePhoto = 1,       //!< 拍照
    HXPhotoCustomCameraTypeVideo = 2,       //!< 录制
    HXPhotoCustomCameraTypePhotoAndVideo    //!< 拍照和录制一起
};

typedef NS_ENUM(NSUInteger, HXPhotoConfigurationCameraType) {
    HXPhotoConfigurationCameraTypePhoto = 0,        //!< 拍照
    HXPhotoConfigurationCameraTypeVideo = 1,        //!< 录制
    HXPhotoConfigurationCameraTypePhotoAndVideo     //!< 拍照和录制一起
};

typedef NS_ENUM(NSUInteger, HXPhotoAlbumShowMode) {
    HXPhotoAlbumShowModeDefault = 0,    //!< 默认的
    HXPhotoAlbumShowModePopup           //!< 弹窗
};

typedef NS_ENUM(NSUInteger, HXPhotoLanguageType) {
    HXPhotoLanguageTypeSys = 0, //!< 跟随系统语言
    HXPhotoLanguageTypeSc,      //!< 中文简体
    HXPhotoLanguageTypeTc,      //!< 中文繁体
    HXPhotoLanguageTypeJa,      //!< 日文
    HXPhotoLanguageTypeKo,      //!< 韩文
    HXPhotoLanguageTypeEn       //!< 英文
};

typedef NS_ENUM(NSUInteger, HXPhotoStyle) {
    HXPhotoStyleDefault = 0,    //!< 默认，会跟随系统变化
    HXPhotoStyleInvariant,      //!< 不跟随系统变化
    HXPhotoStyleDark            //!< 暗黑
};

typedef NS_ENUM(NSUInteger, HXVideoAutoPlayType) {
    HXVideoAutoPlayTypeNormal = 0, //!< 不自动播放
    HXVideoAutoPlayTypeWiFi,       //!< wifi网络下自动播放
    HXVideoAutoPlayTypeAll         //!< 蜂窝移动和wifi网络下自动播放
};

typedef NS_ENUM(NSUInteger, HXConfigurationType) {
    HXConfigurationTypeWXChat = 1,  //!< 微信聊天
    HXConfigurationTypeWXMoment     //!< 微信朋友圈
};

typedef NS_ENUM(NSUInteger, HXPhotoListCancelButtonLocationType) {
    HXPhotoListCancelButtonLocationTypeRight = 0,   //!< 右边
    HXPhotoListCancelButtonLocationTypeLeft         //!< 左边
};

typedef NS_ENUM(NSUInteger, HXPhotoModelMediaType) {
    HXPhotoModelMediaTypePhoto          = 0,    //!< 照片
    HXPhotoModelMediaTypeLivePhoto      = 1,    //!< LivePhoto
    HXPhotoModelMediaTypePhotoGif       = 2,    //!< gif图
    HXPhotoModelMediaTypeVideo          = 3,    //!< 视频
    HXPhotoModelMediaTypeAudio          = 4,    //!< 预留
    HXPhotoModelMediaTypeCameraPhoto    = 5,    //!< 通过相机拍的临时照片、本地/网络图片
    HXPhotoModelMediaTypeCameraVideo    = 6,    //!< 通过相机录制的视频、本地视频
    HXPhotoModelMediaTypeCamera         = 7     //!< 跳转相机
};

typedef NS_ENUM(NSUInteger, HXPhotoModelMediaSubType) {
    HXPhotoModelMediaSubTypePhoto = 0,  //!< 照片
    HXPhotoModelMediaSubTypeVideo       //!< 视频
};

typedef NS_ENUM(NSUInteger, HXPhotoModelMediaTypeCameraPhotoType) {
    HXPhotoModelMediaTypeCameraPhotoTypeLocal = 1,          //!< 本地图片
    HXPhotoModelMediaTypeCameraPhotoTypeLocalGif,           //!< 本地gif图片
    HXPhotoModelMediaTypeCameraPhotoTypeNetWork,            //!< 网络图片
    HXPhotoModelMediaTypeCameraPhotoTypeNetWorkGif,         //!< 网络gif图片
    HXPhotoModelMediaTypeCameraPhotoTypeLocalLivePhoto,     //!< 本地LivePhoto
    HXPhotoModelMediaTypeCameraPhotoTypeNetWorkLivePhoto    //!< 网络LivePhoto
};

typedef NS_ENUM(NSUInteger, HXPhotoModelMediaTypeCameraVideoType) {
    HXPhotoModelMediaTypeCameraVideoTypeLocal = 1,  //!< 本地视频
    HXPhotoModelMediaTypeCameraVideoTypeNetWork     //!< 网络视频
};

typedef NS_ENUM(NSUInteger, HXPhotoModelVideoState) {
    HXPhotoModelVideoStateNormal = 0,   //!< 正常状态
    HXPhotoModelVideoStateUndersize,    //!< 视频时长小于最小选择秒数
    HXPhotoModelVideoStateOversize      //!< 视频时长超出限制
};

typedef NS_ENUM(NSUInteger, HXPhotoModelFormat) {
    HXPhotoModelFormatUnknown = 0,  //!< 未知格式
    HXPhotoModelFormatPNG,          //!< PNG格式
    HXPhotoModelFormatJPG,          //!< JPG格式
    HXPhotoModelFormatGIF,          //!< GIF格式
    HXPhotoModelFormatHEIC          //!< HEIC格式
};


typedef void (^ HXModelStartRequestICloud)(PHImageRequestID iCloudRequestId, HXPhotoModel * _Nullable model);

typedef void (^ HXModelProgressHandler)(double progress, HXPhotoModel * _Nullable model);

typedef void (^ HXModelImageSuccessBlock)(UIImage * _Nullable image, HXPhotoModel * _Nullable model, NSDictionary * _Nullable info);

typedef void (^ HXModelImageDataSuccessBlock)(NSData * _Nullable imageData, UIImageOrientation orientation, HXPhotoModel * _Nullable model, NSDictionary * _Nullable info);

typedef void (^ HXModelImageURLSuccessBlock)(NSURL * _Nullable imageURL, HXPhotoModel * _Nullable model, NSDictionary * _Nullable info);

typedef void (^ HXModelLivePhotoSuccessBlock)(PHLivePhoto * _Nullable livePhoto, HXPhotoModel * _Nullable model, NSDictionary * _Nullable info);

typedef void (^ HXModelAVAssetSuccessBlock)(AVAsset * _Nullable avAsset, AVAudioMix * _Nullable audioMix, HXPhotoModel * _Nullable model, NSDictionary * _Nullable info);

typedef void (^ HXModelAVPlayerItemSuccessBlock)(AVPlayerItem * _Nullable playerItem, HXPhotoModel * _Nullable model, NSDictionary * _Nullable info);

typedef void (^ HXModelAVExportSessionSuccessBlock)(AVAssetExportSession * _Nullable assetExportSession, HXPhotoModel * _Nullable model, NSDictionary * _Nullable info);

typedef void (^ HXModelFailedBlock)(NSDictionary * _Nullable info, HXPhotoModel * _Nullable model);

typedef void (^ HXModelExportVideoSuccessBlock)(NSURL * _Nullable videoURL, HXPhotoModel * _Nullable model);

typedef void (^ HXModelExportVideoProgressHandler)(float progress, HXPhotoModel * _Nullable model);

typedef void (^ HXModelURLHandler)(NSURL * _Nullable URL, HXPhotoModelMediaSubType mediaType,  BOOL isNetwork, HXPhotoModel * _Nullable model);

typedef void (^ HXModelLivePhotoAssetsSuccessBlock)(NSURL * _Nullable imageURL, NSURL * _Nullable videoURL, BOOL isNetwork, HXPhotoModel * _Nullable model);


typedef NS_ENUM(NSInteger, HXCustomAssetModelType) {
    HXCustomAssetModelTypeLocalImage        = 1,    //!< 本地图片
    HXCustomAssetModelTypeLocalVideo        = 2,    //!< 本地视频
    HXCustomAssetModelTypeNetWorkImage      = 3,    //!< 网络图片
    HXCustomAssetModelTypeNetWorkVideo      = 4,    //!< 网络视频
    HXCustomAssetModelTypeLocalLivePhoto    = 5,    //!< 本地图片、视频生成的LivePhoto
    HXCustomAssetModelTypeNetWorkLivePhoto  = 6     //!< 网络图片、视频生成的LivePhoto
};


#endif /* HXPhotoTypes_h */
