//
//  PhotoPreviewContentView.swift
//  HXPHPickerExample
//
//  Created by Slience on 2020/12/29.
//  Copyright © 2020 Silence. All rights reserved.
//

import UIKit
import PhotosUI

#if canImport(Kingfisher)
import Kingfisher
#endif

public protocol PhotoPreviewContentViewDelete: AnyObject {
    func contentView(networkImagedownloadSuccess contentView: PhotoPreviewContentView)
    func contentView(networkImagedownloadFailed contentView: PhotoPreviewContentView)
    func contentView(updateContentSize contentView: PhotoPreviewContentView)
}

open class PhotoPreviewContentView: UIView, PHLivePhotoViewDelegate {
    
    public enum `Type`: Int {
        case photo
        case livePhoto
        case video
    }
    public weak var delegate: PhotoPreviewContentViewDelete?
    
    lazy var imageView: ImageView = {
        let view = ImageView()
        return view
    }()
    @available(iOS 9.1, *)
    lazy var livePhotoView: PHLivePhotoView = {
        let livePhotoView = PHLivePhotoView.init()
        livePhotoView.delegate = self
        return livePhotoView
    }()
    lazy var videoView: PhotoPreviewVideoView = {
        let videoView = PhotoPreviewVideoView.init()
        videoView.alpha = 0
        return videoView
    }()
    
    var isBacking: Bool = false
    var isPeek = false
    
