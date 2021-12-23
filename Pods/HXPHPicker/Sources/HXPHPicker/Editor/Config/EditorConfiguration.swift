//
//  EditorConfiguration.swift
//  HXPHPicker
//
//  Created by Slience on 2021/1/9.
//

import UIKit

open class EditorConfiguration: BaseConfiguration {
    
    public override init() {
        super.init()
        prefersStatusBarHidden = true
    }
}

public struct EditorCropSizeConfiguration {
    
    /// 圆形裁剪框（裁剪图片时有效）
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

public struct EditorBrushConfiguration {
    
    /// 画笔颜色数组
    public var colors: [String] = PhotoTools.defaultColors()
    
    /// 默认画笔颜色索引
    public var defaultColorIndex: Int = 2
    
    /// 初始画笔宽度
    public var lineWidth: CGFloat = 5
    
    /// 画笔最大宽度
    public var maximumLinewidth: CGFloat = 20
    
    /// 画笔最小宽度
    public var minimumLinewidth: CGFloat = 2
    
    /// 显示画笔尺寸大小滑动条
    public var showSlider: Bool = true
    
    public init() { }
}
