//
//  PhotoAsset+Local.swift
//  HXPHPicker
//
//  Created by Slience on 2021/8/25.
//

import UIKit

extension PhotoAsset {
    
    /// 获取本地图片地址
    func requestLocalImageURL(
        toFile fileURL: URL? = nil,
        compressionQuality: CGFloat? = nil,
        resultHandler: @escaping AssetURLCompletion
    ) {
        #if HXPICKER_ENABLE_EDITOR
        if photoEdit != nil {
            getEditedImageURL(
                toFile: fileURL,
                compressionQuality: compressionQuality,
                resultHandler: resultHandler
            )
            return
        }
        #endif
        func result(_ result: Result<AssetURLResult, AssetError>) {
            if DispatchQueue.isMain {
                resultHandler(result)
            }else {
                DispatchQueue.main.async {
                    resultHandler(result)
                }
            }
        }
        if let localImageURL = getLocalImageAssetURL() {
            func completion(_ imageURL: URL) {
                var url = imageURL
                if let fileURL = fileURL {
                    if PhotoTools.copyFile(at: imageURL, to: fileURL) {
                        url = fileURL
                    }else {
                        result(.failure(.fileWriteFailed))
                        return
                    }
                }
                result(
                    .success(
                        .init(
                            url: url,
                            urlType: .local,
                            mediaType: .photo
                        )
                    )
                )
            }
            if let compressionQuality = compressionQuality,
               !isGifAsset {
                DispatchQueue.global().async {
                    guard let imageData = try? Data(contentsOf: localImageURL) else {
                        result(.failure(.imageCompressionFailed))
                        return
                    }
                    if let data = PhotoTools.imageCompress(
                        imageData,
                        compressionQuality: compressionQuality
                    ),
                       let url = PhotoTools.write(
                        toFile: fileURL,
                        imageData: data
                    ) {
                        completion(url)
                    }else {
                        result(.failure(.imageCompressionFailed))
                    }
                }
            }else {
                completion(localImageURL)
            }
            return
        }
        DispatchQueue.global().async {
            var error: AssetError?
            if let imageData = self.getLocalImageData() {
                if let compressionQuality = compressionQuality,
                   !self.isGifAsset {
                    if let data = PhotoTools.imageCompress(
                        imageData,
                        compressionQuality: compressionQuality
                    ),
                       let url = PhotoTools.write(
                        toFile: fileURL,
                        imageData: data
                       ) {
                        result(
                            .success(
                                .init(
                                    url: url,
                                    urlType: .local,
                                    mediaType: .photo
                                )
                            )
                        )
                        return
                    }else {
                        error = .imageCompressionFailed
                    }
                }else {
                    if let imageURL = PhotoTools.write(
                        toFile: fileURL,
                        imageData: imageData
                    ) {
                        result(
                            .success(
                                .init(
                                    url: imageURL,
                                    urlType: .local,
                                    mediaType: .photo
                                )
                            )
                        )
                        return
                    }else {
                        error = .fileWriteFailed
                    }
                }
            }else {
                error = .invalidData
            }
            result(
                .failure(
                    error!
                )
            )
        }
    }
    
    /// 获取本地/网络图片
    /// - Parameters:
    ///   - urlType: 网络图片的url类型
    ///   - resultHandler: 获取结果
    func requestLocalImage(
        urlType: DonwloadURLType = .original,
        targetWidth: CGFloat = 180,
        resultHandler: @escaping (UIImage?, PhotoAsset) -> Void
    ) {
        #if HXPICKER_ENABLE_EDITOR
        if photoEdit != nil || videoEdit != nil {
            resultHandler(getEditedImage(), self)
            return
        }
        #endif
        guard phAsset == nil else {
            resultHandler(nil, self)
            return
        }
        if mediaType == .photo {
            if isNetworkAsset {
                #if canImport(Kingfisher)
                getNetworkImage(urlType: urlType) { (image) in
                    resultHandler(image, self)
                }
                #endif
                return
            }
            if urlType == .thumbnail,
               let thumbnail = localImageAsset?.thumbnail {
                resultHandler(thumbnail, self)
                return
            }
            var image: UIImage?
            if let img = localImageAsset?.image {
                image = img
            }else  if let imageURL = localImageAsset?.imageURL,
               let img = UIImage(contentsOfFile: imageURL.path) {
                localImageAsset?.image = img
                image = img
            }else if let imageURL = localLivePhoto?.imageURL,
                     let img = UIImage(contentsOfFile: imageURL.path) {
                image = img
           }
            if let image = image, urlType == .thumbnail {
                DispatchQueue.global().async {
                    let thumbnail = image.scaleToFillSize(
                        size: CGSize(
                            width: targetWidth,
                            height: targetWidth
                        ),
                        equalRatio: true
                    )
                    self.localImageAsset?.thumbnail = thumbnail
                    DispatchQueue.main.async {
                        resultHandler(thumbnail, self)
                    }
                }
                return
            }
            resultHandler(image, self)
        }else {
            PhotoTools.getVideoCoverImage(
                for: self
            ) { (photoAsset, image) in
                resultHandler(image, photoAsset)
            }
        }
    }
    
