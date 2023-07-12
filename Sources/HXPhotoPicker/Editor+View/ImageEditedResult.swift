//
//  ImageEditedResult.swift
//  HXPhotoPicker
//
//  Created by Silence on 2023/5/26.
//

import UIKit

public struct ImageEditedResult {
    
    /// The edited thumbnail image, or the cover image if gif
    /// Suitable for multi-image list display, please use imageURL to preview the original image or larger image
    /// 编辑后的缩略图片，如果为gif则为封面图片
    /// 适合在多图列表展示，预览原图或者大图请使用 imageURL
    public let image: UIImage
    
    /// The local url of the edited image
    /// 编辑后的图片本地地址
    public var url: URL {
        urlConfig.url
    }
    
    public let urlConfig: EditorURLConfig
    
    /// 图片类型
    public let imageType: ImageType
    
    public enum ImageType: Int, Codable {
        /// static image
        /// 静态图
        case normal
        /// 动图
        case gif
    }
    
    /// 编辑视图的状态
    public let data: EditAdjustmentData?
    
    public init(data: EditAdjustmentData? = nil) {
        self.data = data
        image = .init()
        urlConfig = .empty
        imageType = .normal
    }
    
    init(image: UIImage, urlConfig: EditorURLConfig, imageType: ImageType, data: EditAdjustmentData?) {
        self.image = image
        self.urlConfig = urlConfig
        self.imageType = imageType
        self.data = data
    }
}

public struct EditorURLConfig: Codable {
    public enum PathType: Codable {
        case document
        case caches
        case temp
    }
    /// 文件名称
    public let fileName: String
    /// 路径类型
    public let pathType: PathType
    
    public init(fileName: String, type: PathType) {
        self.fileName = fileName
        self.pathType = type
    }
    
    /// 文件地址
    public var url: URL {
        var filePath: String = ""
        switch pathType {
        case .document:
            filePath = FileManager.documentPath + "/"
        case .caches:
            filePath = FileManager.cachesPath + "/"
        case .temp:
            filePath = FileManager.tempPath
        }
        filePath.append(contentsOf: fileName)
        return .init(fileURLWithPath: filePath)
    }
    
    public static var empty: EditorURLConfig {
        .init(fileName: "", type: .temp)
    }
}
