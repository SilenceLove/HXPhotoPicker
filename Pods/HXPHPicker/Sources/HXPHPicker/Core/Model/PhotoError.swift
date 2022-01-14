//
//  PhotoError.swift
//  HXPHPicker
//
//  Created by Slience on 2021/1/7.
//

import Foundation

public enum PhotoError: LocalizedError {
    
    public enum `Type` {
        case imageEmpty
        case videoEmpty
        case exportFailed
    }
    
    case error(type: Type, message: String)
}

extension PhotoError {
    public var errorDescription: String? {
        switch self {
        case let .error(_, message):
            return message
        }
    }
}

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
    case needSyncICloud
    /// 同步iCloud失败
    case syncICloudFailed([AnyHashable: Any]?)
    /// 指定地址存在其他文件，删除已存在的文件时发生错误
    case removeFileFailed
    /// PHAssetResource 为空
    case assetResourceIsEmpty
    /// PHAssetResource写入数据错误
    case assetResourceWriteDataFailed(Error)
    /// 导出livePhoto里的图片地址失败
    case exportLivePhotoImageURLFailed(Error?)
    /// 导出livePhoto里的视频地址失败
    case exportLivePhotoVideoURLFailed(Error?)
    /// 导出livePhoto里的地址失败（图片失败信息,视频失败信息）
    case exportLivePhotoURLFailed(Error?, Error?)
    /// 图片压缩失败
    case imageCompressionFailed
    /// 视频下载失败
    case videoDownloadFailed
    /// 本地livePhoto取消写入
    case localLivePhotoCancelWrite
    /// 本地livePhoto图片写入失败
    case localLivePhotoWriteImageFailed
    /// 本地livePhoto视频写入失败
    case localLivePhotoWriteVideoFailed
    /// 本地livePhoto合成失败
    case localLivePhotoRequestFailed
}
