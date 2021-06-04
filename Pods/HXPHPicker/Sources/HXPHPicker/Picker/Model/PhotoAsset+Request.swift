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
    
    /// 获取原始图片地址
    /// 网络图片获取方法 getNetworkImageURL
    /// - Parameters:
    ///   - fileURL: 指定图片的本地地址
    ///   - resultHandler: 获取结果
    func requestImageURL(toFile fileURL:URL? = nil,
                         resultHandler: @escaping (URL?) -> Void) {
        if phAsset == nil {
            requestLocalImageURL(toFile: fileURL, resultHandler: resultHandler)
            return
        }
        requestAssetImageURL(toFile: fileURL, resultHandler: resultHandler)
    }
    
    /// 请求获取缩略图
    /// - Parameter completion: 完成回调
    /// - Returns: 请求ID
    @discardableResult
    func requestThumbnailImage(targetWidth: CGFloat = 180,
                               completion: ((UIImage?, PhotoAsset, [AnyHashable : Any]?) -> Void)?) -> PHImageRequestID? {
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
        if phAsset == nil {
            if mediaType == .photo {
                if let image = localImageAsset?.image {
                    completion?(image, self, nil)
                    return nil
                }
                if isNetworkAsset {
                    #if canImport(Kingfisher)
                    getNetworkImage(urlType: .thumbnail) { (image) in
                        completion?(image, self, nil)
                    }
                    #endif
                    return nil
                }
                DispatchQueue.global().async {
                    if let imageURL = self.localImageAsset?.imageURL, let image = UIImage.init(contentsOfFile: imageURL.path) {
                        self.localImageAsset?.image = image
                        DispatchQueue.main.async {
                            completion?(image, self, nil)
                        }
                    }
                }
            }else {
                PhotoTools.getVideoCoverImage(for: self) { (photoAsset, image) in
                    completion?(image, photoAsset, nil)
                }
            }
            return nil
        }
        return AssetManager.requestThumbnailImage(for: phAsset!, targetWidth: targetWidth) { (image, info) in
            completion?(image, self, info)
        }
    }
    
    /// 请求imageData，如果资源在iCloud上会自动下载。如果需要更细节的处理请查看 PHAssetManager+Asset
    /// - Parameters:
    ///   - iCloudHandler: 下载iCloud上的资源时回调iCloud的请求ID
    ///   - progressHandler: iCloud下载进度
    /// - Returns: 请求ID
    @discardableResult
    func requestImageData(iCloudHandler: PhotoAssetICloudHandlerHandler?,
                          progressHandler: PhotoAssetProgressHandler?,
                          success: ((PhotoAsset, Data, UIImage.Orientation, [AnyHashable : Any]?) -> Void)?,
                          failure: PhotoAssetFailureHandler?) -> PHImageRequestID {
        #if HXPICKER_ENABLE_EDITOR
        if let photoEdit = photoEdit {
            DispatchQueue.global().async {
                do {
                    let imageData = try Data.init(contentsOf: photoEdit.editedImageURL)
                    DispatchQueue.main.async {
                        success?(self, imageData, photoEdit.editedImage.imageOrientation, nil)
                    }
                }catch {
                    DispatchQueue.main.async {
                        failure?(self, nil)
                    }
                }
            }
            return 0
        }
        if let videoEdit = videoEdit {
            DispatchQueue.global().async {
                let imageData = PhotoTools.getImageData(for: videoEdit.coverImage)
                DispatchQueue.main.async {
                    if let imageData = imageData {
                        success?(self, imageData, videoEdit.coverImage!.imageOrientation, nil)
                    }else {
                        failure?(self, nil)
                    }
                }
            }
            return 0
        }
        #endif
        if phAsset == nil {
            DispatchQueue.global().async {
                if let imageData = self.localImageAsset?.imageData {
                    let image = UIImage.init(data: imageData)
                    success?(self, imageData, image?.imageOrientation ?? .up, nil)
                }else if let imageURL = self.localImageAsset?.imageURL {
                    do {
                        let imageData = try Data.init(contentsOf: imageURL)
                        let image = UIImage.init(data: imageData)
                        DispatchQueue.main.async {
                            success?(self, imageData, image?.imageOrientation ?? .up, nil)
                        }
                    }catch {
                        DispatchQueue.main.async {
                            failure?(self, nil)
                        }
                    }
                }else if let localImage = self.localImageAsset?.image {
                        let imageData = PhotoTools.getImageData(for: localImage)
                        DispatchQueue.main.async {
                            if let imageData = imageData {
                                success?(self, imageData, localImage.imageOrientation, nil)
                            }else {
                                failure?(self, nil)
                            }
                        }
                }else {
                    if self.isNetworkAsset {
                        #if canImport(Kingfisher)
                        self.getNetworkImage {  (image) in
                            if let imageData = image?.kf.gifRepresentation() {
                                success?(self, imageData, image!.imageOrientation, nil)
                                return
                            }
                            let imageData = PhotoTools.getImageData(for: image)
                            DispatchQueue.main.async {
                                if let imageData = imageData {
                                    success?(self, imageData, image!.imageOrientation, nil)
                                }else {
                                    failure?(self, nil)
                                }
                            }
                        }
                        #endif
                    }else {
                        DispatchQueue.main.async {
                            failure?(self, nil)
                        }
                    }
                }
            }
            return 0
        }
        var version = PHImageRequestOptionsVersion.current
        if mediaSubType == .imageAnimated {
            version = .original
        }
        downloadStatus = .downloading
        return AssetManager.requestImageData(for: phAsset!, version: version, iCloudHandler: { (iCloudRequestID) in
            iCloudHandler?(self, iCloudRequestID)
        }, progressHandler: { (progress, error, stop, info) in
            self.downloadProgress = progress
            DispatchQueue.main.async {
                progressHandler?(self, progress)
            }
        }, resultHandler: { (data, dataUTI, imageOrientation, info, downloadSuccess) in
            if downloadSuccess {
                self.downloadProgress = 1
                self.downloadStatus = .succeed
                success?(self, data!, imageOrientation, info)
            }else {
                if AssetManager.assetCancelDownload(for: info) {
                    self.downloadStatus = .canceled
                }else {
                    self.downloadProgress = 0
                    self.downloadStatus = .failed
                }
                failure?(self, info)
            }
        })
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
    func requestLivePhoto(targetSize: CGSize,
                          iCloudHandler: PhotoAssetICloudHandlerHandler?,
                          progressHandler: PhotoAssetProgressHandler?,
                          success: ((PhotoAsset, PHLivePhoto, [AnyHashable : Any]?) -> Void)?,
                          failure: PhotoAssetFailureHandler?) -> PHImageRequestID {
        if phAsset == nil {
            failure?(self, nil)
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
                failure?(self, info)
            }
        }
    }
}


