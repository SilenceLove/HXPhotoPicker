//
//  PhotoPreviewContentPhotoView.swift
//  HXPhotoPicker
//
//  Created by Silence on 2023/10/24.
//  Copyright © 2023 Silence. All rights reserved.
//

import UIKit
import Photos
import PhotosUI
#if canImport(Kingfisher)
import Kingfisher
#endif

class PhotoPreviewContentPhotoView: UIView, PhotoPreviewContentViewProtocol {
    
    weak var delegate: PhotoPreviewContentViewDelete?
    
    var photoAsset: PhotoAsset! { didSet { updateContent() } }
    
    var imageView: ImageView!
    var livePhotoView: PHLivePhotoView!
    var livePhotoPlayType: PhotoPreviewViewController.PlayType = .once
    var isLivePhotoAnimating: Bool = false
    var videoView: PhotoPreviewVideoView!
    var videoPlayType: PhotoPreviewViewController.PlayType = .normal
    
    var isPeek: Bool = false
    var isBacking: Bool = false
    
    var requestID: PHImageRequestID?
    var requestCompletion: Bool = false
    var requestNetworkCompletion: Bool = false
    private var loadAssetLocalIdentifier: String?
    private var isAnimatedCompletion: Bool = false
    private var imageTask: Any?
    
