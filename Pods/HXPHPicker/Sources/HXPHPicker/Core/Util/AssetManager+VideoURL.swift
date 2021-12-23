//
//  AssetManager+VideoURL.swift
//  HXPHPicker
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
        exportPreset: ExportPreset = .ratio_960x540,
        videoQuality: Int = 5,
        resultHandler: @escaping VideoURLResultHandler
    ) {
        requestAVAsset(
            for: asset
        ) { (reqeustID) in
        } progressHandler: { (progress, error, stop, info) in
        } resultHandler: { (_) in
            self.requestVideoURL(
                mp4Format: asset,
                exportPreset: exportPreset,
                videoQuality: videoQuality,
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
        exportPreset: ExportPreset = .ratio_960x540,
        videoQuality: Int = 5,
        resultHandler: @escaping VideoURLResultHandler
    ) {
        let videoURL = PhotoTools.getVideoTmpURL()
        requestVideoURL(
            for: asset,
            toFile: videoURL,
            exportPreset: exportPreset,
            videoQuality: videoQuality,
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
        exportPreset: ExportPreset = .ratio_960x540,
        videoQuality: Int = 6,
        resultHandler: @escaping VideoURLResultHandler
    ) {
        asset.checkAdjustmentStatus { (isAdjusted) in
            if isAdjusted {
                self.requestAVAsset(
                    for: asset,
                       iCloudHandler: nil,
                       progressHandler: nil
                ) { (result) in
                    switch result {
                    case .success(let avResult):
                        let avAsset = avResult.avAsset
                        if let urlAsset = avAsset as? AVURLAsset,
                           PhotoTools.copyFile(at: urlAsset.url, to: fileURL) {
                            resultHandler(.success(fileURL))
                        }else {
                            let presetName = exportPreset.name
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
                            if videoQuality > 0 {
                                exportSession.fileLengthLimit = PhotoTools.exportSessionFileLengthLimit(
                                    seconds: avAsset.duration.seconds,
                                    exportPreset: exportPreset,
                                    videoQuality: videoQuality
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
                        }
                    case .failure(let error):
                        resultHandler(.failure(error.error))
                    }
                }
            }else {
                var videoResource: PHAssetResource?
                for resource in PHAssetResource.assetResources(for: asset) where
                    resource.type == .video {
                    videoResource = resource
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
    }
}
