//
//  HXPhotoTypes.h
//  照片选择器
//
//  Created by 洪欣 on 2020/8/3.
//  Copyright © 2020 洪欣. All rights reserved.
//

#ifndef HXPhotoTypes_h
#define HXPhotoTypes_h

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
    HXPhotoStyleDefault = 0,    //!< 默认
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


#endif /* HXPhotoTypes_h */
