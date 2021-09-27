//
//  PhotoCroppingConfiguration.swift
//  HXPHPicker
//
//  Created by Slience on 2021/4/13.
//

import UIKit

public struct PhotoCroppingConfiguration {
    
    /// 圆形裁剪框
    public var isRoundCrop: Bool = false
    
    /// 固定比例
    public var fixedRatio: Bool = false
    
    /// 默认宽高比
    public var aspectRatioType: AspectRatioType = .original
    
    /// 裁剪时遮罩类型
    public var maskType: EditorImageResizerMaskView.MaskType = .darkBlurEffect
    
    /// 宽高比选中颜色
    public var aspectRatioSelectedColor: UIColor = .systemTintColor
    
    public init() { }
}
