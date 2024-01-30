//
//  AlbumTitleViewConfiguration.swift
//  HXPhotoPicker
//
//  Created by Slience on 2021/8/30.
//

import UIKit

// MARK: Album title view configuration class, valid when the pop-up window displays the album list / 相册标题视图配置类，弹窗展示相册列表时有效
public struct AlbumTitleViewConfiguration {
    
    public var backgroundColor: UIColor?
    
    /// Background color in dark style
    /// 暗黑风格下背景颜色
    public var backgroudDarkColor: UIColor?
    
    /// Arrow configuration
    /// 箭头配置
    public var arrow: ArrowViewConfiguration = .init()
    
    public init() { }
    
    public mutating func setThemeColor(_ color: UIColor) {
        arrow.setThemeColor(color)
    }
}
