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
    /// 获取视频原始地址
    func requestVideoURL(resultHandler: @escaping (URL?) -> Void) {
        if asset == nil {
            resultHandler(localVideoURL)
            return
        }
        if mediaSubType == .livePhoto {
            var videoURL: URL?
            HXPHAssetManager.requestLivePhotoContent(for: asset!) { (imageData) in
            } videoHandler: { (url) in
                videoURL = url
            } completionHandler: { (error) in
                resultHandler(videoURL)
            }
        }else {
            HXPHAssetManager.requestVideoURL(for: asset!) { (videoURL) in
                resultHandler(videoURL)
            }
        }
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
    
    /// 本地资源的唯一标识符
    var localAssetIdentifier: String?
    var localIndex: Int = 0
    private var localImage: UIImage?
    private var localVideoURL: URL?
    private var pFileSize: Int?
    
    init(asset: PHAsset) {
        super.init()
        self.asset = asset
        setMediaType()
    }
    init(localIdentifier: String) {
        super.init()
        asset = HXPHAssetManager.fetchAsset(withLocalIdentifier: localIdentifier)
        setMediaType()
    }
    convenience init(image: UIImage?) {
        self.init(image: image, localIdentifier: nil)
    }
    init(image: UIImage?, localIdentifier: String?) {
        super.init()
        localAssetIdentifier = localIdentifier
        localImage = image
        mediaType = .photo
        mediaSubType = .localImage
    }
    convenience init(videoURL: URL?) {
        self.init(videoURL: videoURL, localIdentifier: nil)
    }
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
        return HXPHAssetManager.requestImageData(for: asset!, version: version, iCloudHandler: { (iCloudRequestID) in
            iCloudHandler?(self, iCloudRequestID)
        }, progressHandler: { (progress, error, stop, info) in
            progressHandler?(self, progress)
        }, resultHandler: { (data, dataUTI, imageOrientation, info, downloadSuccess) in
            if downloadSuccess {
                success?(self, data!, imageOrientation, info)
            }else {
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
        
        return HXPHAssetManager.requestLivePhoto(for: asset!, targetSize: targetSize) { (iCloudRequestID) in
            iCloudHandler?(self, iCloudRequestID)
        } progressHandler: { (progress, error, stop, info) in
            progressHandler?(self, progress)
        } resultHandler: { (livePhoto, info, downloadSuccess) in
            if downloadSuccess {
                success?(self, livePhoto!, info)
            }else {
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
        return HXPHAssetManager.requestAVAsset(for: asset!) { (iCloudRequestID) in
            iCloudHandler?(self, iCloudRequestID)
        } progressHandler: { (progress, error, stop, info) in
            progressHandler?(self, progress)
        } resultHandler: { (avAsset, audioMix, info, downloadSuccess) in
            if downloadSuccess {
                success?(self, avAsset!, info)
            }else {
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
    private func getFileSize() -> Int {
        if let fileSize = pFileSize {
            return fileSize
        }
        var fileSize = 0
        if let photoAsset = asset {
            let assetResources = PHAssetResource.assetResources(for: photoAsset)
            for assetResource in assetResources {
                if let photoFileSize = assetResource.value(forKey: "fileSize") as? Int {
                    fileSize += photoFileSize
                }
            }
        }else {
            if self.mediaType == .photo {
                if let pngData = localImage?.pngData() {
                    fileSize = pngData.count
                }else if let jpegData = localImage?.jpegData(compressionQuality: 1) {
                    fileSize = jpegData.count
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
}
