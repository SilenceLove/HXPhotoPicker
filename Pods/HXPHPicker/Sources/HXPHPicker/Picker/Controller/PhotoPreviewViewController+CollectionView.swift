//
//  PhotoPreviewViewController+CollectionView.swift
//  HXPHPicker
//
//  Created by Slience on 2021/8/6.
//

import UIKit

// MARK: UICollectionViewDataSource
extension PhotoPreviewViewController: UICollectionViewDataSource {
    
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return previewAssets.count
    }
    
    public func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        let photoAsset = previewAssets[indexPath.item]
        let cell: PhotoPreviewViewCell
        if photoAsset.mediaType == .photo {
            if photoAsset.mediaSubType == .livePhoto ||
                photoAsset.mediaSubType == .localLivePhoto {
                cell = collectionView.dequeueReusableCell(
                    withReuseIdentifier: NSStringFromClass(PreviewLivePhotoViewCell.self),
                    for: indexPath
                ) as! PreviewLivePhotoViewCell
                let livePhotoCell = cell as! PreviewLivePhotoViewCell
                livePhotoCell.livePhotoPlayType = config.livePhotoPlayType
                livePhotoCell.liveMarkConfig = config.livePhotoMark
            }else {
                cell = collectionView.dequeueReusableCell(
                    withReuseIdentifier: NSStringFromClass(PreviewPhotoViewCell.self),
                    for: indexPath
                ) as! PreviewPhotoViewCell
            }
        }else {
            cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: NSStringFromClass(PreviewVideoViewCell.self),
                for: indexPath
            ) as! PreviewVideoViewCell
            let videoCell = cell as! PreviewVideoViewCell
            videoCell.videoPlayType = config.videoPlayType
            videoCell.statusBarShouldBeHidden = statusBarShouldBeHidden
        }
        cell.delegate = self
        cell.photoAsset = photoAsset
        return cell
    }
}
// MARK: UICollectionViewDelegate
extension PhotoPreviewViewController: UICollectionViewDelegate {
    
    public func collectionView(
        _ collectionView: UICollectionView,
        willDisplay cell: UICollectionViewCell,
        forItemAt indexPath: IndexPath
    ) {
        let myCell = cell as! PhotoPreviewViewCell
        myCell.scrollContentView.startAnimatedImage()
        if myCell.photoAsset.mediaType == .video {
            myCell.scrollView.zoomScale = 1
        }
    }
    public func collectionView(
        _ collectionView: UICollectionView,
        didEndDisplaying cell: UICollectionViewCell,
        forItemAt indexPath: IndexPath
    ) {
        let myCell = cell as! PhotoPreviewViewCell
        myCell.cancelRequest()
    }
    
    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView != collectionView || orientationDidChange {
            return
        }
        let offsetX = scrollView.contentOffset.x  + (view.width + 20) * 0.5
        let viewWidth = view.width + 20
        var currentIndex = Int(offsetX / viewWidth)
        if currentIndex > previewAssets.count - 1 {
            currentIndex = previewAssets.count - 1
        }
        if currentIndex < 0 {
            currentIndex = 0
        }
        if !previewAssets.isEmpty {
            let photoAsset = previewAssets[currentIndex]
            if !isExternalPreview {
                if photoAsset.mediaType == .video && videoLoadSingleCell {
                    selectBoxControl.isHidden = true
                    selectBoxControl.isEnabled = false
                }else {
                    selectBoxControl.isHidden = false
                    selectBoxControl.isEnabled = true
                    updateSelectBox(photoAsset.isSelected, photoAsset: photoAsset)
                    selectBoxControl.isSelected = photoAsset.isSelected
                }
            }
            if !firstLayoutSubviews &&
                config.bottomView.showSelectedView &&
                (isMultipleSelect || isExternalPreview) &&
                config.showBottomView {
                bottomView.selectedView.scrollTo(photoAsset: photoAsset)
            }
            #if HXPICKER_ENABLE_EDITOR
            if let pickerController = pickerController,
               !config.bottomView.editButtonHidden,
               config.showBottomView {
                if photoAsset.mediaType == .photo {
                    bottomView.editBtn.isEnabled = pickerController.config.editorOptions.isPhoto
                }else if photoAsset.mediaType == .video {
                    bottomView.editBtn.isEnabled = pickerController.config.editorOptions.contains(.video)
                }
            }
            #endif
            pickerController?.previewUpdateCurrentlyDisplayedAsset(photoAsset: photoAsset, index: currentIndex)
        }
        self.currentPreviewIndex = currentIndex
    }
    
    public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        if scrollView != collectionView || orientationDidChange {
            return
        }
        if scrollView.isTracking {
            return
        }
        let cell = getCell(for: currentPreviewIndex)
        cell?.requestPreviewAsset()
    }
}

