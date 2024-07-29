//
//  CameraConfiguration.swift
//  HXPhotoPicker
//
//  Created by Slience on 2021/8/30.
//

import UIKit
import AVFoundation

// MARK: 相机配置类
#if !targetEnvironment(macCatalyst)
public struct CameraConfiguration: IndicatorTypeConfig, PhotoHUDConfig {
    
    /// 图片资源
    public var imageResource: HX.ImageResource { HX.ImageResource.shared }
    
    /// 文本管理
    public var textManager: HX.TextManager { HX.TextManager.shared }
    
    public var modalPresentationStyle: UIModalPresentationStyle
    
    /// If the built-in language is not enough, you can add a custom language text
    /// customLanguages - custom language array
    /// 如果自带的语言不够，可以添加自定义的语言文字
    /// customLanguages - 自定义语言数组
    public var languageType: LanguageType = .system {
        didSet {
            #if HXPICKER_ENABLE_EDITOR
            editor.languageType = languageType
            #endif
        }
    }
    
    /// 自定义语言
    public var customLanguages: [CustomLanguage] {
        get { PhotoManager.shared.customLanguages }
        set { PhotoManager.shared.customLanguages = newValue }
    }
    
    /// hide status bar
    /// 隐藏状态栏
    public var prefersStatusBarHidden: Bool = true
    
    /// Rotation is allowed, and rotation can only be disabled in full screen
    /// 允许旋转，全屏情况下才可以禁止旋转
    public var shouldAutorotate: Bool = true
    
    /// 是否自动返回
    public var isAutoBack: Bool = true
    
    /// supported directions
    /// 支持的方向
    public var supportedInterfaceOrientations: UIInterfaceOrientationMask = .all
    
    public var indicatorType: IndicatorType = PhotoManager.shared.indicatorType {
        didSet {
            #if HXPICKER_ENABLE_EDITOR
            editor.indicatorType = indicatorType
            #endif
        }
    }
    
    /// 自定义相机控制器
    public var cameraViewController: CameraViewControllerProtocol.Type = CameraViewController.self
    
    /// After the photo is completed, save it to the system album
    /// 拍照完成后保存到系统相册
    public var isSaveSystemAlbum: Bool = false
    
    /// 保存到自定义相册的类型
    public var saveSystemAlbumType: AssetSaveUtil.AlbumType = .displayName
    
    /// 相机类型
    public var cameraType: CameraController.CameraType = .normal
    
    /// 相机分辨率
    public var sessionPreset: Preset = .hd1280x720
    
    /// 相机画面比例
    /// iPad无效
    public var aspectRatio: AspectRatio = ._9x16
    
    /// 摄像头默认位置
    public var position: DevicePosition = .back
    
    /// 默认闪光灯模式
    public var flashMode: AVCaptureDevice.FlashMode = .auto
    
    /// 录制视频时设置的 `AVVideoCodecType`
    /// iPhone7 以下为 `.h264`
    public var videoCodecType: AVVideoCodecType = {
        if #available(iOS 11.0, *) {
            return .h264
        } else {
            return .init(rawValue: AVVideoCodecH264)
        }
    }()
    
    /// 视频最大录制时长
    /// takePhotoMode = .click 支持不限制最大时长 (0 - 不限制)
    /// takePhotoMode = .press 最小 1
    public var videoMaximumDuration: TimeInterval = 60
    
    /// 视频最短录制时长
    public var videoMinimumDuration: TimeInterval = 1
    
    /// 拍照方式
    public var takePhotoMode: TakePhotoMode = .press
    
    /// 主题色
    public var tintColor: UIColor = .systemBlue {
        didSet {
            focusColor = tintColor
        }
    }
    
    /// 聚焦框的颜色
    public var focusColor: UIColor = .systemBlue
    
    /// 摄像头最大缩放比例
    public var videoMaxZoomScale: CGFloat = 6
    
    /// cameraType == .metal 时才有效
    /// 默认滤镜对应滤镜数组的下标，为 -1 默认不加滤镜
    public var defaultFilterIndex: Int = -1
    
    /// cameraType == .metal 时才有效
    /// 切换滤镜显示名称
    public var changeFilterShowName: Bool = true
    
    /// cameraType == .metal 时才有效
    /// 拍照时的滤镜数组，请与 videoFilters 效果保持一致
    /// 左滑/右滑切换滤镜
    public var photoFilters: [CameraFilter] = [
        InstantFilter(), Apply1977Filter(), ToasterFilter(), TransferFilter()
    ]
    
    /// cameraType == .metal 时才有效
    /// 录制视频的滤镜数组，请与 photoFilters 效果保持一致
    /// 左滑/右滑切换滤镜
    public var videoFilters: [CameraFilter] = [
        InstantFilter(), Apply1977Filter(), ToasterFilter(), TransferFilter()
    ]
    
    #if HXPICKER_ENABLE_EDITOR
    /// 允许编辑
    /// true: 拍摄完成后会跳转到编辑界面
    public var allowsEditing: Bool = true
    
    /// 编辑器配置
    public var editor: EditorConfiguration = .init()
    #endif
    
    #if HXPICKER_ENABLE_CAMERA_LOCATION
    /// 允许启动定位
    public var allowLocation: Bool = true
    #endif
    
    public init() {
        #if HXPICKER_ENABLE_EDITOR
        editor.languageType = languageType
        editor.indicatorType = indicatorType
        #endif
        
        if #available(iOS 13.0, *) {
            modalPresentationStyle = .automatic
        } else {
            modalPresentationStyle = .fullScreen
        }
    }
}

extension CameraConfiguration {
    
    public enum DevicePosition {
        /// 后置
        case back
        /// 前置
        case front
    }
    
    public enum AspectRatio {
        case fullScreen
        case _9x16
        case _16x9
        case _3x4
        case _1x1
        case custom(CGSize)
        
        var size: CGSize {
            switch self {
            case .fullScreen:
                return .init(width: -1, height: -1)
            case ._9x16:
                return .init(width: 9, height: 16)
            case ._16x9:
                return .init(width: 16, height: 9)
            case ._3x4:
                return .init(width: 3, height: 4)
            case ._1x1:
                return .init(width: 1, height: 1)
            case .custom(let size):
                return size
            }
        }
    }
    
    public enum TakePhotoMode {
        /// 长按
        case press
        /// 点击（支持不限制最大时长）
        case click
    }
    
    public enum Preset {
        case vga640x480
        case iFrame960x540
        case hd1280x720
        case hd1920x1080
        case hd4K3840x2160
        
        var system: AVCaptureSession.Preset {
            switch self {
            case .vga640x480:
                return .vga640x480
            case .iFrame960x540:
                return .iFrame960x540
            case .hd1280x720:
                return .hd1280x720
            case .hd1920x1080:
                return .hd1920x1080
            case .hd4K3840x2160:
                return .hd4K3840x2160
            }
        }
        
        var size: CGSize {
            switch self {
            case .vga640x480:
                return CGSize(width: 480, height: 640)
            case .iFrame960x540:
                return CGSize(width: 540, height: 960)
            case .hd1280x720:
                return CGSize(width: 720, height: 1280)
            case .hd1920x1080:
                return CGSize(width: 1080, height: 1920)
            case .hd4K3840x2160:
                return CGSize(width: 2160, height: 3840)
            }
        }
    }
}

#endif
