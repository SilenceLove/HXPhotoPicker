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

open class PhotoAsset: Equatable, PhotoAssetEquatable {
    
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
    
    /// 原图
    /// 如果为网络图片时，获取的是缩略地址的图片，也可能为nil
    /// 如果为网络视频，则为nil
    public var originalImage: UIImage? { getOriginalImage() }

    /// 图片/视频文件大小
    /// 1000 = 1kb
    /// 1000000 = 1Mb
    public var fileSize: Int { getFileSize() }
    
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
    
    /// 图片/视频尺寸大小
    public var imageSize: CGSize { getImageSize() }
    
    /// 是否是 gif
    public var isGifAsset: Bool { mediaSubType.isGif }
    
    /// 是否是本地 Asset
    public var isLocalAsset: Bool { mediaSubType.isLocal }
    
    /// 是否是网络 Asset
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
        mediaSubType = .networkImage(networkImageAsset.originalURL.isGif)
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
            pVideoDuration = phAsset.duration
            pVideoTime = PhotoTools.transformVideoDurationToString(duration: TimeInterval(round(phAsset.duration)))
        }
    }
    
    func updateVideoDuration(_ duration: TimeInterval) {
        pVideoDuration = duration
        pVideoTime = PhotoTools.transformVideoDurationToString(duration: duration)
    }
    func getOriginalImage() -> UIImage? {
        #if HXPICKER_ENABLE_EDITOR
        if editedResult != nil {
            return getEditedImage()
        }
        #endif
        guard let phAsset = phAsset else {
            if mediaType == .photo {
                if let livePhoto = localLivePhoto {
                    if livePhoto.imageURL.isFileURL {
                        return UIImage(contentsOfFile: livePhoto.imageURL.path)
                    }else {
                        #if canImport(Kingfisher)
                        if ImageCache.default.isCached(forKey: livePhoto.imageURL.cacheKey) {
                            return ImageCache.default.retrieveImageInMemoryCache(
                                forKey: livePhoto.imageURL.cacheKey,
                                options: []
                            )
                        }
                        #endif
                        return nil
                    }
                }
                if let image = localImageAsset?.image {
                    return image
                }else if let imageURL = localImageAsset?.imageURL {
                    let image = UIImage(contentsOfFile: imageURL.path)
                    localImageAsset?.image = image
                }
                return localImageAsset?.image
            }else {
                checkLoaclVideoImage()
                return localVideoAsset?.image
            }
        }
        let options = PHImageRequestOptions.init()
        options.isSynchronous = true
        options.isNetworkAccessAllowed = true
        options.deliveryMode = .highQualityFormat
        if mediaSubType == .imageAnimated {
            options.version = .original
        }
        var originalImage: UIImage?
        let isGif = phAsset.isImageAnimated
        AssetManager.requestImageData(for: phAsset, options: options) { (result) in
            switch result {
            case .success(let dataResult):
                let image = UIImage(data: dataResult.imageData)?.normalizedImage()
                if isGif && self.mediaSubType != .imageAnimated {
                    if let data = PhotoTools.getImageData(for: image) {
                        originalImage = UIImage(data: data)
                    }
                }else {
                    originalImage = image
                }
            default:
                break
            }
        }
        return originalImage
    }
    func getImageSize() -> CGSize {
        #if HXPICKER_ENABLE_EDITOR
        if let photoEdit = photoEditedResult {
            return photoEdit.image.size
        }
        if let videoEdit = videoEditedResult {
            return videoEdit.coverImage?.size ?? CGSize(width: 200, height: 200)
        }
        #endif
        let size: CGSize
        if let phAsset = phAsset {
            if phAsset.pixelWidth == 0 || phAsset.pixelHeight == 0 {
                size = CGSize(width: 200, height: 200)
            }else {
                size = CGSize(width: phAsset.pixelWidth, height: phAsset.pixelHeight)
            }
        }else {
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
                    size = image?.size ?? .init(width: 200, height: 200)
                }
            }else if let networkVideo = networkVideoAsset {
                if !networkVideo.videoSize.equalTo(.zero) {
                    size = networkVideo.videoSize
                }else if let image = networkVideo.coverImage {
                    size = image.size
                }else {
                    let key = networkVideo.videoURL.absoluteString
                    if PhotoTools.isCached(forVideo: key) {
                        let videoURL = PhotoTools.getVideoCacheURL(for: key)
                        if let image = PhotoTools.getVideoThumbnailImage(videoURL: videoURL, atTime: 0.1) {
                            networkVideoAsset?.coverImage = image
                            return image.size
                        }
                    }
                    size = CGSize(width: 200, height: 200)
                }
            }else {
                if let localLivePhoto = localLivePhoto {
                    if localLivePhoto.size.equalTo(.zero) {
                        if localLivePhoto.imageURL.isFileURL {
                            let image = UIImage(contentsOfFile: localLivePhoto.imageURL.path)
                            size = image?.size ?? .init(width: 200, height: 200)
                            self.localLivePhoto?.size = size
                        }else {
                            #if canImport(Kingfisher)
                            if ImageCache.default.isCached(forKey: localLivePhoto.imageURL.cacheKey) {
                                let cachePath = ImageCache.default.cachePath(forKey: localLivePhoto.imageURL.cacheKey)
                                if let image = UIImage(contentsOfFile: cachePath) {
                                    size = image.size
                                    self.localLivePhoto?.size = size
                                }else {
                                    size = .init(width: 200, height: 200)
                                }
                            }else {
                                size = .init(width: 200, height: 200)
                            }
                            #else
                            size = .init(width: 200, height: 200)
                            #endif
                        }
                    }else {
                        size = localLivePhoto.size
                    }
                }else {
                    #if canImport(Kingfisher)
                    if let networkImageSize = networkImageAsset?.imageSize, !networkImageSize.equalTo(.zero) {
                        size = networkImageSize
                    } else {
                        size = CGSize(width: 200, height: 200)
                    }
                    #else
                    size = CGSize(width: 200, height: 200)
                    #endif
                }
                
            }
        }
        return size
    }
    func getVideoCoverURL(
        toFile fileURL: URL? = nil,
        resultHandler: @escaping AssetURLCompletion
    ) {
        let coverURL = fileURL ?? PhotoTools.getImageTmpURL(.jpg)
        requestImageData { _, result in
            switch result {
            case .success(let dataResult):
                let imageData = dataResult.imageData
                DispatchQueue.global().async {
                    if let imageURL = PhotoTools.write(
                        toFile: coverURL,
                        imageData: imageData
                    ) {
                        DispatchQueue.main.async {
                            resultHandler(
                                .success(
                                    .init(
                                        url: imageURL,
                                        urlType: .local,
                                        mediaType: .photo
                                    )
                                )
                            )
                        }
                    }else {
                        DispatchQueue.main.async {
                            resultHandler(.failure(.fileWriteFailed))
                        }
                    }
                }
            case .failure(let error):
                resultHandler(.failure(error.error))
            }
        }
    }
    
    func requestAssetImageURL(
        toFile fileURL: URL? = nil,
        compressionQuality: CGFloat? = nil,
        filterEditor: Bool = false,
        resultHandler: @escaping AssetURLCompletion
    ) {
        #if HXPICKER_ENABLE_EDITOR
        if (editedResult != nil) && !filterEditor {
            getEditedImageURL(
                toFile: fileURL,
                compressionQuality: compressionQuality,
                resultHandler: resultHandler
            )
            return
        }
        #endif
        guard let phAsset = phAsset else {
            resultHandler(
                .failure(
                    .invalidPHAsset
                )
            )
            return
        }
        if mediaType == .video {
            getVideoCoverURL(
                toFile: fileURL,
                resultHandler: resultHandler
            )
            return
        }
        let isGif = phAsset.isImageAnimated
        var imageFileURL: URL
        if let fileURL = fileURL {
            imageFileURL = fileURL
        }else {
            var suffix: String
            if mediaSubType == .imageAnimated {
                suffix = "gif"
            }else {
                if let compressionQuality, compressionQuality < 1, !isGif {
                    suffix = "jpeg"
                }else {
                    if let photoFormat = photoFormat, !isGif {
                        suffix = photoFormat
                    }else {
                        suffix = "png"
                    }
                }
            }
            imageFileURL = PhotoTools.getTmpURL(for: suffix)
        }
        AssetManager.requestImageURL(
            for: phAsset,
            toFile: imageFileURL
        ) { (result) in
            switch result {
            case .success(let imageURL):
                self.requestAssetImageURL(
                    imageFileURL: imageFileURL,
                    resultURL: imageURL,
                    isGif: isGif,
                    compressionQuality: compressionQuality,
                    resultHandler: resultHandler
                )
            case .failure(let error):
                resultHandler(.failure(error))
            }
        }
    }
    
    private func requestAssetImageURL(
        imageFileURL: URL,
        resultURL: URL,
        isGif: Bool,
        compressionQuality: CGFloat?,
        resultHandler: @escaping AssetURLCompletion
    ) {
        let imageURL = resultURL
        func resultSuccess(_ url: URL) {
            DispatchQueue.main.async {
                resultHandler(
                    .success(
                        .init(
                            url: url,
                            urlType: .local,
                            mediaType: .photo
                        )
                    )
                )
            }
        }
        func converImageURL(_ url: URL) -> URL {
            let imageURL: URL
            if url.pathExtension.uppercased() == "HEIC" {
                let path = url.path.replacingOccurrences(
                    of: url.pathExtension,
                    with: imageFileURL.pathExtension
                )
                imageURL = .init(fileURLWithPath: path)
            }else {
                imageURL = url
            }
            return imageURL
        }
        if isGif && self.mediaSubType != .imageAnimated {
            DispatchQueue.global().async {
                // 本质上是gif，需要变成静态图
                guard let imageData = try? Data(contentsOf: imageURL),
                      let image = UIImage(data: imageData) else {
                    DispatchQueue.main.async {
                        resultHandler(.failure(.fileWriteFailed))
                    }
                    return
                }
                if let compressionQuality = compressionQuality, compressionQuality < 1 {
                    if FileManager.default.fileExists(atPath: imageURL.path) {
                        try? FileManager.default.removeItem(at: imageURL)
                    }
                    let toURL = converImageURL(imageURL)
                    if let data = PhotoTools.imageCompress(
                        imageData,
                        compressionQuality: compressionQuality,
                        isHEIC: imageURL.pathExtension.uppercased() == "HEIC"
                    ),
                       let url = PhotoTools.write(
                        toFile: toURL,
                        imageData: data
                    ) {
                        resultSuccess(url)
                    }else {
                        DispatchQueue.main.async {
                            resultHandler(.failure(.imageCompressionFailed))
                        }
                    }
                    return
                }
                do {
                    let toURL = converImageURL(imageURL)
                    let imageData = PhotoTools.getImageData(for: image)
                    if FileManager.default.fileExists(atPath: imageURL.path) {
                        try FileManager.default.removeItem(at: imageURL)
                    }
                    try imageData?.write(to: toURL)
                    resultSuccess(toURL)
                } catch {
                    DispatchQueue.main.async {
                        resultHandler(.failure(.fileWriteFailed))
                    }
                }
            }
            return
        }else if !isGif {
            if let compressionQuality = compressionQuality, compressionQuality < 1 {
                DispatchQueue.global().async {
                    guard let imageData = try? Data(contentsOf: imageURL) else {
                        DispatchQueue.main.async {
                            resultHandler(.failure(.imageCompressionFailed))
                        }
                        return
                    }
                    if FileManager.default.fileExists(atPath: imageURL.path) {
                        try? FileManager.default.removeItem(at: imageURL)
                    }
                    let toURL = converImageURL(imageURL)
                    if let data = PhotoTools.imageCompress(
                        imageData,
                        compressionQuality: compressionQuality,
                        isHEIC: imageURL.pathExtension.uppercased() == "HEIC"
                    ),
                       let url = PhotoTools.write(
                        toFile: toURL,
                        imageData: data
                    ) {
                        resultSuccess(url)
                    }else {
                        DispatchQueue.main.async {
                            resultHandler(.failure(.imageCompressionFailed))
                        }
                    }
                }
                return
            }
        }
        resultSuccess(imageURL)
    }
    
    func requestAssetVideoURL(
        toFile fileURL: URL? = nil,
        exportParameter: VideoExportParameter? = nil,
        exportSession: ((AVAssetExportSession) -> Void)? = nil,
        resultHandler: @escaping AssetURLCompletion
    ) {
        #if HXPICKER_ENABLE_EDITOR
        if let videoEdit = videoEditedResult {
            if let fileURL = fileURL {
                if PhotoTools.copyFile(at: videoEdit.url, to: fileURL) {
                    resultHandler(.success(.init(url: fileURL, urlType: .local, mediaType: .video)))
                }else {
                    resultHandler(.failure(.fileWriteFailed))
                }
                return
            }
            resultHandler(.success(.init(url: videoEdit.url, urlType: .local, mediaType: .video)))
            return
        }
        #endif
        guard let phAsset = phAsset else {
            resultHandler(.failure(.invalidPHAsset))
            return
        }
        let toFile = fileURL == nil ? PhotoTools.getVideoTmpURL() : fileURL!
        if mediaSubType == .livePhoto {
            if let exportParameter = exportParameter {
                AssetManager.exportVideoURL(
                    forVideo: phAsset,
                    toFile: toFile,
                    exportParameter: exportParameter,
                    exportSession: exportSession
                ) { (result) in
                    switch result {
                    case .success(let videoURL):
                        resultHandler(.success(.init(url: videoURL, urlType: .local, mediaType: .video)))
                    case .failure(let error):
                        resultHandler(.failure(error.error))
                    }
                }
                return
            }
            let assetHandler: (URL?, Error?) -> Void = { videoURL, error in
                if let videoURL = videoURL {
                    resultHandler(.success(.init(url: videoURL, urlType: .local, mediaType: .video)))
                }else {
                    resultHandler(.failure(.exportFailed(error)))
                }
            }
            AssetManager.requestLivePhoto(
                videoURL: phAsset,
                toFile: toFile
            ) { (videoURL, _) in
                assetHandler(videoURL, nil)
            }
        }else {
            if mediaType == .photo {
                resultHandler(.failure(.typeError))
                return
            }
            AssetManager.requestVideoURL(
                for: phAsset,
                toFile: toFile,
                exportParameter: exportParameter
            ) { (result) in
                switch result {
                case .success(let videoURL):
                    resultHandler(.success(.init(url: videoURL, urlType: .local, mediaType: .video)))
                case .failure(let error):
                    resultHandler(.failure(error))
                }
            }
        }
    }
}
