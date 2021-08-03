//
//  EditorChartlet.swift
//  HXPHPicker
//
//  Created by Slience on 2021/7/26.
//

import UIKit


public typealias EditorTitleChartletResponse = ([EditorChartlet]) -> Void
public typealias EditorChartletListResponse = (Int, [EditorChartlet]) -> Void

public struct EditorChartlet {
    
    /// 贴图对应的 UIImage 对象
    public let image: UIImage?
    
    #if canImport(Kingfisher)
    /// 贴图对应的 网络地址
    public let url: URL?
    #endif
    
    public let ext: Any?
    
    public init(image: UIImage?,
                ext: Any? = nil) {
        self.image = image
        #if canImport(Kingfisher)
        self.url = nil
        #endif
        self.ext = ext
    }
    
    #if canImport(Kingfisher)
    public init(url: URL?,
                ext: Any? = nil) {
        self.url = url
        self.image = nil
        self.ext = ext
    }
    #endif
}


class EditorChartletTitle {
    
    /// 标题图标 对应的 UIImage 数据
    let image: UIImage?
    
    #if canImport(Kingfisher)
    /// 标题图标 对应的 网络地址
    let url: URL?
    #endif
    
    init(image: UIImage?) {
        self.image = image
        #if canImport(Kingfisher)
        self.url = nil
        #endif
    }
    
    #if canImport(Kingfisher)
    init(url: URL?) {
        self.url = url
        self.image = nil
    }
    #endif
    
    var isSelected: Bool = false
    var isLoading: Bool = false
    var chartletList: [EditorChartlet] = []
}
