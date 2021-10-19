//
//  PhotoPickerController+PHPhotoLibrary.swift
//  HXPHPicker
//
//  Created by Slience on 2021/8/25.
//

import UIKit
import Photos

// MARK: PHPhotoLibraryChangeObserver
extension PhotoPickerController: PHPhotoLibraryChangeObserver {
    
    public func photoLibraryDidChange(_ changeInstance: PHChange) {
        if !AssetManager.authorizationStatusIsLimited() || !config.allowLoadPhotoLibrary {
            return
        }
        var needReload = false
        if assetCollectionsArray.isEmpty {
            if let collection = cameraAssetCollection {
                needReload = resultHasChanges(
                    for: changeInstance,
                    assetCollection: collection
                )
            }else {
                needReload = true
            }
        }else {
            let collectionArray = assetCollectionsArray
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
                if self.cameraAssetCollection?.result == nil {
                    self.fetchCameraAssetCollection()
                }else {
                    self.reloadData(assetCollection: nil)
                }
                self.fetchAssetCollections()
            }
        }
    }
    private func resultHasChanges(
        for changeInstance: PHChange,
        assetCollection: PhotoAssetCollection
    ) -> Bool {
        if assetCollection.result == nil {
            if assetCollection == self.cameraAssetCollection {
                return true
            }
            return false
        }
        let changeResult: PHFetchResultChangeDetails? = changeInstance.changeDetails(
            for: assetCollection.result!
        )
        if changeResult != nil {
            if !changeResult!.hasIncrementalChanges {
                let result = changeResult!.fetchResultAfterChanges
                assetCollection.changeResult(for: result)
                if assetCollection == self.cameraAssetCollection && result.count == 0 {
                    assetCollection.change(
                        albumName: self.config.albumList.emptyAlbumName.localized,
                        coverImage: self.config.albumList.emptyCoverImageName.image
                    )
                }
                return true
            }
        }
        return false
    }
}
