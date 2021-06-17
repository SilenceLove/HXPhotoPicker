//
//  PhotoEditorConfiguration.swift
//  HXPHPicker
//
//  Created by Slience on 2021/3/20.
//

import UIKit

/// 旋转会重置所有编辑效果
open class PhotoEditorConfiguration: EditorConfiguration {
    
    /// 编辑器默认状态
    public var state: PhotoEditorViewController.State = .normal
    
    /// 编辑器固定裁剪状态
    public var fixedCropState: Bool = false
    
    /// 工具视图配置
    public lazy var toolView: EditorToolViewConfiguration = {
        let config = EditorToolViewConfiguration.init()
        let graffitiOption = EditorToolOptions.init(imageName: "hx_editor_tools_graffiti", type: .graffiti)
        let cropOption = EditorToolOptions.init(imageName: "hx_editor_photo_crop", type: .cropping)
        let options: [EditorToolOptions] = [graffitiOption, cropOption]
        config.toolOptions = options
        return config
    }()
    
    /// 画笔颜色数组
    public lazy var brushColors: [String] = ["#ffffff", "#2B2B2B", "#FA5150", "#FEC200", "#07C160", "#10ADFF", "#6467EF"]
    
    /// 默认画笔颜色索引
    public var defaultBrushColorIndex: Int = 2
    
    /// 画笔宽度
    public var brushLineWidth: CGFloat = 5
    
    /// 裁剪配置
    public lazy var cropConfig: PhotoCroppingConfiguration = .init()
    
    /// 裁剪确认视图配置
    public lazy var cropConfimView: CropConfirmViewConfiguration = .init()
     
}
