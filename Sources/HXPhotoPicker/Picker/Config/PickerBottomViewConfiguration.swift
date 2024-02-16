//
//  PickerBottomViewConfiguration.swift
//  HXPhotoPicker
//
//  Created by Slience on 2020/12/29.
//  Copyright © 2020 Silence. All rights reserved.
//

import UIKit

// MARK: Bottom toolbar configuration class / 底部工具栏配置类
public struct PickerBottomViewConfiguration {
    
    /// UIToolbar
    public var backgroundColor: UIColor?
    public var backgroundDarkColor: UIColor?
    
    /// UIToolbar
    public var barTintColor: UIColor?
    public var barTintDarkColor: UIColor?
    
    /// Translucent effect
    /// 半透明效果
    public var isTranslucent: Bool = true
    
    /// barStyle
    public var barStyle: UIBarStyle = UIBarStyle.default
    public var barDarkStyle: UIBarStyle = UIBarStyle.black
    
    /// hide preview button
    /// 隐藏预览按钮
    public var isHiddenPreviewButton: Bool = false
    
    /// Preview button title color
    /// 预览按钮标题颜色
    public var previewButtonTitleColor: UIColor = .systemBlue
    
    /// Preview button title color in dark style
    /// 暗黑风格下预览按钮标题颜色
    public var previewButtonTitleDarkColor: UIColor = .white
    
    /// Header color under preview button disabled
    /// 预览按钮禁用下的标题颜色
    public var previewButtonDisableTitleColor: UIColor?
    
    /// Title color under preview button disabled in dark style
    /// 暗黑风格下预览按钮禁用下的标题颜色
    public var previewButtonDisableTitleDarkColor: UIColor?
    
    /// Hide original image button
    /// 是否隐藏原图按钮
    public var isHiddenOriginalButton: Bool = false
    
    /// Original image button title color
    /// 原图按钮标题颜色
    public var originalButtonTitleColor: UIColor = .systemBlue
    
    /// Preview button title color in dark style
    /// 暗黑风格下原图按钮标题颜色
    public var originalButtonTitleDarkColor: UIColor = .white
    
    /// Display original image file size
    /// 显示原图文件大小
    public var isShowOriginalFileSize: Bool = true
    
    /// Original image loading chrysanthemum type
    /// 原图加载菊花类型
    public var originalLoadingStyle: UIActivityIndicatorView.Style = .gray
    
    /// Load the chrysanthemum type in the original image under the dark style
    /// 暗黑风格下原图加载菊花类型
    public var originalLoadingDarkStyle: UIActivityIndicatorView.Style = .white
    
    /// Original image button selection box related configuration
    /// 原图按钮选择框相关配置
    public var originalSelectBox: SelectBoxConfiguration
    
    /// Done button title color
    /// 完成按钮标题颜色
    public var finishButtonTitleColor: UIColor = .white
    
    /// Done button title color in dark style
    /// 暗黑风格下完成按钮标题颜色
    public var finishButtonTitleDarkColor: UIColor = .white
    
    /// Header color under Done button disabled
    /// 完成按钮禁用下的标题颜色
    public var finishButtonDisableTitleColor: UIColor = .white.withAlphaComponent(0.4)
    
    /// Title color under Done button disabled in dark style
    /// 暗黑风格下完成按钮禁用下的标题颜色
    public var finishButtonDisableTitleDarkColor: UIColor = .white.withAlphaComponent(0.4)
    
    /// background color when done button is selected
    /// 完成按钮选中时的背景颜色
    public var finishButtonBackgroundColor: UIColor = .systemBlue
    
    /// The background color when the Done button is selected in the dark style
    /// 暗黑风格下完成按钮选中时的背景颜色
    public var finishButtonDarkBackgroundColor: UIColor = .systemBlue
    
    /// background color when done button is disabled
    /// 完成按钮禁用时的背景颜色
    public var finishButtonDisableBackgroundColor: UIColor = .systemBlue.withAlphaComponent(0.4)
    
    /// Background color when done button is disabled in dark style
    /// 暗黑风格下完成按钮禁用时的背景颜色
    public var finishButtonDisableDarkBackgroundColor: UIColor = .systemBlue.withAlphaComponent(0.4)
    
    /// Whether to disable the finish button when no resource is selected
    /// 未选择资源时是否禁用完成按钮
    /// 视频最大选择数量为 1 时无效
    public var disableFinishButtonWhenNotSelected: Bool = true
    
