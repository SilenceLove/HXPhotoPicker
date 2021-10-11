//
//  AssetManager+AVAsset.swift
//  HXPHPicker
//
//  Created by Slience on 2021/1/8.
//

import UIKit
import Photos

public extension AssetManager {
    typealias AVAssetResultHandler = (Result<AVAssetResult, AVAssetError>) -> Void
    
    struct AVAssetResult {
        public let avAsset: AVAsset
        public let avAudioMix: AVAudioMix?
        public let info: [AnyHashable: Any]?
    }
    
    struct AVAssetError: Error {
        public let info: [AnyHashable: Any]?
        public let error: AssetError
    }
    
    /// 请求获取AVAsset，如果资源在iCloud上会自动请求下载iCloud上的资源
    /// - Parameters:
    ///   - asset: 对应的 PHAsset 数据
    ///   - iCloudHandler: 如果资源在iCloud上，下载之前回先回调出请求ID
    ///   - progressHandler: iCloud下载进度
    ///   - resultHandler: AVAsset，AVAudioMix，info，downloadSuccess
    /// - Returns: 请求ID
    @discardableResult
    static func requestAVAsset(
        for asset: PHAsset,
        deliveryMode: PHVideoRequestOptionsDeliveryMode = .automatic,
        iCloudHandler: ((PHImageRequestID) -> Void)?,
        progressHandler: PHAssetImageProgressHandler?,
        resultHandler: @escaping AVAssetResultHandler
    ) -> PHImageRequestID {
        let version = PHVideoRequestOptionsVersion.current
        return requestAVAsset(
            for: asset,
            version: version,
            deliveryMode: deliveryMode,
            isNetworkAccessAllowed: false,
            progressHandler:
                progressHandler) { (result) in
            DispatchQueue.main.async {
                switch result {
                case .success(let avResult):
                    if avResult.avAsset.isPlayable == false {
                        self.requestAVAsset(
                            for: asset,
                            deliveryMode: .highQualityFormat,
                            iCloudHandler: iCloudHandler,
                            progressHandler: progressHandler,
                            resultHandler: resultHandler
                        )
                    }else {
                        resultHandler(.success(avResult))
                    }
                case .failure(let error):
                    switch error.error {
                    case .needSyncICloud:
                        let iCloudRequestID = self.requestAVAsset(
                            for: asset,
                            version: version,
                            deliveryMode: deliveryMode,
                            isNetworkAccessAllowed: true,
                            progressHandler: progressHandler
                        ) { (result) in
                            DispatchQueue.main.async {
                                switch result {
                                case .success(let avResult):
                                    if avResult.avAsset.isPlayable == false {
                                        self.requestAVAsset(
                                            for: asset,
                                            deliveryMode: .highQualityFormat,
                                            iCloudHandler: iCloudHandler,
                                            progressHandler: progressHandler,
                                            resultHandler: resultHandler)
                                    }else {
                                        resultHandler(.success(avResult))
                                    }
                                case .failure(let error):
                                    resultHandler(
                                        .failure(
                                            .init(
                                                info: error.info,
                                                error: .syncICloudFailed(error.info)
                                            )
                                        )
                                    )
                                }
                            }
                        }
                        iCloudHandler?(iCloudRequestID)
                    default:
                        resultHandler(.failure(error))
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
    static func requestAVAsset(
        for asset: PHAsset,
        version: PHVideoRequestOptionsVersion,
        deliveryMode: PHVideoRequestOptionsDeliveryMode,
        isNetworkAccessAllowed: Bool,
        progressHandler: PHAssetVideoProgressHandler?,
        resultHandler: @escaping AVAssetResultHandler
    ) -> PHImageRequestID {
        let options = PHVideoRequestOptions.init()
        options.isNetworkAccessAllowed = isNetworkAccessAllowed
        options.progressHandler = progressHandler
        options.version = version
        options.deliveryMode = deliveryMode
        return requestAVAsset(
            for: asset,
            options: options,
            resultHandler: resultHandler
        )
    }
    
    /// 请求AVAsset
    /// - Parameters:
    ///   - asset: 对应的 PHAsset
    ///   - options: 可选项
    ///   - resultHandler: 获取结果
    /// - Returns: 请求ID
    @discardableResult
    static func requestAVAsset(
        for asset: PHAsset,
        options: PHVideoRequestOptions,
        resultHandler: @escaping AVAssetResultHandler
    ) -> PHImageRequestID {
        return PHImageManager.default().requestAVAsset(
            forVideo: asset,
            options: options
        ) { avAsset, avAudioMix, info in
            DispatchQueue.main.async {
                if self.assetDownloadFinined(for: info) && avAsset != nil {
                    resultHandler(
                        .success(
                            .init(
                                avAsset: avAsset!,
                                avAudioMix: avAudioMix,
                                info: info
                            )
                        )
                    )
                }else {
                    if self.assetIsInCloud(for: info) {
                        resultHandler(
                            .failure(
                                .init(
                                    info: info,
                                    error: .needSyncICloud
                                )
                            )
                        )
                        return
                    }
                    resultHandler(
                        .failure(
                            .init(
                                info: info,
                                error: .requestFailed(info)
                            )
                        )
                    )
                }
            }
        }
    }
}
