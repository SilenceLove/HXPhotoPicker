//
//  PhotoPickerController+FetchAsset.swift
//  HXPHPicker
//
//  Created by Slience on 2021/8/25.
//

import UIKit
import Photos

// MARK: fetch Asset
extension PhotoPickerController {
    
    func fetchData(status: PHAuthorizationStatus) {
        if status.rawValue >= 3 {
            PHPhotoLibrary.shared().register(self)
            // 有权限
            ProgressHUD.showLoading(addedTo: view, afterDelay: 0.15, animated: true)
            fetchCameraAssetCollection()
        }else if status.rawValue >= 1 {
            // 无权限
            view.addSubview(deniedView)
        }
    }
    
    /// 获取相机胶卷资源集合
    func fetchCameraAssetCollection() {
        if !config.allowLoadPhotoLibrary {
            if cameraAssetCollection == nil {
                cameraAssetCollection = PhotoAssetCollection(
                    albumName: config.albumList.emptyAlbumName.localized,
                    coverImage: config.albumList.emptyCoverImageName.image
                )
            }
            fetchCameraAssetCollectionCompletion?(cameraAssetCollection)
            return
        }
        if config.creationDate {
            options.sortDescriptors = [NSSortDescriptor.init(key: "creationDate", ascending: config.creationDate)]
        }
        PhotoManager.shared.fetchCameraAssetCollection(
            for: selectOptions,
            options: options
        ) { [weak self] (assetCollection) in
            guard let self = self else { return }
            if assetCollection.count == 0 {
                self.cameraAssetCollection = PhotoAssetCollection(
                    albumName: self.config.albumList.emptyAlbumName.localized,
                    coverImage: self.config.albumList.emptyCoverImageName.image
                )
            }else {
                // 获取封面
                self.cameraAssetCollection = assetCollection
                self.cameraAssetCollection?.fetchCoverAsset()
            }
            if self.config.albumShowMode == .popup {
                self.fetchAssetCollections()
            }
            self.fetchCameraAssetCollectionCompletion?(self.cameraAssetCollection)
        }
    }
    
