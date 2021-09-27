//
//  PhotoPickerViewController+CollectionView.swift
//  HXPHPicker
//
//  Created by Slience on 2021/8/4.
//

import UIKit

// MARK: UICollectionViewDataSource
extension PhotoPickerViewController: UICollectionViewDataSource {
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        config.allowAddCamera &&
            canAddCamera &&
            pickerController != nil ? assets.count + 1 : assets.count
    }
    
    public func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        if config.allowAddCamera && canAddCamera {
            if config.sort == .asc {
                if indexPath.item == assets.count {
                    return cameraCell
                }
            }else {
                if indexPath.item == 0 {
                    return cameraCell
                }
            }
        }
        let cell: PhotoPickerBaseViewCell
        let photoAsset = getPhotoAsset(for: indexPath.item)
        if pickerController?.config.selectMode == .single ||
            (photoAsset.mediaType == .video && videoLoadSingleCell) {
            cell = collectionView.dequeueReusableCell(
                withReuseIdentifier:
                    NSStringFromClass(PhotoPickerViewCell.classForCoder()),
                for: indexPath
            ) as! PhotoPickerBaseViewCell
        }else {
            cell = collectionView.dequeueReusableCell(
                withReuseIdentifier:
                    NSStringFromClass(PhotoPickerSelectableViewCell.classForCoder()),
                for: indexPath
            ) as! PhotoPickerBaseViewCell
        }
        cell.delegate = self
        cell.config = config.cell
        cell.photoAsset = photoAsset
        return cell
    }
}

// MARK: UICollectionViewDelegate
extension PhotoPickerViewController: UICollectionViewDelegate {
    
