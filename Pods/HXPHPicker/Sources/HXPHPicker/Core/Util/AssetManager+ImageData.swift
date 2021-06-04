//
//  AssetManager+ImageData.swift
//  HXPHPicker
//
//  Created by Slience on 2021/1/8.
//

import UIKit
import Photos

public typealias ImageDataResultHandler = (Data?, String?, UIImage.Orientation, [AnyHashable : Any]?) -> Void
public typealias ImageDataFetchCompletion = (Data?, String?, UIImage.Orientation, [AnyHashable : Any]?, Bool) -> Void

public extension AssetManager {
    
    /// 请求imageData，如果资源在iCloud上会自动请求下载iCloud上的资源 注意处理 HEIC格式
    /// - Parameters:
    ///   - asset: 对应的 PHAsset 数据 
    ///   - iCloudHandler: 如果资源在iCloud上，下载之前回先回调出请求ID
    ///   - progressHandler: iCloud下载进度
    ///   - resultHandler: 获取结果
    /// - Returns: 请求ID
    @discardableResult
    class func requestImageData(for asset: PHAsset,
                                version: PHImageRequestOptionsVersion,
                                iCloudHandler: @escaping (PHImageRequestID) -> Void,
                                progressHandler: @escaping PHAssetImageProgressHandler,
                                resultHandler: @escaping ImageDataFetchCompletion) -> PHImageRequestID {
        return requestImageData(for: asset, version: version, isNetworkAccessAllowed: false, progressHandler: progressHandler) { (data, dataUTI, imageOrientation, info) in
            DispatchQueue.main.async {
                if self.assetDownloadFinined(for: info) {
                    resultHandler(data, dataUTI, imageOrientation, info, true)
                }else {
                    if self.assetIsInCloud(for: info) {
                        let iCloudRequestID = self.requestImageData(for: asset, version: version, isNetworkAccessAllowed: true, progressHandler: progressHandler, resultHandler: { (data, dataUTI, imageOrientation, info) in
                            DispatchQueue.main.async {
                                resultHandler(data, dataUTI, imageOrientation, info, self.assetDownloadFinined(for: info))
                            }
                        })
                        iCloudHandler(iCloudRequestID)
                    }else {
                        resultHandler(data, dataUTI, imageOrientation, info, false)
                    }
                }
            }
        }
    }
    
    /// 请求imageData，注意处理 HEIC格式
    @discardableResult
    class func requestImageData(for asset: PHAsset,
                                version: PHImageRequestOptionsVersion,
                                isNetworkAccessAllowed: Bool,
                                progressHandler: @escaping PHAssetImageProgressHandler,
                                resultHandler: @escaping ImageDataResultHandler) -> PHImageRequestID {
        let options = PHImageRequestOptions.init()
        options.version = version
        options.resizeMode = .fast
        options.isNetworkAccessAllowed = isNetworkAccessAllowed
        options.progressHandler = progressHandler
        return requestImageData(for: asset, options: options, resultHandler: resultHandler)
    }
    /// 请求imageData，注意处理 HEIC格式
    @discardableResult
    class func requestImageData(for asset: PHAsset,
                                options: PHImageRequestOptions,
                                resultHandler: @escaping ImageDataResultHandler) -> PHImageRequestID {
        if #available(iOS 13, *) {
            return PHImageManager.default().requestImageDataAndOrientation(for: asset, options: options) { (imageData, dataUTI, imageOrientation, info) in
                var sureOrientation : UIImage.Orientation;
                if (imageOrientation == .up) {
                    sureOrientation = .up;
                } else if (imageOrientation == .upMirrored) {
                    sureOrientation = .upMirrored;
                } else if (imageOrientation == .down) {
                    sureOrientation = .down;
                } else if (imageOrientation == .downMirrored) {
                    sureOrientation = .downMirrored;
                } else if (imageOrientation == .left) {
                    sureOrientation = .left;
                } else if (imageOrientation == .leftMirrored) {
                    sureOrientation = .leftMirrored;
                } else if (imageOrientation == .right) {
                    sureOrientation = .right;
                } else if (imageOrientation == .rightMirrored) {
                    sureOrientation = .rightMirrored;
                } else {
                    sureOrientation = .up;
                }
                
                if DispatchQueue.isMain {
                    resultHandler(imageData, dataUTI, sureOrientation, info)
                }else {
                    DispatchQueue.main.async {
                        resultHandler(imageData, dataUTI, sureOrientation, info)
                    }
                }
            }
        } else {
            // Fallback on earlier versions
            return PHImageManager.default().requestImageData(for: asset, options: options) { (imageData, dataUTI, imageOrientation, info) in
                if DispatchQueue.isMain {
                    resultHandler(imageData, dataUTI, imageOrientation, info)
                }else {
                    DispatchQueue.main.async {
                        resultHandler(imageData, dataUTI, imageOrientation, info)
                    }
                }
            }
        }
    }
}
