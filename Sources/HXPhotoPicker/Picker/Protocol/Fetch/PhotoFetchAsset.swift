//
//  PhotoFetchAsset.swift
//  HXPhotoPicker
//
//  Created by Silence on 2023/9/25.
//  Copyright © 2023 洪欣. All rights reserved.
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
        var photoCount = 0
        var videoCount = 0
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
            photoAssets.append(asset)
        }
        if config.photoList.isShowAssetNumber {
            localAssets.forEach {
                if $0.mediaType == .photo {
                    photoCount += 1
                }else {
                    videoCount += 1
                }
            }
        }
        photoAssets.append(contentsOf: localAssets.reversed())
        if config.photoList.sort == .desc {
            photoAssets.reverse()
        }
        return .init(assets: photoAssets, selectedAsset: selectedAsset, photoCount: photoCount, videoCount: videoCount)
    }
}

public struct PhotoFetchAssetResult {
    /// 相册里的`PhotoAsst`对象
    let assets: [PhotoAsset]
    /// 相册列表滚动到指定的 `PhotoAsset`
    let selectedAsset: PhotoAsset?
    /// 相册里的照片数量
    let photoCount: Int
    /// 相册里的视频数量
    let videoCount: Int
    
    public init(assets: [PhotoAsset] = [], selectedAsset: PhotoAsset? = nil, photoCount: Int = 0, videoCount: Int = 0) {
        self.assets = assets
        self.selectedAsset = selectedAsset
        self.photoCount = photoCount
        self.videoCount = videoCount
    }
}
