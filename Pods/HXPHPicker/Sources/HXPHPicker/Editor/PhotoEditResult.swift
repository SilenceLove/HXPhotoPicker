//
//  PhotoEditResult.swift
//  HXPHPicker
//
//  Created by Slience on 2021/4/22.
//

import UIKit

public struct PhotoEditResult {
    
    public enum ImageType {
        /// 静态图
        case normal
        /// 动图
        case gif
    }
    
    /// 编辑后的缩略图片，如果为gif则为封面图片
    /// 适合在多图列表展示，预览原图或者大图请使用 editedImageURL
    public let editedImage: UIImage
    
    /// 编辑后的图片本地地址
    public let editedImageURL: URL
    
    /// 图片类型
    public let imageType: ImageType
    
    /// 编辑状态数据
    let editedData: PhotoEditData
}

struct PhotoEditData {
    let isPortrait: Bool
    let cropData: PhotoEditCropData?
    let brushData: [PhotoEditorBrushData]
}

struct PhotoEditCropData {
    let cropSize: CGSize
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
