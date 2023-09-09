//
//  AssetManager+LivePhotoURL.swift
//  HXPhotoPicker
//
//  Created by Slience on 2021/1/8.
//

import UIKit
import Photos

public extension AssetManager {
    
    // MARK: 获取LivePhoto里的图片Data和视频地址
    static func requestLivePhoto(
        content asset: PHAsset,
        imageDataHandler: @escaping (Data?) -> Void,
        videoHandler: @escaping (URL?) -> Void,
        completionHandler: @escaping (LivePhotoError?) -> Void
    ) {
        if #available(iOS 9.1, *) {
            requestLivePhoto(
                for: asset,
                targetSize: PHImageManagerMaximumSize
            ) { livePhoto, _, _ in
                guard let livePhoto = livePhoto else {
                    completionHandler(
                        .allError(
                            PhotoError.error(
                                    type: .imageEmpty,
                                message: "livePhoto为nil，获取失败"
                            ),
                            PhotoError.error(
                                type: .videoEmpty,
                                message: "livePhoto为nil，获取失败"
                            )
                        )
                    )
                    return
                }
                let assetResources: [PHAssetResource] = PHAssetResource.assetResources(for: livePhoto)
                if assetResources.isEmpty {
                    completionHandler(
                        .allError(
                            PhotoError.error(
                                type: .imageEmpty,
                                message: "assetResources为nil，获取失败"
                            ),
                            PhotoError.error(
                                type: .videoEmpty,
                                message: "assetResources为nil，获取失败"
                            )
                        )
                    )
                    return
                }
                let options: PHAssetResourceRequestOptions = .init()
                options.isNetworkAccessAllowed = true
                var imageCompletion = false
                var imageError: Error?
                var videoCompletion = false
                var videoError: Error?
                var imageData: Data?
                let videoURL: URL = PhotoTools.getVideoTmpURL()
                let callback = { (imageError: Error?, videoError: Error?) in
                    if imageError != nil && videoError != nil {
                        completionHandler(.allError(imageError, videoError))
                    }else if imageError != nil {
                        completionHandler(.imageError(imageError))
                    }else if videoError != nil {
                        completionHandler(.videoError(videoError))
                    }else {
                        completionHandler(nil)
                    }
                }
                var hasAdjustmentData: Bool = false
                for assetResource in assetResources where
                    assetResource.type == .adjustmentData {
                    hasAdjustmentData = true
                    break
                }
                for assetResource in assetResources {
                    var photoType: PHAssetResourceType = .photo
                    var videoType: PHAssetResourceType = .pairedVideo
                    if hasAdjustmentData {
                        photoType = .fullSizePhoto
                        videoType = .fullSizePairedVideo
                    }
                    if assetResource.type == photoType {
                        PHAssetResourceManager.default().requestData(for: assetResource, options: options) { (data) in
                            imageData = data
                            DispatchQueue.main.async {
                                imageDataHandler(imageData)
                            }
                        } completionHandler: { (error) in
                            imageError = error
                            DispatchQueue.main.async {
                                if videoCompletion {
                                    callback(imageError, videoError)
                                }
                                imageCompletion = true
                            }
                        }
                    }else if assetResource.type == videoType {
                        PHAssetResourceManager.default().writeData(
                            for: assetResource,
                            toFile: videoURL,
                            options: options
                        ) { (error) in
                            DispatchQueue.main.async {
                                if error == nil {
                                    videoHandler(videoURL)
                                }
                                videoCompletion = true
                                videoError = error
                                if imageCompletion {
                                    callback(imageError, videoError)
                                }
                            }
                        }
                    }
                }
            }
        } else {
            completionHandler(
                .allError(
                    PhotoError.error(
                        type: .imageEmpty,
                        message: "系统版本低于9.1"
                    ),
                    PhotoError.error(
                        type: .videoEmpty,
                        message: "系统版本低于9.1"
                    )
                )
            )
        }
    }
    
    /// 获取LivePhoto里的视频地址
    /// - Parameters:
    ///   - forAsset: 对应的 PHAsset 对象
    ///   - fileURL: 指定视频地址
    ///   - completionHandler: 获取完成
    static func requestLivePhoto(
        videoURL forAsset: PHAsset,
        toFile fileURL: URL,
        completionHandler: @escaping (URL?, LivePhotoError?) -> Void
    ) {
        if #available(iOS 9.1, *) {
            requestLivePhoto(
                for: forAsset,
                targetSize: PHImageManagerMaximumSize
            ) { livePhoto, _, _ in
                guard let livePhoto = livePhoto else {
                    completionHandler(
                        nil,
                        .allError(
                            PhotoError.error(
                                type: .imageEmpty,
                                message: "livePhoto为nil，获取失败"),
                            PhotoError.error(
                                type: .videoEmpty,
                                message: "livePhoto为nil，获取失败"
                            )
                        )
                    )
                    return
                }
                let assetResources: [PHAssetResource] = PHAssetResource.assetResources(for: livePhoto)
                if assetResources.isEmpty {
                    completionHandler(
                        nil,
                        .allError(
                            PhotoError.error(
                                type: .imageEmpty,
                                message: "assetResources为nil，获取失败"
                            ),
                            PhotoError.error(
                                type: .videoEmpty,
                                message: "assetResources为nil，获取失败"
                            )
                        )
                    )
                    return
                }
                if !PhotoTools.removeFile(fileURL: fileURL) {
                    completionHandler(
                        nil,
                        .allError(
                            PhotoError.error(
                                type: .imageEmpty,
                                message: "指定的地址已存在"
                            ),
                            PhotoError.error(
                                type: .videoEmpty,
                                message: "指定的地址已存在"
                            )
                        )
                    )
                    return
                }
                let videoURL: URL = fileURL
                let options: PHAssetResourceRequestOptions = .init()
                options.isNetworkAccessAllowed = true
                var hasAdjustmentData: Bool = false
                for assetResource in assetResources where
                    assetResource.type == .adjustmentData {
                    hasAdjustmentData = true
                    break
                }
                for assetResource in assetResources {
                    var videoType: PHAssetResourceType = .pairedVideo
                    if hasAdjustmentData {
                        videoType = .fullSizePairedVideo
                    }
                    if assetResource.type == videoType {
                        PHAssetResourceManager.default().writeData(
                            for: assetResource,
                            toFile: videoURL,
                            options: options
                        ) { (error) in
                            DispatchQueue.main.async {
                                if error == nil {
                                    completionHandler(videoURL, nil)
                                }else {
                                    completionHandler(nil, .videoError(error))
                                }
                            }
                        }
                    }
                }
            }
        } else {
            completionHandler(
                nil,
                .allError(
                    PhotoError.error(
                        type: .imageEmpty,
                        message: "系统版本低于9.1"
                    ),
                    PhotoError.error(
                        type: .videoEmpty,
                        message: "系统版本低于9.1"
                    )
                )
            )
        }
    }
    
    // MARK: 获取LivePhoto里的图片地址和视频地址
    static func requestLivePhoto(
        contentURL asset: PHAsset,
        imageFileURL: URL? = nil,
        videoFileURL: URL? = nil,
        imageURLHandler: @escaping (URL?) -> Void,
        videoHandler: @escaping (URL?) -> Void,
        completionHandler: @escaping (LivePhotoError?) -> Void
    ) {
        guard #available(iOS 9.1, *) else {
            completionHandler(
                .allError(
                    PhotoError.error(
                        type: .imageEmpty,
                        message: "系统版本低于9.1"),
                    PhotoError.error(
                        type: .videoEmpty,
                        message: "系统版本低于9.1"
                    )
                )
            )
            return
        }
        requestLivePhoto(
            for: asset,
            targetSize: PHImageManagerMaximumSize
        ) { livePhoto, _, _ in
            guard let livePhoto = livePhoto else {
                completionHandler(
                    .allError(
                        PhotoError.error(
                            type: .imageEmpty,
                            message: "livePhoto为nil，获取失败"
                        ),
                        PhotoError.error(
                            type: .videoEmpty,
                            message: "livePhoto为nil，获取失败"
                        )
                    )
                )
                return
            }
            let assetResources: [PHAssetResource] = PHAssetResource.assetResources(for: livePhoto)
            if assetResources.isEmpty {
                completionHandler(
                    .allError(
                        PhotoError.error(
                            type: .imageEmpty,
                            message: "assetResources为nil，获取失败"
                        ),
                        PhotoError.error(
                            type: .videoEmpty,
                            message: "assetResources为nil，获取失败"
                        )
                    )
                )
                return
            }
            let options: PHAssetResourceRequestOptions = .init()
            options.isNetworkAccessAllowed = true
            var imageCompletion = false
            var imageError: Error?
            var videoCompletion = false
            var videoError: Error?
            let imageURL: URL
            if let imageFileURL = imageFileURL {
                imageURL = imageFileURL
            }else {
                imageURL = PhotoTools.getImageTmpURL(.png)
            }
            let videoURL: URL
            if let videoFileURL = videoFileURL {
                videoURL = videoFileURL
            }else {
                videoURL = PhotoTools.getVideoTmpURL()
            }
            let callback = {(imageError: Error?, videoError: Error?) in
                if imageError != nil && videoError != nil {
                    completionHandler(.allError(imageError, videoError))
                }else if imageError != nil {
                    completionHandler(.imageError(imageError))
                }else if videoError != nil {
                    completionHandler(.videoError(videoError))
                }else {
                    completionHandler(nil)
                }
            }
            var hasAdjustmentData: Bool = false
            for assetResource in assetResources where
                assetResource.type == .adjustmentData {
                hasAdjustmentData = true
                break
            }
            for assetResource in assetResources {
                var photoType: PHAssetResourceType = .photo
                var videoType: PHAssetResourceType = .pairedVideo
                if hasAdjustmentData {
                    photoType = .fullSizePhoto
                    videoType = .fullSizePairedVideo
                }
                if assetResource.type == photoType {
                    let _imageURL: URL
                    let isHEIC: Bool = assetResource.uniformTypeIdentifier.uppercased().hasSuffix("HEIC")
                    let sourceIsHEIC: Bool = imageURL.pathExtension.uppercased() == "HEIC"
                    if isHEIC, !sourceIsHEIC {
                        let path: String = imageURL.path.replacingOccurrences(of: imageURL.pathExtension, with: "HEIC")
                        _imageURL = .init(fileURLWithPath: path)
                    }else {
                        _imageURL = imageURL
                    }
                    PHAssetResourceManager.default().writeData(
                        for: assetResource,
                        toFile: _imageURL,
                        options: options
                    ) { (error) in
                        if isHEIC && !sourceIsHEIC {
                            let image: UIImage? = UIImage(contentsOfFile: _imageURL.path)?.normalizedImage()
                            try? FileManager.default.removeItem(at: _imageURL)
                            guard let data: Data = PhotoTools.getImageData(for: image) else {
                                imageError = AssetError.assetResourceWriteDataFailed(AssetError.invalidData)
                                imageCompletion = true
                                DispatchQueue.main.async {
                                    if videoCompletion {
                                        callback(imageError, videoError)
                                    }
                                }
                                return
                            }
                            do {
                                try data.write(to: imageURL)
                                DispatchQueue.main.async {
                                    imageURLHandler(imageURL)
                                }
                            } catch {
                                imageError = AssetError.assetResourceWriteDataFailed(AssetError.fileWriteFailed)
                            }
                            imageCompletion = true
                            DispatchQueue.main.async {
                                if videoCompletion {
                                    callback(imageError, videoError)
                                }
                            }
                            return
                        }
                        DispatchQueue.main.async {
                            if error == nil {
                                imageURLHandler(_imageURL)
                            }
                            imageCompletion = true
                            imageError = error
                            if videoCompletion {
                                callback(imageError, videoError)
                            }
                        }
                    }
                }else if assetResource.type == videoType {
                    PHAssetResourceManager.default().writeData(
                        for: assetResource,
                        toFile: videoURL,
                        options: options
                    ) { (error) in
                        DispatchQueue.main.async {
                            if error == nil {
                                videoHandler(videoURL)
                            }
                            videoCompletion = true
                            videoError = error
                            if imageCompletion {
                                callback(imageError, videoError)
                            }
                        }
                    }
                }
            }
        }
    }
}
