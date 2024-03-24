//
//  PickerTypes.swift
//  HXPhotoPicker
//
//  Created by Slience on 2021/1/7.
//

import UIKit
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
    case none
    case present(rightSwipe: RightSwipe? = .init(50))
    case push(rightSwipe: RightSwipe? = .init(50))
    
    public struct RightSwipe {
        /// 右滑返回手势触发范围，距离屏幕左边的距离
        public let triggerRange: CGFloat
        /// 如果返回过程中没有显示背景视图，请将fromVC传入
        public let viewControlls: [UIViewController.Type]
        public init(_ triggerRange: CGFloat, viewControlls: [UIViewController.Type] = []) {
            self.triggerRange = triggerRange
            self.viewControlls = viewControlls
        }
    }
}

public enum PhotoPickerPreviewJumpStyle {
    case push
    case present
}

public enum EditorJumpStyle {
    case push(PushStyle = .custom)
    case present(PresentStyle = .automatic)
    
    public enum PushStyle {
        case normal
        case custom
    }
    public enum PresentStyle {
        case automatic
        case fullScreen
        case custom
    }
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

    enum MediaSubType: Equatable, Codable {
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
            case .image, .imageAnimated, .livePhoto, .localImage, .localLivePhoto, .localGifImage, .networkImage:
                return true
            default:
                return false
            }
        }
        
        public var isNormalPhoto: Bool {
            switch self {
            case .image, .localImage:
                return true
            case .networkImage(let isGif):
                return !isGif
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
        
        public var isLivePhoto: Bool {
            switch self {
            case .livePhoto, .localLivePhoto:
                return true
            default:
                return false
            }
        }
        
        public var isNetwork: Bool {
            switch self {
            case .networkImage, .networkVideo:
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

public enum AlbumShowMode {
    /// 正常展示
    case normal
    /// 弹出 View
    case popup
    /// 弹出 控制器
    case present(UIModalPresentationStyle)
    
    public var isPop: Bool {
        switch self {
        case .popup, .present:
            return true
        default:
            return false
        }
    }
    
    public var isPopView: Bool {
        switch self {
        case .popup:
            return true
        default:
            return false
        }
    }
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

public enum PickerError: Error, LocalizedError, CustomStringConvertible {
    case imageFetchFaild
    case imageDataFetchFaild(AssetError)
    case urlFetchFaild(AssetError)
    case urlResultFetchFaild(AssetError)
    case objsFetchFaild(PhotoAsset, Int, Error)
    case canceled
    
    public var errorDescription: String? {
        switch self {
        case .imageDataFetchFaild(let error):
            return "imageFetchFaild：获取 UIImage 失败: \(error)"
        case .imageFetchFaild:
            return "imageDataFetchFaild：获取 UIImage Data 失败"
        case .urlFetchFaild(let error):
            return "urlFetchFaild：获取 URL 失败: \(error)"
        case .urlResultFetchFaild(let error):
            return "urlResultFetchFaild：获取 AssetURLResult 失败: \(error)"
        case .objsFetchFaild(let photoAsset, let index, let error):
            return "objsFetchFaild：PickerResult.photoAssets获取到第\(index + 1)失败，photoAsset: \(photoAsset), error: \(error)"
        case .canceled:
            return "canceled：取消选择"
        }
    }
    
    public var description: String {
        errorDescription ?? "nil"
    }
}

public enum PhotoPreviewType {
    case none
    case picker
    case browser
}

public enum PickerTransitionType {
    case push
    case pop
    case present
    case dismiss
}
