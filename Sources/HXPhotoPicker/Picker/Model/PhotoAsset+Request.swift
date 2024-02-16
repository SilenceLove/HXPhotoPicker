//
//  PhotoAsset+Request.swift
//  HXPhotoPicker
//
//  Created by Slience on 2021/3/11.
//

import UIKit
import Photos
#if canImport(Kingfisher)
import Kingfisher
#endif

// MARK: Request Photo
public extension PhotoAsset {
    
    struct ImageDataResult {
        let imageData: Data
        let imageOrientation: UIImage.Orientation
        let info: [AnyHashable: Any]?
    }
    
    @discardableResult
    func requestImage(
        filterEditor: Bool = false,
        iCloudHandler: PhotoAssetICloudHandler? = nil,
        progressHandler: PhotoAssetProgressHandler? = nil,
        resultHandler: @escaping (PhotoAsset, UIImage?, [AnyHashable: Any]?) -> Void
    ) -> PHImageRequestID? {
        #if HXPICKER_ENABLE_EDITOR
        if !filterEditor, editedResult != nil {
            DispatchQueue.global().async {
                let image = self.getEditedImage()
                DispatchQueue.main.async {
                    resultHandler(self, image, nil)
                }
            }
            return nil
        }
        #endif
        guard let phAsset else {
            return nil
        }
        if downloadStatus != .succeed {
            downloadStatus = .downloading
        }
        return AssetManager.requestImage(for: phAsset, targetSize: phAsset.targetSize, resizeMode: .fast) {
            iCloudHandler?(self, $0)
        } progressHandler: { progress, error, stop, info in
            self.downloadProgress = progress
            DispatchQueue.main.async {
                progressHandler?(self, progress)
            }
        } resultHandler: {
            if $0 != nil {
                self.downloadProgress = 1
                self.downloadStatus = .succeed
            }else {
                if AssetManager.assetCancelDownload(for: $1) {
                    self.downloadStatus = .canceled
                }else {
                    self.downloadProgress = 0
                    self.downloadStatus = .failed
                }
            }
            resultHandler(self, $0, $1)
        }
    }
    
    /// 获取原始图片地址
    /// 网络图片获取方法 getNetworkImageURL
    /// - Parameters:
    ///   - fileURL: 指定图片的本地地址
    ///   - compressionQuality: 压缩比例
    ///   - resultHandler: 获取结果
    func requestImageURL(
        toFile fileURL: URL? = nil,
        compressionQuality: CGFloat? = nil,
        resultHandler: @escaping AssetURLCompletion
    ) {
        if phAsset == nil {
            requestLocalImageURL(
                toFile: fileURL,
                compressionQuality: compressionQuality,
                resultHandler: resultHandler
            )
            return
        }
        requestAssetImageURL(
            toFile: fileURL,
            compressionQuality: compressionQuality,
            resultHandler: resultHandler
        )
    }
    
    /// 获取图片
    /// - Parameters:
    ///   - compressionScale: 压缩比例 [0 - 1]
    ///   - completion: 获取完成
    /// - Returns: 请求系统相册资源的请求id
    @discardableResult
    func requestImage(
        compressionScale: CGFloat? = nil,
        completion: ((UIImage?, PhotoAsset) -> Void)?
    ) -> PHImageRequestID? {
        #if HXPICKER_ENABLE_EDITOR
        if editedResult != nil {
            getEditedImageURL(
                compressionQuality: compressionScale
            ) { result in
                switch result {
                case .success(let urlResult):
                    completion?(
                        UIImage(
                            contentsOfFile: urlResult.url.path
                        ),
                        self
                    )
                case .failure:
                    completion?(nil, self)
                }
            }
            return nil
        }
        #endif
        guard let phAsset = phAsset else {
            requestLocalImage(
                urlType: .original
            ) { (image, photoAsset) in
                completion?(image, photoAsset)
            }
            return nil
        }
        let isHEIC = photoFormat == "heic"
        let options = PHImageRequestOptions.init()
        options.resizeMode = .fast
        options.deliveryMode = .highQualityFormat
        options.isNetworkAccessAllowed = true
        return AssetManager.requestImageData(
            for: phAsset,
            version: isGifAsset ? .original : .current
        ) { (result) in
            switch result {
            case .success(let dataResult):
                if let compressionScale = compressionScale, compressionScale < 1 {
                    DispatchQueue.global().async {
                        if let data = PhotoTools.imageCompress(
                            dataResult.imageData,
                            compressionQuality: compressionScale,
                            isHEIC: isHEIC
                        ), let image = UIImage(data: data)?.normalizedImage() {
                            DispatchQueue.main.async {
                                completion?(image, self)
                            }
                        }else {
                            DispatchQueue.main.async {
                                completion?(nil, self)
                            }
                        }
                    }
                    return
                }
                let image = UIImage(
                    data: dataResult.imageData
                )?.normalizedImage()
                completion?(image, self)
            case .failure:
                completion?(nil, self)
            }
        }
    }
    
