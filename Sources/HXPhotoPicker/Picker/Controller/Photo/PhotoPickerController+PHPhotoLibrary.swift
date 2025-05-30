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
                if !needReload, assetCollection.isSelected {
                    needReload = hasChanges
                }
            }
        }
        if needReload {
            DispatchQueue.main.async {
                if self.fetchData.cameraAssetCollection?.collection == nil {
                    self.fetchData.fetchCameraAssetCollection()
                }else {
                    let captureTime = PhotoManager.shared.pickerCaptureTime
                    if captureTime > 0 {
                        let time = Date().timeIntervalSince1970 - captureTime
                        if time > 1 {
                            self.reloadData(assetCollection: nil)
                        }
                        PhotoManager.shared.pickerCaptureTime = 0
                    }else {
                        self.reloadData(assetCollection: nil)
                    }
                }
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
        if let changeResult  = changeInstance.changeDetails(for: result) {
            if changeResult.hasIncrementalChanges {
                if changeResult.insertedObjects.isEmpty && changeResult.removedObjects.isEmpty && !changeResult.hasMoves {
                    return false
                }
            }
            let fetchAssetCollection = fetchData.config.fetchAssetCollection
            fetchAssetCollection.enumerateAllAlbums(options: nil) { collection, _, stop in
                if collection.localIdentifier == assetCollection.collection?.localIdentifier {
                    assetCollection.collection = collection
                    stop.initialize(to: true)
                }
            }
            assetCollection.result = changeResult.fetchResultAfterChanges
            assetCollection.count = changeResult.fetchResultAfterChanges.count
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
