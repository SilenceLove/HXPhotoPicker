//
//  HXPHTypes.swift
//  照片选择器-Swift
//
//  Created by 洪欣 on 2020/11/9.
//  Copyright © 2020 洪欣. All rights reserved.
//

import UIKit

enum HXPHSelectType: Int {
    case photo = 0      //!< 只显示图片
    case video = 1      //!< 只显示视频
    case any = 2        //!< 任何类型
}

enum HXPHAssetSelectMode: Int {
    case single = 0         //!< 单选模式
    case multiple = 1       //!< 多选模式
}

enum HXAlbumShowMode: Int {
    case normal = 0         //!< 正常展示
    case popup = 1          //!< 弹出展示
}

enum HXPHAssetMediaType: Int {
    case photo = 0      //!< 照片
    case video = 1      //!< 视频
}

enum HXPHAssetMediaSubType: Int {
    case image = 0          //!< 静态图
    case imageAnimated = 1  //!< 动图
    case livePhoto = 2      //!< LivePhoto
    case localPhoto = 3     //!< 本地图片
    case video = 4          //!< 视频
    case localVideo = 5     //!< 本地视频
    case camera = 99        //!< 相机
}

enum HXPHLanguageType: Int {
    case system             //!< 跟随系统语言
    case simplifiedChinese  //!< 中文简体
    case traditionalChinese //!< 中文繁体
    case japanese           //!< 日文
    case korean             //!< 韩文
    case english            //!< 英文
}

enum HXPHPickerCellSelectBoxType: Int {
    case number //!< 数字
    case tick   //!< √
}
