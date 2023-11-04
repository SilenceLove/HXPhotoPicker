//
//  PhotoFetchAssetCollection.swift
//  HXPhotoPicker
//
//  Created by Silence on 2023/9/25.
//  Copyright © 2023 Silence. All rights reserved.
//

import UIKit
import Photos

public struct DefaultPhotoFetchAssetCollection: PhotoFetchAssetCollection { }

public protocol PhotoFetchAssetCollection {
    
    /// 枚举所有相册
    static func enumerateAllAlbums(
        options: PHFetchOptions?,
        usingBlock: @escaping (PHAssetCollection, Int, UnsafeMutablePointer<ObjCBool>) -> Void
    )
   
    /// 获取相机胶卷资源集合
    static func fetchCameraRollAlbum(options: PHFetchOptions?) -> PHAssetCollection?
    
    /// 获取所有相册的  `PhotoAssetCollection` 对象
    static func fetchAssetCollections(
        options: PHFetchOptions,
        usingBlock: @escaping (PhotoAssetCollection, Bool, UnsafeMutablePointer<ObjCBool>) -> Void
    )
    
    /// 获取所有相册的  `PhotoAssetCollection` 对象
    /// - Parameters:
    ///   - config: 配置
    ///   - localCount: 本地资源的数量
    ///   - coverImage: 本地资源的封面图片
    ///   - options: 获取 PHAssetCollection 里的 PHAsset 集合的选项
    static func fetchAssetCollections(
        _ config: PickerConfiguration,
        localCount: Int,
        coverImage: UIImage?,
        options: PHFetchOptions,
        usingBlock: @escaping (PhotoAssetCollection, UnsafeMutablePointer<ObjCBool>) -> Bool
    ) -> [PhotoAssetCollection]
    
    /// 获取相机胶卷相册的  `PhotoAssetCollection` 对象
    /// 打开选择器默认显示的相册
    static func fetchCameraAssetCollection(
        _ config: PickerConfiguration,
        options: PHFetchOptions
    ) -> PhotoAssetCollection?
}

public extension PhotoFetchAssetCollection {
    
    private static func fetchSmartAlbums(options: PHFetchOptions?) -> PHFetchResult<PHAssetCollection> {
        PHAssetCollection.fetchAssetCollections(
            with: .smartAlbum,
            subtype: .any,
            options: options
        )
    }
    
    private static func fetchUserAlbums(options: PHFetchOptions?) -> PHFetchResult<PHAssetCollection> {
        PHAssetCollection.fetchAssetCollections(
            with: .album,
            subtype: .any,
            options: options
        )
    }
    
    static func enumerateAllAlbums(
        options: PHFetchOptions?,
        usingBlock: @escaping (PHAssetCollection, Int, UnsafeMutablePointer<ObjCBool>) -> Void
    ) {
        let smartAlbums: PHFetchResult<PHAssetCollection> = fetchSmartAlbums(options: nil)
        let userAlbums: PHFetchResult<PHAssetCollection> = fetchUserAlbums(options: nil)
        let albums: [PHFetchResult<PHAssetCollection>] = [smartAlbums, userAlbums]
        var stopAblums: Bool = false
        for result in albums {
            result.enumerateObjects { (collection, index, stop) in
                if !collection.isKind(of: PHAssetCollection.self) {
                    return
                }
                if  collection.estimatedAssetCount <= 0 ||
                    collection.assetCollectionSubtype.rawValue == 205 ||
                    collection.assetCollectionSubtype.rawValue == 215 ||
                    collection.assetCollectionSubtype.rawValue == 212 ||
                    collection.assetCollectionSubtype.rawValue == 204 ||
                    collection.assetCollectionSubtype.rawValue == 1000000201 {
                    return
                }
                usingBlock(collection, index, stop)
                stopAblums = stop.pointee.boolValue
            }
            if stopAblums {
                break
            }
        }
    }
   
