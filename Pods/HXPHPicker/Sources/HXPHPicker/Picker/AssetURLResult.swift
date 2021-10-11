//
//  AssetURLResult.swift
//  HXPHPicker
//
//  Created by Slience on 2021/8/25.
//

import Foundation

public struct AssetURLResult {
    
    /// url类型
    public enum URLType {
        /// 本地
        case local
        /// 网络
        case network
    }
    
    /// LivePhoto包含的内容
    public struct LivePhoto {
        /// 图片地址
        public let imageURL: URL
        /// 视频地址
        public let videoURL: URL
    }
    
    /// 地址
    public let url: URL
    
    /// URL类型
    public let urlType: URLType
    
    /// 媒体类型
    public let mediaType: PhotoAsset.MediaType
    
    /// LivePhoto里包含的资源
    /// selectOptions 需包含 livePhoto
    public let livePhoto: LivePhoto?
    
    init(
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
