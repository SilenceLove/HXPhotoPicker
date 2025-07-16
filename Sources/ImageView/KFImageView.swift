//
//  KFImageView.swift
//  HXPhotoPickerExample
//
//  Created by Silence on 2025/2/21.
//  Copyright © 2025 Silence. All rights reserved.
//

#if canImport(Kingfisher) && HXPICKER_ENABLE_CORE_IMAGEVIEW_KF
import UIKit
import Kingfisher

public class KFImageView: AnimatedImageView, HXImageViewProtocol {
    
    public func setImageData(_ imageData: Data?) {
        guard let imageData else { return }
        let image: KFCrossPlatformImage? = DefaultImageProcessor.default.process(item: .data(imageData), options: .init([]))
        self.image = image
    }
    
    @discardableResult
    public func setImage(with resource: ImageDownloadResource, placeholder: UIImage?, options: ImageDownloadOptionsInfo?, progressHandler: ((CGFloat) -> Void)?, completionHandler: ((Result<UIImage, ImageDownloadError>) -> Void)?) -> ImageDownloadTask? {
        var kfOptions: KingfisherOptionsInfo = []
        if let options {
            for option in options {
                switch option {
                case .fade(let duration):
                    kfOptions += [.transition(.fade(duration))]
                case .imageProcessor(let size):
                    let imageProcessor = DownsamplingImageProcessor(size: size)
                    kfOptions += [.processor(imageProcessor)]
                case .onlyLoadFirstFrame:
                    kfOptions += [.onlyLoadFirstFrame]
                case .cacheOriginalImage:
                    kfOptions += [.cacheOriginalImage]
                case .memoryCacheExpirationExpired:
                    kfOptions += [.memoryCacheExpiration(.expired)]
                case .scaleFactor(let scale):
                    kfOptions += [.scaleFactor(scale)]
                }
            }
        }
        let imageResource = Kingfisher.ImageResource(downloadURL: resource.downloadURL, cacheKey: resource.cacheKey)
        if let indicatorColor = resource.indicatorColor {
            kf.indicatorType = .activity
            (kf.indicator?.view as? UIActivityIndicatorView)?.color = indicatorColor
        }
        let task = kf.setImage(with: imageResource, placeholder: placeholder, options: kfOptions) { receivedSize, totalSize in
            progressHandler?(CGFloat(receivedSize) / CGFloat(totalSize))
        } completionHandler: {
            switch $0 {
            case .success(let result):
                completionHandler?(.success(result.image))
            case .failure(let error):
                completionHandler?(.failure(error.isTaskCancelled ? .cancel : .error(error)))
            }
        }
        let downloadTask = ImageDownloadTask {
            task?.cancel()
        }
        return downloadTask
    }
    
    public func setVideoCover(with url: URL, placeholder: UIImage?, completionHandler: ((Result<UIImage, ImageDownloadError>) -> Void)?) -> ImageDownloadTask? {
        let provider = AVAssetImageDataProvider(assetURL: url, seconds: 0.1)
        provider.assetImageGenerator.appliesPreferredTrackTransform = true
        let task = KF.dataProvider(provider)
            .placeholder(placeholder)
            .onSuccess { result in
                completionHandler?(.success(result.image))
            }
            .onFailure { error in
                completionHandler?(.failure(error.isTaskCancelled ? .cancel : .error(error)))
            }
            .set(to: self)
        let downloadTask = ImageDownloadTask {
            task?.cancel()
        }
        return downloadTask
    }
    
    @discardableResult
    public static func download(with resource: ImageDownloadResource, options: ImageDownloadOptionsInfo?, progressHandler: ((CGFloat) -> Void)?, completionHandler: ((Result<ImageDownloadResult, ImageDownloadError>) -> Void)?) -> ImageDownloadTask? {
        let key = resource.cacheKey
        var kfOptions: KingfisherOptionsInfo = []
        if let options {
            for option in options {
                switch option {
                case .fade(let duration):
                    kfOptions += [.transition(.fade(duration))]
                case .imageProcessor(let size):
                    let imageProcessor = DownsamplingImageProcessor(size: size)
                    kfOptions += [.processor(imageProcessor)]
                case .onlyLoadFirstFrame:
                    kfOptions += [.onlyLoadFirstFrame]
                case .cacheOriginalImage:
                    kfOptions += [.cacheOriginalImage]
                case .memoryCacheExpirationExpired:
                    kfOptions += [.memoryCacheExpiration(.expired)]
                case .scaleFactor(let scale):
                    kfOptions += [.scaleFactor(scale)]
                }
            }
        }
        if ImageCache.default.isCached(forKey: key) {
            ImageCache.default.retrieveImage(
                forKey: key,
                options: kfOptions
            ) { (result) in
                switch result {
                case .success(let value):
                    if let data = value.image?.kf.gifRepresentation() {
                        completionHandler?(.success(.init(imageData: data)))
                    }else if let image = value.image {
                        completionHandler?(.success(.init(image: image)))
                    }else {
                        completionHandler?(.failure(.error(nil)))
                    }
                case .failure(let error):
                    completionHandler?(.failure(.error(error)))
                }
            }
            return nil
        }
        let task =  ImageDownloader.default.downloadImage(with: resource.downloadURL, options: kfOptions) { receivedSize, totalSize in
            let progress = CGFloat(receivedSize) / CGFloat(totalSize)
            progressHandler?(progress)
        } completionHandler: {
            switch $0 {
            case .success(let value):
                DispatchQueue.global().async {
                    if let gifImage = DefaultImageProcessor.default.process(
                        item: .data(value.originalData),
                        options: .init([])
                    ) {
                        ImageCache.default.store(
                            gifImage,
                            original: value.originalData,
                            forKey: key
                        )
                        DispatchQueue.main.async {
                            completionHandler?(.success(.init( imageData: value.originalData)))
                        }
                        return
                    }
                    ImageCache.default.store(
                        value.image,
                        original: value.originalData,
                        forKey: key
                    )
                    DispatchQueue.main.async {
                        completionHandler?(.success(.init(image: value.image)))
                    }
                }
            case .failure(let error):
                completionHandler?(.failure(.error(error)))
            }
        }
        let downloadTask = ImageDownloadTask {
            task?.cancel()
        }
        return downloadTask
    }
    
    public func _startAnimating() {
        startAnimating()
    }
    
    public func _stopAnimating() {
        stopAnimating()
    }
    
    public static func getCacheKey(forURL url: URL) -> String {
        url.cacheKey
    }
    
    public static func getCachePath(forKey key: String) -> String {
        ImageCache.default.cachePath(forKey: key)
    }
    
    public static func isCached(forKey key: String) -> Bool {
        ImageCache.default.isCached(forKey: key)
    }
    
    public static func getInMemoryCacheImage(forKey key: String) -> UIImage? {
        ImageCache.default.retrieveImageInMemoryCache(forKey: key)
    }
    
    public static func getCacheImage(forKey key: String, completionHandler: ((UIImage?) -> Void)?) {
        ImageCache.default.retrieveImage(forKey: key, options: []) {
            switch $0 {
            case .success(let result):
                completionHandler?(result.image)
            case .failure:
                completionHandler?(nil)
            }
        }
    }
}
#endif
