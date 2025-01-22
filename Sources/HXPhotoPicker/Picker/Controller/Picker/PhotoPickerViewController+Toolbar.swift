//
//  PhotoPickerViewController+Toolbar.swift
//  HXPhotoPicker
//
//  Created by Slience on 2021/8/27.
//

import UIKit

extension PhotoPickerViewController: PhotoToolBarDelegate {
    
    func initToolbar() {
        if AssetPermissionsUtil.authorizationStatus == .notDetermined {
            photoToolbar = PhotoToolBarEmptyView(pickerConfig, type: .picker)
            return
        }
        if photoToolbar?.superview == view {
            return
        }
        if !isShowToolbar {
            photoToolbar = PhotoToolBarEmptyView(pickerConfig, type: .picker)
            return
        }
        guard let toolbar = config.photoToolbar else {
            return
        }
        photoToolbar = toolbar.init(pickerConfig, type: .picker)
        photoToolbar.toolbarDelegate = self
        photoToolbar.updateOriginalState(pickerController.isOriginal)
        view.addSubview(photoToolbar)
        if pickerConfig.isMultipleSelect {
            if pickerController.isOriginal {
                photoToolbar.requestOriginalAssetBtyes()
            }
            photoToolbar.selectedAssetDidChanged(pickerController.selectedAssetArray)
            photoToolbar.updateSelectedAssets(pickerController.selectedAssetArray)
        }
    }
    
    func updateToolbarFrame() {
        if photoToolbar.viewHeight != photoToolbar.height {
            UIView.animate(withDuration: 0.25) {
                self.layoutToolbar()
                self.photoToolbar.layoutSubviews()
            }
        }
    }
    
    func requestSelectedAssetFileSize() {
        pickerController.pickerData.requestSelectedAssetFileSize(isPreview: false, completion: { [weak self] in
            self?.photoToolbar.originalAssetBytes($0, bytesString: $1)
        })
    }
    
    public func photoToolbar(didPreviewClick toolbar: PhotoToolBar) {
        pushPreviewViewController(
            previewAssets: pickerController.selectedAssetArray,
            currentPreviewIndex: 0,
            isPreviewSelect: true,
            animated: true
        )
    }
    
    public func photoToolbar(_ toolbar: PhotoToolBar, didOriginalClick isSelected: Bool) {
        pickerController.isOriginal = isSelected
        pickerController.originalButtonCallback()
        if isSelected {
            requestSelectedAssetFileSize()
        }else {
            pickerController.pickerData.cancelRequestAssetFileSize(isPreview: false)
        }
    }
    
    public func photoToolbar(didFinishClick toolbar: PhotoToolBar) {
        pickerController.finishCallback()
    }
    
    public func photoToolbar(_ toolbar: PhotoToolBar, didSelectedAsset asset: PhotoAsset) {
        let previewAssets = pickerController.selectedAssetArray
        let index = previewAssets.firstIndex(of: asset) ?? 0
        pushPreviewViewController(
            previewAssets: pickerController.selectedAssetArray,
            currentPreviewIndex: index,
            isPreviewSelect: true,
            animated: true
        )
    }
    
    public func photoToolbar(_ toolbar: PhotoToolBar, didMoveAsset fromIndex: Int, with toIndex: Int) {
        pickerController.pickerData.move(fromIndex: fromIndex, toIndex: toIndex)
        photoToolbar.updateSelectedAssets(pickerController.selectedAssetArray)
        listView.updateCellSelectedTitle()
    }
    
    public func photoToolbar(_ toolbar: PhotoToolBar, didDeleteAsset asset: PhotoAsset) {
        deselectedAsset(asset)
    }
    
    public func deselectedAsset(_ asset: PhotoAsset) {
        pickerController.pickerData.remove(asset)
        #if HXPICKER_ENABLE_EDITOR
        if asset.videoEditedResult != nil, pickerConfig.isDeselectVideoRemoveEdited {
            asset.editedResult = nil
        }else if asset.photoEditedResult != nil, pickerConfig.isDeselectPhotoRemoveEdited {
            asset.editedResult = nil
        }
        #endif
        listView.updateCellSelectedTitle()
        photoToolbar.removeSelectedAssets([asset])
        if pickerController.isOriginal {
            photoToolbar.requestOriginalAssetBtyes()
        }
        photoToolbar.selectedAssetDidChanged(pickerController.selectedAssetArray)
        updateToolbarFrame()
    }
    
    public func setOriginal(_ isOriginal: Bool) {
        guard let photoToolbar = photoToolbar else {
            return
        }
        photoToolbar.updateOriginalState(isOriginal)
        if !isOriginal {
            pickerController.pickerData.cancelRequestAssetFileSize(isPreview: false)
        }else {
            photoToolbar.requestOriginalAssetBtyes()
        }
        pickerController.isOriginal = isOriginal
        pickerController.originalButtonCallback()
    }
}
