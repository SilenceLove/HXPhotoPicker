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
            }
            if self.config.albumShowMode == .popup {
                self.fetchAssetCollections()
            }
            self.fetchCameraAssetCollectionCompletion?(self.cameraAssetCollection)
        }
    }
    
    /// 获取相册集合
    func fetchAssetCollections() {
        cancelAssetCollectionsQueue()
        let operation = BlockOperation()
        operation.addExecutionBlock { [unowned operation] in
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
                    where: {
                    $0.isEqual(phAsset)
                })
                let inLocalCamera = self.localCameraAssetArray.contains(
                    where: {
                        $0.isEqual(phAsset)
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
            if operation.isCancelled {
                return
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
            ) { [weak self] (assetCollection, isCameraRoll, stop) in
                guard let self = self else {
                    stop.pointee = true
                    return
                }
                if operation.isCancelled {
                    stop.pointee = true
                    return
                }
                if let assetCollection = assetCollection {
                    if let collection = assetCollection.collection,
                       let canAdd = self.pickerDelegate?.pickerController(self, didFetchAssetCollections: collection) {
                        if !canAdd {
                            return
                        }
                    }
                    assetCollection.count += localCount
                    if isCameraRoll {
                        self.assetCollectionsArray.insert(assetCollection, at: 0)
                    }else {
                        self.assetCollectionsArray.append(assetCollection)
                    }
                }else {
                    if let cameraAssetCollection = self.cameraAssetCollection {
                        self.cameraAssetCollection?.count += localCount
                        if coverImage != nil {
                            self.cameraAssetCollection?.realCoverImage = coverImage
                        }
                        if !self.assetCollectionsArray.isEmpty {
                            self.assetCollectionsArray[0] = cameraAssetCollection
                        }else {
                            self.assetCollectionsArray.append(cameraAssetCollection)
                        }
                    }
                    DispatchQueue.main.async {
                        self.fetchAssetCollectionsCompletion?(self.assetCollectionsArray)
                    }
                }
            }
        }
        assetCollectionsQueue.addOperation(operation)
    }
    func cancelAssetCollectionsQueue() {
        assetCollectionsQueue.cancelAllOperations()
    }
    private func getSelectAsset() -> ([PHAsset], [PhotoAsset]) {
        var selectedAssets = [PHAsset]()
        var selectedPhotoAssets: [PhotoAsset] = []
        var localIndex = -1
        for (index, photoAsset) in selectedAssetArray.enumerated() {
            if config.selectMode == .single {
                break
            }
            photoAsset.selectIndex = index
            photoAsset.isSelected = true
            if let phAsset = photoAsset.phAsset {
                selectedAssets.append(phAsset)
                selectedPhotoAssets.append(photoAsset)
            }else {
                let inLocal = localAssetArray
                    .contains {
                    if $0.isEqual(photoAsset) {
                        localAssetArray[localAssetArray.firstIndex(of: $0)!] = photoAsset
                        return true
                    }
                    return false
                }
                let inLocalCamera = localCameraAssetArray
                    .contains(where: {
                    if $0.isEqual(photoAsset) {
                        localCameraAssetArray[
                            localCameraAssetArray.firstIndex(of: $0)!
                        ] = photoAsset
                        return true
                    }
                    return false
                })
                if !inLocal && !inLocalCamera {
                    if photoAsset.localIndex > localIndex {
                        localIndex = photoAsset.localIndex
                        localAssetArray.insert(photoAsset, at: 0)
                    }else {
                        if localIndex == -1 {
                            localIndex = photoAsset.localIndex
                            localAssetArray.insert(photoAsset, at: 0)
                        }else {
                            localAssetArray.insert(photoAsset, at: 1)
                        }
                    }
                }
            }
        }
        return (selectedAssets, selectedPhotoAssets)
    }
    /// 获取相册里的资源
    /// - Parameters:
    ///   - assetCollection: 相册
    ///   - completion: 完成回调
    func fetchPhotoAssets(
        assetCollection: PhotoAssetCollection?,
        completion: (([PhotoAsset], PhotoAsset?, Int, Int) -> Void)?
    ) {
        cancelFetchAssetsQueue()
        let operation = BlockOperation()
        operation.addExecutionBlock { [unowned operation] in
            var photoCount = 0
            var videoCount = 0
            self.localAssetArray.forEach { $0.isSelected = false }
            self.localCameraAssetArray.forEach { $0.isSelected = false }
            let result = self.getSelectAsset()
            let selectedAssets = result.0
            let selectedPhotoAssets = result.1
            var localAssets: [PhotoAsset] = []
            if operation.isCancelled {
                return
            }
            localAssets.append(contentsOf: self.localCameraAssetArray.reversed())
            localAssets.append(contentsOf: self.localAssetArray)
            var photoAssets = [PhotoAsset]()
            photoAssets.reserveCapacity(assetCollection?.count ?? 10)
            var lastAsset: PhotoAsset?
            assetCollection?.enumerateAssets( usingBlock: { [weak self] (photoAsset, index, stop) in
                guard let self = self,
                      let phAsset = photoAsset.phAsset
                else {
                    stop.pointee = true
                    return
                }
                if operation.isCancelled {
                    stop.pointee = true
                    return
                }
                if let canAdd = self.pickerDelegate?.pickerController(self, didFetchAssets: phAsset) {
                    if !canAdd {
                        return
                    }
                }
                if self.selectOptions.contains(.gifPhoto) {
                    if phAsset.isImageAnimated {
                        photoAsset.mediaSubType = .imageAnimated
                    }
                }
                if self.config.selectOptions.contains(.livePhoto) {
                    if phAsset.isLivePhoto {
                        photoAsset.mediaSubType = .livePhoto
                    }
                }
                
                switch photoAsset.mediaType {
                case .photo:
                    if !self.selectOptions.isPhoto {
                        return
                    }
                    photoCount += 1
                case .video:
                    if !self.selectOptions.isVideo {
                        return
                    }
                    videoCount += 1
                }
                var asset = photoAsset
                if let index = selectedAssets.firstIndex(of: phAsset) {
                    let selectPhotoAsset = selectedPhotoAssets[index]
                    asset = selectPhotoAsset
                    lastAsset = selectPhotoAsset
                }
                photoAssets.append(asset)
            })
            if self.config.photoList.showAssetNumber {
                localAssets.forEach {
                    if $0.mediaType == .photo {
                        photoCount += 1
                    }else {
                        videoCount += 1
                    }
                }
            }
            photoAssets.append(contentsOf: localAssets.reversed())
            if self.config.photoList.sort == .desc {
                photoAssets.reverse()
            }
            if operation.isCancelled {
                return
            }
            DispatchQueue.main.async {
                completion?(photoAssets, lastAsset, photoCount, videoCount)
            }
        }
        assetsQueue.addOperation(operation)
    }
    func cancelFetchAssetsQueue() {
        assetsQueue.cancelAllOperations()
    }
}
