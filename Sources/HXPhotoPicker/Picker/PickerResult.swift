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
    public var isOriginal: Bool
    
    /// isOriginal = false
    /// The original image does not select the compression parameter when getting the URL
    /// 原图未选中获取 URL 时的压缩参数，默认为空
    public var compression: PhotoAsset.Compression? {
        get { PhotoManager.shared.pickerResultCompression }
        set { PhotoManager.shared.pickerResultCompression = newValue }
    }
    
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
    
    /// 获取  image
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
        photoAssets.getImage(
            targetSize: targetSize,
            targetMode: targetMode,
            imageHandler: imageHandler,
            completionHandler: completionHandler
        )
    }
    
    /// Get video address / 获取视频地址
    /// - Parameters:
    ///   - videoURLConfig: 指定视频路径
    ///   - exportSession: The corresponding AVAssetExportSession when exporting video, triggered when exportPreset is not nil / 导出视频时对应的 AVAssetExportSession，exportPreset不为nil时触发
    ///   - videoURLHandler: Triggered every time the video address is obtained / 每一次获取视频地址都会触发
    ///   - completionHandler: All acquisitions are completed (failures will not be added) / 全部获取完成(失败的不会添加)
    func getVideoURL(
        toFile videoURLConfig: ((PhotoAsset, Int) -> URL)? = nil,
        exportSession: AVAssetExportSessionHandler? = nil,
        videoURLHandler: URLHandler? = nil,
        completionHandler: @escaping ([URL]) -> Void
    ) {
        photoAssets.getVideoURL(
            exportParameter: isOriginal ? nil : compression?.videoExportParameter,
            toFile: videoURLConfig,
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
        toFileConfigHandler fileConfig: FileConfigHandler? = nil,
        completion: @escaping ([URL]) -> Void
    ) {
        photoAssets.getURLs(
            options: options,
            compression: isOriginal ? nil : compression,
            toFileConfigHandler: fileConfig,
            completion: completion
        )
    }
    
    /// Get the address of the selected resource / 获取已选资源的地址
    /// Include web images / 包括网络图片
    /// - Parameters:
    ///   - options: type of get / 获取的类型
    ///   - fileConfig: 指定文件路径配置回调
    ///   - completionHandler: All acquisition completed / 全部获取完成
    func getURLs(
        options: Options = .any,
        toFileConfigHandler fileConfig: FileConfigHandler? = nil,
        urlReceivedHandler handler: URLHandler? = nil,
        completionHandler: @escaping ([URL]) -> Void
    ) {
        photoAssets.getURLs(
            options: options,
            compression: isOriginal ? nil : compression,
            toFile: fileConfig,
            urlReceivedHandler: handler,
            completionHandler: completionHandler
        )
    }
    
    func getURLs(
        compression: PhotoAsset.Compression? = nil,
        toFileConfigHandler fileConfig: FileConfigHandler? = nil,
        urlReceivedHandler handler: URLHandler? = nil,
        completionHandler: @escaping ([URL]) -> Void
    ) {
        photoAssets.getURLs(
            options: .any,
            compression: compression,
            toFile: fileConfig,
            urlReceivedHandler: handler,
            completionHandler: completionHandler
        )
    }
}

extension PickerResult {
    /// (image, PhotoAsset object, index)
    /// (图片、PhotoAsset 对象, 下标)
    public typealias ImageHandler = (UIImage?, PhotoAsset, Int) -> Void
    /// (corresponding AVAssetExportSession object, PhotoAsset object, index when exporting video)
    /// (导出视频时对应的 AVAssetExportSession 对象, PhotoAsset 对象, 下标)
    public typealias AVAssetExportSessionHandler = (AVAssetExportSession, PhotoAsset, Int) -> Void
    /// (Result of getting URL, PhotoAsset object, index)
    /// (获取URL的结果、PhotoAsset 对象, 下标)
    public typealias URLHandler = (Result<AssetURLResult, AssetError>, PhotoAsset, Int) -> Void
    /// (PhotoAsset 对象, 下标)
    public typealias FileConfigHandler = (PhotoAsset, Int) -> PhotoAsset.FileConfig
}

