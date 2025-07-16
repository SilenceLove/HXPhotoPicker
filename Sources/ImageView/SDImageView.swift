//
//  SDImageView.swift
//  HXPhotoPickerExample
//
//  Created by Silence on 2025/2/21.
//  Copyright © 2025 Silence. All rights reserved.
//

#if canImport(SDWebImage) && HXPICKER_ENABLE_CORE_IMAGEVIEW_SD
import UIKit
import SDWebImage
import AVFoundation

public class SDImageView: SDAnimatedImageView, HXImageViewProtocol {
    
    public func setImageData(_ imageData: Data?) {
        guard let imageData else { return }
        let image = SDAnimatedImage(data: imageData)
        self.image = image
    }
    
    @discardableResult
    public func setImage(with resource: ImageDownloadResource, placeholder: UIImage?, options: ImageDownloadOptionsInfo?, progressHandler: ((CGFloat) -> Void)?, completionHandler: ((Result<UIImage, ImageDownloadError>) -> Void)?) -> ImageDownloadTask? {
        var sdOptions: SDWebImageOptions = []
        var context: [SDWebImageContextOption: Any] = [:]
        if let options {
            for option in options {
                switch option {
                case .imageProcessor(let size):
                    let imageProcessor = SDImageResizingTransformer(size: size, scaleMode: .aspectFill)
                    context[.imageTransformer] = imageProcessor
                case .onlyLoadFirstFrame:
                    sdOptions.insert(.decodeFirstFrameOnly)
                case .memoryCacheExpirationExpired:
                    sdOptions.insert(.refreshCached)
                case .cacheOriginalImage, .fade, .scaleFactor:
                    break
                }
            }
        }
        sd_setImage(with: resource.downloadURL, placeholderImage: placeholder, options: sdOptions, context: context) { receivedSize, totalSize, _ in
            let progress = CGFloat(receivedSize) / CGFloat(totalSize)
            DispatchQueue.main.async {
                progressHandler?(progress)
            }
        } completed: { image, error, cacheType, sourceURL in
            if let image {
                completionHandler?(.success(image))
            }else {
                if let error = error as? NSError, error.code == NSURLErrorCancelled {
                    completionHandler?(.failure(.cancel))
                    return
                }
                completionHandler?(.failure(.error(error)))
            }
        }
        let downloadTask = ImageDownloadTask { [weak self] in
            self?.sd_cancelCurrentImageLoad()
        }
        return downloadTask
    }
    
    @discardableResult
    public func setVideoCover(with url: URL, placeholder: UIImage?, completionHandler: ((Result<UIImage, ImageDownloadError>) -> Void)?) -> ImageDownloadTask? {
        let cacheKey = url.absoluteString
        if SDImageView.isCached(forKey: cacheKey) {
            SDImageCache.shared.queryImage(forKey: cacheKey, options: [], context: nil) { (image, data, _) in
                if let image {
                    completionHandler?(.success(image))
                }else {
                    completionHandler?(.failure(.error(nil)))
                }
            }
            return nil
        }
        var imageGenerator: AVAssetImageGenerator?
        let avAsset = PhotoTools.getVideoThumbnailImage(url: url, atTime: 0.1) {
            imageGenerator = $0
        } completion: { _, image, _ in
            guard let image else {
                completionHandler?(.failure(.error(nil)))
                return
            }
            SDImageCache.shared.store(image, imageData: nil, forKey: cacheKey, cacheType: .all) {
                DispatchQueue.main.async {
                    completionHandler?(.success(image))
                }
            }
        }
        let task = ImageDownloadTask {
            avAsset.cancelLoading()
            imageGenerator?.cancelAllCGImageGeneration()
        }
        return task
    }
    
    @discardableResult
    public static func download(with resource: ImageDownloadResource, options: ImageDownloadOptionsInfo?, progressHandler: ((CGFloat) -> Void)?, completionHandler: ((Result<ImageDownloadResult, ImageDownloadError>) -> Void)?) -> ImageDownloadTask? {
        var sdOptions: SDWebImageDownloaderOptions = []
        var context: [SDWebImageContextOption: Any] = [:]
        if let options {
            for option in options {
                switch option {
                case .imageProcessor(let size):
                    let imageProcessor = SDImageResizingTransformer(size: size, scaleMode: .aspectFill)
                    context[.imageTransformer] = imageProcessor
                case .onlyLoadFirstFrame:
                    sdOptions.insert(.decodeFirstFrameOnly)
                default:
                    break
                }
            }
        }
        let key = resource.cacheKey
        if SDImageView.isCached(forKey: key) {
            SDImageCache.shared.queryImage(forKey: key, options: [], context: nil) { (image, data, _) in
                if let data = data  {
                    completionHandler?(.success(.init(imageData: data)))
                } else if let image = image as? SDAnimatedImage, let data = image.animatedImageData {
                    completionHandler?(.success(.init(imageData: data)))
                } else if let image {
                    completionHandler?(.success(.init(image: image)))
                } else {
                    completionHandler?(.failure(.error(nil)))
                }
            }
            return nil
        }
        let operation = SDWebImageDownloader.shared.downloadImage(
            with: resource.downloadURL,
            options: sdOptions,
            context: context,
            progress: { receivedSize, totalSize, _ in
                let progress = CGFloat(receivedSize) / CGFloat(totalSize)
                DispatchQueue.main.async {
                    progressHandler?(progress)
                }
            },
            completed: { image, data, error, finished in
                guard let data = data, finished, error == nil else {
                    completionHandler?(.failure(.error(error)))
                    return
                }
                DispatchQueue.global().async {
                    let format = NSData.sd_imageFormat(forImageData: data)
                    if format == SDImageFormat.GIF, let gifImage = SDAnimatedImage(data: data) {
                        SDImageCache.shared.store(gifImage, imageData: data, forKey: key, options: [], context: nil, cacheType: .all) {
                            DispatchQueue.main.async {
                                completionHandler?(.success(.init(imageData: data)))
                            }
                        }
                        return
                    }
                    if let image = image {
                        SDImageCache.shared.store(image, imageData: data, forKey: key, options: [], context: nil, cacheType: .all) {
                            DispatchQueue.main.async {
                                completionHandler?(.success(.init(image: image)))
                            }
                        }
                    }
                }
            }
        )
        let downloadTask = ImageDownloadTask {
            operation?.cancel()
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
        SDWebImageManager.shared.cacheKey(for: url) ?? ""
    }
    
    public static func getCachePath(forKey key: String) -> String {
        SDImageCache.shared.cachePath(forKey: key) ?? ""
    }
    
    public static func isCached(forKey key: String) -> Bool {
        FileManager.default.fileExists(atPath: getCachePath(forKey: key))
    }
    
    public static func getInMemoryCacheImage(forKey key: String) -> UIImage? {
        SDImageCache.shared.imageFromMemoryCache(forKey: key)
    }
    
    public static func getCacheImage(forKey key: String, completionHandler: ((UIImage?) -> Void)?) {
        SDImageCache.shared.queryImage(forKey: key, context: nil, cacheType: .all) { image, data, _ in
            if let data, let image = SDAnimatedImage(data: data) {
                completionHandler?(image)
            }else if let image {
                completionHandler?(image)
            }else {
                completionHandler?(nil)
            }
        }
    }
}
#endif
