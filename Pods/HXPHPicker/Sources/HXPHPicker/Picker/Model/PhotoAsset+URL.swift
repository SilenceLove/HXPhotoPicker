//
//  PhotoAsset+URL.swift
//  HXPHPicker
//
//  Created by Slience on 2021/7/19.
//

import UIKit
import AVFoundation

public extension PhotoAsset {
    
    typealias AssetURLCompletion = (Result<AssetURLResult, AssetError>) -> Void
    
    /// 获取url
    ///   - completion: 获取完成
    func getAssetURL(
        completion: @escaping AssetURLCompletion
    ) {
        if mediaType == .photo {
            if mediaSubType == .livePhoto {
                getLivePhotoURL(
                    completion: completion
                )
                return
            }
            getImageURL(
                completion: completion
            )
        }else {
            getVideoURL(
                completion: completion
            )
        }
    }
    
    /// 获取图片url
    ///   - completion: 获取完成
    func getImageURL(
        completion: @escaping AssetURLCompletion
    ) {
        #if canImport(Kingfisher)
        if isNetworkAsset {
            getNetworkImageURL(
                resultHandler: completion
            )
            return
        }
        #endif
        requestImageURL(
            resultHandler: completion
        )
    }
    
    /// 获取视频url
    /// - Parameters:
    ///   - exportPreset: 视频分辨率，不传获取的就是原始视频
    ///   - videoQuality: 视频质量[0-10]
    ///   - exportSession: 导出视频时对应的 AVAssetExportSession
    ///   - completion: 获取完成
    func getVideoURL(
        exportPreset: ExportPreset? = nil,
        videoQuality: Int = 6,
        exportSession: ((AVAssetExportSession) -> Void)? = nil,
        completion: @escaping AssetURLCompletion
    ) {
        if isNetworkAsset {
            getNetworkVideoURL(
                resultHandler: completion
            )
            return
        }
        requestVideoURL(
            exportPreset: exportPreset,
            videoQuality: videoQuality,
            exportSession: exportSession,
            resultHandler: completion
        )
    }
    
    /// 获取LivePhoto里的图片和视频URL
    /// - Parameter completion: 获取完成
    func getLivePhotoURL(
        completion: @escaping AssetURLCompletion
    ) {
        requestLivePhotoURL(
            completion: completion
        )
    }
}
