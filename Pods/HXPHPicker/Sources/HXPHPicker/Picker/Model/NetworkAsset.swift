//
//  NetworkAsset.swift
//  HXPHPicker
//
//  Created by Slience on 2021/5/24.
//

import UIKit
#if canImport(Kingfisher)
import Kingfisher

public struct NetworkImageAsset: Codable {
    
    /// 占位图
    public let placeholder: String?
    
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
    
    public init(
        thumbnailURL: URL,
        originalURL: URL,
        thumbnailSize: CGSize = UIScreen.main.bounds.size,
        placeholder: String? = nil,
        imageSize: CGSize = .zero,
        fileSize: Int = 0
    ) {
        self.thumbnailURL = thumbnailURL
        self.originalURL = originalURL
        self.thumbnailSize = thumbnailSize
        self.placeholder = placeholder
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

/// 网络视频
public struct NetworkVideoAsset {
    
    /// 网络视频地址
    public let videoURL: URL
    
    /// 视频时长
    public var duration: TimeInterval
    
    /// 视频封面，优先级大于 coverImageURL
    public var coverImage: UIImage?
    
    /// 图片文件大小
    public var fileSize: Int
    
    /// 视频尺寸
    public var videoSize: CGSize
    
    #if canImport(Kingfisher)
    /// 视频封面网络地址
    public var coverImageURL: URL?
    
    public init(videoURL: URL,
                duration: TimeInterval = 0,
                fileSize: Int = 0,
                coverImage: UIImage? = nil,
                videoSize: CGSize = .zero,
                coverImageURL: URL? = nil) {
        self.videoURL = videoURL
        self.duration = duration
        self.fileSize = fileSize
        self.coverImage = coverImage
        self.videoSize = videoSize
        self.coverImageURL = coverImageURL
    }
    #else
    public init(videoURL: URL,
                duration: TimeInterval = 0,
                fileSize: Int = 0,
                coverImage: UIImage? = nil,
                videoSize: CGSize = .zero) {
        self.videoURL = videoURL
        self.duration = duration
        self.fileSize = fileSize
        self.coverImage = coverImage
        self.videoSize = videoSize
    }
    #endif
}

extension NetworkVideoAsset: Codable {
    enum CodingKeys: CodingKey {
        case videoURL
        case duration
        case coverImage
        case fileSize
        case videoSize
        #if canImport(Kingfisher)
        case coverImageURL
        #endif
    }
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        videoURL = try container.decode(URL.self, forKey: .videoURL)
        duration = try container.decode(TimeInterval.self, forKey: .duration)
        if let imageData = try container.decodeIfPresent(Data.self, forKey: .coverImage) {
            coverImage = try NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(imageData) as? UIImage
        }else {
            coverImage = nil
        }
        fileSize = try container.decode(Int.self, forKey: .fileSize)
        videoSize = try container.decode(CGSize.self, forKey: .videoSize)
        #if canImport(Kingfisher)
        coverImageURL = try container.decodeIfPresent(URL.self, forKey: .coverImageURL)
        #endif
    }
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(videoURL, forKey: .videoURL)
        try container.encode(duration, forKey: .duration)
        if let image = coverImage {
            if #available(iOS 11.0, *) {
                let imageData = try NSKeyedArchiver.archivedData(withRootObject: image, requiringSecureCoding: false)
                try container.encode(imageData, forKey: .coverImage)
            } else {
                let imageData = NSKeyedArchiver.archivedData(withRootObject: image)
                try container.encode(imageData, forKey: .coverImage)
            }
        }
        try container.encode(fileSize, forKey: .fileSize)
        try container.encode(videoSize, forKey: .videoSize)
        #if canImport(Kingfisher)
        try container.encode(coverImageURL, forKey: .coverImageURL)
        #endif
    }
}
