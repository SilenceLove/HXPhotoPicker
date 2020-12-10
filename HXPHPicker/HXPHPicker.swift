//
//  HXPHPicker.swift
//  照片选择器-Swift
//
//  Created by 洪欣 on 2020/11/9.
//  Copyright © 2020 洪欣. All rights reserved.
//

import UIKit

class HXPHPicker: NSObject {
    
    enum SelectType: Int {
        case photo = 0      //!< 只显示图片
        case video = 1      //!< 只显示视频
        case any = 2        //!< 任何类型
    }

    enum SelectMode: Int {
        case single = 0         //!< 单选模式
        case multiple = 1       //!< 多选模式
    }
    
    enum AppearanceStyle: Int {
        case varied     //!< 跟随系统变化
        case normal     //!< 正常风格，不会跟随系统变化
        case dark       //!< 暗黑风格
    }
    
    enum LanguageType: Int {
        case system             //!< 跟随系统语言
        case simplifiedChinese  //!< 中文简体
        case traditionalChinese //!< 中文繁体
        case japanese           //!< 日文
        case korean             //!< 韩文
        case english            //!< 英文
        case thai               //!< 泰语
        case indonesia          //!< 印尼语
    }
    enum Asset {
        enum MediaType: Int {
            case photo = 0      //!< 照片
            case video = 1      //!< 视频
        }

        enum MediaSubType: Int {
            case image = 0          //!< 静态图
            case imageAnimated = 1  //!< 动图
            case livePhoto = 2      //!< LivePhoto
            case localPhoto = 3     //!< 本地图片
            case video = 4          //!< 视频
            case localVideo = 5     //!< 本地视频
            case camera = 99        //!< 相机
        }
    }
    enum Album {
        enum ShowMode: Int {
            case normal = 0         //!< 正常展示
            case popup = 1          //!< 弹出展示
        }
    }
    enum PhotoList {
        enum Cell {
            enum SelectBoxType: Int {
                case number //!< 数字
                case tick   //!< √
            }
        }
    }
    enum CameraAlbumLocal: String {
        case identifier = "HXCameraAlbumLocalIdentifier"
        case identifierType = "HXCameraAlbumLocalIdentifierType"
        case language = "HXCameraAlbumLocalLanguage"
    }
    enum LivePhotoError {
        case imageError(Error?)
        case videoError(Error?)
        case allError(Error?, Error?)
    }
}

enum HXPickerError: LocalizedError {
    case error(message: String)
}
extension HXPickerError {
    public var errorDescription: String? {
        switch self {
            case let .error(message):
                return message
        }
    }
}
