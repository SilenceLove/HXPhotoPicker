//
//  AssetError.swift
//  HXPhotoPicker
//
//  Created by Silence on 2024/4/6.
//  Copyright © 2024 Silence. All rights reserved.
//

import Foundation

public enum AssetError: Error {
    /// 写入文件失败
    case fileWriteFailed
    /// 导出失败
    case exportFailed(Error?)
    /// 无效的 Data
    case invalidData
    /// 无效的编辑数据
    case invalidEditedData
    /// phAsset为空
    case invalidPHAsset
    /// 网络地址为空
    case networkURLIsEmpty
    /// 本地地址为空
    case localURLIsEmpty
    /// 本地LocalLivePhoto为空
    case localLivePhotoIsEmpty
    /// 类型错误，例：本来是 .photo 却去获取 videoURL
    case typeError
    /// 从系统相册获取数据失败, [AnyHashable: Any]?: 系统获取失败的信息
    case requestFailed([AnyHashable: Any]?)
    /// 需要同步iCloud上的资源
    case needSyncICloud([AnyHashable: Any]?)
    /// 同步iCloud失败
    case syncICloudFailed([AnyHashable: Any]?)
    /// 指定地址存在其他文件，删除已存在的文件时发生错误
    case removeFileFailed(Error)
    /// PHAssetResource 为空
    case assetResourceIsEmpty
    /// PHAssetResource写入数据错误
    case assetResourceWriteDataFailed(Error)
    /// 导出livePhoto里的图片地址失败
    case exportLivePhotoImageURLFailed(Error)
    /// 导出livePhoto里的视频地址失败
    case exportLivePhotoVideoURLFailed(Error)
    /// 导出livePhoto里的地址失败（图片失败信息,视频失败信息）
    case exportLivePhotoURLFailed(Error, Error)
    /// 图片压缩失败
    case imageCompressionFailed
    /// 图片下载失败
    case imageDownloadFailed
    /// 视频下载失败
    case videoDownloadFailed
    /// 视频压缩失败
    case videoCompressionFailed
    /// 本地livePhoto取消写入
    case localLivePhotoCancelWrite
    /// 本地livePhoto图片写入失败
    case localLivePhotoWriteImageFailed
    /// 本地livePhoto视频写入失败
    case localLivePhotoWriteVideoFailed
    /// 本地livePhoto合成失败
    case localLivePhotoRequestFailed
    /// 获取失败-未知原因
    case failed
}

extension AssetError: LocalizedError, CustomStringConvertible {
    public var info: [AnyHashable: Any]? {
        switch self {
        case .requestFailed(let info):
            return info
        case .needSyncICloud(let info):
            return info
        case .syncICloudFailed(let info):
            return info
        default:
            return nil
        }
    }
    
    public var errorDescription: String? {
        switch self {
        case .fileWriteFailed:
            return "写入文件失败"
        case .exportFailed(let error):
            return "导出失败: \(String(describing: error))"
        case .invalidData:
            return "无效的 Data"
        case .invalidEditedData:
            return "无效的编辑数据"
        case .invalidPHAsset:
            return "phAsset为空"
        case .networkURLIsEmpty:
            return "网络地址为空"
        case .localURLIsEmpty:
            return "本地地址为空"
        case .localLivePhotoIsEmpty:
            return "本地LocalLivePhoto为空"
        case .typeError:
            return "类型错误，例：本来是 .photo 却去获取 videoURL"
        case .requestFailed(let info):
            return "从系统相册获取数据失败, 系统获取失败的信息: \(String(describing: info))"
        case .needSyncICloud(let info):
            return "需要同步iCloud上的资源: \(String(describing: info))"
        case .syncICloudFailed(let info):
            return "同步iCloud失败: \(String(describing: info))"
        case .removeFileFailed:
            return "指定地址存在其他文件，删除已存在的文件时发生错误"
        case .assetResourceIsEmpty:
            return "PHAssetResource 为空"
        case .assetResourceWriteDataFailed(let error):
            return "PHAssetResource写入数据错误: \(error)"
        case .exportLivePhotoImageURLFailed(let error):
            return "导出livePhoto里的图片地址失败: \(String(describing: error))"
        case .exportLivePhotoVideoURLFailed(let error):
            return "导出livePhoto里的视频地址失败: \(String(describing: error))"
        case .exportLivePhotoURLFailed(let imageError, let videoError):
            return "导出livePhoto里的地址失败（图片失败信息:" +
            String(describing: imageError) + ", 视频失败信息:" +
            String(describing: videoError)
        case .imageCompressionFailed:
            return "图片压缩失败"
        case .imageDownloadFailed:
            return "图片下载失败"
        case .videoDownloadFailed:
            return "视频下载失败"
        case .videoCompressionFailed:
            return "视频压缩失败"
        case .localLivePhotoCancelWrite:
            return "本地livePhoto取消写入"
        case .localLivePhotoWriteImageFailed:
            return "本地livePhoto图片写入失败"
        case .localLivePhotoWriteVideoFailed:
            return "本地livePhoto视频写入失败"
        case .localLivePhotoRequestFailed:
            return "本地livePhoto合成失败"
        case .failed:
            return "获取失败-未知原因"
        }
    }
    
    public var description: String {
        if let errorDescription = errorDescription {
            return errorDescription
        }
        return "nil"
    }
}
