//
//  AssetManager+Asset.swift
//  HXPHPickerExample
//
//  Created by Slience on 2020/12/29.
//  Copyright © 2020 Silence. All rights reserved.
//

import UIKit
import Photos

public extension AssetManager {
    
    /// 根据 Asset 的本地唯一标识符获取 Asset
    /// - Parameter withLocalIdentifiers: 本地唯一标识符
    /// - Returns: 对应获取的 PHAsset
    static func fetchAssets(
        withLocalIdentifiers: [String]
    ) -> PHFetchResult<PHAsset> {
        PHAsset.fetchAssets(
            withLocalIdentifiers: withLocalIdentifiers,
            options: nil
        )
    }
    
    /// 根据 Asset 的本地唯一标识符获取 Asset
    /// - Parameter withLocalIdentifiers: 本地唯一标识符
    /// - Returns: 对应获取的 PHAsset
    static func fetchAsset
    (withLocalIdentifier: String
    ) -> PHAsset? {
        return fetchAssets(
            withLocalIdentifiers: [withLocalIdentifier]
        ).firstObject
    }
    
    /// 根据下载获取的信息判断资源是否存在iCloud上
    /// - Parameter info: 下载获取的信息
    static func assetIsInCloud(
        for info: [AnyHashable: Any]?
    ) -> Bool {
        if let info = info, info.inICloud {
            return true
        }
        return false
    }
    
    /// 判断资源是否取消了下载
    /// - Parameter info: 下载获取的信息
    static func assetCancelDownload(
        for info: [AnyHashable: Any]?
    ) -> Bool {
        if let info = info, info.isCancel {
            return true
        }
        return false
    }
    
    /// 判断资源是否下载错误
    /// - Parameter info: 下载获取的信息
    static func assetDownloadError(
        for info: [AnyHashable: Any]?
    ) -> Bool {
        if let info = info, info.isError {
            return true
        }
        return false
    }
    
    /// 判断资源下载得到的是否为退化的
    /// - Parameter info: 下载获取的信息
    static func assetIsDegraded(
        for info: [AnyHashable: Any]?
    ) -> Bool {
        if let info = info, info.isDegraded {
            return true
        }
        return false
    }
    
    /// 判断资源是否下载完成
    /// - Parameter info: 下载获取的信息
    static func assetDownloadFinined(
        for info: [AnyHashable: Any]?
    ) -> Bool {
        if let info = info, info.downloadFinined {
            return true
        }
        return false
    }
}
