//
//  AssetManager+ImageData.swift
//  HXPHPicker
//
//  Created by Slience on 2021/1/8.
//

import UIKit
import Photos

public extension AssetManager {
    typealias ImageDataResultHandler = (Result<ImageDataResult, ImageDataError>) -> Void
    
    struct ImageDataResult {
        public let imageData: Data
        public let dataUTI: String
        public let imageOrientation: UIImage.Orientation
        public let info: [AnyHashable : Any]?
    }
    
    struct ImageDataError: Error {
        public let info: [AnyHashable : Any]?
        public let error: AssetError
    }
    
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
                                iCloudHandler: ((PHImageRequestID) -> Void)?,
                                progressHandler: PHAssetImageProgressHandler?,
                                resultHandler: @escaping ImageDataResultHandler) -> PHImageRequestID {
        return requestImageData(for: asset, version: version, isNetworkAccessAllowed: false, progressHandler: progressHandler) { (result) in
            DispatchQueue.main.async {
                switch result {
                case .failure(let error):
                    switch error.error {
                    case .needSyncICloud:
                        let iCloudRequestID = self.requestImageData(for: asset, version: version, isNetworkAccessAllowed: true, progressHandler: progressHandler, resultHandler: { (result) in
                            DispatchQueue.main.async {
                                switch result {
                                case .success(_):
                                    resultHandler(result)
                                case .failure(let error):
                                    resultHandler(.failure(.init(info: error.info, error: .syncICloudFailed(error.info))))
                                }
                            }
                        })
                        iCloudHandler?(iCloudRequestID)
                    default:
                        resultHandler(.failure(error))
                        break
                    }
                default:
                    resultHandler(result)
                    break
                }
            }
        }
    }
    
    /// 请求imageData，注意处理 HEIC格式
    @discardableResult
    class func requestImageData(for asset: PHAsset,
                                version: PHImageRequestOptionsVersion,
                                isNetworkAccessAllowed: Bool,
                                progressHandler: PHAssetImageProgressHandler?,
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
                func result() {
                    if let imageData = imageData, self.assetDownloadFinined(for: info) {
                        resultHandler(.success(.init(imageData: imageData, dataUTI: dataUTI!, imageOrientation: sureOrientation, info: info)))
                        return
                    }
                    
                    if let inICloud = info?.inICloud, inICloud {
                        resultHandler(.failure(.init(info: info, error: .needSyncICloud)))
                    }else {
                        resultHandler(.failure(.init(info: info, error: .requestFailed(info))))
                    }
                }
                if DispatchQueue.isMain {
                    result()
                }else {
                    DispatchQueue.main.async {
                        result()
                    }
                }
            }
        } else {
            // Fallback on earlier versions
            return PHImageManager.default().requestImageData(for: asset, options: options) { (imageData, dataUTI, imageOrientation, info) in
                func result() {
                    if let imageData = imageData {
                        resultHandler(.success(.init(imageData: imageData, dataUTI: dataUTI!, imageOrientation: imageOrientation, info: info)))
                        return
                    }
                    if let inICloud = info?.inICloud, inICloud {
                        resultHandler(.failure(.init(info: info, error: .needSyncICloud)))
                    }else {
                        resultHandler(.failure(.init(info: info, error: .requestFailed(info))))
                    }
                }
                if DispatchQueue.isMain {
                    result()
                }else {
                    DispatchQueue.main.async {
                        result()
                    }
                }
            }
        }
    }
}
