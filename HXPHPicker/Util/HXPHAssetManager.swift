//
//  HXPHAssetManager.swift
//  照片选择器-Swift
//
//  Created by Silence on 2020/11/9.
//  Copyright © 2020 Silence. All rights reserved.
//

import UIKit
import Photos

public class HXPHAssetManager: NSObject {
    
    /// 保存资源到系统相册
    /// - Parameters:
    ///   - asset: 需要保存的资源数据，UIImage / URL
    ///   - mediaType: 资源类型
    ///   - customAlbumName: 需要保存到自定义相册的名称，默认BundleName
    ///   - creationDate: 创建时间，默认当前时间
    ///   - location: 位置信息
    ///   - completion: PHAsset为空则保存失败
    public class func saveSystemAlbum(forAsset asset: Any, mediaType: HXPHPicker.Asset.MediaType, customAlbumName: String?, creationDate: Date?, location: CLLocation?, completion: @escaping (PHAsset?) -> Void) {
        var albumName: String?
        if let customAlbumName = customAlbumName {
            albumName = customAlbumName
        }else {
            albumName = Bundle.main.infoDictionary?[kCFBundleNameKey as String] as? String
        }
        requestAuthorization { (status) in
            if status == .denied || status == .notDetermined || status == .restricted {
                completion(nil)
                return
            }
            do {
                var placeholder: PHObjectPlaceholder?
                try PHPhotoLibrary.shared().performChangesAndWait {
                    var creationRequest: PHAssetCreationRequest? = nil
                    if asset is URL {
                        if mediaType == .photo {
                            creationRequest = PHAssetCreationRequest.creationRequestForAssetFromImage(atFileURL: asset as! URL)
                        }else if mediaType == .video {
                            creationRequest = PHAssetCreationRequest.creationRequestForAssetFromVideo(atFileURL: asset as! URL)
                        }
                    }else if asset is UIImage {
                        creationRequest = PHAssetCreationRequest.creationRequestForAsset(from: asset as! UIImage)
                    }
                    if let creationDate = creationDate {
                        creationRequest?.creationDate = creationDate
                    }else {
                        creationRequest?.creationDate = Date.init()
                    }
                    creationRequest?.location = location
                    placeholder = creationRequest?.placeholderForCreatedAsset
                }
                if let placeholder = placeholder, let phAsset = fetchAsset(withLocalIdentifier: placeholder.localIdentifier) {
                    completion(phAsset)
                    if let albumName = albumName, let assetCollection = createAssetCollection(for: albumName) {
                        do {try PHPhotoLibrary.shared().performChangesAndWait {
                            PHAssetCollectionChangeRequest.init(for: assetCollection)?.insertAssets([phAsset] as NSFastEnumeration, at: IndexSet.init(integer: 0))
                        }}catch{}
                    }
                }else {
                    completion(nil)
                }
            }catch {
                completion(nil)
            }
        }
    }
    
    /// 保存图片到系统相册
    public class func saveSystemAlbum(forImage image: UIImage, customAlbumName: String?, completion: @escaping (PHAsset?) -> Void) {
        saveSystemAlbum(forAsset: image, mediaType: .photo, customAlbumName: nil, creationDate: nil, location: nil, completion: completion)
    }
    
    /// 保存视频到系统相册
    public class func saveSystemAlbum(forVideoURL videoURL: URL, customAlbumName: String?, completion: @escaping (PHAsset?) -> Void) {
        saveSystemAlbum(forAsset: videoURL, mediaType: .video, customAlbumName: nil, creationDate: nil, location: nil, completion: completion)
    }
    
}
