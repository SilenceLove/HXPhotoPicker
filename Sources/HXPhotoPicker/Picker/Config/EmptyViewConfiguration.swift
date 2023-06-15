//
//  EmptyViewConfiguration.swift
//  HXPhotoPicker
//
//  Created by Slience on 2020/12/29.
//  Copyright © 2020 Silence. All rights reserved.
//

import UIKit

// MARK: 照片列表空资源时展示的视图
public struct EmptyViewConfiguration {
    
    /// 标题颜色
    public var titleColor: UIColor = "#666666".hx.color
    
    /// 暗黑风格下标题颜色
    public var titleDarkColor: UIColor = "#ffffff".hx.color
    
    /// 子标题颜色
    public var subTitleColor: UIColor = "#999999".hx.color
    
    /// 暗黑风格下子标题颜色
    public var subTitleDarkColor: UIColor = "#dadada".hx.color
    
    public init() { }
}
