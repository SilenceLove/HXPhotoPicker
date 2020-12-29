//
//  HXPHPicker.swift
//  照片选择器-Swift
//
//  Created by Silence on 2020/11/9.
//  Copyright © 2020 Silence. All rights reserved.
//

import UIKit

public class HXPHPicker: NSObject {
    
    public enum SelectType: Int {
        case photo = 0      //!< 只显示图片
        case video = 1      //!< 只显示视频
        case any = 2        //!< 任何类型
    }

    public enum SelectMode: Int {
        case single = 0         //!< 单选模式
        case multiple = 1       //!< 多选模式
    }
    
    public enum AppearanceStyle: Int {
        case varied = 0     //!< 跟随系统变化
        case normal = 1     //!< 正常风格，不会跟随系统变化
        case dark = 2       //!< 暗黑风格
    }
    
    public enum LanguageType: Int {
        case system = 0             //!< 跟随系统语言
        case simplifiedChinese = 1  //!< 中文简体
        case traditionalChinese = 2 //!< 中文繁体
        case japanese = 3           //!< 日文
        case korean = 4             //!< 韩文
        case english = 5            //!< 英文
        case thai = 6               //!< 泰语
        case indonesia = 7          //!< 印尼语
    }
    public enum Asset {
        public enum MediaType: Int {
            case photo = 0      //!< 照片
            case video = 1      //!< 视频
        }

        public enum MediaSubType: Int {
            case image = 0          //!< 手机相册里的图片
            case imageAnimated = 1  //!< 手机相册里的动图
            case livePhoto = 2      //!< 手机相册里的LivePhoto
            case localImage = 3     //!< 本地图片
            case video = 4          //!< 手机相册里的视频
            case localVideo = 5     //!< 本地视频
        }
        public enum DownloadStatus: Int {
            case unknow         //!< 未知，不用下载或还未开始下载
            case succeed        //!< 下载成功
            case downloading    //!< 下载中
            case canceled       //!< 取消下载
            case failed         //!< 下载失败
        }
    }
    public enum Album {
        public enum ShowMode: Int {
            case normal = 0         //!< 正常展示
            case popup = 1          //!< 弹出展示
        }
    }
    public enum PhotoList {
        public enum CancelType {
            case text   //!< 文本
            case image  //!< 图片
        }
        public enum CancelPosition {
            case left   //!< 左边
            case right  //!< 右边
        }
        public enum Cell {
            public enum SelectBoxType: Int {
                case number //!< 数字
                case tick   //!< √
            }
        }
    }
    public enum PreviewView {
        public enum VideoPlayType {
            case normal     //!< 正常状态，不自动播放
            case auto       //!< 自动播放
            case once       //!< 自动播放一次
        }
    }
    public enum CameraAlbumLocal: String {
        case identifier = "HXCameraAlbumLocalIdentifier"
        case identifierType = "HXCameraAlbumLocalIdentifierType"
        case language = "HXCameraAlbumLocalLanguage"
    }
    public enum LivePhotoError {
        case imageError(Error?)
        case videoError(Error?)
        case allError(Error?, Error?)
    }
}

public enum HXPickerError: LocalizedError {
    case error(message: String)
}
public extension HXPickerError {
     var errorDescription: String? {
        switch self {
            case let .error(message):
                return message
        }
    }
}

