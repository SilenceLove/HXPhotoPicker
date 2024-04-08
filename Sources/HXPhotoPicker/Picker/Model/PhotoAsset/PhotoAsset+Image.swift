//
//  PhotoAsset+Image.swift
//  HXPhotoPicker
//
//  Created by Silence on 2024/3/25.
//  Copyright © 2024 Silence. All rights reserved.
//

import UIKit
import Photos
#if canImport(Kingfisher)
import Kingfisher
#endif

public extension PhotoAsset {
    
    /// 原图
    /// 如果为网络图片时，获取的是缩略地址的图片，也可能为nil
    /// 如果为网络视频，则为nil
    var originalImage: UIImage? {
        #if HXPICKER_ENABLE_EDITOR
        if editedResult != nil {
            return getEditedImage()
        }
        #endif
        guard let phAsset = phAsset else {
            if mediaType == .photo {
                if let livePhoto = localLivePhoto {
                    if livePhoto.imageURL.isFileURL {
                        return UIImage(contentsOfFile: livePhoto.imageURL.path)
                    }else {
                        #if canImport(Kingfisher)
                        if ImageCache.default.isCached(forKey: livePhoto.imageURL.cacheKey) {
                            return ImageCache.default.retrieveImageInMemoryCache(
                                forKey: livePhoto.imageURL.cacheKey,
                                options: []
                            )
                        }
                        #endif
                        return nil
                    }
                }
                if let image = localImageAsset?.image {
                    return image
                }else if let imageURL = localImageAsset?.imageURL {
                    let image = UIImage(contentsOfFile: imageURL.path)
                    localImageAsset?.image = image
                }
                return localImageAsset?.image
            }else {
                checkLoaclVideoImage()
                return localVideoAsset?.image
            }
        }
        let options = PHImageRequestOptions.init()
        options.isSynchronous = true
        options.isNetworkAccessAllowed = true
        options.deliveryMode = .highQualityFormat
        if mediaSubType == .imageAnimated {
            options.version = .original
        }
        var originalImage: UIImage?
        let isGif = phAsset.isImageAnimated
        AssetManager.requestImageData(for: phAsset, options: options) { (result) in
            switch result {
            case .success(let dataResult):
                let image = UIImage(data: dataResult.imageData)?.normalizedImage()
                if isGif && self.mediaSubType != .imageAnimated {
                    if let data = PhotoTools.getImageData(for: image) {
                        originalImage = UIImage(data: data)
                    }
                }else {
                    originalImage = image
                }
            default:
                break
            }
        }
        return originalImage
    }
    
    /// 获取image，视频为封面图片
    /// - Parameters:
    ///   - compressionQuality: 压缩参数 0-1
    ///   - resolution: 缩小到指定分辨率，优先级小于`compressionQuality`
    ///   - completion: 获取完成
    func getImage(
        compressionQuality: CGFloat? = nil,
        completion: @escaping (UIImage?) -> Void
    ) {
        #if canImport(Kingfisher)
        let hasEdited: Bool
        #if HXPICKER_ENABLE_EDITOR
        hasEdited = editedResult != nil
        #else
        hasEdited = false
        #endif
        if isNetworkAsset && !hasEdited {
            getNetworkImage { image in
                guard let compressionQuality = compressionQuality else {
                    completion(image)
                    return
                }
                DispatchQueue.global().async {
                    guard let imageData = PhotoTools.getImageData(for: image),
                          let data = PhotoTools.imageCompress(
                            imageData,
                              compressionQuality: compressionQuality
                          ),
                          let image = UIImage(data: data)?.normalizedImage()
                    else {
                        DispatchQueue.main.async {
                            completion(nil)
                        }
                        return
                    }
                    DispatchQueue.main.async {
                        completion(image)
                    }
                }
            }
            return
        }
        #endif
        requestImage(compressionScale: compressionQuality) { image, _ in
            completion(image)
        }
    }
    
    /// 获取image，视频为封面图片
    /// - Parameters:
    ///   - targetSize: 指定`imageSize`
    ///   - targetMode: 裁剪模式
    ///   - completion: 获取完成
    func getImage(
        targetSize: CGSize,
        targetMode: HX.ImageTargetMode = .fill,
        completion: @escaping (UIImage?, PhotoAsset) -> Void
    ) {
        #if canImport(Kingfisher)
        let hasEdited: Bool
        #if HXPICKER_ENABLE_EDITOR
        hasEdited = editedResult != nil
        #else
        hasEdited = false
        #endif
        if isNetworkAsset && !hasEdited {
            getNetworkImage { image in
                DispatchQueue.global().async {
                    let image = image?.scaleToFillSize(size: targetSize, mode: targetMode)
                    DispatchQueue.main.async {
                        completion(image, self)
                    }
                }
            }
            return
        }
        #endif
        requestImage(targetSize: targetSize, targetMode: targetMode) {
            completion($0, $1)
        }
    }
    
    /// 获取 imageData
    /// - Parameter completion: 获取完成
    func getImageData(completion: @escaping (Result<AssetManager.ImageDataResult, AssetError>) -> Void) {
        requestImageData { _, result in
            completion(result)
        }
    }
    
}

extension PhotoAsset {
    
