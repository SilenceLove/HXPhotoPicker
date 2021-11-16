//
//  VideoEditorViewController+Request.swift
//  HXPHPicker
//
//  Created by Slience on 2021/8/6.
//

import UIKit
import AVKit
import Photos

// MARK: PhotoAsset Request AVAsset
extension VideoEditorViewController {
    #if HXPICKER_ENABLE_PICKER
    func requestAVAsset() {
        if photoAsset.isNetworkAsset {
            pNetworkVideoURL = photoAsset.networkVideoAsset?.videoURL
            downloadNetworkVideo()
            return
        }
        let loadingView = ProgressHUD.showLoading(addedTo: view, text: nil, animated: true)
        view.bringSubviewToFront(topView)
        assetRequestID = photoAsset.requestAVAsset(
            filterEditor: true,
            deliveryMode: .highQualityFormat
        ) { [weak self] (photoAsset, requestID) in
            self?.assetRequestID = requestID
            loadingView?.mode = .circleProgress
            loadingView?.text = "正在同步iCloud".localized + "..."
        } progressHandler: { (photoAsset, progress) in
            if progress > 0 {
                loadingView?.progress = CGFloat(progress)
            }
        } success: { [weak self] (photoAsset, avAsset, info) in
            ProgressHUD.hide(forView: self?.view, animated: false)
            self?.pAVAsset = avAsset
            self?.avassetLoadValuesAsynchronously()
//            self?.reqeustAssetCompletion = true
//            self?.assetRequestComplete()
        } failure: { [weak self] (photoAsset, info, error) in
            if let info = info, !info.isCancel {
                ProgressHUD.hide(forView: self?.view, animated: false)
                if info.inICloud {
                    self?.assetRequestFailure(message: "iCloud同步失败".localized)
                }else {
                    self?.assetRequestFailure()
                }
            }
        }
    }
    #endif
    
    func assetRequestFailure(message: String = "视频获取失败!".localized) {
        PhotoTools.showConfirm(
            viewController: self,
            title: "提示".localized,
            message: message,
            actionTitle: "确定".localized
        ) { (alertAction) in
            self.backAction()
        }
    }
    
    func assetRequestComplete() {
        let image = PhotoTools.getVideoThumbnailImage(avAsset: avAsset, atTime: 0.1)
        videoSize = image?.size ?? view.size
        videoView.setAVAsset(avAsset, coverImage: image ?? .init())
        cropView.avAsset = avAsset
        if orientationDidChange {
            setCropViewFrame()
        }
        if !videoInitializeCompletion {
            setEditedSizeData()
            videoInitializeCompletion = true
        }
        if transitionCompletion {
            setAsset()
        }
    }
    
    func setEditedSizeData() {
        if let sizeData = editResult?.sizeData {
            videoView.setVideoEditedData(editedData: sizeData)
            brushColorView.canUndo = videoView.canUndoDraw
            if let stickerData = sizeData.stickerData {
                musicView.showLyricButton.isSelected = stickerData.showLyric
                if stickerData.showLyric {
                    otherMusic = stickerData.items[stickerData.LyricIndex].item.music
                }
            }
        }
    }
    
    func setAsset() {
        if setAssetCompletion {
            return
        }
        videoView.playerView.configAsset()
        if let editResult = editResult {
            videoView.playerView.player.volume = editResult.videoSoundVolume
            musicView.originalSoundButton.isSelected = editResult.videoSoundVolume > 0
            if let audioURL = editResult.backgroundMusicURL {
                backgroundMusicPath = audioURL.path
                musicView.backgroundButton.isSelected = true
                PhotoManager.shared.playMusic(filePath: audioURL.path) {
                }
                videoView.imageResizerView.imageView.stickerView.audioView?.contentView.startTimer()
                backgroundMusicVolume = editResult.backgroundMusicVolume
            }
        }
        if !orientationDidChange {
            videoView.playerView.resetPlay()
            startPlayTimer()
        }
        setAssetCompletion = true
    }
}

// MARK: DownloadNetworkVideo
extension VideoEditorViewController {
    func downloadNetworkVideo() {
        if let videoURL = networkVideoURL {
            let key = videoURL.absoluteString
            if PhotoTools.isCached(forVideo: key) {
                let localURL = PhotoTools.getVideoCacheURL(for: key)
                pAVAsset = AVAsset.init(url: localURL)
                avassetLoadValuesAsynchronously()
                return
            }
            loadingView = ProgressHUD.showLoading(addedTo: view, text: "视频下载中".localized, animated: true)
            view.bringSubviewToFront(topView)
            PhotoManager.shared.downloadTask(
                with: videoURL
            ) { [weak self] (progress, task) in
                if progress > 0 {
                    self?.loadingView?.mode = .circleProgress
                    self?.loadingView?.progress = CGFloat(progress)
                }
            } completionHandler: { [weak self] (url, error, _) in
                if let url = url {
                    #if HXPICKER_ENABLE_PICKER
                    if let photoAsset = self?.photoAsset {
                        photoAsset.networkVideoAsset?.fileSize = url.fileSize
                    }
                    #endif
                    self?.loadingView = nil
                    ProgressHUD.hide(forView: self?.view, animated: false)
                    self?.pAVAsset = AVAsset(url: url)
                    self?.avassetLoadValuesAsynchronously()
                }else {
                    if let error = error as NSError?, error.code == NSURLErrorCancelled {
                        return
                    }
                    self?.loadingView = nil
                    ProgressHUD.hide(forView: self?.view, animated: false)
                    self?.assetRequestFailure()
                }
            }
        }
    }
    
    func avassetLoadValuesAsynchronously() {
        avAsset.loadValuesAsynchronously(
            forKeys: ["duration"]
        ) { [weak self] in
            guard let self = self else { return }
            DispatchQueue.main.async {
                if self.avAsset.statusOfValue(forKey: "duration", error: nil) != .loaded {
                    self.assetRequestFailure()
                    return
                }
                self.reqeustAssetCompletion = true
                self.assetRequestComplete()
            }
        }
    }
}
