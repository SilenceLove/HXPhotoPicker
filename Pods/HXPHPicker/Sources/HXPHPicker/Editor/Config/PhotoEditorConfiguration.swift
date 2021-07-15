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
        let graffiti = EditorToolOptions(imageName: "hx_editor_tools_graffiti",
                                               type: .graffiti)
        let crop = EditorToolOptions(imageName: "hx_editor_photo_crop",
                                           type: .cropping)
        let mosaic = EditorToolOptions(imageName: "hx_editor_tools_mosaic",
                                             type: .mosaic)
        let filter = EditorToolOptions(imageName: "hx_editor_tools_filter",
                                             type: .filter)
        config.toolOptions = [graffiti, crop, mosaic, filter]
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
    
    /// 滤镜配置
    public lazy var filterConfig: FilterConfig = .init(infos: PhotoTools.defaultFilters())
    
    public struct FilterConfig {
        /// 滤镜信息
        public let infos: [PhotoEditorFilterInfo]
        /// 滤镜选中颜色
        public let selectedColor: UIColor
        public init(infos: [PhotoEditorFilterInfo],
                    selectedColor: UIColor = .systemTintColor) {
            self.infos = infos
            self.selectedColor = selectedColor
        }
    }
    
    /// 马赛克配置
    public lazy var mosaicConfig: MosaicConfig = .init(mosaicWidth: 20,
                                                       mosaiclineWidth: 25,
                                                       smearWidth: 30)
    
    public struct MosaicConfig {
        /// 生成马赛克的大小
        public let mosaicWidth: CGFloat
        /// 涂鸦时马赛克的线宽
        public let mosaiclineWidth: CGFloat
        /// 涂抹的宽度
        public let smearWidth: CGFloat
    }
}
