//
//  AssetManager+AVAsset.swift
//  HXPHPicker
//
//  Created by Slience on 2021/1/8.
//

import UIKit
import Photos

public typealias AVAssetResultHandler = (AVAsset?, AVAudioMix?, [AnyHashable : Any]?) -> Void

public extension AssetManager {
    
    /// 请求获取AVAsset，如果资源在iCloud上会自动请求下载iCloud上的资源
    /// - Parameters:
    ///   - asset: 对应的 PHAsset 数据
    ///   - iCloudHandler: 如果资源在iCloud上，下载之前回先回调出请求ID
    ///   - progressHandler: iCloud下载进度
    ///   - resultHandler: AVAsset，AVAudioMix，info，downloadSuccess
    /// - Returns: 请求ID
    @discardableResult
    class func requestAVAsset(for asset: PHAsset,
                              deliveryMode: PHVideoRequestOptionsDeliveryMode = .automatic,
                              iCloudHandler: @escaping (PHImageRequestID) -> Void,
                              progressHandler: @escaping PHAssetImageProgressHandler,
                              resultHandler: @escaping (AVAsset?, AVAudioMix?, [AnyHashable : Any]?, Bool) -> Void) -> PHImageRequestID {
        let version = PHVideoRequestOptionsVersion.current
        return requestAVAsset(for: asset, version: version, deliveryMode: deliveryMode, isNetworkAccessAllowed: false, progressHandler: progressHandler) { (avAsset, audioMix, info) in
            DispatchQueue.main.async {
                if self.assetDownloadFinined(for: info) {
                    if avAsset?.isPlayable == false {
                        self.requestAVAsset(for: asset, deliveryMode: .highQualityFormat, iCloudHandler: iCloudHandler, progressHandler: progressHandler, resultHandler: resultHandler)
                    }else {
                        resultHandler(avAsset, audioMix, info, true)
                    }
                }else {
                    if self.assetIsInCloud(for: info) {
                        let iCloudRequestID = self.requestAVAsset(for: asset, version: version, deliveryMode: deliveryMode, isNetworkAccessAllowed: true, progressHandler: progressHandler) { (avAsset, audioMix, info) in
                            DispatchQueue.main.async {
                                if self.assetDownloadFinined(for: info) {
                                    if avAsset?.isPlayable == false {
                                        self.requestAVAsset(for: asset, deliveryMode: .highQualityFormat, iCloudHandler: iCloudHandler, progressHandler: progressHandler, resultHandler: resultHandler)
                                    }else {
                                        resultHandler(avAsset, audioMix, info, true)
                                    }
                                }else {
                                    resultHandler(avAsset, audioMix, info, false)
                                }
                            }
                        }
                        iCloudHandler(iCloudRequestID)
                    }else {
                        resultHandler(avAsset, audioMix, info, false)
                    }
                }
            }
        }
    }
    
    /// 请求AVAsset，如果资源在iCloud上会自动请求下载iCloud上的资源
    /// - Parameters:
    ///   - isNetworkAccessAllowed: 如果资源在iCloud上，下载之前回先回调出请求ID
    ///   - progressHandler: iCloud下载进度
    ///   - resultHandler: 获取结果
    /// - Returns: 请求ID
    @discardableResult
    class func requestAVAsset(for asset: PHAsset,
                              version: PHVideoRequestOptionsVersion,
                              deliveryMode: PHVideoRequestOptionsDeliveryMode,
                              isNetworkAccessAllowed: Bool,
                              progressHandler: @escaping PHAssetImageProgressHandler,
                              resultHandler: @escaping AVAssetResultHandler) -> PHImageRequestID {
        let options = PHVideoRequestOptions.init()
        options.isNetworkAccessAllowed = isNetworkAccessAllowed
        options.progressHandler = progressHandler
        options.version = version
        options.deliveryMode = deliveryMode
        return requestAVAsset(for: asset, options: options, resultHandler: resultHandler)
    }
    
    /// 请求AVAsset
    /// - Parameters:
    ///   - asset: 对应的 PHAsset
    ///   - options: 可选项
    ///   - resultHandler: 获取结果
    /// - Returns: 请求ID
    @discardableResult
    class func requestAVAsset(for asset: PHAsset,
                              options: PHVideoRequestOptions,
                              resultHandler: @escaping AVAssetResultHandler) -> PHImageRequestID {
        return PHImageManager.default().requestAVAsset(forVideo: asset, options: options, resultHandler: resultHandler)
    }
}
