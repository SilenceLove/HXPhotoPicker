//
//  LocalAsset.swift
//  HXPHPicker
//
//  Created by Slience on 2021/5/24.
//

import UIKit

public struct LocalImageAsset {
    public var image: UIImage?
    public var imageData: Data?
    public var imageURL: URL?
    
    public init(image: UIImage) {
        self.image = image
    }
    public init(imageData: Data) {
        self.imageData = imageData
        self.image = UIImage.init(data: imageData)
    }
    public init(imageURL: URL) {
        self.imageURL = imageURL
    }
}

public struct LocalVideoAsset {
    public let videoURL: URL
    /// 封面
    public var image: UIImage?
    public var duration: TimeInterval
    public init(videoURL: URL,
                coverImage: UIImage? = nil,
                duration: TimeInterval = 0) {
        self.videoURL = videoURL
        self.image = coverImage
        self.duration = duration
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
            image = try NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(data) as? UIImage
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
    }
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        videoURL = try container.decode(URL.self, forKey: .videoURL)
        if let data = try container.decodeIfPresent(Data.self, forKey: .image) {
            image = try NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(data) as? UIImage
        }else {
           image = nil
        }
        duration = try container.decode(TimeInterval.self, forKey: .duration)
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
    }
}
