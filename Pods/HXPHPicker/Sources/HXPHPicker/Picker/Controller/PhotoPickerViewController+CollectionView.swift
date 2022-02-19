//
//  PhotoPickerViewController+CollectionView.swift
//  HXPHPicker
//
//  Created by Slience on 2021/8/4.
//

import UIKit
import Photos
import PhotosUI

// MARK: UICollectionViewDataSource
extension PhotoPickerViewController: UICollectionViewDataSource {
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if pickerController == nil {
            return assets.count
        }
        if canAddCamera && canAddLimit {
            return assets.count + 2
        }else if canAddCamera || canAddLimit {
            return assets.count + 1
        }else {
            return assets.count
        }
    }
    func getAdditiveCell(_ indexPath: IndexPath) -> UICollectionViewCell? {
        if canAddCamera && canAddLimit {
            if config.sort == .asc {
                if indexPath.item == assets.count + 1 {
                    return cameraCell
                }
                if indexPath.item == assets.count {
                    return limitAddCell
                }
            }else {
                if indexPath.item == 0 {
                    return cameraCell
                }
                if indexPath.item == 1 {
                    return limitAddCell
                }
            }
        }else if canAddCamera || canAddLimit {
            if config.sort == .asc {
                if indexPath.item == assets.count {
                    return canAddCamera ? cameraCell : limitAddCell
                }
            }else {
                if indexPath.item == 0 {
                    return canAddCamera ? cameraCell : limitAddCell
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
            return cell
        }
        let cell: PhotoPickerBaseViewCell
        let photoAsset = getPhotoAsset(for: indexPath.item)
        let isPickerCell: Bool
        if let picker = pickerController,
           picker.config.selectMode == .single {
            isPickerCell = true
        }else if photoAsset.mediaType == .video && videoLoadSingleCell {
            isPickerCell = true
        }else {
            isPickerCell = false
        }
        if isPickerCell {
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
        cell.isRequestDirectly = false
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
        guard let pickerController = pickerController,
              let myCell = cell as? PhotoPickerBaseViewCell else {
            return
        }
        myCell.request()
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
    public func collectionView(
        _ collectionView: UICollectionView,
        didEndDisplaying cell: UICollectionViewCell,
        forItemAt indexPath: IndexPath
    ) {
        guard let myCell = cell as? PhotoPickerBaseViewCell else {
            return
        }
        myCell.cancelReload()
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
            return
        }
        if cell is PhotoPickerLimitCell {
            if #available(iOS 14, *) {
                PHPhotoLibrary.shared().presentLimitedLibraryPicker(from: self)
            }
            return
        }
        if let myCell = cell as? PhotoPickerBaseViewCell,
           let photoAsset = myCell.photoAsset {
            if !myCell.canSelect {
                return
            }
            
            if let pickerCell = myCell as? PhotoPickerViewCell,
               pickerCell.inICloud {
                photoAsset.syncICloud(
                    hudAddedTo: navigationController?.view
                ) { [weak self] photoAsset, _ in
                    self?.resetICloud(for: photoAsset)
                }
                return
            }
            let item = needOffset ? indexPath.item - offsetIndex : indexPath.item
            guard let picker = pickerController else {
                return
            }
            if !picker.shouldClickCell(photoAsset: myCell.photoAsset, index: item) {
                return
            }
            var selectionTapAction: SelectionTapAction
            if photoAsset.mediaType == .photo {
                selectionTapAction = picker.config.photoSelectionTapAction
            }else {
                selectionTapAction = picker.config.videoSelectionTapAction
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
    func quickSelect(
        _ photoAsset: PhotoAsset,
        isCapture: Bool = false
    ) {
        guard let picker = pickerController else {
            return
        }
        if !photoAsset.isSelected {
            if !isMultipleSelect || (videoLoadSingleCell && photoAsset.mediaType == .video) {
                if picker.canSelectAsset(
                    for: photoAsset,
                    showHUD: true,
                    filterEditor: isCapture
                ) {
                    picker.singleFinishCallback(for: photoAsset)
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
            if pickerController.config.editorCustomTransition {
                navigationController?.delegate = photoEditorVC
            }
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
                config.defaultState = .cropTime
                config.cropTime.maximumVideoCroppingTime = TimeInterval(
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
            if pickerController.config.editorCustomTransition {
                navigationController?.delegate = videoEditorVC
            }
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
                vc.delegate = self
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
    
    public func collectionView(
        _ collectionView: UICollectionView,
        viewForSupplementaryElementOfKind kind: String,
        at indexPath: IndexPath
    ) -> UICollectionReusableView {
        if config.showAssetNumber &&
            kind == UICollectionView.elementKindSectionFooter &&
            (photoCount > 0 || videoCount > 0) {
            let view = collectionView
                .dequeueReusableSupplementaryView(
                    ofKind: kind,
                    withReuseIdentifier: NSStringFromClass(PhotoPickerBottomNumberView.classForCoder()),
                    for: indexPath
                ) as! PhotoPickerBottomNumberView
            view.photoCount = photoCount
            view.videoCount = videoCount
            view.config = config.assetNumber
            return view
        }
        return .init()
    }
    public func scrollViewDidScrollToTop(_ scrollView: UIScrollView) {
        PhotoManager.shared.thumbnailLoadModeDidChange(.complete)
        cellReloadImage()
        scrollToTop = false
    }
    public func scrollViewShouldScrollToTop(_ scrollView: UIScrollView) -> Bool {
        scrollToTop = true
        scrollEndReload = true
        PhotoManager.shared.thumbnailLoadModeDidChange(.simplify)
        return true
    }
//    public func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
//        setCellLoadMode(.complete)
//        print("BeginDragging complete")
//    }
    public func scrollViewDidEndDragging(
        _ scrollView: UIScrollView,
        willDecelerate decelerate: Bool
    ) {
        if !decelerate && !scrollToTop {
            didChangeCellLoadMode = false
            cellReloadImage()
        }
    }
    public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        if !scrollView.isTracking && !scrollToTop {
            didChangeCellLoadMode = false
            cellReloadImage()
        }
    }
    public func scrollViewWillEndDragging(
        _ scrollView: UIScrollView,
        withVelocity velocity: CGPoint,
        targetContentOffset: UnsafeMutablePointer<CGPoint>
    ) {
        let offset = targetContentOffset.pointee
        let abs = abs(offset.y - scrollView.contentOffset.y)
        if abs < 3000 {
            if scrollReachDistance {
                setCellLoadMode(.complete, false)
                scrollReachDistance = false
            }
            return
        }
        targetOffsetY = offset.y
        setCellLoadMode(.simplify)
        scrollReachDistance = true
    }
    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if didChangeCellLoadMode {
            if abs(targetOffsetY - scrollView.contentOffset.y) < 1250 {
                setCellLoadMode(.complete)
            }
        }
    }
    func setCellLoadMode(
        _ mode: PhotoManager.ThumbnailLoadMode,
        _ judgmentIsEqual: Bool = true
    ) {
        if PhotoManager.shared.thumbnailLoadMode == mode && judgmentIsEqual {
            return
        }
        PhotoManager.shared.thumbnailLoadModeDidChange(mode)
        scrollEndReload = mode == .complete
        didChangeCellLoadMode = mode != .complete
    }
    func cellReloadImage() {
        if !scrollEndReload && !didChangeCellLoadMode {
            return
        }
        for baseCell in collectionView.visibleCells where baseCell is PhotoPickerBaseViewCell {
            let cell = baseCell as! PhotoPickerBaseViewCell
            cell.reload()
        }
        scrollEndReload = false
    }
}

extension PhotoPickerViewController: UICollectionViewDelegateFlowLayout {
    public func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        referenceSizeForFooterInSection section: Int
    ) -> CGSize {
        if config.showAssetNumber && (photoCount > 0 || videoCount > 0) {
            return CGSize(width: view.width, height: 50)
        }
        return .zero
    }
}

extension PhotoPickerViewController: PhotoPeekViewControllerDelegate {
    public func photoPeekViewController(
        requestSucceed photoPeekViewController: PhotoPeekViewController
    ) {
        guard let photoAsset = photoPeekViewController.photoAsset else {
            return
        }
        resetICloud(for: photoAsset)
    }
}
