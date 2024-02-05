//
//  PhotoFetchData.swift
//  HXPhotoPicker
//
//  Created by Silence on 2023/9/28.
//  Copyright © 2023 Silence. All rights reserved.
//

import UIKit
import Photos

public protocol PhotoFetchDataDelegate: AnyObject {
    func fetchData(
        _ fetchData: PhotoFetchData,
        didFetchAssetCollections collection: PHAssetCollection
    ) -> Bool
    
    func fetchData(
        _ fetchData: PhotoFetchData,
        didFetchAssets asset: PHAsset
    ) -> Bool
    
    func fetchData(fetchCameraAssetCollectionCompletion fetchData: PhotoFetchData)
    func fetchData(fetchAssetCollectionsCompletion fetchData: PhotoFetchData)
}

open class PhotoFetchData {
    
    public weak var delegate: PhotoFetchDataDelegate?
    
    public var assetCollections: [PhotoAssetCollection] = []
    public var cameraAssetCollection: PhotoAssetCollection?
    
    
    public let config: PickerConfiguration
    public let pickerData: PhotoPickerData
    
    let assetCollectionsQueue: OperationQueue
    let assetsQueue: OperationQueue
    
    /// fetch Assets 时的选项配置
    public var options: PHFetchOptions = .init()
    
    public required init(config: PickerConfiguration, pickerData: PhotoPickerData) {
        self.config = config
        self.pickerData = pickerData
        
        if !config.selectOptions.mediaTypes.contains(.image) {
            options.predicate = NSPredicate(
                format: "mediaType == %ld",
                argumentArray: [PHAssetMediaType.video.rawValue]
            )
        }else if !config.selectOptions.mediaTypes.contains(.video) {
            options.predicate = NSPredicate(
                format: "mediaType == %ld",
                argumentArray: [PHAssetMediaType.image.rawValue]
            )
        }else {
            options.predicate = nil
        }
        
        assetCollectionsQueue = OperationQueue()
        assetCollectionsQueue.maxConcurrentOperationCount = 1
        assetsQueue = OperationQueue()
        assetsQueue.maxConcurrentOperationCount = 1
    }
    
    /// 获取相机胶卷资源集合
    public func fetchCameraAssetCollection() {
        DispatchQueue.global().async {
            let fetchAssetCollection = self.config.fetchAssetCollection
            let assetCollection = fetchAssetCollection.fetchCameraAssetCollection(
                self.config,
                options: self.options
            )
            let cameraAssetCollection: PhotoAssetCollection
            if let assetCollection = assetCollection {
                cameraAssetCollection = assetCollection
                if assetCollection.count == 0 {
                    assetCollection.coverImage = self.config.emptyCoverImageName.image
                }
            }else {
                cameraAssetCollection = PhotoAssetCollection(
                    albumName: .textManager.picker.albumList.emptyAlbumName.text,
                    coverImage: self.config.emptyCoverImageName.image
                )
            }
            cameraAssetCollection.isSelected = true
            self.cameraAssetCollection = cameraAssetCollection
            DispatchQueue.main.async {
                self.delegate?.fetchData(fetchCameraAssetCollectionCompletion: self)
            }
        }
    }
    
    /// 获取相册集合
    public func fetchAssetCollections() {
        cancelAssetCollectionsQueue()
        let localAssets = pickerData.localAssets
        let localCameraAssets = pickerData.localCameraAssets
        let operation = BlockOperation()
        operation.addExecutionBlock { [unowned operation, weak self] in
            guard let self = self else { return }
            var localCount = localAssets.count + localCameraAssets.count
            var coverImage = localCameraAssets.first?.originalImage
            if coverImage == nil {
                coverImage = localAssets.first?.originalImage
            }
            var firstSetImage = true
            for photoAsset in self.pickerData.selectedAssets where photoAsset.phAsset == nil {
                if operation.isCancelled { return }
                let inLocal = localAssets.contains(
                    where: {
                    $0.isEqual(photoAsset)
                })
                let inLocalCamera = localCameraAssets.contains(
                    where: {
                        $0.isEqual(photoAsset)
                    }
                )
                if !inLocal && !inLocalCamera {
                    if firstSetImage {
                        coverImage = photoAsset.originalImage
                        firstSetImage = false
                    }
                    localCount += 1
                }
            }
            let assetCollections = self.config.fetchAssetCollection.fetchAssetCollections(
                self.config,
                localCount: localCount,
                coverImage: coverImage,
                options: self.options
            ) {
                if operation.isCancelled {
                    $1.pointee = true
                    return false
                }
                if let collection = $0.collection,
                    let shouldFetch = self.delegate?.fetchData(self, didFetchAssetCollections: collection) {
                    return shouldFetch
                }
                return true
            }
            self.assetCollections = []
            if var collection = assetCollections.first {
                if let cameraAssetCollection = self.cameraAssetCollection {
                    collection = cameraAssetCollection
                }else {
                    collection.isSelected = true
                    self.cameraAssetCollection = collection
                }
                collection.count += localCount
                if let coverImage = coverImage {
                    collection.realCoverImage = coverImage
                }
                self.assetCollections = assetCollections
                self.assetCollections[0] = collection
            }else {
                if let cameraAssetCollection = self.cameraAssetCollection {
                    cameraAssetCollection.count += localCount
                    if let coverImage = coverImage {
                        cameraAssetCollection.realCoverImage = coverImage
                    }
                    self.assetCollections.append(cameraAssetCollection)
                }
            }
            DispatchQueue.main.async {
                self.delegate?.fetchData(fetchAssetCollectionsCompletion: self)
            }
        }
        assetCollectionsQueue.addOperation(operation)
    }
    
    public func fetchPhotoAssets(
        assetCollection: PhotoAssetCollection,
        completion: @escaping (PhotoFetchAssetResult) -> Void
    ) {
        cancelFetchAssetsQueue()
        let localAssets = pickerData.localAssets
        let localCameraAssets = pickerData.localCameraAssets
        let operation = BlockOperation()
        operation.addExecutionBlock { [unowned operation, weak self] in
            if operation.isCancelled { return }
            guard let self = self else { return}
            localAssets.forEach { $0.isSelected = false }
            localCameraAssets.forEach { $0.isSelected = false }
            let result = self.config.fetchAsset.fetchPhotoAssets(
                self.config,
                pickerData: self.pickerData,
                assetCollection: assetCollection
            ) {
                if operation.isCancelled {
                    $1.pointee = true
                    return false
                }
                if let phAsset = $0.phAsset,
                    let shouldFetch = self.delegate?.fetchData(self, didFetchAssets: phAsset) {
                    return shouldFetch
                }
                return true
            }
            if operation.isCancelled { return }
            DispatchQueue.main.async {
                completion(result)
            }
        }
        assetsQueue.addOperation(operation)
    }
    
    /// 更新相册资源
    /// - Parameters:
    ///   - coverImage: 封面图片
    ///   - count: 需要累加的数量
    public func updateAlbums(coverImage: UIImage?, count: Int) {
        for assetCollection in assetCollections {
            if assetCollection.realCoverImage != nil {
                assetCollection.realCoverImage = coverImage
            }
            assetCollection.count += count
        }
    }
    
    private func cancelAssetCollectionsQueue() {
        assetCollectionsQueue.cancelAllOperations()
    }
    
    private func cancelFetchAssetsQueue() {
        assetsQueue.cancelAllOperations()
    }
    
    deinit {
        cancelFetchAssetsQueue()
        cancelAssetCollectionsQueue()
    }
}
