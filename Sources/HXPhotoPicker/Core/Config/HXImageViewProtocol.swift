//
//  HXImageViewProtocol.swift
//  HXPhotoPickerExample
//
//  Created by Silence on 2025/2/21.
//  Copyright © 2025 Silence. All rights reserved.
//

import UIKit
import AVFoundation

/// GIF 参考 https://github.com/SilenceLove/HXPhotoPicker/tree/master/Sources/ImageView/GIFImageView.swift
/// 使用 `Kingfisher`
/// 参考 https://github.com/SilenceLove/HXPhotoPicker/tree/master/Sources/ImageView/KFImageView.swift
/// PickerConfiguration.imageViewProtocol  = KFImageView.self
/// 使用 `SDWebImage`
/// 参考 https://github.com/SilenceLove/HXPhotoPicker/tree/master/Sources/ImageView/SDImageView.swift
/// PickerConfiguration.imageViewProtocol  = SDImageView.self
public protocol HXImageViewProtocol: UIImageView {
    func setImageData(_ imageData: Data?)
    @discardableResult
    func setImage(with resource: ImageDownloadResource, placeholder: UIImage?, options: ImageDownloadOptionsInfo?, progressHandler: ((CGFloat) -> Void)?, completionHandler: ((Result<UIImage, ImageDownloadError>) -> Void)?) -> ImageDownloadTask?
    
    @discardableResult
    func setVideoCover(with url: URL, placeholder: UIImage?, completionHandler: ((Result<UIImage, ImageDownloadError>) -> Void)?) -> ImageDownloadTask?
    
    func _startAnimating()
    func _stopAnimating()
    
    @discardableResult
    static func download(with resource: ImageDownloadResource, options: ImageDownloadOptionsInfo?, progressHandler: ((CGFloat) -> Void)?, completionHandler: ((Result<ImageDownloadResult, ImageDownloadError>) -> Void)?) -> ImageDownloadTask?
    
    static func getCacheKey(forURL url: URL) -> String
    static func getCachePath(forKey key: String) -> String
    static func isCached(forKey key: String) -> Bool
    static func getInMemoryCacheImage(forKey key: String) -> UIImage?
    static func getCacheImage(forKey key: String, completionHandler: ((UIImage?) -> Void)?)
}

public extension HXImageViewProtocol {
    func setVideoCover(with url: URL, placeholder: UIImage?, completionHandler: ((Result<UIImage, ImageDownloadError>) -> Void)?) -> ImageDownloadTask? {
        weak var imageGenerator: AVAssetImageGenerator?
        let avAsset = PhotoTools.getVideoThumbnailImage(url: url, atTime: 0.1) {
            imageGenerator = $0
        } completion: { _, image, _ in
            guard let image else {
                completionHandler?(.failure(.error(nil)))
                return
            }
            completionHandler?(.success(image))
        }
        let task = ImageDownloadTask {
            avAsset.cancelLoading()
            imageGenerator?.cancelAllCGImageGeneration()
        }
        return task
    }
    
    func setImage(with resource: ImageDownloadResource, placeholder: UIImage?, options: ImageDownloadOptionsInfo?, progressHandler: ((CGFloat) -> Void)?, completionHandler: ((Result<UIImage, ImageDownloadError>) -> Void)?) -> ImageDownloadTask? {
        assertionFailure("请实现此方法用于加载网络图片")
        return nil
    }
    
    static func download(with resource: ImageDownloadResource, options: ImageDownloadOptionsInfo?, progressHandler: ((CGFloat) -> Void)?, completionHandler: ((Result<ImageDownloadResult, ImageDownloadError>) -> Void)?) -> ImageDownloadTask? {
        assertionFailure("请实现此方法用于加载网络图片")
        return nil
    }
    
    static func getCacheKey(forURL url: URL) -> String {
        assertionFailure("请实现此方法用于加载网络图片")
        return ""
    }
    
    static func getCachePath(forKey key: String) -> String {
        assertionFailure("请实现此方法用于加载网络图片")
        return ""
    }
    
    static func isCached(forKey key: String) -> Bool {
        assertionFailure("请实现此方法用于加载网络图片")
        return false
    }
    
    static func getInMemoryCacheImage(forKey key: String) -> UIImage? {
        assertionFailure("请实现此方法用于加载网络图片")
        return nil
    }
    
    static func getCacheImage(forKey key: String, completionHandler: ((UIImage?) -> Void)?) {
        assertionFailure("请实现此方法用于加载网络图片")
    }
}

public typealias ImageDownloadOptionsInfo = [ImageDownloadOptionsInfoItem]

public enum ImageDownloadOptionsInfoItem: Sendable {
    case onlyLoadFirstFrame
    case cacheOriginalImage
    case fade(TimeInterval)
    case imageProcessor(CGSize)
    case memoryCacheExpirationExpired
    case scaleFactor(CGFloat)
}

public struct ImageDownloadResource {
    public init(downloadURL: URL, cacheKey: String? = nil, indicatorColor: UIColor? = nil) {
        self.downloadURL = downloadURL
        self.cacheKey = cacheKey ?? PhotoManager.ImageView.getCacheKey(forURL: downloadURL)
        self.indicatorColor = indicatorColor
    }
    
    public let cacheKey: String
    public let downloadURL: URL
    public let indicatorColor: UIColor?
}

public enum ImageDownloadError: Error {
    case error(Error?)
    case cancel
}

public struct ImageDownloadTask {
    public let cancelHandler: () -> Void
    public init(cancelHandler: @escaping () -> Void) {
        self.cancelHandler = cancelHandler
    }
}

public struct ImageDownloadResult {
    public let image: UIImage?
    public let imageData: Data?
    
    public init(image: UIImage) {
        self.image = image
        self.imageData = nil
    }
    
    public init(imageData: Data) {
        self.image = nil
        self.imageData = imageData
    }
}

public class HXImageView: UIImageView, HXImageViewProtocol {
    
    /// GIF 参考 https://github.com/SilenceLove/HXPhotoPicker/tree/master/Sources/ImageView/GIFImageView.swift
    public func setImageData(_ imageData: Data?) {
        guard let imageData else { return }
        image = .init(data: imageData)
    }
    
    public func _startAnimating() {
        
    }
    
    public func _stopAnimating() {
        
    }
}
