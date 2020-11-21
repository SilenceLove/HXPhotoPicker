//
//  HXPHAsset.swift
//  HXPhotoPickerSwift
//
//  Created by 洪欣 on 2020/11/12.
//  Copyright © 2020 洪欣. All rights reserved.
//

import UIKit
import Photos

typealias HXPHAssetICloudHandlerHandler = (HXPHAsset, PHImageRequestID) -> Void
typealias HXPHAssetProgressHandler = (HXPHAsset, Double) -> Void
typealias HXPHAssetFailureHandler = (HXPHAsset, [AnyHashable : Any]?) -> Void

class HXPHAsset: NSObject {
    
    /// 系统相册里的资源
    var asset: PHAsset? {
        didSet {
            setMediaType()
        }
    }
    
    /// 当前资源的图片大小
    var imageSize: CGSize {
        get {
            let size : CGSize
            if asset != nil {
                if asset!.pixelWidth == 0 || asset!.pixelHeight == 0 {
                    size = CGSize(width: 200, height: 200)
                }else {
                    size = CGSize(width: asset!.pixelWidth, height: asset!.pixelHeight)
                }
            }else {
                size = CGSize(width: 200, height: 200)
            }
            return size
        }
    }
    
    /// 媒体类型
    var mediaType: HXPHAssetMediaType = HXPHAssetMediaType.photo
    
    /// 媒体子类型
    var mediaSubType: HXPHAssetMediaSubType = HXPHAssetMediaSubType.image
    
    /// 视频时长 格式：00:00
    var videoTime: String?
    
    /// 视频时长 秒
    var videoDuration: TimeInterval = 0
    
    /// 当前资源是否被选中
    var selected: Bool = false
    
    /// 选中时的下标
    var selectIndex: Int = 0
    
    init(asset: PHAsset) {
        super.init()
        self.asset = asset
        setMediaType()
    }
    private func setMediaType() {
        if asset?.mediaType.rawValue == 1 {
            mediaType = HXPHAssetMediaType.photo
            mediaSubType = HXPHAssetMediaSubType.image
        }else if asset?.mediaType.rawValue == 2 {
            mediaType = HXPHAssetMediaType.video
            mediaSubType = HXPHAssetMediaSubType.video
            videoDuration = asset!.duration
            videoTime = HXPHTools.transformVideoDurationToString(duration: asset!.duration)
        }
    }
    
    /// 请求缩略图
    /// - Parameter completion: 完成回调
    /// - Returns: 请求ID
    func requestThumbnailImage(completion: ((UIImage?, HXPHAsset, [AnyHashable : Any]?) -> Void)?) -> PHImageRequestID? {
        if asset == nil {
            return nil
        }
        return HXPHAssetManager.requestThumbnailImage(for: asset!, targetWidth: 165) { (image, info) in
            if completion != nil {
                completion!(image, self, info)
            }
        }
    }
    
    /// 请求imageData，如果资源在iCloud上会自动下载。如果需要更细节的处理请使用 PHAssetManager
    /// - Parameters:
    ///   - iCloudHandler: 下载iCloud上的资源时回调iCloud的请求ID
    ///   - progressHandler: iCloud下载进度
    /// - Returns: 请求ID
    func requestImageData(iCloudHandler: HXPHAssetICloudHandlerHandler?, progressHandler: HXPHAssetProgressHandler?, success: ((HXPHAsset, Data, UIImage.Orientation, [AnyHashable : Any]?) -> Void)?, failure: HXPHAssetFailureHandler?) -> PHImageRequestID {
        if asset == nil {
            if failure != nil {
                failure!(self, nil)
            }
            return 0
        }
        var version = PHImageRequestOptionsVersion.current
        if mediaSubType == HXPHAssetMediaSubType.imageAnimated {
            version = PHImageRequestOptionsVersion.original
        }
        return HXPHAssetManager.requestImageData(for: asset!, version: version, iCloudHandler: { (iCloudRequestID) in
            if iCloudHandler != nil {
                iCloudHandler!(self, iCloudRequestID)
            }
        }, progressHandler: { (progress, error, stop, info) in
            if progressHandler != nil {
                progressHandler!(self, progress)
            }
        }, resultHandler: { (data, dataUTI, imageOrientation, info, downloadSuccess) in
            if downloadSuccess {
                if success != nil {
                    success!(self, data!, imageOrientation, info)
                }
            }else {
                if failure != nil {
                    failure!(self, info)
                }
            }
        })
    }
    
    /// 请求LivePhoto，如果资源在iCloud上会自动下载。如果需要更细节的处理请使用 PHAssetManager
    /// - Parameters:
    ///   - targetSize: 请求的大小
    ///   - iCloudHandler: 下载iCloud上的资源时回调iCloud的请求ID
    ///   - progressHandler: iCloud下载进度
    /// - Returns: 请求ID
    @available(iOS 9.1, *)
    func requestLivePhoto(targetSize: CGSize, iCloudHandler: HXPHAssetICloudHandlerHandler?, progressHandler: HXPHAssetProgressHandler?, success: ((HXPHAsset, PHLivePhoto, [AnyHashable : Any]?) -> Void)?, failure: HXPHAssetFailureHandler?) -> PHImageRequestID {
        if asset == nil {
            if failure != nil {
                failure?(self, nil)
            }
            return 0
        }
        
        return HXPHAssetManager.requestLivePhoto(for: asset!, targetSize: targetSize) { (iCloudRequestID) in
            if iCloudHandler != nil {
                iCloudHandler!(self, iCloudRequestID)
            }
        } progressHandler: { (progress, error, stop, info) in
            if progressHandler != nil {
                progressHandler!(self, progress)
            }
        } resultHandler: { (livePhoto, info, downloadSuccess) in
            if downloadSuccess {
                if success != nil {
                    success!(self, livePhoto!, info)
                }
            }else {
                if failure != nil {
                    failure!(self, info)
                }
            }
        }

    }
}