    /// 获取本地/网络视频地址
    func requestLocalVideoURL(
        toFile fileURL: URL? = nil,
        resultHandler: AssetURLCompletion
    ) {
        #if HXPICKER_ENABLE_EDITOR
        if videoEdit != nil {
            getEditedVideoURL(
                toFile: fileURL,
                resultHandler: resultHandler
            )
            return
        }
        #endif
        guard phAsset == nil else {
            resultHandler(.failure(.localURLIsEmpty))
            return
        }
        if mediaType == .photo {
            resultHandler(.failure(.typeError))
        }else {
            var videoURL: URL?
            if isNetworkAsset {
                let key = networkVideoAsset!.videoURL.absoluteString
                if PhotoTools.isCached(forVideo: key) {
                    videoURL = PhotoTools.getVideoCacheURL(for: key)
                }
            }else {
                videoURL = localVideoAsset?.videoURL
            }
            if let fileURL = fileURL,
               let url = videoURL {
                if PhotoTools.copyFile(at: url, to: fileURL) {
                    videoURL = fileURL
                }else {
                    resultHandler(.failure(.fileWriteFailed))
                    return
                }
            }
            if let videoURL = videoURL {
                resultHandler(
                    .success(
                        .init(
                            url: videoURL,
                            urlType: .local,
                            mediaType: .video
                        )
                    )
                )
            }else {
                if isNetworkAsset {
                    getNetworkVideoURL(resultHandler: resultHandler)
                }else {
                    resultHandler(.failure(.localURLIsEmpty))
                }
            }
        }
    }
    
    func getLocalImageAssetURL() -> URL? {
        #if HXPICKER_ENABLE_EDITOR
        if photoEdit != nil {
            return nil
        }
        #endif
        if mediaSubType == .localLivePhoto {
            return localLivePhoto?.imageURL
        }
        return localImageAsset?.imageURL
    }
    func getLocalImageData() -> Data? {
        #if HXPICKER_ENABLE_EDITOR
        if photoEdit != nil || videoEdit != nil {
            return getEditedImageData()
        }
        #endif
        if let imageData = localImageAsset?.imageData {
            return imageData
        }else if let imageURL = localImageAsset?.imageURL,
                 let imageData = try? Data(contentsOf: imageURL) {
            return imageData
        }else if let localImage = localImageAsset?.image,
                 let imageData = PhotoTools.getImageData(for: localImage) {
            return imageData
        }else if let imageURL = localLivePhoto?.imageURL,
                 let imageData = try? Data(contentsOf: imageURL) {
            return imageData
        }else {
            if mediaType == .video {
                checkLoaclVideoImage()
                return PhotoTools.getImageData(for: localVideoAsset?.image)
            }
        }
        return nil
    }
    func requestlocalImageData(
        resultHandler: (
            (PhotoAsset, Result<ImageDataResult, AssetManager.ImageDataError>) -> Void
        )?
    ) {
        func resultSuccess(
            data: Data,
            orientation: UIImage.Orientation,
            info: [AnyHashable: Any]?
        ) {
            DispatchQueue.main.async {
                resultHandler?(
                    self,
                    .success(
                        .init(
                            imageData: data,
                            imageOrientation: orientation,
                            info: info
                        )
                    )
                )
            }
        }
        func resultFailed(
            info: [AnyHashable: Any]?,
            error: AssetError
        ) {
            DispatchQueue.main.async {
                resultHandler?(
                    self,
                    .failure(
                        .init(
                            info: info,
                            error: error
                        )
                    )
                )
            }
        }
        #if HXPICKER_ENABLE_EDITOR
        if photoEdit != nil || videoEdit != nil {
            if let imageData = getEditedImageData(),
               let image = getEditedImage() {
                resultSuccess(
                    data: imageData,
                    orientation: image.imageOrientation,
                    info: nil
                )
                return
            }
            resultFailed(info: nil, error: .invalidData)
            return
        }
        #endif
        guard phAsset == nil else {
            resultFailed(info: nil, error: .invalidData)
            return
        }
        DispatchQueue.global().async {
            if let imageData = self.getLocalImageData(),
               let image = UIImage(data: imageData) {
                resultSuccess(
                    data: imageData,
                    orientation: image.imageOrientation,
                    info: nil
                )
                return
            }else {
                if self.isNetworkAsset {
                    #if canImport(Kingfisher)
                    self.getNetworkImage {  (image) in
                        var imageData: Data?
                        if let data = image?.kf.gifRepresentation() {
                            imageData = data
                        }else if let data = PhotoTools.getImageData(for: image) {
                            imageData = data
                        }
                        if let imageData = imageData,
                            let image = image {
                            resultSuccess(
                                data: imageData,
                                orientation: image.imageOrientation,
                                info: nil
                            )
                        }else {
                            resultFailed(info: nil, error: .invalidData)
                        }
                    }
                    #endif
                    return
                }
                resultFailed(info: nil, error: .invalidData)
            }
        }
    }
    func checkLoaclVideoImage() {
        if localVideoAsset?.image == nil {
            let image = PhotoTools.getVideoThumbnailImage(videoURL: localVideoAsset?.videoURL, atTime: 0.1)
            localVideoAsset?.image = image
        }
    }
    func getLocalVideoDuration(
        completionHandler: (
            (TimeInterval, String) -> Void
        )? = nil
    ) {
        if pVideoDuration > 0 {
            completionHandler?(pVideoDuration, pVideoTime!)
        }else {
            DispatchQueue.global().async {
                let duration = PhotoTools.getVideoDuration(videoURL: self.localVideoAsset?.videoURL)
                self.pVideoDuration = duration
                self.pVideoTime = PhotoTools.transformVideoDurationToString(
                    duration: duration
                )
                DispatchQueue.main.async {
                    completionHandler?(duration, self.pVideoTime!)
                }
            }
        }
    }
}
