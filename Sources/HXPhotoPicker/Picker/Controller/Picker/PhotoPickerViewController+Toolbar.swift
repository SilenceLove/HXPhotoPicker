//
//  PhotoPickerViewController+Toolbar.swift
//  HXPhotoPicker
//
//  Created by Slience on 2021/8/27.
//

import UIKit

extension PhotoPickerViewController {
    
    func initToolbar() {
        photoToolbar = config.photoToolbar.init(pickerConfig, type: .picker)
        photoToolbar.updateOriginalState(pickerController.isOriginal)
        photoToolbar.previewHandler = { [weak self] in
            guard let picker = self?.pickerController else { return }
            self?.pushPreviewViewController(
                previewAssets: picker.selectedAssetArray,
                currentPreviewIndex: 0,
                isPreviewSelect: true,
                animated: true
            )
        }
        photoToolbar.originalHandler = { [weak self] in
            self?.pickerController.isOriginal = $0
            self?.pickerController.originalButtonCallback()
            if $0 {
                self?.requestSelectedAssetFileSize()
            }else {
                self?.pickerController.pickerData.cancelRequestAssetFileSize(isPreview: false)
            }
        }
        photoToolbar.finishHandler = { [weak self] in
            self?.pickerController.finishCallback()
        }
        
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
