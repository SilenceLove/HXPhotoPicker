//
//  EditorChartlet.swift
//  HXPhotoPicker
//
//  Created by Slience on 2021/7/26.
//

import UIKit

public typealias EditorTitleChartletResponse = ([EditorChartlet]) -> Void
public typealias EditorChartletListResponse = (Int, [EditorChartlet]) -> Void

public struct EditorChartlet {
    
    /// 贴图对应的 UIImage 对象, 视频支持gif
    public let image: UIImage?
    
    public let imageData: Data?
    
    #if canImport(Kingfisher)
    /// 贴图对应的 网络地址（视频支持gif)
    public let url: URL?
    #endif
    
    public let ext: Any?
    
    public init(
        image: UIImage?,
        imageData: Data? = nil,
        ext: Any? = nil
    ) {
        self.image = image
        self.imageData = imageData
        self.ext = ext
        #if canImport(Kingfisher)
        url = nil
        #endif
    }
    
    #if canImport(Kingfisher)
    public init(
        url: URL?,
        ext: Any? = nil
    ) {
        self.url = url
        self.ext = ext
        image = nil
        imageData = nil
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
        url = nil
        #endif
    }
    
    #if canImport(Kingfisher)
    init(url: URL?) {
        self.url = url
        image = nil
    }
    #endif
    
    var isSelected = false
    var isLoading = false
    var isAlbum = false
    var chartletList: [EditorChartlet] = []
}
