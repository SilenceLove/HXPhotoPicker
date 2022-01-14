//
//  PhotoAsset+Request.swift
//  HXPHPicker
//
//  Created by Slience on 2021/3/11.
//

import UIKit
import Photos

// MARK: Request Photo
public extension PhotoAsset {
    
    struct ImageDataResult {
        let imageData: Data
        let imageOrientation: UIImage.Orientation
        let info: [AnyHashable: Any]?
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
    ///   - compressionScale: 压缩比例，获取系统相册里的资源时有效 
    ///   - completion: 获取完成
    /// - Returns: 请求系统相册资源的请求id
    @discardableResult
    func requestImage(
        compressionScale: CGFloat = 0.5,
        completion: ((UIImage?, PhotoAsset) -> Void)?
    ) -> PHImageRequestID? {
        #if HXPICKER_ENABLE_EDITOR
        if let photoEdit = photoEdit {
            completion?(
                UIImage(
                    contentsOfFile: photoEdit.editedImageURL.path
                ),
                self
            )
            return nil
        }
        if let videoEdit = videoEdit {
            completion?(
                videoEdit.coverImage,
                self
            )
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
        let options = PHImageRequestOptions.init()
        options.resizeMode = .fast
        options.deliveryMode = .highQualityFormat
        options.isNetworkAccessAllowed = true
        return AssetManager.requestImageData(
            for: phAsset,
            version: isGifAsset ? .original : .current,
            iCloudHandler: nil,
            progressHandler: nil
        ) { (result) in
            switch result {
            case .success(let dataResult):
                let image = UIImage(
                    data: dataResult.imageData
                )?
                .normalizedImage()?
                .scaleImage(toScale: compressionScale)
                completion?(image, self)
            case .failure(_):
                completion?(nil, self)
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
        if let photoEdit = photoEdit {
            completion?(photoEdit.editedImage, self, nil)
            return nil
        }
        if let videoEdit = videoEdit {
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
        iCloudHandler: PhotoAssetICloudHandler?,
        progressHandler: PhotoAssetProgressHandler?,
        resultHandler: (
            (PhotoAsset, Result<ImageDataResult, AssetManager.ImageDataError>
        ) -> Void)?
    ) -> PHImageRequestID {
        #if HXPICKER_ENABLE_EDITOR
        if let photoEdit = photoEdit, !filterEditor {
            do {
                let imageData = try Data.init(contentsOf: photoEdit.editedImageURL)
                resultHandler?(
                    self,
                    .success(
                        .init(
                            imageData: imageData,
                            imageOrientation: photoEdit.editedImage.imageOrientation,
                            info: nil
                        )
                    )
                )
            }catch {
                resultHandler?(self, .failure(.init(info: nil, error: .invalidData)))
            }
            return 0
        }
        if let videoEdit = videoEdit, !filterEditor {
            let imageData = PhotoTools.getImageData(for: videoEdit.coverImage)
            if let imageData = imageData {
                resultHandler?(
                    self,
                    .success(
                        .init(
                            imageData: imageData,
                            imageOrientation: videoEdit.coverImage!.imageOrientation,
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
        } progressHandler: { progress, error, stop, info in
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
        if phAsset == nil {
            failure?(self, nil, .invalidPHAsset)
            return 0
        }
        if downloadStatus != .succeed {
            downloadStatus = .downloading
        }
        return AssetManager.requestLivePhoto(for: phAsset!, targetSize: targetSize) { (iCloudRequestID) in
            iCloudHandler?(self, iCloudRequestID)
        } progressHandler: { (progress, error, stop, info) in
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
        compression: Compression? = nil,
        completion: @escaping AssetURLCompletion
    ) {
        #if HXPICKER_ENABLE_EDITOR
        if photoEdit != nil {
            getEditedImageURL(
                compressionQuality: compression?.imageCompressionQuality,
                resultHandler: completion
            )
            return
        }
        #endif
        guard let phAsset = phAsset else {
            if mediaSubType == .localLivePhoto {
                requestLocalLivePhotoURL(
                    compression: compression,
                    completion: completion
                )
                return
            }
            completion(.failure(.invalidPHAsset))
            return
        }
        var imageURL: URL?
        var videoURL: URL?
        AssetManager.requestLivePhoto(contentURL: phAsset) { url in
            imageURL  = url
        } videoHandler: { url in
            videoURL  = url
        } completionHandler: { error in
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
                        compressionQuality: compressionQuality
                    ) {
                        return PhotoTools.write(imageData: data)
                    }
                    return nil
                }
                func videoCompressor(
                    _ url: URL,
                    _ exportPreset: ExportPreset,
                    _ videoQuality: Int,
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
                            exportPreset: exportPreset,
                            videoQuality: videoQuality) { video_URL, error in
                                if FileManager.default.fileExists(atPath: url.path) {
                                    try? FileManager.default.removeItem(at: url)
                                }
                                completionHandler?(video_URL, error)
                            }
                    }
                }
                if let imageCompression = compression?.imageCompressionQuality,
                   let videoExportPreset = compression?.videoExportPreset,
                   let videoQuality = compression?.videoQuality {
                    let group = DispatchGroup()
                    let imageQueue = DispatchQueue(label: "hxphpicker.request.livephoto.imageurl")
                    var image_URL: URL?
                    var video_URL: URL?
                    imageQueue.async(group: group, execute: DispatchWorkItem(block: {
                        image_URL = imageCompressor(imageURL!, imageCompression)
                    }))
                    let videoQueue = DispatchQueue(label: "hxphpicker.request.livephoto.videourl")
                    let semaphore = DispatchSemaphore(value: 0)
                    videoQueue.async(group: group, execute: DispatchWorkItem(block: {
                        videoCompressor(videoURL!, videoExportPreset, videoQuality) { url, error in
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
                        let url = imageCompressor(imageURL!, imageCompression)
                        DispatchQueue.main.async {
                            completionFunc(url, videoURL)
                        }
                    }
                }else if let videoExportPreset = compression?.videoExportPreset,
                         let videoQuality = compression?.videoQuality {
                    DispatchQueue.global().async {
                        videoCompressor(videoURL!, videoExportPreset, videoQuality) { url, error in
                            DispatchQueue.main.async {
                                completionFunc(imageURL, url)
                            }
                        }
                    }
                }else {
                    completionFunc(imageURL, videoURL)
                }
            }
        }
    }
    
    class LocalLivePhotoRequest {
        var videoURL: URL
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
        
        func cancelRequest() {
            isCancel = true
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
        success: ((PhotoAsset, PHLivePhoto) -> Void)? = nil,
        failure: PhotoAssetFailureHandler? = nil
    ) -> LocalLivePhotoRequest? {
        guard let livePhoto = localLivePhoto else {
            failure?(self, nil, .localLivePhotoIsEmpty)
            return nil
        }
        let videoURL = livePhoto.videoURL
        let request = LocalLivePhotoRequest(videoURL: videoURL)
        func write(videoURL: URL) {
            DispatchQueue.global().async {
                PhotoTools.getLivePhotoJPGURL(livePhoto.imageURL) { url in
                    guard let imageURL = url else {
                        DispatchQueue.main.async {
                            URLHandler?(nil, nil)
                            failure?(self, nil, .localLivePhotoWriteImageFailed)
                        }
                        return
                    }
                    if request.isCancel {
                        DispatchQueue.main.async {
                            URLHandler?(imageURL, nil)
                            failure?(self, nil, .localLivePhotoCancelWrite)
                        }
                        return
                    }
                    PhotoTools.getLivePhotoVideoMovURL(
                        videoURL
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
                                failure?(self, nil, .localLivePhotoWriteVideoFailed)
                            }
                            return
                        }
                        DispatchQueue.main.async {
                            URLHandler?(imageURL, videoURL)
                        }
                        if success == nil && failure == nil {
                            return
                        }
                        let image = UIImage(contentsOfFile: imageURL.path)
                        request.requestID = PHLivePhoto.request(
                            withResourceFileURLs: [videoURL, imageURL],
                            placeholderImage: image,
                            targetSize: .zero,
                            contentMode: .aspectFill
                        ) { phLivePhoto, info in
                            guard let phLivePhoto = phLivePhoto else {
                                DispatchQueue.main.async {
                                    failure?(self, nil, .localLivePhotoWriteVideoFailed)
                                }
                                return
                            }
                            let isDegraded = info[PHLivePhotoInfoIsDegradedKey] as? Int
                            let isCancel = info[PHLivePhotoInfoCancelledKey] as? Int
                            DispatchQueue.main.async {
                                if let isDegraded = isDegraded {
                                    if isDegraded == 0 {
                                        success?(self, phLivePhoto)
                                    }
                                }else if let isCancel = isCancel {
                                    if isCancel == 0 {
                                        success?(self, phLivePhoto)
                                    }else {
                                        failure?(self, info, .localLivePhotoRequestFailed)
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        if videoURL.isFileURL {
            write(videoURL: videoURL)
        }else {
            PhotoManager.shared.downloadTask(with: videoURL) { url, error, ext in
                guard let videoURL = url else {
                    URLHandler?(nil, nil)
                    failure?(self, nil, .videoDownloadFailed)
                    return
                }
                write(videoURL: videoURL)
            }
        }
        return request
    }
    
    func requestLocalLivePhotoURL(
        compression: Compression? = nil,
        completion: @escaping AssetURLCompletion
    ) {
        #if HXPICKER_ENABLE_EDITOR
        if photoEdit != nil {
            getEditedImageURL(
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
        let imageURL = localLivePhoto.imageURL
        let videoURL = localLivePhoto.videoURL
        completion(
            .success(
                .init(
                    url: imageURL,
                    urlType: .local,
                    mediaType: .photo,
                    livePhoto: .init(
                        imageURL: imageURL,
                        imageURLType: .local,
                        videoURL: videoURL,
                        videoURLType: videoURL.isFileURL ? .local : .network
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
    ///   - exportPreset: 视频分辨率，不传获取的就是原始视频
    ///   - videoQuality: 视频质量[0-10]
    ///   - resultHandler: 获取结果
    func requestVideoURL(
        toFile fileURL: URL? = nil,
        exportPreset: ExportPreset? = nil,
        videoQuality: Int? = 5,
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
            exportPreset: exportPreset,
            videoQuality: videoQuality,
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
        if let videoEdit = videoEdit, !filterEditor {
            success?(self, AVAsset.init(url: videoEdit.editedURL), nil)
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
        } progressHandler: { (progress, error, stop, info) in
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
}
