//
//  HXPHNotAuthorizedConfiguration.swift
//  HXPHPickerExample
//
//  Created by Slience on 2020/12/29.
//  Copyright © 2020 Silence. All rights reserved.
//

import UIKit

// MARK: 未授权界面配置类
public class HXPHNotAuthorizedConfiguration: NSObject {
    
    /// 背景颜色
    public lazy var backgroundColor: UIColor = {
        return UIColor.white
    }()
    
    /// 暗黑风格下的背景颜色
    public lazy var darkBackgroundColor: UIColor = {
        return "#2E2F30".hx_color
    }()
    
    /// 关闭按钮图片名
    public lazy var closeButtonImageName: String = {
        return "hx_picker_notAuthorized_close"
    }()
    
    /// 暗黑风格下的关闭按钮图片名
    public lazy var closeButtonDarkImageName: String = {
        return "hx_picker_notAuthorized_close_dark"
    }()
    
    /// 标题颜色
    public lazy var titleColor: UIColor = {
        return UIColor.black
    }()
    
    /// 暗黑风格下的标题颜色
    public lazy var titleDarkColor: UIColor = {
        return .white
    }()
    
    /// 子标题颜色
    public lazy var subTitleColor: UIColor = {
        return "#444444".hx_color
    }()
    
    /// 暗黑风格下的子标题颜色
    public lazy var darkSubTitleColor: UIColor = {
        return .white
    }()
    
    /// 跳转按钮背景颜色
    public lazy var jumpButtonBackgroundColor: UIColor = {
        return "#333333".hx_color
    }()
    
    /// 暗黑风格下跳转按钮背景颜色
    public lazy var jumpButtonDarkBackgroundColor: UIColor = {
        return .white
    }()
    
    /// 跳转按钮文字颜色
    public lazy var jumpButtonTitleColor: UIColor = {
        return "#ffffff".hx_color
    }()
    
    /// 暗黑风格下跳转按钮文字颜色
    public lazy var jumpButtonTitleDarkColor: UIColor = {
        return "#333333".hx_color
    }()
}
