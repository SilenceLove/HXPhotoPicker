//
//  PhotoPickerController+PHPhotoLibrary.swift
//  HXPhotoPicker
//
//  Created by Slience on 2021/8/25.
//

import UIKit
import Photos

// MARK: PHPhotoLibraryChangeObserver
extension PhotoPickerController: PHPhotoLibraryChangeObserver {
    
    public func photoLibraryDidChange(_ changeInstance: PHChange) {
        if !config.allowLoadPhotoLibrary || !isDidEnterBackground {
            return
        }
        var needReload = false
        if fetchData.assetCollections.isEmpty {
            if let collection = fetchData.cameraAssetCollection {
                needReload = resultHasChanges(
                    for: changeInstance,
                    assetCollection: collection
                )
            }else {
                needReload = true
            }
        }else {
            let collectionArray = fetchData.assetCollections
            for assetCollection in collectionArray {
                let hasChanges = resultHasChanges(
                    for: changeInstance,
                    assetCollection: assetCollection
                )
                if !needReload {
                    needReload = hasChanges
                }
            }
        }
        if needReload {
            DispatchQueue.main.async {
                if !self.isDidEnterBackground {
                    return
                }
                if self.fetchData.cameraAssetCollection?.result == nil {
                    self.fetchData.fetchCameraAssetCollection()
                }else {
                    self.reloadData(assetCollection: nil)
                }
                self.fetchData.fetchAssetCollections()
            }
        }
    }
    private func resultHasChanges(
        for changeInstance: PHChange,
        assetCollection: PhotoAssetCollection
    ) -> Bool {
        guard let result = assetCollection.result else {
            if assetCollection == self.fetchData.cameraAssetCollection {
                return true
            }
            return false
        }
        let changeResult: PHFetchResultChangeDetails? = changeInstance.changeDetails(
            for: result
        )
        if let changeResult = changeResult {
            if changeResult.hasIncrementalChanges || !changeResult.removedObjects.isEmpty {
                let result = changeResult.fetchResultAfterChanges
                assetCollection.updateResult(for: result)
                if assetCollection == self.fetchData.cameraAssetCollection && result.count == 0 {
                    assetCollection.update(
                        albumName: .textManager.picker.albumList.emptyAlbumName.text,
                        coverImage: self.config.emptyCoverImageName.image
                    )
                }
                return true
            }
        }
        return false
    }
}
