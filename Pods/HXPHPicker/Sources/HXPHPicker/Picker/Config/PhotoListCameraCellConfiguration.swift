//
//  PhotoListCameraCellConfiguration.swift
//  HXPHPickerExample
//
//  Created by Slience on 2020/12/29.
//  Copyright © 2020 Silence. All rights reserved.
//

import UIKit

// MARK: 照片列表相机Cell配置类
public struct PhotoListCameraCellConfiguration {
    
    /// 允许相机预览
    public var allowPreview: Bool = true
    
    /// 背景颜色
    public var backgroundColor: UIColor?
    
    /// 暗黑风格下背景颜色
    public var backgroundDarkColor: UIColor?
    
    /// 相机图标
    public var cameraImageName: String = "hx_picker_photoList_photograph"
    
    /// 暗黑风格下的相机图标 / 相机预览成功之后的图标
    public var cameraDarkImageName: String = "hx_picker_photoList_photograph_white"
    
    public init() { }
}
