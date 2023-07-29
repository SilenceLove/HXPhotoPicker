//
//  SwiftPhotoAsset.swift
//  HXPhotoPickerExample
//
//  Created by Silence on 2023/6/15.
//  Copyright © 2023 洪欣. All rights reserved.
//

import UIKit
import HXPhotoPicker
import AVFoundation

class SwiftPhotoAsset: NSObject {
    
    let photoAsset: PhotoAsset
    
    init(_ photoAsset: PhotoAsset) {
        self.photoAsset = photoAsset
        
    }
    
    /// 获取image，视频为封面图片
    /// - Parameters:
    ///   - compressionQuality: 压缩参数 0-1
    ///   - completion: 获取完成
    @objc
    func getImage(
        compressionQuality: CGFloat = -1,
        completion: @escaping (UIImage?) -> Void
    ) {
        let quality: CGFloat? = compressionQuality == -1 ? nil : compressionQuality
        photoAsset.getImage(compressionQuality: quality, completion: completion)
    }
    
    /// 获取url
    /// - Parameters:
    ///   - compression: 压缩参数，nil - 原图
    ///   - completion: 获取完成
    @objc
    func getURL(
        compression: SwiftCompression? = nil,
        completion: @escaping (SwiftAssetURLResult?) -> Void
    ) {
        photoAsset.getURL(compression: compression?.toHX) { result in
            switch result {
            case .success(let urlResult):
                completion(urlResult.toOC)
            case .failure:
                completion(nil)
            }
        }
    }
    
    @objc
    func getAssetURL(
        compression: SwiftCompression? = nil,
        completion: @escaping (SwiftAssetURLResult?) -> Void
    ) {
        photoAsset.getAssetURL(compression: compression?.toHX) { result in
            switch result {
            case .success(let urlResult):
                completion(urlResult.toOC)
            case .failure:
                completion(nil)
            }
        }
    }
    
    /// 获取图片url
    /// - Parameters:
    ///   - compressionQuality: 压缩比例，不传就是原图。gif不会压缩
    ///   - completion: 获取完成
    @objc
    func getImageURL(
        compressionQuality: CGFloat = -1,
        completion: @escaping (SwiftAssetURLResult?) -> Void
    ) {
        let quality: CGFloat? = compressionQuality == -1 ? nil : compressionQuality
        photoAsset.getImageURL(compressionQuality: quality) { result in
            switch result {
            case .success(let urlResult):
                completion(urlResult.toOC)
            case .failure:
                completion(nil)
            }
        }
    }
    
    /// 获取视频url
    /// - Parameters:
    ///   - exportParameter: 导出参数，nil 为原始视频
    ///   - exportSession: 导出视频时对应的 AVAssetExportSession
    ///   - completion: 获取完成
    @objc
    func getVideoURL(
        exportParameter: SwiftVideoExportParameter? = nil,
        exportSession: ((AVAssetExportSession) -> Void)? = nil,
        completion: @escaping (SwiftAssetURLResult?) -> Void
    ) {
        photoAsset.getVideoURL(
            exportParameter: exportParameter?.toHX,
            exportSession: exportSession
        ) { result in
            switch result {
            case .success(let urlResult):
                completion(urlResult.toOC)
            case .failure:
                completion(nil)
            }
        }
    }
    
    /// 获取LivePhoto里的图片和视频URL
    /// - Parameters:
    ///   - compression: 压缩参数，nil - 原图
    ///   - completion: 获取完成
    @objc
    func getLivePhotoURL(
        compression: SwiftCompression? = nil,
        completion: @escaping (SwiftAssetURLResult?) -> Void
    ) {
        photoAsset.getLivePhotoURL(compression: compression?.toHX) { result in
            switch result {
            case .success(let urlResult):
                completion(urlResult.toOC)
            case .failure:
                completion(nil)
            }
        }
    }
}
