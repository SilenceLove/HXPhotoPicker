//
//  PhotoPickerView+Preview.swift
//  HXPHPicker
//
//  Created by Slience on 2021/9/17.
//

import UIKit

extension PhotoPickerView: PhotoPreviewViewControllerDelegate {
    
    func pushPreviewViewController(
        previewAssets: [PhotoAsset],
        currentPreviewIndex: Int,
        animated: Bool
    ) {
        let previewVC = PhotoPickerController(
            pickerPreview: manager.config,
            previewAssets: previewAssets,
            currentIndex: currentPreviewIndex,
            delegate: self
        )
        previewVC.selectedAssetArray = manager.selectedAssetArray
        previewVC.isOriginal = isOriginal
        previewVC.previewViewController?.delegate = self
        previewVC.autoDismiss = false
        viewController?.present(previewVC, animated: animated)
    }
    
    func previewViewController(didFinishButton previewController: PhotoPreviewViewController) {
        previewController.pickerController?.disablesCustomDismiss = true
        let photoAssets = manager.selectedAssetArray
        let result = PickerResult(
            photoAssets: photoAssets,
            isOriginal: isOriginal
        )
        delegate?.photoPickerView(self, didFinishSelection: result)
        previewController.dismiss(animated: true) {
            self.delegate?.photoPickerView(self, dismissCompletion: result)
        }
    }
    
    func previewViewController(
        _ previewController: PhotoPreviewViewController,
        didOriginalButton isOriginal: Bool
    ) {
        self.isOriginal = isOriginal
        delegate?.photoPickerView(self, previewDidOriginalButton: isOriginal)
    }
    
    func previewViewController(
        _ previewController: PhotoPreviewViewController,
        editAssetFinished photoAsset: PhotoAsset
    ) {
        reloadCell(for: photoAsset)
    }
    
    func previewViewController(
        _ previewController: PhotoPreviewViewController,
        didSelectBox photoAsset: PhotoAsset,
        isSelected: Bool,
        updateCell: Bool
    ) {
        if let cell = getCell(for: photoAsset) {
            self.cell(cell, didSelectControl: !isSelected)
        }else {
            manager.addedPhotoAsset(photoAsset: photoAsset)
            updateCellSelectedTitle()
        }
    }
    
    func previewViewController(
        _ previewController: PhotoPreviewViewController,
        networkImagedownloadSuccess photoAsset: PhotoAsset
    ) {
        if let cell = getCell(for: photoAsset), cell.downloadStatus == .failed {
            cell.requestThumbnailImage()
        }
    }
    
    func previewViewController(
        _ previewController: PhotoPreviewViewController,
        requestSucceed photoAsset: PhotoAsset
    ) {
        resetICloud(for: photoAsset)
    }
}

extension PhotoPickerView: PhotoPickerControllerDelegate {
    
    // MARK: 单独预览时的自定义转场动画
    /// present预览时展示的image
    /// - Parameters:
    ///   - pickerController: 对应的 PhotoPickerController
    ///   - index: 预览资源对应的位置
    public func pickerController(
        _ pickerController: PhotoPickerController,
        presentPreviewImageForIndexAt index: Int
    ) -> UIImage? {
        getCell(for: needOffset ? index + offsetIndex : index)?.photoView.image
    }
    
    /// present 预览时起始的视图，用于获取位置大小。与 presentPreviewFrameForIndexAt 一样
    public func pickerController(
        _ pickerController: PhotoPickerController,
        presentPreviewViewForIndexAt index: Int
    ) -> UIView? {
        getCell(for: needOffset ? index + offsetIndex : index)
    }
    
    /// dismiss 结束时对应的视图，用于获取位置大小。与 dismissPreviewFrameForIndexAt 一样
    public func pickerController(
        _ pickerController: PhotoPickerController,
        dismissPreviewViewForIndexAt index: Int
    ) -> UIView? {
        let toIndex = needOffset ? index + offsetIndex : index
        if let cell = getCell(for: toIndex) {
            scrollCellToVisibleArea(cell)
            return cell
        }
        if assets.isEmpty {
            return nil
        }
        let photoAsset = getPhotoAsset(for: toIndex)
        scrollToCenter(for: photoAsset)
        reloadCell(for: photoAsset)
        return getCell(for: toIndex)
    }
}
