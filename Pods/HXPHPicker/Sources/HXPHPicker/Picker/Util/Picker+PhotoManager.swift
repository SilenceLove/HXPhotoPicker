//
//  Picker+PhotoManager.swift
//  HXPHPickerExample
//
//  Created by Slience on 2020/12/29.
//  Copyright © 2020 Silence. All rights reserved.
//

import UIKit
import Photos
import PhotosUI

extension PhotoManager {
    struct AssociatedKeys {
        static var loadNetworkVideoMode: String = "loadNetworkVideoMode"
    }
    public var loadNetworkVideoMode: PhotoAsset.LoadNetworkVideoMode {
        get {
            objc_getAssociatedObject(
                self,
                &AssociatedKeys.loadNetworkVideoMode
            ) as? PhotoAsset.LoadNetworkVideoMode ?? .download
        }
        set {
            objc_setAssociatedObject(
                self,
                &AssociatedKeys.loadNetworkVideoMode,
                newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC
            )
        }
    }
    
    var cameraAlbumLocalIdentifierSelectOptions: PickerAssetOptions? {
        let identifierType = UserDefaults.standard.integer(
            forKey: PhotoManager.CameraAlbumLocal.identifierType.rawValue
        )
        return PickerAssetOptions(rawValue: identifierType)
    }
    
    var cameraAlbumLocalLanguage: String? {
        let language = UserDefaults.standard.string(
            forKey: PhotoManager.CameraAlbumLocal.language.rawValue
        )
        return language
    }
    
    var cameraAlbumLocalIdentifier: String? {
        let identifier = UserDefaults.standard.string(
            forKey: PhotoManager.CameraAlbumLocal.identifier.rawValue
        )
        return identifier
    }
    
    /// 获取所有资源集合
    /// - Parameters:
    ///   - showEmptyCollection: 显示空集合
    ///   - completion: 完成回调
    public func fetchAssetCollections(
        for options: PHFetchOptions,
        showEmptyCollection: Bool,
        completion: @escaping ([PhotoAssetCollection]) -> Void
    ) {
        DispatchQueue.global().async {
            var assetCollectionsArray = [PhotoAssetCollection]()
            AssetManager.enumerateAllAlbums(
                filterInvalid: true,
                options: nil
            ) { (collection) in
                let assetCollection = PhotoAssetCollection.init(collection: collection, options: options)
                if showEmptyCollection == false && assetCollection.count == 0 {
                    return
                }
                if collection.isCameraRoll {
                    assetCollectionsArray.insert(assetCollection, at: 0)
                }else {
                    assetCollectionsArray.append(assetCollection)
                }
            }
            DispatchQueue.main.async {
                completion(assetCollectionsArray)
            }
        }
    }
    
    /// 枚举每个相册资源，
    /// - Parameters:
    ///   - showEmptyCollection: 显示空集合
    ///   - usingBlock: PhotoAssetCollection 为nil则代表结束，Bool 是否为相机胶卷
    public func fetchAssetCollections(
        for options: PHFetchOptions,
        showEmptyCollection: Bool,
        usingBlock: @escaping (PhotoAssetCollection?, Bool) -> Void
    ) {
        AssetManager.enumerateAllAlbums(
            filterInvalid: true,
            options: nil
        ) { (collection) in
            let assetCollection = PhotoAssetCollection(
                collection: collection,
                options: options
            )
            if showEmptyCollection == false && assetCollection.count == 0 {
                return
            }
            usingBlock(assetCollection, collection.isCameraRoll)
        }
        usingBlock(nil, false)
    }
    
    /// 获取相机胶卷资源集合
    public func fetchCameraAssetCollection(
        for selectOptions: PickerAssetOptions,
        options: PHFetchOptions,
        completion: @escaping (PhotoAssetCollection) -> Void
    ) {
        DispatchQueue.global().async {
            var useLocalIdentifier = false
            let language = Locale.preferredLanguages.first
            if self.cameraAlbumLocalIdentifier != nil {
                let localOptions = self.cameraAlbumLocalIdentifierSelectOptions
                if  ((localOptions?.isPhoto == true && localOptions?.isVideo == true) ||
                        selectOptions == self.cameraAlbumLocalIdentifierSelectOptions) &&
                    self.cameraAlbumLocalLanguage == language {
                    useLocalIdentifier = true
                }
            }
            let collection: PHAssetCollection?
            if useLocalIdentifier == true {
                let identifiers: [String] = [self.cameraAlbumLocalIdentifier!]
                collection = PHAssetCollection.fetchAssetCollections(
                    withLocalIdentifiers: identifiers,
                    options: nil
                ).firstObject
            }else {
                collection = AssetManager.fetchCameraRollAlbum(options: nil)
                UserDefaults.standard.set(
                    collection?.localIdentifier,
                    forKey: PhotoManager.CameraAlbumLocal.identifier.rawValue
                )
                UserDefaults.standard.set(
                    selectOptions.rawValue,
                    forKey: PhotoManager.CameraAlbumLocal.identifierType.rawValue
                )
                UserDefaults.standard.set(language, forKey: PhotoManager.CameraAlbumLocal.language.rawValue)
            }
            let assetCollection = PhotoAssetCollection(
                collection: collection,
                options: options
            )
            assetCollection.isCameraRoll = true
            DispatchQueue.main.async {
                completion(assetCollection)
            }
        }
    }
}
