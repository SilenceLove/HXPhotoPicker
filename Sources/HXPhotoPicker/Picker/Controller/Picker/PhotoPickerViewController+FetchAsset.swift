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
        title = ""
        if pickerConfig.albumShowMode.isPop || pickerController.splitType.isSplit {
            if assetCollection != nil {
                fetchPhotoAssets()
            }
        }else {
            if showLoading {
                PhotoManager.HUDView.show(with: nil, delay: 0.15, animated: true, addedTo: view)
            }
            fetchPhotoAssets()
        }
    }
    func fetchPhotoAssets() {
        guard let assetCollection = assetCollection else {
            if showLoading {
                PhotoManager.HUDView.dismiss(delay: 0, animated: true, for: view)
                showLoading = false
            }else {
                PhotoManager.HUDView.dismiss(delay: 0, animated: false, for: navigationController?.view)
            }
            return
        }
        var addFilter: Bool = true
        if let collection = assetCollection.collection {
            if collection.isCameraRoll || collection.assetCollectionType == .album {
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
                PhotoManager.HUDView.dismiss(delay: 0, animated: true, for: self.view)
                self.showLoading = false
            }else {
                PhotoManager.HUDView.dismiss(delay: 0, animated: false, for: self.navigationController?.view)
            }
            if self.pickerConfig.isRemoveSelectedAssetWhenRemovingAssets {
                self.photoToolbar.selectedAssetDidChanged(self.pickerController.selectedAssetArray)
                self.photoToolbar.updateSelectedAssets(self.pickerController.selectedAssetArray)
                self.finishItem?.selectedAssetDidChanged(self.pickerController.selectedAssetArray)
                self.updateToolbarFrame()
                self.requestSelectedAssetFileSize()
            }
            if let previewViewController = self.navigationController?.topViewController as? PhotoPreviewViewController {
                previewViewController.updateAsstes(for: result.assets)
            }else if let presentedViewController = self.presentedViewController as? PhotoPickerController,
                     let previewViewController = presentedViewController.previewViewController {
                previewViewController.updateAsstes(for: result.assets)
            }
        }
    }
    
    func updateAssetCollection(_ collection: PhotoAssetCollection?, isShow: Bool = true) {
        if isShow {
            PhotoManager.HUDView.show(with: nil, delay: 0, animated: true, addedTo: navigationController?.view)
        }
        if let collection = collection {
            if pickerConfig.albumShowMode.isPop {
                assetCollection?.isSelected = false
                collection.isSelected = true
            }
            assetCollection = collection
        }
        initView()
        updateTitle()
        fetchPhotoAssets()
        reloadAlbumData()
    }
    
    func updateAssetCollections(_ collections: [PhotoAssetCollection]) {
        if pickerConfig.albumShowMode.isPopView, !pickerController.splitType.isSplit {
            albumView.selectedAssetCollection = assetCollection
            albumView.assetCollections = collections
            updateAlbumViewFrame()
        }
    }
    
    func reloadAlbumData() {
        if pickerConfig.albumShowMode.isPopView, !pickerController.splitType.isSplit {
            albumView.selectedAssetCollection = assetCollection
            albumView.reloadData()
        }
    }
}
