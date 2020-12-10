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
    
    class func getWXConfig() -> HXPHConfiguration {
        let config = HXPHConfiguration.init()
        config.maximumSelectCount = 9
        config.maximumSelectVideoCount = 0
        config.allowSelectedTogether = false
        config.albumShowMode = .popup
        config.appearanceStyle = .normal
        config.showLivePhoto = true
        config.navigationViewBackgroundColor = "#2E2F30".hx_color
        config.navigationTitleColor = UIColor.white
        config.navigationTintColor = UIColor.white
        config.statusBarStyle = .lightContent
        config.navigationBarStyle = .black
        
        config.albumList.backgroundColor = "#2E2F30".hx_color
        config.albumList.cellHeight = 60
        config.albumList.cellBackgroundColor = "#2E2F30".hx_color
        config.albumList.cellSelectedColor = UIColor.init(red: 0.125, green: 0.125, blue: 0.125, alpha: 1)
        config.albumList.albumNameColor = UIColor.white
        config.albumList.photoCountColor = UIColor.white
        config.albumList.separatorLineColor = "#434344".hx_color.withAlphaComponent(0.6)
        config.albumList.tickColor = "#07C160".hx_color
        
        config.photoList.backgroundColor = "#2E2F30".hx_color
        
        config.photoList.titleViewConfig.backgroundColor = UIColor.gray.withAlphaComponent(0.3)
        config.photoList.titleViewConfig.arrowBackgroundColor = "#B2B2B2".hx_color
        config.photoList.titleViewConfig.arrowColor = "#2E2F30".hx_color
        
        config.photoList.cell.selectBox.selectedBackgroundColor = "#07C160".hx_color
        config.photoList.cell.selectBox.titleColor = UIColor.white
        
        config.photoList.bottomView.barStyle = .black
        config.photoList.bottomView.previewButtonTitleColor = UIColor.white
        
        config.photoList.bottomView.originalButtonTitleColor = UIColor.white
        config.photoList.bottomView.originalSelectBox.backgroundColor = UIColor.clear
        config.photoList.bottomView.originalSelectBox.borderColor = UIColor.white
        config.photoList.bottomView.originalSelectBox.tickColor = UIColor.white
        config.photoList.bottomView.originalSelectBox.selectedBackgroundColor = "#07C160".hx_color
        
        config.photoList.bottomView.finishButtonTitleColor = UIColor.white
        config.photoList.bottomView.finishButtonBackgroundColor = "#07C160".hx_color
        config.photoList.bottomView.finishButtonDisableBackgroundColor = "#666666".hx_color.withAlphaComponent(0.3)
        
        config.previewView.backgroundColor = UIColor.black
        config.previewView.selectBox.tickColor = UIColor.white
        config.previewView.selectBox.selectedBackgroundColor = "#07C160".hx_color
        
        config.previewView.bottomView.barStyle = .black
        config.previewView.bottomView.editButtonTitleColor = UIColor.white
        
        config.previewView.bottomView.originalButtonTitleColor = UIColor.white
        config.previewView.bottomView.originalSelectBox.backgroundColor = UIColor.clear
        config.previewView.bottomView.originalSelectBox.borderColor = UIColor.white
        config.previewView.bottomView.originalSelectBox.tickColor = UIColor.white
        config.previewView.bottomView.originalSelectBox.selectedBackgroundColor = "#07C160".hx_color
        
        config.previewView.bottomView.finishButtonTitleColor = UIColor.white
        config.previewView.bottomView.finishButtonBackgroundColor = "#07C160".hx_color
        config.previewView.bottomView.finishButtonDisableBackgroundColor = "#666666".hx_color.withAlphaComponent(0.3)
        
        config.notAuthorized.closeButtonImageName = "hx_picker_notAuthorized_close_dark"
        config.notAuthorized.backgroundColor = "#2E2F30".hx_color
        config.notAuthorized.titleColor = UIColor.white
        config.notAuthorized.subTitleColor = UIColor.white
        config.notAuthorized.jumpButtonTitleColor = UIColor.white
        config.notAuthorized.jumpButtonBackgroundColor = "#07C160".hx_color
        
        return config
    }
}
