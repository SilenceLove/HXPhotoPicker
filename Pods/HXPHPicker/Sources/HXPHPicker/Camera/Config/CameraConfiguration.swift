//
//  CameraConfiguration.swift
//  HXPHPicker
//
//  Created by Slience on 2021/8/30.
//

import UIKit
import AVFoundation

// MARK: 相机配置类
public class CameraConfiguration: BaseConfiguration {
    
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
    public var videoCodecType: AVVideoCodecType = .h264
    
    /// 视频最大录制时长
    /// takePhotoMode = .click 支持不限制最大时长 (0 - 不限制)
    /// takePhotoMode = .press 最小 1
    public var videoMaximumDuration: TimeInterval = 60
    
    /// 视频最短录制时长
    public var videoMinimumDuration: TimeInterval = 1
    
    /// 拍照方式
    public var takePhotoMode: TakePhotoMode = .press
    
    /// 主题色
    public var tintColor: UIColor = .systemTintColor {
        didSet {
            #if HXPICKER_ENABLE_EDITOR
            setupEditorColor()
            #endif
        }
    }
    
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
    
    /// 照片编辑器配置
    public lazy var photoEditor: PhotoEditorConfiguration = .init()
    
    /// 视频编辑器配置
    public lazy var videoEditor: VideoEditorConfiguration = .init()
    #endif
    
    /// 允许启动定位
    public var allowLocation: Bool = true
    
    public override init() {
        super.init()
        /// shouldAutorotate 能够旋转
        /// supportedInterfaceOrientations 支持的方向
        
        /// 隐藏状态栏
        prefersStatusBarHidden = true
        
        appearanceStyle = .normal
        #if HXPICKER_ENABLE_EDITOR
        photoEditor.languageType = languageType
        videoEditor.languageType = languageType
        photoEditor.indicatorType = indicatorType
        videoEditor.indicatorType = indicatorType
        photoEditor.appearanceStyle = appearanceStyle
        videoEditor.appearanceStyle = appearanceStyle
        #endif
    }
    
    #if HXPICKER_ENABLE_EDITOR
    public override var languageType: LanguageType {
        didSet {
            photoEditor.languageType = languageType
            videoEditor.languageType = languageType
        }
    }
    public override var indicatorType: BaseConfiguration.IndicatorType {
        didSet {
            photoEditor.indicatorType = indicatorType
            videoEditor.indicatorType = indicatorType
        }
    }
    public override var appearanceStyle: AppearanceStyle {
        didSet {
            photoEditor.appearanceStyle = appearanceStyle
            videoEditor.appearanceStyle = appearanceStyle
        }
    }
    #endif
}

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
    
    #if HXPICKER_ENABLE_EDITOR
    fileprivate func setupEditorColor() {
        
        videoEditor.cropConfirmView.finishButtonBackgroundColor = tintColor
        videoEditor.cropConfirmView.finishButtonDarkBackgroundColor = tintColor
        videoEditor.cropSize.aspectRatioSelectedColor = tintColor
        videoEditor.toolView.finishButtonBackgroundColor = tintColor
        videoEditor.toolView.finishButtonDarkBackgroundColor = tintColor
        videoEditor.toolView.toolSelectedColor = tintColor
        videoEditor.toolView.musicSelectedColor = tintColor
        videoEditor.music.tintColor = tintColor
        videoEditor.text.tintColor = tintColor
        videoEditor.filter = .init(
            infos: videoEditor.filter.infos,
            selectedColor: tintColor
        )
        
        photoEditor.toolView.toolSelectedColor = tintColor
        photoEditor.toolView.finishButtonBackgroundColor = tintColor
        photoEditor.toolView.finishButtonDarkBackgroundColor = tintColor
        photoEditor.cropConfimView.finishButtonBackgroundColor = tintColor
        photoEditor.cropConfimView.finishButtonDarkBackgroundColor = tintColor
        photoEditor.cropping.aspectRatioSelectedColor = tintColor
        photoEditor.filter = .init(
            infos: photoEditor.filter.infos,
            selectedColor: tintColor
        )
        photoEditor.text.tintColor = tintColor
    }
    #endif
}
