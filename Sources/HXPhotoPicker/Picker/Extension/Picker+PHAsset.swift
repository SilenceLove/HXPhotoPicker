//
//  Picke+PHAsset.swift
//  HXPhotoPicker
//
//  Created by Slience on 2021/6/9.
//

import Photos
import UIKit

extension PHAsset {
    
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
            AssetManager.requestImageData(
                for: self,
                options: options
            ) { (result) in
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
        guard let isLocallayAvailable = resourceArray.first?.value(forKey: "locallyAvailable") as? Bool else {
            return true
        }
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
    
    private var aspectRatio: CGFloat {
        CGFloat(pixelWidth) / CGFloat(pixelHeight)
    }
    
    var targetSize: CGSize {
        let scale: CGFloat = UIScreen._scale
        let targetSize: CGSize
        if aspectRatio > 1 {
            let height = min(UIScreen._height, 500) * scale
            let width = height * aspectRatio
            targetSize = .init(width: width, height: height)
        }else {
            let width = min(UIScreen._width, 500) * scale
            let height = width / aspectRatio
            targetSize = .init(width: width, height: height)
        }
        return targetSize
    }
    
    var thumTargetSize: CGSize {
        let targetSize: CGSize
        if aspectRatio > 1 {
            let height = UIScreen._height
            let width = height * aspectRatio
            targetSize = .init(width: width, height: height)
        }else {
            let width = UIScreen._height
            let height = width / aspectRatio
            targetSize = .init(width: width, height: height)
        }
        return targetSize
    }
    
    func cellThumTargetSize(for targetWidth: CGFloat) -> CGSize {
        let scale: CGFloat = 0.8
        var width = targetWidth
        if pixelWidth < Int(targetWidth) {
            width *= 0.5
        }
        var height = width / aspectRatio
        let maxHeight = UIScreen._height
        if height > maxHeight {
            width = maxHeight / height * width * scale
            height = maxHeight * scale
        }
        if height < targetWidth && width >= targetWidth {
            width = targetWidth / height * width * scale
            height = targetWidth * scale
        }
        return CGSize(width: width, height: height)
    }
}
