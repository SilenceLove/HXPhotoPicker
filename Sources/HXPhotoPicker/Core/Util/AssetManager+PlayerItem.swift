//
//  AssetManager+PlayerItem.swift
//  HXPhotoPicker
//
//  Created by Silence on 2024/1/24.
//  Copyright © 2024 Silence. All rights reserved.
//

import UIKit
import Photos
import AVKit

public extension AssetManager {
    
    typealias PlayerItemResultHandler = (Result<AVPlayerItem, PlayerItemError>) -> Void
    
    struct PlayerItemError: Error {
        public let info: [AnyHashable: Any]?
        public let error: AssetError
    }
    
    @discardableResult
    static func requestPlayerItem(
        for asset: PHAsset,
        deliveryMode: PHVideoRequestOptionsDeliveryMode = .automatic,
        iCloudHandler: ((PHImageRequestID) -> Void)? = nil,
        progressHandler: PHAssetImageProgressHandler? = nil,
        resultHandler: @escaping PlayerItemResultHandler
    ) -> PHImageRequestID {
        let version = PHVideoRequestOptionsVersion.current
        return requestPlayerItem(
            for: asset,
            version: version,
            deliveryMode: deliveryMode,
            isNetworkAccessAllowed: false,
            progressHandler: nil
        ) { (result) in
            DispatchQueue.main.async {
                switch result {
                case .success(let playerItem):
                    resultHandler(.success(playerItem))
                case .failure(let error):
                    switch error.error {
                    case .needSyncICloud:
                        let iCloudRequestID = self.requestPlayerItem(
                            for: asset,
                            version: version,
                            deliveryMode: deliveryMode,
                            isNetworkAccessAllowed: true,
                            progressHandler: progressHandler
                        ) { (result) in
                            DispatchQueue.main.async {
                                switch result {
                                case .success(let playerItem):
                                    resultHandler(.success(playerItem))
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

    @discardableResult
    static func requestPlayerItem(
        for asset: PHAsset,
        version: PHVideoRequestOptionsVersion,
        deliveryMode: PHVideoRequestOptionsDeliveryMode,
        isNetworkAccessAllowed: Bool,
        progressHandler: PHAssetVideoProgressHandler?,
        resultHandler: @escaping PlayerItemResultHandler
    ) -> PHImageRequestID {
        let options = PHVideoRequestOptions.init()
        options.isNetworkAccessAllowed = isNetworkAccessAllowed
        options.progressHandler = progressHandler
        options.version = version
        options.deliveryMode = deliveryMode
        return requestPlayerItem(
            for: asset,
            options: options,
            resultHandler: resultHandler
        )
    }
    
    @discardableResult
    static func requestPlayerItem(
        for asset: PHAsset,
        options: PHVideoRequestOptions,
        resultHandler: @escaping PlayerItemResultHandler
    ) -> PHImageRequestID {
        PHImageManager.default().requestPlayerItem(
            forVideo: asset,
            options: options
        ) { playerItem, info in
            DispatchQueue.main.async {
                if let playerItem, self.assetDownloadFinined(for: info) {
                    resultHandler(
                        .success(playerItem)
                    )
                }else {
                    if self.assetIsInCloud(for: info) {
                        resultHandler(
                            .failure(
                                .init(
                                    info: info,
                                    error: .needSyncICloud(info)
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
