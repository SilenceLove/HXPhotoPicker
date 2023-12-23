//
//  PhotoPickerViewController+Preview.swift
//  HXPhotoPicker
//
//  Created by Slience on 2021/8/4.
//

import UIKit

// MARK: PhotoPreviewViewControllerDelegate
extension PhotoPickerViewController: PhotoPreviewViewControllerDelegate {
    
    func pushPreviewViewController(
        previewAssets: [PhotoAsset],
        currentPreviewIndex: Int,
        isPreviewSelect: Bool = false,
        animated: Bool
    ) {
        if config.previewStyle == .present {
            var config = pickerConfig
            config.isSelectedOriginal = pickerController.isOriginal
            config.isAutoBack = false
            let previewVC = PhotoPickerController(
                preview: config,
                previewAssets: previewAssets,
                currentIndex: currentPreviewIndex,
                selectedAssets: pickerController.selectedAssetArray,
                previewType: .picker,
                delegate: self
            )
            previewVC.previewViewController?.delegate = self
            present(previewVC, animated: animated)
            return
        }
        let vc = PhotoPreviewViewController(
            config: pickerConfig
        )
        vc.previewAssets = previewAssets
        vc.currentPreviewIndex = currentPreviewIndex
        vc.isPreviewSelect = isPreviewSelect
        vc.delegate = self
        navigationController?.delegate = vc
        navigationController?.pushViewController(vc, animated: animated)
        if !animated {
            vc.updateColors()
        }
    }
    
    func previewViewController(
        _ previewController: PhotoPreviewViewController,
        didOriginalButton isOriginal: Bool
    ) {
        if config.previewStyle == .present {
            pickerController.isOriginal = isOriginal
            pickerController.originalButtonCallback()
        }
        if pickerConfig.isMultipleSelect {
            photoToolbar.updateOriginalState(isOriginal)
            requestSelectedAssetFileSize()
        }
    }
    func previewViewController(
        _ previewController: PhotoPreviewViewController,
        didSelectBox photoAsset: PhotoAsset,
        isSelected: Bool,
        updateCell: Bool
    ) {
        if config.previewStyle == .present {
            listView.selectCell(for: photoAsset, isSelected: isSelected)
        }else {
            if !isSelected && updateCell {
                listView.updateCell(for: photoAsset)
            }
            if isShowToolbar {
                if isSelected {
                    photoToolbar.insertSelectedAsset(photoAsset)
                }else {
                    photoToolbar.removeSelectedAssets([photoAsset])
                }
            }
        }
        listView.updateCellSelectedTitle()
        photoToolbar.selectedAssetDidChanged(pickerController.selectedAssetArray)
        finishItem?.selectedAssetDidChanged(pickerController.selectedAssetArray)
        requestSelectedAssetFileSize()
    }
    
    func previewViewController(
        _ previewController: PhotoPreviewViewController,
        networkImagedownloadSuccess photoAsset: PhotoAsset
    ) {
        if let cell = listView.getCell(for: photoAsset), cell.downloadStatus == .failed {
            cell.requestThumbnailImage()
        }
        if photoAsset.isSelected {
            photoToolbar.selectedAssetDidChanged(pickerController.selectedAssetArray)
            finishItem?.selectedAssetDidChanged(pickerController.selectedAssetArray)
            requestSelectedAssetFileSize()
        }
    }
    
    func previewViewController(_ previewController: PhotoPreviewViewController, requestSucceed photoAsset: PhotoAsset) {
        listView.resetICloud(for: photoAsset)
    }
    
    func previewViewController(movePhotoAsset previewController: PhotoPreviewViewController) {
        listView.updateCellSelectedTitle()
        if isShowToolbar {
            photoToolbar.updateSelectedAssets(pickerController.selectedAssetArray)
        }
    }
    
    func previewViewController(_ previewController: PhotoPreviewViewController, moveItem fromIndex: Int, toIndex: Int) {
        if config.previewStyle == .present {
            pickerController.pickerData.move(fromIndex: fromIndex, toIndex: toIndex)
            listView.updateCellSelectedTitle()
            if isShowToolbar {
                photoToolbar.updateSelectedAssets(pickerController.selectedAssetArray)
            }
        }
    }
    
