//
//  HXPHTools.swift
//  照片选择器-Swift
//
//  Created by 洪欣 on 2019/6/29.
//  Copyright © 2019年 洪欣. All rights reserved.
//

import UIKit
import Photos

typealias statusHandler = (PHAuthorizationStatus) -> ()

class HXPHTools: NSObject {
    
    
    /// 显示没有权限的弹窗
    /// - Parameters:
    ///   - viewController: 需要弹窗的viewController
    ///   - status: 权限类型
    class func showNotAuthorizedAlert(viewController : UIViewController? , status : PHAuthorizationStatus) {
        if viewController == nil {
            return
        }
        if status == PHAuthorizationStatus.denied ||
            status == PHAuthorizationStatus.restricted {
            showAlert(viewController: viewController, title: "无法访问相册", message: "请在设置-隐私-相册中允许访问相册", leftActionTitle: "取消", leftHandler: {_ in }, rightActionTitle: "设置") { (alertAction) in
                openSettingsURL()
            }
        }
    }
    
    class func openSettingsURL() {
        if #available(iOS 10, *) {
            UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!, options: [:], completionHandler: nil)
        } else {
            UIApplication.shared.openURL(URL(string: UIApplication.openSettingsURLString)!)
        }
    }
    
    class func showAlert(viewController: UIViewController? , title: String? , message: String? , leftActionTitle: String ,  leftHandler: @escaping (UIAlertAction)->(), rightActionTitle: String , rightHandler: @escaping (UIAlertAction)->()) {
        let alertController = UIAlertController.init(title: title, message: message, preferredStyle: UIAlertController.Style.alert)
        let leftAction = UIAlertAction.init(title: leftActionTitle, style: UIAlertAction.Style.cancel, handler: leftHandler)
        let rightAction = UIAlertAction.init(title: rightActionTitle, style: UIAlertAction.Style.default, handler: rightHandler)
        alertController.addAction(leftAction)
        alertController.addAction(rightAction)
    }
    
    class func transformVideoDurationToString(duration: TimeInterval) -> String {
        let time = Int(round(Double(duration)))
        if time < 10 {
            return String.init(format: "00:0%d", arguments: [time])
        }else if time < 60 {
            return String.init(format: "00:%d", arguments: [time])
        }else {
            let min = Int(time / 60)
            let sec = time - (min * 60)
            if sec < 10 {
                return String.init(format: "%d:0%d", arguments: [min,sec])
            }else {
                return String.init(format: "%d:%d", arguments: [min,sec])
            }
        }
    }
    
    class func transformAlbumName(for collection: PHAssetCollection) -> String? {
        if collection.assetCollectionType == PHAssetCollectionType.album {
            return collection.localizedTitle
        }
        var albumName : String?
        let type = HXPHManager.shared.languageType
        if type == HXPHLanguageType.system {
            albumName = collection.localizedTitle
        }else {
            if collection.localizedTitle == "最近项目" ||
                collection.localizedTitle == "最近添加"  {
                albumName = "HXAlbumRecents".hx_localized()
            }else if collection.localizedTitle == "Camera Roll" ||
                        collection.localizedTitle == "相机胶卷" {
                albumName = "HXAlbumCameraRoll".hx_localized()
            }else {
                switch collection.assetCollectionSubtype {
                case PHAssetCollectionSubtype.smartAlbumUserLibrary:
                    albumName = "HXAlbumCameraRoll".hx_localized()
                    break
                case PHAssetCollectionSubtype.smartAlbumVideos:
                    albumName = "HXAlbumVideos".hx_localized()
                    break
                case PHAssetCollectionSubtype.smartAlbumPanoramas:
                    albumName = "HXAlbumPanoramas".hx_localized()
                    break
                case PHAssetCollectionSubtype.smartAlbumFavorites:
                    albumName = "HXAlbumFavorites".hx_localized()
                    break
                case PHAssetCollectionSubtype.smartAlbumTimelapses:
                    albumName = "HXAlbumTimelapses".hx_localized()
                    break
                case PHAssetCollectionSubtype.smartAlbumRecentlyAdded:
                    albumName = "HXAlbumRecentlyAdded".hx_localized()
                    break
                case PHAssetCollectionSubtype.smartAlbumBursts:
                    albumName = "HXAlbumBursts".hx_localized()
                    break
                case PHAssetCollectionSubtype.smartAlbumSlomoVideos:
                    albumName = "HXAlbumSlomoVideos".hx_localized()
                    break
                case PHAssetCollectionSubtype.smartAlbumSelfPortraits:
                    albumName = "HXAlbumSelfPortraits".hx_localized()
                    break
                case PHAssetCollectionSubtype.smartAlbumScreenshots:
                    albumName = "HXAlbumScreenshots".hx_localized()
                    break
                case PHAssetCollectionSubtype.smartAlbumDepthEffect:
                    albumName = "HXAlbumDepthEffect".hx_localized()
                    break
                case PHAssetCollectionSubtype.smartAlbumLivePhotos:
                    albumName = "HXAlbumLivePhotos".hx_localized()
                    break
                case PHAssetCollectionSubtype.smartAlbumAnimated:
                    albumName = "HXAlbumAnimated".hx_localized()
                    break
                default:
                    albumName = collection.localizedTitle
                    break
                }
            }
        }
        return albumName
    }
}