    /// 获取相册集合
    func fetchAssetCollections() {
        assetCollectionsQueue.cancelAllOperations()
        let operation = BlockOperation.init {
            if self.config.creationDate {
                self.options.sortDescriptors = [
                    NSSortDescriptor(
                        key: "creationDate",
                        ascending: self.config.creationDate
                    )
                ]
            }
            self.assetCollectionsArray = []
            
            var localCount = self.localAssetArray.count + self.localCameraAssetArray.count
            var coverImage = self.localCameraAssetArray.first?.originalImage
            if coverImage == nil {
                coverImage = self.localAssetArray.first?.originalImage
            }
            var firstSetImage = true
            for phAsset in self.selectedAssetArray where
                phAsset.phAsset == nil {
                let inLocal = self.localAssetArray.contains(
                    where: { (localAsset) -> Bool in
                    return localAsset.isEqual(phAsset)
                })
                let inLocalCamera = self.localCameraAssetArray.contains(
                    where: { (localAsset) -> Bool in
                        return localAsset.isEqual(phAsset)
                    }
                )
                if !inLocal && !inLocalCamera {
                    if firstSetImage {
                        coverImage = phAsset.originalImage
                        firstSetImage = false
                    }
                    localCount += 1
                }
            }
            if !self.config.allowLoadPhotoLibrary {
                DispatchQueue.main.async {
                    self.cameraAssetCollection?.realCoverImage = coverImage
                    self.cameraAssetCollection?.count += localCount
                    self.assetCollectionsArray.append(self.cameraAssetCollection!)
                    self.fetchAssetCollectionsCompletion?(self.assetCollectionsArray)
                }
                return
            }
            PhotoManager.shared.fetchAssetCollections(
                for: self.options,
                showEmptyCollection: false
            ) { [weak self] (assetCollection, isCameraRoll) in
                guard let self = self else { return }
                if assetCollection != nil {
                    // 获取封面
                    assetCollection?.fetchCoverAsset()
                    assetCollection?.count += localCount
                    if isCameraRoll {
                        self.assetCollectionsArray.insert(assetCollection!, at: 0)
                    }else {
                        self.assetCollectionsArray.append(assetCollection!)
                    }
                }else {
                    if self.cameraAssetCollection != nil {
                        self.cameraAssetCollection?.count += localCount
                        if coverImage != nil {
                            self.cameraAssetCollection?.realCoverImage = coverImage
                        }
                        if !self.assetCollectionsArray.isEmpty {
                            self.assetCollectionsArray[0] = self.cameraAssetCollection!
                        }else {
                            self.assetCollectionsArray.append(self.cameraAssetCollection!)
                        }
                    }
                    DispatchQueue.main.async {
                        if let operation =
                            self.assetCollectionsQueue.operations.first {
                            if operation.isCancelled {
                                return
                            }
                        }
                        self.fetchAssetCollectionsCompletion?(self.assetCollectionsArray)
                    }
                }
            }
        }
        assetCollectionsQueue.addOperation(operation)
    }
    /// 获取相册里的资源
    /// - Parameters:
    ///   - assetCollection: 相册
    ///   - completion: 完成回调
    func fetchPhotoAssets(
        assetCollection: PhotoAssetCollection?,
        completion: @escaping ([PhotoAsset], PhotoAsset?) -> Void
    ) {
        DispatchQueue.global().async {
            for photoAsset in self.localAssetArray {
                photoAsset.isSelected = false
            }
            for photoAsset in self.localCameraAssetArray {
                photoAsset.isSelected = false
            }
            var selectedAssets = [PHAsset]()
            var selectedPhotoAssets: [PhotoAsset] = []
            var localAssets: [PhotoAsset] = []
            var localIndex = -1
            for (index, photoAsset) in self.selectedAssetArray.enumerated() {
                if self.config.selectMode == .single {
                    break
                }
                photoAsset.selectIndex = index
                photoAsset.isSelected = true
                if let phAsset = photoAsset.phAsset {
                    selectedAssets.append(phAsset)
                    selectedPhotoAssets.append(photoAsset)
                }else {
                    let inLocal = self
                        .localAssetArray
                        .contains { (localAsset) -> Bool in
                        if localAsset.isEqual(photoAsset) {
                            self.localAssetArray[self.localAssetArray.firstIndex(of: localAsset)!] = photoAsset
                            return true
                        }
                        return false
                    }
                    let inLocalCamera = self
                        .localCameraAssetArray
                        .contains(where: { (localAsset) -> Bool in
                        if localAsset.isEqual(photoAsset) {
                            self.localCameraAssetArray[
                                self.localCameraAssetArray.firstIndex(of: localAsset)!
                            ] = photoAsset
                            return true
                        }
                        return false
                    })
                    if !inLocal && !inLocalCamera {
                        if photoAsset.localIndex > localIndex {
                            localIndex = photoAsset.localIndex
                            self.localAssetArray.insert(photoAsset, at: 0)
                        }else {
                            if localIndex == -1 {
                                localIndex = photoAsset.localIndex
                                self.localAssetArray.insert(photoAsset, at: 0)
                            }else {
                                self.localAssetArray.insert(photoAsset, at: 1)
                            }
                        }
                    }
                }
            }
            localAssets.append(contentsOf: self.localCameraAssetArray.reversed())
            localAssets.append(contentsOf: self.localAssetArray)
            var photoAssets = [PhotoAsset]()
            photoAssets.reserveCapacity(assetCollection?.count ?? 10)
            var lastAsset: PhotoAsset?
            assetCollection?.enumerateAssets(
                usingBlock: { [weak self] (photoAsset, index, stop) in
                guard let self = self else { return }
                if self.selectOptions.contains(.gifPhoto) {
                    if photoAsset.phAsset!.isImageAnimated {
                        photoAsset.mediaSubType = .imageAnimated
                    }
                }
                if self.config.selectOptions.contains(.livePhoto) {
                    if photoAsset.phAsset!.isLivePhoto {
                        photoAsset.mediaSubType = .livePhoto
                    }
                }
                
                switch photoAsset.mediaType {
                case .photo:
                    if !self.selectOptions.isPhoto {
                        return
                    }
                case .video:
                    if !self.selectOptions.isVideo {
                        return
                    }
                }
                var asset = photoAsset
                if selectedAssets.contains(asset.phAsset!) {
                    let index = selectedAssets.firstIndex(of: asset.phAsset!)!
                    let phAsset: PhotoAsset = selectedPhotoAssets[index]
                    asset = phAsset
                    lastAsset = phAsset
                }
//                if self.config.photoList.sort == .desc {
//                    photoAssets.insert(asset, at: 0)
//                }else {
                    photoAssets.append(asset)
//                }
            })
            if self.config.photoList.sort == .desc {
                photoAssets.reverse()
                photoAssets.insert(contentsOf: localAssets, at: 0)
            }else {
                photoAssets.append(contentsOf: localAssets.reversed())
            }
            DispatchQueue.main.async {
                completion(photoAssets, lastAsset)
            }
        }
    }
}
