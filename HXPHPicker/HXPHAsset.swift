//
//  HXPHAsset.swift
//  HXPhotoPickerSwift
//
//  Created by Silence on 2020/11/12.
//  Copyright © 2020 Silence. All rights reserved.
//

import UIKit
import Photos

typealias HXPHAssetICloudHandlerHandler = (HXPHAsset, PHImageRequestID) -> Void
typealias HXPHAssetProgressHandler = (HXPHAsset, Double) -> Void
typealias HXPHAssetFailureHandler = (HXPHAsset, [AnyHashable : Any]?) -> Void

class HXPHAsset: NSObject {
    
    /// 系统相册里的资源
    var asset: PHAsset? {
        didSet {
            setMediaType()
        }
    }
    
    /// 媒体类型
    var mediaType: HXPHPicker.Asset.MediaType = .photo
    
    /// 媒体子类型
    var mediaSubType: HXPHPicker.Asset.MediaSubType = .image
    
    /// 原图
    var originalImage: UIImage? {
        get {
            return getOriginalImage()
        }
    }
    /// 获取图片原始地址
    func requestImageURL(resultHandler: @escaping (URL?) -> Void) {
        if asset == nil {
            requestLocalImageURL(resultHandler: resultHandler)
            return
        }
        requestAssetImageURL(resultHandler: resultHandler)
    }
    /// 获取视频原始地址
    func requestVideoURL(resultHandler: @escaping (URL?) -> Void) {
        if asset == nil {
            resultHandler(localVideoURL)
            return
        }
        requestAssetVideoURL(resultHandler: resultHandler)
    }

    /// 图片/视频大小
    var fileSize: Int {
        get {
            return getFileSize()
        }
    }
    
    /// 视频时长 格式：00:00
    var videoTime: String?
    
    /// 视频时长 秒
    var videoDuration: TimeInterval = 0
    
    /// 当前资源是否被选中
    var isSelected: Bool = false
    
    /// 选中时的下标
    var selectIndex: Int = 0
    
    /// 当前资源的图片大小
    var imageSize: CGSize {
        get {
            return getImageSize()
        }
    }
    
    /// iCloud下载状态
    var downloadStatus: HXPHPicker.Asset.DownloadStatus = .unknow
    
    /// iCloud下载进度，如果取消了会记录上次进度
    var downloadProgress: Double = 0
    
    /// 根据系统相册里对应的 PHAsset 数据初始化
    /// - Parameter asset: 系统相册里对应的 PHAsset 数据
    init(asset: PHAsset) {
        super.init()
        self.asset = asset
        setMediaType()
    }
    
    /// 根据系统相册里对应的 PHAsset本地唯一标识符 初始化
    /// - Parameter localIdentifier: 系统相册里对应的 PHAsset本地唯一标识符
    init(localIdentifier: String) {
        super.init()
        asset = HXPHAssetManager.fetchAsset(withLocalIdentifier: localIdentifier)
        setMediaType()
    }
    
    /// 根据本地image初始化
    /// - Parameter image: 对应的 UIImage 数据
    convenience init(image: UIImage?) {
        self.init(image: image, localIdentifier: String(Date.init().timeIntervalSince1970))
    }
    
    /// 根据本地 UIImage 和 自定义的本地唯一标识符 初始化
    /// 定义了唯一标识符，进入相册时内部会根据标识符自动选中对应的资源。请确保唯一标识符的正确性
    /// - Parameters:
    ///   - image: 对应的 UIImage 数据
    ///   - localIdentifier: 自定义的本地唯一标识符
    init(image: UIImage?, localIdentifier: String?) {
        super.init()
        localAssetIdentifier = localIdentifier
        localImage = image
        mediaType = .photo
        mediaSubType = .localImage
    }
    
    /// 根据本地videoURL初始化
    /// - Parameter videoURL: 对应的 URL 数据
    convenience init(videoURL: URL?) {
        self.init(videoURL: videoURL, localIdentifier: String(Date.init().timeIntervalSince1970))
    }
    
