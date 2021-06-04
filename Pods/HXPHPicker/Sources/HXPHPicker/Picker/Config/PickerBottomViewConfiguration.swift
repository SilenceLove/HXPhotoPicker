//
//  PickerBottomViewConfiguration.swift
//  HXPHPickerExample
//
//  Created by Slience on 2020/12/29.
//  Copyright © 2020 Silence. All rights reserved.
//

import UIKit

// MARK: 底部工具栏配置类
public class PickerBottomViewConfiguration {
    
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
    public lazy var previewButtonTitleColor: UIColor = {
        return .systemTintColor
    }()
    
    /// 暗黑风格下预览按钮标题颜色
    public lazy var previewButtonTitleDarkColor: UIColor = {
        return .white
    }()
    
    /// 预览按钮禁用下的标题颜色
    public var previewButtonDisableTitleColor: UIColor?
    
    /// 暗黑风格下预览按钮禁用下的标题颜色
    public var previewButtonDisableTitleDarkColor: UIColor?
    
    /// 隐藏原图按钮
    public var originalButtonHidden : Bool = false
    
    /// 原图按钮标题颜色
    public lazy var originalButtonTitleColor: UIColor = {
        return .systemTintColor
    }()
    
    /// 暗黑风格下预览按钮标题颜色
    public lazy var originalButtonTitleDarkColor: UIColor = {
        return .white
    }()
    /// 显示原图文件大小
    public var showOriginalFileSize: Bool = true
    
    /// 原图加载菊花类型
    public var originalLoadingStyle : UIActivityIndicatorView.Style = .gray
    
    /// 暗黑风格下原图加载菊花类型
    public var originalLoadingDarkStyle : UIActivityIndicatorView.Style = .white
    
    /// 原图按钮选择框相关配置
    public lazy var originalSelectBox: SelectBoxConfiguration = {
        let config = SelectBoxConfiguration.init()
        config.style = .tick
        // 原图按钮选中时的背景颜色
        config.selectedBackgroundColor = .systemTintColor
        // 暗黑风格下原图按钮选中时的背景颜色
        config.selectedBackgroudDarkColor = UIColor.white
        // 原图按钮未选中时的边框宽度
        config.borderWidth = 1
        // 原图按钮未选中时的边框颜色
        config.borderColor = config.selectedBackgroundColor
        // 暗黑风格下原图按钮未选中时的边框颜色
        config.borderDarkColor = UIColor.white
        // 原图按钮未选中时框框中间的颜色
        config.backgroundColor = UIColor.white.withAlphaComponent(0.3)
        // 原图按钮选中时的勾勾宽度
        config.tickWidth = 1
        return config
    }()
    
    /// 完成按钮标题颜色
    public lazy var finishButtonTitleColor: UIColor = {
        return UIColor.white
    }()
    
    /// 暗黑风格下完成按钮标题颜色
    public lazy var finishButtonTitleDarkColor: UIColor = {
        return .black
    }()
    
    /// 完成按钮禁用下的标题颜色
    public lazy var finishButtonDisableTitleColor: UIColor = {
        return UIColor.white.withAlphaComponent(0.6)
    }()
    
    /// 暗黑风格下完成按钮禁用下的标题颜色
    public lazy var finishButtonDisableTitleDarkColor: UIColor = {
        return UIColor.black.withAlphaComponent(0.6)
    }()
    
    /// 完成按钮选中时的背景颜色
    public lazy var finishButtonBackgroundColor: UIColor = {
        return .systemTintColor
    }()
    
    /// 暗黑风格下完成按钮选中时的背景颜色
    public lazy var finishButtonDarkBackgroundColor: UIColor = {
        return .white
    }()
    
    /// 完成按钮禁用时的背景颜色
    public lazy var finishButtonDisableBackgroundColor: UIColor = {
        return .systemTintColor
    }()
    
    /// 暗黑风格下完成按钮禁用时的背景颜色
    public lazy var finishButtonDisableDarkBackgroundColor: UIColor = {
        return UIColor.white.withAlphaComponent(0.4)
    }()
    
    /// 未选择资源时是否禁用完成按钮
    public var disableFinishButtonWhenNotSelected: Bool = true
    
    #if HXPICKER_ENABLE_EDITOR
    /// 隐藏编辑按钮
    /// 目前只支持预览界面显示
    public var editButtonHidden: Bool = true
    
    /// 编辑按钮标题颜色
    public lazy var editButtonTitleColor: UIColor = {
        return .systemTintColor
    }()
    
    /// 暗黑风格下编辑按钮标题颜色
    public lazy var editButtonTitleDarkColor: UIColor = {
        return .white
    }()
    
    /// 编辑按钮禁用下的标题颜色
    public var editButtonDisableTitleColor: UIColor?
    public var editButtonDisableTitleDarkColor: UIColor?
    #endif
    
    /// 相册权限为选部分时显示提示
    public var showPrompt: Bool = true
    
    /// 提示图标颜色
    public lazy var promptIconColor: UIColor = {
        return .systemTintColor
    }()
    
    /// 暗黑风格下提示图标颜色
    public lazy var promptIconDarkColor: UIColor = {
        return .white
    }()
    
    /// 提示语颜色
    public lazy var promptTitleColor: UIColor = {
        return .systemTintColor
    }()
    
    /// 暗黑风格下提示语颜色
    public lazy var promptTitleDarkColor: UIColor = {
        return .white
    }()
    
    /// 提示语颜色
    public lazy var promptArrowColor: UIColor = {
        return .systemTintColor
    }()
    
    /// 暗黑风格下提示语颜色
    public lazy var promptArrowDarkColor: UIColor = {
        return .white
    }()
    
    /// 显示已选资源
    public var showSelectedView: Bool = false
    
    /// 自定义cell，继承 PhotoPreviewSelectedViewCell 加以修改
    public var customSelectedViewCellClass: PhotoPreviewSelectedViewCell.Type?
    
    /// 已选资源选中的勾勾颜色
    public lazy var selectedViewTickColor: UIColor = {
        return .white
    }()
    
    public init() { }
}
