//
//  ArrowViewConfiguration.swift
//  HXPhotoPicker
//
//  Created by Slience on 2021/8/30.
//

import UIKit

// MARK: Album title view configuration class, valid when the pop-up window displays the album list / 相册标题视图配置类，弹窗展示相册列表时有效
public struct ArrowViewConfiguration {
    
    /// 箭头背景颜色
    public var backgroundColor: UIColor = .systemBlue
    
    /// 箭头颜色
    public var arrowColor: UIColor = "#ffffff".hx.color
    
    /// 暗黑风格下箭头背景颜色
    public var backgroudDarkColor: UIColor = .systemBlue
    
    /// 暗黑风格下箭头颜色
    public var arrowDarkColor: UIColor = "#ffffff".hx.color
    
    public init() { }
    
    public mutating func setThemeColor(_ color: UIColor) {
        backgroundColor = color
        backgroudDarkColor = color
    }
}