// MARK: Request Video
public extension PhotoAsset {
    
    /// 获取原始视频地址
    /// 网络视频如果在本地有缓存则会返回本地地址，如果没有缓存则为ni
    /// - Parameters:
    ///   - fileURL: 指定视频地址
    ///   - resultHandler: 获取结果
    func requestVideoURL(toFile fileURL:URL? = nil,
                         resultHandler: @escaping (URL?) -> Void) {
        #if HXPICKER_ENABLE_EDITOR
        if let videoEdit = videoEdit {
            if let fileURL = fileURL {
                if PhotoTools.copyFile(at: videoEdit.editedURL, to: fileURL) {
                    resultHandler(fileURL)
                }else {
                    resultHandler(nil)
                }
                return
            }
            resultHandler(videoEdit.editedURL)
            return
        }
        #endif
        if phAsset == nil {
            if mediaType == .photo {
                resultHandler(nil)
            }else {
                var videoURL: URL? = nil
                if isNetworkAsset {
                    let key = networkVideoAsset!.videoURL.absoluteString
                    if PhotoTools.isCached(forVideo: key) {
                        videoURL = PhotoTools.getVideoCacheURL(for: key)
                    }
                }else {
                    videoURL = localVideoAsset?.videoURL
                }
                if let fileURL = fileURL, let videoURL = videoURL {
                    if PhotoTools.copyFile(at: videoURL, to: fileURL) {
                        resultHandler(fileURL)
                    }else {
                        resultHandler(nil)
                    }
                    return
                }else {
                    resultHandler(videoURL)
                }
            }
            return
        }
        requestAssetVideoURL(toFile: fileURL, resultHandler: resultHandler)
    }
    
    /// 请求AVAsset，如果资源在iCloud上会自动下载。如果需要更细节的处理请查看 PHAssetManager+Asset
    /// - Parameters:
    ///   - filterEditor: 过滤编辑过的视频，取原视频
    ///   - iCloudHandler: 下载iCloud上的资源时回调iCloud的请求ID
    ///   - progressHandler: iCloud下载进度
    /// - Returns: 请求ID
    @discardableResult
    func requestAVAsset(filterEditor: Bool = false,
                        deliveryMode: PHVideoRequestOptionsDeliveryMode = .automatic,
                        iCloudHandler: PhotoAssetICloudHandlerHandler?,
                        progressHandler: PhotoAssetProgressHandler?,
                        success: ((PhotoAsset, AVAsset, [AnyHashable : Any]?) -> Void)?,
                        failure: PhotoAssetFailureHandler?) -> PHImageRequestID {
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
                failure?(self, nil)
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
        } resultHandler: { (avAsset, audioMix, info, downloadSuccess) in
            if downloadSuccess {
                self.downloadProgress = 1
                self.downloadStatus = .succeed
                success?(self, avAsset!, info)
            }else {
                if AssetManager.assetCancelDownload(for: info) {
                    self.downloadStatus = .canceled
                }else {
                    self.downloadProgress = 0
                    self.downloadStatus = .failed
                }
                failure?(self, info)
            }
        }
    }
}
