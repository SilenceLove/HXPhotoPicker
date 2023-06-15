//
//  SystemCameraConfiguration.swift
//  HXPhotoPicker
//
//  Created by Slience on 2020/12/29.
//  Copyright © 2020 Silence. All rights reserved.
//

import UIKit
import AVFoundation

// MARK: System camera configuration class / 系统相机配置类
public struct SystemCameraConfiguration {
     
    /// 媒体类型
    /// [kUTTypeImage, kUTTypeMovie]
    public var mediaTypes: [String] = []
    
    /// Maximum video recording time
    /// 视频最大录制时长
    public var videoMaximumDuration: TimeInterval = 60
    
    /// Video quality at the time of shooting
    /// 拍摄时的视频质量
    public var videoQuality: UIImagePickerController.QualityType = .typeHigh
    
    /// Video Editing Crop Export Resolution
    /// 视频编辑裁剪导出的分辨率
    public var editExportPreset: ExportPreset = .ratio_960x540
    
    /// Video Editing Cropping Export Quality
    /// 视频编辑裁剪导出的质量
    public var editVideoQuality: Int = 6
    
    /// Use the rear camera by default
    /// 默认使用后置相机
    public var cameraDevice: UIImagePickerController.CameraDevice = .rear
    
    /// allow editing
    /// 允许编辑
    public var allowsEditing: Bool = true
    
    public init() { }
}
