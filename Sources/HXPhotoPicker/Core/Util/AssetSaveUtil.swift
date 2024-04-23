//
//  AssetSaveUtil.swift
//  HXPhotoPicker
//
//  Created by Silence on 2024/3/25.
//  Copyright © 2024 Silence. All rights reserved.
//

import UIKit
import Photos

public struct AssetSaveUtil {
    
    public enum SaveType {
        case image(UIImage)
        case imageURL(URL)
        case videoURL(URL)
        case livePhoto(imageURL: URL, videoURL: URL)
    }

    public enum SaveError: Error {
        case notDetermined
        case phAssetIsNull
        case systemError(Error)
    }
    
    public enum AlbumType {
        /// 只保存到`所有相册`，不创建新相册
        case none
        
        // 保存到指定名称的相册，如果相册不存在会先创建
        /// 项目名称
        case displayName
        /// 指定相册名称
        case custom(String)
    }
    
    /// 保存资源到系统相册
    /// - Parameters:
    ///   - type: 保存类型
    ///   - albumType: 需要保存到自定义相册的类型
    ///   - creationDate: 创建时间，默认当前时间
    ///   - location: 位置信息
    @available(iOS 13.0.0, *)
    @discardableResult
    public static func save(
        type: SaveType,
        albumType: AlbumType = .displayName,
        creationDate: Date = .init(),
        location: CLLocation? = nil
    ) async throws -> PHAsset {
        try await withCheckedThrowingContinuation { continuation in
            save(
                type: type,
                albumType: albumType,
                creationDate: creationDate,
                location: location
            ) { result in
                switch result {
                case .success(let phAsset):
                    continuation.resume(returning: phAsset)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    /// 保存资源到系统相册
    /// - Parameters:
    ///   - type: 保存类型
    ///   - albumType: 需要保存到自定义相册的类型   
    ///   - creationDate: 创建时间，默认当前时间
    ///   - location: 位置信息
    ///   - completion: 保存之后的结果
    public static func save(
        type: SaveType,
        albumType: AlbumType = .displayName,
        creationDate: Date = .init(),
        location: CLLocation? = nil,
        completion: @escaping (Result<PHAsset, SaveError>) -> Void
    ) {
        AssetPermissionsUtil.requestAuthorization {
            switch $0 {
            case .denied, .notDetermined, .restricted:
                completion(.failure(SaveError.notDetermined))
                return
            default:
                break
            }
            DispatchQueue.global().async {
                var placeholder: PHObjectPlaceholder?
                do {
                    try PHPhotoLibrary.shared().performChangesAndWait {
                        var creationRequest: PHAssetCreationRequest?
                        switch type {
                        case .image(let image):
                            creationRequest = PHAssetCreationRequest.creationRequestForAsset(
                                from: image
                            )
                        case .imageURL(let url):
                            creationRequest = PHAssetCreationRequest.creationRequestForAssetFromImage(
                                atFileURL: url
                            )
                        case .videoURL(let url):
                            creationRequest = PHAssetCreationRequest.creationRequestForAssetFromVideo(
                                atFileURL: url
                            )
                        case .livePhoto(let imageURL, let videoURL):
                            creationRequest = PHAssetCreationRequest.forAsset()
                            creationRequest?.addResource(with: .photo, fileURL: imageURL, options: nil)
                            creationRequest?.addResource(with: .pairedVideo, fileURL: videoURL, options: nil)
                        }
                        creationRequest?.creationDate = creationDate
                        creationRequest?.location = location
                        placeholder = creationRequest?.placeholderForCreatedAsset
                    }
                    
                    if let placeholder = placeholder,
                       let phAsset = PHAsset.fetchAssets(
                        withLocalIdentifiers: [placeholder.localIdentifier],
                        options: nil
                       ).firstObject {
                        DispatchQueue.main.async {
                            completion(.success(phAsset))
                        }
                        switch albumType {
                        case .none:
                            break
                        case .displayName:
                            saveCustomAlbum(for: phAsset, albumName: displayName)
                        case .custom(let albumName):
                            saveCustomAlbum(for: phAsset, albumName: albumName)
                        }
                    }else {
                        DispatchQueue.main.async {
                            completion(.failure(SaveError.phAssetIsNull))
                        }
                    }
                } catch {
                    DispatchQueue.main.async {
                        completion(.failure(SaveError.systemError(error)))
                    }
                }
            }
        }
    }
    
    public static func createAssetCollection(for collectionName: String) -> PHAssetCollection? {
        let collections = PHAssetCollection.fetchAssetCollections(
            with: .album,
            subtype: .albumRegular,
            options: nil
        )
        var assetCollection: PHAssetCollection?
        collections.enumerateObjects { (collection, _, stop) in
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
            }catch {
                
            }
        }
        return assetCollection
    }
    
    private static var displayName: String {
        if let displayName = Bundle.main.infoDictionary?["CFBundleDisplayName"] as? String {
            return displayName.count > 0 ? displayName : "PhotoPicker"
        }else if let bundleName = Bundle.main.infoDictionary?[kCFBundleNameKey as String] as? String {
            return bundleName.count > 0 ? bundleName : "PhotoPicker"
        }else {
            return "PhotoPicker"
        }
    }
    
    private static func saveCustomAlbum(
        for asset: PHAsset,
        albumName: String
    ) {
        guard let assetCollection = createAssetCollection(for: albumName) else {
            return
        }
        try? PHPhotoLibrary.shared().performChangesAndWait {
            PHAssetCollectionChangeRequest(
                for: assetCollection
            )?.insertAssets(
                [asset] as NSFastEnumeration,
                at: IndexSet.init(integer: 0)
            )
        }
    }
}
