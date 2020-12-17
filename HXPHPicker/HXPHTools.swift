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
    class func showNotCameraAuthorizedAlert(viewController : UIViewController?) {
        if viewController == nil {
            return
        }
        showAlert(viewController: viewController, title: "无法使用相机功能".hx_localized, message: "请前往系统设置中，允许访问「相机」。".hx_localized, leftActionTitle: "取消".hx_localized, leftHandler: {_ in }, rightActionTitle: "前往系统设置".hx_localized) { (alertAction) in
            openSettingsURL()
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
        viewController?.present(alertController, animated: true, completion: nil)
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
    class func getVideoThumbnailImage(videoURL: URL?, atTime: TimeInterval) -> UIImage? {
        if videoURL == nil {
            return nil
        }
        let urlAsset = AVURLAsset.init(url: videoURL!)
        let assetImageGenerator = AVAssetImageGenerator.init(asset: urlAsset)
        assetImageGenerator.appliesPreferredTrackTransform = true
        assetImageGenerator.apertureMode = .encodedPixels
        let thumbnailImageTime: CFTimeInterval = atTime
        do {
            let thumbnailImageRef = try assetImageGenerator.copyCGImage(at: CMTime(value: CMTimeValue(thumbnailImageTime), timescale: 60), actualTime: nil)
            let image = UIImage.init(cgImage: thumbnailImageRef)
            return image
        } catch {
            return nil
        }
    }
    class func getVideoDuration(videoURL: URL?) -> TimeInterval {
        if videoURL == nil {
            return 0
        }
        let options = [AVURLAssetPreferPreciseDurationAndTimingKey: false]
        let urlAsset = AVURLAsset.init(url: videoURL!, options: options)
        let second = Int(urlAsset.duration.value) / Int(urlAsset.duration.timescale)
        return TimeInterval(second)
    }
    class func transformBytesToString(bytes: Int) -> String {
        if CGFloat(bytes) >= 0.5 * 1024 * 1024 {
            return String.init(format: "%0.1fM", arguments: [CGFloat(bytes) / 1024 / 1024])
        }else if bytes >= 1024 {
            return String.init(format: "%0.0fK", arguments: [CGFloat(bytes) / 1024])
        }else {
            return String.init(format: "%dB", arguments: [bytes])
        }
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
        config.allowSelectedTogether = true
        config.albumShowMode = .popup
        config.appearanceStyle = .normal
        config.showLivePhoto = true
        config.navigationViewBackgroundColor = "#2E2F30".hx_color
        config.navigationTitleColor = .white
        config.navigationTintColor = .white
        config.statusBarStyle = .lightContent
        config.navigationBarStyle = .black
        
        config.albumList.backgroundColor = "#2E2F30".hx_color
        config.albumList.cellHeight = 60
        config.albumList.cellBackgroundColor = "#2E2F30".hx_color
        config.albumList.cellSelectedColor = UIColor.init(red: 0.125, green: 0.125, blue: 0.125, alpha: 1)
        config.albumList.albumNameColor = .white
        config.albumList.photoCountColor = .white
        config.albumList.separatorLineColor = "#434344".hx_color.withAlphaComponent(0.6)
        config.albumList.tickColor = "#07C160".hx_color
        
        config.photoList.backgroundColor = "#2E2F30".hx_color
        
        config.photoList.titleViewConfig.backgroundColor = UIColor.gray.withAlphaComponent(0.3)
        config.photoList.titleViewConfig.arrowBackgroundColor = "#B2B2B2".hx_color
        config.photoList.titleViewConfig.arrowColor = "#2E2F30".hx_color
        
        config.photoList.cell.selectBox.selectedBackgroundColor = "#07C160".hx_color
        config.photoList.cell.selectBox.titleColor = .white
        
        config.photoList.cameraCell.cameraImageName = "hx_picker_photoList_photograph_white"
        
        config.photoList.bottomView.barStyle = .black
        config.photoList.bottomView.previewButtonTitleColor = .white
        
        config.photoList.bottomView.originalButtonTitleColor = .white
        config.photoList.bottomView.originalSelectBox.backgroundColor = .clear
        config.photoList.bottomView.originalSelectBox.borderColor = .white
        config.photoList.bottomView.originalSelectBox.tickColor = .white
        config.photoList.bottomView.originalSelectBox.selectedBackgroundColor = "#07C160".hx_color
        
        config.photoList.bottomView.finishButtonTitleColor = .white
        config.photoList.bottomView.finishButtonBackgroundColor = "#07C160".hx_color
        config.photoList.bottomView.finishButtonDisableBackgroundColor = "#666666".hx_color.withAlphaComponent(0.3)
        
        config.photoList.bottomView.promptTitleColor = UIColor.white.withAlphaComponent(0.6)
        config.photoList.bottomView.promptIconColor = "#f5a623".hx_color
        config.photoList.bottomView.promptArrowColor = UIColor.white.withAlphaComponent(0.6)
        
        config.photoList.emptyView.titleColor = "#ffffff".hx_color
        config.photoList.emptyView.subTitleColor = .lightGray
        
        config.previewView.backgroundColor = .black
        config.previewView.selectBox.tickColor = .white
        config.previewView.selectBox.selectedBackgroundColor = "#07C160".hx_color
        
        config.previewView.bottomView.barStyle = .black
        config.previewView.bottomView.editButtonTitleColor = .white
        
        config.previewView.bottomView.originalButtonTitleColor = .white
        config.previewView.bottomView.originalSelectBox.backgroundColor = .clear
        config.previewView.bottomView.originalSelectBox.borderColor = .white
        config.previewView.bottomView.originalSelectBox.tickColor = .white
        config.previewView.bottomView.originalSelectBox.selectedBackgroundColor = "#07C160".hx_color
        config.previewView.bottomView.originalLoadingStyle = .white
        
        config.previewView.bottomView.finishButtonTitleColor = .white
        config.previewView.bottomView.finishButtonBackgroundColor = "#07C160".hx_color
        config.previewView.bottomView.finishButtonDisableBackgroundColor = "#666666".hx_color.withAlphaComponent(0.3)
        
        config.previewView.bottomView.selectedViewTickColor = "#07C160".hx_color
        
        config.notAuthorized.closeButtonImageName = "hx_picker_notAuthorized_close_dark"
        config.notAuthorized.backgroundColor = "#2E2F30".hx_color
        config.notAuthorized.titleColor = .white
        config.notAuthorized.subTitleColor = .white
        config.notAuthorized.jumpButtonTitleColor = .white
        config.notAuthorized.jumpButtonBackgroundColor = "#07C160".hx_color
        
        return config
    }
}
