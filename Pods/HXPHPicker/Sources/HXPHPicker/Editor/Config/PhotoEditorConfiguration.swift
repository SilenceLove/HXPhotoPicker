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
        let config = EditorToolViewConfiguration.init()
        let graffiti = EditorToolOptions(imageName: "hx_editor_tools_graffiti",
                                         type: .graffiti)
        let chartlet = EditorToolOptions(imageName: "hx_editor_photo_tools_emoji",
                                         type: .chartlet)
        let text = EditorToolOptions(imageName: "hx_editor_photo_tools_text",
                                         type: .text)
        let crop = EditorToolOptions(imageName: "hx_editor_photo_crop",
                                     type: .cropping)
        let mosaic = EditorToolOptions(imageName: "hx_editor_tools_mosaic",
                                       type: .mosaic)
        let filter = EditorToolOptions(imageName: "hx_editor_tools_filter",
                                       type: .filter)
        config.toolOptions = [graffiti, chartlet, text, crop, mosaic, filter]
        return config
    }()
    
    /// 画笔颜色数组
    public lazy var brushColors: [String] = PhotoTools.defaultColors()
    
    /// 默认画笔颜色索引
    public var defaultBrushColorIndex: Int = 2
    
    /// 画笔宽度
    public var brushLineWidth: CGFloat = 5
    
    /// 贴图
    public lazy var chartlet: ChartletConfig = .init()
    
    public class ChartletConfig {
        public enum LoadScene {
            /// cell显示时
            case cellDisplay
            /// 滚动停止时
            case scrollStop
        }
        /// 弹窗高度
        public var viewHeight: CGFloat = UIScreen.main.bounds.height * 0.5
        /// 每行显示个数
        public var rowCount: Int = UIDevice.isPad ? 6 : 5
        /// 加载时机
        public var loadScene: LoadScene = .cellDisplay
        /// 贴图标题
        public var titles: [EditorChartlet] = []
    }
    
    /// 文本
    public lazy var text: TextConfig = .init()
    
    public class TextConfig {
        /// 文本颜色数组
        public lazy var colors: [String] = PhotoTools.defaultColors()
        /// 确定按钮背景颜色、文本光标颜色
        public lazy var tintColor: UIColor = .systemTintColor
        /// 文本字体
        public lazy var font: UIFont = .boldSystemFont(ofSize: 25)
        /// 最大字数限制，0为不限制
        public var maximumLimitTextLength: Int = 0
        /// 文本视图推出样式
        public lazy var modalPresentationStyle: UIModalPresentationStyle = {
            if #available(iOS 13.0, *) {
                return .automatic
            } else {
                return .fullScreen
            }
        }()
        
        public init() { }
    }
    
    /// 裁剪配置
    public lazy var cropping: PhotoCroppingConfiguration = .init()
    
    /// 裁剪确认视图配置
    public lazy var cropConfimView: CropConfirmViewConfiguration = .init()
    
    /// 滤镜配置
    public lazy var filter: FilterConfig = .init(infos: PhotoTools.defaultFilters())
    
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
    public lazy var mosaic: MosaicConfig = .init(mosaicWidth: 20,
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
