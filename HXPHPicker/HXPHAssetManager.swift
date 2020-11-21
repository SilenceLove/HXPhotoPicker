//
//  HXPHAssetManager.swift
//  照片选择器-Swift
//
//  Created by 洪欣 on 2020/11/9.
//  Copyright © 2020 洪欣. All rights reserved.
//

import UIKit
import Photos

class HXPHAssetManager: NSObject {
    
    /// 获取当前相册权限状态
    /// - Returns: 权限状态
    class func authorizationStatus() -> PHAuthorizationStatus {
        let status : PHAuthorizationStatus;
        if #available(iOS 14, *) {
            status = PHPhotoLibrary.authorizationStatus(for: PHAccessLevel.readWrite)
        } else {
            // Fallback on earlier versions
            status = PHPhotoLibrary.authorizationStatus();
        }
        return status;
    }
    
    class func authorizationStatusIsLimited() -> Bool{
        if #available(iOS 14, *) {
            if authorizationStatus() == PHAuthorizationStatus.limited {
                return true
            }
        }
        return false
    }
    
    /// 请求获取相册权限
    /// - Parameters:
    ///   - handler: 请求权限完成
    class func requestAuthorization(with handler : @escaping (PHAuthorizationStatus) -> ()) {
        let status = authorizationStatus()
        if status == PHAuthorizationStatus.notDetermined {
            if #available(iOS 14, *) {
                PHPhotoLibrary.requestAuthorization(for: PHAccessLevel.readWrite) { (authorizationStatus) in
                    DispatchQueue.main.async {
                        handler(authorizationStatus)
                    }
                }
            } else {
                PHPhotoLibrary.requestAuthorization { (authorizationStatus) in
                    DispatchQueue.main.async {
                        handler(authorizationStatus)
                    }
                }
            }
        }else {
            handler(status)
        }
    }
    
    /// 获取系统相册
    /// - Parameter options: 选型
    /// - Returns: 相册列表
    class func fetchSmartAlbums(options : PHFetchOptions?) -> PHFetchResult<PHAssetCollection> {
        return PHAssetCollection.fetchAssetCollections(with: PHAssetCollectionType.smartAlbum, subtype: PHAssetCollectionSubtype.any, options: options)
    }
    
    /// 获取用户创建的相册
    /// - Parameter options: 选项
    /// - Returns: 相册列表
    class func fetchUserAlbums(options : PHFetchOptions?) -> PHFetchResult<PHAssetCollection> {
        return PHAssetCollection.fetchAssetCollections(with: PHAssetCollectionType.album, subtype: PHAssetCollectionSubtype.any, options: options)
    }
    
    
    /// 获取所有相册
    /// - Parameters:
    ///   - filterInvalid: 过滤无效的相册
    ///   - options: 可选项
    ///   - usingBlock: 枚举每一个相册集合
    class func enumerateAllAlbums(filterInvalid: Bool, options : PHFetchOptions?, usingBlock :@escaping (PHAssetCollection)->()) {
        let smartAlbums = fetchSmartAlbums(options: nil)
        let userAlbums = fetchUserAlbums(options: nil)
        let albums = [smartAlbums, userAlbums]
        for result in albums {
            result.enumerateObjects { (collection, index, stop) in
                if !collection.isKind(of: PHAssetCollection.self) {
                    return;
                }
                if filterInvalid {
                    if  collection.estimatedAssetCount <= 0 ||
                        collection.assetCollectionSubtype.rawValue == 205 ||
                        collection.assetCollectionSubtype.rawValue == 215 ||
                        collection.assetCollectionSubtype.rawValue == 212 ||
                        collection.assetCollectionSubtype.rawValue == 204 ||
                        collection.assetCollectionSubtype.rawValue == 1000000201 {
                        return;
                    }
                }
                usingBlock(collection)
            }
        }
    }
    
    /// 获取相机胶卷资源集合
    /// - Parameter options: 可选项
    /// - Returns: 相机胶卷集合
    class func fetchCameraRollAlbum(options: PHFetchOptions?) -> PHAssetCollection? {
        let smartAlbums = fetchSmartAlbums(options: options)
        var assetCollection : PHAssetCollection?
        smartAlbums.enumerateObjects { (collection, index, stop) in
            if  !collection.isKind(of: PHAssetCollection.self) ||
                collection.estimatedAssetCount <= 0 {
                return
            }
            if collectionIsCameraRollAlbum(collection: collection) {
                assetCollection = collection
                stop.initialize(to: true)
            }
        }
        return assetCollection
    }
    
    /// 判断是否是相机胶卷
    /// - Parameter collection: 相机胶卷集合
    class func collectionIsCameraRollAlbum(collection: PHAssetCollection?) -> Bool {
        var versionStr = UIDevice.current.systemVersion.replacingOccurrences(of: ".", with: "")
        if versionStr.count <= 1 {
            versionStr.append("00")
        }else if versionStr.count <= 2 {
            versionStr.append("0")
        }
        let version = Int(versionStr) ?? 0
        if version >= 800 && version <= 802  {
            return collection?.assetCollectionSubtype == PHAssetCollectionSubtype.smartAlbumRecentlyAdded
        }else {
            return collection?.assetCollectionSubtype == PHAssetCollectionSubtype.smartAlbumUserLibrary
        }
    }
    
    /// 判断是否是动图
    /// - Parameter asset: 需要判断的资源
    /// - Returns: 是否
    class func assetIsAnimated(asset: PHAsset) -> Bool {
        var isAnimated : Bool = false
        let fileName = asset.value(forKey: "filename") as? String
        if fileName != nil {
            isAnimated = fileName!.hasSuffix("GIF")
        }
        if #available(iOS 11, *) {
            if asset.playbackStyle == PHAsset.PlaybackStyle.imageAnimated {
                isAnimated = true
            }
        }
        return isAnimated
    }
    
    /// 判断否是LivePhoto
    /// - Parameter asset: 需要判断的资源
    /// - Returns: 是否
    class func assetIsLivePhoto(asset: PHAsset) -> Bool {
        var isLivePhoto : Bool = false
        if #available(iOS 9.1, *) {
            isLivePhoto = asset.mediaSubtypes == PHAssetMediaSubtype.photoLive
            if #available(iOS 11, *) {
                if asset.playbackStyle == PHAsset.PlaybackStyle.livePhoto {
                    isLivePhoto = true
                }
            }
        }
        return isLivePhoto
    }
    
    private class func transformTargetWidthToSize(targetWidth: CGFloat, asset: PHAsset) -> CGSize {
        let scale:CGFloat = 0.8
        let aspectRatio = CGFloat(asset.pixelWidth) / CGFloat(asset.pixelHeight)
        var width = targetWidth
        if asset.pixelWidth < Int(targetWidth) {
            width *= 0.5
        }
        var height = width / aspectRatio
        let maxHeight = UIScreen.main.bounds.size.height
        if height > maxHeight {
            width = maxHeight / height * width * scale
            height = maxHeight * scale
        }
        if height < targetWidth && width >= targetWidth {
            width = targetWidth / height * width * scale
            height = targetWidth * scale
        }
        return CGSize.init(width: width, height: height)
    }
    
    /// 请求image
    /// - Parameters:
    ///   - asset: 资源对象
    ///   - targetSize: 指定大小
    ///   - options: 可选项
    ///   - resultHandler: 回调
    /// - Returns: 请求ID
    class func requestImage(for asset: PHAsset, targetSize: CGSize, options: PHImageRequestOptions, resultHandler: @escaping (UIImage?, [AnyHashable : Any]?) -> Void) -> PHImageRequestID {
        return PHImageManager.default().requestImage(for: asset, targetSize: targetSize, contentMode: PHImageContentMode.aspectFill, options: options, resultHandler: resultHandler)
    }
    
    /// 请求获取缩略图
    /// - Parameters:
    ///   - asset: 资源对象
    ///   - targetWidth: 获取的图片大小
    ///   - completion: 完成
    /// - Returns: 请求ID
    class func requestThumbnailImage(for asset: PHAsset, targetWidth: CGFloat, completion: ((UIImage?, [AnyHashable : Any]?) -> ())?) -> PHImageRequestID {
        let options = PHImageRequestOptions.init()
        options.resizeMode = PHImageRequestOptionsResizeMode.fast
        return requestImage(for: asset, targetSize: transformTargetWidthToSize(targetWidth: targetWidth, asset: asset), options: options) { (image, info) in
            if completion != nil {
                completion!(image, info)
            }
        }
    }
    
    class func requestImageData(for asset: PHAsset, options: PHImageRequestOptions, resultHandler: @escaping (Data?, String?, UIImage.Orientation, [AnyHashable : Any]?) -> Void) -> PHImageRequestID {
        if #available(iOS 13, *) {
            return PHImageManager.default().requestImageDataAndOrientation(for: asset, options: options) { (imageData, dataUTI, imageOrientation, info) in
                var sureOrientation : UIImage.Orientation;
                if (imageOrientation == CGImagePropertyOrientation.up) {
                    sureOrientation = UIImage.Orientation.up;
                } else if (imageOrientation == CGImagePropertyOrientation.upMirrored) {
                    sureOrientation = UIImage.Orientation.upMirrored;
                } else if (imageOrientation == CGImagePropertyOrientation.down) {
                    sureOrientation = UIImage.Orientation.down;
                } else if (imageOrientation == CGImagePropertyOrientation.downMirrored) {
                    sureOrientation = UIImage.Orientation.downMirrored;
                } else if (imageOrientation == CGImagePropertyOrientation.left) {
                    sureOrientation = UIImage.Orientation.left;
                } else if (imageOrientation == CGImagePropertyOrientation.leftMirrored) {
                    sureOrientation = UIImage.Orientation.leftMirrored;
                } else if (imageOrientation == CGImagePropertyOrientation.right) {
                    sureOrientation = UIImage.Orientation.right;
                } else if (imageOrientation == CGImagePropertyOrientation.rightMirrored) {
                    sureOrientation = UIImage.Orientation.rightMirrored;
                } else {
                    sureOrientation = UIImage.Orientation.up;
                }
                resultHandler(imageData, dataUTI, sureOrientation, info)
            }
        } else {
            // Fallback on earlier versions
            return PHImageManager.default().requestImageData(for: asset, options: options, resultHandler: resultHandler)
        }
    }
    
    class func requestImageData(for asset: PHAsset, version: PHImageRequestOptionsVersion, isNetworkAccessAllowed: Bool, progressHandler: @escaping PHAssetImageProgressHandler, resultHandler: @escaping (Data?, String?, UIImage.Orientation, [AnyHashable : Any]?) -> Void) -> PHImageRequestID {
        let options = PHImageRequestOptions.init()
        options.version = version
        options.resizeMode = PHImageRequestOptionsResizeMode.fast
        options.isNetworkAccessAllowed = isNetworkAccessAllowed
        options.progressHandler = progressHandler
        return requestImageData(for: asset, options: options, resultHandler: resultHandler)
    }
    
    /// 请求imageData，如果资源在iCloud上会自动请求下载iCloud上的资源
    /// - Parameters:
    ///   - asset: 资源
    ///   - version: 请求的版本
    ///   - iCloudHandler: 如果资源在iCloud上，下载之前回先回调出请求ID
    ///   - progressHandler: 处理进度
    ///   - resultHandler: 处理结果
    /// - Returns: 请求ID
    class func requestImageData(for asset: PHAsset, version: PHImageRequestOptionsVersion, iCloudHandler: @escaping (PHImageRequestID) -> Void, progressHandler: @escaping PHAssetImageProgressHandler, resultHandler: @escaping (Data?, String?, UIImage.Orientation, [AnyHashable : Any]?, Bool) -> Void) -> PHImageRequestID {
        return requestImageData(for: asset, version: version, isNetworkAccessAllowed: false, progressHandler: progressHandler) { (data, dataUTI, imageOrientation, info) in
            if self.assetDownloadFinined(for: info) {
                resultHandler(data, dataUTI, imageOrientation, info, true)
            }else {
                if self.assetIsInCloud(for: info) {
                    let iCloudRequestID = self.requestImageData(for: asset, version: version, isNetworkAccessAllowed: true, progressHandler: progressHandler, resultHandler: { (data, dataUTI, imageOrientation, info) in
                        resultHandler(data, dataUTI, imageOrientation, info, self.assetDownloadFinined(for: info))
                    })
                    iCloudHandler(iCloudRequestID)
                }else {
                    resultHandler(data, dataUTI, imageOrientation, info, false)
                }
            }
        }
    }
    
    @available(iOS 9.1, *)
    class func requestLivePhoto(for asset: PHAsset, targetSize: CGSize, options: PHLivePhotoRequestOptions, resultHandler: @escaping (PHLivePhoto?, [AnyHashable : Any]?) -> Void) -> PHImageRequestID {
        return PHImageManager.default().requestLivePhoto(for: asset, targetSize: targetSize, contentMode: PHImageContentMode.aspectFill, options: options, resultHandler: resultHandler)
    }
    @available(iOS 9.1, *)
    class func requestLivePhoto(for asset: PHAsset, targetSize: CGSize, isNetworkAccessAllowed: Bool, progressHandler: @escaping PHAssetImageProgressHandler, resultHandler: @escaping (PHLivePhoto?, [AnyHashable : Any]?) -> Void) -> PHImageRequestID {
        let options = PHLivePhotoRequestOptions.init()
        options.isNetworkAccessAllowed = isNetworkAccessAllowed
        options.progressHandler = progressHandler
        return requestLivePhoto(for: asset, targetSize: targetSize, options: options, resultHandler: resultHandler)
    }
    
    /// 请求LivePhoto，如果资源在iCloud上会自动请求下载iCloud上的资源
    /// - Parameters:
    ///   - asset: 资源
    ///   - targetSize: 请求的目标大小
    ///   - iCloudHandler: 如果资源在iCloud上，下载之前回先回调出请求ID
    ///   - progressHandler: 处理进度
    ///   - resultHandler: 处理结果
    /// - Returns: 请求ID
    @available(iOS 9.1, *)
    class func requestLivePhoto(for asset: PHAsset, targetSize: CGSize, iCloudHandler: @escaping (PHImageRequestID) -> Void, progressHandler: @escaping PHAssetImageProgressHandler, resultHandler: @escaping (PHLivePhoto?, [AnyHashable : Any]?, Bool) -> Void) -> PHImageRequestID {
        return requestLivePhoto(for: asset, targetSize: targetSize, isNetworkAccessAllowed: false, progressHandler: progressHandler) { (livePhoto, info) in
            if self.assetDownloadFinined(for: info) {
                resultHandler(livePhoto, info, true)
            }else {
                if self.assetIsInCloud(for: info) {
                    let iCloudRequestID = self.requestLivePhoto(for: asset, targetSize: targetSize, isNetworkAccessAllowed: true, progressHandler: progressHandler) { (livePhoto, info) in
                        if self.assetDownloadFinined(for: info) {
                            resultHandler(livePhoto, info, true)
                        }else {
                            resultHandler(livePhoto, info, false)
                        }
                    }
                    iCloudHandler(iCloudRequestID)
                }else {
                    resultHandler(livePhoto, info, false)
                }
            }
        }
    }
    
    
    /// 根据下载获取的信息判断资源是否存在iCloud上
    /// - Parameter info: 下载获取的信息
    class func assetIsInCloud(for info: [AnyHashable : Any]?) -> Bool {
        if info == nil {
            return false
        }
        if info![AnyHashable(PHImageResultIsInCloudKey)] == nil {
            return false
        }
        let isInCloud = info![AnyHashable(PHImageResultIsInCloudKey)] as! Int
        return (isInCloud == 1)
    }
    
    /// 判断资源是否取消了下载
    /// - Parameter info: 下载获取的信息
    class func assetDownloadCancel(for info: [AnyHashable : Any]?) -> Bool {
        if info == nil {
            return false
        }
        if info![AnyHashable(PHImageCancelledKey)] == nil {
            return false
        }
        let isCancel = info![AnyHashable(PHImageCancelledKey)] as! Int
        return (isCancel == 1)
    }
    
    /// 判断资源是否下载错误
    /// - Parameter info: 下载获取的信息
    class func assetDownloadError(for info: [AnyHashable : Any]?) -> Bool {
        if info == nil {
            return false
        }
        if info![AnyHashable(PHImageErrorKey)] == nil {
            return false
        }
        let error = info![AnyHashable(PHImageErrorKey)]
        return (error != nil)
    }
    
    /// 判断资源下载得到的是否为退化的
    /// - Parameter info: 下载获取的信息
    class func assetDownloadIsDegraded(for info: [AnyHashable : Any]?) -> Bool {
        if info == nil {
            return false
        }
        let isDegraded = info![AnyHashable(PHImageResultIsDegradedKey)] as! Int
        return (isDegraded == 1)
    }
    
    /// 判断资源是否下载完成
    /// - Parameter info: 下载获取的信息
    class func assetDownloadFinined(for info: [AnyHashable : Any]?) -> Bool {
        if info == nil {
            return false
        }
        let isCancel = assetDownloadCancel(for: info)
        let isDegraded = assetDownloadIsDegraded(for: info)
        let error = assetDownloadError(for: info)
        
        return (!isCancel && !error && !isDegraded)
    }
}
