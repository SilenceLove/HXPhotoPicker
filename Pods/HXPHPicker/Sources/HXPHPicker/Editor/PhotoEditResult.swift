//
//  PhotoEditResult.swift
//  HXPHPicker
//
//  Created by Slience on 2021/4/22.
//

import UIKit

public struct PhotoEditResult {
    
    public enum ImageType: Int, Codable {
        /// 静态图
        case normal
        /// 动图
        case gif
    }
    
    /// 编辑后的缩略图片，如果为gif则为封面图片
    /// 适合在多图列表展示，预览原图或者大图请使用 editedImageURL
    public let editedImage: UIImage
    
    /// 编辑后的图片本地地址
    public var editedImageURL: URL {
        urlConfig.url
    }
    
    public let urlConfig: EditorURLConfig
    
    /// 图片类型
    public let imageType: ImageType
    
    /// 编辑状态数据
    let editedData: PhotoEditData
}

struct PhotoEditData: Codable {
    let isPortrait: Bool
    let cropData: PhotoEditCropData?
    let brushData: [PhotoEditorBrushData]
    let hasFilter: Bool
    let filterImageURL: URL?
    let mosaicData: [PhotoEditorMosaicData]
    let stickerData: EditorStickerData?
}

struct PhotoEditCropData: Codable {
    let cropSize: CGSize
    let isRoundCrop: Bool
    let zoomScale: CGFloat
    let contentInset: UIEdgeInsets
    let offsetScale: CGPoint
    let minimumZoomScale: CGFloat
    let maximumZoomScale: CGFloat
    let maskRect: CGRect
    let angle: CGFloat
    let transform: CGAffineTransform
    let mirrorType: EditorImageResizerView.MirrorType
}

extension PhotoEditResult: Codable {
    enum CodingKeys: CodingKey {
        case editedImage
        case urlConfig
        case imageType
        case editedData
    }
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let imageData = try container.decode(Data.self, forKey: .editedImage)
        editedImage = try NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(imageData) as! UIImage
        urlConfig = try container.decode(EditorURLConfig.self, forKey: .urlConfig)
        imageType = try container.decode(ImageType.self, forKey: .imageType)
        editedData = try container.decode(PhotoEditData.self, forKey: .editedData)
    }
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        if #available(iOS 11.0, *) {
            let imageData = try NSKeyedArchiver.archivedData(withRootObject: editedImage, requiringSecureCoding: false)
            try container.encode(imageData, forKey: .editedImage)
        } else {
            let imageData = NSKeyedArchiver.archivedData(withRootObject: editedImage)
            try container.encode(imageData, forKey: .editedImage)
        }
        try container.encode(urlConfig, forKey: .urlConfig)
        try container.encode(imageType, forKey: .imageType)
        try container.encode(editedData, forKey: .editedData)
    }
}
