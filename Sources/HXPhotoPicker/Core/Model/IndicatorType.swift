//
//  IndicatorType.swift
//  HXPhotoPicker
//
//  Created by Slience on 2021/1/8.
//

import UIKit

public enum IndicatorType {
    /// gradient ring
    /// 渐变圆环
    case circle
    
    case circleJoin
    
    /// System chrysanthemum
    /// 系统菊花
    case system
}

public protocol IndicatorTypeConfig {
    /// Loading indicator type
    /// 加载指示器类型
    var indicatorType: IndicatorType { get set }
}

public extension IndicatorTypeConfig {
    var indicatorType: IndicatorType {
        get { PhotoManager.shared.indicatorType }
        set { PhotoManager.shared.indicatorType = newValue }
    }
}
