//
//  EditorTextConfiguration.swift
//  HXPHPicker
//
//  Created by Slience on 2021/8/16.
//

import UIKit

public struct EditorTextConfiguration {
    /// 文本颜色数组
    public var colors: [String] = PhotoTools.defaultColors()
    /// 确定按钮背景颜色、文本光标颜色
    public var tintColor: UIColor = .systemTintColor
    /// 文本字体
    public var font: UIFont = .boldSystemFont(ofSize: 25)
    /// 最大字数限制，0为不限制
    public var maximumLimitTextLength: Int = 0
    /// 文本视图推出样式
    public var modalPresentationStyle: UIModalPresentationStyle
    
    public init() {
        if #available(iOS 13.0, *) {
            self.modalPresentationStyle = .automatic
        }else {
            self.modalPresentationStyle = .fullScreen
        }
    }
}
