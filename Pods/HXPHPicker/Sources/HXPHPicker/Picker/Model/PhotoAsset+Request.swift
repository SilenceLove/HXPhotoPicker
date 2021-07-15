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
    
    /// 获取图片（系统相册获取的是压缩后的，不是原图）
    @discardableResult
    func requestImage(completion: ((UIImage?, PhotoAsset) -> Void)?) -> PHImageRequestID? {
        #if HXPICKER_ENABLE_EDITOR
        if let photoEdit = photoEdit {
            completion?(photoEdit.editedImage, self)
            return nil
        }
        if let videoEdit = videoEdit {
            completion?(videoEdit.coverImage, self)
            return nil
        }
        #endif
        if phAsset == nil {
            requestLocalImage(urlType: .original) { (image, photoAsset) in
                completion?(image, photoAsset)
            }
            return nil
        }
        let options = PHImageRequestOptions.init()
        options.resizeMode = .fast
        options.deliveryMode = .highQualityFormat
        options.isNetworkAccessAllowed = true
        return AssetManager.requestImageData(for: phAsset!, version: isGifAsset ? .original : .current, iCloudHandler: nil, progressHandler: nil) { (imageData, dataUTI, imageOrientation, info, success) in
            if let imageData = imageData {
                var image = UIImage.init(data: imageData)
                if image?.imageOrientation != UIImage.Orientation.up {
                    image = image?.normalizedImage()
                }
                image = image?.scaleImage(toScale: 0.5)
                completion?(image, self)
            }else {
                completion?(nil, self)
            }
        }
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
            requestLocalImage(urlType: .thumbnail) { (image, photoAsset) in
                completion?(image, photoAsset, nil)
            }
            return nil
        }
        return AssetManager.requestThumbnailImage(for: phAsset!, targetWidth: targetWidth) { (image, info) in
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
    func requestImageData(filterEditor: Bool = false,
                          iCloudHandler: PhotoAssetICloudHandler?,
                          progressHandler: PhotoAssetProgressHandler?,
                          success: ((PhotoAsset, Data, UIImage.Orientation, [AnyHashable : Any]?) -> Void)?,
                          failure: PhotoAssetFailureHandler?) -> PHImageRequestID {
        #if HXPICKER_ENABLE_EDITOR
        if let photoEdit = photoEdit, !filterEditor {
            do {
                let imageData = try Data.init(contentsOf: photoEdit.editedImageURL)
                success?(self, imageData, photoEdit.editedImage.imageOrientation, nil)
            }catch {
                failure?(self, nil)
            }
            return 0
        }
        if let videoEdit = videoEdit, !filterEditor {
            let imageData = PhotoTools.getImageData(for: videoEdit.coverImage)
            if let imageData = imageData {
                success?(self, imageData, videoEdit.coverImage!.imageOrientation, nil)
            }else {
                failure?(self, nil)
            }
            return 0
        }
        #endif
        if phAsset == nil {
            requestlocalImageData { (imageData, photoAsset) in
                if let imageData = imageData {
                    let image = UIImage.init(data: imageData)
                    success?(photoAsset, imageData, image!.imageOrientation, nil)
                }else {
                    failure?(photoAsset, nil)
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
                          iCloudHandler: PhotoAssetICloudHandler?,
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
    
    /// 获取原始视频地址，系统相册里的视频需要自行压缩
    /// 网络视频如果在本地有缓存则会返回本地地址，如果没有缓存则为ni
    /// - Parameters:
    ///   - fileURL: 指定视频地址
    ///   - exportPreset: 导出质量，不传则获取的是原始视频地址
    ///   - resultHandler: 获取结果
    func requestVideoURL(toFile fileURL:URL? = nil,
                         exportPreset: String? = nil,
                         resultHandler: @escaping (URL?) -> Void) {
        if phAsset == nil {
            requestLocalVideoURL { (videoURL, photoAsset) in
                resultHandler(videoURL)
            }
            return
        }
        requestAssetVideoURL(toFile: fileURL,
                             exportPreset: exportPreset,
                             resultHandler: resultHandler)
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
                        iCloudHandler: PhotoAssetICloudHandler?,
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
