//
//  PhotoPickerView+CollectionView.swift
//  HXPhotoPicker
//
//  Created by Slience on 2021/9/17.
//

import UIKit
import Photos
import PhotosUI

extension PhotoPickerView: UICollectionViewDataSource {
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if canAddCamera && canAddLimit {
            return assets.count + 2
        }else if canAddCamera || canAddLimit {
            return assets.count + 1
        }
        return assets.count
    }
    func getAdditiveCell(_ indexPath: IndexPath) -> UICollectionViewCell? {
        if canAddCamera && canAddLimit {
            if config.sort == .asc {
                if indexPath.item == assets.count + 1 {
                    #if !targetEnvironment(macCatalyst)
                    return cameraCell
                    #endif
                }
                if indexPath.item == assets.count {
                    return limitAddCell
                }
            }else {
                if indexPath.item == 0 {
                    #if !targetEnvironment(macCatalyst)
                    return cameraCell
                    #endif
                }
                if indexPath.item == 1 {
                    return limitAddCell
                }
            }
        }else if canAddCamera || canAddLimit {
            if config.sort == .asc {
                if indexPath.item == assets.count {
                    if canAddCamera {
                        #if !targetEnvironment(macCatalyst)
                        return cameraCell
                        #endif
                    }
                    return limitAddCell
                }
            }else {
                if indexPath.item == 0 {
                    if canAddCamera {
                        #if !targetEnvironment(macCatalyst)
                        return cameraCell
                        #endif
                    }
                    return limitAddCell
                }
            }
        }
        return nil
    }
    public func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        if let cell = getAdditiveCell(indexPath) {
            #if !targetEnvironment(macCatalyst)
            if let cell = cell as? PickerCameraViewCell {
                cell.allowPreview = allowPreview
                cell.config = config.cameraCell
                if !allowPreview {
                    cell.stopSession()
                }
            }
            #endif
            return cell
        }
        let cell: PhotoPickerBaseViewCell
        let photoAsset = getPhotoAsset(for: indexPath.item)
        if manager.config.selectMode == .single ||
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
extension PhotoPickerView: UICollectionViewDelegate {
    
    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard scrollDirection == .horizontal else {
            resetScrollCell()
            return
        }
        let offsetX = scrollView.contentOffset.x + collectionView.width
        let point = CGPoint(x: offsetX, y: collectionView.height * 0.5)
        guard let indexPath = collectionView.indexPathForItem(at: point),
              let cell = collectionView.cellForItem(at: indexPath) as? PhotoPickerSelectableViewCell else {
            resetScrollCell()
            return
        }
        resetScrollCell(indexPath)
        scrollIndexPath = indexPath
        cell.photoAsset.isScrolling = true
        let rightMargin = cell.config.selectBoxRightMargin
        var m = offsetX - cell.x - cell.selectControl.width - rightMargin
        if m < 0 {
            m = 0
        }
        if m > cell.width - rightMargin - cell.selectControl.width {
            m = cell.width - rightMargin - cell.selectControl.width
        }
        cell.selectControl.x = m
    }
    
    func resetScrollCell(_ indexPath: IndexPath? = nil) {
        guard let scrollIndexPath = scrollIndexPath else {
            return
        }
        guard let cell = collectionView.cellForItem(at: scrollIndexPath) as? PhotoPickerSelectableViewCell else {
            if !assets.isEmpty {
                let photoAsset = getPhotoAsset(for: scrollIndexPath.item)
                photoAsset.isScrolling = false
            }
            self.scrollIndexPath = nil
            return
        }
        guard let indexPath = indexPath else {
            cell.photoAsset.isScrolling = false
            cell.updateSelectControlSize()
            self.scrollIndexPath = nil
            return
        }
        if scrollIndexPath.item != indexPath.item {
            cell.photoAsset.isScrolling = false
            cell.updateSelectControlSize()
            self.scrollIndexPath = nil
        }
    }
    
    public func collectionView(
        _ collectionView: UICollectionView,
        willDisplay cell: UICollectionViewCell,
        forItemAt indexPath: IndexPath
    ) {
        if let myCell = cell as? PhotoPickerBaseViewCell {
            let photoAsset = getPhotoAsset(for: indexPath.item)
            if !photoAsset.isSelected &&
                config.cell.isShowDisableMask &&
                manager.config.maximumSelectedVideoFileSize == 0 &&
                manager.config.maximumSelectedPhotoFileSize == 0 {
                myCell.canSelect = manager.canSelectAsset(
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
        collectionView.deselectItem(at: indexPath, animated: false)
        guard let cell = collectionView.cellForItem(at: indexPath) else {
            return
        }
        let isCameraCell: Bool
        #if !targetEnvironment(macCatalyst)
        isCameraCell = cell is PickerCameraViewCell
        #else
        isCameraCell = false
        #endif
        if isCameraCell {
            #if !targetEnvironment(macCatalyst)
            if !UIImagePickerController.isSourceTypeAvailable(.camera) {
                ProgressHUD.showWarning(
                    addedTo: UIApplication.shared.keyWindow,
                    text: .textPhotoList.cameraUnavailableHudTitle.text,
                    animated: true,
                    delayHide: 1.5
                )
                return
            }
            AssetManager.requestCameraAccess { (granted) in
                if granted {
                    self.presentCameraViewController()
                }else {
                    PhotoTools.showNotCameraAuthorizedAlert(viewController: self.viewController)
                }
            }
            #endif
        }else if cell is PhotoPickerLimitCell {
            guard let vc = UIViewController.topViewController else {
                return
            }
            if #available(iOS 14, *) {
                PHPhotoLibrary.shared().presentLimitedLibraryPicker(from: vc)
            }
        }else if let myCell = cell as? PhotoPickerBaseViewCell,
                 let photoAsset = myCell.photoAsset {
            if !myCell.canSelect {
                return
            }
            if let pickerCell = myCell as? PhotoPickerViewCell,
               pickerCell.inICloud {
                photoAsset.syncICloud { [weak self] photoAsset, _ in
                    self?.resetICloud(for: photoAsset)
                }
                return
            }
            let item = needOffset ? indexPath.item - offsetIndex : indexPath.item
            var selectionTapAction: SelectionTapAction
            if photoAsset.mediaType == .photo {
                selectionTapAction = manager.config.photoSelectionTapAction
            }else {
                selectionTapAction = manager.config.videoSelectionTapAction
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
                if manager.canSelectAsset(for: photoAsset, showHUD: true) == true {
                    manager.addedPhotoAsset(photoAsset: photoAsset)
                    finishSelectionAsset([photoAsset])
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
        guard photoAsset.mediaType == .photo else {
            return false
        }
        #if HXPICKER_ENABLE_EDITOR && HXPICKER_ENABLE_PICKER
        if manager.config.editorOptions.contains(.photo) {
            guard var config = delegate?.photoPickerView(
                self,
                shouldEditPhotoAsset: photoAsset,
                editorConfig: manager.config.editor
            ) else {
                return false
            }
            config.languageType = manager.config.languageType
            config.indicatorType = manager.config.indicatorType
            let photoEditorVC = EditorViewController(
                .init(type: .photoAsset(photoAsset), result: photoAsset.editedResult),
                config: config,
                delegate: self
            )
            viewController?.present(photoEditorVC, animated: animated)
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
        guard photoAsset.mediaType == .video else {
            return false
        }
        #if HXPICKER_ENABLE_EDITOR && HXPICKER_ENABLE_PICKER
        if manager.config.editorOptions.contains(.video) {
            let isExceedsTheLimit = manager.videoDurationExceedsTheLimit(photoAsset: photoAsset)
            var config = manager.config.editor
            if isExceedsTheLimit {
                config.video.defaultSelectedToolOption = .time
                config.video.cropTime.maximumTime = TimeInterval(
                    manager.config.maximumSelectedVideoDuration
                )
            }
            guard var config = delegate?.photoPickerView(
                self,
                shouldEditVideoAsset: photoAsset,
                editorConfig: config
            ) else {
                return false
            }
            config.languageType = manager.config.languageType
            config.indicatorType = manager.config.indicatorType
            
            let videoEditorVC = EditorViewController(
                .init(type: .photoAsset(photoAsset), result: photoAsset.editedResult),
                config: config,
                delegate: self
            )
//            videoEditorVC.videoEditor?.coverImage = coverImage
            viewController?.present(videoEditorVC, animated: animated)
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
        let isCameraCell: Bool
        let isAuthorized: Bool
        let isSourceTypeAvailable: Bool
        #if !targetEnvironment(macCatalyst)
        isCameraCell = sCell is PickerCameraViewCell
        isAuthorized = AssetManager.cameraAuthorizationStatus() == .authorized
        isSourceTypeAvailable = UIImagePickerController.isSourceTypeAvailable(.camera)
        #else
        isCameraCell = false
        isAuthorized = false
        isSourceTypeAvailable = false
        #endif
        let viewSize = size
        return .init(
            identifier: indexPath as NSCopying
        ) {
            if let cell = sCell as? PhotoPickerBaseViewCell {
                let photoAsset = cell.photoAsset!
                let imageSize = photoAsset.imageSize
                let aspectRatio = imageSize.width / imageSize.height
                let maxWidth = viewSize.width - UIDevice.leftMargin - UIDevice.rightMargin - 60
                let maxHeight = UIDevice.screenSize.height * 0.659
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
                vc.delegate = self
                vc.preferredContentSize = CGSize(width: width, height: height)
                return vc
            }else if isCameraCell && isSourceTypeAvailable && isAuthorized {
                let vc = PhotoPeekViewController(isCamera: true)
                return vc
            }
            return nil
        } actionProvider: { _ in
            guard let cell = sCell as? PhotoPickerBaseViewCell,
                  let photoAsset = cell.photoAsset,
                  self.config.allowAddMenuElements else { return nil }
            var menus: [UIMenuElement] = []
            
            if self.manager.config.selectMode == .multiple {
                let title: String
                let image: UIImage?
                let attributes: UIMenuElement.Attributes
                if photoAsset.isSelected {
                    title = .textPhotoList.hapticTouchDeselectedTitle.text
                    image = UIImage(systemName: "minus.circle")
                    attributes = [.destructive]
                }else {
                    title = .textPhotoList.hapticTouchSelectedTitle.text
                    image = UIImage(systemName: "checkmark.circle")
                    attributes = []
                }
                let select = UIAction(
                    title: title,
                    image: image,
                    attributes: attributes
                ) { _ in
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
            if self.manager.config.editorOptions.contains(options) {
                let edit = UIAction(
                    title: .textPhotoList.hapticTouchEditTitle.text,
                    image: UIImage(systemName: "slider.horizontal.3")
                ) { _ in
                    self.openEditor(
                        photoAsset,
                        cell,
                        animated: self.manager.config.selectMode == .multiple
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

extension PhotoPickerView: UICollectionViewDelegateFlowLayout {
    public func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        minimumLineSpacingForSectionAt section: Int
    ) -> CGFloat {
        config.spacing
    }
    public func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        minimumInteritemSpacingForSectionAt section: Int
    ) -> CGFloat {
        config.spacing
    }
    public func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        if scrollDirection == .vertical {
            let space = config.spacing
            let count: CGFloat
            if  UIDevice.isPortrait == true {
                count = CGFloat(config.rowNumber)
            }else {
                count = CGFloat(config.landscapeRowNumber)
            }
            let collectionWidth = collectionView.width - contentInset.left - contentInset.right
            let itemWidth = (collectionWidth - space * (count - CGFloat(1))) / count
            return CGSize(width: itemWidth, height: itemWidth)
        }
        let maxHeight = height - contentInset.top - contentInset.bottom
        let minWidth = maxHeight / 16 * 9
        if canAddCamera && canAddLimit {
            if config.sort == .asc {
                if indexPath.item == assets.count + 1 || indexPath.item == assets.count {
                    return CGSize(width: minWidth, height: maxHeight)
                }
            }else {
                if indexPath.item == 0 || indexPath.item == 1 {
                    return CGSize(width: minWidth, height: maxHeight)
                }
            }
        }else if canAddCamera || canAddLimit {
            if config.sort == .asc {
                if indexPath.item == assets.count {
                    return CGSize(width: minWidth, height: maxHeight)
                }
            }else {
                if indexPath.item == 0 {
                    return CGSize(width: minWidth, height: maxHeight)
                }
            }
        }
        let maxWidth = min(width - 60, maxHeight / 9 * 14)
        let photoAsset = getPhotoAsset(for: indexPath.item)
        let assetSize = photoAsset.imageSize
        let aspectRatio = assetSize.width / assetSize.height
        var itemWidth = maxHeight
        var itemHeight = itemWidth / aspectRatio
        if itemHeight != maxHeight {
            itemHeight = maxHeight
            itemWidth = itemHeight * aspectRatio
            itemWidth = max(itemWidth, minWidth)
            itemWidth = min(itemWidth, maxWidth)
        }
        return CGSize(width: itemWidth, height: itemHeight)
    }
}

extension PhotoPickerView: PhotoPeekViewControllerDelegate {
    public func photoPeekViewController(
        requestSucceed photoPeekViewController: PhotoPeekViewController
    ) {
        guard let photoAsset = photoPeekViewController.photoAsset else {
            return
        }
        resetICloud(for: photoAsset)
    }
}
