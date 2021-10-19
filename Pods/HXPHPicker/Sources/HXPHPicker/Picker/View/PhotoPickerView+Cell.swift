//
//  PhotoPickerView+Cell.swift
//  HXPHPicker
//
//  Created by Slience on 2021/9/17.
//

import UIKit

extension PhotoPickerView: PhotoPickerViewCellDelegate {
    
    public func cell(
        _ cell: PhotoPickerBaseViewCell,
        didSelectControl isSelected: Bool
    ) {
        if isSelected {
            // 取消选中
            let photoAsset = cell.photoAsset!
            manager.removePhotoAsset(photoAsset: photoAsset)
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
                manager.videoDurationExceedsTheLimit(
                    photoAsset: cell.photoAsset) &&
                manager.config.editorOptions.isVideo {
                if manager.canSelectAsset(
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
                if manager.addedPhotoAsset(photoAsset: cell.photoAsset) {
                    cell.updateSelectedState(
                        isSelected: true,
                        animated: true
                    )
                    updateCellSelectedTitle()
                }
            }
            let inICloud = cell.photoAsset.checkICloundStatus(
                allowSyncPhoto: manager.config.allowSyncICloudWhenSelectPhoto,
                hudAddedTo: self,
                completion: { _, isSuccess in
                if isSuccess {
                    addAsset()
                }
            })
            if !inICloud {
                addAsset()
            }
        }
    }
}
