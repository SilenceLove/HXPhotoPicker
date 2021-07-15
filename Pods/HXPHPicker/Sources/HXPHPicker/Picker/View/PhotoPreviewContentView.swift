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

protocol PhotoPreviewContentViewDelete: AnyObject {
    func contentView(networkImagedownloadSuccess contentView: PhotoPreviewContentView)
    func contentView(networkImagedownloadFailed contentView: PhotoPreviewContentView)
    func contentView(updateContentSize contentView: PhotoPreviewContentView)
}

class PhotoPreviewContentView: UIView, PHLivePhotoViewDelegate {
    
    enum `Type`: Int {
        case photo
        case livePhoto
        case video
    }
    weak var delegate: PhotoPreviewContentViewDelete?
    
    lazy var imageView: UIImageView = {
        var imageView: UIImageView
        #if canImport(Kingfisher)
        imageView = AnimatedImageView.init()
        #else
        imageView = GIFImageView.init()
        #endif
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        return imageView
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
    
    var type: Type = .photo
    var requestID: PHImageRequestID?
    var requestCompletion: Bool = false
    var requestNetworkCompletion: Bool = false
    var networkVideoLoading: Bool = false
    
    var videoPlayType: PhotoPreviewViewController.VideoPlayType = .normal  {
        didSet {
            if type == .video {
                videoView.videoPlayType = videoPlayType
            }
        }
    }
    var currentLoadAssetLocalIdentifier: String?
    var photoAsset: PhotoAsset! {
        didSet {
            requestFailed(info: [PHImageCancelledKey : 1])
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
            requestID = photoAsset.requestThumbnailImage(targetWidth: min(UIScreen.main.bounds.width, UIScreen.main.bounds.height), completion: { [weak self] (image, asset, info) in
                if asset == self?.photoAsset && image != nil {
                    self?.imageView.image = image
                }
            })
        }
    }
    
    func requestNetworkImage() {
        requestCompletion = true
        #if canImport(Kingfisher)
        if photoAsset.mediaSubType != .networkVideo {
            showLoadingView()
        }
        imageView.setImage(for: photoAsset, urlType: .original) { [weak self] (receivedData, totolData) in
            if let mediaSubType = self?.photoAsset.mediaSubType, mediaSubType != .networkVideo {
                let percentage = Double(receivedData) / Double(totolData)
                self?.requestUpdateProgress(progress: percentage)
            }
        } completionHandler: { [weak self] (image, error, photoAsset) in
            guard let self = self else { return }
            if self.photoAsset.mediaSubType != .networkVideo {
                self.requestNetworkCompletion = true
                if let image = image {
                    self.requestSucceed()
                    self.updateContentSize(image: image)
                    self.delegate?.contentView(networkImagedownloadSuccess: self)
                }else {
                    self.requestFailed(info: nil)
                }
            }else {
                if let image = image {
                    self.updateContentSize(image: image)
                }
            }
        }
        #else
        imageView.setVideoCoverImage(for: photoAsset) { [weak self] (image, photoAsset) in
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
            let key = videoURL.absoluteString
            if PhotoTools.isCached(forVideo: key) {
                let url = PhotoTools.getVideoCacheURL(for: key)
                checkNetworkVideoFileSize(url)
                networkVideoRequestCompletion(url)
                return
            }
            if loadingView == nil {
                ProgressHUD.hide(forView: superview?.superview, animated: false)
                showLoadingView()
            }else {
                loadingView?.isHidden = false
            }
            networkVideoLoading = true
            PhotoManager.shared.downloadTask(with: videoURL) { [weak self] (progress, task) in
                self?.requestUpdateProgress(progress: progress)
            } completionHandler: { [weak self] (url, error) in
                guard let self = self else {
                    return
                }
                self.networkVideoLoading = false
                if let url = url {
                    if let image = self.photoAsset.networkVideoAsset?.coverImage {
                        self.updateContentSize(image: image)
                    }else if let image = PhotoTools.getVideoThumbnailImage(videoURL: url, atTime: 0.1) {
                        self.photoAsset.networkVideoAsset?.coverImage = image
                        self.updateContentSize(image: image)
                    }
                    self.checkNetworkVideoFileSize(url)
                    self.requestSucceed()
                    self.networkVideoRequestCompletion(url)
                }else {
                    if let error = error as NSError?, error.code == NSURLErrorCancelled {
                        self.requestFailed(info: [PHImageCancelledKey : 1])
                    }else {
                        self.requestFailed(info: nil)
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
        if let localIdentifier = currentLoadAssetLocalIdentifier, localIdentifier == photoAsset.phAsset?.localIdentifier {
            canRequest = false
            UIApplication.shared.isNetworkActivityIndicatorVisible = true
            if loadingView == nil {
                loadingView = ProgressHUD.showLoading(addedTo: superview?.superview, text: "正在下载".localized + "(" + String(Int(photoAsset.downloadProgress * 100)) + "%)", animated: true)
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
            let gifImageView = imageView as! GIFImageView
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
        requestID = photoAsset.requestImageData(iCloudHandler: { [weak self] (asset, iCloudRequestID) in
            if asset == self?.photoAsset {
                self?.requestShowDonwloadICloudHUD(iCloudRequestID: iCloudRequestID)
            }
        }, progressHandler: { [weak self] (asset, progress) in
            if asset == self?.photoAsset {
                self?.requestUpdateProgress(progress: progress)
            }
        }, success: { [weak self] (asset, imageData, imageOrientation, info) in
            guard let self = self else { return }
            if asset.mediaSubType.isGif {
                if asset == self.photoAsset {
                    self.requestSucceed()
                    self.imageView.setImageData(imageData)
                    self.setAnimatedImageCompletion = true
                    self.requestID = nil
                    self.requestCompletion = true
                }
            }else {
                DispatchQueue.global().async {
                    var image = UIImage.init(data: imageData)
                    image = image?.scaleSuitableSize()
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
        }, failure: { [weak self] (asset, info) in
            if asset == self?.photoAsset {
                self?.requestFailed(info: info)
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
        let targetSize : CGSize = size
        requestID = photoAsset.requestLivePhoto(targetSize: targetSize, iCloudHandler: { [weak self] (asset, requestID) in
            if asset == self?.photoAsset {
                self?.requestShowDonwloadICloudHUD(iCloudRequestID: requestID)
            }
        }, progressHandler: {  [weak self](asset, progress) in
            if asset == self?.photoAsset {
                self?.requestUpdateProgress(progress: progress)
            }
        }, success: { [weak self] (asset, livePhoto, info) in
            if asset == self?.photoAsset {
                self?.requestSucceed()
                self?.livePhotoView.livePhoto = livePhoto
                UIView.animate(withDuration: 0.25) {
                    self?.livePhotoView.alpha = 1
                }
                self?.livePhotoView.startPlayback(with: PHLivePhotoViewPlaybackStyle.full)
                self?.requestID = nil
                self?.requestCompletion = true
            }
        }, failure: { [weak self] (asset, info) in
            if asset == self?.photoAsset {
                self?.requestFailed(info: info)
            }
        })
    }
    func requestAVAsset() {
        requestID = photoAsset.requestAVAsset(iCloudHandler: { [weak self] (asset, requestID) in
            if asset == self?.photoAsset {
                self?.requestShowDonwloadICloudHUD(iCloudRequestID: requestID)
            }
        }, progressHandler: { [weak self] (asset, progress) in
            if asset == self?.photoAsset {
                self?.requestUpdateProgress(progress: progress)
            }
        }, success: { [weak self] (asset, avAsset, info) in
            if asset == self?.photoAsset {
                self?.requestSucceed()
                if self?.isBacking ?? true {
                    return
                }
                self?.videoView.avAsset = avAsset
                UIView.animate(withDuration: 0.25) {
                    self?.videoView.alpha = 1
                }
                self?.requestID = nil
                self?.requestCompletion = true
            }
        }, failure: { [weak self] (asset, info) in
            if asset == self?.photoAsset {
                self?.requestFailed(info: info)
            }
        })
    }
    func requestShowDonwloadICloudHUD(iCloudRequestID: PHImageRequestID) {
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        requestID = iCloudRequestID
        currentLoadAssetLocalIdentifier = photoAsset.phAsset?.localIdentifier
        showLoadingView()
    }
    func requestUpdateProgress(progress: Double) {
        loadingView?.updateText(text: "正在下载".localized + "(" + String(Int(progress * 100)) + "%)")
    }
    func showLoadingView() {
        loadingView = ProgressHUD.showLoading(addedTo: superview?.superview, text: "正在下载".localized, animated: true)
    }
    func resetLoadingState() {
        UIApplication.shared.isNetworkActivityIndicatorVisible = false
        currentLoadAssetLocalIdentifier = nil
        loadingView = nil
    }
    func requestSucceed() {
        resetLoadingState()
        ProgressHUD.hide(forView: superview?.superview, animated: true)
    }
    func requestFailed(info: [AnyHashable : Any]?, isCancel: Bool = false) {
        loadingView?.removeFromSuperview()
        resetLoadingState()
        if !AssetManager.assetCancelDownload(for: info) {
            ProgressHUD.hide(forView: superview?.superview, animated: true)
            ProgressHUD.showWarning(addedTo: superview?.superview, text: "下载失败".localized, animated: true, delayHide: 2)
        }
    }
    func cancelRequest() {
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
        ProgressHUD.hide(forView: superview?.superview, animated: false)
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
                requestFailed(info: [PHImageCancelledKey : 1])
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
                }
            }else {
                videoView.hiddenPlayButton()
            }
        }
        if requestNetworkCompletion {
            loadingView = nil
            ProgressHUD.hide(forView: superview?.superview, animated: false)
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
    
    override func layoutSubviews() {
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
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}


fileprivate extension UIImageView {
    #if canImport(Kingfisher)
    var my: AnimatedImageView {
        self as! AnimatedImageView
    }
    #else
    var my: GIFImageView {
        self as! GIFImageView
    }
    #endif
    
    func setImage(_ img: UIImage) {
        #if canImport(Kingfisher)
        let image = DefaultImageProcessor.default.process(item: .image(img), options: .init([]))
        my.image = image
        #else
        my.image = img
        #endif
    }
    
    func setImageData(_ imageData: Data) {
        #if canImport(Kingfisher)
        let image = DefaultImageProcessor.default.process(item: .data(imageData), options: .init([]))
        my.image = image
        #else
        let image = GIFImage.init(data: imageData)
        my.gifImage = image
        #endif
    }
    
    func startAnimatedImage() {
        #if canImport(Kingfisher)
        my.startAnimating()
        #else
        my.setupDisplayLink()
        #endif
    }
    func stopAnimatedImage() {
        #if canImport(Kingfisher)
        my.stopAnimating()
        #else
        my.displayLink?.invalidate()
        my.gifImage = nil
        #endif
    }
}