    @discardableResult
    func requestImage(
        targetSize: CGSize,
        targetMode: HX.ImageTargetMode = .fill,
        completion: ((UIImage?, PhotoAsset) -> Void)?
    ) -> PHImageRequestID? {
        #if HXPICKER_ENABLE_EDITOR
        if editedResult != nil {
            DispatchQueue.global().async {
                let image = self.getEditedImage()?.scaleToFillSize(size: targetSize, mode: targetMode)
                DispatchQueue.main.async {
                    completion?(image, self)
                }
            }
            return nil
        }
        #endif
        guard let phAsset = phAsset else {
            requestLocalImage(
                urlType: .original
            ) { (image, photoAsset) in
                DispatchQueue.global().async {
                    let image = image?.scaleToFillSize(size: targetSize, mode: targetMode)
                    DispatchQueue.main.async {
                        completion?(image, photoAsset)
                    }
                }
            }
            return nil
        }
        
        return AssetManager.requestImage(
            for: phAsset,
            targetSize: targetSize,
            deliveryMode: .highQualityFormat,
            resizeMode: .fast
        ) { image, info in
            if targetMode == .fill {
                completion?(image, self)
            }else {
                DispatchQueue.global().async {
                    let image = image?.scaleToFillSize(size: targetSize, mode: targetMode)
                    DispatchQueue.main.async {
                        completion?(image, self)
                    }
                }
            }
        }
    }
    
    /// 请求获取缩略图
    /// - Parameter completion: 完成回调
    /// - Returns: 请求ID
    @discardableResult
    func requestThumbnailImage(
        localType: DonwloadURLType = .thumbnail,
        targetWidth: CGFloat = 180,
        completion: ((UIImage?, PhotoAsset, [AnyHashable: Any]?) -> Void)?
    ) -> PHImageRequestID? {
        #if HXPICKER_ENABLE_EDITOR
        if let photoEdit = photoEditedResult {
            completion?(photoEdit.image, self, nil)
            return nil
        }
        if let videoEdit = videoEditedResult {
            completion?(videoEdit.coverImage, self, nil)
            return nil
        }
        #endif
        guard let phAsset = phAsset else {
            requestLocalImage(
                urlType: localType,
                targetWidth: targetWidth
            ) { (image, photoAsset) in
                completion?(image, photoAsset, nil)
            }
            return nil
        }
        return AssetManager.requestThumbnailImage(
            for: phAsset,
            targetWidth: targetWidth
        ) { (image, info) in
            completion?(image, self, info)
        }
    }
    
    /// 请求imageData，如果资源在iCloud上会自动下载。如果需要更细节的处理请查看 PHAssetManager+Asset
    /// - Parameters:
    ///   - filterEditor: 过滤编辑后的图片
    ///   - iCloudHandler: 下载iCloud上的资源时回调iCloud的请求ID
    ///   - progressHandler: iCloud下载进度
    /// - Returns: 请求ID
    @discardableResult
    func requestImageData(
        filterEditor: Bool = false,
        iCloudHandler: PhotoAssetICloudHandler? = nil,
        progressHandler: PhotoAssetProgressHandler? = nil,
        resultHandler: (
            (PhotoAsset, Result<ImageDataResult, AssetManager.ImageDataError>
        ) -> Void)?
    ) -> PHImageRequestID {
        #if HXPICKER_ENABLE_EDITOR
        if let photoEdit = photoEditedResult, !filterEditor {
            do {
                let imageData = try Data.init(contentsOf: photoEdit.url)
                resultHandler?(
                    self,
                    .success(
                        .init(
                            imageData: imageData,
                            imageOrientation: photoEdit.image.imageOrientation,
                            info: nil
                        )
                    )
                )
            }catch {
                resultHandler?(self, .failure(.init(info: nil, error: .invalidData)))
            }
            return 0
        }
        if let videoEdit = videoEditedResult, !filterEditor {
            let imageData = PhotoTools.getImageData(for: videoEdit.coverImage)
            if let imageData = imageData {
                resultHandler?(
                    self,
                    .success(
                        .init(
                            imageData: imageData,
                            imageOrientation: videoEdit.coverImage?.imageOrientation ?? .up,
                            info: nil
                        )
                    )
                )
            }else {
                resultHandler?(self, .failure(.init(info: nil, error: .invalidData)))
            }
            return 0
        }
        #endif
        guard let phAsset = phAsset else {
            requestlocalImageData { photoAsset, result in
                switch result {
                case .success(let imageResult):
                    resultHandler?(
                        photoAsset,
                        .success(
                            .init(
                                imageData: imageResult.imageData,
                                imageOrientation: imageResult.imageOrientation,
                                info: nil
                            )
                        )
                    )
                case .failure(let error):
                    resultHandler?(photoAsset, .failure(error))
                }
            }
            return 0
        }
        var version = PHImageRequestOptionsVersion.current
        if mediaSubType == .imageAnimated {
            version = .original
        }
        if downloadStatus != .succeed {
            downloadStatus = .downloading
        }
        let isGif = phAsset.isImageAnimated
        return AssetManager.requestImageData(for: phAsset, version: version) { iCloudRequestID in
            iCloudHandler?(self, iCloudRequestID)
        } progressHandler: { progress, _, _, _ in
            self.downloadProgress = progress
            DispatchQueue.main.async {
                progressHandler?(self, progress)
            }
        } resultHandler: { result in
            switch result {
            case .success(let dataResult):
                self.downloadProgress = 1
                self.downloadStatus = .succeed
                let imageData: Data
                if isGif && self.mediaSubType != .imageAnimated {
                    if let image = UIImage(data: dataResult.imageData),
                       let data = PhotoTools.getImageData(for: image) {
                        imageData = data
                    }else {
                        resultHandler?(
                            self,
                            .failure(
                                .init(
                                    info: nil,
                                    error: .invalidData
                                )
                            )
                        )
                        return
                    }
                }else {
                    imageData = dataResult.imageData
                }
                resultHandler?(
                    self,
                    .success(
                        .init(
                            imageData: imageData,
                            imageOrientation: dataResult.imageOrientation,
                            info: dataResult.info
                        )
                    )
                )
            case .failure(let error):
                if AssetManager.assetCancelDownload(for: error.info) {
                    self.downloadStatus = .canceled
                }else {
                    self.downloadProgress = 0
                    self.downloadStatus = .failed
                }
                resultHandler?(self, .failure(error))
            }
        }
    }
}

