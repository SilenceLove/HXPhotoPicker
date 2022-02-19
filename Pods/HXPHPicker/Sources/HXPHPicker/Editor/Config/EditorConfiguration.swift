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
    
    public struct Filter {
        /// 滤镜信息
        public var infos: [PhotoEditorFilterInfo]
        /// 滤镜选中颜色
        public var selectedColor: UIColor
        
        /// 编辑视频时，是否加载上次滤镜效果
        /// 如果滤镜数据与上次编辑时的滤镜数据不一致会导致加载错乱
        /// 请确保滤镜数据与上一次的数据一致之后再加载
        public var isLoadLastFilter: Bool
        
        public init(
            infos: [PhotoEditorFilterInfo] = [],
            selectedColor: UIColor = HXPickerWrapper<UIColor>.systemTintColor,
            isLoadLastFilter: Bool = true
        ) {
            self.infos = infos
            self.selectedColor = selectedColor
            self.isLoadLastFilter = isLoadLastFilter
        }
    }
}

public struct EditorCropSizeConfiguration {
    
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
    
    /// 宽高比数组 [[宽, 高]]
    /// [0, 0]：自由，数组第一个会自动选中，请将第一个设置为[0, 0]
    public var aspectRatios: [[Int]] = [[0, 0], [1, 1], [3, 2], [2, 3], [4, 3], [3, 4], [16, 9], [9, 16]]
    
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
    
    /// 添加自定义颜色 - iOS14 以上有效
    public var addCustomColor: Bool = true
    
    /// 自定义默认颜色 - iOS14 以上有效
    public var customDefaultColor: UIColor = "#9EB6DC".color
    
    public init() { }
}
