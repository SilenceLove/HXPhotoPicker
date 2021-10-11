//
//  Core+PHAsset.swift
//  HXPHPicker
//
//  Created by Slience on 2021/6/9.
//

import Photos

public extension PHAsset {
    
    var isImageAnimated: Bool {
        var isAnimated: Bool = false
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
        var isLivePhoto: Bool = false
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
        var hasICloud = false
        let options = PHImageRequestOptions()
        options.isSynchronous = true
        options.deliveryMode = .fastFormat
        options.resizeMode = .fast
        AssetManager.requestImageData(for: self, options: options) { (result) in
            switch result {
            case .failure(let error):
                if let inICloud = error.info?.inICloud {
                    isICloud = inICloud
                    hasICloud = true
                }
            default:
                break
            }
        }
        if hasICloud {
            return isICloud
        }
        if mediaType == PHAssetMediaType.video {
            isICloud = !isLocallayAvailable
        }
        return isICloud
    }
    
    var isLocallayAvailable: Bool {
        if let isICloud = self.value(forKey: "isCloudPlaceholder") as? Bool,
           isICloud {
            return false
        }
        let resourceArray = PHAssetResource.assetResources(for: self)
        let isLocallayAvailable = resourceArray.first?.value(forKey: "locallyAvailable") as? Bool ?? true
        return isLocallayAvailable
    }
    
    func checkAdjustmentStatus(completion: @escaping (Bool) -> Void) {
        self.requestContentEditingInput(with: nil) { (input, info) in
            let avAsset = input?.audiovisualAsset
            var isAdjusted: Bool = false
            if let path = avAsset != nil ? avAsset?.description : input?.fullSizeImageURL?.path {
                if path.contains("/Mutations/") {
                    isAdjusted = true
                }
            }
            completion(isAdjusted)
        }
    }
}
