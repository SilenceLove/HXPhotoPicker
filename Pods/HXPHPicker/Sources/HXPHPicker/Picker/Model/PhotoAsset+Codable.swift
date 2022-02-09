//
//  PhotoAsset+Codable.swift
//  HXPHPicker
//
//  Created by Slience on 2021/7/27.
//

import UIKit

extension PhotoAsset {
    private struct Simplify: Codable {
        let phLocalIdentifier: String?
        let localImageAsset: LocalImageAsset?
        let localVideoAsset: LocalVideoAsset?
        let localLivePhoto: LocalLivePhotoAsset?
        let networkVideoAsset: NetworkVideoAsset?
        
        #if canImport(Kingfisher)
        let networkImageAsset: NetworkImageAsset?
        #endif
        
        #if HXPICKER_ENABLE_EDITOR
        let photoEdit: PhotoEditResult?
        let videoEdit: VideoEditResult?
        #endif
    }
    
    /// 编码
    /// - Returns: 编码之后的数据
    public func encode() -> Data? {
        let simplify: Simplify
        #if HXPICKER_ENABLE_EDITOR
            #if canImport(Kingfisher)
            simplify = Simplify(
                phLocalIdentifier: phAsset?.localIdentifier,
                localImageAsset: localImageAsset,
                localVideoAsset: localVideoAsset,
                localLivePhoto: localLivePhoto,
                networkVideoAsset: networkVideoAsset,
                networkImageAsset: networkImageAsset,
                photoEdit: photoEdit,
                videoEdit: videoEdit
            )
            #else
            simplify = Simplify(
                phLocalIdentifier: phAsset?.localIdentifier,
                localImageAsset: localImageAsset,
                localVideoAsset: localVideoAsset,
                localLivePhoto: localLivePhoto,
                networkVideoAsset: networkVideoAsset,
                photoEdit: photoEdit,
                videoEdit: videoEdit
            )
            #endif
        #else
            #if canImport(Kingfisher)
            simplify = Simplify(
                phLocalIdentifier: phAsset?.localIdentifier,
                localImageAsset: localImageAsset,
                localVideoAsset: localVideoAsset,
                localLivePhoto: localLivePhoto,
                networkVideoAsset: networkVideoAsset,
                networkImageAsset: networkImageAsset
            )
            #else
            simplify = Simplify(
                phLocalIdentifier: phAsset?.localIdentifier,
                localImageAsset: localImageAsset,
                localVideoAsset: localVideoAsset,
                localLivePhoto: localLivePhoto,
                networkVideoAsset: networkVideoAsset
            )
            #endif
        #endif
        let encoder = JSONEncoder()
        let data = try? encoder.encode(simplify)
        return data
    }
    
    /// 解码
    /// - Parameter data: 之前编码得到的数据
    /// - Returns: 对应的 PhotoAsset 对象
    public class func decoder(data: Data) -> PhotoAsset? {
        var photoAsset: PhotoAsset?
        do {
            let decoder = JSONDecoder()
            let simplify = try decoder.decode(Simplify.self, from: data)
            if let phLocalIdentifier = simplify.phLocalIdentifier {
                if let phAsset = AssetManager.fetchAsset(withLocalIdentifier: phLocalIdentifier) {
                    photoAsset = PhotoAsset(asset: phAsset)
                }
            }else if let localImageAsset = simplify.localImageAsset {
                photoAsset = PhotoAsset(localImageAsset: localImageAsset)
            }else if let localVideoAsset = simplify.localVideoAsset {
                photoAsset = PhotoAsset(localVideoAsset: localVideoAsset)
            }else if let localLivePhoto = simplify.localLivePhoto {
                photoAsset = PhotoAsset(localLivePhoto: localLivePhoto)
            }else if let networkVideoAsset = simplify.networkVideoAsset {
                photoAsset = PhotoAsset(networkVideoAsset: networkVideoAsset)
            }else {
                #if canImport(Kingfisher)
                if let networkImageAsset = simplify.networkImageAsset {
                    photoAsset = PhotoAsset(networkImageAsset: networkImageAsset)
                }
                #endif
            }
            #if HXPICKER_ENABLE_EDITOR
            if let ImageURL = simplify.photoEdit?.editedImageURL,
               FileManager.default.fileExists(atPath: ImageURL.path) {
                photoAsset?.photoEdit = simplify.photoEdit
            }
            if let videoURL = simplify.videoEdit?.editedURL,
               FileManager.default.fileExists(atPath: videoURL.path) {
                photoAsset?.videoEdit = simplify.videoEdit
            }
            #endif
        } catch  {
            print(error)
        }
        return photoAsset
    }
}
