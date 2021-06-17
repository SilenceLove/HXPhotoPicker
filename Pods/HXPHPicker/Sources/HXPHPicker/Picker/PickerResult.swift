//
//  PickerResult.swift
//  HXPHPicker
//
//  Created by Slience on 2021/3/8.
//

import Foundation
import AVFoundation

public struct PickerResult {
    
    /// 已选的资源
    public let photoAssets: [PhotoAsset]
    
    /// 是否选择的原图
    public let isOriginal: Bool
    
    /// 获取 image (不是原图)
    /// - Parameters:
    ///   - imageHandler: 每一次获取image都会触发
    ///   - completionHandler: 全部获取完成(失败的不会添加)
    public func getImage(imageHandler: @escaping (UIImage?, PhotoAsset, Int) -> Void,
                         completionHandler: @escaping ([UIImage]) -> Void) {
        let group = DispatchGroup.init()
        let queue = DispatchQueue.init(label: "hxphpicker.get.image")
        var images: [UIImage] = []
        for (index, photoAsset) in photoAssets.enumerated() {
            queue.async(group: group, execute: DispatchWorkItem.init(block: {
                let semaphore = DispatchSemaphore.init(value: 0)
                photoAsset.requestImage { (image, phAsset) in
                    imageHandler(image, phAsset, index)
                    if let image = image {
                        images.append(image)
                    }
                    semaphore.signal()
                }
                semaphore.wait()
            }))
        }
        group.notify(queue: .main) {
            completionHandler(images)
        }
    }
    
    /// 获取视频地址
    /// - Parameters:
    ///   - exportPreset: 视频质量，默认中等质量
    ///   - videoURLHandler: 每一次获取视频地址都会触发
    ///   - completionHandler: 全部获取完成(失败的不会添加)
    public func getVideoURL(exportPreset: String = AVAssetExportPresetMediumQuality,
                            videoURLHandler: @escaping (URL?, PhotoAsset, Int) -> Void,
                            completionHandler: @escaping ([URL]) -> Void) {
        let group = DispatchGroup.init()
        let queue = DispatchQueue.init(label: "hxphpicker.get.videoURL")
        var videoURLs: [URL] = []
        for (index, photoAsset) in photoAssets.enumerated() {
            queue.async(group: group, execute: DispatchWorkItem.init(block: {
                let semaphore = DispatchSemaphore.init(value: 0)
                photoAsset.requestVideoURL(exportPreset: exportPreset) { (videoURL) in
                    videoURLHandler(videoURL, photoAsset, index)
                    if let videoURL = videoURL {
                        videoURLs.append(videoURL)
                    }
                    semaphore.signal()
                }
                semaphore.wait()
            }))
        }
        group.notify(queue: .main) {
            completionHandler(videoURLs)
        }
    }
    
    /// 获取已选资源的地址（原图）
    /// 不包括网络资源，如果网络资源编辑过则会获取
    /// - Parameters:
    ///   - options: 获取的类型
    ///         photo    视频获取的是封面图片地址，LivePhoto获取的URL为封面图片地址
    ///         video    LivePhoto获取的URL为内部视频地址，会过滤其他图片
    ///                  LivePhoto如果编辑过，获取的只会是编辑后的图片URL
    ///   - completion: result
    public func getURLs(options: Options = .any,
                        completion: @escaping ([URL]) -> Void) {
        var urls: [URL] = []
        getURLs(options: options) { (url, isNetwork, index, mediaType) in
            if let url = url, !isNetwork {
                urls.append(url)
            }
        } completionHandler: { (_) in
            completion(urls)
        }
    }
    
    /// 获取已选资源的地址
    /// 包括网络图片
    /// - Parameters:
    ///   - options: 获取的类型
    ///   - handler: 获取到url的回调 (地址，是否网络资源，对应的位置下标，类型)
    ///   - completionHandler: 全部获取完成
    public func getURLs(options: Options = .any,
                        urlReceivedHandler handler: @escaping (URL?, Bool, Int, PhotoAsset.MediaType) -> Void,
                        completionHandler: @escaping ([URL]) -> Void) {
        let group = DispatchGroup.init()
        let queue = DispatchQueue.init(label: "hxphpicker.request.urls")
        var urls: [URL] = []
        for (index, photoAsset) in photoAssets.enumerated() {
            queue.async(group: group, execute: DispatchWorkItem.init(block: {
                let semaphore = DispatchSemaphore.init(value: 0)
                var mediatype: PhotoAsset.MediaType = .photo
                if options.contains([.photo, .video]) {
                    mediatype = photoAsset.mediaType
                }else if options.contains([.photo]) {
                    mediatype = .photo
                }else if options.contains([.video]){
                    mediatype = .video
                }
                #if HXPICKER_ENABLE_EDITOR
                if photoAsset.mediaSubType == .livePhoto && photoAsset.photoEdit != nil {
                    mediatype = .photo
                }
                #endif
                if mediatype == .photo {
                    #if canImport(Kingfisher)
                    if photoAsset.isNetworkAsset {
                        photoAsset.getNetworkImageURL { (url, isNetwork) in
                            if let url = url {
                                urls.append(url)
                            }
                            handler(url, isNetwork, index, .photo)
                            semaphore.signal()
                        }
                        return
                    }
                    #endif
                    photoAsset.requestImageURL { (url) in
                        if let url = url {
                            urls.append(url)
                        }
                        handler(url, false, index, .photo)
                        semaphore.signal()
                    }
                }else {
                    if photoAsset.isNetworkAsset {
                        photoAsset.getNetworkVideoURL { (url, isNetwork) in
                            if let url = url {
                                urls.append(url)
                            }
                            handler(url, isNetwork, index, .video)
                            semaphore.signal()
                        }
                        return
                    }
                    photoAsset.requestVideoURL { (url) in
                        if let url = url {
                            urls.append(url)
                        }
                        handler(url, false, index, .video)
                        semaphore.signal()
                    }
                }
                semaphore.wait()
            }))
        }
        group.notify(queue: .main) {
            completionHandler(urls)
        }
    }
    
    /// 初始化
    /// - Parameters:
    ///   - photoAssets: 对应 PhotoAsset 数据的数组
    ///   - isOriginal: 是否原图
    public init(photoAssets: [PhotoAsset],
                isOriginal: Bool) {
        self.photoAssets = photoAssets
        self.isOriginal = isOriginal
    }
}
