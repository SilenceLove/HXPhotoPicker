//
//  Core+PHAsset.swift
//  HXPHPicker
//
//  Created by Slience on 2021/6/9.
//

import Photos

extension PHAsset: HXPickerCompatible {
    
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
        if let isCloud = isCloudPlaceholder, isCloud {
            return true
        }
        var isICloud = false
        if mediaType == .image {
            let options = PHImageRequestOptions()
            options.isSynchronous = true
            options.deliveryMode = .fastFormat
            options.resizeMode = .fast
            AssetManager.requestImageData(for: self, options: options) { (result) in
                switch result {
                case .failure(let error):
                    if let inICloud = error.info?.inICloud {
                        isICloud = inICloud
                    }
                default:
                    break
                }
            }
            return isICloud
        }else {
            return !isLocallayAvailable
        }
    }
    var isCloudPlaceholder: Bool? {
        if let isICloud = self.value(forKey: "isCloudPlaceholder") as? Bool {
            return isICloud
        }
        return nil
    }
    var isLocallayAvailable: Bool {
        if let isCloud = isCloudPlaceholder, isCloud {
            return false
        }
        let resourceArray = PHAssetResource.assetResources(for: self)
        let isLocallayAvailable = resourceArray.first?.value(forKey: "locallyAvailable") as? Bool ?? true
        return isLocallayAvailable
    }
    
    @discardableResult
    func checkAdjustmentStatus(completion: @escaping (Bool) -> Void) -> PHContentEditingInputRequestID {
        requestContentEditingInput(with: nil) { (input, info) in
            if let isCancel = info[PHContentEditingInputCancelledKey] as? Int, isCancel == 1 {
                return
            }
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

public extension HXPickerWrapper where Base: PHAsset {
    
    var isImageAnimated: Bool {
        base.isImageAnimated
    }
    
    var isLivePhoto: Bool {
        base.isLivePhoto
    }
    
    var inICloud: Bool {
        base.inICloud
    }
    var isCloudPlaceholder: Bool? {
        base.isCloudPlaceholder
    }
    var isLocallayAvailable: Bool {
        base.isLocallayAvailable
    }
    
    @discardableResult
    func checkAdjustmentStatus(
        completion: @escaping (Bool) -> Void
    ) -> PHContentEditingInputRequestID {
        base.checkAdjustmentStatus(completion: completion)
    }
}
