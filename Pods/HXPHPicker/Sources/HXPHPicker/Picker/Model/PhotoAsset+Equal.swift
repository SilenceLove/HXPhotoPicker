//
//  PhotoAsset+Equal.swift
//  HXPHPicker
//
//  Created by Slience on 2021/8/25.
//

import UIKit

public extension PhotoAsset {
    
    /// 判断是否是同一个 PhotoAsset 对象
    func isEqual(_ photoAsset: PhotoAsset?) -> Bool {
        if let photoAsset = photoAsset {
            if self === photoAsset {
                return true
            }
            if let localIdentifier = phAsset?.localIdentifier,
               let phLocalIdentifier = photoAsset.phAsset?.localIdentifier,
               localIdentifier == phLocalIdentifier {
                return true
            }
            if localAssetIdentifier == photoAsset.localAssetIdentifier {
                return true
            }
            #if canImport(Kingfisher)
            if let networkImageAsset = networkImageAsset,
               let phNetworkImageAsset = photoAsset.networkImageAsset {
                if networkImageAsset.originalURL == phNetworkImageAsset.originalURL {
                    return true
                }
            }
            #endif
            if let localImageAsset = localImageAsset,
               let phLocalImageAsset = photoAsset.localImageAsset {
                if let localImage = localImageAsset.image,
                   let phLocalImage = phLocalImageAsset.image,
                   localImage == phLocalImage {
                    return true
                }
                if let localImageURL = localImageAsset.imageURL,
                   let phLocalImageURL = phLocalImageAsset.imageURL,
                   localImageURL == phLocalImageURL {
                    return true
                }
            }
            if let localLivePhoto = localLivePhoto,
               let phLocalLivePhoto = photoAsset.localLivePhoto {
                if localLivePhoto.imageURL.path == phLocalLivePhoto.imageURL.path &&
                    localLivePhoto.videoURL.path == phLocalLivePhoto.videoURL.path {
                    return true
                }
            }
            if let localVideoAsset = localVideoAsset,
               let phLocalVideoAsset = photoAsset.localVideoAsset {
                if localVideoAsset.videoURL == phLocalVideoAsset.videoURL {
                    return true
                }
            }
            if let networkVideoAsset = networkVideoAsset,
               let phNetworkVideoAsset = photoAsset.networkVideoAsset {
                if networkVideoAsset.videoURL.absoluteString == phNetworkVideoAsset.videoURL.absoluteString {
                    return true
                }
            }
            if let phAsset = phAsset, phAsset == photoAsset.phAsset {
                return true
            }
        }
        return false
    }
}
