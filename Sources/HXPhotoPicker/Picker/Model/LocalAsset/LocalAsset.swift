//
//  LocalAsset.swift
//  HXPhotoPicker
//
//  Created by Slience on 2021/5/24.
//

import UIKit

public struct LocalImageAsset {
    public var image: UIImage?
    public var imageData: Data?
    public var imageURL: URL?
    
    /// 初始化本地图片
    public init(image: UIImage) {
        self.image = image
    }
    /// 初始化本地图片
    public init(_ image: UIImage) {
        self.init(image: image)
    }
    /// 初始化本地图片
    public init(imageData: Data) {
        self.imageData = imageData
        self.image = UIImage(data: imageData)
    }
    /// 初始化本地图片
    public init(_ imageData: Data) {
        self.init(imageData: imageData)
    }
    /// 初始化本地图片
    public init(imageURL: URL) {
        self.imageURL = imageURL
    }
    /// 初始化本地图片
    public init(_ imageURL: URL) {
        self.init(imageURL: imageURL)
    }
    
    var thumbnail: UIImage?
}

public struct LocalVideoAsset {
    
    /// 视频本地地址
    public let videoURL: URL
    
    /// 视频封面
    public var image: UIImage?
    
    /// 视频时长
    public var duration: TimeInterval
    
    /// 视频尺寸
    public var videoSize: CGSize
    
    /// 初始化本地视频
    public init(
        localVideo url: URL,
        coverImage: UIImage? = nil,
        duration: TimeInterval = 0,
        videoSize: CGSize = .zero
    ) {
        self.init(
            videoURL: url,
            coverImage: coverImage,
            duration: duration,
            videoSize: videoSize
        )
    }
    /// 初始化本地视频
    public init(
        videoURL: URL,
        coverImage: UIImage? = nil,
        duration: TimeInterval = 0,
        videoSize: CGSize = .zero
    ) {
        self.videoURL = videoURL
        self.image = coverImage
        self.duration = duration
        self.videoSize = videoSize
    }
}

public struct LocalLivePhotoAsset {
    /// 封面图片地址（支持本地、网络/需要Kingfisher）
    public let imageURL: URL
    
    /// 本地图片的唯一标识符
    public let imageIdentifier: String?
    
    /// 视频内容地址（支持本地、网络）
    public let videoURL: URL
    
    /// 本地视频的唯一标识符
    public let videoIdentifier: String?
    
    public var size: CGSize
    
    /// 初始化`LivePhoto`
    public init(
        imageURL: URL,
        videoURL: URL,
        imageIdentifier: String? = nil,
        videoIdentifier: String? = nil,
        size: CGSize = .zero
    ) {
        self.imageURL = imageURL
        self.videoURL = videoURL
        self.imageIdentifier = imageIdentifier
        self.videoIdentifier = videoIdentifier
        self.size = size
    }
}

extension LocalImageAsset: Codable {
    enum CodingKeys: CodingKey {
        case image
        case imageData
        case imageURL
    }
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        if let data = try container.decodeIfPresent(Data.self, forKey: .image) {
            if #available(iOS 11.0, *) {
                image = try NSKeyedUnarchiver.unarchivedObject(ofClass: UIImage.self, from: data)
            }else {
                image = try NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(data) as? UIImage
            }
        }else {
            image = nil
        }
        imageURL = try container.decodeIfPresent(URL.self, forKey: .imageURL)
        imageData = try container.decodeIfPresent(Data.self, forKey: .imageData)
    }
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        if let image = image {
            if #available(iOS 11.0, *) {
                let data = try NSKeyedArchiver.archivedData(withRootObject: image, requiringSecureCoding: false)
                try container.encode(data, forKey: .image)
            } else {
                let data = NSKeyedArchiver.archivedData(withRootObject: image)
                try container.encode(data, forKey: .image)
            }
        }
        try container.encode(imageURL, forKey: .imageURL)
        try container.encode(imageData, forKey: .imageData)
    }
}

extension LocalVideoAsset: Codable {
    enum CodingKeys: CodingKey {
        case videoURL
        case image
        case duration
        case videoSize
    }
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        videoURL = try container.decode(URL.self, forKey: .videoURL)
        if let data = try container.decodeIfPresent(Data.self, forKey: .image) {
            if #available(iOS 11.0, *) {
                image = try NSKeyedUnarchiver.unarchivedObject(ofClass: UIImage.self, from: data)
            }else {
                image = try NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(data) as? UIImage
            }
        }else {
           image = nil
        }
        duration = try container.decode(TimeInterval.self, forKey: .duration)
        videoSize = try container.decode(CGSize.self, forKey: .videoSize)
    }
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(videoURL, forKey: .videoURL)
        if let image = image {
            if #available(iOS 11.0, *) {
                let data = try NSKeyedArchiver.archivedData(withRootObject: image, requiringSecureCoding: false)
                try container.encode(data, forKey: .image)
            } else {
                let data = NSKeyedArchiver.archivedData(withRootObject: image)
                try container.encode(data, forKey: .image)
            }
        }
        try container.encode(duration, forKey: .duration)
        try container.encode(videoSize, forKey: .videoSize)
    }
}

extension LocalLivePhotoAsset: Codable {
    enum CodingKeys: CodingKey {
        case imageURL
        case videoURL
        case imageIdentifier
        case videoIdentifier
        case size
    }
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        imageURL = try container.decode(URL.self, forKey: .imageURL)
        videoURL = try container.decode(URL.self, forKey: .videoURL)
        imageIdentifier = try container.decode(String.self, forKey: .imageIdentifier)
        videoIdentifier = try container.decode(String.self, forKey: .videoIdentifier)
        size = try container.decode(CGSize.self, forKey: .size)
    }
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(imageURL, forKey: .imageURL)
        try container.encode(videoURL, forKey: .videoURL)
        try container.encode(imageIdentifier, forKey: .imageIdentifier)
        try container.encode(videoIdentifier, forKey: .videoIdentifier)
        try container.encode(size, forKey: .size)
    }
}
