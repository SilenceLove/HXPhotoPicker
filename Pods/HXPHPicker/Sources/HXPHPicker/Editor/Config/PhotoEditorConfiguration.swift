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
            type: .cropping
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
    public lazy var brush: BrushConfig = .init()
    
    /// 贴图
    public lazy var chartlet: EditorChartletConfig = .init()
    
    /// 文本
    public lazy var text: EditorTextConfig = .init()
    
    /// 裁剪配置
    public lazy var cropping: PhotoCroppingConfiguration = .init()
    
    /// 裁剪确认视图配置
    public lazy var cropConfimView: CropConfirmViewConfiguration = .init()
    
    /// 滤镜配置
    public lazy var filter: FilterConfig = .init(infos: PhotoTools.defaultFilters())
    
    /// 马赛克配置
    public lazy var mosaic: MosaicConfig = .init()
    
    public struct BrushConfig {
        
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
    
    public struct MosaicConfig {
        /// 生成马赛克的大小
        public var mosaicWidth: CGFloat = 20
        /// 涂鸦时马赛克的线宽
        public var mosaiclineWidth: CGFloat = 25
        /// 涂抹的宽度
        public var smearWidth: CGFloat = 30
        
        public init() { }
    }
    
    public struct FilterConfig {
        /// 滤镜信息
        public var infos: [PhotoEditorFilterInfo]
        /// 滤镜选中颜色
        public var selectedColor: UIColor
        public init(
            infos: [PhotoEditorFilterInfo] = [],
            selectedColor: UIColor = .systemTintColor
        ) {
            self.infos = infos
            self.selectedColor = selectedColor
        }
    }
}
