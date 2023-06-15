//
//  PhotoAssetCollection.swift
//  照片选择器-Swift
//
//  Created by Silence on 2019/7/3.
//  Copyright © 2019年 Silence. All rights reserved.
//

import UIKit
import Photos

open class PhotoAssetCollection: Equatable {
    
    /// 相册名称
    public var albumName: String?
    
    /// 相册里的资源数量
    public var count: Int = 0
    
    /// PHAsset 集合
    public var result: PHFetchResult<PHAsset>?
    
    /// 相册对象
    public var collection: PHAssetCollection?
    
    /// 获取 PHFetchResult 中的 PHAsset 时的选项
    public var options: PHFetchOptions?
    
    /// 是否选中
    public var isSelected: Bool = false
    
    /// 是否是相机胶卷
    public var isCameraRoll: Bool = false
    
    /// 真实的封面图片，如果不为nil就是封面
    var realCoverImage: UIImage?
    
    private var coverImage: UIImage?
    
    public init(
        collection: PHAssetCollection?,
        options: PHFetchOptions?
    ) {
        self.collection = collection
        self.options = options
    }
    
    public init(
        albumName: String?,
        coverImage: UIImage?
    ) {
        self.albumName = albumName
        self.coverImage = coverImage
    }
    
    public static func == (lhs: PhotoAssetCollection, rhs: PhotoAssetCollection) -> Bool {
        return lhs === rhs
    }
    
    /// 请求获取相册封面图片
    /// - Parameter completion: 会回调多次
    /// - Returns: 请求ID
    open func requestCoverImage(
        completion: ((UIImage?, PhotoAssetCollection, [AnyHashable: Any]?) -> Void)?
    ) -> PHImageRequestID? {
        if realCoverImage != nil {
            completion?(realCoverImage, self, nil)
            return nil
        }
        if let result = result, result.count > 0 {
            let asset = result.object(at: result.count - 1)
            return AssetManager.requestThumbnailImage(
                for: asset,
                targetWidth: 160
            ) { (image, info) in
                completion?(image, self, info)
            }
        }
        completion?(coverImage, self, nil)
        return nil
    }
    
    /// 枚举相册里的资源
    open func enumerateAssets(
        options opts: NSEnumerationOptions = .concurrent,
        usingBlock: ((PhotoAsset, Int, UnsafeMutablePointer<ObjCBool>) -> Void)?
    ) {
        if result == nil {
            fetchResult()
        }
        guard let result = result else {
            return
        }
        if opts == .reverse {
            result.enumerateObjects(
                options: opts
            ) { asset, index, stop in
                let photoAsset = PhotoAsset(asset: asset)
                usingBlock?(photoAsset, index, stop)
            }
        }else {
            result.enumerateObjects { asset, index, stop in
                let photoAsset = PhotoAsset(asset: asset)
                usingBlock?(photoAsset, index, stop)
            }
        }
    }
}

extension PhotoAssetCollection {
     
    func fetchResult() {
        guard let collection = collection  else {
            return
        }
        albumName = PhotoTools.transformAlbumName(for: collection)
        result = PHAsset.fetchAssets(in: collection, options: options)
        count = result?.count ?? 0
    }
    
    func changeResult(for result: PHFetchResult<PHAsset>) {
        self.result = result
        count = result.count
        if let collection = collection {
            albumName = PhotoTools.transformAlbumName(for: collection)
        }
    }
    
    func change(albumName: String?, coverImage: UIImage?) {
        self.albumName = albumName
        self.coverImage = coverImage
    }
}
