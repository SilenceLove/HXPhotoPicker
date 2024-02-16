//
//  Picker+Array.swift
//  HXPhotoPicker
//
//  Created by Slience on 2021/9/23.
//

import UIKit
import AVFoundation

public extension Array where Element: PhotoAsset {
    
    /// 获取 image
    /// - Parameters:
    ///   - compressionScale: 压缩比例，获取系统相册里的资源时有效
    ///   - imageHandler: 每一次获取image都会触发
    ///   - completionHandler: 全部获取完成(失败的不会添加)
    func getImage(
        compressionScale: CGFloat? = 0.5,
        imageHandler: PickerResult.ImageHandler? = nil,
        completionHandler: @escaping ([UIImage]) -> Void
    ) {
        let group = DispatchGroup()
        let queue = DispatchQueue(label: "HXPhotoPicker.get.image")
        var images: [UIImage] = []
        for (index, photoAsset) in enumerated() {
            queue.async(
                group: group,
                execute: DispatchWorkItem(block: {
                    let semaphore = DispatchSemaphore(value: 0)
                    photoAsset.requestImage(compressionScale: compressionScale) {
                        imageHandler?($0, $1, index)
                        if let image = $0 {
                            images.append(image)
                        }
                        semaphore.signal()
                    }
                    semaphore.wait()
                })
            )
        }
        group.notify(queue: .main) {
            completionHandler(images)
        }
    }
    
    /// 获取 image
    /// - Parameters:
    ///   - targetSize: 指定`imageSize`
    ///   - targetMode: 裁剪模式
    ///   - imageHandler: 每一次获取image都会触发
    ///   - completionHandler: 全部获取完成(失败的不会添加)   
    func getImage(
        targetSize: CGSize,
        targetMode: HX.ImageTargetMode = .fill,
        imageHandler: PickerResult.ImageHandler? = nil,
        completionHandler: @escaping ([UIImage]) -> Void
    ) {
        let group = DispatchGroup()
        let queue = DispatchQueue(label: "HXPhotoPicker.get.targetimage")
        var images: [UIImage] = []
        for (index, photoAsset) in enumerated() {
            queue.async(
                group: group,
                execute: DispatchWorkItem(block: {
                    let semaphore = DispatchSemaphore(value: 0)
                    photoAsset.getImage(targetSize: targetSize, targetMode: targetMode) {
                        imageHandler?($0, $1, index)
                        if let image = $0 {
                            images.append(image)
                        }
                        semaphore.signal()
                    }
                    semaphore.wait()
                })
            )
        }
        group.notify(queue: .main) {
            completionHandler(images)
        }
    }
    
    /// 获取视频地址
    /// - Parameters:
    ///   - exportParameter: 导出参数，nil 为原始视频
    ///   - videoURLConfig: 指定视频路径
    ///   - exportSession: 导出视频时对应的 AVAssetExportSession，exportPreset不为nil时触发
    ///   - videoURLHandler: 每一次获取视频地址都会触发
    ///   - completionHandler: 全部获取完成(失败的不会添加)
    func getVideoURL(
        exportParameter: VideoExportParameter? = .init(
            preset: .ratio_960x540,
            quality: 6
        ),
        toFile videoURLConfig: ((PhotoAsset, Int) -> URL)? = nil,
        exportSession: PickerResult.AVAssetExportSessionHandler? = nil,
        videoURLHandler: PickerResult.URLHandler? = nil,
        completionHandler: @escaping ([URL]) -> Void
    ) {
        let group = DispatchGroup()
        let queue = DispatchQueue(label: "HXPhotoPicker.get.videoURL")
        var videoURLs: [URL] = []
        for (index, photoAsset) in enumerated() {
            queue.async(
                group: group,
                execute: DispatchWorkItem(block: {
                    let semaphore = DispatchSemaphore(value: 0)
                    var toVideoURL: URL?
                    if let videoURL = videoURLConfig?(photoAsset, index) {
                        toVideoURL = videoURL
                    }
                    photoAsset.getVideoURL(
                        toFile: toVideoURL,
                        exportParameter: exportParameter
                    ) { session in
                        exportSession?(session, photoAsset, index)
                    } completion: {
                        switch $0 {
                        case .success(let response):
                            videoURLs.append(response.url)
                        case .failure:
                            break
                        }
                        videoURLHandler?($0, photoAsset, index)
                        semaphore.signal()
                    }
                    semaphore.wait()
                })
            )
        }
        group.notify(queue: .main) {
            completionHandler(videoURLs)
        }
    }
    
