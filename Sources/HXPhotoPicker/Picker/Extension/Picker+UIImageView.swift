//
//  Picker+UIImageView.swift
//  HXPhotoPicker
//
//  Created by Slience on 2021/5/26.
//

import UIKit
import AVFoundation

extension HXImageViewProtocol {
    
    // swiftlint:disable function_body_length
    func setImage(
        for asset: PhotoAsset,
        urlType: DonwloadURLType,
        forciblyOriginal: Bool = false,
        indicatorColor: UIColor? = nil,
        progressBlock: ((CGFloat, PhotoAsset) -> Void)? = nil,
        taskHandler: ((Any, PhotoAsset) -> Void)? = nil,
        completionHandler: ((UIImage?, PhotoAsset) -> Void)? = nil
    ) -> ImageDownloadTask? {
        // swiftlint:enable function_body_length
        #if HXPICKER_ENABLE_EDITOR
        if asset.editedResult != nil {
            getEditedImage(asset, urlType: urlType, completionHandler: completionHandler)
            return nil
        }
        #endif
        let isThumbnail = urlType == .thumbnail
        var url: URL?
        var options: ImageDownloadOptionsInfo = []
        var placeholderImage: UIImage?
        var loadVideoCover: Bool = false
        var cacheKey: String?
        var indicatorColor = indicatorColor
        if let imageAsset = asset.networkImageAsset {
            let originalCacheKey = imageAsset.originalCacheKey
            if isThumbnail {
                let tagerSize: CGSize
                if imageAsset.thumbnailLoadMode == .varied,
                   let originalCacheKey,
                   PhotoManager.ImageView.isCached(forKey: originalCacheKey) {
                    if let thumbnailCacheKey = imageAsset.thumbailCacheKey,
                       PhotoManager.ImageView.isCached(forKey: thumbnailCacheKey) {
                        placeholderImage = PhotoManager.ImageView.getInMemoryCacheImage(forKey: thumbnailCacheKey)
                        indicatorColor = .white
                    }else {
                        placeholderImage = UIImage.image(for: imageAsset.placeholder)
                    }
                    url = imageAsset.originalURL
                    cacheKey = imageAsset.originalCacheKey
                    tagerSize = .init(width: min(200, imageAsset.originalImageSize.width), height: min(200, imageAsset.originalImageSize.height))
                }else {
                    url = imageAsset.thumbnailURL
                    cacheKey = imageAsset.thumbailCacheKey
                    placeholderImage = UIImage.image(for: imageAsset.placeholder)
                    tagerSize = imageAsset.thumbnailSize
                }
                let processorSize: CGSize
                if tagerSize.equalTo(.zero) {
                    if !asset.imageSize.equalTo(.zero) {
                        let pWidth = max(size.width * 2, 200)
                        let pHeight = max(size.height * 2, 200)
                        if pWidth > pHeight {
                            processorSize = .init(width: pWidth, height: asset.imageSize.height / asset.imageSize.width * pHeight)
                        }else {
                            processorSize = .init(width: pHeight, height: asset.imageSize.height / asset.imageSize.width * pWidth)
                        }
                    }else {
                        processorSize = size
                    }
                }else {
                    processorSize = tagerSize
                }
                options += [
                    .onlyLoadFirstFrame,
                    .cacheOriginalImage,
                    .imageProcessor(processorSize),
                    .scaleFactor(UIScreen._scale)
                ]
                if imageAsset.isFade {
                    options += [.fade(0.2)]
                }
            }else {
                if imageAsset.originalLoadMode == .alwaysThumbnail,
                   !forciblyOriginal {
                    if let originalCacheKey,
                       PhotoManager.ImageView.isCached(forKey: originalCacheKey) {
                        url = imageAsset.originalURL
                        cacheKey = imageAsset.originalCacheKey
                    }else {
                        url = imageAsset.thumbnailURL
                        cacheKey = imageAsset.thumbailCacheKey
                    }
                    placeholderImage = UIImage.image(for: imageAsset.placeholder)
                }else {
                    placeholderImage = image
                    url = imageAsset.originalURL
                    cacheKey = imageAsset.originalCacheKey
                }
                options = [.fade(0.2)]
            }
        }else if let videoAsset = asset.networkVideoAsset {
            if let coverImage = videoAsset.coverImage {
                image = coverImage
                completionHandler?(coverImage, asset)
                return nil
            }else if let coverImageURL = videoAsset.coverImageURL {
                url = coverImageURL
                options = [.fade(0.2)]
                placeholderImage = UIImage.image(for: videoAsset.coverPlaceholder)
            }else {
                var videoURL: URL?
                if let key = videoAsset.videoURL?.absoluteString,
                   PhotoTools.isCached(forVideo: key) {
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
                completionHandler?(coverImage, asset)
                return nil
            }
            loadVideoCover = true
            url = videoAsset.videoURL
        }else if let livePhotoAsset = asset.localLivePhoto,
                    !livePhotoAsset.imageURL.isFileURL {
            url = livePhotoAsset.imageURL
        }
        guard let url = url else {
            completionHandler?(nil, asset)
            return nil
        }
        if loadVideoCover {
            return setVideoCover(with: url, placeholder: placeholderImage) { [weak asset] in
                guard let asset else { return }
                switch $0 {
                case .success(let image):
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
                    completionHandler?(image, asset)
                case .failure:
                    completionHandler?(nil, asset)
                }
            }
        }
        return setImage(with: .init(downloadURL: url, cacheKey: cacheKey, indicatorColor: indicatorColor), placeholder: placeholderImage, options: options) { [weak asset] in
            guard let asset else { return }
            progressBlock?($0, asset)
        } completionHandler: { [weak asset] in
            guard let asset else { return }
            switch $0 {
            case .success(let image):
                switch asset.mediaSubType {
                case .networkImage:
                    guard let networkAsset = asset.networkImageAsset else { return }
                    var isGetCache: Bool = false
                    if urlType == .original, networkAsset.originalImageSize.equalTo(.zero) {
                        isGetCache = true
                    }else if networkAsset.imageSize.equalTo(.zero) {
                        isGetCache = true
                    }
                    if isGetCache {
                        asset.networkImageAsset?.imageSize = image.size
                        /// 因为`SDWebImage`获取缩略图时返回的图片比例可能不是原始比例，所以需要重新获取原始的图片比例
                        let cacheKey = PhotoManager.ImageView.getCacheKey(forURL: url)
                        PhotoManager.ImageView.getCacheImage(forKey: cacheKey) { [weak asset] image in
                            guard let asset, let image else { return }
                            asset.networkImageAsset?.imageSize = image.size
                            if urlType == .original {
                                asset.networkImageAsset?.originalImageSize = image.size
                            }
                        }
                    }
                case .networkVideo:
                    asset.networkVideoAsset?.coverImage = image
                    asset.networkVideoAsset?.videoSize = image.size
                case .localLivePhoto:
                    if let livePhoto = asset.localLivePhoto,
                       !livePhoto.imageURL.isFileURL {
                        asset.localLivePhoto?.size = image.size
                    }
                default: break
                }
                completionHandler?(image, asset)
            case .failure:
                completionHandler?(nil, asset)
            }
        }
    }
    
    #if HXPICKER_ENABLE_EDITOR
    private func getEditedImage(
        _ photoAsset: PhotoAsset,
        urlType: DonwloadURLType,
        completionHandler: ((UIImage?, PhotoAsset) -> Void)?
    ) {
        if let photoEdit = photoAsset.photoEditedResult {
            if urlType == .thumbnail {
                image = photoEdit.image
                completionHandler?(photoEdit.image, photoAsset)
            }else {
                do {
                    let imageData = try Data(contentsOf: photoEdit.url)
                    setImageData(imageData)
                }catch {
                    image = photoEdit.image
                }
                completionHandler?(photoEdit.image, photoAsset)
            }
        }else if let videoEdit = photoAsset.videoEditedResult {
            image = videoEdit.coverImage
            completionHandler?(videoEdit.coverImage, photoAsset)
        }
    }
    #endif
    
//    @discardableResult
//    func setVideoCoverImage(
//        for asset: PhotoAsset,
//        imageGenerator: ((AVAssetImageGenerator) -> Void)? = nil,
//        completionHandler: ((UIImage?, PhotoAsset) -> Void)? = nil
//    ) -> Any? {
//        #if HXPICKER_ENABLE_EDITOR
//        if let videoEdit = asset.videoEditedResult {
//            completionHandler?(videoEdit.coverImage, asset)
//            return nil
//        }
//        #endif
//        var videoURL: URL?
//        if let videoAsset = asset.networkVideoAsset {
//            if let coverImage = videoAsset.coverImage {
//                if videoAsset.videoSize.equalTo(.zero) {
//                    asset.networkVideoAsset?.videoSize = coverImage.size
//                }
//                completionHandler?(coverImage, asset)
//                return nil
//            }else {
//                if let key = videoAsset.videoURL?.absoluteString,
//                   PhotoTools.isCached(forVideo: key) {
//                    videoURL = PhotoTools.getVideoCacheURL(for: key)
//                }else {
//                    videoURL = videoAsset.videoURL
//                }
//            }
//        }else if let videoAsset = asset.localVideoAsset {
//            if let coverImage = videoAsset.image {
//                if videoAsset.videoSize.equalTo(.zero) {
//                    asset.localVideoAsset?.videoSize = coverImage.size
//                }
//                completionHandler?(coverImage, asset)
//                return nil
//            }
//            videoURL = videoAsset.videoURL
//        }
//        guard let videoURL = videoURL else {
//            completionHandler?(nil, asset)
//            return nil
//        }
//        return PhotoTools.getVideoThumbnailImage(
//            url: videoURL,
//            atTime: 0.1,
//            imageGenerator: imageGenerator
//        ) { _, image, result in
//            if let image = image {
//                if asset.isNetworkAsset {
//                    asset.networkVideoAsset?.videoSize = image.size
//                    asset.networkVideoAsset?.coverImage = image
//                }else {
//                    asset.localVideoAsset?.videoSize = image.size
//                    asset.localVideoAsset?.image = image
//                }
//            }
//            if result == .cancelled { return }
//            completionHandler?(image, asset)
//        }
//    }
}