    public func collectionView(
        _ collectionView: UICollectionView,
        willDisplay cell: UICollectionViewCell,
        forItemAt indexPath: IndexPath
    ) {
        if let pickerController = pickerController,
           let myCell = cell as? PhotoPickerBaseViewCell {
            let photoAsset = getPhotoAsset(for: indexPath.item)
            if !photoAsset.isSelected &&
                config.cell.showDisableMask &&
                pickerController.config.maximumSelectedVideoFileSize == 0 &&
                pickerController.config.maximumSelectedPhotoFileSize == 0 {
                myCell.canSelect = pickerController.canSelectAsset(
                    for: photoAsset,
                    showHUD: false
                )
            }else {
                myCell.canSelect = true
            }
            myCell.updateSelectedState(
                isSelected: photoAsset.isSelected,
                animated: false
            )
        }
    }
    public func collectionView(
        _ collectionView: UICollectionView,
        didEndDisplaying cell: UICollectionViewCell,
        forItemAt indexPath: IndexPath
    ) {
        let myCell = cell as? PhotoPickerBaseViewCell
        myCell?.cancelRequest()
    }
    public func collectionView(
        _ collectionView: UICollectionView,
        didSelectItemAt indexPath: IndexPath
    ) {
        didSelectItem(
            indexPath: indexPath,
            animated: true
        )
    }
    func didSelectItem(
        indexPath: IndexPath,
        animated: Bool
    ) {
        if navigationController?.topViewController != self {
            return
        }
        collectionView.deselectItem(at: indexPath, animated: false)
        guard let cell = collectionView.cellForItem(at: indexPath) else {
            return
        }
        if cell is PickerCamerViewCell {
            if !UIImagePickerController.isSourceTypeAvailable(.camera) {
                ProgressHUD.showWarning(
                    addedTo: self.navigationController?.view,
                    text: "相机不可用!".localized,
                    animated: true,
                    delayHide: 1.5
                )
                return
            }
            AssetManager.requestCameraAccess { (granted) in
                if granted {
                    self.presentCameraViewController()
                }else {
                    PhotoTools.showNotCameraAuthorizedAlert(viewController: self)
                }
            }
        }else if cell is PhotoPickerBaseViewCell {
            let myCell = cell as! PhotoPickerBaseViewCell
            if !myCell.canSelect {
                return
            }
            let item = needOffset ? indexPath.item - 1 : indexPath.item
            let photoAsset = myCell.photoAsset!
            if let pickerController = pickerController {
                if !pickerController.shouldClickCell(photoAsset: myCell.photoAsset, index: item) {
                    return
                }
            }
            var selectionTapAction: SelectionTapAction
            if photoAsset.mediaType == .photo {
                selectionTapAction = pickerController!.config.photoSelectionTapAction
            }else {
                selectionTapAction = pickerController!.config.videoSelectionTapAction
            }
            switch selectionTapAction {
            case .preview:
                pushPreviewViewController(previewAssets: assets, currentPreviewIndex: item, animated: animated)
            case .quickSelect:
                photoAsset.playerTime = 0
                quickSelect(photoAsset)
            case .openEditor:
                photoAsset.playerTime = 0
                openEditor(photoAsset, myCell)
            }
        }
    }
    func quickSelect(_ photoAsset: PhotoAsset) {
        if !photoAsset.isSelected {
            if !isMultipleSelect || (videoLoadSingleCell && photoAsset.mediaType == .video) {
                if pickerController?.canSelectAsset(for: photoAsset, showHUD: true) == true {
                    pickerController?.singleFinishCallback(for: photoAsset)
                }
            }else {
                if let cell = getCell(for: photoAsset) as? PhotoPickerViewCell {
                    cell.selectedAction(false)
                }
            }
        }else {
            if let cell = getCell(for: photoAsset) as? PhotoPickerViewCell {
                cell.selectedAction(true)
            }
        }
    }
    func openEditor(_ photoAsset: PhotoAsset,
                    _ cell: PhotoPickerBaseViewCell?,
                    animated: Bool = true) {
        if photoAsset.mediaType == .video {
            openVideoEditor(
                photoAsset: photoAsset,
                coverImage: cell?.photoView.image,
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
        guard let pickerController = pickerController,
              photoAsset.mediaType == .photo else {
            return false
        }
        if !pickerController.shouldEditAsset(photoAsset: photoAsset, atIndex: assets.firstIndex(of: photoAsset) ?? 0) {
            return false
        }
        #if HXPICKER_ENABLE_EDITOR && HXPICKER_ENABLE_PICKER
        if pickerController.config.editorOptions.contains(.photo) {
            let config = pickerController.config.photoEditor
            config.languageType = pickerController.config.languageType
            config.appearanceStyle = pickerController.config.appearanceStyle
            config.indicatorType = pickerController.config.indicatorType
            let photoEditorVC = PhotoEditorViewController(
                photoAsset: photoAsset,
                editResult: photoAsset.photoEdit,
                config: config
            )
            photoEditorVC.delegate = self
            navigationController?.pushViewController(photoEditorVC, animated: animated)
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
        guard let pickerController = pickerController,
              photoAsset.mediaType == .video else {
            return false
        }
        if !pickerController.shouldEditAsset(photoAsset: photoAsset, atIndex: assets.firstIndex(of: photoAsset) ?? 0) {
            return false
        }
        #if HXPICKER_ENABLE_EDITOR && HXPICKER_ENABLE_PICKER
        if pickerController.config.editorOptions.contains(.video) {
            let isExceedsTheLimit = pickerController.videoDurationExceedsTheLimit(photoAsset: photoAsset)
            let config: VideoEditorConfiguration
            if isExceedsTheLimit {
                config = pickerController.config.videoEditor.mutableCopy() as! VideoEditorConfiguration
                config.defaultState = .cropping
                config.cropping.maximumVideoCroppingTime = TimeInterval(
                    pickerController.config.maximumSelectedVideoDuration
                )
                config.mustBeTailored = true
            }else {
                config = pickerController.config.videoEditor
            }
            config.languageType = pickerController.config.languageType
            config.appearanceStyle = pickerController.config.appearanceStyle
            config.indicatorType = pickerController.config.indicatorType
            let videoEditorVC = VideoEditorViewController(
                photoAsset: photoAsset,
                editResult: photoAsset.videoEdit,
                config: config
            )
            videoEditorVC.coverImage = coverImage
            videoEditorVC.delegate = self
            navigationController?.pushViewController(videoEditorVC, animated: animated)
            return true
        }
        #endif
        return false
    }
    
    @available(iOS 13.0, *)
    public func collectionView(
        _ collectionView: UICollectionView,
        contextMenuConfigurationForItemAt indexPath: IndexPath,
        point: CGPoint
    ) -> UIContextMenuConfiguration? {
        guard let sCell = collectionView.cellForItem(at: indexPath),
              config.allowHapticTouchPreview else {
            return nil
        }
        let viewSize = view.size
        return .init(
            identifier: indexPath as NSCopying
        ) {
            if let cell = sCell as? PhotoPickerBaseViewCell {
                let photoAsset = cell.photoAsset!
                let imageSize = photoAsset.imageSize
                let aspectRatio = imageSize.width / imageSize.height
                let maxWidth = viewSize.width - UIDevice.leftMargin - UIDevice.rightMargin - 60
                let maxHeight = UIScreen.main.bounds.height * 0.659
                var width = imageSize.width
                var height = imageSize.height
                if width > maxWidth {
                    width = maxWidth
                    height = min(width / aspectRatio, maxHeight)
                }
                if height > maxHeight {
                    height = maxHeight
                    width = min(height * aspectRatio, maxWidth)
                }
                width = max(120, width)
                height = max(120, height)
                let vc = PhotoPeekViewController(photoAsset)
                vc.preferredContentSize = CGSize(width: width, height: height)
                return vc
            }else if sCell is PickerCamerViewCell &&
                     UIImagePickerController.isSourceTypeAvailable(.camera) &&
                     AssetManager.cameraAuthorizationStatus() == .authorized {
                let vc = PhotoPeekViewController(isCamera: true)
                return vc
            }
            return nil
        } actionProvider: { menuElements in
            guard let picker = self.pickerController,
                  let cell = sCell as? PhotoPickerBaseViewCell,
                  self.config.allowAddMenuElements else { return nil }
            var menus: [UIMenuElement] = []
            let photoAsset = cell.photoAsset!
            if picker.config.selectMode == .multiple {
                let select = UIAction(
                    title: photoAsset.isSelected ? "取消选择".localized : "选择".localized
                ) { action in
                    self.updateCellSelectedState(
                        for: indexPath.item,
                        isSelected: !photoAsset.isSelected
                    )
                }
                menus.append(select)
            }
            
            #if HXPICKER_ENABLE_EDITOR
            let options: PickerAssetOptions
            if photoAsset.mediaType == .photo {
                options = .photo
            }else {
                options = .video
            }
            if picker.config.editorOptions.contains(options) {
                let edit = UIAction(
                    title: "编辑".localized
                ) { action in
                    self.openEditor(
                        photoAsset,
                        cell,
                        animated: picker.config.selectMode == .multiple
                    )
                }
                menus.append(edit)
            }
            #endif
            
            return .init(
                children: menus
            )
        }
    }
    
    @available(iOS 13.0, *)
    public func collectionView(
        _ collectionView: UICollectionView,
        willPerformPreviewActionForMenuWith configuration: UIContextMenuConfiguration,
        animator: UIContextMenuInteractionCommitAnimating
    ) {
        guard let indexPath = configuration.identifier as? IndexPath else {
            return
        }
        animator.addCompletion { [weak self] in
            self?.didSelectItem(
                indexPath: indexPath,
                animated: false
            )
        }
    }
}
