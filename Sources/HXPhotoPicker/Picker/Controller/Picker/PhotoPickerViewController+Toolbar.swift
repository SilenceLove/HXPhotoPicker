//
//  PhotoPickerViewController+Toolbar.swift
//  HXPhotoPicker
//
//  Created by Slience on 2021/8/27.
//

import UIKit

extension PhotoPickerViewController {
    
    func initToolbar() {
        guard let picker = pickerController else {
            return
        }
        photoToolbar = config.photoToolbar.init()
        photoToolbar.initViews(picker.config, type: .picker)
        photoToolbar.updateOriginalState(picker.isOriginal)
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
            self?.pickerController?.isOriginal = $0
            self?.pickerController?.originalButtonCallback()
            if $0 {
                self?.requestSelectedAssetFileSize()
            }else {
                self?.pickerController?.cancelRequestAssetFileSize(isPreview: false)
            }
        }
        photoToolbar.finishHandler = { [weak self] in
            self?.pickerController?.finishCallback()
        }
        
        view.addSubview(photoToolbar)
        if isMultipleSelect {
            if picker.isOriginal {
                photoToolbar.requestOriginalAssetBtyes()
            }
            photoToolbar.selectedAssetDidChanged(picker.selectedAssetArray)
        }
    }
    
    func requestSelectedAssetFileSize() {
        pickerController?.requestSelectedAssetFileSize(isPreview: false, completion: { [weak self] in
            self?.photoToolbar.originalAssetBytes($0, bytesString: $1)
        })
    }
    
    public func setOriginal(_ isOriginal: Bool) {
        photoToolbar.updateOriginalState(isOriginal)
        if !isOriginal {
            pickerController?.cancelRequestAssetFileSize(isPreview: false)
        }else {
            photoToolbar.requestOriginalAssetBtyes()
        }
        pickerController?.isOriginal = isOriginal
        pickerController?.originalButtonCallback()
    }
}
