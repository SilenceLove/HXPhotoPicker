//
//  AssetManager+Image.swift
//  HXPhotoPicker
//
//  Created by Slience on 2021/1/8.
//

import UIKit
import Photos

public typealias ImageResultHandler = (UIImage?, [AnyHashable: Any]?) -> Void

public extension AssetManager {
    
    static var thumbnailTargetWidth: CGFloat {
        min(
            UIDevice.screenSize.width,
            UIDevice.screenSize.height
        )
    }
    
    /// 请求获取缩略图
    /// - Parameters:
    ///   - asset: 资源对象
    ///   - targetWidth: 获取的图片大小
    ///   - completion: 完成
    /// - Returns: 请求ID
    @discardableResult
    static func requestThumbnailImage(
        for asset: PHAsset,
        targetWidth: CGFloat,
        completion: ImageResultHandler?
    ) -> PHImageRequestID {
        let options = PHImageRequestOptions()
        options.resizeMode = .fast
        var isSimplify = false
        let targetSize: CGSize
        #if HXPICKER_ENABLE_PICKER
        isSimplify = PhotoManager.shared.thumbnailLoadMode == .simplify
        if isSimplify {
            options.deliveryMode = .fastFormat
        }
        targetSize = isSimplify ? .init(
            width: targetWidth,
            height: targetWidth
        ) : asset.cellThumTargetSize(for: targetWidth)
        #else
        targetSize = asset.cellThumTargetSize(for: targetWidth)
        #endif
        return requestImage(
            for: asset,
            targetSize: targetSize,
            options: options
        ) { (image, info) in
            DispatchQueue.main.async {
                completion?(image, info)
            }
        }
    }
    
    /// 请求image
    /// - Parameters:
    ///   - asset: 资源对象
    ///   - targetSize: 指定大小
    ///   - options: 可选项
    ///   - resultHandler: 回调
    /// - Returns: 请求ID
    @discardableResult
    static func requestImage(
        for asset: PHAsset,
        targetSize: CGSize,
        options: PHImageRequestOptions,
        resultHandler: @escaping ImageResultHandler
    ) -> PHImageRequestID {
        return PHImageManager.default().requestImage(
            for: asset,
            targetSize: targetSize,
            contentMode: .aspectFill,
            options: options,
            resultHandler: resultHandler
        )
    }
    
    @discardableResult
    static func requestImage(
        for asset: PHAsset,
        targetSize: CGSize,
        deliveryMode: PHImageRequestOptionsDeliveryMode = .opportunistic,
        resizeMode: PHImageRequestOptionsResizeMode,
        normalizedCropRect: CGRect = .zero,
        isNetworkAccessAllowed: Bool,
        progressHandler: PHAssetImageProgressHandler?,
        resultHandler: @escaping ImageResultHandler
    ) -> PHImageRequestID {
        let options = PHImageRequestOptions()
        options.deliveryMode = deliveryMode
        options.resizeMode = resizeMode
        options.normalizedCropRect = normalizedCropRect
        options.isNetworkAccessAllowed = isNetworkAccessAllowed
        options.progressHandler = progressHandler
        return requestImage(for: asset, targetSize: targetSize, options: options, resultHandler: resultHandler)
    }
    
    @discardableResult
    static func requestImage(
        for asset: PHAsset,
        targetSize: CGSize,
        deliveryMode: PHImageRequestOptionsDeliveryMode = .opportunistic,
        resizeMode: PHImageRequestOptionsResizeMode,
        normalizedCropRect: CGRect = .zero,
        iCloudHandler: ((PHImageRequestID) -> Void)? = nil,
        progressHandler: PHAssetImageProgressHandler? = nil,
        resultHandler: @escaping ImageResultHandler
    ) -> PHImageRequestID {
        requestImage(
            for: asset,
            targetSize: targetSize,
            deliveryMode: deliveryMode,
            resizeMode: resizeMode,
            normalizedCropRect: normalizedCropRect,
            isNetworkAccessAllowed: false,
            progressHandler: nil
        ) { image, info in
            DispatchQueue.main.async {
                guard let image = image else {
                    if let inICloud = info?.inICloud, inICloud {
                        let iCloudRequestID = self.requestImage(
                            for: asset,
                            targetSize: targetSize,
                            resizeMode: resizeMode,
                            isNetworkAccessAllowed: true,
                            progressHandler: progressHandler
                        ) { image, info in
                            DispatchQueue.main.async {
                                resultHandler(image, info)
                            }
                        }
                        iCloudHandler?(iCloudRequestID)
                    }else {
                        resultHandler(image, info)
                    }
                    return
                }
                resultHandler(image, info)
            }
        }
    }
}
