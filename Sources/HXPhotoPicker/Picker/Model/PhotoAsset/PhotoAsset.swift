//
//  PhotoAsset.swift
//  HXPhotoPickerSwift
//
//  Created by Silence on 2020/11/12.
//  Copyright © 2020 Silence. All rights reserved.
//

import UIKit
import Photos
#if canImport(Kingfisher)
import Kingfisher
#endif

public typealias PhotoAssetICloudHandler = (PhotoAsset, PHImageRequestID) -> Void
public typealias PhotoAssetProgressHandler = (PhotoAsset, Double) -> Void
public typealias PhotoAssetFailureHandler = (PhotoAsset, [AnyHashable: Any]?, AssetError) -> Void

open class PhotoAsset: Equatable {
    
    /// 系统相册里的资源
    public var phAsset: PHAsset? { didSet { setMediaType() } }
    
    /// 媒体类型
    public var mediaType: MediaType = .photo
    
    /// 媒体子类型
    public var mediaSubType: MediaSubType = .image
    
    #if HXPICKER_ENABLE_EDITOR
    /// 编辑之后的数据
    public var editedResult: EditedResult? { didSet { pFileSize = nil } }
    var initialEditedResult: EditedResult?
    
    /// 图片编辑结果
    public var photoEditedResult: ImageEditedResult? {
        guard let editedResult = editedResult else {
            return nil
        }
        switch editedResult {
        case .image(let result, _):
            return result
        default:
            return nil
        }
    }
    /// 视频编辑结果
    public var videoEditedResult: VideoEditedResult? {
        guard let editedResult = editedResult else {
            return nil
        }
        switch editedResult {
        case .video(let result, _):
            return result
        default:
            return nil
        }
    }
    #endif

    /// 图片/视频文件大小
    /// 1000 = 1kb
    /// 1000000 = 1Mb
    public var fileSize: Int { getFileSize() }
    
    /// 图片/视频尺寸大小
    public var imageSize: CGSize {
        if let editedImageSize {
            return editedImageSize
        }
        if let localImageSize {
            return localImageSize
        }
        if let phAssetImageSize {
            return phAssetImageSize
        }
        return .init(width: 200, height: 200)
    }
    
    /// 视频时长 格式：00:00
    public var videoTime: String? {
        #if HXPICKER_ENABLE_EDITOR
        if let videoEdit = videoEditedResult {
            return videoEdit.videoTime
        }
        #endif
        return pVideoTime
    }
    
    /// 视频时长 秒
    public var videoDuration: TimeInterval {
        #if HXPICKER_ENABLE_EDITOR
        if let videoEdit = videoEditedResult {
            return videoEdit.videoDuration
        }
        #endif
        return pVideoDuration
    }
    
    /// 当前资源是否被选中
    public var isSelected: Bool = false
    
    /// 选中时的下标
    public var selectIndex: Int = 0
    
    public var isGifAsset: Bool { mediaSubType.isGif }
    public var isLocalAsset: Bool { mediaSubType.isLocal }
    public var isNetworkAsset: Bool { mediaSubType.isNetwork }
    
    /// 根据系统相册里对应的 PHAsset 数据初始化
    /// - Parameter asset: 系统相册里对应的 PHAsset 数据
    public init(asset: PHAsset) {
        self.phAsset = asset
        setMediaType()
    }
    
    public convenience init(_ asset: PHAsset) {
        self.init(asset: asset)
    }
    
    /// 根据系统相册里对应的 PHAsset本地唯一标识符 初始化
    /// - Parameter localIdentifier: 系统相册里对应的 PHAsset本地唯一标识符
    public init(localIdentifier: String) {
        phAsset = AssetManager.fetchAsset(with: localIdentifier)
        setMediaType()
    }
    
    public convenience init(_ localIdentifier: String) {
        self.init(localIdentifier: localIdentifier)
    }
    
    /// 本地图片
    public var localImageAsset: LocalImageAsset?
    
    /// 初始化本地图片
    /// - Parameters:
    ///   - localImageAsset: 对应本地图片的 LocalImageAsset
    public init(localImageAsset: LocalImageAsset) {
        self.localImageAsset = localImageAsset
        mediaType = .photo
        if let imageData = localImageAsset.imageData {
            mediaSubType = imageData.isGif ? .localGifImage : .localImage
        }else if let imageURL = localImageAsset.imageURL {
            mediaSubType = imageURL.isGif ? .localGifImage : .localImage
        }else {
            mediaSubType = .localImage
        }
    }
    
