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
            if let displayName = Bundle.main.infoDictionary?["CFBundleDisplayName"] as? String {
                albumName = displayName.count > 0 ? displayName : "PhotoPicker"
            }else {
                albumName = Bundle.main.infoDictionary?[kCFBundleNameKey as String] as? String
            }
        }
        requestAuthorization { (status) in
            if status == .denied || status == .notDetermined || status == .restricted {
                completion(nil)
                return
            }
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
            }catch { }
            if let placeholder = placeholder,
               let phAsset = fetchAsset(
                withLocalIdentifier: placeholder.localIdentifier
               ) {
                completion(phAsset)
                if let albumName = albumName, let assetCollection = createAssetCollection(for: albumName) {
                    do {
                        try PHPhotoLibrary.shared().performChangesAndWait {
                            PHAssetCollectionChangeRequest(
                                for: assetCollection
                            )?.insertAssets(
                                [phAsset] as NSFastEnumeration,
                                at: IndexSet.init(integer: 0)
                            )
                        }
                    }catch {}
                }
            }else {
                completion(nil)
            }
        }
    }
    
    /// 保存图片到系统相册
    public static func saveSystemAlbum(
        forImage image: UIImage,
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
    
    private init() { }
}
