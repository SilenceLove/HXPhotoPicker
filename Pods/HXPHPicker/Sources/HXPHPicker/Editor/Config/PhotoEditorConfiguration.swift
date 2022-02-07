//
//  PhotoEditorConfiguration.swift
//  HXPHPicker
//
//  Created by Slience on 2021/3/20.
//

import UIKit

/// 旋转会重置所有编辑效果
open class PhotoEditorConfiguration: EditorConfiguration {
    
    /// 控制画笔、贴图...导出之后清晰程度
    public var scale: CGFloat = 2
    
    /// 编辑器默认状态
    public var state: PhotoEditorViewController.State = .normal
    
    /// 编辑器固定裁剪状态
    public var fixedCropState: Bool = false
    
    /// 工具视图配置
    public lazy var toolView: EditorToolViewConfiguration = {
        let graffiti = EditorToolOptions(
            imageName: "hx_editor_tools_graffiti",
            type: .graffiti
        )
        let chartlet = EditorToolOptions(
            imageName: "hx_editor_photo_tools_emoji",
            type: .chartlet
        )
        let text = EditorToolOptions(
            imageName: "hx_editor_photo_tools_text",
            type: .text
        )
        let crop = EditorToolOptions(
            imageName: "hx_editor_photo_crop",
            type: .cropSize
        )
        let mosaic = EditorToolOptions(
            imageName: "hx_editor_tools_mosaic",
            type: .mosaic
        )
        let filter = EditorToolOptions(
            imageName: "hx_editor_tools_filter",
            type: .filter
        )
        return .init(toolOptions: [graffiti, chartlet, text, crop, mosaic, filter])
    }()
    
    /// 画笔
    public lazy var brush: EditorBrushConfiguration = .init()
    
    /// 贴图
    public lazy var chartlet: EditorChartletConfiguration = .init()
    
    /// 文本
    public lazy var text: EditorTextConfiguration = .init()
    
    /// 裁剪配置
    public lazy var cropping: EditorCropSizeConfiguration = .init()
    
    /// 裁剪确认视图配置
    public lazy var cropConfimView: CropConfirmViewConfiguration = .init()
    
    /// 滤镜配置
    public lazy var filter: Filter = .init(infos: PhotoTools.defaultFilters())
    
    /// 马赛克配置
    public lazy var mosaic: Mosaic = .init()
}

extension PhotoEditorConfiguration {
    
    public struct Mosaic {
        /// 生成马赛克的大小
        public var mosaicWidth: CGFloat = 20
        /// 涂鸦时马赛克的线宽
        public var mosaiclineWidth: CGFloat = 25
        /// 涂抹的宽度
        public var smearWidth: CGFloat = 30
        
        public init() { }
    }
}
