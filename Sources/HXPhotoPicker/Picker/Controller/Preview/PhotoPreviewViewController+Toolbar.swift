//
//  PhotoPreviewViewController+BottomView.swift
//  HXPhotoPicker
//
//  Created by Slience on 2021/8/6.
//

import UIKit

extension PhotoPreviewViewController: PhotoToolBarDelegate {
    
    func initToolbar() {
        if !isShowToolbar {
            photoToolbar = PhotoToolBarEmptyView(pickerConfig, type: .preview)
            return
        }
        guard let toolbar = config.photoToolbar else {
            return
        }
        photoToolbar = toolbar.init(
            pickerConfig,
            type: previewType != .browser ? .preview : .browser
        )
        photoToolbar.toolbarDelegate = self
        view.addSubview(photoToolbar)
        if previewType != .browser {
            photoToolbar.updateOriginalState(pickerController.isOriginal)
            photoToolbar.requestOriginalAssetBtyes()
            let selectedAssetArray = pickerController.selectedAssetArray
            photoToolbar.updateSelectedAssets(selectedAssetArray)
            photoToolbar.selectedAssetDidChanged(selectedAssetArray)
            photoToolbar.configPreviewList(previewAssets, page: currentPreviewIndex)
        }else {
            if config.bottomView.isShowPreviewList {
                photoToolbar.configPreviewList(previewAssets, page: currentPreviewIndex)
            }else {
                photoToolbar.updateSelectedAssets(previewAssets)
            }
        }
    }
    
    public func photoToolbar(_ toolbar: PhotoToolBar, didOriginalClick isSelected: Bool) {
        pickerController.isOriginal = isSelected
        if isSelected {
            requestSelectedAssetFileSize()
        }else {
            pickerController.pickerData.cancelRequestAssetFileSize(isPreview: true)
        }
        delegate?.previewViewController(
            self,
            didOriginalButton: isSelected
        )
        pickerController.originalButtonCallback()
    }
    
    #if HXPICKER_ENABLE_EDITOR
    public func photoToolbar(didEditClick toolbar: PhotoToolBar) {
        guard let photoAsset = photoAsset(for: currentPreviewIndex) else {
            return
        }
        openEditor(photoAsset)
    }
    #endif
    
    public func photoToolbar(didFinishClick toolbar: PhotoToolBar) {
        didFinishClick()
    }
    
    public func photoToolbar(_ toolbar: PhotoToolBar, didSelectedAsset asset: PhotoAsset) {
        if previewAssets.contains(asset) {
            scrollToPhotoAsset(asset)
        }else {
            photoToolbar.selectedViewScrollTo(nil, animated: true)
        }
    }
    
    public func photoToolbar(_ toolbar: PhotoToolBar, didMoveAsset fromIndex: Int, with toIndex: Int) {
        delegate?.previewViewController(self, moveItem: fromIndex, toIndex: toIndex)
        pickerController.pickerData.move(fromIndex: fromIndex, toIndex: toIndex)
        if isPreviewSelect {
            let fromAsset = previewAssets[fromIndex]
            previewAssets.remove(at: fromIndex)
            previewAssets.insert(fromAsset, at: toIndex)
            getCell(for: currentPreviewIndex)?.cancelRequest()
            collectionView.reloadData()
            startRequestPreviewTimer()
        }
        photoToolbar.updateSelectedAssets(pickerController.selectedAssetArray)
        if let asset = photoAsset(for: currentPreviewIndex) {
            updateSelectBox(asset.isSelected, photoAsset: asset)
            DispatchQueue.main.async {
                self.photoToolbar.selectedViewScrollTo(asset, animated: true)
            }
        }
        delegate?.previewViewController(movePhotoAsset: self)
    }
    
    public func photoToolbar(_ toolbar: PhotoToolBar, previewMoveTo asset: PhotoAsset) {
        scrollToPhotoAsset(asset)
    }
    
