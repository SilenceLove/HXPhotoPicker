//
//  PickerResult.swift
//  HXPhotoPicker
//
//  Created by Slience on 2021/3/8.
//

import UIKit
import AVFoundation

public struct PickerResult {
    
    /// selected resource
    /// 已选的资源
    /// getURLs Get the URLs of the original resource / 获取原始资源的URL
    public let photoAssets: [PhotoAsset]
    
    /// Whether to select the original image
    /// 是否选择的原图
    public let isOriginal: Bool
    
    /// isOriginal = false
    /// The original image does not select the compression parameter when getting the URL
    /// 原图未选中获取 URL 时的压缩参数
    public var compression: PhotoAsset.Compression? = .init(
        imageCompressionQuality: 6,
        videoExportParameter: .init(
            preset: .ratio_960x540,
            quality: 6
        )
    )
    
    /// 初始化 / init
    /// - Parameters:
    ///   - photoAssets: an array of corresponding PhotoAsset data / 对应 PhotoAsset 数据的数组
    ///   - isOriginal: Whether the original image / 是否原图
    public init(
        photoAssets: [PhotoAsset],
        isOriginal: Bool
    ) {
        self.photoAssets = photoAssets
        self.isOriginal = isOriginal
    }
}

// MARK: Get Image / Video URL
public extension PickerResult {
    
    /// get / 获取  image
    /// - Parameters:
    ///   - compressionScale: Compression ratio, valid when obtaining resources in the system album / 压缩比例，获取系统相册里的资源时有效
    ///   - imageHandler: Triggered every time an image is fetched / 每一次获取image都会触发
    ///   - completionHandler: All acquisitions are completed (failures will not be added) / 全部获取完成(失败的不会添加)
    func getImage(
        compressionScale: CGFloat? = 0.5,
        imageHandler: ImageHandler? = nil,
        completionHandler: @escaping ([UIImage]) -> Void
    ) {
        photoAssets.getImage(
            compressionScale: compressionScale,
            imageHandler: imageHandler,
            completionHandler: completionHandler
        )
    }
    
    /// Get video address / 获取视频地址
    /// - Parameters:
    ///   - exportSession: The corresponding AVAssetExportSession when exporting video, triggered when exportPreset is not nil / 导出视频时对应的 AVAssetExportSession，exportPreset不为nil时触发
    ///   - videoURLHandler: Triggered every time the video address is obtained / 每一次获取视频地址都会触发
    ///   - completionHandler: All acquisitions are completed (failures will not be added) / 全部获取完成(失败的不会添加)
    func getVideoURL(
        exportSession: AVAssetExportSessionHandler? = nil,
        videoURLHandler: URLHandler? = nil,
        completionHandler: @escaping ([URL]) -> Void
    ) {
        photoAssets.getVideoURL(
            exportParameter: isOriginal ? nil : compression?.videoExportParameter,
            exportSession: exportSession,
            videoURLHandler: videoURLHandler,
            completionHandler: completionHandler
        )
    }
}

// MARK: Get Original URL
public extension PickerResult {
    
    /// Get the address of the selected resource / 获取已选资源的地址
    /// Does not include network resources, if the network resources are edited, they will be obtained / 不包括网络资源，如果网络资源编辑过则会获取
    /// - Parameters:
    ///   - options: type of get / 获取的类型
    ///   - compression: compression parameter, nil - original image / 压缩参数，nil - 原图
    ///   - completion: result
    func getURLs(
        options: Options = .any,
        completion: @escaping ([URL]) -> Void
    ) {
        photoAssets.getURLs(
            options: options,
            compression: isOriginal ? nil : compression,
            completion: completion
        )
    }
    
    /// Get the address of the selected resource / 获取已选资源的地址
    /// Include web images / 包括网络图片
    /// - Parameters:
    ///   - options: type of get / 获取的类型
    ///   - compression: compression parameter, nil - original image / 压缩参数，nil - 原图
    ///   - handler: Get the callback of the url / 获取到url的回调
    ///   - completionHandler: All acquisition completed / 全部获取完成
    func getURLs(
        options: Options = .any,
        urlReceivedHandler handler: URLHandler? = nil,
        completionHandler: @escaping ([URL]) -> Void
    ) {
        photoAssets.getURLs(
            options: options,
            compression: isOriginal ? nil : compression,
            urlReceivedHandler: handler,
            completionHandler: completionHandler
        )
    }
    
    func getURLs(
        compression: PhotoAsset.Compression? = nil,
        urlReceivedHandler handler: URLHandler? = nil,
        completionHandler: @escaping ([URL]) -> Void
    ) {
        photoAssets.getURLs(
            options: .any,
            compression: compression,
            urlReceivedHandler: handler,
            completionHandler: completionHandler
        )
    }
}

extension PickerResult {
    /// (image, PhotoAsset object, index)
    /// (图片、PhotoAsset 对象, 索引)
    public typealias ImageHandler = (UIImage?, PhotoAsset, Int) -> Void
    /// (corresponding AVAssetExportSession object, PhotoAsset object, index when exporting video)
    /// (导出视频时对应的 AVAssetExportSession 对象, PhotoAsset 对象, 索引)
    public typealias AVAssetExportSessionHandler = (AVAssetExportSession, PhotoAsset, Int) -> Void
    /// (Result of getting URL, PhotoAsset object, index)
    /// (获取URL的结果、PhotoAsset 对象, 索引)
    public typealias URLHandler = (Result<AssetURLResult, AssetError>, PhotoAsset, Int) -> Void
}

@available(iOS 13.0.0, *)
public extension PickerResult {
    
    func images(_ compressionScale: CGFloat? = nil) async -> [UIImage] {
        await withCheckedContinuation { continuation in
            getImage(compressionScale: compressionScale) {
                continuation.resume(with: .success($0))
            }
        }
    }
    
    func urls(_ compression: PhotoAsset.Compression? = nil) async -> [URL] {
        await withCheckedContinuation { continuation in
            getURLs(
                compression: compression
            ) {
                continuation.resume(with: .success($0))
            }
        }
    }
    
    func objects<T: PhotoAssetObject>(_ compression: PhotoAsset.Compression? = nil) async throws -> [T] {
        try await withCheckedThrowingContinuation { continuation in
            getObjects(compression) {
                continuation.resume(with: $0)
            }
        }
    }
    
    func getObjects<T: PhotoAssetObject>(_ compression: PhotoAsset.Compression?, completion: @escaping (Result<[T], PickerError>) -> Void) {
        Task {
            var results: [T] = []
            for (index, photoAsset) in photoAssets.enumerated() {
                do {
                    let result = try await T.fetchObject(photoAsset, compression: compression)
                    results.append(result)
                } catch {
                    completion(.failure(.objsFetchFaild(photoAsset, index, error)))
                    return
                }
            }
            completion(.success(results))
        }
    }
}