    public convenience init(_ localImageAsset: LocalImageAsset) {
        self.init(localImageAsset: localImageAsset)
    }
    
    /// 本地视频
    public var localVideoAsset: LocalVideoAsset?
    
    /// 初始化本地视频
    /// - Parameters:
    ///   - localVideoAsset: 对应本地视频的 LocalVideoAsset
    public init(localVideoAsset: LocalVideoAsset) {
        let videoDuration: TimeInterval
        if localVideoAsset.duration == 0 {
            videoDuration = PhotoTools.getVideoDuration(videoURL: localVideoAsset.videoURL)
        }else {
            videoDuration = localVideoAsset.duration
        }
        pVideoTime = PhotoTools.transformVideoDurationToString(duration: videoDuration)
        pVideoDuration = videoDuration
        self.localVideoAsset = localVideoAsset
        mediaType = .video
        mediaSubType = .localVideo
    }
    
    public convenience init(_ localVideoAsset: LocalVideoAsset) {
        self.init(localVideoAsset: localVideoAsset)
    }
    
    /// 本地LivePhoto
    public var localLivePhoto: LocalLivePhotoAsset?
    
    /// 初始化本地LivePhoto
    public init(localLivePhoto: LocalLivePhotoAsset) {
        mediaType = .photo
        mediaSubType = .localLivePhoto
        self.localLivePhoto = localLivePhoto
    }
    
    public convenience init(_ localLivePhoto: LocalLivePhotoAsset) {
        self.init(localLivePhoto: localLivePhoto)
    }
    
    /// 本地/网络Asset的唯一标识符
    public private(set) var localAssetIdentifier: String = UUID().uuidString
    
    #if canImport(Kingfisher)
    /// 初始化网络图片
    /// - Parameter networkImageAsset: 对应网络图片的 NetworkImageAsset
    public init(networkImageAsset: NetworkImageAsset) {
        self.networkImageAsset = networkImageAsset
        mediaType = .photo
        let isGif = networkImageAsset.originalURL?.isGif ?? false
        mediaSubType = .networkImage(isGif)
    }
    
    public convenience init(_ networkImageAsset: NetworkImageAsset) {
        self.init(networkImageAsset: networkImageAsset)
    }
    
    /// 网络图片
    public var networkImageAsset: NetworkImageAsset?
    
    var localImageType: DonwloadURLType = .thumbnail
    
    var loadNetworkImageHandler: ((((PhotoAsset) -> Void)?) -> Void)?
    #endif
    
    /// 网络视频
    public var networkVideoAsset: NetworkVideoAsset?
    
    /// 初始化网络视频
    /// - Parameter networkVideoAsset: 对应网络视频的 NetworkVideoAsset
    public init(networkVideoAsset: NetworkVideoAsset) {
        self.networkVideoAsset = networkVideoAsset
        mediaType = .video
        mediaSubType = .networkVideo
        if networkVideoAsset.duration > 0 {
            pVideoDuration = networkVideoAsset.duration
            pVideoTime = PhotoTools.transformVideoDurationToString(duration: networkVideoAsset.duration)
        }
    }
    
    public convenience init(_ networkVideoAsset: NetworkVideoAsset) {
        self.init(networkVideoAsset: networkVideoAsset)
    }
    
    /// iCloud下载状态，确定不在iCloud上的为 .succeed
    public var downloadStatus: DownloadStatus = .unknow
    
    /// iCloud下载进度，如果取消了会记录上次进度
    public var downloadProgress: Double = 0
    
    var localIndex: Int = 0
    var pFileSize: Int?
    var pVideoTime: String?
    var pVideoDuration: TimeInterval = 0
    var playerTime: CGFloat = 0
    var isScrolling = false
    var requestVideoDurationId: PHImageRequestID?
    
    var identifie: String {
        if let phAsset = phAsset {
            return phAsset.localIdentifier
        }
        return localAssetIdentifier
    }
    
    public static func == (lhs: PhotoAsset, rhs: PhotoAsset) -> Bool {
        lhs.isEqual(rhs)
    }
}

// MARK: Self-use
extension PhotoAsset {
    