// MARK: Request LivePhoto
public extension PhotoAsset {
    
    /// 请求LivePhoto，如果资源在iCloud上会自动下载。如果需要更细节的处理请查看 PHAssetManager+Asset
    /// - Parameters:
    ///   - targetSize: 请求的大小
    ///   - iCloudHandler: 下载iCloud上的资源时回调iCloud的请求ID
    ///   - progressHandler: iCloud下载进度
    /// - Returns: 请求ID
    @available(iOS 9.1, *)
    @discardableResult
    func requestLivePhoto(
        targetSize: CGSize,
        iCloudHandler: PhotoAssetICloudHandler?,
        progressHandler: PhotoAssetProgressHandler?,
        success: ((PhotoAsset, PHLivePhoto, [AnyHashable: Any]?) -> Void)?,
        failure: PhotoAssetFailureHandler?
    ) -> PHImageRequestID {
        guard let phAsset = phAsset else {
            failure?(self, nil, .invalidPHAsset)
            return 0
        }
        if downloadStatus != .succeed {
            downloadStatus = .downloading
        }
        return AssetManager.requestLivePhoto(
            for: phAsset,
            targetSize: targetSize
        ) { (iCloudRequestID) in
            iCloudHandler?(self, iCloudRequestID)
        } progressHandler: { (progress, _, _, _) in
            self.downloadProgress = progress
            DispatchQueue.main.async {
                progressHandler?(self, progress)
            }
        } resultHandler: { (livePhoto, info, downloadSuccess) in
            if downloadSuccess {
                self.downloadProgress = 1
                self.downloadStatus = .succeed
                success?(self, livePhoto!, info)
            }else {
                if AssetManager.assetCancelDownload(for: info) {
                    self.downloadStatus = .canceled
                }else {
                    self.downloadProgress = 0
                    self.downloadStatus = .failed
                }
                failure?(self, info, .requestFailed(info))
            }
        }
    }
    
    func requestLivePhotoURL(
        imageFileURL: URL? = nil,
        videoFileURL: URL? = nil,
        compression: Compression? = nil,
        completion: @escaping AssetURLCompletion
    ) {
        #if HXPICKER_ENABLE_EDITOR
        if photoEditedResult != nil {
            getEditedImageURL(
                toFile: imageFileURL,
                compressionQuality: compression?.imageCompressionQuality,
                resultHandler: completion
            )
            return
        }
        #endif
        guard let phAsset = phAsset else {
            if mediaSubType == .localLivePhoto {
                requestLocalLivePhotoURL(
                    imageFileURL: imageFileURL,
                    videoFileURL: videoFileURL,
                    compression: compression,
                    completion: completion
                )
                return
            }
            completion(.failure(.invalidPHAsset))
            return
        }
        let toImageURL: URL
        if let imageFileURL = imageFileURL {
            toImageURL = imageFileURL
        }else {
            if let photoFormat = photoFormat {
                toImageURL = PhotoTools.getTmpURL(for: photoFormat)
            }else {
                toImageURL = PhotoTools.getImageTmpURL()
            }
        }
        
        var imageURL: URL?
        var videoURL: URL?
        AssetManager.requestLivePhoto(
            contentURL: phAsset,
            imageFileURL: toImageURL,
            videoFileURL: videoFileURL
        ) { url in
            imageURL  = url
        } videoHandler: { url in
            videoURL  = url
        } completionHandler: { error in
            guard let imageURL = imageURL,
                  let videoURL = videoURL else {
                if let error = error {
                    switch error {
                    case .allError(let imageError, let videoError):
                        completion(.failure(.exportLivePhotoURLFailed(imageError, videoError)))
                    case .imageError(let error):
                        completion(.failure(.exportLivePhotoImageURLFailed(error)))
                    case .videoError(let error):
                        completion(.failure(.exportLivePhotoVideoURLFailed(error)))
                    }
                }else {
                    completion(.failure(.exportLivePhotoURLFailed(nil, nil)))
                }
                return
            }
            self.requestLivePhotoURLSuccess(
                imageURL: imageURL,
                videoURL: videoURL,
                compression: compression,
                completion: completion
            )
        }
    }
     
