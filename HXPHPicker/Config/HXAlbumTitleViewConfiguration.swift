//
//  HXAlbumTitleViewConfiguration.swift
//  HXPHPickerExample
//
//  Created by Slience on 2020/12/29.
//  Copyright © 2020 洪欣. All rights reserved.
//

import UIKit

// MARK: 相册标题视图配置类，弹窗展示相册列表时有效
public class HXAlbumTitleViewConfiguration: NSObject {
    
    /// 背景颜色
    public var backgroundColor: UIColor?
    
    /// 暗黑风格下背景颜色
    public var backgroudDarkColor: UIColor?
    
    /// 箭头背景颜色
    public lazy var arrowBackgroundColor: UIColor = {
        return "#333333".hx_color
    }()
    
    /// 箭头颜色
    public lazy var arrowColor: UIColor = {
        return "#ffffff".hx_color
    }()
    
    /// 暗黑风格下箭头背景颜色
    public lazy var arrowBackgroudDarkColor: UIColor = {
        return "#ffffff".hx_color
    }()
    
    /// 暗黑风格下箭头颜色
    public lazy var arrowDarkColor: UIColor = {
        return "#333333".hx_color
    }()
}
