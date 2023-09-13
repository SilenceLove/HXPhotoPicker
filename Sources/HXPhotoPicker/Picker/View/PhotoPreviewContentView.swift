//
//  PhotoPreviewContentView.swift
//  HXPhotoPicker
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
    func contentView(requestSucceed contentView: PhotoPreviewContentView)
    func contentView(requestFailed contentView: PhotoPreviewContentView)
    func contentView(networkImagedownloadSuccess contentView: PhotoPreviewContentView)
    func contentView(networkImagedownloadFailed contentView: PhotoPreviewContentView)
    func contentView(updateContentSize contentView: PhotoPreviewContentView)
    func contentView(livePhotoWillBeginPlayback contentView: PhotoPreviewContentView)
    func contentView(livePhotoDidEndPlayback contentView: PhotoPreviewContentView)
}

public extension PhotoPreviewContentViewDelete {
    func contentView(requestSucceed contentView: PhotoPreviewContentView) { }
    func contentView(requestFailed contentView: PhotoPreviewContentView) { }
    func contentView(networkImagedownloadSuccess contentView: PhotoPreviewContentView) { }
    func contentView(networkImagedownloadFailed contentView: PhotoPreviewContentView) { }
    func contentView(updateContentSize contentView: PhotoPreviewContentView) { }
    func contentView(livePhotoWillBeginPlayback contentView: PhotoPreviewContentView) { }
    func contentView(livePhotoDidEndPlayback contentView: PhotoPreviewContentView) { }
}

open class PhotoPreviewContentView: UIView {
    
    public enum `Type`: Int {
        case photo
        case livePhoto
        case video
    }
    public weak var delegate: PhotoPreviewContentViewDelete?
    
    var videoView: PhotoPreviewVideoView!
    var imageView: ImageView!
    var livePhotoView: PHLivePhotoView!
    var requestCompletion: Bool = false
    
    private var type: `Type` = .photo
    private var requestID: PHImageRequestID?
    private var requestNetworkCompletion: Bool = false
    private var networkVideoLoading: Bool = false
    private var localLivePhotoRequest: PhotoAsset.LocalLivePhotoRequest?
    private var imageTask: Any?
    private var currentLoadAssetLocalIdentifier: String?
    
    private var loadingView: ProgressHUD?
    private var setAnimatedImageCompletion: Bool = false
    
    var livePhotoPlayType: PhotoPreviewViewController.PlayType = .once
    var livePhotoIsAnimating: Bool = false
    var isBacking: Bool = false
    var isPeek = false
    var videoPlayType: PhotoPreviewViewController.PlayType = .normal {
        didSet {
            if type == .video {
                videoView.videoPlayType = videoPlayType
            }
        }
    }
    
