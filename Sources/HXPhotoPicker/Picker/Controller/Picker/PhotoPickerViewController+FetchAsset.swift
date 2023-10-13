//
//  PhotoPickerViewController+FetchAsset.swift
//  HXPhotoPicker
//
//  Created by Slience on 2021/8/27.
//

import UIKit

// MARK: fetch Asset
extension PhotoPickerViewController {
    
    func fetchData() {
        if pickerConfig.albumShowMode == .popup || pickerController.splitType.isSplit {
            fetchAssetCollections()
            title = ""
            if let cameraAssetCollection = pickerController.fetchData.cameraAssetCollection {
                assetCollection = cameraAssetCollection
                assetCollection.isSelected = true
                titleView.title = assetCollection.albumName
                updateCameraAlbumViewController(assetCollection)
                fetchPhotoAssets()
            }else {
                pickerController.fetchData.fetchCameraAssetCollectionCompletion = { [weak self] assetCollection in
                    self?.assetCollection = assetCollection
                    self?.assetCollection.isSelected = true
                    self?.titleView.title = self?.assetCollection.albumName
                    self?.updateCameraAlbumViewController(assetCollection)
                    self?.fetchPhotoAssets()
                }
            }
        }else {
            title = ""
            if showLoading {
                ProgressHUD.showLoading(addedTo: view, afterDelay: 0.15, animated: true)
            }
            fetchPhotoAssets()
        }
    }
    
    private func updateCameraAlbumViewController(_ collection: PhotoAssetCollection?) {
        if let splitViewController = splitViewController as? PhotoSplitViewController,
           let collection = collection {
            let photoPickerController: PhotoPickerController?
            if #available(iOS 14.0, *) {
                photoPickerController = splitViewController.viewController(for: .primary) as? PhotoPickerController
            } else {
                photoPickerController = splitViewController.viewControllers.first as? PhotoPickerController
            }
            splitViewController.cameraAssetCollection = collection
            photoPickerController?.albumViewController?.reloadTableView(assetCollectionsArray: [collection])
        }
    }
    func fetchAssetCollections() {
        if !pickerController.fetchData.assetCollections.isEmpty {
            updateAlbumViewController(pickerController.fetchData.assetCollections)
            albumView.selectedAssetCollection = assetCollection
            updateAlbumViewFrame()
        }
        fetchAssetCollectionsClosure()
        if !pickerConfig.allowLoadPhotoLibrary {
            pickerController.fetchData.fetchAssetCollections()
        }
    }
    private func updateAlbumViewController(_ collections: [PhotoAssetCollection]) {
        albumView.assetCollections = collections
        if let splitViewController = splitViewController as? PhotoSplitViewController {
            let photoPickerController: PhotoPickerController?
            if #available(iOS 14.0, *) {
                photoPickerController = splitViewController.viewController(for: .primary) as? PhotoPickerController
            } else {
                photoPickerController = splitViewController.viewControllers.first as? PhotoPickerController
            }
            splitViewController.assetCollections = collections
            photoPickerController?.albumViewController?.reloadTableView(assetCollectionsArray: collections)
        }
    }
    private func fetchAssetCollectionsClosure() {
        pickerController.fetchData.fetchAssetCollectionsCompletion = { [weak self] in
            self?.updateAlbumViewController($0)
            self?.albumView.selectedAssetCollection = self?.assetCollection
            self?.updateAlbumViewFrame()
        }
    }
    func fetchPhotoAssets() {
        guard let assetCollection = assetCollection else {
            if showLoading {
                ProgressHUD.hide(forView: view, animated: true)
                showLoading = false
            }else {
                ProgressHUD.hide(forView: navigationController?.view, animated: false)
            }
            return
        }
        var addFilter: Bool = true
        if let collection = assetCollection.collection {
            if collection.isCameraRoll {
                addFilter = true
            }else if collection.assetCollectionType == .album {
                addFilter = true
            }else {
                addFilter = false
            }
        }
        let selectOptions = pickerConfig.selectOptions
        if selectOptions.isVideo && !selectOptions.isPhoto {
            addFilter = false
        }else if selectOptions.isPhoto && !selectOptions.isVideo {
            if !selectOptions.contains(.gifPhoto) && !selectOptions.contains(.livePhoto) {
                addFilter = false
            }
        }
        if listView.filterOptions != .any {
            listView.filterOptions = .any
        }
        initNavItems(addFilter)
        pickerController.fetchData.fetchPhotoAssets(assetCollection: assetCollection) { [weak self] result in
            guard let self = self else { return }
            self.listView.assetResult = result
            self.scrollToAppropriatePlace(photoAsset: result.selectedAsset)
            if self.showLoading {
                ProgressHUD.hide(forView: self.view, animated: true)
                self.showLoading = false
            }else {
                ProgressHUD.hide(forView: self.navigationController?.view, animated: false)
            }
        }
    }
}
