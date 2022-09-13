//
//  AssetManager.swift
//  照片选择器-Swift
//
//  Created by Silence on 2020/11/9.
//  Copyright © 2020 Silence. All rights reserved.
//

import UIKit
import Photos

public struct AssetManager {
    
    /// 保存资源到系统相册
    /// - Parameters:
    ///   - asset: 需要保存的资源数据，UIImage / URL
    ///   - mediaType: 资源类型，image/video
    ///   - customAlbumName: 需要保存到自定义相册的名称，默认BundleName
    ///   - creationDate: 创建时间，默认当前时间
    ///   - location: 位置信息
    ///   - completion: PHAsset为空则保存失败
    public static func saveSystemAlbum(
        forAsset asset: Any,
        mediaType: PHAssetMediaType,
        customAlbumName: String? = nil,
        creationDate: Date = Date(),
        location: CLLocation? = nil,
        completion: @escaping (PHAsset?) -> Void
    ) {
        var albumName: String?
        if let customAlbumName = customAlbumName, customAlbumName.count > 0 {
            albumName = customAlbumName
        }else {
            albumName = displayName()
        }
        requestAuthorization {
            switch $0 {
            case .denied, .notDetermined, .restricted:
                completion(nil)
                return
            default:
                break
            }
            DispatchQueue.global().async {
                var placeholder: PHObjectPlaceholder?
                do {
                    try PHPhotoLibrary.shared().performChangesAndWait {
                        var creationRequest: PHAssetCreationRequest?
                        if asset is URL {
                            if mediaType == .image {
                                creationRequest = PHAssetCreationRequest.creationRequestForAssetFromImage(
                                    atFileURL: asset as! URL
                                )
                            }else if mediaType == .video {
                                creationRequest = PHAssetCreationRequest.creationRequestForAssetFromVideo(
                                    atFileURL: asset as! URL
                                )
                            }
                        }else if asset is UIImage {
                            creationRequest = PHAssetCreationRequest.creationRequestForAsset(
                                from: asset as! UIImage
                            )
                        }
                        creationRequest?.creationDate = creationDate
                        creationRequest?.location = location
                        placeholder = creationRequest?.placeholderForCreatedAsset
                    }
                    if let placeholder = placeholder,
                       let phAsset = self.fetchAsset(
                        withLocalIdentifier: placeholder.localIdentifier
                       ) {
                        DispatchQueue.main.async {
                            completion(phAsset)
                        }
                        if let albumName = albumName {
                            saveCustomAlbum(for: phAsset, albumName: albumName)
                        }
                    }else {
                        DispatchQueue.main.async {
                            completion(nil)
                        }
                    }
                } catch {
                    DispatchQueue.main.async {
                        completion(nil)
                    }
                }
            }
        }
    }
    
    /// 保存图片到系统相册
    public static func saveSystemAlbum(
        forImage image: Any,
        customAlbumName: String? = nil,
        completion: @escaping (PHAsset?) -> Void
    ) {
        saveSystemAlbum(
            forAsset: image,
            mediaType: .image,
            customAlbumName: customAlbumName,
            completion: completion
        )
    }
    
    /// 保存视频到系统相册
    public static func saveSystemAlbum(
        forVideoURL videoURL: URL,
        customAlbumName: String? = nil,
        completion: @escaping (PHAsset?) -> Void
    ) {
        saveSystemAlbum(
            forAsset: videoURL,
            mediaType: .video,
            customAlbumName: customAlbumName,
            completion: completion
        )
    }
    
    public static func saveLivePhotoToAlbum(
        imageURL: URL,
        videoURL: URL,
        customAlbumName: String? = nil,
        creationDate: Date = Date(),
        location: CLLocation? = nil,
        completion: @escaping (PHAsset?) -> Void
    ) {
        var albumName: String?
        if let customAlbumName = customAlbumName, customAlbumName.count > 0 {
            albumName = customAlbumName
        }else {
            albumName = displayName()
        }
        requestAuthorization {
            switch $0 {
            case .denied, .notDetermined, .restricted:
                completion(nil)
                return
            default:
                break
            }
            DispatchQueue.global().async {
                var placeholder: PHObjectPlaceholder?
                do {
                    try PHPhotoLibrary.shared().performChangesAndWait {
                        let creationRequest = PHAssetCreationRequest.forAsset()
                        creationRequest.addResource(with: .photo, fileURL: imageURL, options: nil)
                        creationRequest.addResource(with: .pairedVideo, fileURL: videoURL, options: nil)
                        creationRequest.creationDate = creationDate
                        creationRequest.location = location
                        placeholder = creationRequest.placeholderForCreatedAsset
                    }
                    if let placeholder = placeholder,
                       let phAsset = self.fetchAsset(
                        withLocalIdentifier: placeholder.localIdentifier
                       ) {
                        DispatchQueue.main.async {
                            completion(phAsset)
                        }
                        if let albumName = albumName {
                            saveCustomAlbum(for: phAsset, albumName: albumName)
                        }
                    }else {
                        DispatchQueue.main.async {
                            completion(nil)
                        }
                    }
                } catch {
                    DispatchQueue.main.async {
                        completion(nil)
                    }
                }
            }
        }
    }
    
    private static func displayName() -> String {
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
        if let assetCollection = createAssetCollection(for: albumName) {
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
    
    private init() { }
}