    var type: Type = .photo
    var requestID: PHImageRequestID?
    var requestCompletion: Bool = false
    var requestNetworkCompletion: Bool = false
    var networkVideoLoading: Bool = false
    var imageTask: Any?
    var videoPlayType: PhotoPreviewViewController.PlayType = .normal {
        didSet {
            if type == .video {
                videoView.videoPlayType = videoPlayType
            }
        }
    }
    var livePhotoPlayType: PhotoPreviewViewController.PlayType = .once
    var currentLoadAssetLocalIdentifier: String?
    var photoAsset: PhotoAsset! {
        didSet {
            requestFailed(info: [PHImageCancelledKey: 1], isICloud: false)
            setAnimatedImageCompletion = false
            switch photoAsset.mediaSubType {
            case .livePhoto:
                if #available(iOS 9.1, *) {
                    livePhotoView.livePhoto = nil
                }
            case .localImage:
                requestCompletion = true
            case .networkImage(_), .networkVideo:
                networkVideoLoading = false
                requestNetworkCompletion = false
                requestNetworkImage()
                return
            default:
                break
            }
            requestNetworkCompletion = true
            requestID = photoAsset.requestThumbnailImage(
                localType: .original,
                targetWidth: min(
                    UIScreen.main.bounds.width,
                    UIScreen.main.bounds.height
                ),
                completion: { [weak self] (image, asset, info) in
                guard let self = self else { return }
                if let info = info, info.isCancel { return }
                if let image = image,
                   asset == self.photoAsset {
                    self.imageView.image = image
                }
            })
        }
    }
    
    func requestNetworkImage() {
        requestCompletion = true
        #if canImport(Kingfisher)
        if photoAsset.mediaSubType != .networkVideo {
            if !ImageCache.default.isCached(forKey: photoAsset.networkImageAsset!.originalURL.cacheKey) {
                showLoadingView(text: "正在下载".localized)
            }
        }
        imageTask = imageView.setImage(
            for: photoAsset,
            urlType: .original
        ) { [weak self] (receivedData, totolData) in
            guard let self = self else { return }
            if self.photoAsset.mediaSubType != .networkVideo {
                let percentage = Double(receivedData) / Double(totolData)
                self.requestUpdateProgress(progress: percentage, isICloud: false)
            }
        } downloadTask: { [weak self] downloadTask in
            self?.imageTask = downloadTask
        } completionHandler: { [weak self] (image, error, photoAsset) in
            guard let self = self else { return }
            if self.photoAsset.mediaSubType != .networkVideo {
                self.requestNetworkCompletion = true
                if let image = image {
                    self.requestSucceed()
                    self.updateContentSize(image: image)
                    self.delegate?.contentView(networkImagedownloadSuccess: self)
                }else {
                    self.requestFailed(info: nil, isICloud: false)
                }
            }else {
                if let image = image {
                    self.updateContentSize(image: image)
                }
            }
        }
        #else
        imageTask = imageView.setVideoCoverImage(
            for: photoAsset
        ) { [weak self] imageGenerator in
            self?.imageTask = imageGenerator
        } completionHandler: { [weak self] (image, photoAsset) in
            guard let self = self else { return }
            if let image = image, self.photoAsset == photoAsset {
                self.imageView.image = image
                self.updateContentSize(image: image)
            }
        }
        #endif
    }
    func updateContentSize(image: UIImage) {
        let needUpdate = width / height != image.width / image.height
        if needUpdate {
            delegate?.contentView(updateContentSize: self)
        }
    }
    func checkNetworkVideoFileSize(_ url: URL) {
        if let fileSize = photoAsset.networkVideoAsset?.fileSize,
           fileSize == 0 {
            photoAsset.networkVideoAsset?.fileSize = url.fileSize
        }
    }
    func requestNetworkVideo() {
        if requestNetworkCompletion || networkVideoLoading {
            return
        }
        #if HXPICKER_ENABLE_EDITOR
        if let videoEdit = photoAsset.videoEdit {
            networkVideoRequestCompletion(videoEdit.editedURL)
            return
        }
        #endif
        if let videoURL = photoAsset.networkVideoAsset?.videoURL {
            videoView.isNetwork = false
            let key = videoURL.absoluteString
            if PhotoTools.isCached(forVideo: key) {
                let url = PhotoTools.getVideoCacheURL(for: key)
                checkNetworkVideoFileSize(url)
                networkVideoRequestCompletion(url)
                delegate?.contentView(updateContentSize: self)
                return
            }
            if PhotoManager.shared.loadNetworkVideoMode == .play {
                videoView.isNetwork = true
                networkVideoRequestCompletion(videoURL)
                return
            }
            if loadingView == nil {
                ProgressHUD.hide(forView: hudSuperview(), animated: false)
                showLoadingView(text: "正在下载".localized)
            }else {
                loadingView?.isHidden = false
            }
            networkVideoLoading = true
            PhotoManager.shared.downloadTask(
                with: videoURL
            ) { [weak self] (progress, task) in
                self?.requestUpdateProgress(progress: progress, isICloud: false)
            } completionHandler: { [weak self] (url, error, _) in
                guard let self = self else { return }
                self.networkVideoLoading = false
                if let url = url {
                    if let videoAsset = self.photoAsset.networkVideoAsset,
                       videoAsset.videoSize.equalTo(.zero) {
                        self.delegate?.contentView(updateContentSize: self)
                    }
                    self.checkNetworkVideoFileSize(url)
                    self.requestSucceed()
                    self.networkVideoRequestCompletion(url)
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
    
    func cancelRequestNetworkVideo() {
        if let videoURL = photoAsset.networkVideoAsset?.videoURL {
            PhotoManager.shared.suspendTask(videoURL)
            networkVideoLoading = false
        }
    }
    
    func networkVideoRequestCompletion(_ videoURL: URL) {
        if !isPeek {
            videoView.playerTime = photoAsset.playerTime
        }
        requestNetworkCompletion = true
        videoView.avAsset = AVAsset.init(url: videoURL)
        UIView.animate(withDuration: 0.25) {
            self.videoView.alpha = 1
        }
    }
    
    var loadingView: ProgressHUD?
    
    var setAnimatedImageCompletion: Bool = false
    
    init(type: Type) {
        super.init(frame: CGRect.zero)
        self.type = type
        addSubview(imageView)
        if type == .livePhoto {
            if #available(iOS 9.1, *) {
                addSubview(livePhotoView)
            }
        }else if type == .video {
            addSubview(videoView)
        }
    }
    
    func requestPreviewAsset() {
        switch photoAsset.mediaSubType {
        case .localImage, .networkImage(_):
            return
        case .networkVideo:
            requestNetworkVideo()
            return
        default:
            break
        }
        if requestCompletion {
            return
        }
        var canRequest = true
        if let localIdentifier = currentLoadAssetLocalIdentifier,
           localIdentifier == photoAsset.phAsset?.localIdentifier {
            canRequest = false
            UIApplication.shared.isNetworkActivityIndicatorVisible = true
            if loadingView == nil {
                loadingView = ProgressHUD.showLoading(
                    addedTo: hudSuperview(),
                    text: "正在同步iCloud".localized + "(" + String(Int(photoAsset.downloadProgress * 100)) + "%)",
                    animated: true)
            }
        }else {
            UIApplication.shared.isNetworkActivityIndicatorVisible = false
            if requestID != nil {
                PHImageManager.default().cancelImageRequest(requestID!)
                requestID = nil
            }
        }
        if type == .photo {
            #if canImport(Kingfisher)
            if photoAsset.mediaSubType.isGif && setAnimatedImageCompletion {
                startAnimatedImage()
            }else {
                if canRequest {
                    requestOriginalImage()
                }
            }
            #else
            let gifImageView = imageView.my
            if photoAsset.mediaSubType.isGif && gifImageView.gifImage != nil {
                gifImageView.startAnimating()
            }else {
                if canRequest {
                    requestOriginalImage()
                }
            }
            #endif
        }else if type == .livePhoto {
            if #available(iOS 9.1, *) {
                if canRequest {
                    requestLivePhoto()
                }
            }
        }else if type == .video {
            if !isPeek {
                videoView.playerTime = photoAsset.playerTime
            }
            if videoView.player.currentItem == nil && canRequest {
                requestAVAsset()
            }
        }
    }
    
    func requestOriginalImage() {
        #if HXPICKER_ENABLE_EDITOR
        if let photoEdit = photoAsset.photoEdit {
            if photoEdit.imageType == .gif {
                do {
                    let imageData = try Data.init(contentsOf: photoEdit.editedImageURL)
                    imageView.setImageData(imageData)
                }catch {
                    imageView.setImage(photoEdit.editedImage, animated: true)
                }
            }else {
                if let image = UIImage.init(contentsOfFile: photoEdit.editedImageURL.path) {
                    imageView.setImage(image)
                }else {
                    imageView.setImage(photoEdit.editedImage, animated: true)
                }
            }
            requestCompletion = true
            return
        }
        #endif
        requestID = photoAsset.requestImageData(iCloudHandler: { [weak self] asset, iCloudRequestID in
            guard let self = self else { return }
            if asset == self.photoAsset {
                self.requestShowDonwloadICloudHUD(iCloudRequestID: iCloudRequestID)
            }
        }, progressHandler: { [weak self] asset, progress in
            guard let self = self else { return }
            if asset == self.photoAsset {
                self.requestUpdateProgress(progress: progress, isICloud: true)
            }
        }, resultHandler: { [weak self] asset, result in
            guard let self = self else { return }
            switch result {
            case .success(let dataResult):
                if asset.mediaSubType.isGif {
                    if asset == self.photoAsset {
                        self.requestSucceed()
                        self.imageView.setImageData(dataResult.imageData)
                        self.setAnimatedImageCompletion = true
                        self.requestID = nil
                        self.requestCompletion = true
                    }
                }else {
                    DispatchQueue.global().async {
                        var image = UIImage.init(data: dataResult.imageData)
                        if dataResult.imageData.count > 3000000 {
                            image = image?.scaleSuitableSize()
                        }
                        DispatchQueue.main.async {
                            if asset == self.photoAsset {
                                self.requestSucceed()
                                self.imageView.setImage(image, animated: true)
                                self.requestID = nil
                                self.requestCompletion = true
                            }
                        }
                    }
                }
            case .failure(let error):
                if asset == self.photoAsset {
                    self.requestFailed(info: error.info, isICloud: true)
                }
            }
        })
    }
    @available(iOS 9.1, *)
    func requestLivePhoto() {
        #if HXPICKER_ENABLE_EDITOR
        if let photoEdit = photoAsset.photoEdit {
            imageView.setImage(photoEdit.editedImage, animated: true)
            requestCompletion = true
            return
        }
        #endif
        let targetSize: CGSize = size
        requestID = photoAsset.requestLivePhoto(
            targetSize: targetSize,
            iCloudHandler: { [weak self] (asset, requestID) in
            guard let self = self else { return }
            if asset == self.photoAsset {
                self.requestShowDonwloadICloudHUD(iCloudRequestID: requestID)
            }
        }, progressHandler: {  [weak self](asset, progress) in
            guard let self = self else { return }
            if asset == self.photoAsset {
                self.requestUpdateProgress(progress: progress, isICloud: true)
            }
        }, success: { [weak self] (asset, livePhoto, info) in
            guard let self = self else { return }
            if asset == self.photoAsset {
                self.requestSucceed()
                self.livePhotoView.livePhoto = livePhoto
                UIView.animate(withDuration: 0.25) {
                    self.livePhotoView.alpha = 1
                }
                if self.livePhotoPlayType == .auto ||
                    self.livePhotoPlayType == .once {
                    self.livePhotoView.startPlayback(with: PHLivePhotoViewPlaybackStyle.full)
                }
                self.requestID = nil
                self.requestCompletion = true
            }
        }, failure: { [weak self] (asset, info, error) in
            guard let self = self else { return }
            if asset == self.photoAsset {
                self.requestFailed(info: info, isICloud: true)
            }
        })
    }
    func requestAVAsset() {
        requestID = photoAsset.requestAVAsset(iCloudHandler: { [weak self] (asset, requestID) in
            guard let self = self else { return }
            if asset == self.photoAsset {
                self.requestShowDonwloadICloudHUD(iCloudRequestID: requestID)
            }
        }, progressHandler: { [weak self] (asset, progress) in
            guard let self = self else { return }
            if asset == self.photoAsset {
                self.requestUpdateProgress(progress: progress, isICloud: true)
            }
        }, success: { [weak self] (asset, avAsset, info) in
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
        }, failure: { [weak self] (asset, info, error) in
            guard let self = self else { return }
            if asset == self.photoAsset {
                self.requestFailed(info: info, isICloud: true)
            }
        })
    }
    func requestShowDonwloadICloudHUD(iCloudRequestID: PHImageRequestID) {
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        requestID = iCloudRequestID
        currentLoadAssetLocalIdentifier = photoAsset.phAsset?.localIdentifier
        showLoadingView(text: "正在同步iCloud".localized)
    }
    func requestUpdateProgress(progress: Double, isICloud: Bool) {
        let text = isICloud ? "正在同步iCloud".localized : "正在下载".localized
        loadingView?.updateText(text: text.localized + "(" + String(Int(progress * 100)) + "%)")
    }
    func hudSuperview() -> UIView? {
        if !isPeek {
            if let view = superview?.superview {
                return view
            }
        }
        return self
    }
    func showLoadingView(text: String) {
        loadingView = ProgressHUD.showLoading(addedTo: hudSuperview(), text: text.localized, animated: true)
    }
    func resetLoadingState() {
        UIApplication.shared.isNetworkActivityIndicatorVisible = false
        currentLoadAssetLocalIdentifier = nil
        loadingView = nil
    }
    func requestSucceed() {
        resetLoadingState()
        ProgressHUD.hide(forView: hudSuperview(), animated: true)
    }
    func requestFailed(info: [AnyHashable: Any]?, isICloud: Bool) {
        loadingView?.removeFromSuperview()
        resetLoadingState()
        if let info = info, !info.isCancel {
            let text = (info.inICloud && isICloud) ? "iCloud同步失败".localized : "下载失败".localized
            ProgressHUD.hide(forView: hudSuperview(), animated: false)
            ProgressHUD.showWarning(addedTo: hudSuperview(), text: text.localized, animated: true, delayHide: 2)
        }
    }
    func cancelImageTask() {
        #if canImport(Kingfisher)
        if let donwloadTask = imageTask as? Kingfisher.DownloadTask {
            donwloadTask.cancel()
        }else if let avAsset = imageTask as? AVAsset {
            avAsset.cancelLoading()
        }else if let imageGenerator = imageTask as? AVAssetImageGenerator {
            imageGenerator.cancelAllCGImageGeneration()
        }
        #else
        if let avAsset = imageTask as? AVAsset {
            avAsset.cancelLoading()
        }else if let imageGenerator = imageTask as? AVAssetImageGenerator {
            imageGenerator.cancelAllCGImageGeneration()
        }
        #endif
    }
    func cancelRequest() {
        guard let photoAsset = photoAsset else { return }
        cancelImageTask()
        if !isPeek {
            photoAsset.playerTime = 0
        }
        switch photoAsset.mediaSubType {
        case .localImage, .networkImage(_):
            requestCompletion = false
            requestNetworkCompletion = false
            return
        case .networkVideo:
            cancelRequestNetworkVideo()
            requestCompletion = false
            requestNetworkCompletion = false
            videoView.cancelPlayer()
            videoView.alpha = 0
            return
        default:
            break
        }
        currentLoadAssetLocalIdentifier = nil
        if requestID != nil {
            PHImageManager.default().cancelImageRequest(requestID!)
            requestID = nil
        }
        stopAnimatedImage()
        ProgressHUD.hide(forView: hudSuperview(), animated: false)
        if type == .livePhoto {
            if #available(iOS 9.1, *) {
                livePhotoView.stopPlayback()
                livePhotoView.alpha = 0
            }
        }else if type == .video {
            videoView.cancelPlayer()
            videoView.alpha = 0
        }
        requestCompletion = false
    }
    func stopVideo() {
        if photoAsset.mediaType == .video {
            if photoAsset.isNetworkAsset && !requestNetworkCompletion {
                cancelRequest()
                requestFailed(info: [PHImageCancelledKey: 1], isICloud: false)
            }else {
                videoView.stopPlay()
            }
        }
    }
    func showOtherSubview() {
        if photoAsset.mediaType == .video {
            if photoAsset.isNetworkAsset {
                if requestNetworkCompletion {
                    videoView.showPlayButton()
                }else {
                    videoView.showMaskView()
                }
            }else {
                videoView.showPlayButton()
            }
        }
        if !requestNetworkCompletion {
            loadingView?.isHidden = false
        }
    }
    func hiddenOtherSubview() {
        if photoAsset.mediaType == .video {
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
        if requestNetworkCompletion {
            loadingView = nil
            ProgressHUD.hide(forView: hudSuperview(), animated: false)
        }else {
            loadingView?.isHidden = true
        }
    }
    func startAnimatedImage() {
        if photoAsset.mediaSubType.isGif {
            imageView.startAnimatedImage()
        }
    }
    func stopAnimatedImage() {
        if photoAsset.mediaSubType.isGif {
            imageView.stopAnimatedImage()
        }
    }
    public func livePhotoView(
        _ livePhotoView: PHLivePhotoView,
        didEndPlaybackWith playbackStyle: PHLivePhotoViewPlaybackStyle
    ) {
        if livePhotoPlayType == .auto {
            livePhotoView.startPlayback(with: .full)
        }
    }
    
    open override func layoutSubviews() {
        super.layoutSubviews()
        imageView.frame = bounds
        if type == .livePhoto {
            if #available(iOS 9.1, *) {
                livePhotoView.frame = bounds
            }
        }else if type == .video {
            videoView.frame = bounds
        }
    }
    deinit {
        cancelRequest()
        
//        if photoAsset.isNetworkAsset && photoAsset.mediaType == .video {
//            print("deinit \(self)")
//        }
    }
    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
