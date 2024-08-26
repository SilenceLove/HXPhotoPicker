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
        if !config.allowLoadPhotoLibrary {
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
                if self.fetchData.cameraAssetCollection?.collection == nil {
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
        guard let resultCollection = assetCollection.collection else {
            if assetCollection == self.fetchData.cameraAssetCollection {
                return true
            }
            return false
        }
        
        if let changeResult: PHObjectChangeDetails = changeInstance.changeDetails(for: resultCollection),
           let collection = changeResult.objectAfterChanges {
            assetCollection.collection = collection
            assetCollection.fetchResult()
            if assetCollection.count == 0 {
                assetCollection.update(
                    albumName: .textManager.picker.albumList.emptyAlbumName.text,
                    coverImage: config.emptyCoverImageName.image
                )
            }
            return true
        }
        return false
    }
}
