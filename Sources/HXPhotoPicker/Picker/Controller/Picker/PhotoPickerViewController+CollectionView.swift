//
//  PhotoPickerViewController+CollectionView.swift
//  HXPhotoPicker
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
            config.cell.isShowDisableMask &&
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
        if let pickerCell = myCell as? PhotoPickerViewCell {
            pickerCell.cancelSyncICloud()
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
        if navigationController?.topViewController != self {
            return
        }
        collectionView.deselectItem(at: indexPath, animated: false)
        guard let cell = collectionView.cellForItem(at: indexPath) else {
            return
        }
        #if !targetEnvironment(macCatalyst)
        if cell is PickerCameraViewCell {
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
        #endif
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
                if pickerCell.photoAsset.downloadStatus != .downloading {
                    pickerCell.syncICloud()
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
        let editIndex: Int
        if let index = assets.firstIndex(of: photoAsset) {
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
                if let config = self?.pickerController?.config {
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
        guard let pickerController = pickerController,
              photoAsset.mediaType == .video else {
            return false
        }
        let editIndex: Int
        if let index = assets.firstIndex(of: photoAsset) {
            editIndex = index
        }else {
            editIndex = 0
        }
        if !pickerController.shouldEditAsset(photoAsset: photoAsset, atIndex: editIndex) {
            return false
        }
        #if HXPICKER_ENABLE_EDITOR && HXPICKER_ENABLE_PICKER
        if pickerController.config.editorOptions.contains(.video) {
            let isExceedsTheLimit = pickerController.videoDurationExceedsTheLimit(photoAsset: photoAsset)
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
                if let config = self?.pickerController?.config {
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
                }
                present(videoEditorVC, animated: animated)
            }
            return true
        }
        #endif
        return false
    }
    
    @available(iOS 13.0, *)
    public func collectionView(
        _ collectionView: UICollectionView,
        contextMenuConfiguration configuration: UIContextMenuConfiguration,
        highlightPreviewForItemAt indexPath: IndexPath
    ) -> UITargetedPreview? {
        guard let cell = collectionView.cellForItem(at: indexPath) as? PhotoPickerBaseViewCell,
              config.allowHapticTouchPreview else {
            return nil
        }
        return .init(view: cell)
    }
    
    @available(iOS 13.0, *)
    public func collectionView(
        _ collectionView: UICollectionView,
        contextMenuConfigurationForItemsAt indexPaths: [IndexPath],
        point: CGPoint
    ) -> UIContextMenuConfiguration? {
        guard let indexPath = indexPaths.first,
              let sCell = collectionView.cellForItem(at: indexPath),
              config.allowHapticTouchPreview else {
            return nil
        }
        let isCameraCell: Bool
        #if !targetEnvironment(macCatalyst)
        isCameraCell = sCell is PickerCameraViewCell
        if isCameraCell {
            if !UIImagePickerController.isSourceTypeAvailable(.camera) ||
               AssetManager.cameraAuthorizationStatus() != .authorized {
                return nil
            }
        }
        #else
        isCameraCell = false
        #endif
        let viewSize = view.size
        return .init(
            identifier: indexPath as NSCopying
        ) {
            if let cell = sCell as? PhotoPickerBaseViewCell {
                let photoAsset = cell.photoAsset!
                let imageSize = photoAsset.imageSize
                let aspectRatio = imageSize.width / imageSize.height
                let maxWidth = viewSize.width - UIDevice.leftMargin - UIDevice.rightMargin - 60
                let maxHeight: CGFloat
                if UIDevice.isPortrait {
                    maxHeight = UIDevice.screenSize.height * 0.659
                }else {
                    maxHeight = UIDevice.screenSize.height - UIDevice.topMargin - UIDevice.bottomMargin
                }
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
            }else if isCameraCell {
                let vc = PhotoPeekViewController(isCamera: true)
                return vc
            }
            return nil
        } actionProvider: { [weak self] _ in
            guard let self = self,
                  let picker = self.pickerController,
                  let cell = sCell as? PhotoPickerBaseViewCell,
                  self.config.allowAddMenuElements else { return nil }
            var menus: [UIMenuElement] = []
            let photoAsset = cell.photoAsset!
            if picker.config.selectMode == .multiple {
                let title: String
                let image: UIImage?
                let attributes: UIMenuElement.Attributes
                if photoAsset.isSelected {
                    title = "取消选择".localized
                    image = UIImage(systemName: "minus.circle")
                    attributes = [.destructive]
                }else {
                    title = "选择".localized
                    image = UIImage(systemName: "checkmark.circle")
                    attributes = []
                }
                let select = UIAction(
                    title: title,
                    image: image,
                    attributes: attributes
                ) { [weak self] _ in
                    guard let self = self,
                          let cell = self.getCell(for: indexPath.item) else {
                        return
                    }
                    self.cell(cell, didSelectControl: photoAsset.isSelected)
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
                    title: "编辑".localized,
                    image: UIImage(systemName: "slider.horizontal.3")
                ) { [weak self] _ in
                    self?.openEditor(
                        photoAsset,
                        cell,
                        animated: true
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
        if config.isShowAssetNumber &&
            kind == UICollectionView.elementKindSectionFooter &&
            (photoCount > 0 || videoCount > 0) {
            let view = collectionView
                .dequeueReusableSupplementaryView(
                    ofKind: kind,
                    withReuseIdentifier: NSStringFromClass(BottomNumberView.classForCoder()),
                    for: indexPath
                ) as! BottomNumberView
            view.photoCount = photoCount
            view.videoCount = videoCount
            view.config = config.assetNumber
            view.filterOptions = filterOptions
            view.didFilterHandler = { [weak self] in
                self?.didFilterItemClick()
            }
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
        if config.isShowAssetNumber && (photoCount > 0 || videoCount > 0) {
            return CGSize(width: view.width, height: filterOptions == .any ? 50 : 70)
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
