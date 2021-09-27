//
//  AlbumTitleViewConfiguration.swift
//  HXPHPicker
//
//  Created by Slience on 2021/8/30.
//

import UIKit

// MARK: 相册标题视图配置类，弹窗展示相册列表时有效
public struct AlbumTitleViewConfiguration {
    
    /// 背景颜色
    public var backgroundColor: UIColor?
    
    /// 暗黑风格下背景颜色
    public var backgroudDarkColor: UIColor?
    
    /// 箭头配置
    public var arrow: ArrowViewConfiguration = .init()
    
    public init() { }
}
