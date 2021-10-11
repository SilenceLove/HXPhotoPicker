//
//  SystemCameraConfiguration.swift
//  HXPHPickerExample
//
//  Created by Slience on 2020/12/29.
//  Copyright © 2020 Silence. All rights reserved.
//

import UIKit
import AVFoundation

// MARK: 相机配置类
public struct SystemCameraConfiguration {
    
    /// 媒体类型[kUTTypeImage, kUTTypeMovie]
    public var mediaTypes: [String] = []
    
    /// 视频最大录制时长
    public var videoMaximumDuration: TimeInterval = 60
    
    /// 拍摄时的视频质量
    public var videoQuality: UIImagePickerController.QualityType = .typeHigh
    
    /// 视频编辑裁剪导出的分辨率
    public var editExportPreset: ExportPreset = .ratio_960x540
    
    /// 视频编辑裁剪导出的质量
    public var editVideoQuality: Int = 6
    
    /// 默认使用后置相机
    public var cameraDevice: UIImagePickerController.CameraDevice = .rear
    
    /// 允许编辑
    public var allowsEditing: Bool = true
    
    public init() { }
}