    private func requestLivePhotoURLSuccess(
        imageURL: URL,
        videoURL: URL,
        compression: Compression?,
        completion: @escaping AssetURLCompletion
    ) {
        func completionFunc(_ image_URL: URL?, _ video_URL: URL?) {
            if let image_URL = image_URL,
               let video_URL = video_URL {
                completion(
                    .success(
                        .init(
                            url: image_URL,
                            urlType: .local,
                            mediaType: .photo,
                            livePhoto: .init(
                                imageURL: image_URL,
                                videoURL: video_URL
                            )
                        )
                    )
                )
            }else if image_URL != nil {
                completion(.failure(.exportLivePhotoVideoURLFailed(nil)))
            }else if video_URL != nil {
                completion(.failure(.exportLivePhotoImageURLFailed(nil)))
            }else {
                completion(.failure(.exportLivePhotoURLFailed(nil, nil)))
            }
        }
        func imageCompressor(_ url: URL, _ compressionQuality: CGFloat) -> URL? {
            guard let imageData = try? Data(contentsOf: url) else {
                return nil
            }
            if FileManager.default.fileExists(atPath: url.path) {
                try? FileManager.default.removeItem(at: url)
            }
            if let data = PhotoTools.imageCompress(
                imageData,
                compressionQuality: compressionQuality,
                isHEIC: url.pathExtension.uppercased() == "HEIC"
            ) {
                return PhotoTools.write(toFile: url, imageData: data)
            }
            return nil
        }
        func videoCompressor(
            _ url: URL,
            _ exportParameter: VideoExportParameter,
            completionHandler: ((URL?, Error?) -> Void)?
        ) {
            let avAsset = AVAsset(url: url)
            avAsset.loadValuesAsynchronously(forKeys: ["tracks"]) {
                if avAsset.statusOfValue(forKey: "tracks", error: nil) != .loaded {
                    completionHandler?(nil, nil)
                    return
                }
                AssetManager.exportVideoURL(
                    forVideo: avAsset,
                    toFile: PhotoTools.getVideoTmpURL(),
                    exportParameter: exportParameter
                ) { video_URL, error in
                    guard let video_URL = video_URL else {
                        completionHandler?(nil, error)
                        return
                    }
                    do {
                        if FileManager.default.fileExists(atPath: url.path) {
                            try FileManager.default.removeItem(at: url)
                        }
                        try FileManager.default.moveItem(at: video_URL, to: url)
                        completionHandler?(url, error)
                    } catch {
                        completionHandler?(nil, error)
                    }
                }
            }
        }
        if let imageCompression = compression?.imageCompressionQuality,
           let videoExportParameter = compression?.videoExportParameter {
            let group = DispatchGroup()
            let imageQueue = DispatchQueue(label: "HXPhotoPicker.request.livephoto.imageurl")
            var image_URL: URL?
            var video_URL: URL?
            imageQueue.async(group: group, execute: DispatchWorkItem(block: {
                image_URL = imageCompressor(imageURL, imageCompression)
            }))
            let videoQueue = DispatchQueue(label: "HXPhotoPicker.request.livephoto.videourl")
            let semaphore = DispatchSemaphore(value: 0)
            videoQueue.async(group: group, execute: DispatchWorkItem(block: {
                videoCompressor(
                    videoURL,
                    videoExportParameter
                ) { url, _ in
                    video_URL = url
                    semaphore.signal()
                }
                semaphore.wait()
            }))
            group.notify(queue: .main, work: DispatchWorkItem(block: {
                completionFunc(image_URL, video_URL)
            }))
        }else if let imageCompression = compression?.imageCompressionQuality {
            DispatchQueue.global().async {
                let url = imageCompressor(imageURL, imageCompression)
                DispatchQueue.main.async {
                    completionFunc(url, videoURL)
                }
            }
        }else if let videoExportParameter = compression?.videoExportParameter {
            DispatchQueue.global().async {
                videoCompressor(
                    videoURL,
                    videoExportParameter
                ) { url, _ in
                    DispatchQueue.main.async {
                        completionFunc(imageURL, url)
                    }
                }
            }
        }else {
            completionFunc(imageURL, videoURL)
        }
    }
    
    class LocalLivePhotoRequest {
        var videoURL: URL
        #if canImport(Kingfisher)
        var imageTask: Kingfisher.DownloadTask?
        #endif
        var writer: AVAssetWriter?
        var videoInput: AVAssetWriterInput?
        var videoReader: AVAssetReader?
        var audioInput: AVAssetWriterInput?
        var audioReader: AVAssetReader?
        var requestID: PHLivePhotoRequestID?
        
        var isCancel: Bool = false
        
        init(videoURL: URL) {
            self.videoURL = videoURL
        }
        
        public func cancelRequest() {
            isCancel = true
            #if canImport(Kingfisher)
            if let task = imageTask {
                task.cancel()
            }
            #endif
            PhotoManager.shared.removeTask(videoURL)
            writer?.cancelWriting()
            videoInput?.markAsFinished()
            videoReader?.cancelReading()
            audioInput?.markAsFinished()
            audioReader?.cancelReading()
            if let requestID = requestID {
                PHLivePhoto.cancelRequest(withRequestID: requestID)
            }
        }
    }
    
