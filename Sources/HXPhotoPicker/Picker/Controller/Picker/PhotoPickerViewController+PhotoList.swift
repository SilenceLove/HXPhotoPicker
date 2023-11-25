//
//  PhotoPickerViewController+PhotoList.swift.swift
//  HXPhotoPicker
//
//  Created by Slience on 2021/8/27.
//

import UIKit


extension PhotoPickerViewController: PhotoPickerListDelegate {
    
    func initListView() {
        listView = config.listView.init(config: pickerConfig)
        listView.delegate = self
        addChild(listView)
        view.addSubview(listView.view)
    }
    
    public func photoList(_ photoList: PhotoPickerList, didSelectCell asset: PhotoAsset, at index: Int, animated: Bool) {
        if !pickerController.shouldClickCell(photoAsset: asset, index: index) {
            return
        }
        var selectionTapAction: SelectionTapAction
        if asset.mediaType == .photo {
            selectionTapAction = pickerConfig.photoSelectionTapAction
        }else {
            selectionTapAction = pickerConfig.videoSelectionTapAction
        }
        switch selectionTapAction {
        case .preview:
            pushPreviewViewController(previewAssets: listView.assets, currentPreviewIndex: index, animated: animated)
        case .quickSelect:
            asset.playerTime = 0
            quickSelect(asset)
        case .openEditor:
            asset.playerTime = 0
            let cell = listView.getCell(for: asset)
            openEditor(asset, image: cell?.photoView.image, animated: animated)
        }
    }
    
    public func photoList(_ photoList: PhotoPickerList, didSelectedAsset asset: PhotoAsset) {
        if isShowToolbar {
            photoToolbar.insertSelectedAsset(asset)
            updateToolbarFrame()
        }
    }
    
    public func photoList(_ photoList: PhotoPickerList, didDeselectedAsset asset: PhotoAsset) {
        if isShowToolbar {
            photoToolbar.removeSelectedAssets([asset])
            updateToolbarFrame()
        }
    }
    
    public func photoList(_ photoList: PhotoPickerList, updateAsset asset: PhotoAsset) {
        if isShowToolbar {
            photoToolbar.reloadSelectedAsset(asset)
        }
    }
    
    public func photoList(selectedAssetDidChanged photoList: PhotoPickerList) {
        photoToolbar.selectedAssetDidChanged(pickerController.selectedAssetArray)
        finishItem?.selectedAssetDidChanged(pickerController.selectedAssetArray)
        requestSelectedAssetFileSize()
    }
    
    public func photoList(_ photoList: PhotoPickerList, openEditor asset: PhotoAsset, with image: UIImage?) {
        asset.playerTime = 0
        openEditor(asset, image: image)
    }
    
    public func photoList(_ photoList: PhotoPickerList, openPreview assets: [PhotoAsset], with page: Int, animated: Bool) {
        pushPreviewViewController(previewAssets: assets, currentPreviewIndex: page, animated: animated)
    }
    
    public func photoList(presentCamera photoList: PhotoPickerList) {
        presentCameraViewController()
    }
    
    public func photoList(presentFilter photoList: PhotoPickerList, modalPresentationStyle: UIModalPresentationStyle) {
        didFilterItemClick(modalPresentationStyle: modalPresentationStyle)
    }
    
    func quickSelect(_ photoAsset: PhotoAsset, isCapture: Bool = false) {
        if !photoAsset.isSelected {
            if !pickerConfig.isMultipleSelect || (pickerConfig.isSingleVideo && photoAsset.mediaType == .video) {
                if pickerController.pickerData.canSelect(
                    photoAsset,
                    isShowHUD: true,
                    isFilterEditor: isCapture
                ) {
                    pickerController.singleFinishCallback(for: photoAsset)
                }
            }else {
                if let cell = listView.getCell(for: photoAsset) as? PhotoPickerViewCell {
                    cell.selectedAction(false)
                }
            }
        }else {
            if let cell = listView.getCell(for: photoAsset) as? PhotoPickerViewCell {
                cell.selectedAction(true)
            }
        }
    }
    
