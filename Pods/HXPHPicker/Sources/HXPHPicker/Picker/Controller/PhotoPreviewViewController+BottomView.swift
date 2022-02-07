//
//  PhotoPreviewViewController+BottomView.swift
//  HXPHPicker
//
//  Created by Slience on 2021/8/6.
//

import UIKit

// MARK: PhotoPickerBottomViewDelegate
extension PhotoPreviewViewController: PhotoPickerBottomViewDelegate {
    
    func bottomView(didEditButtonClick bottomView: PhotoPickerBottomView) {
        let photoAsset = previewAssets[currentPreviewIndex]
        openEditor(photoAsset)
    }
    
    func openEditor(_ photoAsset: PhotoAsset) {
        guard let picker = pickerController else { return }
        let shouldEditAsset = picker.shouldEditAsset(
            photoAsset: photoAsset,
            atIndex: currentPreviewIndex
        )
        if !shouldEditAsset {
            return
        }
        #if HXPICKER_ENABLE_EDITOR && HXPICKER_ENABLE_PICKER
        beforeNavDelegate = navigationController?.delegate
        let pickerConfig = picker.config
        if photoAsset.mediaType == .video && pickerConfig.editorOptions.isVideo {
            let cell = getCell(
                for: currentPreviewIndex
            )
            cell?.scrollContentView.stopVideo()
            let videoEditorConfig: VideoEditorConfiguration
            let isExceedsTheLimit = picker.videoDurationExceedsTheLimit(
                photoAsset: photoAsset
            )
            if isExceedsTheLimit {
                videoEditorConfig = pickerConfig.videoEditor.mutableCopy() as! VideoEditorConfiguration
                videoEditorConfig.defaultState = .cropTime
                videoEditorConfig.mustBeTailored = true
            }else {
                videoEditorConfig = pickerConfig.videoEditor
            }
            videoEditorConfig.languageType = pickerConfig.languageType
            videoEditorConfig.appearanceStyle = pickerConfig.appearanceStyle
            videoEditorConfig.indicatorType = pickerConfig.indicatorType
            let videoEditorVC = VideoEditorViewController(
                photoAsset: photoAsset,
                editResult: photoAsset.videoEdit,
                config: videoEditorConfig
            )
            videoEditorVC.coverImage = cell?.scrollContentView.imageView.image
            videoEditorVC.delegate = self
            if pickerConfig.editorCustomTransition {
                navigationController?.delegate = videoEditorVC
            }
            navigationController?.pushViewController(
                videoEditorVC,
                animated: true
            )
        }else if pickerConfig.editorOptions.isPhoto {
            let photoEditorConfig = pickerConfig.photoEditor
            photoEditorConfig.languageType = pickerConfig.languageType
            photoEditorConfig.appearanceStyle = pickerConfig.appearanceStyle
            photoEditorConfig.indicatorType = pickerConfig.indicatorType
            let photoEditorVC = PhotoEditorViewController(
                photoAsset: photoAsset,
                editResult: photoAsset.photoEdit,
                config: photoEditorConfig
            )
            photoEditorVC.delegate = self
            if pickerConfig.editorCustomTransition {
                navigationController?.delegate = photoEditorVC
            }
            navigationController?.pushViewController(
                photoEditorVC,
                animated: true
            )
        }
        #endif
    }
    func bottomView(
        didFinishButtonClick bottomView: PhotoPickerBottomView
    ) {
        guard let pickerController = pickerController else {
            return
        }
        if !pickerController.selectedAssetArray.isEmpty {
            delegate?.previewViewController(didFinishButton: self)
            pickerController.finishCallback()
            return
        }
        if previewAssets.isEmpty {
            ProgressHUD.showWarning(
                addedTo: view,
                text: "没有可选资源".localized,
                animated: true,
                delayHide: 1.5
            )
            return
        }
        let photoAsset = previewAssets[currentPreviewIndex]
        #if HXPICKER_ENABLE_EDITOR
        if photoAsset.mediaType == .video &&
            pickerController.videoDurationExceedsTheLimit(photoAsset: photoAsset) &&
            pickerController.config.editorOptions.isVideo {
            if pickerController.canSelectAsset(
                for: photoAsset,
                showHUD: true
            ) {
                openEditor(photoAsset)
            }
            return
        }
        #endif
        func addAsset() {
            if !isMultipleSelect {
                if pickerController.canSelectAsset(
                    for: photoAsset,
                    showHUD: true
                ) {
                    if isExternalPickerPreview {
                        delegate?.previewViewController(
                            self,
                            didSelectBox: photoAsset,
                            isSelected: true,
                            updateCell: false
                        )
                    }
                    delegate?.previewViewController(didFinishButton: self)
                    pickerController.singleFinishCallback(
                        for: photoAsset
                    )
                }
            }else {
                if videoLoadSingleCell {
                    if pickerController.canSelectAsset(
                        for: photoAsset,
                        showHUD: true
                    ) {
                        if isExternalPickerPreview {
                            delegate?.previewViewController(
                                self,
                                didSelectBox: photoAsset,
                                isSelected: true,
                                updateCell: false
                            )
                        }
                        delegate?.previewViewController(didFinishButton: self)
                        pickerController.singleFinishCallback(
                            for: photoAsset
                        )
                    }
                }else {
                    if pickerController.addedPhotoAsset(
                        photoAsset: photoAsset
                    ) {
                        if isExternalPickerPreview {
                            delegate?.previewViewController(
                                self,
                                didSelectBox: photoAsset,
                                isSelected: true,
                                updateCell: false
                            )
                        }
                        delegate?.previewViewController(didFinishButton: self)
                        pickerController.finishCallback()
                    }
                }
            }
        }
        let inICloud = photoAsset.checkICloundStatus(
            allowSyncPhoto: pickerController.config.allowSyncICloudWhenSelectPhoto
        ) { _, isSuccess in
            if isSuccess {
                addAsset()
            }
        }
        if !inICloud {
            addAsset()
        }
    }
    func bottomView(
        _ bottomView: PhotoPickerBottomView,
        didOriginalButtonClick isOriginal: Bool
    ) {
        delegate?.previewViewController(
            self,
            didOriginalButton: isOriginal
        )
        pickerController?.originalButtonCallback()
    }
    func bottomView(
        _ bottomView: PhotoPickerBottomView,
        didSelectedItemAt photoAsset: PhotoAsset
    ) {
        if previewAssets.contains(photoAsset) {
            let index = previewAssets.firstIndex(of: photoAsset) ?? 0
            if index == currentPreviewIndex {
                return
            }
            getCell(for: currentPreviewIndex)?.cancelRequest()
            collectionView.scrollToItem(
                at: IndexPath(item: index, section: 0),
                at: .centeredHorizontally,
                animated: false
            )
            setupRequestPreviewTimer()
        }else {
            bottomView.selectedView.scrollTo(photoAsset: nil)
        }
    }
    func setupRequestPreviewTimer() {
        requestPreviewTimer?.invalidate()
        requestPreviewTimer = Timer(
            timeInterval: 0.2,
            target: self,
            selector: #selector(delayRequestPreview),
            userInfo: nil,
            repeats: false
        )
        RunLoop.main.add(
            requestPreviewTimer!,
            forMode: RunLoop.Mode.common
        )
    }
    @objc func delayRequestPreview() {
        if let cell = getCell(for: currentPreviewIndex) {
            cell.requestPreviewAsset()
            requestPreviewTimer = nil
        }else {
            if previewAssets.isEmpty {
                requestPreviewTimer = nil
                return
            }
            setupRequestPreviewTimer()
        }
    }
    
    public func setOriginal(_ isOriginal: Bool) {
        bottomView.boxControl.isSelected =  isOriginal
        if !isOriginal {
            // 取消
            bottomView.cancelRequestAssetFileSize()
        }else {
            // 选中
            bottomView.requestAssetBytes()
        }
        pickerController?.isOriginal = isOriginal
        pickerController?.originalButtonCallback()
        delegate?.previewViewController(
            self,
            didOriginalButton: isOriginal
        )
    }
}
