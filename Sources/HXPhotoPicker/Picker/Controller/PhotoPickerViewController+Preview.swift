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
        guard let picker = pickerController else {
            return
        }
        let vc = PhotoPreviewViewController(
            config: picker.config.previewView
        )
        vc.previewAssets = previewAssets
        vc.currentPreviewIndex = currentPreviewIndex
        vc.isPreviewSelect = isPreviewSelect
        vc.delegate = self
        navigationController?.delegate = vc
        navigationController?.pushViewController(vc, animated: animated)
        if !animated {
            vc.configColor()
        }
    }
    func previewViewController(
        _ previewController: PhotoPreviewViewController,
        editAssetFinished photoAsset: PhotoAsset
    ) {
        reloadCell(for: photoAsset)
        bottomView.updateFinishButtonTitle()
        if filterOptions.contains(.edited) {
            filterPhotoAssets()
        }
    }
    func previewViewController(
        _ previewController: PhotoPreviewViewController,
        didOriginalButton isOriginal: Bool
    ) {
        if isMultipleSelect {
            bottomView.boxControl.isSelected = isOriginal
            bottomView.requestAssetBytes()
        }
    }
    func previewViewController(
        _ previewController: PhotoPreviewViewController,
        didSelectBox photoAsset: PhotoAsset,
        isSelected: Bool,
        updateCell: Bool
    ) {
        if !isSelected && updateCell {
            let cell = getCell(for: photoAsset)
            cell?.isRequestDirectly = true
            cell?.photoAsset = photoAsset
        }
        updateCellSelectedTitle()
        bottomView.updateFinishButtonTitle()
    }
    
    func previewViewController(
        _ previewController: PhotoPreviewViewController,
        networkImagedownloadSuccess photoAsset: PhotoAsset
    ) {
        if let cell = getCell(for: photoAsset), cell.downloadStatus == .failed {
            cell.requestThumbnailImage()
        }
        if photoAsset.isSelected {
            bottomView.updateFinishButtonTitle()
        }
    }
    
    func previewViewController(_ previewController: PhotoPreviewViewController, requestSucceed photoAsset: PhotoAsset) {
        resetICloud(for: photoAsset)
    }
    
    func previewViewController(movePhotoAsset previewController: PhotoPreviewViewController) {
        updateCellSelectedTitle()
    }
}
