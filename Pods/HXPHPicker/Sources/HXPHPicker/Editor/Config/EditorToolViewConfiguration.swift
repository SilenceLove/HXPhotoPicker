//
//  EditorToolViewConfiguration.swift
//  HXPHPicker
//
//  Created by Slience on 2021/1/9.
//

import UIKit

public class EditorToolViewConfiguration {
    
    /// 工具栏item选项
    public lazy var toolOptions: [EditorToolOptions] = []
    
    /// 工具栏选项按钮选中颜色
    public lazy var toolSelectedColor: UIColor = .systemTintColor
    
    /// 完成按钮标题颜色
    public lazy var finishButtonTitleColor: UIColor = {
        return .white
    }()
    
    /// 暗黑风格下完成按钮标题颜色
    public lazy var finishButtonTitleDarkColor: UIColor = {
        return .white
    }()
    
    /// 完成按钮的背景颜色
    public lazy var finishButtonBackgroundColor: UIColor = {
        return .systemTintColor
    }()
    
    /// 暗黑风格下完成按钮选的背景颜色
    public lazy var finishButtonDarkBackgroundColor: UIColor = {
        return .systemTintColor
    }()
    
    public init() { }
}
