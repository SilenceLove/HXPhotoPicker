//
//  AssetManager+ImageURL.swift
//  HXPHPicker
//
//  Created by Slience on 2021/1/8.
//

import UIKit
import Photos

// MARK: 获取图片地址
public extension AssetManager {
    typealias ImageURLResultHandler = (Result<URL, AssetError>) -> Void
    
    /// 请求获取图片地址
    /// - Parameters:
    ///   - asset: 对应的 PHAsset 数据
    ///   - resultHandler: 获取结果
    static func requestImageURL(
        for asset: PHAsset,
        resultHandler: @escaping ImageURLResultHandler
    ) {
        requestImageURL(
            for: asset,
            suffix: "png",
            resultHandler: resultHandler
        )
    }
    
    /// 请求获取图片地址
    /// - Parameters:
    ///   - asset: 对应的 PHAsset 数据
    ///   - suffix: 后缀格式
    ///   - resultHandler: 获取结果
    static func requestImageURL(
        for asset: PHAsset,
        suffix: String,
        resultHandler: @escaping ImageURLResultHandler
    ) {
        let imageURL = PhotoTools.getTmpURL(for: suffix)
        requestImageURL(
            for: asset,
            toFile: imageURL,
            resultHandler: resultHandler
        )
    }
    
    /// 请求获取图片地址
    /// - Parameters:
    ///   - asset: 对应的 PHAsset 数据
    ///   - fileURL: 指定本地地址
    ///   - resultHandler: 获取结果
    static func requestImageURL(
        for asset: PHAsset,
        toFile fileURL: URL,
        resultHandler: @escaping ImageURLResultHandler
    ) {
        asset.checkAdjustmentStatus { (isAdjusted) in
            if isAdjusted {
                self.requestImageData(
                    for: asset,
                    version: .current,
                    iCloudHandler: nil,
                    progressHandler: nil
                ) { (result) in
                    switch result {
                    case .success(let dataResult):
                        if let imageURL = PhotoTools.write(
                            toFile: fileURL,
                            imageData: dataResult.imageData
                        ) {
                            resultHandler(.success(imageURL))
                        }else {
                            resultHandler(.failure(.fileWriteFailed))
                        }
                    case .failure(let error):
                        resultHandler(.failure(error.error))
                    }
                }
            }else {
                var imageResource: PHAssetResource?
                for resource in PHAssetResource.assetResources(for: asset) where
                    resource.type == .photo {
                    imageResource = resource
                    break
                }
                guard let imageResource = imageResource else {
                    resultHandler(.failure(.assetResourceIsEmpty))
                    return
                }
                if !PhotoTools.removeFile(fileURL: fileURL) {
                    resultHandler(.failure(.removeFileFailed))
                    return
                }
                let imageURL = fileURL
                let options = PHAssetResourceRequestOptions.init()
                options.isNetworkAccessAllowed = true
                PHAssetResourceManager.default().writeData(
                    for: imageResource,
                    toFile: imageURL,
                    options: options
                ) { (error) in
                    DispatchQueue.main.async {
                        if error == nil {
                            resultHandler(.success(imageURL))
                        }else {
                            resultHandler(.failure(.assetResourceWriteDataFailed(error!)))
                        }
                    }
                }
            }
        }
    }
    
    /// 请求获取图片地址
    /// - Parameters:
    ///   - asset: 对应的 PHAsset 数据
    ///   - resultHandler: 获取结果
    /// - Returns: 请求ID
    @discardableResult
    static func requestImageURL(
        for asset: PHAsset,
        resultHandler: @escaping (URL?, UIImage?) -> Void
    ) -> PHContentEditingInputRequestID {
        let options = PHContentEditingInputRequestOptions.init()
        options.isNetworkAccessAllowed = true
        return asset.requestContentEditingInput(
            with: options
        ) { (input, info) in
            DispatchQueue.main.async {
                resultHandler(
                    input?.fullSizeImageURL,
                    input?.displaySizeImage
                )
            }
        }
    }
}
