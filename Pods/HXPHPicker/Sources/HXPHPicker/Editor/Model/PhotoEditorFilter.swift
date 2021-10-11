//
//  PhotoEditorFilter.swift
//  HXPHPicker
//
//  Created by Slience on 2021/6/23.
//

import UIKit

/// 需要添加滤镜的原始图片、上一次添加滤镜的图片，value，event
public typealias PhotoEditorFilterHandler = (UIImage, UIImage?, Float, PhotoEditorFilterInfo.Event) -> UIImage?

public struct PhotoEditorFilterInfo {
    
    public enum Event {
        case touchUpInside
        case valueChanged
    }
    
    /// 滤镜名称
    public let filterName: String
    
    /// UISlider 默认值 [0 - 1]
    /// 设置 -1 则代表不显示滑块
    public let defaultValue: Float
    
    /// 滤镜处理器，内部会传入未添加滤镜的图片，返回添加滤镜之后的图片
    public let filterHandler: PhotoEditorFilterHandler
    
    public init(
        filterName: String,
        defaultValue: Float = -1,
        filterHandler: @escaping PhotoEditorFilterHandler
    ) {
        self.filterName = filterName
        self.defaultValue = defaultValue
        self.filterHandler = filterHandler
    }
}

class PhotoEditorFilter: Equatable, Codable {
    
    let filterName: String
    let defaultValue: Float
    
    init(
        filterName: String,
        defaultValue: Float
    ) {
        self.filterName = filterName
        self.defaultValue = defaultValue
    }
    
    var isOriginal: Bool = false
    var isSelected: Bool = false
    var sourceIndex: Int = 0
    
    static func == (
        lhs: PhotoEditorFilter,
        rhs: PhotoEditorFilter
    ) -> Bool {
        lhs === rhs
    }
}