@available(iOS 13.0.0, *)
public extension PickerResult {
    
    /// 获取 UIImage 对象数组
    /// - Parameter compressionScale: 压缩参数，不传则根据内部 isOriginal 判断是否压缩
    /// - Returns: UIImage 对象数组
    func images(_ compressionScale: CGFloat? = nil) async throws -> [UIImage] {
        try await objects(compression)
    }
    
    /// 获取 URL 对象数组
    /// - Parameters:
    ///   - compression: 压缩参数，不传则根据内部 isOriginal 判断是否压缩
    ///   - fileConfig: 指定路径
    ///   - Returns: URL 对象数组
    func urls(_ compression: PhotoAsset.Compression? = nil, toFile fileConfig: FileConfigHandler? = nil) async throws -> [URL] {
        try await objects(compression, toFile: fileConfig)
    }
    
    /// 获取 AssetURLResult 对象数组
    /// - Parameters:
    ///   - compression: 压缩参数，不传则根据内部 isOriginal 判断是否压缩
    ///   - fileConfig: 指定路径
    ///   - Returns: AssetURLResult 对象数组
    func urlResults(_ compression: PhotoAsset.Compression? = nil, toFile fileConfig: FileConfigHandler? = nil) async throws -> [AssetURLResult] {
        try await objects(compression, toFile: fileConfig)
    }
    
    /// 获取 AssetResult 对象数组
    /// - Parameters:
    ///   - compression: 压缩参数，不传则根据内部 isOriginal 判断是否压缩
    ///   - fileConfig: 指定路径
    ///   - Returns: AssetResult 对象数组
    func assetResults(_ compression: PhotoAsset.Compression? = nil, toFile fileConfig: FileConfigHandler? = nil) async throws -> [AssetResult] {
        try await objects(compression, toFile: fileConfig)
    }
    
    /// 获取对应资源
    /// - Parameters:
    ///   - compression: 压缩参数，不传则根据内部 isOriginal 判断是否压缩
    ///   - fileConfig: 指定路径
    /// - Returns: 对应的对象数组
    func objects<T: PhotoAssetObject>(_ compression: PhotoAsset.Compression? = nil, toFile fileConfig: FileConfigHandler? = nil) async throws -> [T] {
        let _compression: PhotoAsset.Compression?
        if let compression = compression {
            _compression = compression
        }else {
            _compression = isOriginal ? nil : self.compression
        }
        var results: [T] = []
        for (index, photoAsset) in photoAssets.enumerated() {
            if Task.isCancelled { throw PickerError.canceled }
            do {
                var toFileConfig: PhotoAsset.FileConfig?
                if let fileConfig = fileConfig?(photoAsset, index) {
                    toFileConfig = fileConfig
                }
                let result: T = try await photoAsset.object(_compression, toFile: toFileConfig)
                results.append(result)
            } catch {
                throw PickerError.objsFetchFaild(photoAsset, index, error)
            }
        }
        if Task.isCancelled { throw PickerError.canceled }
        return results
    }
    
    /// 获取 UIImage 对象数组
    /// - Parameters:
    ///   - targetSize: 指定`imageSize`
    ///   - targetMode: 裁剪模式
    /// - Returns: `UIImage` 对象数组
    func images(targetSize: CGSize, targetMode: HX.ImageTargetMode = .fill) async throws -> [UIImage] {
        var results: [UIImage] = []
        for (index, photoAsset) in photoAssets.enumerated() {
            if Task.isCancelled { throw PickerError.canceled }
            do {
                let result = try await photoAsset.image(targetSize: targetSize, targetMode: targetMode)
                results.append(result)
            } catch {
                throw PickerError.objsFetchFaild(photoAsset, index, error)
            }
        }
        if Task.isCancelled { throw PickerError.canceled }
        return results
    }
}
