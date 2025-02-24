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
    
    /// 贴图对应的 网络地址（视频支持gif)
    public let url: URL?
    
    public let ext: Any?
    
    public init(
        image: UIImage?,
        imageData: Data? = nil,
        ext: Any? = nil
    ) {
        self.image = image
        self.imageData = imageData
        self.ext = ext
        url = nil
    }
    
    public init(
        url: URL?,
        ext: Any? = nil
    ) {
        self.url = url
        self.ext = ext
        image = nil
        imageData = nil
    }
}

class EditorChartletTitle {
    
    /// 标题图标 对应的 UIImage 数据
    let image: UIImage?
    
    /// 标题图标 对应的 网络地址
    let url: URL?
    
    init(image: UIImage?) {
        self.image = image
        url = nil
    }
    
    init(url: URL?) {
        self.url = url
        image = nil
    }
    
    var isSelected = false
    var isLoading = false
    var isAlbum = false
    var chartletList: [EditorChartlet] = []
}
