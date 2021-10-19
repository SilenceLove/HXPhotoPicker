//
//  PhotoPickerViewController+Cell.swift
//  HXPHPicker
//
//  Created by Slience on 2021/8/27.
//

import UIKit

// MARK: PhotoPickerViewCellDelegate
extension PhotoPickerViewController: PhotoPickerViewCellDelegate {
    
    public func cell(
        _ cell: PhotoPickerBaseViewCell,
        didSelectControl isSelected: Bool
    ) {
        guard let picker = pickerController else { return }
        if isSelected {
            // 取消选中
            let photoAsset = cell.photoAsset!
            picker.removePhotoAsset(photoAsset: photoAsset)
            // 清空视频编辑的数据
            #if HXPICKER_ENABLE_EDITOR
            if photoAsset.videoEdit != nil {
                photoAsset.videoEdit = nil
                cell.photoAsset = photoAsset
            }else {
                cell.updateSelectedState(
                    isSelected: false,
                    animated: true
                )
            }
            #else
            cell.updateSelectedState(
                isSelected: false,
                animated: true
            )
            #endif
            updateCellSelectedTitle()
        }else {
            // 选中
            #if HXPICKER_ENABLE_EDITOR
            if cell.photoAsset.mediaType == .video &&
                picker.videoDurationExceedsTheLimit(
                    photoAsset: cell.photoAsset) &&
                picker.config.editorOptions.isVideo {
                if picker.canSelectAsset(
                    for: cell.photoAsset,
                    showHUD: true
                ) {
                    openVideoEditor(
                        photoAsset: cell.photoAsset,
                        coverImage: cell.photoView.image
                    )
                }
                return
            }
            #endif
            func addAsset() {
                if picker.addedPhotoAsset(photoAsset: cell.photoAsset) {
                    cell.updateSelectedState(
                        isSelected: true,
                        animated: true
                    )
                    updateCellSelectedTitle()
                }
            }
            let inICloud = cell.photoAsset.checkICloundStatus(
                allowSyncPhoto: picker.config.allowSyncICloudWhenSelectPhoto,
                completion: { _, isSuccess in
                if isSuccess {
                    addAsset()
                }
            })
            if !inICloud {
                addAsset()
            }
        }
        bottomView.updateFinishButtonTitle()
    }
}
