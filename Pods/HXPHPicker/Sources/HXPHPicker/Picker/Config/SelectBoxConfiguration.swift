//
//  SelectBoxConfiguration.swift
//  HXPHPickerExample
//
//  Created by Slience on 2020/12/29.
//  Copyright © 2020 Silence. All rights reserved.
//

import UIKit

// MARK: 选择框配置类
public class SelectBoxConfiguration {
    
    /// 选择框的大小
    public var size: CGSize = CGSize(width: 25, height: 25)
    
    /// 选择框的样式
    public var style: PhotoPickerSelectBoxView.Style = .number
    
    /// 标题的文字大小
    public var titleFontSize: CGFloat = 16
    
    /// 选中之后的 标题 颜色
    public lazy var titleColor: UIColor = {
        return .white
    }()
    
    /// 暗黑风格下选中之后的 标题 颜色
    public lazy var titleDarkColor : UIColor = {
        return .white
    }()
    
    /// 选中状态下勾勾的宽度
    public var tickWidth: CGFloat = 1.5
    
    /// 选中之后的 勾勾 颜色
    public lazy var tickColor: UIColor = {
        return UIColor.white
    }()
    
    /// 暗黑风格下选中之后的 勾勾 颜色
    public lazy var tickDarkColor : UIColor = {
        return .black
    }()
    
    /// 未选中时框框中间的颜色
    public lazy var backgroundColor: UIColor = {
        return UIColor.black.withAlphaComponent(0.4)
    }()
    
    /// 暗黑风格下未选中时框框中间的颜色
    public lazy var darkBackgroundColor : UIColor = {
        return UIColor.black.withAlphaComponent(0.2)
    }()
    
    /// 选中之后的背景颜色
    public lazy var selectedBackgroundColor: UIColor = {
        return .systemTintColor
    }()
    
    /// 暗黑风格下选中之后的背景颜色
    public lazy var selectedBackgroudDarkColor : UIColor = {
        return .systemTintColor
    }()
    
    /// 未选中时的边框宽度
    public var borderWidth: CGFloat = 1.5
    
    /// 未选中时的边框颜色
    public lazy var borderColor: UIColor = {
        return .white
    }()
    
    /// 暗黑风格下未选中时的边框颜色
    public lazy var borderDarkColor : UIColor = {
        return .white
    }()
    
    public init() { }
}
