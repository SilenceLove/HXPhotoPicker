//
//  NotAuthorizedConfiguration.swift
//  HXPhotoPicker
//
//  Created by Slience on 2020/12/29.
//  Copyright © 2020 Silence. All rights reserved.
//

import UIKit

// MARK: 未授权界面配置类
public struct NotAuthorizedConfiguration {
    
    public var notAuthorizedView: PhotoDeniedAuthorization.Type = DeniedAuthorizationView.self
    
    /// 背景颜色
    public var backgroundColor: UIColor = .white
    
    /// 暗黑风格下的背景颜色
    public var darkBackgroundColor: UIColor = "#2E2F30".hx.color
    
    /// 关闭按钮图片名
    public var closeButtonImageName: String {
        get { .imageResource.picker.notAuthorized.close }
        set { HX.imageResource.picker.notAuthorized.close = newValue }
    }
    
    /// 暗黑风格下的关闭按钮图片名
    public var closeButtonDarkImageName: String {
        get { .imageResource.picker.notAuthorized.closeDark }
        set { HX.imageResource.picker.notAuthorized.closeDark = newValue }
    }
    
    /// 关闭按钮颜色
    public var closeButtonColor: UIColor? = .systemBlue
    
    /// 暗黑风格下的关闭按钮颜色
    public var closeButtonDarkColor: UIColor? = .white

    /// 隐藏关闭按钮
    public var isHiddenCloseButton: Bool = false
    
    /// 标题颜色
    public var titleColor: UIColor = "#666666".hx.color
    
    /// 暗黑风格下的标题颜色
    public var titleDarkColor: UIColor = .white
    
    /// 子标题颜色
    public var subTitleColor: UIColor = "#999999".hx.color
    
    /// 暗黑风格下的子标题颜色
    public var darkSubTitleColor: UIColor = "#dadada".hx.color
    
    /// 跳转按钮背景颜色
    public var jumpButtonBackgroundColor: UIColor = .systemBlue
    
    /// 暗黑风格下跳转按钮背景颜色
    public var jumpButtonDarkBackgroundColor: UIColor = .white
    
    /// 跳转按钮文字颜色
    public var jumpButtonTitleColor: UIColor = "#ffffff".hx.color
    
    /// 暗黑风格下跳转按钮文字颜色
    public var jumpButtonTitleDarkColor: UIColor = "#333333".hx.color
    
    public init() { 
        HX.imageResource.picker.notAuthorized.close = "hx_picker_notAuthorized_close"
    }
    
    public mutating func setThemeColor(_ color: UIColor) {
        closeButtonColor = color
        jumpButtonBackgroundColor = color
    }
}
