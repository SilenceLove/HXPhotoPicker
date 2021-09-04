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
            imageView.image = placeholder
        }
    }
    
    /// 当前展示的 UIImage 对象
    public var image: UIImage? {
        imageView.image
    }
    
    /// 请求ID
    public var requestID: PHImageRequestID?
    
    /// 网络图片下载状态
    public var downloadStatus: PhotoAsset.DownloadStatus = .unknow
    
    /// 对应资源的 PhotoAsset 对象
    open var photoAsset: PhotoAsset?
    
    /// 获取图片，重写此方法可以修改图片
    open func requestThumbnailImage() {
        requestThumbnailImage(
            targetWidth: PhotoManager.shared.targetWidth <= 0 ?
                width * 2 :
                PhotoManager.shared.targetWidth
        )
    }
    
    /// 下载网络图片时为：Kingfisher.DownloadTask
    public var task: Any?
    
    /// 获取图片，重写此方法可以修改图片
    open func requestThumbnailImage(
        targetWidth: CGFloat,
        completion: ((UIImage?, PhotoAsset) -> Void)? = nil
    ) {
        guard let photoAsset = photoAsset else {
            return
        }
        if photoAsset.isNetworkAsset ||
            photoAsset.mediaSubType == .localVideo {
            
            downloadStatus = .downloading
            #if canImport(Kingfisher)
            task = imageView.setImage(
                for: photoAsset,
                urlType: .thumbnail,
                downloadTask: { [weak self] downloadTask in
                    self?.task = downloadTask
                }
            ) { [weak self] (image, error, photoAsset) in
                guard let self = self else { return }
                if self.photoAsset == photoAsset {
                    if image != nil {
                        self.downloadStatus = .succeed
                    }else {
                        if error!.isTaskCancelled {
                            self.downloadStatus = .canceled
                        }else {
                            self.downloadStatus = .failed
                        }
                    }
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
                    self.imageView.image = image
                    if image != nil {
                        self.downloadStatus = .succeed
                    }else {
                        self.downloadStatus = .failed
                    }
                }
                completion?(image, photoAsset)
            }
            #endif
        }else {
            requestID = photoAsset.requestThumbnailImage(
                targetWidth: targetWidth,
                completion: { [weak self] (image, photoAsset, info) in
                guard let self = self else { return }
                if let info = info, info.isCancel { return }
                if let image = image, self.photoAsset == photoAsset {
                    self.imageView.image = image
                    if !AssetManager.assetIsDegraded(for: info) {
                        self.requestID = nil
                    }
                }
                completion?(image, photoAsset)
            })
        }
    }
    /// 布局，重写此方法修改布局
    open func layoutView() {
        imageView.frame = bounds
    }
    /// 取消请求资源图片
    public func cancelRequest() {
        if let requestID = requestID {
            PHImageManager.default().cancelImageRequest(requestID)
            self.requestID = nil
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
    }
    
    public override init(frame: CGRect) {
        super.init(frame: .zero)
        addSubview(imageView)
    }
    
    open override func layoutSubviews() {
        super.layoutSubviews()
        layoutView()
    }
    
    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
