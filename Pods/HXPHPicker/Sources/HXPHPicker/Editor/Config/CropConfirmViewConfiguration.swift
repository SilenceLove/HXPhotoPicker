//
//  CropConfirmViewConfiguration.swift
//  HXPHPicker
//
//  Created by Slience on 2021/1/9.
//

import UIKit

public struct CropConfirmViewConfiguration {
    
    /// 完成按钮标题颜色
    public var finishButtonTitleColor: UIColor =  .white
    
    /// 暗黑风格下完成按钮标题颜色
    public var finishButtonTitleDarkColor: UIColor = .white
    
    /// 完成按钮的背景颜色
    public var finishButtonBackgroundColor: UIColor = .systemTintColor
    
    /// 暗黑风格下完成按钮选的背景颜色
    public var finishButtonDarkBackgroundColor: UIColor = .systemTintColor
    
    /// 取消按钮标题颜色
    public var cancelButtonTitleColor: UIColor = .white
    
    /// 暗黑风格下取消按钮标题颜色
    public var cancelButtonTitleDarkColor: UIColor = .white
    
    /// 取消按钮的背景颜色
    public var cancelButtonBackgroundColor: UIColor?
    
    /// 暗黑风格下取消按钮选的背景颜色
    public var cancelButtonDarkBackgroundColor: UIColor?
    
    /// 还原按钮标题颜色
    public var resetButtonTitleColor: UIColor = .white
    
    /// 暗黑风格下还原按钮标题颜色
    public var resetButtonTitleDarkColor: UIColor = .white
    
    /// 还原按钮的背景颜色
    public var resetButtonBackgroundColor: UIColor?
    
    /// 暗黑风格下还原按钮选的背景颜色
    public var resetButtonDarkBackgroundColor: UIColor?
    
    public init() { }
}
