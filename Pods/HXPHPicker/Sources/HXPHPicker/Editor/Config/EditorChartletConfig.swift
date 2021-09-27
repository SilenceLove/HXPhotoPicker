//
//  EditorChartletConfig.swift
//  HXPHPicker
//
//  Created by Slience on 2021/8/16.
//

import UIKit

public struct EditorChartletConfig {
    public enum LoadScene {
        /// cell显示时
        case cellDisplay
        /// 滚动停止时
        case scrollStop
    }
    /// 弹窗高度
    public var viewHeight: CGFloat = UIScreen.main.bounds.height * 0.5
    /// 每行显示个数
    public var rowCount: Int = UIDevice.isPad ? 6 : 5
    /// 贴图加载时机
    public var loadScene: LoadScene = .cellDisplay
    /// 贴图标题
    public var titles: [EditorChartlet] = []
    
    public init() { }
}