    /// 根据本地 videoURL 和 自定义的本地唯一标识符初始化
    /// 定义了唯一标识符，进入相册时内部会根据标识符自动选中对应的资源。请确保唯一标识符的正确性
    /// - Parameters:
    ///   - videoURL: 对应的 URL 数据
    ///   - localIdentifier: 自定义的本地唯一标识符
    init(videoURL: URL?, localIdentifier: String?) {
        super.init()
        localAssetIdentifier = localIdentifier
        localImage = HXPHTools.getVideoThumbnailImage(videoURL: videoURL, atTime: 0.1)
        videoDuration = HXPHTools.getVideoDuration(videoURL: videoURL)
        videoTime = HXPHTools.transformVideoDurationToString(duration: videoDuration)
        localVideoURL = videoURL
        mediaType = .video
        mediaSubType = .localVideo
    }
    
    /// 本地资源的唯一标识符
    var localAssetIdentifier: String?
    var localIndex: Int = 0
    private var localImage: UIImage?
    private var localVideoURL: URL?
    private var pFileSize: Int?
    
    /// 请求缩略图
    /// - Parameter completion: 完成回调
    /// - Returns: 请求ID
    func requestThumbnailImage(completion: ((UIImage?, HXPHAsset, [AnyHashable : Any]?) -> Void)?) -> PHImageRequestID? {
        return requestThumbnailImage(targetWidth: 180, completion: completion)
    }
    func requestThumbnailImage(targetWidth: CGFloat, completion: ((UIImage?, HXPHAsset, [AnyHashable : Any]?) -> Void)?) -> PHImageRequestID? {
        if asset == nil {
            completion?(localImage, self, nil)
            return nil
        }
        return HXPHAssetManager.requestThumbnailImage(for: asset!, targetWidth: targetWidth) { (image, info) in
            completion?(image, self, info)
        }
    }
    
