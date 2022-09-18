//
//  PhotoThumbnailView.swift
//  HXPHPicker
//
//  Created by Slience on 2021/9/2.
//

import UIKit
import Photos
import AVFoundation

#if canImport(Kingfisher)
import Kingfisher
#endif

open class PhotoThumbnailView: UIView {
    
    /// 展示图片
    public lazy var imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        return imageView
    }()
    
    /// 占位图
    public var placeholder: UIImage? {
        didSet {
            if _image != nil {
                return
            }
            imageView.image = placeholder
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
    
    /// Kingfisher.DownloadTask
    /// 获取视频封面时为：AVAsset / AVAssetImageGenerator
    public var task: Any?
    
    #if canImport(Kingfisher)
    public var kf_indicatorColor: UIColor?
    #endif
    
    private var _image: UIImage?
    private var firstLoadImage: Bool = true
    private var completeLoading: Bool = false
    
    var fadeImage: Bool = false
    var loadCompletion: Bool = false
    
    public override init(frame: CGRect) {
        super.init(frame: .zero)
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
        if photoAsset.isNetworkAsset ||
            photoAsset.mediaSubType == .localVideo {
            
            downloadStatus = .downloading
            #if canImport(Kingfisher)
            task = imageView.setImage(
                for: photoAsset,
                urlType: .thumbnail,
                indicatorColor: kf_indicatorColor,
                downloadTask: { [weak self] downloadTask in
                    self?.task = downloadTask
                }
            ) { [weak self] (image, error, photoAsset) in
                guard let self = self else { return }
                if self.photoAsset == photoAsset {
                    self._image = image
                    if image != nil {
                        self.downloadStatus = .succeed
                    }else {
                        if let error = error, error.isTaskCancelled {
                            self.downloadStatus = .canceled
                        }else {
                            self.downloadStatus = .failed
                        }
                    }
                    self.loadCompletion = true
                }
                completion?(image, photoAsset)
            }
            #else
            task = imageView.setVideoCoverImage(
                for: photoAsset
            ) { [weak self] imageGenerator in
                self?.task = imageGenerator
            } completionHandler: { [weak self] (image, photoAsset) in
                guard let self = self else { return }
                if self.photoAsset == photoAsset {
                    self.requestCompletion(image)
                    if image != nil {
                        self.downloadStatus = .succeed
                    }else {
                        self.downloadStatus = .failed
                    }
                    self.loadCompletion = true
                }
                completion?(image, photoAsset)
            }
            #endif
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
        if task == nil {
            return
        }
        #if canImport(Kingfisher)
        if let donwloadTask = task as? Kingfisher.DownloadTask {
            donwloadTask.cancel()
        }else if let avAsset = task as? AVAsset {
            avAsset.cancelLoading()
        }else if let imageGenerator = task as? AVAssetImageGenerator {
            imageGenerator.cancelAllCGImageGeneration()
        }
        #else
        if let avAsset = task as? AVAsset {
            avAsset.cancelLoading()
        }else if let imageGenerator = task as? AVAssetImageGenerator {
            imageGenerator.cancelAllCGImageGeneration()
        }
        #endif
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
