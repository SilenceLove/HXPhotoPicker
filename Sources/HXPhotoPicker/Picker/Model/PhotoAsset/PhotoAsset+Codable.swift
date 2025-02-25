//
//  PhotoAsset+Codable.swift
//  HXPhotoPicker
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
        let mediaSubType: MediaSubType
        let networkVideoAsset: NetworkVideoAsset?
        let networkImageAsset: NetworkImageAsset?
        
        #if HXPICKER_ENABLE_EDITOR
        let editedResult: EditedResult?
        #endif
    }
    
    /// 编码
    /// - Returns: 编码之后的数据
    public func encode() throws -> Data {
        let simplify: Simplify
        #if HXPICKER_ENABLE_EDITOR
            simplify = Simplify(
                phLocalIdentifier: phAsset?.localIdentifier,
                localImageAsset: localImageAsset,
                localVideoAsset: localVideoAsset,
                localLivePhoto: localLivePhoto,
                mediaSubType: mediaSubType,
                networkVideoAsset: networkVideoAsset,
                networkImageAsset: networkImageAsset,
                editedResult: editedResult
            )
        #else
            simplify = Simplify(
                phLocalIdentifier: phAsset?.localIdentifier,
                localImageAsset: localImageAsset,
                localVideoAsset: localVideoAsset,
                localLivePhoto: localLivePhoto,
                mediaSubType: mediaSubType,
                networkVideoAsset: networkVideoAsset,
                networkImageAsset: networkImageAsset
            )
        #endif
        return try JSONEncoder().encode(simplify)
    }
    
    public func encodeData() -> Data? {
        do {
            return try encode()
        } catch {
            HXLog("PhotoAsset 编码失败: \(error)")
            return nil
        }
    }
    
    /// 解码
    /// - Parameter data: 之前编码得到的数据
    /// - Returns: 对应的 PhotoAsset 对象
    public static func decode(data: Data) throws -> PhotoAsset {
        var photoAsset: PhotoAsset?
        let decoder = JSONDecoder()
        let simplify = try decoder.decode(Simplify.self, from: data)
        if let phLocalIdentifier = simplify.phLocalIdentifier {
            if let phAsset = AssetManager.fetchAsset(with: phLocalIdentifier) {
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
            if let networkImageAsset = simplify.networkImageAsset {
                photoAsset = PhotoAsset(networkImageAsset: networkImageAsset)
            }
        }
        guard let photoAsset else {
            throw NSError(domain: "PhotoAsset为nil, 解码失败", code: 500)
        }
        photoAsset.mediaSubType = simplify.mediaSubType
        #if HXPICKER_ENABLE_EDITOR
        if let url = simplify.editedResult?.url,
           FileManager.default.fileExists(atPath: url.path) {
            photoAsset.editedResult = simplify.editedResult
        }
        #endif
        return photoAsset
    }
    
    public static func decodeData(data: Data) -> PhotoAsset? {
        do {
            return try decode(data: data)
        } catch {
            HXLog("PhotoAsset 解码失败: \(error)")
            return nil
        }
    }
}
