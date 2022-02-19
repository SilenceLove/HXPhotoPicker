//
//  BaseConfiguration.swift
//  HXPHPicker
//
//  Created by Slience on 2021/1/8.
//

import UIKit

open class BaseConfiguration {
    
    public var modalPresentationStyle: UIModalPresentationStyle
    
    /// 如果自带的语言不够，可以添加自定义的语言文字
    /// PhotoManager.shared.customLanguages 自定义语言数组
    /// PhotoManager.shared.fixedCustomLanguage 如果有多种自定义语言，可以固定显示某一种
    /// 语言类型
    public var languageType: LanguageType = .system
    
    /// 外观风格
    public var appearanceStyle: AppearanceStyle = .varied
    
    /// 隐藏状态栏
    public var prefersStatusBarHidden: Bool = false
    
    /// 允许旋转，全屏情况下才可以禁止旋转
    public var shouldAutorotate: Bool = true
    
    /// 支持的方向
    public var supportedInterfaceOrientations: UIInterfaceOrientationMask = .all
    
    /// 加载指示器类型
    public var indicatorType: IndicatorType = .circle {
        didSet { PhotoManager.shared.indicatorType = indicatorType }
    }
    
    public init() {
        if #available(iOS 13.0, *) {
            modalPresentationStyle = .automatic
        } else {
            modalPresentationStyle = .fullScreen
        }
        PhotoManager.shared.indicatorType = indicatorType
    }
}

public extension BaseConfiguration {
    /// 加载指示器类型
    enum IndicatorType {
        /// 渐变圆环
        case circle
        /// 系统菊花
        case system
    }
}
