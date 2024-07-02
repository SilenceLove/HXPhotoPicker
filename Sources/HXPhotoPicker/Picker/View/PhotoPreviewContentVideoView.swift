//
//  PhotoPreviewContentVideoView.swift
//  HXPhotoPicker
//
//  Created by Silence on 2023/10/24.
//  Copyright © 2023 Silence. All rights reserved.
//

import UIKit
import Photos

class PhotoPreviewContentVideoView: PhotoPreviewContentPhotoView {
    
    override var videoPlayType: PhotoPreviewViewController.PlayType {
        didSet {
            videoView.videoPlayType = videoPlayType
        }
    }
    
    private var isNetworkVideoLoading: Bool = false
    
    override func initViews() {
        super.initViews()
        videoView = PhotoPreviewVideoView()
        videoView.alpha = 0
        addSubview(videoView)
    }
    
    override func requestNetwork() {
        if photoAsset.isNetworkAsset {
            isNetworkVideoLoading = false
        }
        super.requestNetwork()
    }
    
    override func requestPreviewAsset() {
        switch photoAsset.mediaSubType {
        case .networkVideo:
            requestNetworkVideo()
            return
        default:
            break
        }
        super.requestPreviewAsset()
    }
    
    override func requestPreviewContent(_ canRequest: Bool) {
        if !isPeek {
            videoView.playerTime = photoAsset.playerTime
        }
        if videoView.player.currentItem == nil && canRequest {
            requestAVAsset()
        }
    }
    
    override func stopVideo() {
        if photoAsset.isNetworkAsset && !requestNetworkCompletion {
            cancelRequest()
            requestFailed(info: [PHImageCancelledKey: 1], isICloud: false)
        }else {
            videoView.stopPlay()
        }
    }
    
    override func showOtherSubview() {
        super.showOtherSubview()
        if photoAsset.isNetworkAsset {
            if requestNetworkCompletion {
                videoView.showPlayButton()
            }else {
                videoView.showMaskView()
            }
        }else {
            if requestCompletion {
                videoView.showPlayButton()
            }
        }
    }
    
    override func hiddenOtherSubview() {
        super.hiddenOtherSubview()
        if photoAsset.isNetworkAsset {
            if requestNetworkCompletion {
                videoView.hiddenPlayButton()
            }else {
                videoView.hiddenMaskView()
            }
        }else {
            videoView.hiddenPlayButton()
        }
    }
    
    override func cancelRequest() {
        guard let photoAsset = photoAsset else { return }
        super.cancelRequest()
        videoView.cancelPlayer()
        videoView.alpha = 0
        switch photoAsset.mediaSubType {
        case .networkVideo:
            cancelRequestNetworkVideo()
        default:
            break
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        videoView.frame = bounds
    }
}

extension PhotoPreviewContentVideoView {
    
    func requestAVAsset() {
        requestID = photoAsset.requestAVAsset(iCloudHandler: { [weak self] (asset, requestID) in
            guard let self = self else { return }
            if asset == self.photoAsset && asset.downloadStatus != .succeed {
                self.showDonwloadICloudLoading(requestID)
            }
        }, progressHandler: { [weak self] (asset, progress) in
            guard let self = self else { return }
            if asset == self.photoAsset && asset.downloadStatus != .succeed {
                self.updateProgress(progress: progress, isICloud: true)
            }
        }, success: { [weak self] (asset, avAsset, _) in
            guard let self = self else { return }
            if asset == self.photoAsset {
                self.requestSucceed()
                if self.isBacking {
                    return
                }
                self.videoView.avAsset = avAsset
                UIView.animate(withDuration: 0.25) {
                    self.videoView.alpha = 1
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
    
    func requestNetworkVideo() {
        if requestNetworkCompletion || isNetworkVideoLoading {
            return
        }
        #if HXPICKER_ENABLE_EDITOR
        if let videoEdit = photoAsset.videoEditedResult {
            networkVideoRequestCompletion(videoEdit.url, options: photoAsset.networkVideoAsset?.options)
            return
        }
        #endif
        if let videoURL = photoAsset.networkVideoAsset?.videoURL {
            videoView.isNetwork = false
            let key = videoURL.absoluteString
            if PhotoTools.isCached(forVideo: key) {
                let url = PhotoTools.getVideoCacheURL(for: key)
                checkNetworkVideoFileSize(url)
                networkVideoRequestCompletion(url, options: photoAsset.networkVideoAsset?.options)
                return
            }
            
            if PhotoManager.shared.loadNetworkVideoMode == .play ||
                videoURL.path.hasSuffix("m3u8")
                || videoURL.path.hasSuffix("M3U8") {
                videoView.isNetwork = true
                networkVideoRequestCompletion(videoURL, options: photoAsset.networkVideoAsset?.options)
                return
            }
            if loadingView == nil {
                PhotoManager.HUDView.dismiss(delay: 0, animated: false, for: hudSuperview)
                showLoadingView(text: nil)
            }else {
                loadingView?.isHidden = false
            }
            isNetworkVideoLoading = true
            PhotoManager.shared.downloadTask(
                with: videoURL
            ) { [weak self] (progress, _) in
                self?.updateProgress(progress: progress, isICloud: false)
            } completionHandler: { [weak self] (url, error, _) in
                guard let self = self else { return }
                self.isNetworkVideoLoading = false
                if let url = url {
                    if let videoAsset = self.photoAsset.networkVideoAsset,
                       videoAsset.videoSize.equalTo(.zero),
                       let image = PhotoTools.getVideoThumbnailImage(videoURL: url, atTime: 0.1) {
                        self.photoAsset.networkVideoAsset?.videoSize = image.size
                        self.delegate?.contentView(updateContentSize: self)
                    }
                    self.checkNetworkVideoFileSize(url)
                    self.requestSucceed()
                    self.networkVideoRequestCompletion(url, options: self.photoAsset.networkVideoAsset?.options)
                }else {
                    if let error = error as NSError?, error.code == NSURLErrorCancelled {
                        self.requestFailed(info: [PHImageCancelledKey: 1], isICloud: false)
                    }else {
                        self.requestFailed(info: nil, isICloud: false)
                    }
                }
            }
        }
    }
    
    func checkNetworkVideoFileSize(_ url: URL) {
        if let fileSize = photoAsset.networkVideoAsset?.fileSize,
           fileSize == 0 {
            photoAsset.networkVideoAsset?.fileSize = url.fileSize
        }
    }
    
    func cancelRequestNetworkVideo() {
        if let videoURL = photoAsset.networkVideoAsset?.videoURL {
            PhotoManager.shared.suspendTask(videoURL)
            isNetworkVideoLoading = false
        }
    }
    
    func networkVideoRequestCompletion(_ videoURL: URL, options: [String: Any]?) {
        if !isPeek {
            videoView.playerTime = photoAsset.playerTime
        }
        requestNetworkCompletion = true
        videoView.avAsset = AVURLAsset(url: videoURL, options: options)
        UIView.animate(withDuration: 0.25) {
            self.videoView.alpha = 1
        }
    }
}
