//
//  PhotoPickerViewController+Toolbar.swift
//  HXPhotoPicker
//
//  Created by Slience on 2021/8/27.
//

import UIKit

extension PhotoPickerViewController: PhotoToolBarDelegate {
    
    func initToolbar() {
        if !isShowToolbar {
            photoToolbar = PhotoToolBarEmptyView(pickerConfig, type: .picker)
            return
        }
        photoToolbar = config.photoToolbar.init(pickerConfig, type: .picker)
        photoToolbar.toolbarDelegate = self
        photoToolbar.updateOriginalState(pickerController.isOriginal)
        view.addSubview(photoToolbar)
        if pickerConfig.isMultipleSelect {
            if pickerController.isOriginal {
                photoToolbar.requestOriginalAssetBtyes()
            }
            photoToolbar.selectedAssetDidChanged(pickerController.selectedAssetArray)
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
