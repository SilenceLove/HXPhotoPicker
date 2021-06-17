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
    func setImage(
        for asset: PhotoAsset,
        urlType: DonwloadURLType,
        progressBlock: DownloadProgressBlock? = nil,
        completionHandler: ((UIImage?, KingfisherError?, PhotoAsset) -> Void)? = nil) -> Kingfisher.DownloadTask? {
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
        var placeholderImage: UIImage? = nil
        var options: KingfisherOptionsInfo = []
        var loadVideoCover: Bool = false
        if let imageAsset = asset.networkImageAsset {
            url = isThumbnail ? imageAsset.thumbnailURL : imageAsset.originalURL
            placeholderImage = UIImage.image(for: imageAsset.placeholder)
            let processor = DownsamplingImageProcessor(size: imageAsset.thumbnailSize)
            options = isThumbnail ? [.onlyLoadFirstFrame, .processor(processor), .cacheOriginalImage] : [.backgroundDecode]
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
        if loadVideoCover {
//            let generator = AVAssetImageGenerator(asset: .init(url: url!))
//            generator.appliesPreferredTrackTransform = true
//            generator.requestedTimeToleranceBefore = .zero
//            generator.requestedTimeToleranceAfter = .zero
//            let provider = AVAssetImageDataProvider(assetImageGenerator: generator, time: .init(seconds: 0.15, preferredTimescale: 600))
            let provider = AVAssetImageDataProvider(assetURL: url!, seconds: 0.15)
            return KF.dataProvider(provider)
                    .onSuccess { (result) in
                        if asset.isNetworkAsset {
                            asset.networkVideoAsset?.coverImage = result.image
                        }else {
                            asset.localVideoAsset?.image = result.image
                        }
                        completionHandler?(result.image, nil, asset)
                    }
                    .onFailure { (error) in
                        completionHandler?(nil, error, asset)
                    }
                    .set(to: self)
        }
        
        return kf.setImage(with: url, placeholder: placeholderImage, options: options, progressBlock: progressBlock) { (result) in
            switch result {
            case .success(let value):
                switch asset.mediaSubType {
                case .networkImage(_):
                    if asset.localImageAsset == nil {
                        let localImageAsset = LocalImageAsset.init(image: value.image)
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
    func setVideoCoverImage(for asset: PhotoAsset,
                            completionHandler: ((UIImage?, PhotoAsset) -> Void)? = nil) {
        #if HXPICKER_ENABLE_EDITOR
        if let videoEdit = asset.videoEdit {
            completionHandler?(videoEdit.coverImage, asset)
            return
        }
        #endif
        var videoURL: URL? = nil
        if let videoAsset = asset.networkVideoAsset {
            if let coverImage = videoAsset.coverImage {
                completionHandler?(coverImage, asset)
                return
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
                return
            }
            videoURL = videoAsset.videoURL
        }else {
            completionHandler?(nil, asset)
            return
        }
        PhotoTools.getVideoThumbnailImage(url: videoURL!, atTime: 0.1) { (videoURL, image) in
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
