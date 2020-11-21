//
//  HXPHAssetCollection.swift
//  照片选择器-Swift
//
//  Created by 洪欣 on 2019/7/3.
//  Copyright © 2019年 洪欣. All rights reserved.
//

import UIKit
import Photos

class HXPHAssetCollection: NSObject {
    var albumName : String?
    var count : Int = 0
    var result : PHFetchResult<PHAsset>?
    var collection : PHAssetCollection?
    var options : PHFetchOptions?
    var coverAsset: PHAsset?
    private var coverImage: UIImage?
    
    init(collection: PHAssetCollection? , options: PHFetchOptions?) {
        super.init()
        self.collection = collection
        self.options = options
        fetchResult()
    }
    
    init(albumName: String?, coverImage: UIImage?) {
        super.init()
        self.albumName = albumName
        self.coverImage = coverImage
    }
    
    func fetchResult() {
        if collection == nil {
            return
        }
        albumName = HXPHTools.transformAlbumName(for: collection!)
        result = PHAsset.fetchAssets(in: collection!, options: options)
        count = result?.count ?? 0
        coverAsset = result?.firstObject
    }
    
    func changeResult(for result: PHFetchResult<PHAsset>) {
        self.result = result
        count = result.count
        coverAsset = result.firstObject
    }
    
    /// 请求获取相册封面图片
    /// - Parameter completion: 会回调多次
    /// - Returns: 请求ID
    func requestCoverImage(completion: ((UIImage?, HXPHAssetCollection, [AnyHashable : Any]?) -> Void)?) -> PHImageRequestID? {
        if coverAsset == nil {
            if completion != nil {
                completion!(coverImage, self, nil)
            }
            return nil
        }
        return HXPHAssetManager.requestThumbnailImage(for: coverAsset!, targetWidth: 160) { (image, info) in
            if completion != nil {
                completion!(image, self, info)
            }
        }
    }
    
    /// 枚举相册里的资源
    func enumerateAssets(usingBlock :@escaping (HXPHAsset)->()) {
        if result == nil {
            fetchResult()
        }
        result?.enumerateObjects({ (asset, index, stop) in
            let photoAsset = HXPHAsset.init(asset: asset)
            usingBlock(photoAsset)
        })
    }
}
