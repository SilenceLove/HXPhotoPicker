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
            status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        } else {
            // Fallback on earlier versions
            status = PHPhotoLibrary.authorizationStatus();
        }
        return status;
    }
    
    class func authorizationStatusIsLimited() -> Bool{
        if #available(iOS 14, *) {
            if authorizationStatus() == .limited {
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
                PHPhotoLibrary.requestAuthorization(for: .readWrite) { (authorizationStatus) in
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
        return PHAssetCollection.fetchAssetCollections(with: .smartAlbum, subtype: .any, options: options)
    }
    
    /// 获取用户创建的相册
    /// - Parameter options: 选项
    /// - Returns: 相册列表
    class func fetchUserAlbums(options : PHFetchOptions?) -> PHFetchResult<PHAssetCollection> {
        return PHAssetCollection.fetchAssetCollections(with: .album, subtype: .any, options: options)
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
            return collection?.assetCollectionSubtype == .smartAlbumRecentlyAdded
        }else {
            return collection?.assetCollectionSubtype == .smartAlbumUserLibrary
        }
    }
    
    class func fetchAssets(withLocalIdentifiers: [String]) -> PHFetchResult<PHAsset> {
        PHAsset.fetchAssets(withLocalIdentifiers: withLocalIdentifiers, options: nil)
    }
    
    class func fetchAsset(withLocalIdentifier: String) -> PHAsset? {
        return fetchAssets(withLocalIdentifiers: [withLocalIdentifier]).firstObject
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
            if asset.playbackStyle == .imageAnimated {
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
            isLivePhoto = asset.mediaSubtypes == .photoLive
            if #available(iOS 11, *) {
                if asset.playbackStyle == .livePhoto {
                    isLivePhoto = true
                }
            }
        }
        return isLivePhoto
    }
    
    /// 请求image
    /// - Parameters:
    ///   - asset: 资源对象
    ///   - targetSize: 指定大小
    ///   - options: 可选项
    ///   - resultHandler: 回调
    /// - Returns: 请求ID
    class func requestImage(for asset: PHAsset, targetSize: CGSize, options: PHImageRequestOptions, resultHandler: @escaping (UIImage?, [AnyHashable : Any]?) -> Void) -> PHImageRequestID {
        return PHImageManager.default().requestImage(for: asset, targetSize: targetSize, contentMode: .aspectFill, options: options, resultHandler: resultHandler)
    }
    
    /// 请求获取缩略图
    /// - Parameters:
    ///   - asset: 资源对象
    ///   - targetWidth: 获取的图片大小
    ///   - completion: 完成
    /// - Returns: 请求ID
    class func requestThumbnailImage(for asset: PHAsset, targetWidth: CGFloat, completion: ((UIImage?, [AnyHashable : Any]?) -> ())?) -> PHImageRequestID {
        let options = PHImageRequestOptions.init()
        options.resizeMode = .fast
        return requestImage(for: asset, targetSize: HXPHTools.transformTargetWidthToSize(targetWidth: targetWidth, asset: asset), options: options) { (image, info) in
            if completion != nil {
                DispatchQueue.main.async {
                    completion!(image, info)
                }
            }
        }
    }
    
    /// 请求imageData，注意处理 HEIC格式
    class func requestImageData(for asset: PHAsset, options: PHImageRequestOptions, resultHandler: @escaping (Data?, String?, UIImage.Orientation, [AnyHashable : Any]?) -> Void) -> PHImageRequestID {
        if #available(iOS 13, *) {
            return PHImageManager.default().requestImageDataAndOrientation(for: asset, options: options) { (imageData, dataUTI, imageOrientation, info) in
                var sureOrientation : UIImage.Orientation;
                if (imageOrientation == .up) {
                    sureOrientation = .up;
                } else if (imageOrientation == .upMirrored) {
                    sureOrientation = .upMirrored;
                } else if (imageOrientation == .down) {
                    sureOrientation = .down;
                } else if (imageOrientation == .downMirrored) {
                    sureOrientation = .downMirrored;
                } else if (imageOrientation == .left) {
                    sureOrientation = .left;
                } else if (imageOrientation == .leftMirrored) {
                    sureOrientation = .leftMirrored;
                } else if (imageOrientation == .right) {
                    sureOrientation = .right;
                } else if (imageOrientation == .rightMirrored) {
                    sureOrientation = .rightMirrored;
                } else {
                    sureOrientation = .up;
                }
                
                if Thread.current.isMainThread {
                    resultHandler(imageData, dataUTI, sureOrientation, info)
                }else {
                    DispatchQueue.main.async {
                        resultHandler(imageData, dataUTI, sureOrientation, info)
                    }
                }
            }
        } else {
            // Fallback on earlier versions
            return PHImageManager.default().requestImageData(for: asset, options: options) { (imageData, dataUTI, imageOrientation, info) in
                if Thread.current.isMainThread {
                    resultHandler(imageData, dataUTI, imageOrientation, info)
                }else {
                    DispatchQueue.main.async {
                        resultHandler(imageData, dataUTI, imageOrientation, info)
                    }
                }
            }
        }
    }
    /// 请求imageData，注意处理 HEIC格式
    class func requestImageData(for asset: PHAsset, version: PHImageRequestOptionsVersion, isNetworkAccessAllowed: Bool, progressHandler: @escaping PHAssetImageProgressHandler, resultHandler: @escaping (Data?, String?, UIImage.Orientation, [AnyHashable : Any]?) -> Void) -> PHImageRequestID {
        let options = PHImageRequestOptions.init()
        options.version = version
        options.resizeMode = .fast
        options.isNetworkAccessAllowed = isNetworkAccessAllowed
        options.progressHandler = progressHandler
        return requestImageData(for: asset, options: options, resultHandler: resultHandler)
    }
    
    /// 请求imageData，如果资源在iCloud上会自动请求下载iCloud上的资源 注意处理 HEIC格式
    /// - Parameters:
    ///   - iCloudHandler: 如果资源在iCloud上，下载之前回先回调出请求ID
    ///   - progressHandler: 处理进度
    ///   - resultHandler: 处理结果
    /// - Returns: 请求ID
    class func requestImageData(for asset: PHAsset, version: PHImageRequestOptionsVersion, iCloudHandler: @escaping (PHImageRequestID) -> Void, progressHandler: @escaping PHAssetImageProgressHandler, resultHandler: @escaping (Data?, String?, UIImage.Orientation, [AnyHashable : Any]?, Bool) -> Void) -> PHImageRequestID {
        return requestImageData(for: asset, version: version, isNetworkAccessAllowed: false, progressHandler: progressHandler) { (data, dataUTI, imageOrientation, info) in
            if self.assetDownloadFinined(for: info) {
                DispatchQueue.main.async {
                    resultHandler(data, dataUTI, imageOrientation, info, true)
                }
            }else {
                if self.assetIsInCloud(for: info) {
                    let iCloudRequestID = self.requestImageData(for: asset, version: version, isNetworkAccessAllowed: true, progressHandler: progressHandler, resultHandler: { (data, dataUTI, imageOrientation, info) in
                        DispatchQueue.main.async {
                            resultHandler(data, dataUTI, imageOrientation, info, self.assetDownloadFinined(for: info))
                        }
                    })
                    DispatchQueue.main.async {
                        iCloudHandler(iCloudRequestID)
                    }
                }else {
                    DispatchQueue.main.async {
                        resultHandler(data, dataUTI, imageOrientation, info, false)
                    }
                }
            }
        }
    }
    
    @available(iOS 9.1, *)
    class func requestLivePhoto(for asset: PHAsset, targetSize: CGSize, options: PHLivePhotoRequestOptions, resultHandler: @escaping (PHLivePhoto?, [AnyHashable : Any]?) -> Void) -> PHImageRequestID {
        return PHImageManager.default().requestLivePhoto(for: asset, targetSize: targetSize, contentMode: .aspectFill, options: options, resultHandler: resultHandler)
    }
    @available(iOS 9.1, *)
    class func requestLivePhoto(for asset: PHAsset, targetSize: CGSize, isNetworkAccessAllowed: Bool, progressHandler: @escaping PHAssetImageProgressHandler, resultHandler: @escaping (PHLivePhoto?, [AnyHashable : Any]?) -> Void) -> PHImageRequestID {
        let options = PHLivePhotoRequestOptions.init()
        options.deliveryMode = .highQualityFormat
        options.isNetworkAccessAllowed = isNetworkAccessAllowed
        options.progressHandler = progressHandler
        return requestLivePhoto(for: asset, targetSize: targetSize, options: options, resultHandler: resultHandler)
    }
    
    /// 请求LivePhoto，如果资源在iCloud上会自动请求下载iCloud上的资源
    /// - Parameters:
    ///   - targetSize: 请求的目标大小
    ///   - iCloudHandler: 如果资源在iCloud上，下载之前回先回调出请求ID
    ///   - progressHandler: 处理进度
    ///   - resultHandler: 处理结果
    /// - Returns: 请求ID
    @available(iOS 9.1, *)
    class func requestLivePhoto(for asset: PHAsset, targetSize: CGSize, iCloudHandler: @escaping (PHImageRequestID) -> Void, progressHandler: @escaping PHAssetImageProgressHandler, resultHandler: @escaping (PHLivePhoto?, [AnyHashable : Any]?, Bool) -> Void) -> PHImageRequestID {
        return requestLivePhoto(for: asset, targetSize: targetSize, isNetworkAccessAllowed: false, progressHandler: progressHandler) { (livePhoto, info) in
            if self.assetDownloadFinined(for: info) {
                DispatchQueue.main.async {
                    resultHandler(livePhoto, info, true)
                }
            }else {
                if self.assetIsInCloud(for: info) {
                    let iCloudRequestID = self.requestLivePhoto(for: asset, targetSize: targetSize, isNetworkAccessAllowed: true, progressHandler: progressHandler) { (livePhoto, info) in
                        DispatchQueue.main.async {
                            if self.assetDownloadFinined(for: info) {
                                resultHandler(livePhoto, info, true)
                            }else {
                                resultHandler(livePhoto, info, false)
                            }
                        }
                    }
                    DispatchQueue.main.async {
                        iCloudHandler(iCloudRequestID)
                    }
                }else {
                    DispatchQueue.main.async {
                        resultHandler(livePhoto, info, false)
                    }
                }
            }
        }
    }
    
    
    /// 请求AVAsset
    /// - Parameters:
    ///   - asset: 对应的 PHAsset
    ///   - options: 可选项
    ///   - resultHandler: 处理结果
    /// - Returns: 请求ID
    class func requestAVAsset(for asset: PHAsset, options: PHVideoRequestOptions, resultHandler: @escaping (AVAsset?, AVAudioMix?, [AnyHashable : Any]?) -> Void) -> PHImageRequestID {
        return PHImageManager.default().requestAVAsset(forVideo: asset, options: options, resultHandler: resultHandler)
    }
    
    /// 请求AVAsset，如果资源在iCloud上会自动请求下载iCloud上的资源
    /// - Parameters:
    ///   - isNetworkAccessAllowed: 如果资源在iCloud上，下载之前回先回调出请求ID
    ///   - progressHandler: 处理进度
    ///   - resultHandler: 处理结果
    /// - Returns: 请求ID
    class func requestAVAsset(for asset: PHAsset, version: PHVideoRequestOptionsVersion, deliveryMode: PHVideoRequestOptionsDeliveryMode, isNetworkAccessAllowed: Bool, progressHandler: @escaping PHAssetImageProgressHandler, resultHandler: @escaping (AVAsset?, AVAudioMix?, [AnyHashable : Any]?) -> Void) -> PHImageRequestID {
        let options = PHVideoRequestOptions.init()
        options.isNetworkAccessAllowed = isNetworkAccessAllowed
        options.progressHandler = progressHandler
        options.version = version
        options.deliveryMode = deliveryMode
        return requestAVAsset(for: asset, options: options, resultHandler: resultHandler)
    }
    class func requestAVAsset(for asset: PHAsset, iCloudHandler: @escaping (PHImageRequestID) -> Void, progressHandler: @escaping PHAssetImageProgressHandler, resultHandler: @escaping (AVAsset?, AVAudioMix?, [AnyHashable : Any]?, Bool) -> Void) -> PHImageRequestID {
        let version = PHVideoRequestOptionsVersion.current
        var deliveryMode = PHVideoRequestOptionsDeliveryMode.fastFormat
        return requestAVAsset(for: asset, version: version, deliveryMode: deliveryMode, isNetworkAccessAllowed: false, progressHandler: progressHandler) { (avAsset, audioMix, info) in
            if self.assetDownloadFinined(for: info) {
                DispatchQueue.main.async {
                    resultHandler(avAsset, audioMix, info, true)
                }
            }else {
                if self.assetIsInCloud(for: info) {
                    deliveryMode = .highQualityFormat
                    let iCloudRequestID = self.requestAVAsset(for: asset, version: version, deliveryMode: deliveryMode, isNetworkAccessAllowed: true, progressHandler: progressHandler) { (avAsset, audioMix, info) in
                        DispatchQueue.main.async {
                            if self.assetDownloadFinined(for: info) {
                                resultHandler(avAsset, audioMix, info, true)
                            }else {
                                resultHandler(avAsset, audioMix, info, false)
                            }
                        }
                    }
                    DispatchQueue.main.async {
                        iCloudHandler(iCloudRequestID)
                    }
                }else {
                    DispatchQueue.main.async {
                        resultHandler(avAsset, audioMix, info, false)
                    }
                }
            }
        }
    }
    // MARK: 获取视频地址
    class func requestVideoURL(for asset: PHAsset, resultHandler: @escaping (URL?) -> Void) {
        _ = requestAVAsset(for: asset) { (reqeustID) in
        } progressHandler: { (progress, error, stop, info) in
        } resultHandler: { (avAsset, audioMix, info, downloadSuccess) in
            DispatchQueue.main.async {
                if avAsset is AVURLAsset {
                    let urlAsset = avAsset as! AVURLAsset
                    resultHandler(urlAsset.url)
                }else {
                    let videoResource = PHAssetResource.assetResources(for: asset).first
                    if videoResource == nil {
                        resultHandler(nil)
                        return
                    }
                    var tempPath = NSTemporaryDirectory()
                    tempPath.append(contentsOf: String.hx_fileName(suffix: "mp4"))
                    let videoURl = URL.init(fileURLWithPath: tempPath)
                    let options = PHAssetResourceRequestOptions.init()
                    options.isNetworkAccessAllowed = true
                    PHAssetResourceManager.default().writeData(for: videoResource!, toFile: videoURl, options: options) { (error) in
                        if error == nil {
                            resultHandler(videoURl)
                        }else {
                            resultHandler(nil)
                        }
                    }
                }
            }
        }
    }
    // MARK: 获取图片地址
    class func requestImageURL(for asset: PHAsset, resultHandler: @escaping (URL?, UIImage?) -> Void) -> PHContentEditingInputRequestID {
        let options = PHContentEditingInputRequestOptions.init()
        options.isNetworkAccessAllowed = true
        return asset.requestContentEditingInput(with: options) { (input, info) in
            DispatchQueue.main.async {
                resultHandler(input?.fullSizeImageURL, input?.displaySizeImage)
            }
        }
    }
    // MARK: 获取LivePhoto里的图片和视频地址
    class func requestLivePhotoContent(for asset: PHAsset, imageHandler: @escaping (Data?) -> Void, videoHandler: @escaping (URL?) -> Void, completionHandler: @escaping (HXPHPicker.LivePhotoError?) -> Void) {
        if #available(iOS 9.1, *) {
            _ = requestLivePhoto(for: asset, targetSize: PHImageManagerMaximumSize) { (ID) in
            } progressHandler: { (progress, error, stop, info) in
            } resultHandler: { (livePhoto, info, downloadSuccess) in
                if livePhoto == nil {
                    completionHandler(.allError(HXPickerError.error(message: "livePhoto为nil，获取失败"), HXPickerError.error(message: "livePhoto为nil，获取失败")))
                    return
                }
                let assetResources: [PHAssetResource] = PHAssetResource.assetResources(for: livePhoto!)
                if assetResources.isEmpty {
                    completionHandler(.allError(HXPickerError.error(message: "assetResources为nil，获取失败"), HXPickerError.error(message: "assetResources为nil，获取失败")))
                    return
                }
                let callback = {(imageError: Error?, videoError: Error?) in
                    if imageError != nil && videoError != nil {
                        completionHandler(.allError(imageError, videoError))
                    }else if imageError != nil {
                        completionHandler(.imageError(imageError))
                    }else if videoError != nil {
                        completionHandler(.videoError(videoError))
                    }else {
                        completionHandler(nil)
                    }
                }
                let options = PHAssetResourceRequestOptions.init()
                options.isNetworkAccessAllowed = true
                var imageCompletion = false
                var imageError: Error?
                var videoCompletion = false
                var videoError: Error?
                
                for assetResource in assetResources {
                    if assetResource.type == .photo {
                        PHAssetResourceManager.default().requestData(for: assetResource, options: options) { (data) in
                            imageHandler(data)
                        } completionHandler: { (error) in
                            imageCompletion = true
                            imageError = error
                            if videoCompletion {
                                callback(imageError, videoError)
                            }
                        }
                    }else if assetResource.type == .pairedVideo {
                        var tempPath = NSTemporaryDirectory()
                        tempPath.append(contentsOf: String.hx_fileName(suffix: "mp4"))
                        let videoURl = URL.init(fileURLWithPath: tempPath)
                        PHAssetResourceManager.default().writeData(for: assetResource, toFile: videoURl, options: options) { (error) in
                            videoCompletion = true
                            if error == nil {
                                videoHandler(videoURl)
                            }
                            videoError = error
                            if imageCompletion {
                                callback(imageError, videoError)
                            }
                        }
                    }
                }
            }
        } else {
            // Fallback on earlier versions
            completionHandler(.allError(HXPickerError.error(message: "系统版本低于9.1"), HXPickerError.error(message: "系统版本低于9.1")))
        }
    }
    
    /// 资源是否存在iCloud上
    /// - Parameter asset: 对应的 PHAsset
    /// - Returns: 如果在获取到PHAsset之前还未下载的iCloud，之后下载了还是会返回存在
    class func isICloudAsset(for asset: PHAsset?) -> Bool {
        var isICloud = false
        if asset?.mediaType == PHAssetMediaType.image {
            let options = PHImageRequestOptions.init()
            options.isSynchronous = true
            options.deliveryMode = .fastFormat
            options.resizeMode = .fast
            _ = requestImageData(for: asset!, options: options) { (imageData, dataUTI, orientation, info) in
                if imageData == nil && self.assetIsInCloud(for: info) {
                    isICloud = true
                }
            }
        }else if asset?.mediaType == PHAssetMediaType.video {
            let resourceArray = PHAssetResource.assetResources(for: asset!)
            let bIsLocallayAvailable = resourceArray.first?.value(forKey: "locallyAvailable") as? Bool ?? true
            if !bIsLocallayAvailable {
                isICloud = true
            }
        }
        return isICloud
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
        if info![AnyHashable(PHImageResultIsDegradedKey)] == nil {
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
