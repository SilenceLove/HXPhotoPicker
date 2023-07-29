//
//  CameraConfiguration.swift
//  HXPhotoPicker
//
//  Created by Slience on 2021/8/30.
//

import UIKit
import AVFoundation

// MARK: 相机配置类
#if targetEnvironment(macCatalyst)
@available(macCatalyst 14.0, *)
#endif
public struct CameraConfiguration: IndicatorTypeConfig {
    
    public var modalPresentationStyle: UIModalPresentationStyle
    
    /// If the built-in language is not enough, you can add a custom language text
    /// PhotoManager.shared.customLanguages - custom language array
    /// PhotoManager.shared.fixedCustomLanguage - If there are multiple custom languages, one can be fixed to display
    /// 如果自带的语言不够，可以添加自定义的语言文字
    /// PhotoManager.shared.customLanguages - 自定义语言数组
    /// PhotoManager.shared.fixedCustomLanguage - 如果有多种自定义语言，可以固定显示某一种
    public var languageType: LanguageType = .system {
        didSet {
            #if HXPICKER_ENABLE_EDITOR
            editor.languageType = languageType
            #endif
        }
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
    
    /// After the photo is completed, save it to the system album
    /// 拍照完成后保存到系统相册
    public var isSaveSystemAlbum: Bool = false
    
    /// 相机类型
    public var cameraType: CameraController.CameraType = .normal
    
    /// 相机分辨率
    public var sessionPreset: Preset = .hd1280x720
    
    /// 摄像头默认位置
    public var position: DevicePosition = .back
    
    /// 默认闪光灯模式
    public var flashMode: AVCaptureDevice.FlashMode = .auto
    
    /// 录制视频时设置的 `AVVideoCodecType`
    /// iPhone7 以下为 `.h264`
    public var videoCodecType: AVVideoCodecType = {
        #if targetEnvironment(macCatalyst)
        return .h264
        #else
        if #available(iOS 11.0, *) {
            return .h264
        } else {
            return .init(rawValue: AVVideoCodecH264)
        }
        #endif
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
    public var tintColor: UIColor = HXPickerWrapper<UIColor>.systemTintColor
    
    /// 摄像头最大缩放比例
    public var videoMaxZoomScale: CGFloat = 6
    
    /// 默认滤镜对应滤镜数组的下标，为 -1 默认不加滤镜
    public var defaultFilterIndex: Int = -1
    
    /// 切换滤镜显示名称
    public var changeFilterShowName: Bool = true
    
    /// 拍照时的滤镜数组，请与 videoFilters 效果保持一致
    /// 左滑/右滑切换滤镜
    public lazy var photoFilters: [CameraFilter] = [
        InstantFilter(), Apply1977Filter(), ToasterFilter(), TransferFilter()
    ]
    
    /// 录制视频的滤镜数组，请与 photoFilters 效果保持一致
    /// 左滑/右滑切换滤镜
    public lazy var videoFilters: [CameraFilter] = [
        InstantFilter(), Apply1977Filter(), ToasterFilter(), TransferFilter()
    ]
    
    #if HXPICKER_ENABLE_EDITOR
    /// 允许编辑
    /// true: 拍摄完成后会跳转到编辑界面
    public var allowsEditing: Bool = true
    
    /// 编辑器配置
    public lazy var editor: EditorConfiguration = {
        var editor = EditorConfiguration()
        editor.languageType = languageType
        editor.indicatorType = indicatorType
        return editor
    }()
    #endif
    
    #if HXPICKER_ENABLE_CAMERA_LOCATION
    /// 允许启动定位
    public var allowLocation: Bool = true
    #endif
    
    public init() {
        #if targetEnvironment(macCatalyst)
        modalPresentationStyle = .automatic
        #else
        if #available(iOS 13.0, *) {
            modalPresentationStyle = .automatic
        } else {
            modalPresentationStyle = .fullScreen
        }
        #endif
    }
}

#if targetEnvironment(macCatalyst)
@available(macCatalyst 14.0, *)
#endif
extension CameraConfiguration {
    
    public enum DevicePosition {
        /// 后置
        case back
        /// 前置
        case front
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
