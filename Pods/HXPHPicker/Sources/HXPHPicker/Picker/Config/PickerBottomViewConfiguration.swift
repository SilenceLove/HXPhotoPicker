//
//  PickerBottomViewConfiguration.swift
//  HXPHPickerExample
//
//  Created by Slience on 2020/12/29.
//  Copyright © 2020 Silence. All rights reserved.
//

import UIKit

// MARK: 底部工具栏配置类
public struct PickerBottomViewConfiguration {
    
    /// UIToolbar
    public var backgroundColor: UIColor?
    public var backgroundDarkColor: UIColor?
    
    /// UIToolbar
    public var barTintColor: UIColor?
    public var barTintDarkColor: UIColor?
    
    /// 半透明效果
    public var isTranslucent: Bool = true
    
    /// barStyle
    public var barStyle: UIBarStyle = UIBarStyle.default
    public var barDarkStyle: UIBarStyle = UIBarStyle.black
    
    /// 隐藏预览按钮
    public var previewButtonHidden: Bool = false
    
    /// 预览按钮标题颜色
    public var previewButtonTitleColor: UIColor = .systemTintColor
    
    /// 暗黑风格下预览按钮标题颜色
    public var previewButtonTitleDarkColor: UIColor = .systemTintColor
    
    /// 预览按钮禁用下的标题颜色
    public var previewButtonDisableTitleColor: UIColor?
    
    /// 暗黑风格下预览按钮禁用下的标题颜色
    public var previewButtonDisableTitleDarkColor: UIColor?
    
    /// 隐藏原图按钮
    public var originalButtonHidden: Bool = false
    
    /// 原图按钮标题颜色
    public var originalButtonTitleColor: UIColor = .systemTintColor
    
    /// 暗黑风格下预览按钮标题颜色
    public var originalButtonTitleDarkColor: UIColor = .systemTintColor
    
    /// 显示原图文件大小
    public var showOriginalFileSize: Bool = true
    
    /// 原图加载菊花类型
    public var originalLoadingStyle: UIActivityIndicatorView.Style = .gray
    
    /// 暗黑风格下原图加载菊花类型
    public var originalLoadingDarkStyle: UIActivityIndicatorView.Style = .white
    
    /// 原图按钮选择框相关配置
    public var originalSelectBox: SelectBoxConfiguration
    
    /// 完成按钮标题颜色
    public var finishButtonTitleColor: UIColor = .white
    
    /// 暗黑风格下完成按钮标题颜色
    public var finishButtonTitleDarkColor: UIColor = .white
    
    /// 完成按钮禁用下的标题颜色
    public var finishButtonDisableTitleColor: UIColor = .white.withAlphaComponent(0.4)
    
    /// 暗黑风格下完成按钮禁用下的标题颜色
    public var finishButtonDisableTitleDarkColor: UIColor = .white.withAlphaComponent(0.4)
    
    /// 完成按钮选中时的背景颜色
    public var finishButtonBackgroundColor: UIColor = .systemTintColor
    
    /// 暗黑风格下完成按钮选中时的背景颜色
    public var finishButtonDarkBackgroundColor: UIColor = .systemTintColor
    
    /// 完成按钮禁用时的背景颜色
    public var finishButtonDisableBackgroundColor: UIColor = .systemTintColor.withAlphaComponent(0.4)
    
    /// 暗黑风格下完成按钮禁用时的背景颜色
    public var finishButtonDisableDarkBackgroundColor: UIColor = .systemTintColor.withAlphaComponent(0.4)
    
    /// 未选择资源时是否禁用完成按钮
    public var disableFinishButtonWhenNotSelected: Bool = true
    
    #if HXPICKER_ENABLE_EDITOR
    /// 隐藏编辑按钮
    /// 目前只支持预览界面显示
    public var editButtonHidden: Bool = true
    
    /// 编辑按钮标题颜色
    public var editButtonTitleColor: UIColor = .systemTintColor
    
    /// 暗黑风格下编辑按钮标题颜色
    public var editButtonTitleDarkColor: UIColor = .systemTintColor
    
    /// 编辑按钮禁用下的标题颜色
    public var editButtonDisableTitleColor: UIColor?
    public var editButtonDisableTitleDarkColor: UIColor?
    #endif
    
    /// 相册权限为选部分时显示提示
    public var showPrompt: Bool = true
    
    /// 提示图标颜色
    public var promptIconColor: UIColor = .systemTintColor
    
    /// 暗黑风格下提示图标颜色
    public var promptIconDarkColor: UIColor = .systemTintColor
    
    /// 提示语颜色
    public var promptTitleColor: UIColor = .systemTintColor
    
    /// 暗黑风格下提示语颜色
    public var promptTitleDarkColor: UIColor = .systemTintColor
    
    /// 提示语颜色
    public var promptArrowColor: UIColor = .systemTintColor
    
    /// 暗黑风格下提示语颜色
    public var promptArrowDarkColor: UIColor = .systemTintColor
    
    /// 显示已选资源
    public var showSelectedView: Bool = false
    
    /// 自定义cell，继承 PhotoPreviewSelectedViewCell 加以修改
    public var customSelectedViewCellClass: PhotoPreviewSelectedViewCell.Type?
    
    /// 已选资源选中的勾勾颜色
    public var selectedViewTickColor: UIColor = .white
    
    public init() {
        var boxConfig = SelectBoxConfiguration.init()
        boxConfig.style = .tick
        // 原图按钮选中时的背景颜色
        boxConfig.selectedBackgroundColor = .systemTintColor
        // 暗黑风格下原图按钮选中时的背景颜色
        boxConfig.selectedBackgroudDarkColor = .systemTintColor
        // 原图按钮未选中时的边框宽度
        boxConfig.borderWidth = 1
        // 原图按钮未选中时的边框颜色
        boxConfig.borderColor = .systemTintColor
        // 暗黑风格下原图按钮未选中时的边框颜色
        boxConfig.borderDarkColor = .systemTintColor
        // 原图按钮未选中时框框中间的颜色
        boxConfig.backgroundColor = UIColor.white.withAlphaComponent(0.3)
        // 原图按钮选中时的勾勾宽度
        boxConfig.tickWidth = 1
        self.originalSelectBox = boxConfig
    }
}
