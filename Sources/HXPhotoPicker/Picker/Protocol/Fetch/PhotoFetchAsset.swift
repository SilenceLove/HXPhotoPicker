//
//  PhotoFetchAsset.swift
//  HXPhotoPicker
//
//  Created by Silence on 2023/9/25.
//  Copyright © 2023 Silence. All rights reserved.
//

import UIKit
import Photos

public struct DefaultPhotoFetchAsset: PhotoFetchAsset { }

public protocol PhotoFetchAsset {
    
    /// 获取相册`PhotoAssetCollection` 里的资源
    static func fetchPhotoAssets(
        _ config: PickerConfiguration,
        pickerData: PhotoPickerData,
        assetCollection: PhotoAssetCollection,
        usingBlock: @escaping (PhotoAsset, UnsafeMutablePointer<ObjCBool>) -> Bool
    ) -> PhotoFetchAssetResult
}

public extension PhotoFetchAsset {
    
    static func fetchPhotoAssets(
        _ config: PickerConfiguration,
        pickerData: PhotoPickerData,
        assetCollection: PhotoAssetCollection,
        usingBlock: @escaping (PhotoAsset, UnsafeMutablePointer<ObjCBool>) -> Bool
    ) -> PhotoFetchAssetResult {
        let localAssets: [PhotoAsset] = pickerData.localCameraAssets.reversed() + pickerData.localAssets
        var photoAssets: [PhotoAsset] = []
        photoAssets.reserveCapacity(assetCollection.count)
        var selectedPHAssets: [PHAsset] = []
        var selectedPhotoAssets: [PhotoAsset] = []
        if config.selectMode != .single {
            let result = pickerData.selectResult
            selectedPHAssets = result.phAssets
            selectedPhotoAssets = result.photoAssets
        }
        var selectedAsset: PhotoAsset?
        var normalAssets: [PhotoAsset] = []
        var gifAssets: [PhotoAsset] = []
        var livePhotoAssets: [PhotoAsset] = []
        var videoAssets: [PhotoAsset] = []
        var photoCount = 0
        var videoCount = 0
        var phAssetResult: [PHAsset] = []
        let isLimited = AssetPermissionsUtil.isLimitedAuthorizationStatus && config.isRemoveSelectedAssetWhenRemovingAssets
        assetCollection.enumerateAssets { photoAsset, index, stop in
            guard let phAsset = photoAsset.phAsset else {
                return
            }
            if !usingBlock(photoAsset, stop) {
                return
            }
            if config.selectOptions.contains(.gifPhoto) {
                if phAsset.isImageAnimated {
                    photoAsset.mediaSubType = .imageAnimated
                }
            }
            if config.selectOptions.contains(.livePhoto) {
                if phAsset.isLivePhoto {
                    photoAsset.mediaSubType = .livePhoto
                }
            }
            
            switch photoAsset.mediaType {
            case .photo:
                if !config.selectOptions.isPhoto {
                    return
                }
                photoCount += 1
            case .video:
                if !config.selectOptions.isVideo {
                    return
                }
                videoCount += 1
            }
            var asset = photoAsset
            if let index = selectedPHAssets.firstIndex(of: phAsset) {
                let selectPhotoAsset = selectedPhotoAssets[index]
                asset = selectPhotoAsset
                selectedAsset = selectPhotoAsset
            }
            if isLimited {
                phAssetResult.append(phAsset)
            }
            photoAssets.append(asset)
            if config.isFetchDeatilsAsset {
                if asset.mediaSubType.isNormalPhoto {
                    normalAssets.append(asset)
                }
                if asset.mediaSubType.isLivePhoto {
                    livePhotoAssets.append(asset)
                }
                if asset.mediaSubType.isGif {
                    gifAssets.append(asset)
                }
                if asset.mediaType == .video {
                    videoAssets.append(asset)
                }
            }
        }
        if isLimited {
            var removedAssets: [PhotoAsset] = []
            for (index, selectedPHAsset) in selectedPHAssets.enumerated() where !phAssetResult.contains(selectedPHAsset) {
                let resultCount = PHAsset.fetchAssets(withLocalIdentifiers: [selectedPHAsset.localIdentifier], options: nil).count
                if resultCount != 0 {
                    continue
                }
                let photoAsset = selectedPhotoAssets[index]
                pickerData.remove(photoAsset)
                removedAssets.append(photoAsset)
            }
            DispatchQueue.main.async {
                pickerData.delegate?.pickerData(pickerData, removeSelectedAssetWhenRemovingAssets: removedAssets)
            }
        }
        for asset in localAssets.reversed() {
            photoAssets.append(asset)
            if config.isFetchDeatilsAsset {
                if asset.mediaSubType.isNormalPhoto {
                    normalAssets.append(asset)
                }
                if asset.mediaSubType.isLivePhoto {
                    livePhotoAssets.append(asset)
                }
                if asset.mediaSubType.isGif {
                    gifAssets.append(asset)
                }
                if asset.mediaType == .video {
                    videoAssets.append(asset)
                }
            }
            if config.photoList.isShowAssetNumber {
                if asset.mediaType == .photo {
                    photoCount += 1
                }else {
                    videoCount += 1
                }
            }
        }
        if config.photoList.sort == .desc {
            photoAssets.reverse()
            if config.isFetchDeatilsAsset {
                normalAssets.reverse()
                livePhotoAssets.reverse()
                gifAssets.reverse()
                videoAssets.reverse()
            }
        }
        return .init(
            assets: photoAssets,
            selectedAsset: selectedAsset,
            normalAssets: normalAssets,
            gifAssets: gifAssets,
            livePhotoAssets: livePhotoAssets,
            videoAssets: videoAssets,
            photoCount: photoCount,
            videoCount: videoCount
        )
    }
}

public struct PhotoFetchAssetResult {
    /// 相册里的`PhotoAsst`对象
    public let assets: [PhotoAsset]
    /// 相册列表滚动到指定的 `PhotoAsset`
    public let selectedAsset: PhotoAsset?
    
    /// 普通照片 Asset
    public let normalAssets: [PhotoAsset]
    /// GIF Asset
    public let gifAssets: [PhotoAsset]
    /// LivePhoto Asset
    public let livePhotoAssets: [PhotoAsset]
    /// 视频 Asset
    public let videoAssets: [PhotoAsset]
    
    public let photoCount: Int
    public let videoCount: Int
    
    public init(
        assets: [PhotoAsset] = [],
        selectedAsset: PhotoAsset? = nil,
        normalAssets: [PhotoAsset] = [],
        gifAssets: [PhotoAsset] = [],
        livePhotoAssets: [PhotoAsset] = [],
        videoAssets: [PhotoAsset] = [],
        photoCount: Int = 0,
        videoCount: Int = 0
    ) {
        self.assets = assets
        self.selectedAsset = selectedAsset
        self.normalAssets = normalAssets
        self.gifAssets = gifAssets
        self.livePhotoAssets = livePhotoAssets
        self.videoAssets = videoAssets
        self.photoCount = photoCount
        self.videoCount = videoCount
    }
}
