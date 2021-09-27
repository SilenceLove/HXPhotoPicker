//
//  PickerResult.swift
//  HXPHPicker
//
//  Created by Slience on 2021/3/8.
//

import UIKit
import AVFoundation

public struct PickerResult {
    
    /// 已选的资源
    /// getURLs 获取原始资源的URL
    public let photoAssets: [PhotoAsset]
    
    /// 是否选择的原图
    public let isOriginal: Bool
    
    /// 初始化
    /// - Parameters:
    ///   - photoAssets: 对应 PhotoAsset 数据的数组
    ///   - isOriginal: 是否原图
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
    
    /// 获取 image
    /// - Parameters:
    ///   - compressionScale: 压缩比例，获取系统相册里的资源时有效
    ///   - imageHandler: 每一次获取image都会触发
    ///   - completionHandler: 全部获取完成(失败的不会添加)
    func getImage(
        compressionScale: CGFloat = 0.5,
        imageHandler: ((UIImage?, PhotoAsset, Int) -> Void)? = nil,
        completionHandler: @escaping ([UIImage]) -> Void
    ) {
        photoAssets.getImage(
            compressionScale: compressionScale,
            imageHandler: imageHandler,
            completionHandler: completionHandler
        )
    }
    
    /// 获取视频地址
    /// - Parameters:
    ///   - exportPreset: 视频分辨率，默认ratio_640x480，传 nil 获取则是原始视频
    ///   - videoQuality: 视频质量[0-10]，默认4
    ///   - exportSession: 导出视频时对应的 AVAssetExportSession   
    ///   - videoURLHandler: 每一次获取视频地址都会触发
    ///   - completionHandler: 全部获取完成(失败的不会添加)
    func getVideoURL(
        exportPreset: ExportPreset? = .ratio_640x480,
        videoQuality: Int = 4,
        exportSession: ((AVAssetExportSession, PhotoAsset, Int) -> Void)? = nil,
        videoURLHandler: ((Result<AssetURLResult, AssetError>, PhotoAsset, Int) -> Void)? = nil,
        completionHandler: @escaping ([URL]) -> Void
    ) {
        photoAssets.getVideoURL(
            exportPreset: exportPreset,
            videoQuality: videoQuality,
            exportSession: exportSession,
            videoURLHandler: videoURLHandler,
            completionHandler: completionHandler
        )
    }
}

// MARK: Get Original URL
public extension PickerResult {
    
    /// 获取已选资源的地址（原图）
    /// 不包括网络资源，如果网络资源编辑过则会获取
    /// - Parameters:
    ///   - options: 获取的类型
    ///   - completion: result
    func getURLs(
        options: Options = .any,
        completion: @escaping ([URL]) -> Void
    ) {
        photoAssets.getURLs(
            options: options,
            completion: completion
        )
    }
    
    /// 获取已选资源的地址（原图）
    /// 包括网络图片
    /// - Parameters:
    ///   - options: 获取的类型
    ///   - handler: 获取到url的回调
    ///   - completionHandler: 全部获取完成
    func getURLs(
        options: Options = .any,
        urlReceivedHandler handler: (
            (Result<AssetURLResult, AssetError>, PhotoAsset, Int) -> Void
        )? = nil,
        completionHandler: @escaping ([URL]) -> Void
    ) {
        photoAssets.getURLs(
            options: options,
            urlReceivedHandler: handler,
            completionHandler: completionHandler
        )
    }
}