    func openEditor(
        _ photoAsset: PhotoAsset,
        image: UIImage?,
        animated: Bool = true
    ) {
        if photoAsset.mediaType == .video {
            openVideoEditor(
                photoAsset: photoAsset,
                coverImage: image,
                animated: animated
            )
        }else {
            openPhotoEditor(
                photoAsset: photoAsset,
                animated: animated
            )
        }
    }
    
    @discardableResult
    func openPhotoEditor(
        photoAsset: PhotoAsset,
        animated: Bool = true
    ) -> Bool {
       if photoAsset.mediaType != .photo {
            return false
        }
        let editIndex: Int
        if let index = listView.assets.firstIndex(of: photoAsset) {
            editIndex = index
        }else {
            editIndex = 0
        }
        if !pickerController.shouldEditAsset(photoAsset: photoAsset, atIndex: editIndex) {
            return false
        }
        #if HXPICKER_ENABLE_EDITOR && HXPICKER_ENABLE_PICKER
        if pickerController.config.editorOptions.contains(.photo) {
            guard var config = pickerController.shouldEditPhotoAsset(
                photoAsset: photoAsset,
                editorConfig: pickerController.config.editor,
                atIndex: editIndex
            ) else {
                return false
            }
            config.languageType = pickerController.config.languageType
            config.indicatorType = pickerController.config.indicatorType
             
            config.chartlet.albumPickerConfigHandler = { [weak self] in
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
                .init(type: .photoAsset(photoAsset), result: photoAsset.editedResult),
                config: config,
                delegate: self
            )
            switch pickerController.config.editorJumpStyle {
            case .push(let style):
                if style == .custom {
                    navigationController?.delegate = photoEditorVC
                }
                navigationController?.pushViewController(photoEditorVC, animated: animated)
            case .present(let style):
                if style == .fullScreen {
                    photoEditorVC.modalPresentationStyle = .fullScreen
                }else if style == .custom {
                    photoEditorVC.modalPresentationStyle = .custom
                    photoEditorVC.modalPresentationCapturesStatusBarAppearance = true
                    photoEditorVC.transitioningDelegate = photoEditorVC
                }
                present(photoEditorVC, animated: animated)
            }
            return true
        }
        #endif
        return false
    }
    @discardableResult
    func openVideoEditor(
        photoAsset: PhotoAsset,
        coverImage: UIImage? = nil,
        animated: Bool = true
    ) -> Bool {
        if photoAsset.mediaType != .video {
            return false
        }
        let editIndex: Int
        if let index = listView.assets.firstIndex(of: photoAsset) {
            editIndex = index
        }else {
            editIndex = 0
        }
        if !pickerController.shouldEditAsset(photoAsset: photoAsset, atIndex: editIndex) {
            return false
        }
        #if HXPICKER_ENABLE_EDITOR && HXPICKER_ENABLE_PICKER
        if pickerController.config.editorOptions.contains(.video) {
            let isExceedsTheLimit = pickerController.pickerData.videoDurationExceedsTheLimit(photoAsset)
            var config = pickerController.config.editor
            if isExceedsTheLimit {
                config.video.defaultSelectedToolOption = .time
                config.video.cropTime.maximumTime = TimeInterval(
                    pickerController.config.maximumSelectedVideoDuration
                )
            }
            guard var config = pickerController.shouldEditVideoAsset(
                videoAsset: photoAsset,
                editorConfig: config,
                atIndex: editIndex
            ) else {
                return false
            }
            config.languageType = pickerController.config.languageType
            config.indicatorType = pickerController.config.indicatorType
            config.chartlet.albumPickerConfigHandler = { [weak self] in
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
                .init(type: .photoAsset(photoAsset), result: photoAsset.editedResult),
                config: config,
                delegate: self
            )
            switch pickerController.config.editorJumpStyle {
            case .push(let style):
                if style == .custom {
                    navigationController?.delegate = videoEditorVC
                }
                navigationController?.pushViewController(videoEditorVC, animated: animated)
            case .present(let style):
                if style == .fullScreen {
                    videoEditorVC.modalPresentationStyle = .fullScreen
                }else if style == .custom {
                    videoEditorVC.modalPresentationStyle = .custom
                    videoEditorVC.modalPresentationCapturesStatusBarAppearance = true
                    videoEditorVC.transitioningDelegate = videoEditorVC
                }
                present(videoEditorVC, animated: animated)
            }
            return true
        }
        #endif
        return false
    }
}
