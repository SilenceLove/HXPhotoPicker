//
//  AssetManager+VideoURL.swift
//  HXPHPicker
//
//  Created by Slience on 2021/1/8.
//

import UIKit
import Photos

public typealias VideoURLResultHandler = (URL?) -> Void

// MARK: 获取视频地址
public extension AssetManager {
    
    /// 请求获取视频地址
    /// - Parameters:
    ///   - asset: 对应的 PHAsset 数据
    ///   - resultHandler: 获取结果
    class func requestVideoURL(for asset: PHAsset,
                               resultHandler: @escaping VideoURLResultHandler) {
        requestAVAsset(for: asset) { (reqeustID) in
        } progressHandler: { (progress, error, stop, info) in
        } resultHandler: { (avAsset, audioMix, info, downloadSuccess) in
            self.requestVideoURL(mp4Format: asset, resultHandler: resultHandler)
        }
    }
    
    /// 请求获取mp4格式的视频地址
    /// - Parameters:
    ///   - asset: 对应的 PHAsset 数据
    ///   - resultHandler: 获取结果
    class func requestVideoURL(mp4Format asset: PHAsset,
                               resultHandler: @escaping VideoURLResultHandler) {
        let videoURL = PhotoTools.getVideoTmpURL()
        requestVideoURL(for: asset, toFile: videoURL, resultHandler: resultHandler)
    }
    
    /// 获取视频地址
    /// - Parameters:
    ///   - asset: 对应的 PHAsset 数据
    ///   - fileURL: 指定视频地址
    ///   - resultHandler: 获取结果
    class func requestVideoURL(for asset: PHAsset,
                               toFile fileURL:URL,
                               resultHandler: @escaping VideoURLResultHandler) {
        asset.checkAdjustmentStatus { (isAdjusted) in
            if isAdjusted {
                self.requestAVAsset(for: asset, iCloudHandler: nil, progressHandler: nil) { (avAsset, audioMix, info, success) in
                    if let urlAsset = avAsset as? AVURLAsset,
                       PhotoTools.copyFile(at: urlAsset.url, to: fileURL) {
                        resultHandler(fileURL)
                    }else {
                        if let avAsset = avAsset {
                            var presetName: String
                            let presets = AVAssetExportSession.exportPresets(compatibleWith: avAsset)
                            if presets.contains(AVAssetExportPresetHighestQuality) {
                                presetName = AVAssetExportPresetHighestQuality
                            }else if presets.contains(AVAssetExportPreset1280x720) {
                                presetName = AVAssetExportPreset1280x720
                            }else {
                                presetName = AVAssetExportPresetMediumQuality
                            }
                            let exportSession = AVAssetExportSession.init(asset: avAsset, presetName: presetName)
                            exportSession?.outputURL = fileURL
                            exportSession?.shouldOptimizeForNetworkUse = true
                            exportSession?.outputFileType = .mp4
                            exportSession?.exportAsynchronously(completionHandler: {
                                DispatchQueue.main.async {
                                    switch exportSession?.status {
                                    case .completed:
                                        resultHandler(fileURL)
                                    case .failed, .cancelled:
                                        resultHandler(nil)
                                    default: break
                                    }
                                }
                            })
                            return
                        }
                        resultHandler(nil)
                    }
                }
            }else {
                var videoResource: PHAssetResource?
                for resource in PHAssetResource.assetResources(for: asset) {
                    if resource.type == .video {
                        videoResource = resource
                    }
                }
                if videoResource == nil {
                    resultHandler(nil)
                    return
                }
                if !PhotoTools.removeFile(fileURL: fileURL) {
                    resultHandler(nil)
                    return
                }
                let videoURL = fileURL
                let options = PHAssetResourceRequestOptions.init()
                options.isNetworkAccessAllowed = true
                PHAssetResourceManager.default().writeData(for: videoResource!, toFile: videoURL, options: options) { (error) in
                    DispatchQueue.main.async {
                        if error == nil {
                            resultHandler(videoURL)
                        }else {
                            resultHandler(nil)
                        }
                    }
                }
            }
        }
    }
}