    func openEditor(_ photoAsset: PhotoAsset) {
        let shouldEditAsset = pickerController.shouldEditAsset(
            photoAsset: photoAsset,
            atIndex: currentPreviewIndex
        )
        if !shouldEditAsset {
            return
        }
        #if HXPICKER_ENABLE_EDITOR && HXPICKER_ENABLE_PICKER
        beforeNavDelegate = navigationController?.delegate
        let pickerConfig = pickerConfig
        if photoAsset.mediaType == .video && pickerConfig.editorOptions.isVideo {
            let cell = getCell(
                for: currentPreviewIndex
            )
            cell?.scrollContentView.stopVideo()
            var videoEditorConfig = pickerConfig.editor
            let isExceedsTheLimit = pickerController.pickerData.videoDurationExceedsTheLimit(
                photoAsset
            )
            if isExceedsTheLimit {
                videoEditorConfig.video.defaultSelectedToolOption = .time
                videoEditorConfig.video.cropTime.maximumTime = TimeInterval(
                    pickerConfig.maximumSelectedVideoDuration
                )
            }
            guard let videoEditorConfig = pickerController.shouldEditVideoAsset(
                videoAsset: photoAsset,
                editorConfig: videoEditorConfig,
                atIndex: currentPreviewIndex
            ) else {
                return
            }
            guard var videoEditorConfig = delegate?.previewViewController(
                self,
                shouldEditVideoAsset: photoAsset,
                editorConfig: videoEditorConfig
            ) else {
                return
            }
            videoEditorConfig.languageType = pickerConfig.languageType
            videoEditorConfig.indicatorType = pickerConfig.indicatorType
            videoEditorConfig.chartlet.albumPickerConfigHandler = { [weak self] in
                var pickerConfig: PickerConfiguration
                if let config = self?.pickerConfig {
                    pickerConfig = config
                }else {
                    pickerConfig = .init()
                }
                pickerConfig.selectOptions = [.gifPhoto]
                pickerConfig.photoList.bottomView.isHiddenOriginalButton = true
                pickerConfig.previewView.bottomView.isHiddenOriginalButton = true
                pickerConfig.previewView.bottomView.isHiddenEditButton = true
                return pickerConfig
            }
            let videoEditorVC = EditorViewController(
                .init(
                    type: .photoAsset(photoAsset),
                    result: photoAsset.editedResult
                ),
                config: videoEditorConfig,
                delegate: self
            )
            switch pickerConfig.editorJumpStyle {
            case .push(let style):
                if style == .custom {
                    navigationController?.delegate = videoEditorVC
                }
                navigationController?.pushViewController(videoEditorVC, animated: true)
            case .present(let style):
                if style == .fullScreen {
                    videoEditorVC.modalPresentationStyle = .fullScreen
                }else if style == .custom {
                    videoEditorVC.modalPresentationStyle = .custom
                    videoEditorVC.modalPresentationCapturesStatusBarAppearance = true
                    videoEditorVC.transitioningDelegate = videoEditorVC
                }
                present(videoEditorVC, animated: true)
            }
        }else if pickerConfig.editorOptions.isPhoto {
            guard let photoEditorConfig = pickerController.shouldEditPhotoAsset(
                photoAsset: photoAsset,
                editorConfig: pickerConfig.editor,
                atIndex: currentPreviewIndex
            ) else {
                return
            }
            guard var photoEditorConfig = delegate?.previewViewController(
                self,
                shouldEditPhotoAsset: photoAsset,
                editorConfig: photoEditorConfig
            ) else {
                return
            }
            if photoAsset.mediaSubType == .livePhoto ||
               photoAsset.mediaSubType == .localLivePhoto {
                let cell = getCell(
                    for: currentPreviewIndex
                )
                cell?.scrollContentView.stopLivePhoto()
            }
            photoEditorConfig.languageType = pickerConfig.languageType
            photoEditorConfig.indicatorType = pickerConfig.indicatorType
            photoEditorConfig.chartlet.albumPickerConfigHandler = { [weak self] in
                var pickerConfig: PickerConfiguration
                if let config = self?.pickerConfig {
                    pickerConfig = config
                }else {
                    pickerConfig = .init()
                }
                pickerConfig.selectOptions = [.photo]
                pickerConfig.photoList.bottomView.isHiddenOriginalButton = true
                pickerConfig.previewView.bottomView.isHiddenOriginalButton = true
                pickerConfig.previewView.bottomView.isHiddenEditButton = true
                return pickerConfig
            }
            let photoEditorVC = EditorViewController(
                .init(
                    type: .photoAsset(photoAsset),
                    result: photoAsset.editedResult
                ),
                config: photoEditorConfig,
                delegate: self
            )
            switch pickerConfig.editorJumpStyle {
            case .push(let style):
                if style == .custom {
                    navigationController?.delegate = photoEditorVC
                }
                navigationController?.pushViewController(photoEditorVC, animated: true)
            case .present(let style):
                if style == .fullScreen {
                    photoEditorVC.modalPresentationStyle = .fullScreen
                }else if style == .custom {
                    photoEditorVC.modalPresentationStyle = .custom
                    photoEditorVC.modalPresentationCapturesStatusBarAppearance = true
                    photoEditorVC.transitioningDelegate = photoEditorVC
                }
                present(photoEditorVC, animated: true)
            }
        }
        #endif
    }
    
