//
//  PhotoThumbnailView.swift
//  HXPhotoPicker
//
//  Created by Slience on 2021/9/2.
//

import UIKit
import Photos
import AVFoundation

open class PhotoThumbnailView: UIView {
    
    /// 展示图片
    public var imageView: HXImageViewProtocol!
    
    /// 占位图
    public var placeholder: UIImage? {
        get {
            if _image != nil {
                return nil
            }
            return imageView.image
        }
        set {
            if _image != nil {
                return
            }
            imageView.image = newValue
        }
    }
    
    /// 当前展示的 UIImage 对象
    public var image: UIImage? {
        _image
    }
    
    /// 请求ID
    public var requestID: PHImageRequestID?
    
    /// 网络图片下载状态
    public var downloadStatus: PhotoAsset.DownloadStatus = .unknow
    
    /// 对应资源的 PhotoAsset 对象
    open var photoAsset: PhotoAsset?
    
    /// 缩略图的清晰度，越大越清楚，越小越模糊
    open var targetWidth: CGFloat = 250
    
    /// 获取图片，重写此方法可以修改图片
    open func requestThumbnailImage() {
        requestThumbnailImage(
            targetWidth: targetWidth
        )
    }
    
    /// 获取视频封面时为：AVAsset / AVAssetImageGenerator
    public var task: Any?
    
    public var kf_indicatorColor: UIColor?
    
    private var _image: UIImage?
    private var firstLoadImage: Bool = true
    private var completeLoading: Bool = false
    
    var fadeImage: Bool = false
    var loadCompletion: Bool = false
    
    public init(_ photoAsset: PhotoAsset? = nil) {
        self.photoAsset = photoAsset
        super.init(frame: .zero)
        imageView = PhotoManager.ImageView.init()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        addSubview(imageView)
    }
    
    open override func layoutSubviews() {
        super.layoutSubviews()
        layoutView()
    }
    
    /// 布局，重写此方法修改布局
    open func layoutView() {
        imageView.frame = bounds
    }
    
    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    /// 获取图片，重写此方法可以修改图片
    open func requestThumbnailImage(
        targetWidth: CGFloat,
        completion: ((UIImage?, PhotoAsset) -> Void)? = nil
    ) {
        guard let photoAsset = photoAsset else { return }
        if _image != nil {
            firstLoadImage = false
        }
        loadCompletion = false
        cancelRequest()
        var isNetworkLivePhotoImage: Bool = false
        if let livePhoto = photoAsset.localLivePhoto?.imageURL, !livePhoto.isFileURL {
            isNetworkLivePhotoImage = true
        }
        
        if photoAsset.isNetworkAsset || photoAsset.mediaSubType == .localVideo || isNetworkLivePhotoImage {
            downloadStatus = .downloading
            task = imageView.setImage(
                for: photoAsset,
                urlType: .thumbnail,
                indicatorColor: kf_indicatorColor,
                progressBlock: nil
            ) { [weak self] downloadTask, asset in
                guard let self, self.photoAsset == asset else { return }
                self.task = downloadTask
            } completionHandler: { [weak self] image, photoAsset in
                guard let self = self else { return }
                if self.photoAsset == photoAsset {
                    if photoAsset.mediaSubType == .localVideo || photoAsset.mediaSubType == .networkVideo {
                        self.imageView.image = image
                    }
                    self._image = image
                    if image != nil {
                        self.downloadStatus = .succeed
                    }else {
                        self.downloadStatus = .failed
                    }
                    self.loadCompletion = true
                }
                completion?(image, photoAsset)
            }
        }else {
            let thumbnailLoadMode = PhotoManager.shared.thumbnailLoadMode
            if thumbnailLoadMode == .complete {
                completeLoading = true
            }
            requestID = photoAsset.requestThumbnailImage(
                targetWidth: thumbnailLoadMode == .simplify ? 10 : targetWidth
            ) { [weak self] (image, photoAsset, info) in
                guard let self = self else { return }
                if let info = info, info.isCancel { return }
                if self.photoAsset == photoAsset {
                    if let image = image {
                        self.requestCompletion(image)
                        if !AssetManager.assetIsDegraded(for: info) {
                            self.requestID = nil
                            if PhotoManager.shared.thumbnailLoadMode == .complete {
                                self.loadCompletion = true
                            }
                        }
                    }
                    if PhotoManager.shared.thumbnailLoadMode == .complete {
                        self.completeLoading = false
                    }
                }
                completion?(image, photoAsset)
            }
        }
    }
    /// 取消请求资源图片
    public func cancelRequest() {
        if completeLoading {
            completeLoading = false
        }
        if let requestID = requestID {
            PHImageManager.default().cancelImageRequest(requestID)
            self.requestID = nil
        }
        if let avAsset = task as? AVAsset {
            avAsset.cancelLoading()
        }else if let imageGenerator = task as? AVAssetImageGenerator {
            imageGenerator.cancelAllCGImageGeneration()
        }else if let task = task as? ImageDownloadTask {
            task.cancelHandler()
        }
        task = nil
    }
}

// MARK: private
extension PhotoThumbnailView {
    
    private func requestCompletion(_ image: UIImage?) {
        if fadeImage {
            imageView.setImage(image, animated: _image == nil ? false : firstLoadImage)
        }else {
            imageView.image = image
        }
        _image = image
    }
}

extension PhotoThumbnailView {
    func reloadImage() {
        if completeLoading { return }
        if !loadCompletion {
            _image = nil
            firstLoadImage = true
            fadeImage = true
            requestThumbnailImage()
        }
    }
}