    @discardableResult
    func requestLocalLivePhoto(
        URLHandler: ((URL?, URL?) -> Void)? = nil,
        success: @escaping (PhotoAsset, PHLivePhoto) -> Void,
        failure: @escaping PhotoAssetFailureHandler
    ) -> LocalLivePhotoRequest? {
        guard let livePhoto = localLivePhoto else {
            failure(self, nil, .localLivePhotoIsEmpty)
            return nil
        }
        let imageURL = livePhoto.imageURL
        let videoURL = livePhoto.videoURL
        let imageIdentifier = livePhoto.imageIdentifier
        let videoIdentifier = livePhoto.videoIdentifier
        let request = LocalLivePhotoRequest(videoURL: videoURL)
        if livePhoto.isCache {
            DispatchQueue.main.async {
                URLHandler?(livePhoto.jpgURL, livePhoto.movURL)
            }
            request.requestID = mergeToLivePhoto(
                imageURL: livePhoto.jpgURL,
                videoURL: livePhoto.movURL,
                success: success,
                failure: failure
            )
            return request
        }
        if imageURL.isFileURL && videoURL.isFileURL {
            writeLivePhoto(
                request: request,
                imageURL: imageURL,
                imageCacheKey: imageIdentifier,
                videoURL: videoURL,
                videoCacheKey: videoIdentifier,
                URLHandler: URLHandler,
                success: success,
                failure: failure
            )
        }else if !imageURL.isFileURL && videoURL.isFileURL {
            #if canImport(Kingfisher)
            request.imageTask = KingfisherManager.shared.retrieveImage(with: imageURL) { result in
                switch result {
                case .success:
                    let cachePath = ImageCache.default.cachePath(forKey: imageURL.cacheKey)
                    let cacheURL = URL(fileURLWithPath: cachePath)
                    self.writeLivePhoto(
                        request: request,
                        imageURL: cacheURL,
                        imageCacheKey: imageURL.absoluteString,
                        videoURL: videoURL,
                        videoCacheKey: videoIdentifier,
                        URLHandler: URLHandler,
                        success: success,
                        failure: failure
                    )
                case .failure:
                    URLHandler?(nil, nil)
                    failure(self, nil, .imageDownloadFailed)
                }
            }
            #else
            assert(
                false,
                "下载网络图片请导入 Kingfisher"
            )
            #endif
        }else if imageURL.isFileURL && !videoURL.isFileURL {
            PhotoManager.shared.downloadTask(with: videoURL) { url, _, _ in
                guard let video_URL = url else {
                    URLHandler?(nil, nil)
                    failure(self, nil, .videoDownloadFailed)
                    return
                }
                self.writeLivePhoto(
                    request: request,
                    imageURL: imageURL,
                    imageCacheKey: imageIdentifier,
                    videoURL: video_URL,
                    videoCacheKey: videoURL.absoluteString,
                    URLHandler: URLHandler,
                    success: success,
                    failure: failure
                )
            }
        }else {
            #if canImport(Kingfisher)
            request.imageTask = KingfisherManager.shared.retrieveImage(with: imageURL) { result in
                switch result {
                case .success:
                    let cachePath = ImageCache.default.cachePath(forKey: imageURL.cacheKey)
                    let cacheURL = URL(fileURLWithPath: cachePath)
                    PhotoManager.shared.downloadTask(with: videoURL) { url, _, _ in
                        guard let video_URL = url else {
                            URLHandler?(nil, nil)
                            failure(self, nil, .videoDownloadFailed)
                            return
                        }
                        self.writeLivePhoto(
                            request: request,
                            imageURL: cacheURL,
                            imageCacheKey: imageURL.absoluteString,
                            videoURL: video_URL,
                            videoCacheKey: videoURL.absoluteString,
                            URLHandler: URLHandler,
                            success: success,
                            failure: failure
                        )
                    }
                case .failure:
                    URLHandler?(nil, nil)
                    failure(self, nil, .imageDownloadFailed)
                }
            }
            #else
            assert(
                false,
                "下载网络图片请导入 Kingfisher"
            )
            #endif
        }
        return request
    }
    
    private func mergeToLivePhoto(
        imageURL: URL,
        videoURL: URL,
        success: @escaping (PhotoAsset, PHLivePhoto) -> Void,
        failure: @escaping PhotoAssetFailureHandler
    ) -> PHLivePhotoRequestID? {
        let image = UIImage(contentsOfFile: imageURL.path)
        return PHLivePhoto.request(
            withResourceFileURLs: [videoURL, imageURL],
            placeholderImage: image,
            targetSize: .zero,
            contentMode: .aspectFill
        ) { phLivePhoto, info in
            guard let phLivePhoto = phLivePhoto else {
                DispatchQueue.main.async {
                    failure(self, nil, .localLivePhotoWriteVideoFailed)
                }
                return
            }
            let isDegraded = info[PHLivePhotoInfoIsDegradedKey] as? Int
            let isCancel = info[PHLivePhotoInfoCancelledKey] as? Int
            DispatchQueue.main.async {
                if let isDegraded = isDegraded {
                    if isDegraded == 0 {
                        success(self, phLivePhoto)
                    }
                }else if let isCancel = isCancel {
                    if isCancel == 0 {
                        success(self, phLivePhoto)
                    }else {
                        failure(self, info, .localLivePhotoRequestFailed)
                    }
                }
            }
        }
    }
    
