//
//  NetworkAsset.swift
//  HXPHPicker
//
//  Created by Slience on 2021/5/24.
//

import UIKit
#if canImport(Kingfisher)
import Kingfisher

public struct NetworkImageAsset {
    
    /// 占位图
    public var placeholder: String?
    
    /// 缩略图，列表cell展示
    public let thumbnailURL: URL
    
    /// Kingfisher 下载缩略图时 DownsamplingImageProcessor 设置的大小
    public let thumbnailSize: CGSize
    
    /// 原图，预览大图展示
    public let originalURL: URL
    
    /// 图片尺寸
    public var imageSize: CGSize
    
    /// 图片文件大小
    public var fileSize: Int
    
    public init(thumbnailURL: URL,
                originalURL: URL,
                thumbnailSize: CGSize = UIScreen.main.bounds.size,
                imageSize: CGSize = .zero,
                fileSize: Int = 0) {
        self.thumbnailURL = thumbnailURL
        self.originalURL = originalURL
        self.thumbnailSize = thumbnailSize
        self.imageSize = imageSize
        self.fileSize = fileSize
        if let image = ImageCache.default.retrieveImageInMemoryCache(forKey: originalURL.cacheKey) {
            self.imageSize = image.size
            if let imageData = image.kf.gifRepresentation() {
                self.fileSize = imageData.count
            }else if let imageData = image.kf.pngRepresentation() {
                self.fileSize = imageData.count
            }else if let imageData = image.kf.jpegRepresentation(compressionQuality: 1) {
                self.fileSize = imageData.count
            }
        }
    }
}
#endif

/// 网络视频目前只支持下载完之后播放
public struct NetworkVideoAsset {
    
    /// 网络视频地址
    public let videoURL: URL
    
    /// 视频时长
    public var duration: TimeInterval
    
    /// 视频封面，优先级大于 coverImageURL
    public var coverImage: UIImage?
    
    /// 图片文件大小
    public var fileSize: Int
    
    #if canImport(Kingfisher)
    /// 视频封面网络地址
    public var coverImageURL: URL?
    
    public init(videoURL: URL,
                duration: TimeInterval = 0,
                fileSize: Int = 0,
                coverImage: UIImage? = nil,
                coverImageURL: URL? = nil) {
        self.videoURL = videoURL
        self.duration = duration
        self.fileSize = fileSize
        self.coverImageURL = coverImageURL
        self.coverImage = coverImage
    }
    #else
    public init(videoURL: URL,
                duration: TimeInterval = 0,
                fileSize: Int = 0,
                coverImage: UIImage? = nil) {
        self.videoURL = videoURL
        self.duration = duration
        self.fileSize = fileSize
        self.coverImage = coverImage
    }
    #endif
}
