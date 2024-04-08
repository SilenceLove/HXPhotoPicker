//
//  PhotoAsset+Equatable.swift
//  HXPhotoPicker
//
//  Created by Silence on 2023/10/14.
//  Copyright © 2023 Silence. All rights reserved.
//

import Foundation

public extension PhotoAsset {
    func isEqual(_ photoAsset: PhotoAsset?) -> Bool {
        guard let photoAsset = photoAsset else {
            return false
        }
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
            if networkVideoAsset.videoURL?.absoluteString == phNetworkVideoAsset.videoURL?.absoluteString {
                return true
            }
        }
        if let phAsset = phAsset, phAsset == photoAsset.phAsset {
            return true
        }
        return false
    }
}