    public var photoAsset: PhotoAsset! {
        didSet {
            #if canImport(Kingfisher)
            photoAsset.loadNetworkImageHandler = nil
            #endif
            requestFailed(info: [PHImageCancelledKey: 1], isICloud: false)
            setAnimatedImageCompletion = false
            switch photoAsset.mediaSubType {
            case .livePhoto, .localLivePhoto:
                if #available(iOS 9.1, *) {
                    livePhotoView.livePhoto = nil
                }
                if let localLivePhoto = photoAsset.localLivePhoto,
                   !localLivePhoto.imageURL.isFileURL {
                    requestNetworkCompletion = false
                    requestNetworkImage()
                }
            case .localImage:
                requestCompletion = true
            case .networkImage, .networkVideo:
                networkVideoLoading = false
                requestNetworkCompletion = false
                requestNetworkImage()
                #if canImport(Kingfisher)
                photoAsset.loadNetworkImageHandler = { [weak self] in
                    self?.requestNetworkImage(loadOriginal: true, $0)
                }
                #endif
                return
            default:
                break
            }
            requestNetworkCompletion = true
            requestID = photoAsset.requestThumbnailImage(
                localType: .original,
                targetWidth: min(
                    UIDevice.screenSize.width,
                    UIDevice.screenSize.height
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
    
    init(type: `Type`) {
        super.init(frame: CGRect.zero)
        self.type = type
        imageView = ImageView()
        imageView.size = size
        imageView.imageView.size = size
        addSubview(imageView)
        if type == .livePhoto {
            if #available(iOS 9.1, *) {
                livePhotoView = PHLivePhotoView()
                livePhotoView.delegate = self
                addSubview(livePhotoView)
            }
        }else if type == .video {
            videoView = PhotoPreviewVideoView()
            videoView.alpha = 0
            addSubview(videoView)
        }
    }
    
    func updateContentSize(image: UIImage) {
        updateContentSize(image.size)
    }
    
    func updateContentSize(_ size: CGSize) {
        if height == 0 || width == 0 {
            delegate?.contentView(updateContentSize: self)
            return
        }
        let needUpdate = (width / height) != (size.width / size.height)
        if needUpdate {
            delegate?.contentView(updateContentSize: self)
        }
    }
    
    func hudSuperview() -> UIView? {
        if !isPeek {
            if let view = superview?.superview {
                return view
            }
        }
        return self
    }
    func showLoadingView(text: String?) {
        loadingView = ProgressHUD.showProgress(
            addedTo: hudSuperview(),
            text: text?.localized,
            animated: true
        )
    }
    
    func stopLivePhoto() {
        if photoAsset.mediaSubType == .livePhoto ||
           photoAsset.mediaSubType == .localLivePhoto {
            livePhotoView.stopPlayback()
        }
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
        if photoAsset.mediaSubType == .livePhoto ||
            photoAsset.mediaSubType == .localLivePhoto {
            delegate?.contentView(livePhotoDidEndPlayback: self)
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
        if photoAsset.mediaSubType == .livePhoto ||
            photoAsset.mediaSubType == .localLivePhoto {
            delegate?.contentView(livePhotoWillBeginPlayback: self)
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
    }
    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}

// MARK: Request Network
extension PhotoPreviewContentView {
    
    func requestNetworkImage(loadOriginal: Bool = false, _ completion: ((PhotoAsset) -> Void)? = nil) {
        requestCompletion = true
        var isLoaclLivePhoto = false
        #if canImport(Kingfisher)
        if photoAsset.mediaSubType != .networkVideo {
            var key: String = ""
            if let networkImage = photoAsset.networkImageAsset {
                if networkImage.originalLoadMode == .alwaysThumbnail,
                   !loadOriginal {
                    key = networkImage.thumbnailURL.cacheKey
                }else {
                    key = networkImage.originalURL.cacheKey
                }
            }else if let livePhoto = photoAsset.localLivePhoto,
                         !livePhoto.imageURL.isFileURL {
                key = livePhoto.imageURL.cacheKey
                requestCompletion = false
                isLoaclLivePhoto = true
            }
            if !ImageCache.default.isCached(forKey: key) {
                showLoadingView(text: nil)
            }
        }
        imageTask = imageView.setImage(
            for: photoAsset,
            urlType: .original,
            forciblyOriginal: loadOriginal
        ) { [weak self] (receivedData, totolData) in
            guard let self = self else { return }
            if self.photoAsset.mediaSubType != .networkVideo {
                let percentage = Double(receivedData) / Double(totolData)
                self.requestUpdateProgress(progress: percentage, isICloud: false)
            }
        } downloadTask: { [weak self] downloadTask in
            self?.imageTask = downloadTask
        } completionHandler: { [weak self] (image, _, photoAsset) in
            guard let self = self else { return }
            completion?(photoAsset)
            if isLoaclLivePhoto {
                if let image = image {
                    self.updateContentSize(image: image)
                }
                return
            }
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
    func requestNetworkVideo() {
        if requestNetworkCompletion || networkVideoLoading {
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
                ProgressHUD.hide(forView: hudSuperview(), animated: false)
                showLoadingView(text: nil)
            }else {
                loadingView?.isHidden = false
            }
            networkVideoLoading = true
            PhotoManager.shared.downloadTask(
                with: videoURL
            ) { [weak self] (progress, _) in
                self?.requestUpdateProgress(progress: progress, isICloud: false)
            } completionHandler: { [weak self] (url, error, _) in
                guard let self = self else { return }
                self.networkVideoLoading = false
                if let url = url {
                    if let videoAsset = self.photoAsset.networkVideoAsset,
                       videoAsset.videoSize.equalTo(.zero) {
                        let image = PhotoTools.getVideoThumbnailImage(videoURL: url, atTime: 0.1)
                        self.photoAsset.networkVideoAsset?.videoSize = image?.size ?? .zero
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
            networkVideoLoading = false
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

// MARK: Request Asset
extension PhotoPreviewContentView {
    
    func requestPreviewAsset() {
        switch photoAsset.mediaSubType {
        case .localImage, .networkImage:
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
            if photoAsset.mediaSubType == .localLivePhoto {
                requestLocalLivePhoto()
                return
            }
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
        if let photoEdit = photoAsset.photoEditedResult {
            if photoEdit.imageType == .gif {
                do {
                    let imageData = try Data(contentsOf: photoEdit.url)
                    imageView.setImageData(imageData)
                }catch {
                    imageView.setImage(photoEdit.image, animated: true)
                }
            }else {
                if let image = UIImage(contentsOfFile: photoEdit.url.path) {
                    imageView.setImage(image, animated: true)
                }else {
                    imageView.setImage(photoEdit.image, animated: true)
                }
            }
            requestCompletion = true
            return
        }
        #endif
        requestID = photoAsset.requestImageData(iCloudHandler: { [weak self] photoAsset, iCloudRequestID in
            guard let self = self,
                  photoAsset == self.photoAsset,
                  photoAsset.downloadStatus != .succeed else {
                return
            }
            self.requestShowDonwloadICloudHUD(iCloudRequestID: iCloudRequestID)
        }, progressHandler: { [weak self] photoAsset, progress in
            guard let self = self,
                  photoAsset == self.photoAsset,
                  photoAsset.downloadStatus != .succeed else {
                return
            }
            self.requestUpdateProgress(progress: progress, isICloud: true)
        }, resultHandler: { [weak self] asset, result in
            guard let self = self,
                  self.photoAsset == asset else { return }
            switch result {
            case .success(let dataResult):
                if asset.mediaSubType.isGif {
                    self.requestSucceed()
                    self.imageView.setImageData(dataResult.imageData)
                    self.setAnimatedImageCompletion = true
                    self.requestID = nil
                    self.requestCompletion = true
                }else {
                    DispatchQueue.global().async {
                        var image: UIImage?
                        let dataCount = CGFloat(dataResult.imageData.count)
                        if dataCount > 3000000 {
                            if let imageData = PhotoTools.imageCompress(
                                dataResult.imageData,
                                compressionQuality: dataCount.compressionQuality,
                                isHEIC: asset.photoFormat == "heic"
                            ) {
                                image = .init(data: imageData)
                            }
                        }
                        if image == nil {
                            image = UIImage(data: dataResult.imageData)
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
                self.requestFailed(info: error.info, isICloud: true)
            }
        })
    }
    @available(iOS 9.1, *)
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
                self.requestShowDonwloadICloudHUD(iCloudRequestID: requestID)
            }
        }, progressHandler: {  [weak self](asset, progress) in
            guard let self = self else { return }
            if asset == self.photoAsset && asset.downloadStatus != .succeed {
                self.requestUpdateProgress(progress: progress, isICloud: true)
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
            loadingView = ProgressHUD.showLoading(addedTo: hudSuperview(), animated: true)
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
                self.requestFailed(
                    info: info ?? [PHImageCancelledKey: 0],
                    isICloud: false,
                    showWarning: false
                )
            }
        })
    }
    func requestAVAsset() {
        requestID = photoAsset.requestAVAsset(iCloudHandler: { [weak self] (asset, requestID) in
            guard let self = self else { return }
            if asset == self.photoAsset && asset.downloadStatus != .succeed {
                self.requestShowDonwloadICloudHUD(iCloudRequestID: requestID)
            }
        }, progressHandler: { [weak self] (asset, progress) in
            guard let self = self else { return }
            if asset == self.photoAsset && asset.downloadStatus != .succeed {
                self.requestUpdateProgress(progress: progress, isICloud: true)
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
    func requestShowDonwloadICloudHUD(iCloudRequestID: PHImageRequestID) {
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        requestID = iCloudRequestID
        currentLoadAssetLocalIdentifier = photoAsset.phAsset?.localIdentifier
        showLoadingView(text: "正在同步iCloud".localized)
    }
    func requestUpdateProgress(progress: Double, isICloud: Bool) {
        guard let loadingView = loadingView else {
            return
        }
        if loadingView.mode == .circleProgress {
            loadingView.progress = CGFloat(progress)
        }else {
            loadingView.text = "正在同步iCloud".localized + "(" + String(Int(photoAsset.downloadProgress * 100)) + "%)"
        }
    }
    func resetLoadingState() {
        UIApplication.shared.isNetworkActivityIndicatorVisible = false
        currentLoadAssetLocalIdentifier = nil
        loadingView = nil
    }
    func requestSucceed() {
        resetLoadingState()
        ProgressHUD.hide(forView: hudSuperview(), animated: true)
        delegate?.contentView(requestSucceed: self)
    }
    func requestFailed(
        info: [AnyHashable: Any]?,
        isICloud: Bool,
        showWarning: Bool = true
    ) {
        loadingView?.removeFromSuperview()
        resetLoadingState()
        if let info = info, !info.isCancel {
            delegate?.contentView(requestFailed: self)
            ProgressHUD.hide(forView: hudSuperview(), animated: false)
            if showWarning {
                let text = (info.inICloud && isICloud) ? "iCloud同步失败".localized : "下载失败".localized
                ProgressHUD.showWarning(addedTo: hudSuperview(), text: text.localized, animated: true, delayHide: 2)
            }
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
        imageTask = nil
    }
    func cancelRequest() {
        guard let photoAsset = photoAsset else { return }
        cancelImageTask()
        if let localLivePhotoRequest = localLivePhotoRequest {
            localLivePhotoRequest.cancelRequest()
            self.localLivePhotoRequest = nil
        }
        if !isPeek {
            photoAsset.playerTime = 0
        }
        switch photoAsset.mediaSubType {
        case .localImage, .networkImage:
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
        if let id = requestID {
            PHImageManager.default().cancelImageRequest(id)
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
}

// MARK: PHLivePhotoViewDelegate
extension PhotoPreviewContentView: PHLivePhotoViewDelegate {
    public func livePhotoView(
        _ livePhotoView: PHLivePhotoView,
        willBeginPlaybackWith playbackStyle: PHLivePhotoViewPlaybackStyle
    ) {
        livePhotoIsAnimating = true
        delegate?.contentView(livePhotoWillBeginPlayback: self)
    }
    public func livePhotoView(
        _ livePhotoView: PHLivePhotoView,
        didEndPlaybackWith playbackStyle: PHLivePhotoViewPlaybackStyle
    ) {
        livePhotoIsAnimating = false
        delegate?.contentView(livePhotoDidEndPlayback: self)
        if livePhotoPlayType == .auto && livePhotoView.alpha != 0 {
            livePhotoView.startPlayback(with: .full)
        }
    }
}