    func requestAssetImageURL(
        toFile fileURL: URL? = nil,
        compressionQuality: CGFloat? = nil,
        filterEditor: Bool = false,
        resultHandler: @escaping AssetURLCompletion
    ) {
        #if HXPICKER_ENABLE_EDITOR
        if (editedResult != nil) && !filterEditor {
            getEditedImageURL(
                toFile: fileURL,
                compressionQuality: compressionQuality,
                resultHandler: resultHandler
            )
            return
        }
        #endif
        guard let phAsset = phAsset else {
            resultHandler(
                .failure(
                    .invalidPHAsset
                )
            )
            return
        }
        if mediaType == .video {
            getVideoCoverURL(
                toFile: fileURL,
                resultHandler: resultHandler
            )
            return
        }
        let isGif = phAsset.isImageAnimated
        var imageFileURL: URL
        if let fileURL = fileURL {
            imageFileURL = fileURL
        }else {
            var suffix: String
            if mediaSubType == .imageAnimated {
                suffix = "gif"
            }else {
                if let compressionQuality, compressionQuality < 1, !isGif {
                    suffix = "jpeg"
                }else {
                    if let photoFormat = photoFormat, !isGif {
                        suffix = photoFormat
                    }else {
                        suffix = "png"
                    }
                }
            }
            imageFileURL = PhotoTools.getTmpURL(for: suffix)
        }
        AssetManager.requestImageURL(
            for: phAsset,
            toFile: imageFileURL
        ) { (result) in
            switch result {
            case .success(let imageURL):
                self.requestAssetImageURL(
                    imageFileURL: imageFileURL,
                    resultURL: imageURL,
                    isGif: isGif,
                    compressionQuality: compressionQuality,
                    resultHandler: resultHandler
                )
            case .failure(let error):
                resultHandler(.failure(error))
            }
        }
    }
    
    private func requestAssetImageURL(
        imageFileURL: URL,
        resultURL: URL,
        isGif: Bool,
        compressionQuality: CGFloat?,
        resultHandler: @escaping AssetURLCompletion
    ) {
        let imageURL = resultURL
        func resultSuccess(_ url: URL) {
            DispatchQueue.main.async {
                resultHandler(
                    .success(
                        .init(
                            url: url,
                            urlType: .local,
                            mediaType: .photo
                        )
                    )
                )
            }
        }
        func converImageURL(_ url: URL) -> URL {
            let imageURL: URL
            if url.pathExtension.uppercased() == "HEIC" {
                let path = url.path.replacingOccurrences(
                    of: url.pathExtension,
                    with: imageFileURL.pathExtension
                )
                imageURL = .init(fileURLWithPath: path)
            }else {
                imageURL = url
            }
            return imageURL
        }
        if isGif && self.mediaSubType != .imageAnimated {
            DispatchQueue.global().async {
                // 本质上是gif，需要变成静态图
                guard let imageData = try? Data(contentsOf: imageURL),
                      let image = UIImage(data: imageData) else {
                    DispatchQueue.main.async {
                        resultHandler(.failure(.fileWriteFailed))
                    }
                    return
                }
                if let compressionQuality = compressionQuality, compressionQuality < 1 {
                    if FileManager.default.fileExists(atPath: imageURL.path) {
                        try? FileManager.default.removeItem(at: imageURL)
                    }
                    let toURL = converImageURL(imageURL)
                    if let data = PhotoTools.imageCompress(
                        imageData,
                        compressionQuality: compressionQuality
                    ),
                       let url = PhotoTools.write(
                        toFile: toURL,
                        imageData: data
                    ) {
                        resultSuccess(url)
                    }else {
                        DispatchQueue.main.async {
                            resultHandler(.failure(.imageCompressionFailed))
                        }
                    }
                    return
                }
                do {
                    let toURL = converImageURL(imageURL)
                    let imageData = PhotoTools.getImageData(for: image)
                    if FileManager.default.fileExists(atPath: imageURL.path) {
                        try FileManager.default.removeItem(at: imageURL)
                    }
                    try imageData?.write(to: toURL)
                    resultSuccess(toURL)
                } catch {
                    DispatchQueue.main.async {
                        resultHandler(.failure(.fileWriteFailed))
                    }
                }
            }
            return
        }else if !isGif {
            if let compressionQuality = compressionQuality, compressionQuality < 1 {
                DispatchQueue.global().async {
                    guard let imageData = try? Data(contentsOf: imageURL) else {
                        DispatchQueue.main.async {
                            resultHandler(.failure(.imageCompressionFailed))
                        }
                        return
                    }
                    if FileManager.default.fileExists(atPath: imageURL.path) {
                        try? FileManager.default.removeItem(at: imageURL)
                    }
                    let toURL = converImageURL(imageURL)
                    if let data = PhotoTools.imageCompress(
                        imageData,
                        compressionQuality: compressionQuality
                    ),
                       let url = PhotoTools.write(
                        toFile: toURL,
                        imageData: data
                    ) {
                        resultSuccess(url)
                    }else {
                        DispatchQueue.main.async {
                            resultHandler(.failure(.imageCompressionFailed))
                        }
                    }
                }
                return
            }
        }
        resultSuccess(imageURL)
    }
    
}
