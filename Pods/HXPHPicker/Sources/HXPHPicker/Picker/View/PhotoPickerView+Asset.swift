//
//  PhotoPickerView+Asset.swift
//  HXPHPicker
//
//  Created by Slience on 2021/9/17.
//

import UIKit

extension PhotoPickerView {
    
    /// 重新加载Asset
    /// 可以通过获取相册集合 manager.fetchAssetCollections()
    /// - Parameter assetCollection: 相册
    public func reloadAsset(assetCollection: PhotoAssetCollection?) {
        if assetCollection == nil {
            if config.allowAddCamera {
                allowPreview = false
            }
        }else {
            if config.allowAddCamera {
                allowPreview = true
            }
        }
        if AssetManager.authorizationStatus() != .denied {
            showLoading()
        }
        manager.fetchPhotoAssets(assetCollection: assetCollection)
    }
    
    /// 重新加载相机胶卷相册
    public func reloadCameraAsset() {
        if config.allowAddCamera {
            allowPreview = true
        }
        if AssetManager.authorizationStatus() != .denied {
            showLoading()
        }else {
            if config.allowAddCamera {
                allowPreview = false
            }
        }
        manager.reloadCameraAsset()
    }
    
    /// 获取相机胶卷相册集合里的Asset
    public func fetchAsset() {
        manager.requestAuthorization { [weak self] status in
            guard let self = self else { return }
            if status == .denied {
                self.hideLoading()
                self.setupDeniedView()
                return
            }
            self.manager.reloadAssetCollection = { [weak self] in
                guard let self = self else { return }
                self.showLoading()
            }
            self.showLoading()
            self.manager.fetchAssets { [weak self] photoAssets, photoAsset in
                guard let self = self else { return }
                self.fetchAssetCompletion(photoAssets, photoAsset)
            }
        }
    }
    
    /// 取消选择
    /// - Parameter index: 对应的索引
    public func deselect(at index: Int) {
        updateCellSelectedState(for: index, isSelected: false)
    }
    
    /// 取消选择
    /// - Parameter photoAsset: 对应的 PhotoAsset
    public func deselect(at photoAsset: PhotoAsset) {
        if let index = getIndexPath(for: photoAsset)?.item {
            deselect(at: index)
        }
    }
    
    /// 全部取消选择
    public func deselectAll() {
        manager.deselectAll()
        collectionView.reloadData()
    }
    
    /// 移除选择的内容
    /// 只是移除的manager里的已选数据
    /// cell选中状态需要调用 deselectAll()
    public func removeSelectedAssets() {
        manager.removeSelectedAssets()
    }
    
    /// 清空
    public func clear() {
        removeSelectedAssets()
        didFetchAsset = false
        allowPreview = false
        isFirst = true
        assets.removeAll()
        collectionView.reloadData()
        emptyView.removeFromSuperview()
    }
    
    private func showLoading() {
        loadingView = ProgressHUD.showLoading(
            addedTo: self,
            afterDelay: 0.15,
            animated: true
        )
    }
    private func hideLoading() {
        loadingView = nil
        ProgressHUD.hide(forView: self, animated: false)
    }
    private func fetchAssetCompletion(
        _ photoAssets: [PhotoAsset],
        _ photoAsset: PhotoAsset?
    ) {
        resetScrollCell()
        if isFirst {
            didFetchAsset = true
            allowPreview = true
            isFirst = false
        }
        assets = photoAssets
        setupEmptyView()
        collectionView.reloadData()
        scrollToAppropriatePlace(photoAsset: photoAsset)
        hideLoading()
        DispatchQueue.main.async {
            self.scrollViewDidScroll(self.collectionView)
        }
    }
}