    var cameraAsset: PhotoAsset? {
        var photoAsset: PhotoAsset?
        if mediaType == .photo {
            if let localImageAsset = localImageAsset {
                photoAsset = PhotoAsset(localImageAsset: localImageAsset)
            }
        }else {
            if let localVideoAsset = localVideoAsset {
                photoAsset = PhotoAsset(localVideoAsset: localVideoAsset)
            }
        }
        photoAsset?.localAssetIdentifier = localAssetIdentifier
        photoAsset?.localIndex = localIndex
        return photoAsset
    }
    
    func setMediaType() {
        guard let phAsset = phAsset else {
            return
        }
        if phAsset.mediaType == .image {
            mediaType = .photo
            mediaSubType = .image
        }else if phAsset.mediaType == .video {
            mediaType = .video
            mediaSubType = .video
            if !phAsset.mediaSubtypes.contains(.videoHighFrameRate) {
                pVideoDuration = phAsset.duration
                pVideoTime = PhotoTools.transformVideoDurationToString(duration: TimeInterval(round(phAsset.duration)))
            }else {
                let options = PHVideoRequestOptions()
                options.deliveryMode = .fastFormat
                options.version = .current
                requestVideoDurationId = AssetManager.requestPlayerItem(for: phAsset, options: options) { result in
                    switch result {
                    case .success(let playerItem):
                        self.updateVideoDuration(playerItem.duration.seconds)
                    default:
                        break
                    }
                }
            }
        }
    }
    
    var phAssetImageSize: CGSize? {
        guard let phAsset, phAsset.pixelWidth > 0, phAsset.pixelHeight > 0 else {
            return nil
        }
        return .init(width: phAsset.pixelWidth, height: phAsset.pixelHeight)
    }
    
    var localImageSize: CGSize? {
        var size: CGSize?
        if let localImage = localImageAsset?.image {
            size = localImage.size
        }else if let localImageData = localImageAsset?.imageData,
                 let image = UIImage(data: localImageData) {
            size = image.size
        }else if let imageURL = localImageAsset?.imageURL,
                 let image = UIImage(contentsOfFile: imageURL.path) {
            localImageAsset?.image = image
            size = image.size
        }else if let localVideoAsset = localVideoAsset {
            if !localVideoAsset.videoSize.equalTo(.zero) {
                size = localVideoAsset.videoSize
            }else if let localImage = localVideoAsset.image {
                size = localImage.size
            }else {
                let image = PhotoTools.getVideoThumbnailImage(videoURL: localVideoAsset.videoURL, atTime: 0.1)
                self.localVideoAsset?.image = image
                size = image?.size
            }
        }else if let networkVideo = networkVideoAsset {
            if !networkVideo.videoSize.equalTo(.zero) {
                size = networkVideo.videoSize
            }else if let image = networkVideo.coverImage {
                size = image.size
            }else {
                if let key = networkVideo.videoURL?.absoluteString,
                   PhotoTools.isCached(forVideo: key) {
                    let videoURL = PhotoTools.getVideoCacheURL(for: key)
                    if let image = PhotoTools.getVideoThumbnailImage(videoURL: videoURL, atTime: 0.1) {
                        networkVideoAsset?.coverImage = image
                        return image.size
                    }
                }
            }
        }else {
            if let localLivePhoto = localLivePhoto {
                if localLivePhoto.size.equalTo(.zero) {
                    if localLivePhoto.imageURL.isFileURL {
                        let image = UIImage(contentsOfFile: localLivePhoto.imageURL.path)
                        size = image?.size
                        self.localLivePhoto?.size = size ?? .init(width: 200, height: 200)
                    }else {
                        #if canImport(Kingfisher)
                        if ImageCache.default.isCached(forKey: localLivePhoto.imageURL.cacheKey) {
                            let cachePath = ImageCache.default.cachePath(forKey: localLivePhoto.imageURL.cacheKey)
                            if let image = UIImage(contentsOfFile: cachePath) {
                                size = image.size
                                self.localLivePhoto?.size = size ?? .init(width: 200, height: 200)
                            }
                        }
                        #endif
                    }
                }else {
                    size = localLivePhoto.size
                }
            }else {
                #if canImport(Kingfisher)
                if let networkImageSize = networkImageAsset?.imageSize, !networkImageSize.equalTo(.zero) {
                    size = networkImageSize
                }
                #endif
            }
        }
        return size
    }
    
    var editedImageSize: CGSize? {
        #if HXPICKER_ENABLE_EDITOR
        if let photoEdit = photoEditedResult {
            return photoEdit.image.size
        }
        if let videoEdit = videoEditedResult {
            return videoEdit.coverImage?.size
        }
        #endif
        return nil
    }
}
