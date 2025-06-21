//
//  PhotoListCellConfiguration.swift
//  HXPhotoPicker
//
//  Created by Slience on 2020/12/29.
//  Copyright © 2020 Silence. All rights reserved.
//

import UIKit

// MARK: Photo list Cell configuration class / 照片列表Cell配置类
public struct PhotoListCellConfiguration {
    
    /// Customize cell without select box
    /// Inherit PhotoPickerBaseViewCell only UIImageView, other controls need to be added by themselves
    /// Inherit PhotoPickerViewCell and modify it on the basis of its own
    /// 自定义不带选择框的cell
    /// 继承 PhotoPickerBaseViewCell 只有UIImageView，其他控件需要自己添加
    /// 继承 PhotoPickerViewCell 在自带的基础上修改
    public var customSingleCellClass: PhotoPickerBaseViewCell.Type?
    
    /// Custom cell with select box
    /// Inherit PhotoPickerBaseViewCell only UIImageView, other controls need to be added by themselves
    /// Inherit PhotoPickerViewCell with picture and type controls, select button controls need to be added by yourself
    /// Inherit PhotoPickerSelectableViewCell and modify it
    /// 自定义带选择框的cell
    /// 继承 PhotoPickerBaseViewCell 只有UIImageView，其他控件需要自己添加
    /// 继承 PhotoPickerViewCell 带有图片和类型控件，选择按钮控件需要自己添加
    /// 继承 PhotoPickerSelectableViewCell 加以修改
    public var customSelectableCellClass: PhotoPickerBaseViewCell.Type?
    
    /// Whether to show the iCloud logo if the asset is on iCloud
    /// 如果资产在iCloud上，是否显示iCloud标示
    public var isShowICloudMark: Bool = true
    
    /// 背景颜色
    public var backgroundColor: UIColor?
    
    /// Background color in dark style
    /// 暗黑风格下背景颜色
    public var backgroundDarkColor: UIColor?
    
    /// The sharpness of the thumbnail, the bigger the clearer, the smaller the blurrier
    /// 缩略图的清晰度，越大越清楚，越小越模糊
    public var targetWidth: CGFloat
    
    /// Whether to display the disabled mask when the cell is not selectable
    /// Not valid if the file size of the photo/video is limited
    /// cell在不可选择状态下是否显示禁用遮罩
    /// 如果限制了照片/视频的文件大小，则无效
    public var isShowDisableMask: Bool = true
    
    /// Whether the video cell hides the selection box when the photo and video cannot be selected at the same time and the maximum number of video selections is 1
    /// 照片视频不能同时选择并且视频最大选择数为1时视频cell是否隐藏选择框
    public var isHiddenSingleVideoSelect: Bool = true
    
    /// Spacing at the top of the selection box
    /// 选择框顶部的间距
    public var selectBoxTopMargin: CGFloat = 5
    
    /// Select the spacing to the right of the box
    /// 选择框右边的间距
    public var selectBoxRightMargin: CGFloat = 5
    
    /// Select box related configuration
    /// 选择框相关配置
    public var selectBox: SelectBoxConfiguration = .init()
    
    /// 是否显示控制`LivePhoto`禁用按钮
    public var isShowLivePhotoControl: Bool = true
    
    /// 选中`LivePhoto`时是否播放预览
    public var isPlayLivePhoto: Bool = true
    
    public var kf_indicatorColor: UIColor?
    
    public init() { 
        targetWidth = UIDevice.isPad ? 400 : min(UIScreen._width, UIScreen._height)
    }
    
    public mutating func setThemeColor(_ color: UIColor) {
        selectBox.setThemeColor(color)
    }
}