    func didFinishClick() {
        if !pickerController.selectedAssetArray.isEmpty {
            delegate?.previewViewController(didFinishButton: self, photoAssets: pickerController.selectedAssetArray)
            pickerController.finishCallback()
            return
        }
        if assetCount == 0 {
            ProgressHUD.showWarning(
                addedTo: view,
                text: .textPreview.emptyAssetHudTitle.text,
                animated: true,
                delayHide: 1.5
            )
            return
        }
        guard let photoAsset = photoAsset(for: currentPreviewIndex) else {
            return
        }
        #if HXPICKER_ENABLE_EDITOR
        if photoAsset.mediaType == .video &&
            pickerController.pickerData.videoDurationExceedsTheLimit(photoAsset) &&
            pickerController.config.editorOptions.isVideo {
            if pickerController.pickerData.canSelect(
                photoAsset,
                isShowHUD: true
            ) {
                openEditor(photoAsset)
            }
            return
        }
        #endif
        func addAsset() {
            if !pickerConfig.isMultipleSelect {
                if pickerController.pickerData.canSelect(
                    photoAsset,
                    isShowHUD: true
                ) {
                    if previewType == .picker {
                        delegate?.previewViewController(
                            self,
                            didSelectBox: photoAsset,
                            isSelected: true,
                            updateCell: false
                        )
                    }
                    delegate?.previewViewController(didFinishButton: self, photoAssets: [photoAsset])
                    pickerController.singleFinishCallback(
                        for: photoAsset
                    )
                }
            }else {
                if pickerConfig.isSingleVideo {
                    if pickerController.pickerData.canSelect(
                        photoAsset,
                        isShowHUD: true
                    ) {
                        if previewType == .picker {
                            delegate?.previewViewController(
                                self,
                                didSelectBox: photoAsset,
                                isSelected: true,
                                updateCell: false
                            )
                        }
                        delegate?.previewViewController(didFinishButton: self, photoAssets: [photoAsset])
                        pickerController.singleFinishCallback(
                            for: photoAsset
                        )
                    }
                }else {
                    if pickerController.pickerData.append(
                        photoAsset
                    ) {
                        if previewType == .picker {
                            delegate?.previewViewController(
                                self,
                                didSelectBox: photoAsset,
                                isSelected: true,
                                updateCell: false
                            )
                        }
                        delegate?.previewViewController(didFinishButton: self, photoAssets: pickerController.selectedAssetArray)
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
    
    func requestSelectedAssetFileSize() {
        pickerController.pickerData.requestSelectedAssetFileSize(isPreview: true, completion: { [weak self] in
            self?.photoToolbar.originalAssetBytes($0, bytesString: $1)
        })
    }
    
    func startRequestPreviewTimer() {
        requestPreviewTimer?.invalidate()
        requestPreviewTimer = Timer.scheduledTimer(
            timeInterval: 0.2,
            target: self,
            selector: #selector(delayRequestPreview),
            userInfo: nil,
            repeats: false
        )
    }
    @objc
    func delayRequestPreview() {
        if let cell = getCell(for: currentPreviewIndex) {
            cell.requestPreviewAsset()
            requestPreviewTimer = nil
        }else {
            if assetCount == 0 {
                requestPreviewTimer = nil
                return
            }
            startRequestPreviewTimer()
        }
    }
    
    public func setOriginal(_ isOriginal: Bool) {
        guard let photoToolbar = photoToolbar else {
            return
        }
        photoToolbar.updateOriginalState(isOriginal)
        if !isOriginal {
            pickerController.pickerData.cancelRequestAssetFileSize(isPreview: true)
        }else {
            requestSelectedAssetFileSize()
        }
        pickerController.isOriginal = isOriginal
        pickerController.originalButtonCallback()
        delegate?.previewViewController(
            self,
            didOriginalButton: isOriginal
        )
    }
    
}
