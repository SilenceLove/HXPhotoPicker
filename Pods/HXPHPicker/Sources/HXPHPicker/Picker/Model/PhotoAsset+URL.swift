//
//  PhotoAsset+URL.swift
//  HXPHPicker
//
//  Created by Slience on 2021/7/19.
//

import UIKit

public extension PhotoAsset {
    
    typealias AssetURLCompletion = (Result<AssetURLResult, AssetError>) -> Void
    
    struct AssetURLResult {
        public enum URLType {
            /// 本地
            case local
            /// 网络
            case network
        }
        /// 地址
        public let url: URL
        /// URL类型
        public let urlType: URLType
        /// 媒体类型
        public let mediaType: PhotoAsset.MediaType
        
        /// LivePhoto里包含的资源
        /// selectOptions 需包含 livePhoto
        public let livePhoto: LivePhotoResult?
        
        public struct LivePhotoResult {
            /// 图片地址
            public let imageURL: URL
            /// 视频地址
            public let videoURL: URL
        }
        
        init(url: URL,
             urlType: URLType,
             mediaType: PhotoAsset.MediaType,
             livePhoto: LivePhotoResult? = nil) {
            self.url = url
            self.urlType = urlType
            self.mediaType = mediaType
            self.livePhoto = livePhoto
        }
    }
    
    /// 获取url
    ///   - completion: result 
    func getAssetURL(completion: @escaping AssetURLCompletion) {
        if mediaType == .photo {
            if mediaSubType == .livePhoto {
                getLivePhotoURL(completion: completion)
                return
            }
            getImageURL(completion: completion)
        }else {
            getVideoURL(completion: completion)
        }
    }
    
    /// 获取图片url
    ///   - completion: result
    func getImageURL(completion: @escaping AssetURLCompletion) {
        #if canImport(Kingfisher)
        if isNetworkAsset {
            getNetworkImageURL(resultHandler: completion)
            return
        }
        #endif
        requestImageURL(resultHandler: completion)
    }
    
    /// 获取视频url
    /// - Parameters:
    ///   - exportPreset: 导出质量，不传获取的就是原始视频
    ///   - completion: result
    func getVideoURL(exportPreset: String? = nil,
                     completion: @escaping AssetURLCompletion) {
        if isNetworkAsset {
            getNetworkVideoURL(resultHandler: completion)
            return
        }
        requestVideoURL(exportPreset: exportPreset, resultHandler: completion)
    }
    
    func getLivePhotoURL(completion: @escaping AssetURLCompletion) {
        requestLivePhotoURL(completion: completion)
    }
}
