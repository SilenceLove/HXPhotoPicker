//
//  HXPHAssetCollection.swift
//  照片选择器-Swift
//
//  Created by Silence on 2019/7/3.
//  Copyright © 2019年 Silence. All rights reserved.
//

import UIKit
import Photos

open class HXPHAssetCollection: NSObject {
    
    /// 相册名称
    public var albumName : String?
    /// 相册里的资源数量
    public var count : Int = 0
    
    public var result : PHFetchResult<PHAsset>?
    public var collection : PHAssetCollection?
    public var options : PHFetchOptions?
    public var isSelected: Bool = false
    public var isCameraRoll: Bool = false
    
    var coverAsset: PHAsset?
    var realCoverImage: UIImage?
    private var coverImage: UIImage?
    public init(collection: PHAssetCollection? , options: PHFetchOptions?) {
        super.init()
        self.collection = collection
        self.options = options
        fetchResult()
    }
    
    public init(albumName: String?, coverImage: UIImage?) {
        super.init()
        self.albumName = albumName
        self.coverImage = coverImage
    }
    
    public func fetchResult() {
        if collection == nil {
            return
        }
        albumName = HXPHTools.transformAlbumName(for: collection!)
        result = PHAsset.fetchAssets(in: collection!, options: options)
        count = result?.count ?? 0
    }
    
    public func changeResult(for result: PHFetchResult<PHAsset>) {
        self.result = result
        count = result.count
        if collection != nil {
            albumName = HXPHTools.transformAlbumName(for: collection!)
        }
    }
    
    public func fetchCoverAsset() {
        coverAsset = result?.lastObject
    }
    
    public func change(albumName: String?, coverImage: UIImage?) {
        self.albumName = albumName
        self.coverImage = coverImage
    }
    
    /// 请求获取相册封面图片
    /// - Parameter completion: 会回调多次
    /// - Returns: 请求ID
    public func requestCoverImage(completion: ((UIImage?, HXPHAssetCollection, [AnyHashable : Any]?) -> Void)?) -> PHImageRequestID? {
        if realCoverImage != nil {
            completion?(realCoverImage, self, nil)
            return nil
        }
        if coverAsset == nil {
            completion?(coverImage, self, nil)
            return nil
        }
        return HXPHAssetManager.requestThumbnailImage(for: coverAsset!, targetWidth: 160) { (image, info) in
            completion?(image, self, info)
        }
    }
    
    /// 枚举相册里的资源
    public func enumerateAssets(usingBlock :@escaping (HXPHAsset)->()) {
        if result == nil {
            fetchResult()
        }
        result?.enumerateObjects({ (asset, index, stop) in
            let photoAsset = HXPHAsset.init(asset: asset)
            usingBlock(photoAsset)
        })
    }
}
