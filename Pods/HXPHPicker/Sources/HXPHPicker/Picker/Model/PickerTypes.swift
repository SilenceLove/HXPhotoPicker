//
//  PickerTypes.swift
//  HXPHPicker
//
//  Created by Slience on 2021/1/7.
//

import Foundation
import Photos

/// 资源类型可选项
public struct PickerAssetOptions: OptionSet {
    /// Photo 静态照片
    public static let photo = PickerAssetOptions(rawValue: 1 << 0)
    /// Video 视频
    public static let video = PickerAssetOptions(rawValue: 1 << 1)
    /// Gif 动图（包括静态图）
    public static let gifPhoto = PickerAssetOptions(rawValue: 1 << 2)
    /// LivePhoto 实况照片
    public static let livePhoto = PickerAssetOptions(rawValue: 1 << 3)
    
    public var isPhoto: Bool {
        contains(.photo) || contains(.gifPhoto) || contains(.livePhoto)
    }
    public var isVideo: Bool {
        contains(.video)
    }
    
    public let rawValue: Int

    public init(rawValue: Int) {
        self.rawValue = rawValue
    }
}

public enum PickerSelectMode: Int {
    /// 单选模式
    case single = 0
    /// 多选模式
    case multiple = 1
}

/// 资源列表Cell点击动作
public enum SelectionTapAction: Equatable {
    
    /// 进入预览界面
    case preview
    
    /// 快速选择
    /// - 点击资源时会直接选中，不会进入预览界面
    case quickSelect
    
    /// 打开编辑器
    /// - 点击资源时如果可以编辑的话，就会进入编辑界面
    case openEditor
}

public enum PickerPresentStyle {
    case present
    case push
}

public extension PickerResult {
    struct Options: OptionSet {
        public static let photo = Options(rawValue: 1 << 0)
        public static let video = Options(rawValue: 1 << 1)
        public static let any: Options = [.photo, .video]
        public let rawValue: Int
        
        public init(rawValue: Int) {
            self.rawValue = rawValue
        }
    }
}

public extension PhotoAsset {
    enum MediaType: Int {
        /// 照片
        case photo = 0
        /// 视频
        case video = 1
    }

    enum MediaSubType: Equatable {
        /// 手机相册里的图片
        case image
        /// 手机相册里的动图
        case imageAnimated
        /// 手机相册里的LivePhoto
        case livePhoto
        /// 手机相册里的视频
        case video
        /// 本地图片
        case localImage
        /// 本地视频
        case localVideo
        /// 本地LivePhoto
        case localLivePhoto
        /// 本地动图
        case localGifImage
        /// 网络图片
        case networkImage(Bool)
        /// 网络视频
        case networkVideo
        
        public var isLocal: Bool {
            switch self {
            case .localImage, .localGifImage, .localVideo, .localLivePhoto:
                return true
            default:
                return false
            }
        }
        
        public var isPhoto: Bool {
            switch self {
            case .image, .imageAnimated, .livePhoto, .localImage, .localLivePhoto, .localGifImage, .networkImage(_):
                return true
            default:
                return false
            }
        }
        
        public var isVideo: Bool {
            switch self {
            case .video, .localVideo, .networkVideo:
                return true
            default:
                return false
            }
        }
        
        public var isGif: Bool {
            switch self {
            case .imageAnimated, .localGifImage:
                return true
            case .networkImage(let isGif):
                return isGif
            default:
                return false
            }
        }
        
        public var isNetwork: Bool {
            switch self {
            case .networkImage(_), .networkVideo:
                return true
            default:
                return false
            }
        }
    }
    enum DownloadStatus: Int {
        /// 未知，不用下载或还未开始下载
        case unknow
        /// 下载成功
        case succeed
        /// 下载中
        case downloading
        /// 取消下载
        case canceled
        /// 下载失败
        case failed
    }
    
    /// 网络视频加载方式
    enum LoadNetworkVideoMode {
        /// 先下载
        case download
        /// 直接播放
        case play
    }
}

public enum AlbumShowMode: Int {
    /// 正常展示
    case normal = 0
    /// 弹出展示
    case popup = 1
}

public extension PhotoPickerViewController {
    enum CancelType {
        /// 文本
        case text
        /// 图片
        case image
    }
    enum CancelPosition {
        /// 左边
        case left
        /// 右边
        case right
    }
}

public extension PhotoPreviewViewController {
    enum PlayType {
        /// 视频不自动播放
        /// LivePhoto需要长按播放
        case normal
        /// 自动循环播放
        case auto
        /// 只有第一次自动播放
        case once
    }
}

public enum DonwloadURLType {
    case thumbnail
    case original
}

extension PhotoManager {
    enum CameraAlbumLocal: String {
        case identifier = "HXCameraAlbumLocalIdentifier"
        case identifierType = "HXCameraAlbumLocalIdentifierType"
        case language = "HXCameraAlbumLocalLanguage"
    }
}
extension PickerAssetOptions {
    
    var mediaTypes: [PHAssetMediaType] {
        var result: [PHAssetMediaType] = []
        if contains(.photo) || contains(.gifPhoto) || contains(.livePhoto) {
            result.append(.image)
        }
        if contains(.video) {
            result.append(.video)
        }
        return result
    }
}

/// Sort 排序规则
public enum Sort: Equatable {
    /// ASC 升序
    case asc
    /// DESC 降序
    case desc
}