    private func writeLivePhoto(
        request: LocalLivePhotoRequest,
        imageURL: URL,
        imageCacheKey: String?,
        videoURL: URL,
        videoCacheKey: String?,
        URLHandler: ((URL?, URL?) -> Void)? = nil,
        success: @escaping (PhotoAsset, PHLivePhoto) -> Void,
        failure: @escaping PhotoAssetFailureHandler
    ) {
        DispatchQueue.global().async {
            PhotoTools.getLivePhotoJPGURL(
                imageURL,
                cacheKey: imageCacheKey
            ) { url in
                guard let imageURL = url else {
                    DispatchQueue.main.async {
                        URLHandler?(nil, nil)
                        failure(self, nil, .localLivePhotoWriteImageFailed)
                    }
                    return
                }
                if request.isCancel {
                    DispatchQueue.main.async {
                        URLHandler?(imageURL, nil)
                        failure(self, nil, .localLivePhotoCancelWrite)
                    }
                    return
                }
                PhotoTools.getLivePhotoVideoMovURL(
                    videoURL,
                    cacheKey: videoCacheKey
                ) { writer, videoInput, videoReader, audioInput, audioReader in
                    request.writer = writer
                    request.videoInput = videoInput
                    request.videoReader = videoReader
                    request.audioInput = audioInput
                    request.audioReader = audioReader
                } completion: { url in
                    guard let videoURL = url else {
                        DispatchQueue.main.async {
                            URLHandler?(imageURL, nil)
                            failure(self, nil, .localLivePhotoWriteVideoFailed)
                        }
                        return
                    }
                    DispatchQueue.main.async {
                        URLHandler?(imageURL, videoURL)
                    }
                    request.requestID = self.mergeToLivePhoto(
                        imageURL: imageURL,
                        videoURL: videoURL,
                        success: success,
                        failure: failure
                    )
                }
            }
        }
    }
    
    func requestLocalLivePhotoURL(
        imageFileURL: URL? = nil,
        videoFileURL: URL? = nil,
        compression: Compression? = nil,
        completion: @escaping AssetURLCompletion
    ) {
        #if HXPICKER_ENABLE_EDITOR
        if photoEditedResult != nil {
            getEditedImageURL(
                toFile: imageFileURL,
                compressionQuality: compression?.imageCompressionQuality,
                resultHandler: completion
            )
            return
        }
        #endif
        guard let localLivePhoto = localLivePhoto else {
            completion(.failure(.localLivePhotoIsEmpty))
            return
        }
        var imageURL = localLivePhoto.imageURL
        var videoURL = localLivePhoto.videoURL
        let imageURLType: AssetURLResult.URLType
        if imageURL.isFileURL {
            imageURLType = .local
            if let imageFileURL = imageFileURL {
                if PhotoTools.copyFile(
                    at: imageURL,
                    to: imageFileURL
                ) {
                    imageURL = imageFileURL
                }else {
                    completion(.failure(.fileWriteFailed))
                    return
                }
            }
        }else {
            imageURLType = .network
        }
        let videoURLType: AssetURLResult.URLType
        if videoURL.isFileURL {
            videoURLType = .local
            if let videoFileURL = videoFileURL {
                if PhotoTools.copyFile(
                    at: videoURL,
                    to: videoFileURL
                ) {
                    videoURL = videoFileURL
                }else {
                    completion(.failure(.fileWriteFailed))
                    return
                }
            }
        }else {
            videoURLType = .network
        }
        completion(
            .success(
                .init(
                    url: imageURL,
                    urlType: imageURLType,
                    mediaType: .photo,
                    livePhoto: .init(
                        imageURL: imageURL,
                        imageURLType: imageURLType,
                        videoURL: videoURL,
                        videoURLType: videoURLType
                    )
                )
            )
        )
    }
}

// MARK: Request Video
public extension PhotoAsset {
    
    /// 获取原始视频地址，系统相册里的视频需要自行压缩
    /// 网络视频如果在本地有缓存则会返回本地地址，如果没有缓存则为ni
    /// - Parameters:
    ///   - fileURL: 指定视频地址
    ///   - exportParameter: 导出参数，nil 为原始视频
    ///   - resultHandler: 获取结果
    func requestVideoURL(
        toFile fileURL: URL? = nil,
        exportParameter: VideoExportParameter? = nil,
        exportSession: ((AVAssetExportSession) -> Void)? = nil,
        resultHandler: @escaping AssetURLCompletion
    ) {
        if phAsset == nil {
            requestLocalVideoURL(
                toFile: fileURL,
                resultHandler: resultHandler
            )
            return
        }
        requestAssetVideoURL(
            toFile: fileURL,
            exportParameter: exportParameter,
            exportSession: exportSession,
            resultHandler: resultHandler
        )
    }
    
