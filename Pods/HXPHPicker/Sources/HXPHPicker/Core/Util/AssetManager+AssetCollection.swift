//
//  AssetManager+AssetCollection.swift
//  HXPHPickerExample
//
//  Created by Slience on 2020/12/29.
//  Copyright © 2020 Silence. All rights reserved.
//

import Photos
import UIKit

public extension AssetManager {
     
    /// 获取系统相册
    /// - Parameter options: 选型
    /// - Returns: 相册列表
    static func fetchSmartAlbums(
        options: PHFetchOptions?
    ) -> PHFetchResult<PHAssetCollection> {
        return PHAssetCollection.fetchAssetCollections(
            with: .smartAlbum,
            subtype: .any,
            options: options
        )
    }
    
    /// 获取用户创建的相册
    /// - Parameter options: 选项
    /// - Returns: 相册列表
    static func fetchUserAlbums(
        options: PHFetchOptions?
    ) -> PHFetchResult<PHAssetCollection> {
        return PHAssetCollection.fetchAssetCollections(
            with: .album,
            subtype: .any,
            options: options
        )
    }
    
    /// 获取所有相册
    /// - Parameters:
    ///   - filterInvalid: 过滤无效的相册
    ///   - options: 可选项
    ///   - usingBlock: 枚举每一个相册集合
    static func enumerateAllAlbums(
        filterInvalid: Bool,
        options: PHFetchOptions?,
        usingBlock :@escaping (PHAssetCollection, Int, UnsafeMutablePointer<ObjCBool>) -> Void
    ) {
        let smartAlbums = fetchSmartAlbums(options: nil)
        let userAlbums = fetchUserAlbums(options: nil)
        let albums = [smartAlbums, userAlbums]
        var stopAblums: Bool = false
        for result in albums {
            result.enumerateObjects { (collection, index, stop) in
                if !collection.isKind(of: PHAssetCollection.self) {
                    return
                }
                if filterInvalid {
                    if  collection.estimatedAssetCount <= 0 ||
                        collection.assetCollectionSubtype.rawValue == 205 ||
                        collection.assetCollectionSubtype.rawValue == 215 ||
                        collection.assetCollectionSubtype.rawValue == 212 ||
                        collection.assetCollectionSubtype.rawValue == 204 ||
                        collection.assetCollectionSubtype.rawValue == 1000000201 {
                        return
                    }
                }
                usingBlock(collection, index, stop)
                stopAblums = stop.pointee.boolValue
            }
            if stopAblums {
                break
            }
        }
    }
    
    /// 获取相机胶卷资源集合
    /// - Parameter options: 可选项
    /// - Returns: 相机胶卷集合
    static func fetchCameraRollAlbum(
        options: PHFetchOptions?
    ) -> PHAssetCollection? {
        let smartAlbums = fetchSmartAlbums(options: options)
        var assetCollection: PHAssetCollection?
        smartAlbums.enumerateObjects { (collection, index, stop) in
            if  !collection.isKind(of: PHAssetCollection.self) ||
                collection.estimatedAssetCount <= 0 {
                return
            }
            if collection.isCameraRoll {
                assetCollection = collection
                stop.initialize(to: true)
            }
        }
        return assetCollection
    }
    
    /// 创建相册
    /// - Parameter collectionName: 相册名
    /// - Returns: 对应的 PHAssetCollection 数据
    static func createAssetCollection(
        for collectionName: String
    ) -> PHAssetCollection? {
        let collections = PHAssetCollection.fetchAssetCollections(
            with: .album,
            subtype: .albumRegular,
            options: nil
        )
        var assetCollection: PHAssetCollection?
        collections.enumerateObjects { (collection, index, stop) in
            if collection.localizedTitle == collectionName {
                assetCollection = collection
                stop.pointee = true
            }
        }
        if assetCollection == nil {
            do {
                var createCollectionID: String?
                try PHPhotoLibrary.shared().performChangesAndWait {
                    createCollectionID = PHAssetCollectionChangeRequest.creationRequestForAssetCollection(
                        withTitle: collectionName
                    ).placeholderForCreatedAssetCollection.localIdentifier
                }
                if let createCollectionID = createCollectionID {
                    assetCollection = PHAssetCollection.fetchAssetCollections(
                        withLocalIdentifiers: [createCollectionID],
                        options: nil
                    ).firstObject
                }
            }catch {}
        }
        return assetCollection
    }
}
