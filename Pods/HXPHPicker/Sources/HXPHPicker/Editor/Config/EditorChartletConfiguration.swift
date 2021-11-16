//
//  EditorChartletConfiguration.swift
//  HXPHPicker
//
//  Created by Slience on 2021/8/16.
//

import UIKit

public struct EditorChartletConfiguration {
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
    
    /// 加载标题, titles 为空时才会触发
    /// titleHandler = { response in
    ///     // 传入标题数据
    ///     response(self.getChartletTitles())
    /// }
    public var titleHandler: ((@escaping EditorTitleChartletResponse) -> Void)?
    
    /// 加载贴图列表
    /// listHandler = { titleIndex, response in
    ///     // 传入标题下标，对应标题下的贴纸数据
    ///     response(titleIndex, self.getChartlets())
    /// }
    public var listHandler: ((Int, @escaping EditorChartletListResponse) -> Void)?
    
    public init() { }
}
