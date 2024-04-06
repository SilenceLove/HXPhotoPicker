//
//  PhotoPreviewContentLivePhotoView.swift
//  HXPhotoPicker
//
//  Created by Silence on 2023/10/24.
//  Copyright © 2023 Silence. All rights reserved.
//

import UIKit
import PhotosUI

class PhotoPreviewContentLivePhotoView: PhotoPreviewContentPhotoView {
    private var localLivePhotoRequest: PhotoAsset.LocalLivePhotoRequest?
    
    override func initViews() {
        super.initViews()
        livePhotoView = PHLivePhotoView()
        livePhotoView.delegate = self
        addSubview(livePhotoView)
    }
    
    override func updateContent() {
        if photoAsset.mediaSubType.isLivePhoto {
            livePhotoView.livePhoto = nil
            if let localLivePhoto = photoAsset.localLivePhoto,
               !localLivePhoto.imageURL.isFileURL {
                requestNetworkCompletion = false
                requestNetworkImage()
            }
        }
        super.updateContent()
    }
    
    override func requestPreviewContent(_ canRequest: Bool) {
        if photoAsset.mediaSubType == .localLivePhoto {
            requestLocalLivePhoto()
            return
        }
        if canRequest {
            requestLivePhoto()
        }
    }
    
    override func stopLivePhoto() {
        livePhotoView.stopPlayback()
    }
    
    override func showOtherSubview() {
        super.showOtherSubview()
        delegate?.contentView(livePhotoDidEndPlayback: self)
    }
    override func hiddenOtherSubview() {
        super.hiddenOtherSubview()
        delegate?.contentView(livePhotoWillBeginPlayback: self)
    }
    
    override func cancelRequest() {
        super.cancelRequest()
        if let localLivePhotoRequest = localLivePhotoRequest {
            localLivePhotoRequest.cancelRequest()
            self.localLivePhotoRequest = nil
        }
        livePhotoView.stopPlayback()
        livePhotoView.alpha = 0
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        livePhotoView.frame = bounds
    }
}

extension PhotoPreviewContentLivePhotoView {
    
    func requestLivePhoto() {
        #if HXPICKER_ENABLE_EDITOR
        if let photoEdit = photoAsset.photoEditedResult {
            if let image = UIImage(contentsOfFile: photoEdit.url.path) {
                imageView.setImage(image, animated: true)
            }else {
                imageView.setImage(photoEdit.image, animated: true)
            }
            requestCompletion = true
            return
        }
        #endif
        let targetSize: CGSize = size
        requestID = photoAsset.requestLivePhoto(
            targetSize: targetSize,
            iCloudHandler: { [weak self] (asset, requestID) in
            guard let self = self else { return }
            if asset == self.photoAsset && asset.downloadStatus != .succeed {
                self.showDonwloadICloudLoading(requestID)
            }
        }, progressHandler: {  [weak self](asset, progress) in
            guard let self = self else { return }
            if asset == self.photoAsset && asset.downloadStatus != .succeed {
                self.updateProgress(progress: progress, isICloud: true)
            }
        }, success: { [weak self] (asset, livePhoto, _) in
            guard let self = self else { return }
            if asset == self.photoAsset {
                self.requestSucceed()
                self.livePhotoView.livePhoto = livePhoto
                UIView.animate(withDuration: 0.25) {
                    self.livePhotoView.alpha = 1
                }
                if self.livePhotoPlayType == .auto ||
                    self.livePhotoPlayType == .once {
                    self.livePhotoView.startPlayback(with: .full)
                }
                self.requestID = nil
                self.requestCompletion = true
            }
        }, failure: { [weak self] (asset, info, _) in
            guard let self = self else { return }
            if asset == self.photoAsset {
                self.requestFailed(info: info, isICloud: true)
            }
        })
    }
    
    func requestLocalLivePhoto() {
        #if HXPICKER_ENABLE_EDITOR
        if let photoEdit = photoAsset.photoEditedResult {
            if let image = UIImage(contentsOfFile: photoEdit.url.path) {
                imageView.setImage(image, animated: true)
            }else {
                imageView.setImage(photoEdit.image, animated: true)
            }
            requestCompletion = true
            return
        }
        #endif
        if let livePhoto = photoAsset.localLivePhoto, !livePhoto.isCache {
            if loadingView?.superview == nil {
                loadingView?.removeFromSuperview()
                loadingView = PhotoManager.HUDView.show(with: nil, delay: 0, animated: true, addedTo: hudSuperview)
            }
        }
        localLivePhotoRequest = photoAsset.requestLocalLivePhoto(success: { [weak self] photoAsset, livePhoto in
            guard let self = self else { return }
            if photoAsset == self.photoAsset {
                self.requestSucceed()
                self.livePhotoView.livePhoto = livePhoto
                UIView.animate(withDuration: 0.25) {
                    self.livePhotoView.alpha = 1
                }
                if self.livePhotoPlayType == .auto ||
                    self.livePhotoPlayType == .once {
                    self.livePhotoView.startPlayback(with: .full)
                }
                self.localLivePhotoRequest = nil
                self.requestCompletion = true
            }
        }, failure: { [weak self] (asset, info, _) in
            guard let self = self else { return }
            if asset == self.photoAsset {
                self.localLivePhotoRequest = nil
                let _info: [AnyHashable: Any]
                if let info = info {
                    _info = info
                }else {
                    _info = [PHImageCancelledKey: 0]
                }
                self.requestFailed(
                    info: _info,
                    isICloud: false,
                    showWarning: false
                )
            }
        })
    }
}

extension PhotoPreviewContentLivePhotoView: PHLivePhotoViewDelegate {
    func livePhotoView(
        _ livePhotoView: PHLivePhotoView,
        willBeginPlaybackWith playbackStyle: PHLivePhotoViewPlaybackStyle
    ) {
        isLivePhotoAnimating = true
        delegate?.contentView(livePhotoWillBeginPlayback: self)
    }
    func livePhotoView(
        _ livePhotoView: PHLivePhotoView,
        didEndPlaybackWith playbackStyle: PHLivePhotoViewPlaybackStyle
    ) {
        isLivePhotoAnimating = false
        delegate?.contentView(livePhotoDidEndPlayback: self)
        if livePhotoPlayType == .auto && livePhotoView.alpha != 0 {
            livePhotoView.startPlayback(with: .full)
        }
    }
}
