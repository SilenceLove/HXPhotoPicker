//
//  PhotoPickerController+PickerData.swift
//  HXPhotoPicker
//
//  Created by Slience on 2021/8/25.
//

import UIKit
import Photos

extension PhotoPickerController: PhotoPickerDataDelegate {
    public func pickerData(_ pickerData: PhotoPickerData, canSelectAsset photoAsset: PhotoAsset) -> Bool {
        pickerDelegate?.pickerController(self, canSelectAsset: photoAsset) ?? true
    }
    
    public func pickerData(_ pickerData: PhotoPickerData, shouldSelectedAsset photoAsset: PhotoAsset, at index: Int) -> Bool {
        pickerDelegate?.pickerController(self, shouldSelectedAsset: photoAsset, atIndex: index) ?? true
    }
    
    public func pickerData(_ pickerData: PhotoPickerData, willSelectAsset photoAsset: PhotoAsset, at index: Int) {
        pickerDelegate?.pickerController(self, willSelectAsset: photoAsset, atIndex: index)
    }
    
    public func pickerData(_ pickerData: PhotoPickerData, didSelectAsset photoAsset: PhotoAsset, at index: Int) {
        pickerDelegate?.pickerController(self, didSelectAsset: photoAsset, atIndex: index)
    }
    
    public func pickerData(_ pickerData: PhotoPickerData, willUnselectAsset photoAsset: PhotoAsset, at index: Int) {
        pickerDelegate?.pickerController(self, willUnselectAsset: photoAsset, atIndex: index)
    }
    
    public func pickerData(_ pickerData: PhotoPickerData, didUnselectAsset photoAsset: PhotoAsset, at index: Int) {
        pickerDelegate?.pickerController(self, didUnselectAsset: photoAsset, atIndex: index)
    }
    
    public func pickerData(_ pickerData: PhotoPickerData, removeSelectedAssetWhenRemovingAssets photoAssets: [PhotoAsset]) {
        if let presentedViewController = presentedViewController as? PhotoPickerController,
           let previewViewController = presentedViewController.previewViewController {
            previewViewController.removeSelectedAssetWhenRemovingAssets(photoAssets)
        }else {
            previewViewController?.removeSelectedAssetWhenRemovingAssets(photoAssets)
        }
    }
}

extension PhotoPickerController: PhotoFetchDataDelegate {
    public func fetchData(_ fetchData: PhotoFetchData, didFetchAssetCollections collection: PHAssetCollection) -> Bool {
        pickerDelegate?.pickerController(self, didFetchAssetCollections: collection) ?? true
    }
    
    public func fetchData(_ fetchData: PhotoFetchData, didFetchAssets asset: PHAsset) -> Bool {
        pickerDelegate?.pickerController(self, didFetchAssets: asset) ?? true
    }
    
    public func fetchData(fetchCameraAssetCollectionCompletion fetchData: PhotoFetchData) {
        PhotoManager.HUDView.dismiss(delay: 0, animated: true, for: view)
        switch config.albumShowMode {
        case .normal:
            photoAlbumViewController?.selectedAssetCollection = fetchData.cameraAssetCollection
            
            let vc = PhotoPickerViewController(config: config)
            vc.assetCollection = fetchData.cameraAssetCollection
            vc.showLoading = false
            pushViewController(vc, animated: false)
        default:
            pickerViewController?.updateAssetCollection(fetchData.cameraAssetCollection, isShow: false)
            if let assetCollection = fetchData.cameraAssetCollection {
                pickerViewController?.updateAssetCollections([assetCollection])
            }
            fetchData.fetchAssetCollections()
        }
        if let splitViewController = splitViewController as? PhotoSplitViewController,
           let collection = fetchData.cameraAssetCollection {
            let photoPickerController: PhotoPickerController?
            if #available(iOS 14.0, *) {
                photoPickerController = splitViewController.viewController(for: .primary) as? PhotoPickerController
            } else {
                photoPickerController = splitViewController.viewControllers.first as? PhotoPickerController
            }
            splitViewController.cameraAssetCollection = collection
            photoPickerController?.albumViewController?.reloadTableView(assetCollections: [collection])
        }
    }
    
    public func fetchData(fetchAssetCollectionsCompletion fetchData: PhotoFetchData) {
        isFetchAssetCollection = false
        PhotoManager.HUDView.dismiss(delay: 0, animated: true, for: view)
        switch config.albumShowMode {
        case .normal:
            PhotoManager.HUDView.dismiss(delay: 0, animated: true, for: photoAlbumViewController?.view)
            photoAlbumViewController?.assetCollections = fetchData.assetCollections
            photoAlbumViewController?.reloadData()
        default:
            pickerViewController?.updateAssetCollections(fetchData.assetCollections)
        }
        if let splitViewController = splitViewController as? PhotoSplitViewController {
            let photoPickerController: PhotoPickerController?
            if #available(iOS 14.0, *) {
                photoPickerController = splitViewController.viewController(for: .primary) as? PhotoPickerController
            } else {
                photoPickerController = splitViewController.viewControllers.first as? PhotoPickerController
            }
            splitViewController.assetCollections = fetchData.assetCollections
            photoPickerController?.albumViewController?.reloadTableView(assetCollections: fetchData.assetCollections)
        }
    }
}
