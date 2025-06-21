//
//  PhotoPreviewViewController+CollectionView.swift
//  HXPhotoPicker
//
//  Created by Slience on 2021/8/6.
//

import UIKit

// MARK: UICollectionViewDataSource
extension PhotoPreviewViewController: UICollectionViewDataSource {
    
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        assetCount
    }
    
    public func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        guard let photoAsset = photoAsset(for: indexPath.item) else {
            return collectionView.dequeueReusableCell(
                withReuseIdentifier: PreviewPhotoViewCell.className,
                for: indexPath
            )
        }
        let cell: PhotoPreviewViewCell
        if photoAsset.mediaType == .photo {
            if photoAsset.mediaSubType.isLivePhoto {
                cell = collectionView.dequeueReusableCell(
                    withReuseIdentifier: PreviewLivePhotoViewCell.className,
                    for: indexPath
                ) as! PreviewLivePhotoViewCell
                let livePhotoCell = cell as! PreviewLivePhotoViewCell
                livePhotoCell.livePhotoPlayType = config.livePhotoPlayType
                livePhotoCell.liveMarkConfig = config.livePhotoMark
            }else {
                cell = collectionView.dequeueReusableCell(
                    withReuseIdentifier: PreviewPhotoViewCell.className,
                    for: indexPath
                ) as! PreviewPhotoViewCell
                let photoCell = cell as! PreviewPhotoViewCell
                photoCell.HDRMarkConfig = config.HDRMark
            }
        }else {
            cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: PreviewVideoViewCell.className,
                for: indexPath
            ) as! PreviewVideoViewCell
            let videoCell = cell as! PreviewVideoViewCell
            videoCell.videoPlayType = config.videoPlayType
            videoCell.statusBarShouldBeHidden = statusBarShouldBeHidden
            videoCell.previewType = previewType
        }
        cell.contentMaximumZoomScale = config.maximumZoomScale
        cell.delegate = self
        cell.photoAsset = photoAsset
        cellForIndex?(cell, indexPath.item, currentPreviewIndex)
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
        myCell.scrollContentView.startAnimated()
        if myCell.photoAsset.mediaType == .video {
            myCell.scrollView.zoomScale = 1
        }
        myCell.checkContentSize()
        pickerController.pickerDelegate?.pickerController(
            pickerController,
            previewCellWillDisplay: myCell.photoAsset,
            at: indexPath.item
        )
    }
    public func collectionView(
        _ collectionView: UICollectionView,
        didEndDisplaying cell: UICollectionViewCell,
        forItemAt indexPath: IndexPath
    ) {
        let myCell = cell as! PhotoPreviewViewCell
        myCell.cancelRequest()
        pickerController.pickerDelegate?.pickerController(
            pickerController,
            previewCellDidEndDisplaying: myCell.photoAsset,
            at: indexPath.item
        )
    }
    
    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView != collectionView || orientationDidChange {
            return
        }
        let viewWidth = view.width + 20
        let offsetX = scrollView.contentOffset.x + viewWidth * 0.5
        var currentIndex = Int(offsetX / viewWidth)
        if currentIndex > assetCount - 1 {
            currentIndex = assetCount - 1
        }
        if currentIndex < 0 {
            currentIndex = 0
        }
        if let photoAsset = photoAsset(for: currentIndex) {
            if previewType != .browser {
                if photoAsset.mediaType == .video && pickerConfig.isSingleVideo {
                    selectBoxControl.isHidden = true
                    selectBoxControl.isEnabled = false
                }else {
                    selectBoxControl.isHidden = false
                    selectBoxControl.isEnabled = true
                    updateSelectBox(photoAsset.isSelected, photoAsset: photoAsset)
                    selectBoxControl.isSelected = photoAsset.isSelected
                }
            }
            if !firstLayoutSubviews && isShowToolbar {
                photoToolbar.selectedViewScrollTo(photoAsset, animated: true)
            }
            #if HXPICKER_ENABLE_EDITOR
            if isShowToolbar {
                if photoAsset.mediaType == .photo {
                    photoToolbar.updateEditState(pickerController.config.editorOptions.isPhoto)
                }else if photoAsset.mediaType == .video {
                    photoToolbar.updateEditState(pickerController.config.editorOptions.contains(.video))
                }
            }
            #endif
            pickerController.previewUpdateCurrentlyDisplayedAsset(photoAsset: photoAsset, index: currentIndex)
        }
        self.currentPreviewIndex = currentIndex
        if !firstLayoutSubviews && isShowToolbar {
            photoToolbar.previewListDidScroll(scrollView)
        }
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
        if let cell {
            if let videoCell = cell as? PreviewVideoControlViewCell, statusBarShouldBeHidden {
                videoCell.showToolView()
            }
            pickerController.pickerDelegate?.pickerController(
                pickerController,
                previewDidEndDecelerating: cell.photoAsset,
                at: currentPreviewIndex
            )
        }
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
        guard let navigationController = navigationController else {
            return
        }
        if let pickerDelegate = pickerController.pickerDelegate,
           !pickerDelegate.pickerController(
            pickerController,
            previewShouldSingleClick: cell.photoAsset,
            at: currentPreviewIndex) {
            return
        }
        let isHidden = navigationController.navigationBar.isHidden
        statusBarShouldBeHidden = !isHidden
        if self.modalPresentationStyle == .fullScreen ||
            pickerController.splitViewController?.modalPresentationStyle == .fullScreen {
            navigationController.setNeedsStatusBarAppearanceUpdate()
        }
        navigationController.setNavigationBarHidden(statusBarShouldBeHidden, animated: true)
        let currentCell = getCell(for: currentPreviewIndex)
        currentCell?.statusBarShouldBeHidden = statusBarShouldBeHidden
        let videoCell = currentCell as? PreviewVideoViewCell
        if !statusBarShouldBeHidden {
            if isShowToolbar {
                photoToolbar.isHidden = false
            }
            navBgView?.isHidden = false
            if currentCell?.photoAsset.mediaType == .video && config.singleClickCellAutoPlayVideo {
                currentCell?.scrollContentView.videoView.stopPlay()
            }
            if previewType != .browser {
                videoCell?.hideToolView()
            }else {
                videoCell?.showToolView()
            }
            if let photoAsset = currentCell?.photoAsset, photoAsset.mediaSubType.isHDRPhoto || photoAsset.mediaSubType.isLivePhoto {
                currentCell?.showScrollContainerSubview()
            }
        }else {
            if currentCell?.photoAsset.mediaType == .video && config.singleClickCellAutoPlayVideo {
                currentCell?.scrollContentView.videoView.startPlay()
            }
            if previewType != .browser {
                videoCell?.showToolView()
            }else {
                videoCell?.hideToolView()
            }
            if let photoAsset = currentCell?.photoAsset, photoAsset.mediaSubType.isHDRPhoto || photoAsset.mediaSubType.isLivePhoto {
                currentCell?.hideScrollContainerSubview()
            }
        }
        if isShowToolbar {
            UIView.animate(withDuration: 0.25) {
                self.photoToolbar.alpha = self.statusBarShouldBeHidden ? 0 : 1
            } completion: {
                if $0 {
                    self.photoToolbar.isHidden = self.statusBarShouldBeHidden
                }
            }
        }

        UIView.animate(withDuration: 0.25) {
            self.navBgView?.alpha = self.statusBarShouldBeHidden ? 0 : 1
            self.updateColors()
        } completion: {
            if $0 {
                self.navBgView?.isHidden = self.statusBarShouldBeHidden
            }
        }
        pickerController.pickerDelegate?.pickerController(
            pickerController,
            previewSingleClick: cell.photoAsset,
            atIndex: currentPreviewIndex
        )
    }
    func cell(longPress cell: PhotoPreviewViewCell) {
        pickerController.pickerDelegate?.pickerController(
            pickerController,
            previewLongPressClick: cell.photoAsset,
            atIndex: currentPreviewIndex
        )
    }
    
    func photoCell(networkImagedownloadSuccess photoCell: PhotoPreviewViewCell) {
        if let index = collectionView.indexPath(for: photoCell)?.item {
            pickerController.pickerDelegate?.pickerController(
                pickerController,
                previewNetworkImageDownloadSuccess: photoCell.photoAsset,
                atIndex: index
            )
        }
        delegate?.previewViewController(self, networkImagedownloadSuccess: photoCell.photoAsset)
        if config.isShowBottomView {
            photoToolbar.requestOriginalAssetBtyes()
        }
    }
    
    func photoCell(networkImagedownloadFailed photoCell: PhotoPreviewViewCell) {
        if let index = collectionView.indexPath(for: photoCell)?.item {
            pickerController.pickerDelegate?.pickerController(
                pickerController,
                previewNetworkImageDownloadFailed: photoCell.photoAsset,
                atIndex: index
            )
        }
    }
    
    func photoCell(_ photoCell: PhotoPreviewViewCell, HDRDidDisabled isDisabled: Bool) {
        if let index = collectionView.indexPath(for: photoCell)?.item, let photoAsset = photoCell.photoAsset {
            photoAsset.isDisableHDR = isDisabled
            photoCell.cancelRequest()
            photoCell.requestPreviewAsset()
            
            delegate?.previewViewController(self, updatePhotoAsset: photoAsset, at: index)
        }
    }
    
    func photoCell(_ photoCell: PhotoPreviewViewCell, livePhotoDidDisabled isDisabled: Bool) {
        if let index = collectionView.indexPath(for: photoCell)?.item, let photoAsset = photoCell.photoAsset {
            photoAsset.isDisableLivePhoto = isDisabled
            if photoAsset.isDisableLivePhoto {
                photoCell.scrollContentView.livePhotoView.stopPlayback()
            }else {
                photoCell.scrollContentView.livePhotoView.startPlayback(with: .full)
            }
            photoAsset.pFileSize = nil
            photoCell.scrollContentView.livePhotoView.playbackGestureRecognizer.isEnabled = !photoAsset.isDisableLivePhoto
            if isShowToolbar {
                requestSelectedAssetFileSize()
            }
            delegate?.previewViewController(self, updatePhotoAsset: photoAsset, at: index)
        }
    }
    
    func photoCell(_ photoCell: PhotoPreviewViewCell, livePhotoDidMuted isMuted: Bool) {
        if let index = collectionView.indexPath(for: photoCell)?.item, let photoAsset = photoCell.photoAsset {
            photoAsset.isLivePhotoMuted = isMuted
            photoCell.scrollContentView.livePhotoView.isMuted = photoAsset.isLivePhotoMuted
            
            delegate?.previewViewController(self, updatePhotoAsset: photoAsset, at: index)
        }
    }
    
}
