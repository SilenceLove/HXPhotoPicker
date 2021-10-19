//
//  PhotoPreviewViewController+SelectBox.swift
//  HXPHPicker
//
//  Created by Slience on 2021/8/27.
//

import UIKit

extension PhotoPreviewViewController {
    @objc func didSelectBoxControlClick() {
        guard let picker = pickerController else { return }
        let isSelected = !selectBoxControl.isSelected
        let photoAsset = previewAssets[currentPreviewIndex]
        var canUpdate = false
        var bottomNeedAnimated = false
        var pickerUpdateCell = false
        let beforeIsEmpty = picker.selectedAssetArray.isEmpty
        if isSelected {
            // 选中
            #if HXPICKER_ENABLE_EDITOR
            if photoAsset.mediaType == .video &&
                picker.videoDurationExceedsTheLimit(photoAsset: photoAsset) &&
                picker.config.editorOptions.isVideo {
                if picker.canSelectAsset(for: photoAsset, showHUD: true) {
                    openEditor(photoAsset)
                }
                return
            }
            #endif
            func addAsset() {
                if picker.addedPhotoAsset(photoAsset: photoAsset) {
                    canUpdate = true
                    if config.bottomView.showSelectedView && isMultipleSelect && config.showBottomView {
                        bottomView.selectedView.insertPhotoAsset(
                            photoAsset: photoAsset
                        )
                    }
                    if beforeIsEmpty {
                        bottomNeedAnimated = true
                    }
                }
            }
            let inICloud = photoAsset.checkICloundStatus(
                allowSyncPhoto: picker.config.allowSyncICloudWhenSelectPhoto
            ) { _, isSuccess in
                if isSuccess {
                    addAsset()
                    if canUpdate {
                        self.updateSelectBox(
                            photoAsset: photoAsset,
                            isSelected: isSelected,
                            pickerUpdateCell: pickerUpdateCell,
                            bottomNeedAnimated: bottomNeedAnimated)
                    }
                }
            }
            if !inICloud {
                addAsset()
            }
        }else {
            // 取消选中
            picker.removePhotoAsset(photoAsset: photoAsset)
            if !beforeIsEmpty && picker.selectedAssetArray.isEmpty {
                bottomNeedAnimated = true
            }
            if config.bottomView.showSelectedView &&
                isMultipleSelect &&
                config.showBottomView {
                bottomView.selectedView.removePhotoAsset(
                    photoAsset: photoAsset
                )
            }
            #if HXPICKER_ENABLE_EDITOR
            if photoAsset.videoEdit != nil {
                photoAsset.videoEdit = nil
                let cell = getCell(for: currentPreviewIndex)
                cell?.photoAsset = photoAsset
                cell?.cancelRequest()
                cell?.requestPreviewAsset()
                pickerUpdateCell = true
            }
            #endif
            canUpdate = true
        }
        if canUpdate {
            updateSelectBox(
                photoAsset: photoAsset,
                isSelected: isSelected,
                pickerUpdateCell: pickerUpdateCell,
                bottomNeedAnimated: bottomNeedAnimated
            )
        }
    }
    
    func updateSelectBox(
        photoAsset: PhotoAsset,
        isSelected: Bool,
        pickerUpdateCell: Bool,
        bottomNeedAnimated: Bool
    ) {
        if config.bottomView.showSelectedView &&
            isMultipleSelect &&
            config.showBottomView {
            if bottomNeedAnimated {
                UIView.animate(withDuration: 0.25) {
                    self.configBottomViewFrame()
                    self.bottomView.layoutSubviews()
                }
            }else {
                configBottomViewFrame()
            }
        }
        updateSelectBox(
            isSelected,
            photoAsset: photoAsset
        )
        selectBoxControl.isSelected = isSelected
        delegate?.previewViewController(
            self,
            didSelectBox: photoAsset,
            isSelected: isSelected,
            updateCell: pickerUpdateCell
        )
        if config.showBottomView {
            bottomView.updateFinishButtonTitle()
        }
        selectBoxControl.layer.removeAnimation(
            forKey: "SelectControlAnimation"
        )
        let keyAnimation = CAKeyframeAnimation(
            keyPath: "transform.scale"
        )
        keyAnimation.duration = 0.3
        keyAnimation.values = [1.2, 0.8, 1.1, 0.9, 1.0]
        selectBoxControl.layer.add(
            keyAnimation,
            forKey: "SelectControlAnimation"
        )
    }
    
    func updateSelectBox(_ isSelected: Bool, photoAsset: PhotoAsset) {
        let boxWidth = config.selectBox.size.width
        let boxHeight = config.selectBox.size.height
        if isSelected {
            if config.selectBox.style == .number {
                let text = String(
                    format: "%d",
                    arguments: [photoAsset.selectIndex + 1]
                )
                let font = UIFont.mediumPingFang(
                    ofSize: config.selectBox.titleFontSize
                )
                let textHeight = text.height(
                    ofFont: font,
                    maxWidth: CGFloat(MAXFLOAT)
                )
                var textWidth = text.width(
                    ofFont: font,
                    maxHeight: textHeight
                )
                selectBoxControl.textSize = CGSize(
                    width: textWidth,
                    height: textHeight
                )
                textWidth += boxHeight * 0.5
                if textWidth < boxWidth {
                    textWidth = boxWidth
                }
                selectBoxControl.text = text
                selectBoxControl.size = CGSize(
                    width: textWidth,
                    height: boxHeight
                )
            }else {
                selectBoxControl.size = CGSize(
                    width: boxWidth,
                    height: boxHeight
                )
            }
        }else {
            selectBoxControl.size = CGSize(
                width: boxWidth,
                height: boxHeight
            )
        }
    }
}