    static func fetchCameraRollAlbum(options: PHFetchOptions?) -> PHAssetCollection? {
        let smartAlbums: PHFetchResult<PHAssetCollection> = fetchSmartAlbums(options: options)
        var assetCollection: PHAssetCollection?
        smartAlbums.enumerateObjects { (collection, _, stop) in
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
    
    static func fetchAssetCollections(
        options: PHFetchOptions,
        usingBlock: @escaping (PhotoAssetCollection, Bool, UnsafeMutablePointer<ObjCBool>) -> Void
    ) {
        enumerateAllAlbums(options: nil) { collection, _, stop in
            let assetCollection = PhotoAssetCollection(
                collection: collection,
                options: options
            )
            assetCollection.fetchResult()
            if assetCollection.count == 0 {
                return
            }
            usingBlock(assetCollection, collection.isCameraRoll, stop)
        }
    }
    
    static func fetchAssetCollections(
        _ config: PickerConfiguration,
        localCount: Int,
        coverImage: UIImage?,
        options: PHFetchOptions,
        usingBlock: @escaping (PhotoAssetCollection, UnsafeMutablePointer<ObjCBool>) -> Bool
    ) -> [PhotoAssetCollection] {
        if !config.allowLoadPhotoLibrary {
            return []
        }
        if config.creationDate {
            options.sortDescriptors = [
                NSSortDescriptor(
                    key: "creationDate",
                    ascending: config.creationDate
                )
            ]
        }
        var assetCollections: [PhotoAssetCollection] = []
        fetchAssetCollections(
            options: options
        )  { assetCollection, isCameraRoll, stop in
            if !usingBlock(assetCollection, stop) {
                return
            }
            assetCollection.count += localCount
            if isCameraRoll {
                assetCollections.insert(assetCollection, at: 0)
            }else {
                assetCollections.append(assetCollection)
            }
        }
        if let collection = assetCollections.first {
            collection.count += localCount
            if let coverImage = coverImage {
                collection.realCoverImage = coverImage
            }
        }
        return assetCollections
    }
    
    static func fetchCameraAssetCollection(
        _ config: PickerConfiguration,
        options: PHFetchOptions
    ) -> PhotoAssetCollection? {
        if !config.allowLoadPhotoLibrary {
            return nil
        }
        if config.creationDate {
            options.sortDescriptors = [
                NSSortDescriptor(
                    key: "creationDate",
                    ascending: config.creationDate
                )
            ]
        }
        let selectOptions = config.selectOptions
        var useLocalIdentifier = false
        let language = Locale.preferredLanguages.first
        if let localOptions = self.cameraAlbumLocalIdentifierSelectOptions,
           let localLanguage = self.cameraAlbumLocalLanguage,
           localLanguage == language,
           self.cameraAlbumLocalIdentifier != nil {
            if (localOptions.isPhoto && localOptions.isVideo) ||
                selectOptions == localOptions {
                useLocalIdentifier = true
            }
        }
        var collection: PHAssetCollection?
        if let localIdentifier = self.cameraAlbumLocalIdentifier,
           useLocalIdentifier {
            let identifiers: [String] = [localIdentifier]
            collection = PHAssetCollection.fetchAssetCollections(
                withLocalIdentifiers: identifiers,
                options: nil
            ).firstObject
        }
        if collection == nil {
            collection = self.fetchCameraRollAlbum(options: nil)
            UserDefaults.standard.set(
                collection?.localIdentifier,
                forKey: PhotoManager.CameraAlbumLocal.identifier.rawValue
            )
            UserDefaults.standard.set(
                selectOptions.rawValue,
                forKey: PhotoManager.CameraAlbumLocal.identifierType.rawValue
            )
            UserDefaults.standard.set(
                language, forKey: PhotoManager.CameraAlbumLocal.language.rawValue
            )
        }
        guard let collection = collection else {
            return nil
        }
        let assetCollection = PhotoAssetCollection(
            collection: collection,
            options: options
        )
        if let fetchResult = PhotoManager.shared.cameraAlbumResult,
           let options = PhotoManager.shared.cameraAlbumResultOptions,
           (options == selectOptions || (options.isPhoto && options.isVideo)) {
            assetCollection.updateResult(for: fetchResult)
        }else {
            assetCollection.fetchResult()
            if PhotoManager.shared.isCacheCameraAlbum {
                PhotoManager.shared.cameraAlbumResult = assetCollection.result
                PhotoManager.shared.cameraAlbumResultOptions = selectOptions
            }
        }
        assetCollection.isCameraRoll = true
        return assetCollection
    }
    
    private static var cameraAlbumLocalIdentifierSelectOptions: PickerAssetOptions? {
        let identifierType = UserDefaults.standard.integer(
            forKey: PhotoManager.CameraAlbumLocal.identifierType.rawValue
        )
        return PickerAssetOptions(rawValue: identifierType)
    }
    
    private static var cameraAlbumLocalLanguage: String? {
        let language = UserDefaults.standard.string(
            forKey: PhotoManager.CameraAlbumLocal.language.rawValue
        )
        return language
    }
    
    private static var cameraAlbumLocalIdentifier: String? {
        let identifier = UserDefaults.standard.string(
            forKey: PhotoManager.CameraAlbumLocal.identifier.rawValue
        )
        return identifier
    }
}
