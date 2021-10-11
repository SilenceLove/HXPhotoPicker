//
//  NotAuthorizedConfiguration.swift
//  HXPHPickerExample
//
//  Created by Slience on 2020/12/29.
//  Copyright © 2020 Silence. All rights reserved.
//

import UIKit

// MARK: 未授权界面配置类
public struct NotAuthorizedConfiguration {
    
    /// 背景颜色
    public var backgroundColor: UIColor = .white
    
    /// 暗黑风格下的背景颜色
    public var darkBackgroundColor: UIColor = "#2E2F30".color
    
    /// 关闭按钮图片名
    public var closeButtonImageName: String = "hx_picker_notAuthorized_close"
    
    /// 暗黑风格下的关闭按钮图片名
    public var closeButtonDarkImageName: String = "hx_picker_notAuthorized_close_dark"

    /// 隐藏关闭按钮
    public var hiddenCloseButton: Bool = false
    
    /// 标题颜色
    public var titleColor: UIColor = .black
    
    /// 暗黑风格下的标题颜色
    public var titleDarkColor: UIColor = .white
    
    /// 子标题颜色
    public var subTitleColor: UIColor = "#444444".color
    
    /// 暗黑风格下的子标题颜色
    public var darkSubTitleColor: UIColor = .white
    
    /// 跳转按钮背景颜色
    public var jumpButtonBackgroundColor: UIColor = "#333333".color
    
    /// 暗黑风格下跳转按钮背景颜色
    public var jumpButtonDarkBackgroundColor: UIColor = .white
    
    /// 跳转按钮文字颜色
    public var jumpButtonTitleColor: UIColor = "#ffffff".color
    
    /// 暗黑风格下跳转按钮文字颜色
    public var jumpButtonTitleDarkColor: UIColor = "#333333".color
    
    public init() { }
}
