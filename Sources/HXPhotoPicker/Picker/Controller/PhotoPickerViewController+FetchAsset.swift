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
        guard let picker = pickerController else { return }
        if picker.config.albumShowMode == .popup {
            fetchAssetCollections()
            title = ""
            navigationItem.titleView = titleView
            if let cameraAssetCollection = picker.cameraAssetCollection {
                assetCollection = cameraAssetCollection
                assetCollection.isSelected = true
                titleView.title = assetCollection.albumName
                fetchPhotoAssets()
            }else {
                picker.fetchCameraAssetCollectionCompletion = { [weak self] (assetCollection) in
                    var cameraAssetCollection = assetCollection
                    if cameraAssetCollection == nil {
                        cameraAssetCollection = PhotoAssetCollection(
                            albumName:
                                self?.pickerController?.config.albumList.emptyAlbumName.localized,
                            coverImage:
                                self?.pickerController?.config.albumList.emptyCoverImageName.image
                        )
                    }
                    self?.assetCollection = cameraAssetCollection
                    self?.assetCollection.isSelected = true
                    self?.titleView.title = self?.assetCollection.albumName
                    self?.fetchPhotoAssets()
                }
            }
        }else {
            title = ""
            navigationItem.titleView = titleLabel
            if showLoading {
                ProgressHUD.showLoading(addedTo: view, afterDelay: 0.15, animated: true)
            }
            fetchPhotoAssets()
        }
    }
    
    func fetchAssetCollections() {
        guard let picker = pickerController else { return }
        if !picker.assetCollectionsArray.isEmpty {
            albumView.assetCollectionsArray = picker.assetCollectionsArray
            albumView.currentSelectedAssetCollection = assetCollection
            updateAlbumViewFrame()
        }
        fetchAssetCollectionsClosure()
        if !picker.config.allowLoadPhotoLibrary {
            picker.fetchAssetCollections()
        }
    }
    private func fetchAssetCollectionsClosure() {
        pickerController?.fetchAssetCollectionsCompletion = { [weak self] (assetCollectionsArray) in
            self?.albumView.assetCollectionsArray = assetCollectionsArray
            self?.albumView.currentSelectedAssetCollection = self?.assetCollection
            self?.updateAlbumViewFrame()
        }
    }
    func fetchPhotoAssets() {
        guard let picker = pickerController else { return }
        var addFilter: Bool = true
        if let assetCollection = assetCollection,
           let collection = assetCollection.collection {
            if collection.isCameraRoll {
                addFilter = true
            }else if collection.assetCollectionType == .album {
                addFilter = true
            }else {
                addFilter = false
            }
        }
        let selectOptions = picker.config.selectOptions
        if selectOptions.isVideo && !selectOptions.isPhoto {
            addFilter = false
        }else if selectOptions.isPhoto && !selectOptions.isVideo {
            if !selectOptions.contains(.gifPhoto) && !selectOptions.contains(.livePhoto) {
                addFilter = false
            }
        }
        if filterOptions != .any {
            filterOptions = .any
        }
        initNavItems(addFilter)
        picker.fetchPhotoAssets(
            assetCollection: assetCollection
        ) { [weak self] (photoAssets, photoAsset, photoCount, videoCount) in
            guard let self = self else { return }
            self.didFetchAsset = true
            self.allAssets = photoAssets
            self.assets = photoAssets
            self.photoCount = photoCount
            self.videoCount = videoCount
            self.allPhotoCount = photoCount
            self.allVideoCount = videoCount
            self.setupEmptyView()
            self.collectionView.reloadData()
//            DispatchQueue.main.async {
//                // collectionView reload 完成之后
                self.scrollToAppropriatePlace(photoAsset: photoAsset)
//            }
            if self.showLoading {
                ProgressHUD.hide(forView: self.view, animated: true)
                self.showLoading = false
            }else {
                ProgressHUD.hide(forView: self.navigationController?.view, animated: false)
            }
        }
    }
}
