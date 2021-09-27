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
    ///   - resultHandler: 获取结果
    func requestImageURL(
        toFile fileURL: URL? = nil,
        resultHandler: @escaping AssetURLCompletion
    ) {
        if phAsset == nil {
            requestLocalImageURL(
                toFile: fileURL,
                resultHandler: resultHandler
            )
            return
        }
        requestAssetImageURL(
            toFile: fileURL,
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
        resultHandler: ((PhotoAsset, Result<ImageDataResult, AssetManager.ImageDataError>
        ) -> Void)?) -> PHImageRequestID {
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
        downloadStatus = .downloading
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
        downloadStatus = .downloading
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
        completion: @escaping (Result<AssetURLResult, AssetError>) -> Void
    ) {
        #if HXPICKER_ENABLE_EDITOR
        if let photoEdit = photoEdit {
            completion(
                .success(
                    .init(
                        url: photoEdit.editedImageURL,
                        urlType: .local,
                        mediaType: .photo,
                        livePhoto: nil
                    )
                )
            )
            return
        }
        #endif
        guard let phAsset = phAsset else {
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
                completion(
                    .success(
                        .init(
                            url: imageURL!,
                            urlType: .local,
                            mediaType: .photo,
                            livePhoto: .init(
                                imageURL: imageURL!,
                                videoURL: videoURL!
                            )
                        )
                    )
                )
            }
        }

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
        videoQuality: Int = 5,
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
        if phAsset == nil {
            if let localVideoURL = localVideoAsset?.videoURL {
                success?(self, AVAsset.init(url: localVideoURL), nil)
            }else if let networkVideoURL = networkVideoAsset?.videoURL {
                success?(self, AVAsset.init(url: networkVideoURL), nil)
            }else {
                failure?(self, nil, .invalidPHAsset)
            }
            return 0
        }
        downloadStatus = .downloading
        return AssetManager.requestAVAsset(for: phAsset!, deliveryMode: deliveryMode) { (iCloudRequestID) in
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
