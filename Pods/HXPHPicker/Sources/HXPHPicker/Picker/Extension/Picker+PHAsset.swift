//
//  Picker+PHAsset.swift
//  HXPHPicker
//
//  Created by Slience on 2021/1/7.
//

import Photos

 public extension PHAsset {
    
    var isImageAnimated: Bool {
        var isAnimated : Bool = false
        let fileName = value(forKey: "filename") as? String
        if fileName != nil {
            isAnimated = fileName!.hasSuffix("GIF")
        }
        if #available(iOS 11, *) {
            if playbackStyle == .imageAnimated {
                isAnimated = true
            }
        }
        return isAnimated
    }
    
    var isLivePhoto: Bool {
        var isLivePhoto : Bool = false
        if #available(iOS 9.1, *) {
            isLivePhoto = mediaSubtypes == .photoLive
            if #available(iOS 11, *) {
                if playbackStyle == .livePhoto {
                    isLivePhoto = true
                }
            }
        }
        return isLivePhoto
    }
    
    /// 如果在获取到PHAsset之前还未下载的iCloud，之后下载了还是会返回存在
    var inICloud: Bool {
        var isICloud = false
        if mediaType == PHAssetMediaType.image {
            let options = PHImageRequestOptions.init()
            options.isSynchronous = true
            options.deliveryMode = .fastFormat
            options.resizeMode = .fast
            AssetManager.requestImageData(for: self, options: options) { (imageData, dataUTI, orientation, info) in
                if imageData == nil && AssetManager.assetIsInCloud(for: info) {
                    isICloud = true
                }
            }
        }else if mediaType == PHAssetMediaType.video {
            let resourceArray = PHAssetResource.assetResources(for: self)
            let bIsLocallayAvailable = resourceArray.first?.value(forKey: "locallyAvailable") as? Bool ?? true
            if !bIsLocallayAvailable {
                isICloud = true
            }
        }
        return isICloud
    }
}
