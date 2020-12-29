//
//  HXPHPhotoListCellConfiguration.swift
//  HXPHPickerExample
//
//  Created by Slience on 2020/12/29.
//  Copyright © 2020 洪欣. All rights reserved.
//

import UIKit

// MARK: 照片列表Cell配置类
public class HXPHPhotoListCellConfiguration: NSObject {
    
    /// 自定义不带选择框的cell
    /// 继承 HXPHPickerBaseViewCell 只有UIImageView，其他控件需要自己添加
    /// 继承 HXPHPickerViewCell 在自带的基础上修改
    public var customSingleCellClass: HXPHPickerBaseViewCell.Type?
    
    /// 自定义带选择框的cell
    /// 继承 HXPHPickerBaseViewCell 只有UIImageView，其他控件需要自己添加
    /// 继承 HXPHPickerViewCell 带有图片和类型控件，选择按钮控件需要自己添加
    /// 继承 HXPHPickerSelectableViewCell 加以修改
    public var customSelectableCellClass: HXPHPickerBaseViewCell.Type?
    
    /// 背景颜色
    public var backgroundColor: UIColor?
    
    /// 暗黑风格下背景颜色
    public var backgroundDarkColor: UIColor?
    
    /// cell在不可选择状态是否显示遮罩
    public var showDisableMask: Bool = true
    
    /// 选择框顶部的间距
    public var selectBoxTopMargin: CGFloat = 5
    
    /// 选择框右边的间距
    public var selectBoxRightMargin: CGFloat = 5
    
    /// 选择框相关配置
    public lazy var selectBox: HXPHSelectBoxConfiguration = {
        return HXPHSelectBoxConfiguration.init()
    }()
}
