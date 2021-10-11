//
//  Picker+UIImageView.swift
//  HXPHPicker
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
    // swiftlint:disable function_body_length
    func setImage(
        for asset: PhotoAsset,
        urlType: DonwloadURLType,
        progressBlock: DownloadProgressBlock? = nil,
        downloadTask: ((Kingfisher.DownloadTask?) -> Void)? = nil,
        completionHandler: ((UIImage?, KingfisherError?, PhotoAsset) -> Void)? = nil
    ) -> Any? {
        // swiftlint:enable function_body_length
        #if HXPICKER_ENABLE_EDITOR
        if let photoEdit = asset.photoEdit {
            if urlType == .thumbnail {
                image = photoEdit.editedImage
                completionHandler?(photoEdit.editedImage, nil, asset)
            }else {
                do {
                    let imageData = try Data.init(contentsOf: photoEdit.editedImageURL)
                    let img = DefaultImageProcessor.default.process(item: .data(imageData), options: .init([]))!
                    let kfView = self as? AnimatedImageView
                    kfView?.image = img
                }catch {
                    image = photoEdit.editedImage
                }
                completionHandler?(photoEdit.editedImage, nil, asset)
            }
            return nil
        }else if let videoEdit = asset.videoEdit {
            image = videoEdit.coverImage
            completionHandler?(videoEdit.coverImage, nil, asset)
            return nil
        }
        #endif
        let isThumbnail = urlType == .thumbnail
        if isThumbnail {
            kf.indicatorType = .activity
        }
        var url = URL(string: "")
        var placeholderImage: UIImage?
        var options: KingfisherOptionsInfo = []
        var loadVideoCover: Bool = false
        if let imageAsset = asset.networkImageAsset {
            url = isThumbnail ? imageAsset.thumbnailURL : imageAsset.originalURL
            placeholderImage = UIImage.image(for: imageAsset.placeholder)
            let processor = DownsamplingImageProcessor(size: imageAsset.thumbnailSize)
            options = isThumbnail ?
                [.onlyLoadFirstFrame, .processor(processor), .cacheOriginalImage] :
                [.backgroundDecode]
        }else if let videoAsset = asset.networkVideoAsset {
            if let coverImage = videoAsset.coverImage {
                image = coverImage
                completionHandler?(coverImage, nil, asset)
                return nil
            }else if let coverImageURL = videoAsset.coverImageURL {
                url = coverImageURL
                options = []
            }else {
                let key = videoAsset.videoURL.absoluteString
                var videoURL: URL
                if PhotoTools.isCached(forVideo: key) {
                    videoURL = PhotoTools.getVideoCacheURL(for: key)
                }else {
                    videoURL = videoAsset.videoURL
                }
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
        }
        if let url = url, loadVideoCover {
//            func loadVideoCover() {
                let provider = AVAssetImageDataProvider(assetURL: url, seconds: 0.1)
                provider.assetImageGenerator.appliesPreferredTrackTransform = true
                let task = KF.dataProvider(provider)
                    .onSuccess { (result) in
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
                    .onFailure { (error) in
                        completionHandler?(nil, error, asset)
                    }
                    .set(to: self)
//                downloadTask?(task)
                return task
//            }
//            let avAsset = AVURLAsset(url: url)
//            avAsset.loadValuesAsynchronously(forKeys: ["duration"]) {
//                DispatchQueue.main.async {
//                    loadVideoCover()
//                }
//            }
//            return avAsset
        }
        return kf.setImage(
            with: url,
            placeholder: placeholderImage,
            options: options,
            progressBlock: progressBlock
        ) { (result) in
            switch result {
            case .success(let value):
                switch asset.mediaSubType {
                case .networkImage(_):
                    if asset.localImageAsset == nil {
                        let localImageAsset = LocalImageAsset(image: value.image)
                        asset.localImageAsset = localImageAsset
                    }
                    asset.networkImageAsset?.imageSize = value.image.size
                    if asset.localImageType != .original && !isThumbnail {
                        if let imageData = value.image.kf.data(format: asset.mediaSubType.isGif ? .GIF : .unknown) {
                            asset.networkImageAsset?.fileSize = imageData.count
                        }
                        asset.localImageType = urlType
                    }
                case .networkVideo:
                    asset.networkVideoAsset?.coverImage = value.image
                default: break
                }
                completionHandler?(value.image, nil, asset)
            case .failure(let error):
                completionHandler?(nil, error, asset)
            }
        }
    }
    #else
    @discardableResult
    func setVideoCoverImage(
        for asset: PhotoAsset,
        imageGenerator: ((AVAssetImageGenerator) -> Void)? = nil,
        completionHandler: ((UIImage?, PhotoAsset) -> Void)? = nil
    ) -> Any? {
        #if HXPICKER_ENABLE_EDITOR
        if let videoEdit = asset.videoEdit {
            completionHandler?(videoEdit.coverImage, asset)
            return nil
        }
        #endif
        var videoURL: URL?
        if let videoAsset = asset.networkVideoAsset {
            if let coverImage = videoAsset.coverImage {
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
            if result == .cancelled { return }
            if asset.isNetworkAsset {
                asset.networkVideoAsset?.coverImage = image
            }else {
                asset.localVideoAsset?.image = image
            }
            completionHandler?(image, asset)
        }
    }
    #endif
}

extension ImageView {
    
    #if canImport(Kingfisher)
    @discardableResult
    func setImage(
        for asset: PhotoAsset,
        urlType: DonwloadURLType,
        progressBlock: DownloadProgressBlock? = nil,
        downloadTask: ((Kingfisher.DownloadTask?) -> Void)? = nil,
        completionHandler: ((UIImage?, KingfisherError?, PhotoAsset) -> Void)? = nil
    ) -> Any? {
        imageView.setImage(
            for: asset,
            urlType: urlType,
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
