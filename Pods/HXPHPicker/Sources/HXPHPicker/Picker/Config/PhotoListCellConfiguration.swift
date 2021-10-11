//
//  PhotoListCellConfiguration.swift
//  HXPHPickerExample
//
//  Created by Slience on 2020/12/29.
//  Copyright © 2020 Silence. All rights reserved.
//

import UIKit

// MARK: 照片列表Cell配置类
public struct PhotoListCellConfiguration {
    
    /// 自定义不带选择框的cell
    /// 继承 PhotoPickerBaseViewCell 只有UIImageView，其他控件需要自己添加
    /// 继承 PhotoPickerViewCell 在自带的基础上修改
    public var customSingleCellClass: PhotoPickerBaseViewCell.Type?
    
    /// 自定义带选择框的cell
    /// 继承 PhotoPickerBaseViewCell 只有UIImageView，其他控件需要自己添加
    /// 继承 PhotoPickerViewCell 带有图片和类型控件，选择按钮控件需要自己添加
    /// 继承 PhotoPickerSelectableViewCell 加以修改
    public var customSelectableCellClass: PhotoPickerBaseViewCell.Type?
    
    /// 背景颜色
    public var backgroundColor: UIColor?
    
    /// 暗黑风格下背景颜色
    public var backgroundDarkColor: UIColor?
    
    /// 缩略图的清晰度，越大越清楚，越小越模糊
    /// 默认为 250
    public var targetWidth: CGFloat = 250
    
    /// cell在不可选择状态下是否显示禁用遮罩
    /// 如果限制了照片/视频的文件大小，则无效
    public var showDisableMask: Bool = true
    
    /// 选择框顶部的间距
    public var selectBoxTopMargin: CGFloat = 5
    
    /// 选择框右边的间距
    public var selectBoxRightMargin: CGFloat = 5
    
    /// 选择框相关配置
    public var selectBox: SelectBoxConfiguration = .init()
    
    public init() { }
}
