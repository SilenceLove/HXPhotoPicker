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
    
    func registerPhotoChangeObserver() {
        let status = AssetManager.authorizationStatus()
        if status == .notDetermined || status == .denied {
            return
        }
        if isCacheCameraAlbum {
            if didRegisterObserver {
                return
            }
            PHPhotoLibrary.shared().register(self)
            didRegisterObserver = true
        }else {
            if !didRegisterObserver {
                return
            }
            PHPhotoLibrary.shared().unregisterChangeObserver(self)
            cameraAlbumResult = nil
            cameraAlbumResultOptions = nil
            didRegisterObserver = false
        }
    }
    
    private var cameraAlbumLocalIdentifierSelectOptions: PickerAssetOptions? {
        let identifierType = UserDefaults.standard.integer(
            forKey: PhotoManager.CameraAlbumLocal.identifierType.rawValue
        )
        return PickerAssetOptions(rawValue: identifierType)
    }
    
    private var cameraAlbumLocalLanguage: String? {
        let language = UserDefaults.standard.string(
            forKey: PhotoManager.CameraAlbumLocal.language.rawValue
        )
        return language
    }
    
    private var cameraAlbumLocalIdentifier: String? {
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
        completion: (([PhotoAssetCollection]) -> Void)?
    ) {
        DispatchQueue.global().async {
            var assetCollectionsArray = [PhotoAssetCollection]()
            AssetManager.enumerateAllAlbums(
                filterInvalid: true,
                options: nil
            ) { (collection, index, stop) in
                if completion == nil {
                    stop.pointee = true
                    return
                }
                let assetCollection = PhotoAssetCollection(
                    collection: collection,
                    options: options
                )
                assetCollection.fetchResult()
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
                completion?(assetCollectionsArray)
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
        usingBlock: ((PhotoAssetCollection?, Bool, UnsafeMutablePointer<ObjCBool>) -> Void)?
    ) {
        AssetManager.enumerateAllAlbums(
            filterInvalid: true,
            options: nil
        ) { (collection, index, stop) in
            let assetCollection = PhotoAssetCollection(
                collection: collection,
                options: options
            )
            assetCollection.fetchResult()
            if showEmptyCollection == false && assetCollection.count == 0 {
                return
            }
            usingBlock?(assetCollection, collection.isCameraRoll, stop)
        }
        var result = ObjCBool(true)
        usingBlock?(nil, false, &result)
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
                collection = AssetManager.fetchCameraRollAlbum(options: nil)
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
            let assetCollection = PhotoAssetCollection(
                collection: collection,
                options: options
            )
            if let fetchResult = self.cameraAlbumResult,
               let options = self.cameraAlbumResultOptions,
               (options == selectOptions || (options.isPhoto && options.isVideo)) {
                assetCollection.changeResult(for: fetchResult)
            }else {
                assetCollection.fetchResult()
                if self.isCacheCameraAlbum {
                    self.cameraAlbumResult = assetCollection.result
                    self.cameraAlbumResultOptions = selectOptions
                }
            }
            assetCollection.isCameraRoll = true
            DispatchQueue.main.async {
                completion(assetCollection)
            }
        }
    }
}

extension PhotoManager: PHPhotoLibraryChangeObserver {
    public func photoLibraryDidChange(_ changeInstance: PHChange) {
        guard let fetchResult = cameraAlbumResult,
              let changeResult = changeInstance.changeDetails(for: fetchResult) else {
            return
        }
        let result = changeResult.fetchResultAfterChanges
        cameraAlbumResult = result
        PhotoManager.shared.firstLoadAssets = true
    }
}
