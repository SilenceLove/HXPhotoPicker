//
//  AssetManager+LivePhoto.swift
//  HXPHPicker
//
//  Created by Slience on 2021/1/8.
//

import UIKit
import Photos

@available(iOS 9.1, *)
public typealias LivePhotoResultHandler = (PHLivePhoto?, [AnyHashable: Any]?) -> Void

public extension AssetManager {
    
    /// 请求LivePhoto，如果资源在iCloud上会自动请求下载iCloud上的资源
    /// - Parameters:
    ///   - targetSize: 请求的目标大小
    ///   - iCloudHandler: 如果资源在iCloud上，下载之前回先回调出请求ID
    ///   - progressHandler: iCloud下载进度
    ///   - resultHandler: 获取结果
    /// - Returns: 请求ID
    @available(iOS 9.1, *)
    @discardableResult
    static func requestLivePhoto(
        for asset: PHAsset,
        targetSize: CGSize,
        iCloudHandler: @escaping (PHImageRequestID) -> Void,
        progressHandler: @escaping PHAssetImageProgressHandler,
        resultHandler: @escaping (PHLivePhoto?, [AnyHashable: Any]?, Bool) -> Void
    ) -> PHImageRequestID {
        return requestLivePhoto(
            for: asset,
            targetSize: targetSize,
            isNetworkAccessAllowed: false,
            progressHandler: progressHandler
        ) { (livePhoto, info) in
            if self.assetDownloadFinined(for: info) {
                DispatchQueue.main.async {
                    resultHandler(livePhoto, info, true)
                }
            }else {
                if self.assetIsInCloud(for: info) {
                    let iCloudRequestID = self.requestLivePhoto(
                        for: asset,
                        targetSize: targetSize,
                        isNetworkAccessAllowed: true,
                        progressHandler: progressHandler
                    ) { (livePhoto, info) in
                        DispatchQueue.main.async {
                            if self.assetDownloadFinined(for: info) {
                                resultHandler(livePhoto, info, true)
                            }else {
                                resultHandler(livePhoto, info, false)
                            }
                        }
                    }
                    DispatchQueue.main.async {
                        iCloudHandler(iCloudRequestID)
                    }
                }else {
                    DispatchQueue.main.async {
                        resultHandler(livePhoto, info, false)
                    }
                }
            }
        }
    }
    
    @available(iOS 9.1, *)
    @discardableResult
    static func requestLivePhoto(
        for asset: PHAsset,
        targetSize: CGSize,
        isNetworkAccessAllowed: Bool,
        progressHandler: @escaping PHAssetImageProgressHandler,
        resultHandler: @escaping LivePhotoResultHandler
    ) -> PHImageRequestID {
        let options = PHLivePhotoRequestOptions.init()
        options.deliveryMode = .highQualityFormat
        options.isNetworkAccessAllowed = isNetworkAccessAllowed
        options.progressHandler = progressHandler
        return requestLivePhoto(
            for: asset,
            targetSize: targetSize,
            options: options,
            resultHandler: resultHandler
        )
    }
    
    @available(iOS 9.1, *)
    @discardableResult
    static func requestLivePhoto(
        for asset: PHAsset,
        targetSize: CGSize,
        options: PHLivePhotoRequestOptions,
        resultHandler: @escaping LivePhotoResultHandler
    ) -> PHImageRequestID {
        return PHImageManager.default().requestLivePhoto(
            for: asset,
            targetSize: targetSize,
            contentMode: .aspectFill,
            options: options,
            resultHandler: resultHandler
        )
    }
}