// MARK: PhotoPreviewViewCellDelegate
extension PhotoPreviewViewController: PhotoPreviewViewCellDelegate {
    func cell(requestSucceed cell: PhotoPreviewViewCell) {
        delegate?.previewViewController(self, requestSucceed: cell.photoAsset)
    }
    func cell(requestFailed cell: PhotoPreviewViewCell) {
        delegate?.previewViewController(self, requestFailed: cell.photoAsset)
    }
    func cell(singleTap cell: PhotoPreviewViewCell) {
        if navigationController == nil {
            return
        }
        let isHidden = navigationController!.navigationBar.isHidden
        statusBarShouldBeHidden = !isHidden
        if self.modalPresentationStyle == .fullScreen {
            navigationController?.setNeedsStatusBarAppearanceUpdate()
        }
        navigationController!.setNavigationBarHidden(statusBarShouldBeHidden, animated: true)
        let currentCell = getCell(for: currentPreviewIndex)
        currentCell?.statusBarShouldBeHidden = statusBarShouldBeHidden
        let videoCell = currentCell as? PreviewVideoViewCell
        if !statusBarShouldBeHidden {
            if config.showBottomView {
                bottomView.isHidden = false
            }
            if currentCell?.photoAsset.mediaType == .video && config.singleClickCellAutoPlayVideo {
                currentCell?.scrollContentView.videoView.stopPlay()
            }
            videoCell?.showToolView()
            if let liveCell = currentCell as? PreviewLivePhotoViewCell {
                liveCell.showMark()
            }
        }else {
            if currentCell?.photoAsset.mediaType == .video && config.singleClickCellAutoPlayVideo {
                currentCell?.scrollContentView.videoView.startPlay()
            }
            videoCell?.hideToolView()
            if let liveCell = currentCell as? PreviewLivePhotoViewCell {
                liveCell.hideMark()
            }
        }
        if config.showBottomView {
            UIView.animate(withDuration: 0.25) {
                self.bottomView.alpha = self.statusBarShouldBeHidden ? 0 : 1
            } completion: { (finish) in
                self.bottomView.isHidden = self.statusBarShouldBeHidden
            }
        }
        if let pickerController = pickerController {
            pickerController.pickerDelegate?.pickerController(
                pickerController,
                previewSingleClick: cell.photoAsset,
                atIndex: currentPreviewIndex
            )
        }
    }
    func cell(longPress cell: PhotoPreviewViewCell) {
        if let pickerController = pickerController {
            pickerController.pickerDelegate?.pickerController(
                pickerController,
                previewLongPressClick: cell.photoAsset,
                atIndex: currentPreviewIndex
            )
        }
    }
    
    func photoCell(networkImagedownloadSuccess photoCell: PhotoPreviewViewCell) {
        #if canImport(Kingfisher)
        if let pickerController = pickerController,
           let index = previewAssets.firstIndex(of: photoCell.photoAsset) {
            pickerController.pickerDelegate?.pickerController(
                pickerController,
                previewNetworkImageDownloadSuccess: photoCell.photoAsset,
                atIndex: index
            )
        }
        delegate?.previewViewController(self, networkImagedownloadSuccess: photoCell.photoAsset)
        if config.showBottomView {
            bottomView.requestAssetBytes()
        }
        #endif
    }
    
    func photoCell(networkImagedownloadFailed photoCell: PhotoPreviewViewCell) {
        #if canImport(Kingfisher)
        if let pickerController = pickerController,
           let index = previewAssets.firstIndex(of: photoCell.photoAsset) {
            pickerController.pickerDelegate?.pickerController(
                pickerController,
                previewNetworkImageDownloadFailed: photoCell.photoAsset,
                atIndex: index
            )
        }
        #endif
    }
}