    /// 请求imageData，如果资源在iCloud上会自动下载。如果需要更细节的处理请查看 PHAssetManager
    /// - Parameters:
    ///   - iCloudHandler: 下载iCloud上的资源时回调iCloud的请求ID
    ///   - progressHandler: iCloud下载进度
    /// - Returns: 请求ID
    func requestImageData(iCloudHandler: HXPHAssetICloudHandlerHandler?, progressHandler: HXPHAssetProgressHandler?, success: ((HXPHAsset, Data, UIImage.Orientation, [AnyHashable : Any]?) -> Void)?, failure: HXPHAssetFailureHandler?) -> PHImageRequestID {
        if asset == nil {
            failure?(self, nil)
            return 0
        }
        var version = PHImageRequestOptionsVersion.current
        if mediaSubType == .imageAnimated {
            version = .original
        }
        downloadStatus = .downloading
        return HXPHAssetManager.requestImageData(for: asset!, version: version, iCloudHandler: { (iCloudRequestID) in
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
                if HXPHAssetManager.assetDownloadCancel(for: info) {
                    self.downloadStatus = .canceled
                }else {
                    self.downloadProgress = 0
                    self.downloadStatus = .failed
                }
                failure?(self, info)
            }
        })
    }
    
    /// 请求LivePhoto，如果资源在iCloud上会自动下载。如果需要更细节的处理请查看 PHAssetManager
    /// - Parameters:
    ///   - targetSize: 请求的大小
    ///   - iCloudHandler: 下载iCloud上的资源时回调iCloud的请求ID
    ///   - progressHandler: iCloud下载进度
    /// - Returns: 请求ID
    @available(iOS 9.1, *)
    func requestLivePhoto(targetSize: CGSize, iCloudHandler: HXPHAssetICloudHandlerHandler?, progressHandler: HXPHAssetProgressHandler?, success: ((HXPHAsset, PHLivePhoto, [AnyHashable : Any]?) -> Void)?, failure: HXPHAssetFailureHandler?) -> PHImageRequestID {
        if asset == nil {
            failure?(self, nil)
            return 0
        }
        downloadStatus = .downloading
        return HXPHAssetManager.requestLivePhoto(for: asset!, targetSize: targetSize) { (iCloudRequestID) in
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
                if HXPHAssetManager.assetDownloadCancel(for: info) {
                    self.downloadStatus = .canceled
                }else {
                    self.downloadProgress = 0
                    self.downloadStatus = .failed
                }
                failure?(self, info)
            }
        }
    }
    
    /// 请求AVAsset，如果资源在iCloud上会自动下载。如果需要更细节的处理请查看 PHAssetManager
    /// - Parameters:
    ///   - iCloudHandler: 下载iCloud上的资源时回调iCloud的请求ID
    ///   - progressHandler: iCloud下载进度
    /// - Returns: 请求ID
    func requestAVAsset(iCloudHandler: HXPHAssetICloudHandlerHandler?, progressHandler: HXPHAssetProgressHandler?, success: ((HXPHAsset, AVAsset, [AnyHashable : Any]?) -> Void)?, failure: HXPHAssetFailureHandler?) -> PHImageRequestID {
        if asset == nil {
            if localVideoURL != nil {
                success?(self, AVAsset.init(url: localVideoURL!), nil)
            }else {
                failure?(self, nil)
            }
            return 0
        }
        downloadStatus = .downloading
        return HXPHAssetManager.requestAVAsset(for: asset!) { (iCloudRequestID) in
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
                if HXPHAssetManager.assetDownloadCancel(for: info) {
                    self.downloadStatus = .canceled
                }else {
                    self.downloadProgress = 0
                    self.downloadStatus = .failed
                }
                failure?(self, info)
            }
        }
    }
    
    func isEqual(_ photoAsset: HXPHAsset?) -> Bool {
        if photoAsset == nil {
            return false
        }
        if self == photoAsset {
            return true
        }
        if localAssetIdentifier != nil && photoAsset?.localAssetIdentifier != nil &&
            localAssetIdentifier == photoAsset?.localAssetIdentifier{
            return true
        }
        if localImage != nil && photoAsset?.localImage != nil && localImage == photoAsset?.localImage {
            return true
        }
        if localVideoURL != nil && photoAsset?.localVideoURL != nil && localVideoURL == photoAsset?.localVideoURL {
            return true
        }
        if asset != nil && photoAsset?.asset != nil && asset == photoAsset?.asset {
            return true
        }
        if asset?.localIdentifier != nil && photoAsset?.asset?.localIdentifier != nil && asset?.localIdentifier == photoAsset?.asset?.localIdentifier {
            return true
        }
        
        return false
    }
    
    func copyCamera() -> HXPHAsset {
        var photoAsset: HXPHAsset
        if mediaType == .photo {
            photoAsset = HXPHAsset.init(image: localImage, localIdentifier: localAssetIdentifier)
        }else {
            photoAsset = HXPHAsset.init(videoURL: localVideoURL, localIdentifier: localAssetIdentifier)
        }
        photoAsset.localIndex = localIndex
        return photoAsset
    }
    
    private func setMediaType() {
        if asset?.mediaType.rawValue == 1 {
            mediaType = .photo
            mediaSubType = .image
        }else if asset?.mediaType.rawValue == 2 {
            mediaType = .video
            mediaSubType = .video
            videoDuration = asset!.duration
            videoTime = HXPHTools.transformVideoDurationToString(duration: asset!.duration)
        }
    }
    private func getLocalImageData() -> Data? {
        return HXPHTools.getImageData(for: localImage)
    }
    private func getFileSize() -> Int {
        if let fileSize = pFileSize {
            return fileSize
        }
        var fileSize = 0
        if let photoAsset = asset {
            let assetResources = PHAssetResource.assetResources(for: photoAsset)
            let assetIsLivePhoto = HXPHAssetManager.assetIsLivePhoto(asset: photoAsset)
            for assetResource in assetResources {
                if assetIsLivePhoto && mediaSubType != .livePhoto {
                    if assetResource.type == .photo {
                        if let photoFileSize = assetResource.value(forKey: "fileSize") as? Int {
                            fileSize += photoFileSize
                        }
                    }
                }else {
                    if let photoFileSize = assetResource.value(forKey: "fileSize") as? Int {
                        fileSize += photoFileSize
                    }
                }
            }
        }else {
            if self.mediaType == .photo {
                if let imageData = getLocalImageData() {
                    fileSize = imageData.count
                }
            }else {
                if let videoURL = localVideoURL {
                    do {
                        let videofileSize = try videoURL.resourceValues(forKeys: [.fileSizeKey])
                        fileSize = videofileSize.fileSize ?? 0
                    } catch {}
                }
            }
        }
        pFileSize = fileSize
        return fileSize
    }
    private func getOriginalImage() -> UIImage? {
        if asset == nil {
            return localImage
        }
        let options = PHImageRequestOptions.init()
        options.isSynchronous = true
        options.isNetworkAccessAllowed = true
        options.deliveryMode = .highQualityFormat
        if mediaSubType == .imageAnimated {
            options.version = .original
        }
        var originalImage: UIImage?
        _ = HXPHAssetManager.requestImageData(for: asset!, options: options) { (imageData, dataUTI, orientation, info) in
            if imageData != nil {
                originalImage = UIImage.init(data: imageData!)
                if self.mediaSubType != .imageAnimated && HXPHAssetManager.assetIsAnimated(asset: self.asset!) {
                    // 原始图片是动图，但是设置的是不显示动图，所以在这里处理一下
                    originalImage = originalImage?.images?.first
                }
            }
        }
        return originalImage
    }
    private func getImageSize() -> CGSize {
        let size : CGSize
        if asset != nil {
            if asset!.pixelWidth == 0 || asset!.pixelHeight == 0 {
                size = CGSize(width: 200, height: 200)
            }else {
                size = CGSize(width: asset!.pixelWidth, height: asset!.pixelHeight)
            }
        }else {
            size = localImage?.size ?? CGSize(width: 200, height: 200)
        }
        return size
    }
    
    /// 获取本地图片地址
    private func requestLocalImageURL(resultHandler: @escaping (URL?) -> Void) {
        DispatchQueue.global().async {
            if let imageData = self.getLocalImageData() {
                let imageURL = HXPHTools.getImageTmpURL()
                do {
                    try imageData.write(to: imageURL)
                    DispatchQueue.main.async {
                        resultHandler(imageURL)
                    }
                } catch {
                    DispatchQueue.main.async {
                        resultHandler(nil)
                    }
                }
            }else {
                DispatchQueue.main.async {
                    resultHandler(nil)
                }
            }
        }
    }
    private func requestAssetImageURL(resultHandler: @escaping (URL?) -> Void) {
        if asset == nil {
            return
        }
        var suffix: String
        if mediaSubType == .imageAnimated {
            suffix = "gif"
        }else {
            suffix = "jpeg"
        }
        HXPHAssetManager.requestImageURL(for: asset!, suffix: suffix) { (imageURL) in
            if HXPHAssetManager.assetIsAnimated(asset: self.asset!) && self.mediaSubType != .imageAnimated && imageURL != nil {
                // 本质上是gif，需要变成静态图
                let image = UIImage.init(contentsOfFile: imageURL!.path)
                if let imageData = HXPHTools.getImageData(for: image) {
                    do {
                        let tempURL = HXPHTools.getImageTmpURL()
                        try imageData.write(to: tempURL)
                        resultHandler(tempURL)
                    } catch {
                        resultHandler(nil)
                    }
                }else {
                    resultHandler(nil)
                }
            }else {
                resultHandler(imageURL)
            }
        }
    }
    private func requestAssetVideoURL(resultHandler: @escaping (URL?) -> Void) {
        if mediaSubType == .livePhoto {
            var videoURL: URL?
            HXPHAssetManager.requestLivePhoto(content: asset!) { (imageData) in
            } videoHandler: { (url) in
                videoURL = url
            } completionHandler: { (error) in
                resultHandler(videoURL)
            }
        }else {
            HXPHAssetManager.requestVideoURL(mp4Format: asset!) { (videoURL) in
                resultHandler(videoURL)
            }
        }
    }
}
