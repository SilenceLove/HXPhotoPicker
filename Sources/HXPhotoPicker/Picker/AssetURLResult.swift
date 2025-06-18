//
//  AssetURLResult.swift
//  HXPhotoPicker
//
//  Created by Slience on 2021/8/25.
//

import Foundation

public struct AssetURLResult {
    public let url: URL
    public let urlType: URLType
    public let mediaType: PhotoAsset.MediaType
    
    /// Contents of LivePhoto
    /// selectOptions needs to include livePhoto
    /// LivePhoto里包含的资源
    /// selectOptions 需包含 livePhoto
    /// 如果静止播放点击了禁止播放LivePhoto 则为 nil
    public let livePhoto: LivePhoto?
    
    public init(
        url: URL,
        urlType: URLType,
        mediaType: PhotoAsset.MediaType,
        livePhoto: LivePhoto? = nil
    ) {
        self.url = url
        self.urlType = urlType
        self.mediaType = mediaType
        self.livePhoto = livePhoto
    }
}

public extension AssetURLResult {
    /// Contents of LivePhoto
    /// LivePhoto包含的内容
    struct LivePhoto {
        
        public let imageURL: URL
        public let imageURLType: URLType
        public let videoURL: URL
        public let videoURLType: URLType
        
        public init(
            imageURL: URL,
            imageURLType: URLType = .local,
            videoURL: URL,
            videoURLType: URLType = .local
        ) {
            self.imageURL = imageURL
            self.imageURLType = imageURLType
            self.videoURL = videoURL
            self.videoURLType = videoURLType
        }
    }
    
    enum URLType {
        case local
        case network
    }
}
