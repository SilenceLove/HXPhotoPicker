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
