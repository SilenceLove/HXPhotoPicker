//
//  AssetManager+VideoURL.swift
//  HXPhotoPicker
//
//  Created by Slience on 2021/1/8.
//

import UIKit
import Photos

// MARK: 获取视频地址
public extension AssetManager {
    
    typealias VideoURLResultHandler = (Result<URL, AssetError>) -> Void
    
    /// 请求获取视频地址
    /// - Parameters:
    ///   - asset: 对应的 PHAsset 数据
    ///   - resultHandler: 获取结果
    static func requestVideoURL(
        for asset: PHAsset,
        exportParameter: VideoExportParameter? = .init(
            preset: .ratio_960x540,
            quality: 6
        ),
        resultHandler: @escaping VideoURLResultHandler
    ) {
        requestAVAsset(
            for: asset
        ) { (reqeustID) in
        } progressHandler: { (progress, error, stop, info) in
        } resultHandler: { (_) in
            self.requestVideoURL(
                mp4Format: asset,
                exportParameter: exportParameter,
                resultHandler: resultHandler
            )
        }
    }
    
    /// 请求获取mp4格式的视频地址
    /// - Parameters:
    ///   - asset: 对应的 PHAsset 数据
    ///   - resultHandler: 获取结果
    static func requestVideoURL(
        mp4Format asset: PHAsset,
        exportParameter: VideoExportParameter? = .init(
            preset: .ratio_960x540,
            quality: 6
        ),
        resultHandler: @escaping VideoURLResultHandler
    ) {
        let videoURL = PhotoTools.getVideoTmpURL()
        requestVideoURL(
            for: asset,
            toFile: videoURL,
            exportParameter: exportParameter,
            resultHandler: resultHandler
        )
    }
    
    /// 获取视频地址
    /// - Parameters:
    ///   - asset: 对应的 PHAsset 数据
    ///   - fileURL: 指定视频地址
    ///   - resultHandler: 获取结果
    static func requestVideoURL(
        for asset: PHAsset,
        toFile fileURL: URL,
        exportParameter: VideoExportParameter? = nil,
        resultHandler: @escaping VideoURLResultHandler
    ) {
        if let exportParameter = exportParameter {
            requestAVAsset(
                for: asset
            ) { (result) in
                switch result {
                case .success(let avResult):
                    let avAsset = avResult.avAsset
                    let presetName = exportParameter.preset.name
                    guard let exportSession = AVAssetExportSession(
                            asset: avAsset,
                            presetName: presetName
                    ) else {
                        resultHandler(.failure(.exportFailed(nil)))
                        return
                    }
                    exportSession.outputURL = fileURL
                    exportSession.shouldOptimizeForNetworkUse = true
                    exportSession.outputFileType = .mp4
                    if exportParameter.quality > 0 {
                        var maxSize: Int?
                        if let urlAsset = avAsset as? AVURLAsset {
                            maxSize = urlAsset.url.fileSize
                        }
                        exportSession.fileLengthLimit = PhotoTools.exportSessionFileLengthLimit(
                            seconds: avAsset.duration.seconds,
                            maxSize: maxSize,
                            exportPreset: exportParameter.preset,
                            videoQuality: exportParameter.quality
                        )
                    }
                    exportSession.exportAsynchronously(completionHandler: {
                        DispatchQueue.main.async {
                            switch exportSession.status {
                            case .completed:
                                resultHandler(.success(fileURL))
                            case .failed, .cancelled:
                                resultHandler(.failure(.exportFailed(exportSession.error)))
                            default: break
                            }
                        }
                    })
                case .failure(let error):
                    resultHandler(.failure(error.error))
                }
            }
        }else {
            requestOriginalVideoURL(
                for: asset,
                toFile: fileURL,
                resultHandler: resultHandler
            )
        }
    }
    
    /// 获取原始视频
    /// - Parameters:
    ///   - asset: 对应的 PHAsset 数据
    ///   - fileURL: 指定视频地址
    ///   - isOriginal: 是否获取系统相册最原始的数据，如果在系统相册编辑过，则获取的是未编辑的视频
    ///   - resultHandler: 获取结果
    static func requestOriginalVideoURL(
        for asset: PHAsset,
        toFile fileURL: URL,
        isOriginal: Bool = false,
        resultHandler: @escaping VideoURLResultHandler
    ) {
        var videoResource: PHAssetResource?
        var resources: [PHAssetResourceType: PHAssetResource] = [:]
        for resource in PHAssetResource.assetResources(for: asset) {
            resources[resource.type] = resource
        }
        if isOriginal {
            if let resource = resources[.video] {
                videoResource = resource
            }else if let resource = resources[.fullSizeVideo] {
                videoResource = resource
            }
        }else {
            if let resource = resources[.fullSizeVideo] {
                videoResource = resource
            }else if let resource = resources[.video] {
                videoResource = resource
            }
        }
        guard let videoResource = videoResource else {
            resultHandler(.failure(.assetResourceIsEmpty))
            return
        }
        if !PhotoTools.removeFile(fileURL: fileURL) {
            resultHandler(.failure(.removeFileFailed))
            return
        }
        let videoURL = fileURL
        let options = PHAssetResourceRequestOptions()
        options.isNetworkAccessAllowed = true
        PHAssetResourceManager.default().writeData(
            for: videoResource,
            toFile: videoURL,
            options: options
        ) { (error) in
            DispatchQueue.main.async {
                if error == nil {
                    resultHandler(.success(videoURL))
                }else {
                    resultHandler(.failure(.assetResourceWriteDataFailed(error!)))
                }
            }
        }
    }
}
