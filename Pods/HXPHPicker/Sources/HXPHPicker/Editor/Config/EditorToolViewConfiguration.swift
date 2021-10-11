//
//  EditorToolViewConfiguration.swift
//  HXPHPicker
//
//  Created by Slience on 2021/1/9.
//

import UIKit

public struct EditorToolViewConfiguration {
    
    /// 工具栏item选项
    public var toolOptions: [EditorToolOptions]
    
    /// 工具栏选项按钮选中颜色
    public var toolSelectedColor: UIColor = .systemTintColor
    
    /// 配乐选中时的颜色
    public var musicSelectedColor: UIColor = .systemTintColor
    
    /// 完成按钮标题颜色
    public var finishButtonTitleColor: UIColor = .white
    
    /// 暗黑风格下完成按钮标题颜色
    public var finishButtonTitleDarkColor: UIColor = .white
    
    /// 完成按钮的背景颜色
    public var finishButtonBackgroundColor: UIColor = .systemTintColor
    
    /// 暗黑风格下完成按钮选的背景颜色
    public var finishButtonDarkBackgroundColor: UIColor = .systemTintColor
    
    public init(toolOptions: [EditorToolOptions] = []) {
        self.toolOptions = toolOptions
    }
}