    func previewViewController(
        didFinishButton previewController: PhotoPreviewViewController,
        photoAssets: [PhotoAsset]
    ) {
        if config.previewStyle != .present {
            return
        }
        previewController.pickerController.disablesCustomDismiss = true
        if pickerConfig.isMultipleSelect {
            pickerController.finishCallback()
        }else {
            if let photoAsset = photoAssets.first {
                pickerController.singleFinishCallback(for: photoAsset)
            }
        }
    }
    
    func previewViewController(
        _ previewController: PhotoPreviewViewController,
        editAssetFinished photoAsset: PhotoAsset
    ) {
        listView.reloadCell(for: photoAsset)
        photoToolbar.selectedAssetDidChanged(pickerController.selectedAssetArray)
        finishItem?.selectedAssetDidChanged(pickerController.selectedAssetArray)
        requestSelectedAssetFileSize()
        if listView.filterOptions.contains(.edited) {
            listView.reloadData()
        }
        if isShowToolbar {
            photoToolbar.reloadSelectedAsset(photoAsset)
        }
    }
    
    #if HXPICKER_ENABLE_EDITOR
    func previewViewController(
        _ previewController: PhotoPreviewViewController,
        shouldEditPhotoAsset photoAsset: PhotoAsset,
        editorConfig: EditorConfiguration
    ) -> EditorConfiguration? {
        if config.previewStyle != .present {
            return editorConfig
        }
        let config = pickerController.shouldEditPhotoAsset(
            photoAsset: photoAsset,
            editorConfig: editorConfig,
            atIndex: previewController.currentPreviewIndex
        )
        guard let config = config else {
            return editorConfig
        }
        return config
    }
    
    func previewViewController(
        _ previewController: PhotoPreviewViewController,
        shouldEditVideoAsset videoAsset: PhotoAsset,
        editorConfig: EditorConfiguration
    ) -> EditorConfiguration? {
        if config.previewStyle != .present {
            return editorConfig
        }
        let config = pickerController.shouldEditVideoAsset(
            videoAsset: videoAsset,
            editorConfig: editorConfig,
            atIndex: previewController.currentPreviewIndex
        )
        guard let config else {
            return editorConfig
        }
        return config
    }
    #endif
}

extension PhotoPickerViewController: PhotoPickerControllerDelegate {
    
    // MARK: 单独预览时的自定义转场动画
    /// present预览时展示的image
    /// - Parameters:
    ///   - pickerController: 对应的 PhotoPickerController
    ///   - index: 预览资源对应的位置
    public func pickerController(
        _ pickerController: PhotoPickerController,
        presentPreviewImageForIndexAt index: Int
    ) -> UIImage? {
        listView.getCell(for: pickerController.previewAssets[index])?.photoView.image
    }
    
    /// present 预览时起始的视图，用于获取位置大小。与 presentPreviewFrameForIndexAt 一样
    public func pickerController(
        _ pickerController: PhotoPickerController,
        presentPreviewViewForIndexAt index: Int
    ) -> UIView? {
        listView.getCell(for: pickerController.previewAssets[index])
    }
    
    /// dismiss 结束时对应的视图，用于获取位置大小。与 dismissPreviewFrameForIndexAt 一样
    public func pickerController(
        _ pickerController: PhotoPickerController,
        dismissPreviewViewForIndexAt index: Int
    ) -> UIView? {
        if pickerController.previewAssets.isEmpty {
            return nil
        }
        let photoAsset = pickerController.previewAssets[index]
        if let cell = listView.getCell(for: photoAsset) {
            listView.scrollCellToVisibleArea(cell)
            return cell
        }
        if listView.assets.isEmpty {
            return nil
        }
        listView.scrollToCenter(for: photoAsset)
        listView.reloadCell(for: photoAsset)
        return listView.getCell(for: photoAsset)
    }
}