    var loadingView: PhotoHUDProtocol?
    var isProgressHUD: Bool = false
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        initViews()
    }
    
    func initViews() {
        imageView = ImageView()
        imageView.size = size
        addSubview(imageView)
    }
    
    func updateContent() {
        #if canImport(Kingfisher)
        photoAsset.loadNetworkImageHandler = nil
        #endif
        requestFailed(info: [PHImageCancelledKey: 1], isICloud: false)
        isAnimatedCompletion = false
        switch photoAsset.mediaSubType {
        case .localImage:
            requestCompletion = true
        default:
            break
        }
        if photoAsset.isNetworkAsset {
            requestNetwork()
        }else {
            requestThumbnail()
        }
    }
    
    func requestNetwork() { 
        requestNetworkCompletion = false
        requestNetworkImage()
        #if canImport(Kingfisher)
        photoAsset.loadNetworkImageHandler = { [weak self] in
            self?.requestNetworkImage(loadOriginal: true, $0)
        }
        #endif
    }
    
    func requestThumbnail() {
        requestNetworkCompletion = true
        requestID = photoAsset.requestThumImage { [weak self] in
            guard let self = self else { return }
            if let info = $2, info.isCancel { return }
            if let image = $1, self.photoAsset == $0 {
                self.imageView.image = image
            }
        }
    }
    
    func requestPreviewAsset() {
        switch photoAsset.mediaSubType {
        case .localImage, .networkImage:
            return
        default:
            break
        }
        if requestCompletion {
            return
        }
        var canRequest = true
        if let localIdentifier = loadAssetLocalIdentifier,
           localIdentifier == photoAsset.phAsset?.localIdentifier {
            canRequest = false
            UIApplication.shared.isNetworkActivityIndicatorVisible = true
            if loadingView == nil {
                let text: String = .textPreview.iCloudSyncHudTitle.text + "(" + String(Int(photoAsset.downloadProgress * 100)) + "%)"
                let toView = hudSuperview
                loadingView = PhotoManager.HUDView.show(with: text, delay: 0, animated: true, addedTo: toView)
                isProgressHUD = false
            }
        }else {
            UIApplication.shared.isNetworkActivityIndicatorVisible = false
            if let id = requestID {
                PHImageManager.default().cancelImageRequest(id)
                requestID = nil
            }
        }
        requestPreviewContent(canRequest)
    }
    
    func requestPreviewContent(_ canRequest: Bool) {
        #if canImport(Kingfisher)
        if photoAsset.mediaSubType.isGif && isAnimatedCompletion {
            startAnimated()
        }else {
            if canRequest {
                requestOriginalImage()
            }
        }
        #else
        if photoAsset.mediaSubType.isGif && imageView.gifImage != nil {
            imageView.startAnimating()
        }else {
            if canRequest {
                requestOriginalImage()
            }
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
        case .localImage, .networkImage:
            requestCompletion = false
            requestNetworkCompletion = false
            return
        case .networkVideo:
            requestCompletion = false
            requestNetworkCompletion = false
            return
        default:
            break
        }
        loadAssetLocalIdentifier = nil
        if let id = requestID {
            PHImageManager.default().cancelImageRequest(id)
            requestID = nil
        }
        stopAnimated()
        PhotoManager.HUDView.dismiss(delay: 0, animated: false, for: hudSuperview)
        requestCompletion = false
    }
    
    func startAnimated() {
        if photoAsset.mediaSubType.isGif {
            imageView.startAnimatedImage()
        }
    }
    
    func stopAnimated() {
        if photoAsset.mediaSubType.isGif {
            imageView.stopAnimatedImage()
        }
    }
    
    func stopVideo() { }
    
    func stopLivePhoto() { }
    
    var hudSuperview: UIView? {
        if !isPeek {
            if let view = superview?.superview {
                return view
            }
        }
        return self
    }
    
    func showLoadingView(text: String?) {
        loadingView = PhotoManager.HUDView.showProgress(with: text?.localized, progress: 0, animated: true, addedTo: hudSuperview)
        isProgressHUD = true
    }
    
    func showOtherSubview() {
        if !requestNetworkCompletion {
            loadingView?.isHidden = false
        }
    }
    func hiddenOtherSubview() {
        if requestNetworkCompletion {
            loadingView = nil
            PhotoManager.HUDView.dismiss(delay: 0, animated: false, for: hudSuperview)
        }else {
            loadingView?.isHidden = true
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
    
    override func layoutSubviews() {
        super.layoutSubviews()
        imageView.frame = bounds
    }
    
    deinit {
        cancelRequest()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension PhotoPreviewContentPhotoView {
    func requestNetworkImage(
        loadOriginal: Bool = false,
        _ completion: ((PhotoAsset) -> Void)? = nil
    ) {
        requestCompletion = true
        var isLoaclLivePhoto = false
        #if canImport(Kingfisher)
        if photoAsset.mediaSubType != .networkVideo {
            var key: String = ""
            if let networkImage = photoAsset.networkImageAsset {
                if let cacheKey = networkImage.thumbnailURL?.cacheKey,
                   networkImage.originalLoadMode == .alwaysThumbnail,
                   !loadOriginal {
                    key = cacheKey
                }else if let cacheKey = networkImage.originalURL?.cacheKey {
                    key = cacheKey
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
                self.updateProgress(progress: percentage, isICloud: false)
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
}

extension PhotoPreviewContentPhotoView {
    
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
        if photoAsset.isGifAsset {
            requestPreviewImageData()
        }else {
            requestID = photoAsset.requestICloudState { [weak self] asset, inICloud in
                guard let self = self, self.photoAsset == asset else {
                    return
                }
                if inICloud {
                    self.requestPreviewImageData()
                }else {
                    self.requestPreviewImage()
                }
            }
        }
    }
    
    func requestPreviewImage() {
        requestID = photoAsset.requestImage { [weak self] in
            guard $0 == self?.photoAsset,
                  $0.downloadStatus != .succeed else {
                return
            }
            self?.showDonwloadICloudLoading($1)
        } progressHandler: { [weak self] in
            guard $0 == self?.photoAsset,
                  $0.downloadStatus != .succeed else {
                return
            }
            self?.updateProgress(progress: $1, isICloud: true)
        } resultHandler: { [weak self] asset, image, info in
            guard let self = self, self.photoAsset == asset else {
                return
            }
            guard let image else {
                self.requestFailed(info: info, isICloud: true)
                return
            }
            if AssetManager.assetIsDegraded(for: info) {
                return
            }
            self.requestSucceed()
            self.imageView.setImage(image, animated: true)
            self.requestID = nil
            self.requestCompletion = true
        }
    }
    
    func requestPreviewImageData() {
        requestID = photoAsset.requestImageData { [weak self] in
            guard $0 == self?.photoAsset,
                  $0.downloadStatus != .succeed else {
                return
            }
            self?.showDonwloadICloudLoading($1)
        } progressHandler: { [weak self] in
            guard $0 == self?.photoAsset,
                  $0.downloadStatus != .succeed else {
                return
            }
            self?.updateProgress(progress: $1, isICloud: true)
        } resultHandler: { [weak self] in
            self?.requestOriginalCompletion(asset: $0, result: $1)
        }
    }
    
    func showDonwloadICloudLoading(_ requestID: PHImageRequestID) {
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        self.requestID = requestID
        loadAssetLocalIdentifier = photoAsset.phAsset?.localIdentifier
        showLoadingView(text: .textPreview.iCloudSyncHudTitle.text)
    }
    
    func updateProgress(progress: Double, isICloud: Bool) {
        guard let loadingView = loadingView else {
            return
        }
        if isProgressHUD {
            loadingView.setProgress(CGFloat(progress))
        }else {
            let text: String = .textPreview.iCloudSyncHudTitle.text + "(" + String(Int(photoAsset.downloadProgress * 100)) + "%)"
            loadingView.setText(text)
        }
    }
    
    func requestOriginalCompletion(
        asset: PhotoAsset,
        result: Result<AssetManager.ImageDataResult, AssetError>
    ) {
        if asset != photoAsset {
            return
        }
        switch result {
        case .success(let dataResult):
            if asset.mediaSubType.isGif {
                self.requestSucceed()
                imageView.setImageData(dataResult.imageData)
                isAnimatedCompletion = true
                requestID = nil
                requestCompletion = true
            }else {
                DispatchQueue.global().async {
                    func handler(_ result: UIImage? = nil) {
                        var image = result
                        if image == nil {
                            image = UIImage(data: dataResult.imageData)?.normalizedImage()
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
                    let dataCount = CGFloat(dataResult.imageData.count)
                    if dataCount > 3000000 {
                        PhotoTools.compressImageData(
                            dataResult.imageData,
                            compressionQuality: dataCount.compressionQuality,
                            queueLabel: "com.hxphotopicker.previewrequest"
                        ) {
                            guard let imageData = $0 else {
                                handler()
                                return
                            }
                            handler(.init(data: imageData))
                        }
                        return
                    }
                    handler()
                }
            }
        case .failure(let error):
            self.requestFailed(info: error.info, isICloud: true)
        }
    }
    
    func resetLoadingState() {
        UIApplication.shared.isNetworkActivityIndicatorVisible = false
        loadAssetLocalIdentifier = nil
        loadingView = nil
    }
    func requestSucceed() {
        resetLoadingState()
        PhotoManager.HUDView.dismiss(delay: 0, animated: true, for: hudSuperview)
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
            PhotoManager.HUDView.dismiss(delay: 0, animated: false, for: hudSuperview)
            if showWarning {
                let text: String = (info.inICloud && isICloud) ? .textPreview.iCloudSyncFailedHudTitle.text : .textPreview.downloadFailedHudTitle.text
                PhotoManager.HUDView.showInfo(with: text.localized, delay: 2, animated: true, addedTo: hudSuperview)
            }
        }
    }
}
