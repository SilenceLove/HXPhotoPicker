//
//  Picker+UIImageView.swift
//  HXPhotoPicker
//
//  Created by Slience on 2021/5/26.
//

import UIKit
import AVKit
#if canImport(Kingfisher)
import Kingfisher
#endif

extension UIImageView {
    
    #if canImport(Kingfisher)
    @discardableResult
    func setImage(
        for asset: PhotoAsset,
        urlType: DonwloadURLType,
        forciblyOriginal: Bool = false,
        indicatorColor: UIColor? = nil,
        progressBlock: DownloadProgressBlock? = nil,
        downloadTask: ((Kingfisher.DownloadTask?) -> Void)? = nil,
        completionHandler: ImageView.ImageCompletion? = nil
    ) -> Any? {
        #if HXPICKER_ENABLE_EDITOR
        if asset.editedResult != nil {
            getEditedImage(asset, urlType: urlType, completionHandler: completionHandler)
            return nil
        }
        #endif
        let isThumbnail = urlType == .thumbnail
        if isThumbnail {
            kf.indicatorType = .activity
            if let color = indicatorColor {
                (kf.indicator?.view as? UIActivityIndicatorView)?.color = color
            }
        }
        var url: URL?
        var placeholderImage: UIImage?
        var options: KingfisherOptionsInfo = []
        if let imageDonwloader = PhotoManager.shared.imageDownloader {
            options += [.downloader(imageDonwloader)]
        }
        var loadVideoCover: Bool = false
        if let imageAsset = asset.networkImageAsset {
            if isThumbnail {
                if imageAsset.thumbnailLoadMode == .varied {
                    if ImageCache.default.isCached(forKey: imageAsset.originalURL.cacheKey) {
                        if ImageCache.default.isCached(forKey: imageAsset.thumbnailURL.cacheKey) {
                            placeholderImage = ImageCache.default.retrieveImageInMemoryCache(forKey: imageAsset.thumbnailURL.cacheKey, options: [])
                            (kf.indicator?.view as? UIActivityIndicatorView)?.color = .white
                        }else {
                            placeholderImage = UIImage.image(for: imageAsset.placeholder)
                        }
                        url = imageAsset.originalURL
                    }else {
                        url = imageAsset.thumbnailURL
                        placeholderImage = UIImage.image(for: imageAsset.placeholder)
                    }
                }else {
                    url = imageAsset.thumbnailURL
                    placeholderImage = UIImage.image(for: imageAsset.placeholder)
                }
                let processor: DownsamplingImageProcessor
                if imageAsset.thumbnailSize.equalTo(.zero) {
                    processor = .init(size: size)
                }else {
                    processor = .init(size: imageAsset.thumbnailSize)
                }
                options += [
                    .onlyLoadFirstFrame,
                    .processor(processor),
                    .cacheOriginalImage,
                    .scaleFactor(UIScreen.main.scale)
                ]
                if imageAsset.isFade {
                    options += [.transition(.fade(0.2))]
                }
            }else {
                if imageAsset.originalLoadMode == .alwaysThumbnail,
                   !forciblyOriginal {
                    if ImageCache.default.isCached(forKey: imageAsset.originalURL.cacheKey) {
                        url = imageAsset.originalURL
                    }else {
                        url = imageAsset.thumbnailURL
                    }
                    placeholderImage = UIImage.image(for: imageAsset.placeholder)
                }else {
                    placeholderImage = image
                    url = imageAsset.originalURL
                }
                options = [.transition(.fade(0.2))]
            }
        }else if let videoAsset = asset.networkVideoAsset {
            if let coverImage = videoAsset.coverImage {
                image = coverImage
                completionHandler?(coverImage, nil, asset)
                return nil
            }else if let coverImageURL = videoAsset.coverImageURL {
                url = coverImageURL
                options = [.transition(.fade(0.2))]
                placeholderImage = UIImage.image(for: videoAsset.coverPlaceholder)
            }else {
                let key = videoAsset.videoURL.absoluteString
                var videoURL: URL
                if PhotoTools.isCached(forVideo: key) {
                    videoURL = PhotoTools.getVideoCacheURL(for: key)
                }else {
                    videoURL = videoAsset.videoURL
                }
                placeholderImage = UIImage.image(for: videoAsset.coverPlaceholder)
                loadVideoCover = true
                url = videoURL
            }
        }else if let videoAsset = asset.localVideoAsset {
            if let coverImage = videoAsset.image {
                image = coverImage
                completionHandler?(coverImage, nil, asset)
                return nil
            }
            loadVideoCover = true
            url = videoAsset.videoURL
        }else if let livePhotoAsset = asset.localLivePhoto,
                    !livePhotoAsset.imageURL.isFileURL {
            url = livePhotoAsset.imageURL
        }
        if let url = url, loadVideoCover {
            let provider = AVAssetImageDataProvider(assetURL: url, seconds: 0.1)
            provider.assetImageGenerator.appliesPreferredTrackTransform = true
            let task = KF.dataProvider(provider)
                .placeholder(placeholderImage)
                .onSuccess { [weak asset] (result) in
                    guard let asset = asset else {
                        return
                    }
                    let image = result.image
                    let videoSize: CGSize?
                    if asset.isNetworkAsset {
                        videoSize = asset.networkVideoAsset?.videoSize
                    }else {
                        videoSize = asset.localVideoAsset?.videoSize
                    }
                    if let videoSize = videoSize, videoSize.equalTo(.zero) {
                        asset.localVideoAsset?.videoSize = image.size
                        asset.networkVideoAsset?.videoSize = image.size
                    }
                    completionHandler?(image, nil, asset)
                }
                .onFailure { [weak asset] (error) in
                    guard let asset = asset else {
                        return
                    }
                    completionHandler?(nil, error, asset)
                }
                .set(to: self)
            return task
        }
        return kf.setImage(
            with: url,
            placeholder: placeholderImage,
            options: options,
            progressBlock: progressBlock
        ) { [weak asset] result in
            guard let asset = asset else { return }
            switch result {
            case .success(let value):
                switch asset.mediaSubType {
                case .networkImage(_):
                    let cacheKey = value.originalSource.cacheKey
                    if let networkAsset = asset.networkImageAsset, networkAsset.imageSize.equalTo(.zero) {
                        ImageCache.default.retrieveImage(forKey: cacheKey, options: []) { [weak asset] result in
                            guard let asset = asset else { return }
                            switch result {
                            case .success(let value):
                                guard let image = value.image else { return }
    //                            if asset.localImageAsset == nil {
    //                                let localImageAsset = LocalImageAsset(image: image)
    //                                asset.localImageAsset = localImageAsset
    //                            }
                                asset.networkImageAsset?.imageSize = image.size
//                                if asset.localImageType != .original && !isThumbnail {
//                                    DispatchQueue.global().async {
//                                        if let imageData = image.kf.data(format: asset.mediaSubType.isGif ? .GIF : .unknown) {
//                                            asset.networkImageAsset?.fileSize = imageData.count
//                                        }
//                                    }
//                                    asset.localImageType = urlType
//                                }
                            case .failure(_):
                                return
                            }
                        }
                    }
                case .networkVideo:
                    asset.networkVideoAsset?.coverImage = value.image
                    asset.networkVideoAsset?.videoSize = value.image.size
                case .localLivePhoto:
                    if let livePhoto = asset.localLivePhoto,
                       !livePhoto.imageURL.isFileURL {
                        asset.localLivePhoto?.size = value.image.size
                    }
                default: break
                }
                completionHandler?(value.image, nil, asset)
            case .failure(let error):
                completionHandler?(nil, error, asset)
            }
        }
    }
    #if HXPICKER_ENABLE_EDITOR
    private func getEditedImage(
        _ photoAsset: PhotoAsset,
        urlType: DonwloadURLType,
        completionHandler: ImageView.ImageCompletion?
    ) {
        if let photoEdit = photoAsset.photoEditedResult {
            if urlType == .thumbnail {
                image = photoEdit.image
                completionHandler?(photoEdit.image, nil, photoAsset)
            }else {
                do {
                    let imageData = try Data(contentsOf: photoEdit.url)
                    let img = DefaultImageProcessor.default.process(item: .data(imageData), options: .init([]))!
                    let kfView = self as? AnimatedImageView
                    kfView?.image = img
                }catch {
                    image = photoEdit.image
                }
                completionHandler?(photoEdit.image, nil, photoAsset)
            }
        }else if let videoEdit = photoAsset.videoEditedResult {
            image = videoEdit.coverImage
            completionHandler?(videoEdit.coverImage, nil, photoAsset)
        }
    }
    #endif
    #else
    @discardableResult
    func setVideoCoverImage(
        for asset: PhotoAsset,
        imageGenerator: ((AVAssetImageGenerator) -> Void)? = nil,
        completionHandler: ((UIImage?, PhotoAsset) -> Void)? = nil
    ) -> Any? {
        #if HXPICKER_ENABLE_EDITOR
        if let videoEdit = asset.videoEditedResult {
            completionHandler?(videoEdit.coverImage, asset)
            return nil
        }
        #endif
        var videoURL: URL?
        if let videoAsset = asset.networkVideoAsset {
            if let coverImage = videoAsset.coverImage {
                if videoAsset.videoSize.equalTo(.zero) {
                    asset.networkVideoAsset?.videoSize = coverImage.size
                }
                completionHandler?(coverImage, asset)
                return nil
            }else {
                let key = videoAsset.videoURL.absoluteString
                if PhotoTools.isCached(forVideo: key) {
                    videoURL = PhotoTools.getVideoCacheURL(for: key)
                }else {
                    videoURL = videoAsset.videoURL
                }
            }
        }else if let videoAsset = asset.localVideoAsset {
            if let coverImage = videoAsset.image {
                if videoAsset.videoSize.equalTo(.zero) {
                    asset.localVideoAsset?.videoSize = coverImage.size
                }
                completionHandler?(coverImage, asset)
                return nil
            }
            videoURL = videoAsset.videoURL
        }else {
            completionHandler?(nil, asset)
            return nil
        }
        return PhotoTools.getVideoThumbnailImage(
            url: videoURL!,
            atTime: 0.1,
            imageGenerator: imageGenerator
        ) { videoURL, image, result in
            if let image = image {
                if asset.isNetworkAsset {
                    asset.networkVideoAsset?.videoSize = image.size
                    asset.networkVideoAsset?.coverImage = image
                }else {
                    asset.localVideoAsset?.videoSize = image.size
                    asset.localVideoAsset?.image = image
                }
            }
            if result == .cancelled { return }
            completionHandler?(image, asset)
        }
    }
    #endif
}

extension ImageView {
    
    #if canImport(Kingfisher)
    typealias ImageCompletion = (UIImage?, KingfisherError?, PhotoAsset) -> Void
    
    @discardableResult
    func setImage(
        for asset: PhotoAsset,
        urlType: DonwloadURLType,
        forciblyOriginal: Bool = false,
        progressBlock: DownloadProgressBlock? = nil,
        downloadTask: ((Kingfisher.DownloadTask?) -> Void)? = nil,
        completionHandler: ImageCompletion? = nil
    ) -> Any? {
        imageView.setImage(
            for: asset,
            urlType: urlType,
            forciblyOriginal: forciblyOriginal,
            progressBlock: progressBlock,
            downloadTask: downloadTask,
            completionHandler: completionHandler
        )
    }
    #else
    @discardableResult
    func setVideoCoverImage(
        for asset: PhotoAsset,
        imageGenerator: ((AVAssetImageGenerator) -> Void)? = nil,
        completionHandler: ((UIImage?, PhotoAsset) -> Void)? = nil
    ) -> Any? {
        imageView.setVideoCoverImage(
            for: asset,
            imageGenerator: imageGenerator,
            completionHandler: completionHandler
        )
    }
    #endif
}