    /// 获取已选资源的地址
    /// 不包括网络资源，如果网络资源编辑过则会获取
    /// - Parameters:
    ///   - options: 获取的类型
    ///   - compression: 压缩参数，nil - 原图
    ///   - fileConfig: 指定文件路径配置回调
    ///   - completion: result
    func getURLs(
        options: PickerResult.Options = .any,
        compression: PhotoAsset.Compression? = nil,
        toFileConfigHandler fileConfig: PickerResult.FileConfigHandler? = nil,
        completion: @escaping ([URL]) -> Void
    ) {
        var urls: [URL] = []
        getURLs(
            options: options,
            compression: compression,
            toFile: fileConfig
        ) { result, _, _ in
            switch result {
            case .success(let response):
                if response.urlType == .local {
                    urls.append(response.url)
                }
            case .failure:
                break
            }
        } completionHandler: { _ in
            completion(urls)
        }
    }
    
    /// 获取已选资源的地址，包括网络图片
    /// - Parameters:
    ///   - options: 获取的类型
    ///   - compression: 压缩参数，nil - 原图
    ///   - fileConfigHandler: 指定文件路径配置回调
    ///   - urlReceivedHandler: 获取到url的回调
    ///     - result: 获取的结果
    ///     - photoAsset: 对应的 PhotoAsset 对象
    ///     - index: 当前索引
    ///   - completionHandler: 全部获取完成
    ///     - urls: 获取成功的url集合
    func getURLs(
        options: PickerResult.Options = .any,
        compression: PhotoAsset.Compression? = nil,
        toFile fileConfigHandler: PickerResult.FileConfigHandler? = nil,
        urlReceivedHandler handler: PickerResult.URLHandler? = nil,
        completionHandler: @escaping ([URL]) -> Void
    ) {
        let group = DispatchGroup()
        let queue = DispatchQueue(label: "HXPhotoPicker.request.urls")
        var urls: [URL] = []
        for (index, photoAsset) in enumerated() {
            queue.async(
                group: group,
                execute: DispatchWorkItem(block: {
                    let semaphore = DispatchSemaphore(value: 0)
                    var mediatype: PhotoAsset.MediaType = .photo
                    if options.contains([.photo, .video]) {
                        mediatype = photoAsset.mediaType
                    }else if options.contains([.photo]) {
                        mediatype = .photo
                    }else if options.contains([.video]) {
                        mediatype = .video
                    }
                    #if HXPICKER_ENABLE_EDITOR
                    if (photoAsset.mediaSubType == .livePhoto ||
                        photoAsset.mediaSubType == .localLivePhoto) &&
                        photoAsset.editedResult != nil {
                        mediatype = .photo
                    }
                    #endif
                    let resultHandler: PhotoAsset.AssetURLCompletion = { result in
                        switch result {
                        case .success(let respone):
                            urls.append(respone.url)
                        case .failure:
                            break
                        }
                        handler?(result, photoAsset, index)
                        semaphore.signal()
                    }
                    var toImageURL: URL?
                    var toVideoURL: URL?
                    if let fileConfig = fileConfigHandler?(photoAsset, index) {
                        toImageURL = fileConfig.imageURL
                        toVideoURL = fileConfig.videoURL
                    }
                    if mediatype == .photo {
                        if photoAsset.mediaSubType == .livePhoto ||
                            photoAsset.mediaSubType == .localLivePhoto {
                            photoAsset.getLivePhotoURL(
                                imageFileURL: toImageURL,
                                videoFileURL: toVideoURL,
                                compression: compression
                            ) {
                                resultHandler($0)
                            }
                        }else {
                            photoAsset.getImageURL(
                                toFile: toImageURL,
                                compressionQuality: compression?.imageCompressionQuality
                            ) {
                                resultHandler($0)
                            }
                        }
                    }else {
                        photoAsset.getVideoURL(
                            toFile: toImageURL,
                            exportParameter: compression?.videoExportParameter
                        ) {
                            resultHandler($0)
                        }
                    }
                    semaphore.wait()
                })
            )
        }
        group.notify(queue: .main) {
            completionHandler(urls)
        }
    }
}