    /// 请求AVAsset，如果资源在iCloud上会自动下载。如果需要更细节的处理请查看 PHAssetManager+Asset
    /// - Parameters:
    ///   - filterEditor: 过滤编辑过的视频，取原视频
    ///   - iCloudHandler: 下载iCloud上的资源时回调iCloud的请求ID
    ///   - progressHandler: iCloud下载进度
    /// - Returns: 请求ID
    @discardableResult
    func requestAVAsset(
        filterEditor: Bool = false,
        deliveryMode: PHVideoRequestOptionsDeliveryMode = .automatic,
        iCloudHandler: PhotoAssetICloudHandler?,
        progressHandler: PhotoAssetProgressHandler?,
        success: ((PhotoAsset, AVAsset, [AnyHashable: Any]?) -> Void)?,
        failure: PhotoAssetFailureHandler?
    ) -> PHImageRequestID {
        #if HXPICKER_ENABLE_EDITOR
        if let videoEdit = videoEditedResult, !filterEditor {
            success?(self, AVAsset.init(url: videoEdit.url), nil)
            return 0
        }
        #endif
        guard let phAsset = phAsset else {
            if let localVideoURL = localVideoAsset?.videoURL {
                success?(self, AVAsset.init(url: localVideoURL), nil)
            }else if let networkVideoURL = networkVideoAsset?.videoURL {
                success?(self, AVAsset.init(url: networkVideoURL), nil)
            }else {
                failure?(self, nil, .invalidPHAsset)
            }
            return 0
        }
        if downloadStatus != .succeed {
            downloadStatus = .downloading
        }
        return AssetManager.requestAVAsset(
            for: phAsset,
            deliveryMode: deliveryMode
        ) { (iCloudRequestID) in
            iCloudHandler?(self, iCloudRequestID)
        } progressHandler: { (progress, _, _, _) in
            self.downloadProgress = progress
            DispatchQueue.main.async {
                progressHandler?(self, progress)
            }
        } resultHandler: { (result) in
            switch result {
            case .success(let avResult):
                self.downloadProgress = 1
                self.downloadStatus = .succeed
                success?(self, avResult.avAsset, avResult.info)
            case .failure(let error):
                if AssetManager.assetCancelDownload(for: error.info) {
                    self.downloadStatus = .canceled
                }else {
                    self.downloadProgress = 0
                    self.downloadStatus = .failed
                }
                failure?(self, error.info, error.error)
            }
        }
    }
    
    @discardableResult
    func requestPlayerItem(
        filterEditor: Bool = false,
        deliveryMode: PHVideoRequestOptionsDeliveryMode = .automatic,
        iCloudHandler: PhotoAssetICloudHandler?,
        progressHandler: PhotoAssetProgressHandler?,
        success: ((PhotoAsset, AVPlayerItem) -> Void)?,
        failure: PhotoAssetFailureHandler?
    ) -> PHImageRequestID {
        #if HXPICKER_ENABLE_EDITOR
        if let videoEdit = videoEditedResult, !filterEditor {
            success?(self, .init(url: videoEdit.url))
            return 0
        }
        #endif
        guard let phAsset = phAsset else {
            if let localVideoURL = localVideoAsset?.videoURL {
                success?(self, .init(url: localVideoURL))
            }else if let networkVideoURL = networkVideoAsset?.videoURL {
                success?(self, .init(url: networkVideoURL))
            }else {
                failure?(self, nil, .invalidPHAsset)
            }
            return 0
        }
        if downloadStatus != .succeed {
            downloadStatus = .downloading
        }
        return AssetManager.requestPlayerItem(
            for: phAsset,
            deliveryMode: deliveryMode
        ) { (iCloudRequestID) in
            iCloudHandler?(self, iCloudRequestID)
        } progressHandler: { (progress, _, _, _) in
            self.downloadProgress = progress
            DispatchQueue.main.async {
                progressHandler?(self, progress)
            }
        } resultHandler: { (result) in
            switch result {
            case .success(let playerItem):
                self.downloadProgress = 1
                self.downloadStatus = .succeed
                success?(self, playerItem)
            case .failure(let error):
                if AssetManager.assetCancelDownload(for: error.info) {
                    self.downloadStatus = .canceled
                }else {
                    self.downloadProgress = 0
                    self.downloadStatus = .failed
                }
                failure?(self, error.info, error.error)
            }
        }
    }
}


@available(iOS 13.0, *)
public extension PhotoAsset {
    
    func requesthumbnailImage(
        targetWidth: CGFloat = 180,
        didRequestHandler: ((PhotoAsset, PHImageRequestID) -> Void)? = nil
    ) async throws -> UIImage {
        try await withCheckedThrowingContinuation { continuation in
            var didResume: Bool = false
            let requestId = requestThumbnailImage(targetWidth: targetWidth) { image, _, info in
                if didResume { return }
                if let isError = info?.isError, isError {
                    continuation.resume(throwing: AssetError.requestFailed(info))
                    didResume = true
                    return
                }
                if !AssetManager.assetIsDegraded(for: info) {
                    if let image {
                        continuation.resume(returning: image)
                    }else {
                        continuation.resume(throwing: AssetError.requestFailed(info))
                    }
                    didResume = true
                }
            }
            if let requestId {
                didRequestHandler?(self, requestId)
            }
        }
    }
    