    #if HXPICKER_ENABLE_EDITOR
    /// hide edit button
    /// Currently only supports preview interface display
    /// 隐藏编辑按钮
    /// 目前只支持预览界面显示
    public var isHiddenEditButton: Bool = false
    
    /// Edit button title color
    /// 编辑按钮标题颜色
    public var editButtonTitleColor: UIColor = .systemBlue
    
    /// Edit button title color in dark style
    /// 暗黑风格下编辑按钮标题颜色
    public var editButtonTitleDarkColor: UIColor = .white
    
    /// Header color under edit button disabled
    /// 编辑按钮禁用下的标题颜色
    public var editButtonDisableTitleColor: UIColor?
    public var editButtonDisableTitleDarkColor: UIColor?
    #endif
    
    /// Display a prompt when album permissions are selected
    /// 相册权限为选部分时显示提示
    public var isShowPrompt: Bool = true
    
    /// Hint icon color
    /// 提示图标颜色
    public var promptIconColor: UIColor = .systemBlue
    
    /// The color of the prompt icon in the dark style
    /// 暗黑风格下提示图标颜色
    public var promptIconDarkColor: UIColor = .systemBlue
    
    /// prompt color
    /// 提示语颜色
    public var promptTitleColor: UIColor = .systemBlue
    
    /// Prompt color in dark style
    /// 暗黑风格下提示语颜色
    public var promptTitleDarkColor: UIColor = .white
    
    /// prompt arrow color
    /// 提示语箭头颜色
    public var promptArrowColor: UIColor = .systemBlue
    
    /// The color of the prompt arrow in the dark style
    /// 暗黑风格下提示语箭头颜色
    public var promptArrowDarkColor: UIColor = .systemBlue
    
    /// 显示预览列表，优先级高于`isShowSelectedView`
    public var isShowPreviewList: Bool = true
    
    public var previewListTickColor: UIColor = .white
    public var previewListTickBgColor: UIColor = .systemBlue
    public var previewListTickDarkColor: UIColor = .white
    public var previewListTickBgDarkColor: UIColor = .systemBlue
    
    /// Show selected resources
    /// 显示已选资源
    public var isShowSelectedView: Bool = true
    
    /// Custom cell, inherit PhotoPreviewSelectedViewCell and modify it
    /// 自定义cell，继承 PhotoPreviewSelectedViewCell 加以修改
    public var customSelectedViewCellClass: PhotoPreviewSelectedViewCell.Type?
    
    /// The selected tick color of the selected resource
    /// 已选资源选中的勾勾颜色
    public var selectedViewTickColor: UIColor = .systemBlue
    public var selectedViewTickDarkColor: UIColor = .systemBlue
    
    public init() {
        var boxConfig = SelectBoxConfiguration()
        boxConfig.style = .tick
        // The width of the border when the original image button is not selected
        // 原图按钮未选中时的边框宽度
        boxConfig.borderWidth = 1
        // The border color of the original image button when it is not selected
        // 原图按钮未选中时的边框颜色
        boxConfig.borderColor = .systemBlue
        // The border color of the original image button when the dark style is not selected
        // 暗黑风格下原图按钮未选中时的边框颜色
        boxConfig.borderDarkColor = .white
        // The color in the middle of the frame when the original image button is not selected
        // 原图按钮未选中时框框中间的颜色
        boxConfig.backgroundColor = UIColor.white.withAlphaComponent(0.3)
        // The width of the tick when the original image button is selected
        // 原图按钮选中时的勾勾宽度
        boxConfig.tickWidth = 1
        self.originalSelectBox = boxConfig
    }
    
    public mutating func setThemeColor(_ color: UIColor) {
        originalSelectBox.setThemeColor(color)
        originalSelectBox.borderColor = color
        previewButtonTitleColor = color
        originalButtonTitleColor = color
        finishButtonBackgroundColor = color
        finishButtonDarkBackgroundColor = color
        finishButtonDisableBackgroundColor = color.withAlphaComponent(0.4)
        finishButtonDisableDarkBackgroundColor = color.withAlphaComponent(0.4)
        #if HXPICKER_ENABLE_EDITOR
        editButtonTitleColor = color
        #endif
        promptIconColor = color
        promptIconDarkColor = color
        promptTitleColor = color
        promptArrowColor = color
        promptArrowDarkColor = color
        previewListTickBgColor = color
        previewListTickBgDarkColor = color
        selectedViewTickColor = color
        selectedViewTickDarkColor = color
    }
}
