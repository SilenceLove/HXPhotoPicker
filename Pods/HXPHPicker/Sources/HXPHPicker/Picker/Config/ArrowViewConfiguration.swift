//
//  ArrowViewConfiguration.swift
//  HXPHPicker
//
//  Created by Slience on 2021/8/30.
//

import UIKit

// MARK: 相册标题视图配置类，弹窗展示相册列表时有效
public struct ArrowViewConfiguration {
    
    /// 箭头背景颜色
    public var backgroundColor: UIColor = .black
    
    /// 箭头颜色
    public var arrowColor: UIColor = "#ffffff".color
    
    /// 暗黑风格下箭头背景颜色
    public var backgroudDarkColor: UIColor = "#ffffff".color
    
    /// 暗黑风格下箭头颜色
    public var arrowDarkColor: UIColor = "#333333".color
    
    public init() { }
}