    func requestPreviewImage(
        didRequestHandler: ((PhotoAsset, PHImageRequestID) -> Void)? = nil,
        iCloudHandler: PhotoAssetICloudHandler? = nil,
        progressHandler: PhotoAssetProgressHandler? = nil
    ) async throws -> UIImage {
        try await withCheckedThrowingContinuation { continuation in
            var didResume: Bool = false
            let requestId = requestImage(iCloudHandler: iCloudHandler, progressHandler: progressHandler) { _, image, info in
                if didResume { return }
                if let isError = info?.isError, isError {
                    continuation.resume(throwing: AssetError.requestFailed(info))
                    didResume = true
                    return
                }
                if !AssetManager.assetIsDegraded(for: info) {
                    if let image {
                        continuation.resume(returning: image)
                    }else {
                        continuation.resume(throwing: AssetError.requestFailed(info))
                    }
                    didResume = true
                }
            }
            if let requestId {
                didRequestHandler?(self, requestId)
            }
        }
    }
    
    func requestAVAsset(
        didRequestHandler: ((PhotoAsset, PHImageRequestID) -> Void)? = nil,
        iCloudHandler: PhotoAssetICloudHandler? = nil,
        progressHandler: PhotoAssetProgressHandler? = nil
    ) async throws -> AVAsset {
        try await withCheckedThrowingContinuation { continuation in
            let requestId = requestAVAsset(iCloudHandler: iCloudHandler, progressHandler: progressHandler) { _, avAsset, _ in
                continuation.resume(returning: avAsset)
            } failure: { _, _, error in
                continuation.resume(throwing: error)
            }
            didRequestHandler?(self, requestId)
        }
    }
    
    func requestPlayerItem(
        didRequestHandler: ((PhotoAsset, PHImageRequestID) -> Void)? = nil,
        iCloudHandler: PhotoAssetICloudHandler? = nil,
        progressHandler: PhotoAssetProgressHandler? = nil
    ) async throws -> AVPlayerItem {
        try await withCheckedThrowingContinuation { continuation in
            let requestId = requestPlayerItem(iCloudHandler: iCloudHandler, progressHandler: progressHandler) { _, playerItem in
                continuation.resume(returning: playerItem)
            } failure: { _, _, error in
                continuation.resume(throwing: error)
            }
            didRequestHandler?(self, requestId)
        }
    }
    
    func requestLivePhoto(
        targetSize: CGSize = .zero,
        didRequestHandler: ((PhotoAsset, PHImageRequestID?, LocalLivePhotoRequest?) -> Void)? = nil,
        iCloudHandler: PhotoAssetICloudHandler? = nil,
        progressHandler: PhotoAssetProgressHandler? = nil
    ) async throws -> PHLivePhoto {
        let screenSize = await UIScreen._size
        return try await withCheckedThrowingContinuation { continuation in
            if mediaSubType == .localLivePhoto {
                let request = requestLocalLivePhoto { _, livePhoto in
                    continuation.resume(returning: livePhoto)
                } failure: { _, _, error in
                    continuation.resume(throwing: error)
                }
                didRequestHandler?(self, nil, request)
            }else {
                let size = targetSize.equalTo(.zero) ? screenSize : targetSize
                let request = requestLivePhoto(targetSize: size, iCloudHandler: iCloudHandler, progressHandler: progressHandler) { _, livePhoto, _ in
                    continuation.resume(returning: livePhoto)
                } failure: { _, _, error in
                    continuation.resume(throwing: error)
                }
                didRequestHandler?(self, request, nil)
            }
        }
    }
}

extension PhotoAsset {
    @discardableResult
    func requestThumImage(
        filterEditor: Bool = false,
        iCloudHandler: PhotoAssetICloudHandler? = nil,
        progressHandler: PhotoAssetProgressHandler? = nil,
        resultHandler: @escaping (PhotoAsset, UIImage?, [AnyHashable: Any]?) -> Void
    ) -> PHImageRequestID? {
        #if HXPICKER_ENABLE_EDITOR
        if let photoEdit = photoEditedResult {
            resultHandler(self, photoEdit.image, nil)
            return nil
        }
        if let videoEdit = videoEditedResult {
            resultHandler(self, videoEdit.coverImage, nil)
            return nil
        }
        #endif
        guard let phAsset else {
            requestLocalImage(
                urlType: .original,
                targetWidth: AssetManager.thumbnailTargetWidth
            ) { (image, photoAsset) in
                resultHandler(photoAsset, image, nil)
            }
            return nil
        }
        return AssetManager.requestImage(for: phAsset, targetSize: phAsset.thumTargetSize, resizeMode: .fast) {
            iCloudHandler?(self, $0)
        } progressHandler: { progress, error, stop, info in
            DispatchQueue.main.async {
                progressHandler?(self, progress)
            }
        } resultHandler: {
            resultHandler(self, $0, $1)
        }
    }
}
