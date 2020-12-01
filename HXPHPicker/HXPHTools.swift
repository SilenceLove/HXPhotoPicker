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
        if status == .denied ||
            status == .restricted {
            showAlert(viewController: viewController, title: "无法访问相册中照片".hx_localized, message: "当前无照片访问权限，建议前往系统设置，\n允许访问「照片」中的「所有照片」。".hx_localized, leftActionTitle: "取消".hx_localized, leftHandler: {_ in }, rightActionTitle: "前往系统设置".hx_localized) { (alertAction) in
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
        let alertController = UIAlertController.init(title: title, message: message, preferredStyle: .alert)
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
        if collection.assetCollectionType == .album {
            return collection.localizedTitle
        }
        var albumName : String?
        let type = HXPHManager.shared.languageType
        if type == .system {
            albumName = collection.localizedTitle
        }else {
            if collection.localizedTitle == "最近项目" ||
                collection.localizedTitle == "最近添加"  {
                albumName = "HXAlbumRecents".hx_localized
            }else if collection.localizedTitle == "Camera Roll" ||
                        collection.localizedTitle == "相机胶卷" {
                albumName = "HXAlbumCameraRoll".hx_localized
            }else {
                switch collection.assetCollectionSubtype {
                case .smartAlbumUserLibrary:
                    albumName = "HXAlbumCameraRoll".hx_localized
                    break
                case .smartAlbumVideos:
                    albumName = "HXAlbumVideos".hx_localized
                    break
                case .smartAlbumPanoramas:
                    albumName = "HXAlbumPanoramas".hx_localized
                    break
                case .smartAlbumFavorites:
                    albumName = "HXAlbumFavorites".hx_localized
                    break
                case .smartAlbumTimelapses:
                    albumName = "HXAlbumTimelapses".hx_localized
                    break
                case .smartAlbumRecentlyAdded:
                    albumName = "HXAlbumRecentlyAdded".hx_localized
                    break
                case .smartAlbumBursts:
                    albumName = "HXAlbumBursts".hx_localized
                    break
                case .smartAlbumSlomoVideos:
                    albumName = "HXAlbumSlomoVideos".hx_localized
                    break
                case .smartAlbumSelfPortraits:
                    albumName = "HXAlbumSelfPortraits".hx_localized
                    break
                case .smartAlbumScreenshots:
                    albumName = "HXAlbumScreenshots".hx_localized
                    break
                case .smartAlbumDepthEffect:
                    albumName = "HXAlbumDepthEffect".hx_localized
                    break
                case .smartAlbumLivePhotos:
                    albumName = "HXAlbumLivePhotos".hx_localized
                    break
                case .smartAlbumAnimated:
                    albumName = "HXAlbumAnimated".hx_localized
                    break
                default:
                    albumName = collection.localizedTitle
                    break
                }
            }
        }
        return albumName
    }
    
    class func transformTargetWidthToSize(targetWidth: CGFloat, asset: PHAsset) -> CGSize {
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
}
